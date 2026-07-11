<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * D-02: every query goes through $wpdb->prepare() with %s/%d placeholders.
 * This is a runtime-only guarantee — PHP has no compile-time query-shape
 * check equivalent to sqlc/hasql-th/sqlx::query! (PLAN.md D-02).
 */
final class Threat_Repository {

	public function search( Threat_Filter $filter ): array {
		global $wpdb;

		$table  = $wpdb->prefix . 'sp_threats';
		$fw     = $wpdb->prefix . 'sp_frameworks';
		$where  = array( '1=1' );
		$params = array();

		if ( null !== $filter->framework_code ) {
			$where[]  = "f.code = %s";
			$params[] = $filter->framework_code;
		}

		if ( null !== $filter->severity ) {
			$where[]  = 't.severity = %s';
			$params[] = $filter->severity;
		}

		if ( null !== $filter->stride ) {
			$where[]  = 't.stride = %s';
			$params[] = $filter->stride;
		}

		if ( null !== $filter->category ) {
			$where[]  = 't.category = %s';
			$params[] = $filter->category;
		}

		if ( null !== $filter->tag ) {
			$where[]  = 't.tags LIKE %s';
			$params[] = '%' . $wpdb->esc_like( $filter->tag ) . '%';
		}

		if ( null !== $filter->query ) {
			$where[]  = '(t.title LIKE %s OR t.description LIKE %s)';
			$like     = '%' . $wpdb->esc_like( $filter->query ) . '%';
			$params[] = $like;
			$params[] = $like;
		}

		$offset   = ( $filter->page - 1 ) * $filter->size;
		$params[] = $filter->size;
		$params[] = $offset;

		$sql = "SELECT t.*, f.code AS framework_code FROM {$table} t
                INNER JOIN {$fw} f ON f.id = t.framework_id
                WHERE " . implode( ' AND ', $where ) . '
                ORDER BY FIELD(t.severity, \'critical\',\'high\',\'medium\',\'low\',\'info\'), t.code ASC
                LIMIT %d OFFSET %d';

		return $wpdb->get_results( $wpdb->prepare( $sql, ...$params ) ); // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- built via prepare() above with positional placeholders.
	}

	public function count( Threat_Filter $filter ): int {
		global $wpdb;

		$table  = $wpdb->prefix . 'sp_threats';
		$fw     = $wpdb->prefix . 'sp_frameworks';
		$where  = array( '1=1' );
		$params = array();

		if ( null !== $filter->framework_code ) {
			$where[]  = 'f.code = %s';
			$params[] = $filter->framework_code;
		}

		if ( null !== $filter->severity ) {
			$where[]  = 't.severity = %s';
			$params[] = $filter->severity;
		}

		$sql = "SELECT COUNT(*) FROM {$table} t
                INNER JOIN {$fw} f ON f.id = t.framework_id
                WHERE " . implode( ' AND ', $where );

		if ( array() === $params ) {
			return (int) $wpdb->get_var( $sql ); // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- static SQL, no params to bind.
		}

		return (int) $wpdb->get_var( $wpdb->prepare( $sql, ...$params ) ); // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
	}

	public function by_id( int $id ): ?object {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_threats';

		$row = $wpdb->get_row(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE id = %d", $id ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);

		return $row instanceof \stdClass ? $row : null;
	}

	public function insert_seed_threat( int $framework_id, array $attributes ): int {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_threats';

		$wpdb->insert(
			$table,
			array(
				'framework_id'   => $framework_id,
				'code'           => $attributes['code'],
				'title'          => $attributes['title'],
				'severity'       => $attributes['severity'],
				'category'       => $attributes['category'],
				'description'    => $attributes['description'],
				'attack_vector'  => $attributes['attack_vector'],
				'attack_surface' => $attributes['attack_surface'],
				'stride'         => $attributes['stride'] ?? '',
				'tags'           => wp_json_encode( $attributes['tags'] ?? array() ),
			),
			array( '%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s' )
		);

		return (int) $wpdb->insert_id;
	}

	public function code_exists( string $code ): bool {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_threats';

		return null !== $wpdb->get_var(
			$wpdb->prepare( "SELECT id FROM {$table} WHERE code = %s", $code ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);
	}
}
