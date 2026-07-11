<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use SecurePress\Service\Card_Service;
use WP_UnitTestCase;

final class CardServiceTest extends WP_UnitTestCase {

	public function test_ve3_cross_references_a03(): void {
		$card = ( new Card_Service() )->by_card_id( 'VE3' );

		$this->assertNotNull( $card );
		$this->assertContains( 'A03:2021', $card['owaspRefs'] );
	}

	public function test_aaik_is_flagged_critical_by_card_value(): void {
		$card = ( new Card_Service() )->by_card_id( 'AAIK' );

		$this->assertNotNull( $card );
		$this->assertTrue( $card['isCritical'] );
	}

	public function test_emr2_has_no_owasp_ref_but_has_misc_note(): void {
		$card = ( new Card_Service() )->by_card_id( 'EMR2' );

		$this->assertNotNull( $card );
		$this->assertSame( array(), $card['owaspRefs'] );
		$this->assertNotNull( $card['miscNote'] );
	}

	/**
	 * FR-19.2(b): the digital-harms deck's cards must never carry a
	 * `severity` key at all — not `severity: null`, an absent key.
	 */
	public function test_design_harm_card_response_never_has_severity_key(): void {
		$card = ( new Card_Service() )->by_card_id( 'SCO2' );

		$this->assertNotNull( $card );
		$this->assertSame( 'design_harm', $card['cardKind'] );
		$this->assertArrayNotHasKey( 'severity', $card );
		$this->assertContains( 'A04:2021', $card['owaspRefs'] );
	}

	public function test_technical_threat_card_response_has_severity_key(): void {
		$card = ( new Card_Service() )->by_card_id( 'VE3' );

		$this->assertNotNull( $card );
		$this->assertArrayHasKey( 'severity', $card );
		$this->assertNotNull( $card['severity'] );
	}

	public function test_by_suit_returns_only_that_suit(): void {
		$cards = ( new Card_Service() )->by_suit( 'sco' );

		$this->assertNotEmpty( $cards );
		foreach ( $cards as $card ) {
			$this->assertSame( 'SCO', $card['suitCode'] );
		}
	}

	public function test_pl_locale_returns_reviewed_translation(): void {
		$card = ( new Card_Service() )->by_card_id( 'FRE4', 'pl' );

		$this->assertNotNull( $card );
		$this->assertStringContainsString( 'James', $card['description'] );
	}
}
