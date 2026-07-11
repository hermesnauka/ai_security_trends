<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * FR-18.4: threat title/description/attack_vector served per-locale from
 * sp_threat_translations, distinct from D-05's UI-string i18n. Only 'pl' rows
 * are ever stored — 'en' content already lives on sp_threats itself, and
 * FR-18.6's missing-translation fallback is exactly "use that English row",
 * so seeding an identical 'en' row here would be redundant, not additive.
 */
final class Threat_Translation_Repository {

	public function upsert( int $threat_id, string $locale, array $attributes ): void {
		global $wpdb;

		$table    = $wpdb->prefix . 'sp_threat_translations';
		$existing = $this->by_threat_and_locale( $threat_id, $locale );

		$data = array(
			'threat_id'     => $threat_id,
			'locale'        => $locale,
			'title'         => $attributes['title'],
			'description'   => $attributes['description'],
			'attack_vector' => $attributes['attack_vector'],
		);
		$formats = array( '%d', '%s', '%s', '%s', '%s' );

		if ( null !== $existing ) {
			$wpdb->update( $table, $data, array( 'id' => $existing->id ), $formats, array( '%d' ) );
			return;
		}

		$wpdb->insert( $table, $data, $formats );
	}

	public function by_threat_and_locale( int $threat_id, string $locale ): ?object {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_threat_translations';

		$row = $wpdb->get_row(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE threat_id = %d AND locale = %s", $threat_id, $locale ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);

		return $row instanceof \stdClass ? $row : null;
	}
}
