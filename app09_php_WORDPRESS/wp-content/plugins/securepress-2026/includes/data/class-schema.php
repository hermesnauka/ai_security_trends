<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * All CREATE TABLE statements from PLAN.md §5.1, run through dbDelta() on
 * activation and on version-upgrade (Plugin::maybe_upgrade()). dbDelta()
 * requires a very specific formatting (two spaces after PRIMARY KEY, no
 * backticks around KEY names it must parse, etc.) — see the Plugin Handbook.
 */
final class Schema {

	public static function create_tables(): void {
		require_once ABSPATH . 'wp-admin/includes/upgrade.php';

		$charset_collate = self::charset_collate();

		// dbDelta()'s regex-based parser does not reliably handle FOREIGN KEY
		// or CHECK clauses embedded in a CREATE TABLE statement — it silently
		// drops or mangles them on some MySQL/MariaDB versions. Every table
		// is therefore created by dbDelta() with columns and KEYs only; the
		// FOREIGN KEY / CHECK constraints (including D-04's
		// chk_design_harm_has_no_severity) are added afterwards via a plain
		// ALTER TABLE, which MySQL executes exactly as written.
		foreach ( self::table_definitions( $charset_collate ) as $sql ) {
			dbDelta( $sql );
		}

		self::add_constraints();
	}

	private static function add_constraints(): void {
		global $wpdb;

		$p = $wpdb->prefix;

		self::add_constraint_if_missing(
			"{$p}sp_threats",
			'fk_threats_framework',
			"ALTER TABLE {$p}sp_threats ADD CONSTRAINT fk_threats_framework
                FOREIGN KEY (framework_id) REFERENCES {$p}sp_frameworks(id)"
		);

		self::add_constraint_if_missing(
			"{$p}sp_threat_translations",
			'fk_translations_threat',
			"ALTER TABLE {$p}sp_threat_translations ADD CONSTRAINT fk_translations_threat
                FOREIGN KEY (threat_id) REFERENCES {$p}sp_threats(id)"
		);

		self::add_constraint_if_missing(
			"{$p}sp_cards",
			'chk_design_harm_has_no_severity',
			"ALTER TABLE {$p}sp_cards ADD CONSTRAINT chk_design_harm_has_no_severity CHECK (
                (card_kind = 'design_harm'     AND severity IS NULL) OR
                (card_kind = 'technical_threat' AND severity IS NOT NULL)
            )"
		);

		self::add_constraint_if_missing(
			"{$p}sp_mitigations",
			'fk_mitigations_threat',
			"ALTER TABLE {$p}sp_mitigations ADD CONSTRAINT fk_mitigations_threat
                FOREIGN KEY (threat_id) REFERENCES {$p}sp_threats(id)"
		);

		self::add_constraint_if_missing(
			"{$p}sp_mitigations",
			'fk_mitigations_card',
			"ALTER TABLE {$p}sp_mitigations ADD CONSTRAINT fk_mitigations_card
                FOREIGN KEY (card_id) REFERENCES {$p}sp_cards(card_id)"
		);

		self::add_constraint_if_missing(
			"{$p}sp_code_samples",
			'fk_code_samples_mitigation',
			"ALTER TABLE {$p}sp_code_samples ADD CONSTRAINT fk_code_samples_mitigation
                FOREIGN KEY (mitigation_id) REFERENCES {$p}sp_mitigations(id)"
		);

		self::add_constraint_if_missing(
			"{$p}sp_cross_references",
			'fk_crossref_source',
			"ALTER TABLE {$p}sp_cross_references ADD CONSTRAINT fk_crossref_source
                FOREIGN KEY (source_threat_id) REFERENCES {$p}sp_threats(id)"
		);

		self::add_constraint_if_missing(
			"{$p}sp_cross_references",
			'fk_crossref_target',
			"ALTER TABLE {$p}sp_cross_references ADD CONSTRAINT fk_crossref_target
                FOREIGN KEY (target_threat_id) REFERENCES {$p}sp_threats(id)"
		);
	}

	private static function add_constraint_if_missing( string $table, string $constraint_name, string $alter_sql ): void {
		global $wpdb;

		$exists = $wpdb->get_var(
			$wpdb->prepare(
				'SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS
                 WHERE TABLE_SCHEMA = %s AND TABLE_NAME = %s AND CONSTRAINT_NAME = %s',
				DB_NAME,
				$table,
				$constraint_name
			)
		);

		if ( '0' === (string) $exists ) {
			$wpdb->query( $alter_sql ); // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- DDL, no user input; identifiers are hardcoded constants above.
		}
	}

	private static function charset_collate(): string {
		global $wpdb;

		return $wpdb->get_charset_collate();
	}

	/**
	 * @return string[]
	 */
	private static function table_definitions( string $charset_collate ): array {
		global $wpdb;

		$p = $wpdb->prefix;

		return array(
			"CREATE TABLE {$p}sp_frameworks (
                id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                code          VARCHAR(32)  NOT NULL,
                name          VARCHAR(200) NOT NULL,
                version       VARCHAR(20)  NOT NULL,
                description   TEXT NOT NULL,
                reference_url VARCHAR(500) NOT NULL,
                PRIMARY KEY  (id),
                UNIQUE KEY code (code)
            ) {$charset_collate};",

			"CREATE TABLE {$p}sp_threats (
                id             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                framework_id   BIGINT UNSIGNED NOT NULL,
                code           VARCHAR(40)  NOT NULL,
                title          VARCHAR(300) NOT NULL,
                severity       ENUM('critical','high','medium','low','info') NOT NULL,
                category       VARCHAR(100) NOT NULL,
                description    TEXT NOT NULL,
                attack_vector  TEXT NOT NULL,
                attack_surface TEXT NOT NULL,
                stride         VARCHAR(6)   NOT NULL DEFAULT '',
                tags           TEXT NOT NULL,
                PRIMARY KEY  (id),
                KEY framework_id (framework_id),
                KEY severity (severity)
            ) {$charset_collate};",

			"CREATE TABLE {$p}sp_threat_translations (
                id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                threat_id     BIGINT UNSIGNED NOT NULL,
                locale        ENUM('pl','en') NOT NULL,
                title         VARCHAR(300) NOT NULL,
                description   TEXT NOT NULL,
                attack_vector TEXT NOT NULL,
                PRIMARY KEY  (id),
                UNIQUE KEY uq_threat_locale (threat_id, locale)
            ) {$charset_collate};",

			"CREATE TABLE {$p}sp_cards (
                card_id           VARCHAR(10)  NOT NULL,
                suit_code         VARCHAR(10)  NOT NULL,
                suit_name         VARCHAR(100) NOT NULL,
                edition           VARCHAR(20)  NOT NULL,
                card_value        VARCHAR(2)   NOT NULL,
                is_critical       TINYINT(1)   NOT NULL DEFAULT 0,
                card_kind         ENUM('technical_threat','design_harm') NOT NULL,
                severity          ENUM('critical','high','medium','low','info') NULL,
                description_en    TEXT NOT NULL,
                description_pl    TEXT NOT NULL,
                misc_note         TEXT NULL,
                source_url        VARCHAR(500) NULL,
                owasp_refs        JSON NOT NULL,
                mitre_refs        JSON NOT NULL,
                content_sha256    CHAR(64) NOT NULL,
                PRIMARY KEY  (card_id),
                KEY idx_suit (suit_code),
                KEY idx_edition (edition),
                CONSTRAINT chk_design_harm_has_no_severity CHECK (
                    (card_kind = 'design_harm'     AND severity IS NULL) OR
                    (card_kind = 'technical_threat' AND severity IS NOT NULL)
                )
            ) {$charset_collate};",

			"CREATE TABLE {$p}sp_mitigations (
                id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                slug            VARCHAR(100) NOT NULL,
                threat_id       BIGINT UNSIGNED NULL,
                card_id         VARCHAR(10) NULL,
                title           VARCHAR(300) NOT NULL,
                description     TEXT NOT NULL,
                mitigation_type ENUM('preventive','detective','corrective','compensating') NOT NULL,
                effort          ENUM('low','medium','high') NOT NULL,
                effectiveness   ENUM('partial','significant','full') NOT NULL,
                PRIMARY KEY  (id),
                UNIQUE KEY slug (slug),
                KEY threat_id (threat_id),
                KEY card_id (card_id)
            ) {$charset_collate};",

			"CREATE TABLE {$p}sp_code_samples (
                id              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                mitigation_id   BIGINT UNSIGNED NOT NULL,
                language        ENUM('python','java','go','scala','lua') NOT NULL,
                sample_type     ENUM('attack_demo','defense') NOT NULL,
                title           VARCHAR(200) NOT NULL,
                description     TEXT NOT NULL,
                code            MEDIUMTEXT NOT NULL,
                framework_hint  VARCHAR(100) NOT NULL,
                version_note    VARCHAR(100) NOT NULL,
                PRIMARY KEY  (id),
                KEY mitigation_id (mitigation_id)
            ) {$charset_collate};",

			"CREATE TABLE {$p}sp_cross_references (
                id                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
                source_threat_id   BIGINT UNSIGNED NOT NULL,
                target_threat_id   BIGINT UNSIGNED NOT NULL,
                relationship_type  ENUM('equivalent','related','parent_child','maps_to') NOT NULL,
                description        TEXT NOT NULL,
                PRIMARY KEY  (id),
                KEY source_threat_id (source_threat_id),
                KEY target_threat_id (target_threat_id)
            ) {$charset_collate};",

			"CREATE TABLE {$p}sp_content_hashes (
                file_name    VARCHAR(100) NOT NULL,
                sha256_hash  CHAR(64)     NOT NULL,
                verified_at  DATETIME     NOT NULL,
                is_valid     TINYINT(1)   NOT NULL,
                verified_by  VARCHAR(30)  NOT NULL DEFAULT 'securepress-integrity-verifier',
                PRIMARY KEY  (file_name)
            ) {$charset_collate};",
		);
	}
}
