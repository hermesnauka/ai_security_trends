<?php

declare( strict_types = 1 );

namespace SecurePress\Rest_Api;

use SecurePress\Service\Matrix_Service;
use WP_REST_Request;
use WP_REST_Response;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Matrix_Controller {

	private Matrix_Service $service;

	public function __construct( ?Matrix_Service $service = null ) {
		$this->service = $service ?? new Matrix_Service();
	}

	public function llm(): WP_REST_Response {
		return new WP_REST_Response( $this->service->llm(), 200 );
	}

	public function agentic(): WP_REST_Response {
		return new WP_REST_Response( $this->service->agentic(), 200 );
	}

	public function mobile_vs_web(): WP_REST_Response {
		return new WP_REST_Response( $this->service->mobile_vs_web(), 200 );
	}

	public function stride_heatmap(): WP_REST_Response {
		return new WP_REST_Response( $this->service->stride_heatmap(), 200 );
	}

	public function cross_references( WP_REST_Request $request ): WP_REST_Response {
		$source_code = $request->get_param( 'sourceCode' );
		$source_code = is_string( $source_code ) && '' !== $source_code ? $source_code : null;

		return new WP_REST_Response( $this->service->cross_references( $source_code ), 200 );
	}
}
