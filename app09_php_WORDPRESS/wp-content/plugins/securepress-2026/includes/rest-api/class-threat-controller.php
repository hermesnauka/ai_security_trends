<?php

declare( strict_types = 1 );

namespace SecurePress\Rest_Api;

use SecurePress\Data\Threat_Filter;
use SecurePress\Service\Threat_Service;
use WP_Error;
use WP_REST_Request;
use WP_REST_Response;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Threat_Controller {

	private Threat_Service $service;

	public function __construct( ?Threat_Service $service = null ) {
		$this->service = $service ?? new Threat_Service();
	}

	public function index( WP_REST_Request $request ): WP_REST_Response|WP_Error {
		$query = (string) ( $request->get_param( 'q' ) ?? '' );

		// SR-05.3: reject overlong search input before it ever reaches a query.
		if ( strlen( $query ) > 200 ) {
			return new WP_Error(
				'securepress_query_too_long',
				__( 'Search query must be 200 characters or fewer.', 'securepress-2026' ),
				array( 'status' => 422 )
			);
		}

		$filter = Threat_Filter::from_request( $request );

		return new WP_REST_Response( $this->service->list( $filter ), 200 );
	}

	public function show( WP_REST_Request $request ): WP_REST_Response|WP_Error {
		$id     = (int) $request->get_param( 'id' );
		$threat = $this->service->find( $id );

		if ( null === $threat ) {
			return new WP_Error(
				'securepress_not_found',
				__( 'Threat not found.', 'securepress-2026' ),
				array( 'status' => 404 )
			);
		}

		return new WP_REST_Response( $threat, 200 );
	}
}
