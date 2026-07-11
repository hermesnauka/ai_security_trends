<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use SecurePress\Service\Search_Service;
use WP_UnitTestCase;

final class SearchServiceTest extends WP_UnitTestCase {

	public function test_finds_prompt_injection_threat(): void {
		$results = ( new Search_Service() )->search( 'prompt injection' );

		$this->assertNotEmpty( $results['threats'] );

		$codes = array_map( fn( array $t ): string => $t['code'], $results['threats'] );
		$this->assertContains( 'LLM01:2025', $codes );
	}

	public function test_excerpt_highlights_matched_term(): void {
		$results = ( new Search_Service() )->search( 'injection' );

		$this->assertNotEmpty( $results['threats'] );
		$this->assertStringContainsString( '<mark>', $results['threats'][0]['excerpt'] );
	}

	public function test_no_match_returns_empty_arrays_not_an_error(): void {
		$results = ( new Search_Service() )->search( 'zzzznonexistentqueryzzzz' );

		$this->assertSame( array(), $results['threats'] );
		$this->assertSame( array(), $results['cards'] );
	}
}
