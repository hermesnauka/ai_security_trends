<?php

declare( strict_types = 1 );

use SecurePress\Tests\Support\AcceptanceTester;

/**
 * FR-03.4/SR-12.3: attack-demo code must not be visible until the user
 * explicitly confirms — implemented as a native <details>/<summary>
 * disclosure (see single-threat.php), not a JS-only <dialog>, specifically
 * so this gate also holds with JavaScript disabled.
 */
final class AttackDemoConfirmationCest {

	public function does_not_show_attack_demo_code_before_confirmation( AcceptanceTester $I ): void {
		$I->amOnPage( '/threats/?framework=A03:2021' );
		$I->click( '.securepress-threat-card a' );
		$I->dontSeeElement( '[data-testid="attack-demo-code-body"]:not([hidden])' );
	}

	public function shows_attack_demo_code_after_clicking_the_summary( AcceptanceTester $I ): void {
		$I->amOnPage( '/threats/?framework=A03:2021' );
		$I->click( '.securepress-threat-card a' );
		$I->click( '.securepress-attack-demo-label' );
		$I->see( 'VULNERABLE' );
	}
}
