<?php

declare( strict_types = 1 );

namespace SecurePress\Rest_Api;

use SecurePress\Service\Search_Service;
use WP_Error;
use WP_REST_Request;
use WP_REST_Response;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Search_Controller {

	private Search_Service $service;

	public function __construct( ?Search_Service $service = null ) {
		$this->service = $service ?? new Search_Service();
	}

	public function index( WP_REST_Request $request ): WP_REST_Response|WP_Error {
		$query = (string) ( $request->get_param( 'q' ) ?? '' );

		// SR-05.3: same 200-character cap as the threats list route.
		if ( strlen( $query ) > 200 ) {
			return new WP_Error(
				'securepress_query_too_long',
				__( 'Search query must be 200 characters or fewer.', 'securepress-2026' ),
				array( 'status' => 422 )
			);
		}

		if ( '' === trim( $query ) ) {
			return new WP_Error(
				'securepress_query_required',
				__( 'A search query is required.', 'securepress-2026' ),
				array( 'status' => 422 )
			);
		}

		$requested = (string) ( $request->get_param( 'lang' ) ?? '' );
		$locale    = in_array( $requested, array( 'pl', 'en' ), true ) ? $requested : 'en';

		return new WP_REST_Response( $this->service->search( $query, $locale ), 200 );
	}
}
