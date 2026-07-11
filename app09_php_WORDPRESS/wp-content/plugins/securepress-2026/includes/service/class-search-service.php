<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

use SecurePress\Data\Search_Repository;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * FR-17.2: results grouped by type (threats, cards) with a highlighted
 * excerpt around the first match — <mark> is added here, server-side,
 * against already-escaped-on-output text (the caller must still esc_html()
 * anything except the deliberately-injected <mark>...</mark> tags).
 */
final class Search_Service {

	private Search_Repository $repository;

	public function __construct( ?Search_Repository $repository = null ) {
		$this->repository = $repository ?? new Search_Repository();
	}

	public function search( string $query, string $locale = 'en' ): array {
		$threat_rows = $this->repository->search_threats( $query, $locale );
		$card_rows   = $this->repository->search_cards( $query );

		return array(
			'threats' => array_map(
				fn( object $row ): array => array(
					'id'            => (int) $row->id,
					'code'          => $row->code,
					'title'         => $row->title,
					'frameworkCode' => $row->framework_code,
					'excerpt'       => $this->highlight_excerpt( $row->description, $query ),
				),
				$threat_rows
			),
			'cards'   => array_map(
				function ( object $row ) use ( $locale ): array {
					$description = 'pl' === $locale && '' !== (string) $row->description_pl
						? $row->description_pl
						: $row->description_en;

					return array(
						'cardId'   => $row->card_id,
						'suitCode' => $row->suit_code,
						'edition'  => $row->edition,
						'excerpt'  => $this->highlight_excerpt( $description, $query ),
					);
				},
				$card_rows
			),
		);
	}

	private function highlight_excerpt( string $text, string $query, int $context_chars = 80 ): string {
		$terms = array_filter( preg_split( '/\s+/', trim( $query ) ) ?: array() );
		$pos   = false;

		foreach ( $terms as $term ) {
			$found = mb_stripos( $text, $term );
			if ( false !== $found && ( false === $pos || $found < $pos ) ) {
				$pos = $found;
			}
		}

		if ( false === $pos ) {
			$excerpt = mb_substr( $text, 0, $context_chars * 2 );
			return esc_html( $excerpt ) . ( mb_strlen( $text ) > $context_chars * 2 ? '…' : '' );
		}

		$start   = max( 0, $pos - $context_chars );
		$length  = $context_chars * 2;
		$excerpt = mb_substr( $text, $start, $length );

		// Escape once, then wrap matches in <mark> — the matched substring is
		// already-escaped text at this point, so it must not be re-escaped.
		$highlighted = preg_replace_callback(
			'/(' . implode( '|', array_map( fn( string $t ): string => preg_quote( $t, '/' ), $terms ) ) . ')/iu',
			static fn( array $m ): string => '<mark>' . $m[0] . '</mark>',
			esc_html( $excerpt )
		);

		return ( $start > 0 ? '…' : '' ) . $highlighted . ( $start + $length < mb_strlen( $text ) ? '…' : '' );
	}
}
