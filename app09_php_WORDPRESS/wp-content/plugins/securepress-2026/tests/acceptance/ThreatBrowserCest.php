<?php

declare( strict_types = 1 );

use SecurePress\Tests\Support\AcceptanceTester;

final class ThreatBrowserCest {

	public function filters_update_results_without_full_reload( AcceptanceTester $I ): void {
		$I->amOnPage( '/threats/' );
		$I->fillField( '#threat-search', 'prompt injection' );
		$I->waitForElement( '[data-testid="threat-result"]' );
		$I->see( 'LLM01' );
	}

	public function severity_filter_narrows_results( AcceptanceTester $I ): void {
		$I->amOnPage( '/threats/?framework=OWASP_LLM&severity=critical' );
		$I->see( 'LLM01' );
		$I->dontSee( 'LLM09' );
	}
}
