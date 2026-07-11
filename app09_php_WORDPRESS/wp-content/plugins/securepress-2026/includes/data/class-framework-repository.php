<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Framework_Repository {

	public function all(): array {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_frameworks';

		return $wpdb->get_results( "SELECT * FROM {$table} ORDER BY name ASC" ); // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- no user input, table name only.
	}

	public function by_code( string $code ): ?object {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_frameworks';

		$row = $wpdb->get_row(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE code = %s", $code ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- table name interpolated, value parameterized.
		);

		return $row instanceof \stdClass ? $row : null;
	}

	public function threat_count( int $framework_id ): int {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_threats';

		return (int) $wpdb->get_var(
			$wpdb->prepare( "SELECT COUNT(*) FROM {$table} WHERE framework_id = %d", $framework_id ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);
	}

	public function upsert( string $code, string $name, string $version, string $description, string $reference_url ): void {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_frameworks';

		$existing = $this->by_code( $code );

		if ( null !== $existing ) {
			$wpdb->update(
				$table,
				array(
					'name'          => $name,
					'version'       => $version,
					'description'   => $description,
					'reference_url' => $reference_url,
				),
				array( 'code' => $code ),
				array( '%s', '%s', '%s', '%s' ),
				array( '%s' )
			);

			return;
		}

		$wpdb->insert(
			$table,
			array(
				'code'          => $code,
				'name'          => $name,
				'version'       => $version,
				'description'   => $description,
				'reference_url' => $reference_url,
			),
			array( '%s', '%s', '%s', '%s', '%s' )
		);
	}
}
