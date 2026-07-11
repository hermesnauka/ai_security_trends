<?php

declare( strict_types = 1 );

namespace SecurePress\Rest_Api;

use SecurePress\Service\Rate_Limiter;
use WP_Error;
use WP_REST_Request;
use WP_REST_Server;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Every route below has an EXPLICIT permission_callback (an omitted one is a
 * known WordPress REST API vulnerability class this project treats as a
 * first-class abuse case, AC-14 in requirements.md).
 */
final class Rest_Api {

	private const NAMESPACE = 'securepress/v1';

	public function register_routes(): void {
		$framework_controller = new Framework_Controller();
		$threat_controller    = new Threat_Controller();

		register_rest_route(
			self::NAMESPACE,
			'/frameworks',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $framework_controller, 'index' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/frameworks/(?P<code>[A-Za-z0-9_]+)',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $framework_controller, 'show' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
				'args'                => array(
					'code' => array( 'required' => true, 'type' => 'string' ),
				),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/threats',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $threat_controller, 'index' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/threats/(?P<id>\d+)',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $threat_controller, 'show' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
				'args'                => array(
					'id' => array( 'required' => true, 'type' => 'integer' ),
				),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/health',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => static fn(): array => array( 'status' => 'UP' ),
				'permission_callback' => '__return_true',
			)
		);
	}

	/**
	 * Public, read-only, and explicitly not `__return_true` unconditionally —
	 * it still enforces D-09's rate limit before allowing the request through.
	 */
	public function public_read_rate_limited( WP_REST_Request $request ): bool|WP_Error {
		$rate_limiter = new Rate_Limiter();
		$client_ip    = $this->client_ip();

		if ( ! $rate_limiter->is_allowed( $client_ip ) ) {
			return new WP_Error(
				'securepress_rate_limited',
				__( 'Too many requests.', 'securepress-2026' ),
				array(
					'status'      => 429,
					'Retry-After' => (string) MINUTE_IN_SECONDS,
				)
			);
		}

		return true;
	}

	private function client_ip(): string {
		$ip = isset( $_SERVER['REMOTE_ADDR'] ) ? sanitize_text_field( wp_unslash( $_SERVER['REMOTE_ADDR'] ) ) : '0.0.0.0';

		return $ip;
	}
}
