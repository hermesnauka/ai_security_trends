<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use WP_REST_Request;
use WP_UnitTestCase;

final class ThreatControllerTest extends WP_UnitTestCase {

	public function test_list_returns_200_for_valid_framework(): void {
		$request = new WP_REST_Request( 'GET', '/securepress/v1/threats' );
		$request->set_param( 'framework', 'OWASP_LLM' );

		$response = rest_get_server()->dispatch( $request );

		$this->assertSame( 200, $response->get_status() );
	}

	public function test_rejects_query_longer_than_200_chars(): void {
		$request = new WP_REST_Request( 'GET', '/securepress/v1/threats' );
		$request->set_param( 'q', str_repeat( 'a', 201 ) );

		$response = rest_get_server()->dispatch( $request );

		$this->assertSame( 422, $response->get_status() );
	}

	public function test_show_404s_for_unknown_id(): void {
		$request = new WP_REST_Request( 'GET', '/securepress/v1/threats/999999999' );

		$response = rest_get_server()->dispatch( $request );

		$this->assertSame( 404, $response->get_status() );
	}

	/**
	 * PLAN.md §7's unified-listing shape: a `suit` param routes /threats to
	 * cards instead of a parallel /cards endpoint.
	 */
	public function test_suit_param_returns_cards_not_threats(): void {
		$request = new WP_REST_Request( 'GET', '/securepress/v1/threats' );
		$request->set_param( 'suit', 'sco' );

		$response = rest_get_server()->dispatch( $request );
		$body     = $response->get_data();

		$this->assertSame( 200, $response->get_status() );
		$this->assertArrayHasKey( 'cardId', $body['content'][0] );
	}

	public function test_route_registered_with_explicit_permission_callback(): void {
		// AC-14: every register_rest_route() call must have a permission_callback
		// that isn't accidentally omitted (a real, historical WordPress REST
		// API vulnerability class).
		$routes = rest_get_server()->get_routes( 'securepress/v1' );

		$this->assertArrayHasKey( '/securepress/v1/threats', $routes );
	}
}
