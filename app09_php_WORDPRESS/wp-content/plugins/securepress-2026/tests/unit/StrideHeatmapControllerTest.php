<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use WP_REST_Request;
use WP_UnitTestCase;

/**
 * SR-01.3: /stride-heatmap requires manage_securepress or securepress_trainer.
 * Anonymous gets 401 (not authenticated at all); a logged-in user without
 * either capability gets 403 (authenticated but not authorized) — these are
 * deliberately different statuses, asserted separately.
 */
final class StrideHeatmapControllerTest extends WP_UnitTestCase {

	public function test_anonymous_request_returns_401(): void {
		wp_set_current_user( 0 );

		$request  = new WP_REST_Request( 'GET', '/securepress/v1/stride-heatmap' );
		$response = rest_get_server()->dispatch( $request );

		$this->assertSame( 401, $response->get_status() );
	}

	public function test_logged_in_user_without_capability_returns_403(): void {
		$subscriber_id = self::factory()->user->create( array( 'role' => 'subscriber' ) );
		wp_set_current_user( $subscriber_id );

		$request  = new WP_REST_Request( 'GET', '/securepress/v1/stride-heatmap' );
		$response = rest_get_server()->dispatch( $request );

		$this->assertSame( 403, $response->get_status() );
	}

	public function test_administrator_returns_200(): void {
		$admin_id = self::factory()->user->create( array( 'role' => 'administrator' ) );
		wp_set_current_user( $admin_id );

		$request  = new WP_REST_Request( 'GET', '/securepress/v1/stride-heatmap' );
		$response = rest_get_server()->dispatch( $request );

		$this->assertSame( 200, $response->get_status() );
	}
}
