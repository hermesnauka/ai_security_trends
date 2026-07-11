<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Cross_Reference_Repository {

	public function upsert_seed( int $source_id, int $target_id, string $relationship_type, string $description ): void {
		global $wpdb;

		$table    = $wpdb->prefix . 'sp_cross_references';
		$existing = $wpdb->get_var(
			$wpdb->prepare(
				"SELECT id FROM {$table} WHERE source_threat_id = %d AND target_threat_id = %d", // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
				$source_id,
				$target_id
			)
		);

		$data    = array(
			'source_threat_id'  => $source_id,
			'target_threat_id'  => $target_id,
			'relationship_type' => $relationship_type,
			'description'       => $description,
		);
		$formats = array( '%d', '%d', '%s', '%s' );

		if ( null !== $existing ) {
			$wpdb->update( $table, $data, array( 'id' => $existing ), $formats, array( '%d' ) );
			return;
		}

		$wpdb->insert( $table, $data, $formats );
	}

	/**
	 * @return object[] every cross-reference row, joined with both threats' code/title
	 */
	public function all(): array {
		global $wpdb;

		$cross = $wpdb->prefix . 'sp_cross_references';
		$t     = $wpdb->prefix . 'sp_threats';

		return $wpdb->get_results(
			"SELECT c.relationship_type, c.description,
                    src.code AS source_code, src.title AS source_title,
                    tgt.code AS target_code, tgt.title AS target_title
             FROM {$cross} c
             INNER JOIN {$t} src ON src.id = c.source_threat_id
             INNER JOIN {$t} tgt ON tgt.id = c.target_threat_id" // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- no user input, static query.
		);
	}

	/**
	 * @return object[] rows joined with the target threat's code/title
	 */
	public function by_source_threat_id( int $source_id ): array {
		global $wpdb;

		$cross = $wpdb->prefix . 'sp_cross_references';
		$t     = $wpdb->prefix . 'sp_threats';

		return $wpdb->get_results(
			$wpdb->prepare(
				"SELECT c.relationship_type, c.description, t.code AS target_code, t.title AS target_title
                 FROM {$cross} c INNER JOIN {$t} t ON t.id = c.target_threat_id
                 WHERE c.source_threat_id = %d", // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
				$source_id
			)
		);
	}
}
