<?php

declare( strict_types = 1 );

namespace SecurePress\Rest_Api;

use SecurePress\Service\Framework_Service;
use WP_Error;
use WP_REST_Request;
use WP_REST_Response;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Framework_Controller {

	private Framework_Service $service;

	public function __construct( ?Framework_Service $service = null ) {
		$this->service = $service ?? new Framework_Service();
	}

	public function index( WP_REST_Request $request ): WP_REST_Response {
		return new WP_REST_Response( $this->service->list(), 200 );
	}

	public function show( WP_REST_Request $request ): WP_REST_Response|WP_Error {
		$code       = (string) $request->get_param( 'code' );
		$framework  = $this->service->find( $code );

		if ( null === $framework ) {
			return new WP_Error(
				'securepress_not_found',
				__( 'Framework not found.', 'securepress-2026' ),
				array( 'status' => 404 )
			);
		}

		return new WP_REST_Response( $framework, 200 );
	}
}
