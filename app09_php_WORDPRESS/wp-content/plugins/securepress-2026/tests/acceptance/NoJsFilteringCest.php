<?php

declare( strict_types = 1 );

use SecurePress\Tests\Support\AcceptanceTester;

/**
 * NFR-02.4: every filtering path must also work via a plain query-string
 * navigation, since JavaScript being disabled must never break the page —
 * this is the acceptance-level check for that specific guarantee.
 */
final class NoJsFilteringCest {

	public function filters_work_via_query_string_without_javascript( AcceptanceTester $I ): void {
		$I->amOnPage( '/threats/?framework=OWASP_LLM&severity=critical' );
		$I->see( 'LLM01' );
		$I->dontSee( 'LLM09' );
	}

	public function search_page_works_via_query_string_without_javascript( AcceptanceTester $I ): void {
		$I->amOnPage( '/search/?q=injection' );
		$I->see( 'A03:2021' );
	}
}
