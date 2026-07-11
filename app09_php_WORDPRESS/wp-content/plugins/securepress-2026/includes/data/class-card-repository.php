<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * D-07: this class exposes no update/delete path reachable from any REST
 * route or admin screen — upsert() is called only from Card_Loader-driven
 * ingestion (activation hook + Reingest_Deck_Job), verified by code review
 * and a CI grep for INSERT/UPDATE against sp_cards outside includes/cards
 * and includes/cron (PLAN.md D-07).
 */
final class Card_Repository {

	public function upsert( array $row ): void {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_cards';

		$data = array(
			'suit_code'      => $row['suit_code'],
			'suit_name'      => $row['suit_name'],
			'edition'        => $row['edition'],
			'card_value'     => $row['card_value'],
			'is_critical'    => $row['is_critical'],
			'card_kind'      => $row['card_kind'],
			'severity'       => $row['severity'],
			'description_en' => $row['description_en'],
			'description_pl' => $row['description_pl'],
			'misc_note'      => $row['misc_note'],
			'source_url'     => $row['source_url'],
			'owasp_refs'     => wp_json_encode( $row['owasp_refs'] ),
			'mitre_refs'     => wp_json_encode( $row['mitre_refs'] ),
			'content_sha256' => $row['content_sha256'],
		);

		$formats = array( '%s', '%s', '%s', '%s', '%d', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s', '%s' );

		if ( null !== $this->by_card_id( $row['card_id'] ) ) {
			$wpdb->update( $table, $data, array( 'card_id' => $row['card_id'] ), $formats, array( '%s' ) );
			return;
		}

		$data['card_id'] = $row['card_id'];
		$wpdb->insert( $table, $data, array( ...$formats, '%s' ) );
	}

	public function by_card_id( string $card_id ): ?object {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_cards';

		$row = $wpdb->get_row(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE card_id = %s", $card_id ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);

		return $row instanceof \stdClass ? $row : null;
	}

	public function by_suit( string $suit_code ): array {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_cards';

		return $wpdb->get_results(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE suit_code = %s ORDER BY card_value ASC", strtoupper( $suit_code ) ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);
	}

	public function by_edition( string $edition ): array {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_cards';

		return $wpdb->get_results(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE edition = %s ORDER BY suit_code ASC, card_value ASC", $edition ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);
	}

	public function suits_by_edition( string $edition ): array {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_cards';

		$suits = $wpdb->get_col(
			$wpdb->prepare( "SELECT DISTINCT suit_code FROM {$table} WHERE edition = %s ORDER BY suit_code ASC", $edition ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);

		return array_map( 'strtolower', $suits );
	}
}
