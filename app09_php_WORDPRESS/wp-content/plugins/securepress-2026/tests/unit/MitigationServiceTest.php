<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use SecurePress\Service\Mitigation_Service;
use WP_UnitTestCase;

final class MitigationServiceTest extends WP_UnitTestCase {

	public function test_sql_injection_mitigation_has_all_five_languages(): void {
		$mitigations = ( new Mitigation_Service() )->for_threat_code( 'A03:2021' );

		$this->assertNotEmpty( $mitigations );

		$languages = array_unique(
			array_map( fn( array $s ): string => $s['language'], $mitigations[0]['codeSamples'] )
		);
		sort( $languages );

		$this->assertSame( array( 'go', 'java', 'lua', 'python', 'scala' ), $languages );
	}

	public function test_every_language_has_an_attack_demo_and_a_defense_sample(): void {
		$mitigations = ( new Mitigation_Service() )->for_threat_code( 'A03:2021' );
		$by_language = array();

		foreach ( $mitigations[0]['codeSamples'] as $sample ) {
			$by_language[ $sample['language'] ][] = $sample['sampleType'];
		}

		foreach ( $by_language as $language => $types ) {
			sort( $types );
			$this->assertSame( array( 'attack_demo', 'defense' ), $types, "language {$language}" );
		}
	}

	public function test_llm2_card_mitigation_has_lua_resty_limit_req_sample(): void {
		$mitigations = ( new Mitigation_Service() )->for_card_id( 'LLM2' );

		$this->assertNotEmpty( $mitigations );

		$lua_defense = array_values(
			array_filter(
				$mitigations[0]['codeSamples'],
				fn( array $s ): bool => 'lua' === $s['language'] && 'defense' === $s['sampleType']
			)
		)[0];

		$this->assertStringContainsString( 'lua-resty-limit-req', $lua_defense['code'] );
	}

	public function test_unknown_threat_code_returns_empty_array(): void {
		$this->assertSame( array(), ( new Mitigation_Service() )->for_threat_code( 'NOT-A-REAL-CODE' ) );
	}
}
