<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use SecurePress\Service\Rate_Limiter;
use WP_UnitTestCase;

final class RateLimiterTest extends WP_UnitTestCase {

	public function test_allows_up_to_the_limit_then_blocks(): void {
		$limiter = new Rate_Limiter();
		$ip      = '203.0.113.' . wp_rand( 1, 254 ); // unique per test run to avoid transient collisions

		for ( $i = 0; $i < 60; $i++ ) {
			$this->assertTrue( $limiter->is_allowed( $ip ), "request {$i} should be allowed" );
		}

		$this->assertFalse( $limiter->is_allowed( $ip ), 'the 61st request within the window should be blocked' );
	}

	public function test_different_ips_have_independent_limits(): void {
		$limiter = new Rate_Limiter();
		$ip_a    = '203.0.113.10';
		$ip_b    = '203.0.113.20';

		for ( $i = 0; $i < 60; $i++ ) {
			$limiter->is_allowed( $ip_a );
		}

		$this->assertFalse( $limiter->is_allowed( $ip_a ) );
		$this->assertTrue( $limiter->is_allowed( $ip_b ) );
	}
}
