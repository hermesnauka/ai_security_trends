<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Mitigation_Repository {

	public function upsert_seed( string $slug, array $attributes ): int {
		global $wpdb;

		$table    = $wpdb->prefix . 'sp_mitigations';
		$existing = $this->by_slug( $slug );

		$data = array(
			'slug'            => $slug,
			'threat_id'       => $attributes['threat_id'],
			'card_id'         => $attributes['card_id'],
			'title'           => $attributes['title'],
			'description'     => $attributes['description'],
			'mitigation_type' => $attributes['mitigation_type'],
			'effort'          => $attributes['effort'],
			'effectiveness'   => $attributes['effectiveness'],
		);
		$formats = array( '%s', '%d', '%s', '%s', '%s', '%s', '%s', '%s' );

		if ( null !== $existing ) {
			$wpdb->update( $table, $data, array( 'id' => $existing->id ), $formats, array( '%d' ) );
			return (int) $existing->id;
		}

		$wpdb->insert( $table, $data, $formats );

		return (int) $wpdb->insert_id;
	}

	public function by_slug( string $slug ): ?object {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_mitigations';

		$row = $wpdb->get_row(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE slug = %s", $slug ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);

		return $row instanceof \stdClass ? $row : null;
	}

	public function by_id( int $id ): ?object {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_mitigations';

		$row = $wpdb->get_row(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE id = %d", $id ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);

		return $row instanceof \stdClass ? $row : null;
	}

	public function by_threat_id( int $threat_id ): array {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_mitigations';

		return $wpdb->get_results(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE threat_id = %d", $threat_id ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);
	}

	public function by_card_id( string $card_id ): array {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_mitigations';

		return $wpdb->get_results(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE card_id = %s", $card_id ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);
	}
}
