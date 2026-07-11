<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use SecurePress\Service\Matrix_Service;
use WP_UnitTestCase;

final class MatrixServiceTest extends WP_UnitTestCase {

	public function test_llm_matrix_maps_llm10_to_card_llm2(): void {
		$matrix = ( new Matrix_Service() )->llm();

		$row = array_values(
			array_filter( $matrix['rows'], fn( array $r ): bool => 'LLM10:2025' === $r['threatCode'] )
		)[0];

		$this->assertContains( 'LLM2', $row['cardIds'] );
	}

	/**
	 * requirements.md DR-01.4: no OWASP Agentic AI Top 10 threats are seeded
	 * yet — this must be reported honestly, not silently show zero rows as
	 * if the comparison were simply empty by coincidence.
	 */
	public function test_agentic_matrix_reports_zero_seeded_threats_with_a_note(): void {
		$agentic = ( new Matrix_Service() )->agentic();

		$this->assertSame( 0, $agentic['agenticThreatsSeeded'] );
		$this->assertNotNull( $agentic['note'] );
		$this->assertNotEmpty( $agentic['aaiCardIds'] );
	}

	public function test_stride_heatmap_has_exactly_six_categories(): void {
		$heatmap = ( new Matrix_Service() )->stride_heatmap();

		$this->assertCount( 6, $heatmap['categories'] );
	}

	public function test_cross_references_by_source_code_llm01_maps_related(): void {
		$refs = ( new Matrix_Service() )->cross_references( 'A03:2021' );

		$this->assertNotEmpty( $refs );
		$codes = array_map( fn( array $r ): string => $r['targetCode'], $refs );
		$this->assertContains( 'LLM01:2025', $codes );
	}
}
