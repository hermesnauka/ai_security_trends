<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Code_Sample_Repository {

	public function upsert_seed( int $mitigation_id, string $language, string $sample_type, array $attributes ): void {
		global $wpdb;

		$table    = $wpdb->prefix . 'sp_code_samples';
		$existing = $this->find( $mitigation_id, $language, $sample_type );

		$data = array(
			'mitigation_id'  => $mitigation_id,
			'language'       => $language,
			'sample_type'    => $sample_type,
			'title'          => $attributes['title'],
			'description'    => $attributes['description'],
			'code'           => $attributes['code'],
			'framework_hint' => $attributes['framework_hint'],
			'version_note'   => $attributes['version_note'],
		);
		$formats = array( '%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s' );

		if ( null !== $existing ) {
			$wpdb->update( $table, $data, array( 'id' => $existing->id ), $formats, array( '%d' ) );
			return;
		}

		$wpdb->insert( $table, $data, $formats );
	}

	public function find( int $mitigation_id, string $language, string $sample_type ): ?object {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_code_samples';

		$row = $wpdb->get_row(
			$wpdb->prepare(
				"SELECT * FROM {$table} WHERE mitigation_id = %d AND language = %s AND sample_type = %s", // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
				$mitigation_id,
				$language,
				$sample_type
			)
		);

		return $row instanceof \stdClass ? $row : null;
	}

	public function by_mitigation_id( int $mitigation_id ): array {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_code_samples';

		return $wpdb->get_results(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE mitigation_id = %d ORDER BY language ASC, sample_type ASC", $mitigation_id ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);
	}
}
