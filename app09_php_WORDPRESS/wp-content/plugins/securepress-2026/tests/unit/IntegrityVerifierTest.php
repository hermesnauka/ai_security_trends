<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use SecurePress\Integrity\Integrity_Verifier;
use WP_UnitTestCase;

final class IntegrityVerifierTest extends WP_UnitTestCase {

	public function test_all_six_decks_are_valid_against_committed_hashes(): void {
		$results = ( new Integrity_Verifier() )->verify();

		$this->assertCount( 6, $results );
		$this->assertNotContains( false, $results, 'every deck file should match data/hashes.json' );
	}

	public function test_all_valid_returns_true_when_every_deck_matches(): void {
		$this->assertTrue( ( new Integrity_Verifier() )->all_valid() );
	}

	public function test_verify_records_a_row_per_deck_in_sp_content_hashes(): void {
		global $wpdb;

		( new Integrity_Verifier() )->verify();

		$count = (int) $wpdb->get_var( "SELECT COUNT(*) FROM {$wpdb->prefix}sp_content_hashes" );

		$this->assertSame( 6, $count );
	}
}
