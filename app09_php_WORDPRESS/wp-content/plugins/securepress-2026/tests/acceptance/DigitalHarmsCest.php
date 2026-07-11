<?php

declare( strict_types = 1 );

use SecurePress\Tests\Support\AcceptanceTester;

final class DigitalHarmsCest {

	public function shows_all_five_suits_and_disclaimer( AcceptanceTester $I ): void {
		$I->amOnPage( '/frameworks/digital-harms/' );
		$I->see( 'nie jest listą podatności technicznych' );

		foreach ( array( 'sco', 'arc', 'age', 'tru', 'por' ) as $suit ) {
			$I->seeElement( "[data-testid='{$suit}-section']" );
		}
	}

	public function never_shows_severity_badge_on_a_dbd_card( AcceptanceTester $I ): void {
		$I->amOnPage( '/frameworks/digital-harms/' );
		$I->seeElement( '[data-testid="card-SCO2"] [data-testid="design-harm-badge"]' );
		$I->dontSeeElement( '[data-testid="card-SCO2"] [data-testid="severity-badge"]' );
	}

	public function polish_translation_is_shown_for_sco2( AcceptanceTester $I ): void {
		$I->amOnPage( '/frameworks/digital-harms/?lang=pl' );
		$I->see( 'Tommy nie tworzy' );
	}
}
