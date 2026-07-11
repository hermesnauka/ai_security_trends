<?php

declare( strict_types = 1 );

namespace SecurePress\Rest_Api;

use SecurePress\Data\Threat_Filter;
use SecurePress\Service\Card_Service;
use SecurePress\Service\Threat_Service;
use WP_Error;
use WP_REST_Request;
use WP_REST_Response;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * PLAN.md §7 unifies technical threats and Cornucopia cards under the same
 * /threats route (FR-02.1: "a unified... list shall cover all threats and
 * all Cornucopia cards") — a `suit`/`edition` param routes this endpoint to
 * Card_Service instead of Threat_Service, rather than adding a parallel
 * /cards endpoint that would fork the API surface FR-02.1 says to unify.
 */
final class Threat_Controller {

	private Threat_Service $service;
	private Card_Service $card_service;

	public function __construct( ?Threat_Service $service = null, ?Card_Service $card_service = null ) {
		$this->service      = $service ?? new Threat_Service();
		$this->card_service = $card_service ?? new Card_Service();
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

		$suit    = $request->get_param( 'suit' );
		$edition = $request->get_param( 'edition' );
		$locale  = $this->locale_from_request( $request );

		if ( is_string( $suit ) && '' !== $suit ) {
			$cards = $this->card_service->by_suit( $suit, $locale );

			return new WP_REST_Response(
				array( 'content' => $cards, 'totalElements' => count( $cards ) ),
				200
			);
		}

		if ( is_string( $edition ) && '' !== $edition ) {
			$cards = $this->card_service->by_edition( $edition, $locale );

			return new WP_REST_Response(
				array( 'content' => $cards, 'totalElements' => count( $cards ) ),
				200
			);
		}

		$filter = Threat_Filter::from_request( $request );

		return new WP_REST_Response( $this->service->list( $filter ), 200 );
	}

	/**
	 * SR-13.1: `?lang=` is allowlisted to pl/en; anything else falls back to
	 * the site default rather than being passed through to a query.
	 */
	private function locale_from_request( WP_REST_Request $request ): string {
		$requested = (string) ( $request->get_param( 'lang' ) ?? '' );

		if ( in_array( $requested, array( 'pl', 'en' ), true ) ) {
			return $requested;
		}

		return str_starts_with( get_locale(), 'en' ) ? 'en' : 'pl';
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
