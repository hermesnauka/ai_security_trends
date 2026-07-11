<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * FR-17.1: MySQL FULLTEXT search via MATCH...AGAINST, always through
 * $wpdb->prepare() (D-02) — natural language mode, so a query with no
 * boolean operators behaves the way a plain search box user expects.
 */
final class Search_Repository {

	/**
	 * @return object[] rows with threat_id, code, title, framework_code, excerpt
	 */
	public function search_threats( string $query, string $locale ): array {
		global $wpdb;

		$threats = $wpdb->prefix . 'sp_threats';
		$fw      = $wpdb->prefix . 'sp_frameworks';

		return $wpdb->get_results(
			$wpdb->prepare(
				"SELECT t.id, t.code, t.title, t.description, f.code AS framework_code,
                        MATCH(t.title, t.description) AGAINST (%s IN NATURAL LANGUAGE MODE) AS relevance
                 FROM {$threats} t
                 INNER JOIN {$fw} f ON f.id = t.framework_id
                 WHERE MATCH(t.title, t.description) AGAINST (%s IN NATURAL LANGUAGE MODE)
                 ORDER BY relevance DESC
                 LIMIT 25", // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared -- table names interpolated, values parameterized below.
				$query,
				$query
			)
		);
	}

	/**
	 * @return object[] rows with card_id, description_en, description_pl, edition, suit_code
	 */
	public function search_cards( string $query ): array {
		global $wpdb;

		$cards = $wpdb->prefix . 'sp_cards';

		return $wpdb->get_results(
			$wpdb->prepare(
				"SELECT card_id, suit_code, edition, description_en, description_pl,
                        MATCH(description_en, description_pl) AGAINST (%s IN NATURAL LANGUAGE MODE) AS relevance
                 FROM {$cards}
                 WHERE MATCH(description_en, description_pl) AGAINST (%s IN NATURAL LANGUAGE MODE)
                 ORDER BY relevance DESC
                 LIMIT 25", // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
				$query,
				$query
			)
		);
	}
}
