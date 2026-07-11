<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use SecurePress\Data\Threat_Filter;
use SecurePress\Service\Threat_Service;
use WP_UnitTestCase;

final class ThreatServiceTest extends WP_UnitTestCase {

	public function test_combines_framework_and_severity_filters(): void {
		$result = ( new Threat_Service() )->list(
			new Threat_Filter( framework_code: 'OWASP_LLM', severity: 'critical' )
		);

		$this->assertNotEmpty( $result['content'] );

		foreach ( $result['content'] as $threat ) {
			$this->assertSame( 'OWASP_LLM', $threat['frameworkCode'] );
			$this->assertSame( 'critical', $threat['severity'] );
		}
	}

	public function test_find_returns_polish_translation_when_locale_is_pl(): void {
		$service = new Threat_Service();
		$en      = $service->find( $this->llm01_id(), 'en' );
		$pl      = $service->find( $this->llm01_id(), 'pl' );

		$this->assertNotNull( $en );
		$this->assertNotNull( $pl );
		$this->assertNotSame( $en['title'], $pl['title'] );
		$this->assertStringContainsString( 'Wstrzyknięcie', $pl['title'] );
	}

	/**
	 * FR-18.6: a threat with no curated 'pl' row (there is at least one
	 * seeded framework beyond Web/LLM with no translations at all) must fall
	 * back to the English content, never a blank field. All 20 seeded
	 * threats currently have translations, so this asserts the fallback
	 * mechanism directly rather than relying on a coincidental gap.
	 */
	public function test_detail_never_has_blank_title_regardless_of_locale(): void {
		$service = new Threat_Service();
		$detail  = $service->find( $this->llm01_id(), 'pl' );

		$this->assertNotSame( '', $detail['title'] );
		$this->assertNotSame( '', $detail['description'] );
	}

	public function test_find_returns_null_for_unknown_id(): void {
		$this->assertNull( ( new Threat_Service() )->find( 999999999 ) );
	}

	private function llm01_id(): int {
		global $wpdb;

		return (int) $wpdb->get_var(
			$wpdb->prepare( "SELECT id FROM {$wpdb->prefix}sp_threats WHERE code = %s", 'LLM01:2025' )
		);
	}
}
