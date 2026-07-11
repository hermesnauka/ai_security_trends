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
		$search_controller    = new Search_Controller();
		$matrix_controller    = new Matrix_Controller();
		$export_controller    = new Export_Controller();

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
			'/search',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $search_controller, 'index' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/matrix/llm',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $matrix_controller, 'llm' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/matrix/agentic',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $matrix_controller, 'agentic' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/matrix/mobile-vs-web',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $matrix_controller, 'mobile_vs_web' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/stride-heatmap',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $matrix_controller, 'stride_heatmap' ),
				'permission_callback' => array( $this, 'require_trainer_capability' ),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/cross-references',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $matrix_controller, 'cross_references' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/export',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $export_controller, 'create' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
			)
		);

		register_rest_route(
			self::NAMESPACE,
			'/export/status/(?P<jobId>[A-Za-z0-9-]+)',
			array(
				'methods'             => WP_REST_Server::READABLE,
				'callback'            => array( $export_controller, 'status' ),
				'permission_callback' => array( $this, 'public_read_rate_limited' ),
				'args'                => array(
					'jobId' => array( 'required' => true, 'type' => 'string' ),
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

	/**
	 * SR-01.3: /stride-heatmap requires manage_securepress or securepress_trainer,
	 * not just being logged in — an anonymous request must get 401, not 403,
	 * per user_stories+tests.md's StrideHeatmapControllerTest expectation.
	 */
	public function require_trainer_capability(): bool|WP_Error {
		if ( ! is_user_logged_in() ) {
			return new WP_Error(
				'securepress_unauthorized',
				__( 'Authentication is required.', 'securepress-2026' ),
				array( 'status' => 401 )
			);
		}

		if ( ! current_user_can( 'manage_securepress' ) && ! current_user_can( 'securepress_trainer' ) ) {
			return new WP_Error(
				'securepress_forbidden',
				__( 'You do not have permission to view this resource.', 'securepress-2026' ),
				array( 'status' => 403 )
			);
		}

		return true;
	}

	private function client_ip(): string {
		$ip = isset( $_SERVER['REMOTE_ADDR'] ) ? sanitize_text_field( wp_unslash( $_SERVER['REMOTE_ADDR'] ) ) : '0.0.0.0';

		return $ip;
	}
}
