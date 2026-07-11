<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use SecurePress\Cards\Card_Loader;
use WP_UnitTestCase;

final class CardLoaderTest extends WP_UnitTestCase {

	public function test_deck_manifest_lists_all_six_decks(): void {
		$this->assertCount( 6, Card_Loader::deck_manifest() );
	}

	public function test_webapp_deck_cards_are_technical_threat_with_curated_severity(): void {
		$manifest = Card_Loader::deck_manifest()[0];
		$this->assertSame( 'webapp-cards-3.0-en.yaml', $manifest['file'] );

		$rows = ( new Card_Loader() )->load_deck( $manifest );
		$ve3  = current( array_filter( $rows, fn( array $r ): bool => 'VE3' === $r['card_id'] ) );

		$this->assertNotFalse( $ve3 );
		$this->assertSame( 'technical_threat', $ve3['card_kind'] );
		$this->assertNotNull( $ve3['severity'] );
	}

	/**
	 * D-04: card_kind/severity for the dbd deck are forced by the loader
	 * itself based on which file a card came from — never read from the raw
	 * YAML (which has no such field at all) or even from curation.
	 */
	public function test_dbd_deck_cards_are_design_harm_with_null_severity(): void {
		$manifest = current(
			array_filter( Card_Loader::deck_manifest(), fn( array $m ): bool => $m['design_harm'] )
		);

		$rows = ( new Card_Loader() )->load_deck( $manifest );
		$sco2 = current( array_filter( $rows, fn( array $r ): bool => 'SCO2' === $r['card_id'] ) );

		$this->assertNotFalse( $sco2 );
		$this->assertSame( 'design_harm', $sco2['card_kind'] );
		$this->assertNull( $sco2['severity'] );
	}

	public function test_face_card_values_are_marked_critical(): void {
		$manifest = current(
			array_filter( Card_Loader::deck_manifest(), fn( array $m ): bool => 'companion' === $m['edition'] )
		);

		$rows = ( new Card_Loader() )->load_deck( $manifest );
		$aaik = current( array_filter( $rows, fn( array $r ): bool => 'AAIK' === $r['card_id'] ) );

		$this->assertNotFalse( $aaik );
		$this->assertSame( 1, $aaik['is_critical'] );
	}
}
