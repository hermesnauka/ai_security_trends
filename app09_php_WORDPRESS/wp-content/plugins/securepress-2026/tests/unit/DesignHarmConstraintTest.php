<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use WP_UnitTestCase;

/**
 * SR-08 / D-04: the single most-repeated claim in this project's docs is
 * that chk_design_harm_has_no_severity is enforced by the database engine
 * itself, independent of any PHP code path. This test is the one place that
 * claim is actually exercised — a raw $wpdb->query() bypassing every
 * repository/service/validator in this plugin, attempting exactly the
 * violation the constraint exists to reject.
 */
final class DesignHarmConstraintTest extends WP_UnitTestCase {

	public function test_mysql_rejects_design_harm_row_with_non_null_severity(): void {
		global $wpdb;

		$suppress_errors = $wpdb->suppress_errors( true );

		$result = $wpdb->query(
			$wpdb->prepare(
				"INSERT INTO {$wpdb->prefix}sp_cards
                 (card_id, suit_code, suit_name, edition, card_value, card_kind, severity,
                  description_en, description_pl, owasp_refs, mitre_refs, content_sha256)
                 VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
				'ZZTEST1', 'SCO', 'Scope', 'dbd', '2', 'design_harm', 'high',
				'test', 'test', '[]', '[]', str_repeat( '0', 64 )
			)
		);

		$wpdb->suppress_errors( $suppress_errors );

		$this->assertFalse( $result, 'MySQL should reject a design_harm row with a non-NULL severity.' );
		$this->assertStringContainsString( 'chk_design_harm_has_no_severity', (string) $wpdb->last_error );
	}

	public function test_mysql_accepts_design_harm_row_with_null_severity(): void {
		global $wpdb;

		$result = $wpdb->query(
			$wpdb->prepare(
				"INSERT INTO {$wpdb->prefix}sp_cards
                 (card_id, suit_code, suit_name, edition, card_value, card_kind, severity,
                  description_en, description_pl, owasp_refs, mitre_refs, content_sha256)
                 VALUES (%s, %s, %s, %s, %s, %s, NULL, %s, %s, %s, %s, %s)",
				'ZZTEST2', 'SCO', 'Scope', 'dbd', '3', 'design_harm',
				'test', 'test', '[]', '[]', str_repeat( '1', 64 )
			)
		);

		$this->assertNotFalse( $result );

		$wpdb->query( $wpdb->prepare( "DELETE FROM {$wpdb->prefix}sp_cards WHERE card_id = %s", 'ZZTEST2' ) );
	}
}
