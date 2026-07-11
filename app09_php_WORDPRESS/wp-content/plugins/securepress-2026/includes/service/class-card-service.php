<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

use SecurePress\Data\Card_Repository;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Card_Service {

	private Card_Repository $repository;

	public function __construct( ?Card_Repository $repository = null ) {
		$this->repository = $repository ?? new Card_Repository();
	}

	public function by_suit( string $suit_code, string $locale = 'en' ): array {
		return array_map(
			fn( object $row ): array => $this->to_array( $row, $locale ),
			$this->repository->by_suit( $suit_code )
		);
	}

	public function by_edition( string $edition, string $locale = 'en' ): array {
		return array_map(
			fn( object $row ): array => $this->to_array( $row, $locale ),
			$this->repository->by_edition( $edition )
		);
	}

	public function by_card_id( string $card_id, string $locale = 'en' ): ?array {
		$row = $this->repository->by_card_id( $card_id );

		return null === $row ? null : $this->to_array( $row, $locale );
	}

	/**
	 * @return string[]
	 */
	public function suits_by_edition( string $edition ): array {
		return $this->repository->suits_by_edition( $edition );
	}

	/**
	 * FR-19.2(b): a design_harm card's response never carries a `severity`
	 * key at all — not `severity: null`, an absent key — verified by
	 * CardControllerTest::test_digital_harms_suits_never_return_a_severity_value
	 * in user_stories+tests.md.
	 */
	private function to_array( object $row, string $locale ): array {
		$description = 'pl' === $locale && '' !== (string) $row->description_pl
			? $row->description_pl
			: $row->description_en;

		$card = array(
			'cardId'      => $row->card_id,
			'suitCode'    => $row->suit_code,
			'suitName'    => $row->suit_name,
			'edition'     => $row->edition,
			'cardValue'   => $row->card_value,
			'isCritical'  => (bool) $row->is_critical,
			'cardKind'    => $row->card_kind,
			'description' => $description,
			'miscNote'    => $row->misc_note,
			'sourceUrl'   => $row->source_url,
			'owaspRefs'   => json_decode( $row->owasp_refs, true ) ?: array(),
			'mitreRefs'   => json_decode( $row->mitre_refs, true ) ?: array(),
		);

		if ( 'design_harm' !== $row->card_kind ) {
			$card['severity'] = $row->severity;
		}

		return $card;
	}
}
