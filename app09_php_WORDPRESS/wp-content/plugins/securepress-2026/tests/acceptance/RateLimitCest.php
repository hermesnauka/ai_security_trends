<?php

declare( strict_types = 1 );

use SecurePress\Tests\Support\AcceptanceTester;

final class RateLimitCest {

	public function bot_suit_is_rate_limited_after_60_requests_per_minute( AcceptanceTester $I ): void {
		for ( $i = 0; $i < 60; $i++ ) {
			$I->sendGET( '/wp-json/securepress/v1/threats?suit=bot' );
			$I->seeResponseCodeIs( 200 );
		}

		$I->sendGET( '/wp-json/securepress/v1/threats?suit=bot' );
		$I->seeResponseCodeIs( 429 );
		$I->seeHttpHeader( 'Retry-After' );
	}

	public function xmlrpc_is_disabled( AcceptanceTester $I ): void {
		$I->sendPOST( '/xmlrpc.php', '<?xml version="1.0"?><methodCall><methodName>demo.sayHello</methodName></methodCall>' );
		$I->dontSeeResponseCodeIs( 200 );
	}
}
