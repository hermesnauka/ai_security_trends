<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

use SecurePress\Data\Card_Repository;
use SecurePress\Data\Cross_Reference_Repository;
use SecurePress\Data\Framework_Repository;
use SecurePress\Data\Threat_Repository;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * PLAN.md §6 Phase 6 matrix pages. Every method here reflects only the data
 * actually seeded (§0.1's honesty principle applied to this phase): the LLM
 * and STRIDE matrices have real seeded data on both sides, while the Agentic
 * matrix and MASVS-vs-Web comparison are stated as partial rather than
 * quietly padded out with invented rows.
 */
final class Matrix_Service {

	private Threat_Repository $threats;
	private Framework_Repository $frameworks;
	private Card_Repository $cards;
	private Cross_Reference_Repository $cross_references;

	public function __construct(
		?Threat_Repository $threats = null,
		?Framework_Repository $frameworks = null,
		?Card_Repository $cards = null,
		?Cross_Reference_Repository $cross_references = null
	) {
		$this->threats          = $threats ?? new Threat_Repository();
		$this->frameworks       = $frameworks ?? new Framework_Repository();
		$this->cards            = $cards ?? new Card_Repository();
		$this->cross_references = $cross_references ?? new Cross_Reference_Repository();
	}

	/**
	 * FR-06.2: maps OWASP LLM Top 10 entries to Cornucopia LLM suit cards via
	 * each card's curated owasp_refs (D-08) — real data on both sides.
	 */
	public function llm(): array {
		$framework = $this->frameworks->by_code( 'OWASP_LLM' );
		$llm_cards = null !== $framework ? $this->cards->by_suit( 'llm' ) : array();

		$rows = array();
		foreach ( $this->llm_threats() as $threat ) {
			$matching = array_values(
				array_filter(
					$llm_cards,
					static function ( object $card ) use ( $threat ): bool {
						$refs = json_decode( $card->owasp_refs, true ) ?: array();
						return in_array( $threat->code, $refs, true );
					}
				)
			);

			$rows[] = array(
				'threatCode'  => $threat->code,
				'threatTitle' => $threat->title,
				'cardIds'     => array_map( static fn( object $c ): string => $c->card_id, $matching ),
			);
		}

		return array( 'rows' => $rows );
	}

	/**
	 * FR-07.2: compares OWASP Agentic AI Top 10 (2026) with OWASP LLM Top 10
	 * (2025) — requirements.md DR-01.4 documents that no Agentic AI Top 10
	 * threats are seeded yet, so this returns an honest empty-state alongside
	 * the AAI suit cards that DO exist, rather than fabricating rows.
	 */
	public function agentic(): array {
		$agentic_threats = $this->threats_for_framework( 'OWASP_AGENTIC' );
		$aai_cards       = $this->cards->by_suit( 'aai' );

		return array(
			'agenticThreatsSeeded' => count( $agentic_threats ),
			'aaiCardIds'           => array_map( static fn( object $c ): string => $c->card_id, $aai_cards ),
			'note'                 => count( $agentic_threats ) > 0
				? null
				: 'OWASP Agentic AI Top 10 threats are not yet seeded (requirements.md DR-01.4) — showing only the AAI suit cards.',
		);
	}

	/**
	 * FR-10.2: MASVS 2.0 categories (curated as owasp_refs on mobile cards)
	 * shown alongside OWASP Web Top 10 — a side-by-side juxtaposition, not a
	 * formal crosswalk, since no official MASVS<->Web-Top-10 mapping exists;
	 * the two frameworks cover different application layers.
	 */
	public function mobile_vs_web(): array {
		$mobile_cards = $this->cards->by_edition( 'mobileapp' );
		$by_category  = array();

		foreach ( $mobile_cards as $card ) {
			foreach ( json_decode( $card->owasp_refs, true ) ?: array() as $ref ) {
				if ( str_starts_with( $ref, 'MASVS-' ) ) {
					$by_category[ $ref ][] = $card->card_id;
				}
			}
		}

		return array(
			'masvsCategories' => $by_category,
			'webTop10'        => array_map(
				static fn( object $t ): array => array( 'code' => $t->code, 'title' => $t->title ),
				$this->threats_for_framework( 'OWASP_WEB' )
			),
		);
	}

	/**
	 * SR-01.3 (capability-gated): a simplified heatmap — count of curated
	 * STRIDE-suit cards per category — not "per system component" as
	 * PLAN.md's aspirational description reads, since this schema has no
	 * system-component entity to attach coverage to.
	 */
	public function stride_heatmap(): array {
		$categories = array( 'sp', 'ta', 're', 'id', 'ds', 'ep' );
		$heatmap    = array();

		foreach ( $categories as $suit ) {
			$heatmap[ strtoupper( $suit ) ] = count( $this->cards->by_suit( $suit ) );
		}

		return array( 'categories' => $heatmap );
	}

	public function cross_references( ?string $source_code ): array {
		if ( null === $source_code ) {
			return array_map( array( $this, 'cross_reference_row_to_array' ), $this->cross_references->all() );
		}

		$threat = $this->threats->by_code( $source_code );

		if ( null === $threat ) {
			return array();
		}

		return array_map(
			static fn( object $row ): array => array(
				'relationshipType' => $row->relationship_type,
				'description'      => $row->description,
				'targetCode'       => $row->target_code,
				'targetTitle'      => $row->target_title,
			),
			$this->cross_references->by_source_threat_id( (int) $threat->id )
		);
	}

	private function cross_reference_row_to_array( object $row ): array {
		return array(
			'sourceCode'       => $row->source_code,
			'sourceTitle'      => $row->source_title,
			'relationshipType' => $row->relationship_type,
			'description'      => $row->description,
			'targetCode'       => $row->target_code,
			'targetTitle'      => $row->target_title,
		);
	}

	private function llm_threats(): array {
		return $this->threats_for_framework( 'OWASP_LLM' );
	}

	private function threats_for_framework( string $framework_code ): array {
		$framework = $this->frameworks->by_code( $framework_code );

		return null !== $framework ? $this->threats->by_framework_id( (int) $framework->id ) : array();
	}
}
