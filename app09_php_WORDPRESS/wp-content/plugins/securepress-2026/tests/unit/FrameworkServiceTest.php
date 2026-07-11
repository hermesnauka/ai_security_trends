<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use SecurePress\Service\Framework_Service;
use WP_UnitTestCase;

final class FrameworkServiceTest extends WP_UnitTestCase {

	public function test_list_returns_at_least_eleven_seeded_frameworks(): void {
		$frameworks = ( new Framework_Service() )->list();

		$this->assertGreaterThanOrEqual( 11, count( $frameworks ) );
	}

	public function test_find_returns_owasp_llm_framework(): void {
		$framework = ( new Framework_Service() )->find( 'OWASP_LLM' );

		$this->assertNotNull( $framework );
		$this->assertSame( 'OWASP_LLM', $framework['code'] );
		$this->assertGreaterThanOrEqual( 10, $framework['threatCount'] );
	}

	public function test_find_returns_null_for_unknown_code(): void {
		$framework = ( new Framework_Service() )->find( 'NOT_A_REAL_FRAMEWORK' );

		$this->assertNull( $framework );
	}
}
