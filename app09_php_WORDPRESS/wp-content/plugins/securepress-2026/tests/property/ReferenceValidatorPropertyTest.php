<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Property;

use Eris\Generator;
use Eris\TestTrait;
use SecurePress\Cards\Card_Decode_Exception;
use SecurePress\Service\Reference_Validator;
use WP_UnitTestCase;

/**
 * SR-07: any owasp_refs/mitre_refs value not present in the fixed allowlist
 * files must be rejected — this is what stops a curation-file typo or a
 * fabricated reference from ever reaching the database (AC-07/AC-08).
 */
final class ReferenceValidatorPropertyTest extends WP_UnitTestCase {

	use TestTrait;

	private const KNOWN_OWASP_REFS = array(
		'A01:2021', 'A02:2021', 'A03:2021', 'A04:2021', 'A05:2021',
		'A06:2021', 'A07:2021', 'A08:2021', 'A09:2021', 'A10:2021',
		'LLM01:2025', 'LLM02:2025', 'LLM03:2025', 'LLM04:2025', 'LLM05:2025',
		'LLM06:2025', 'LLM07:2025', 'LLM08:2025', 'LLM09:2025', 'LLM10:2025',
		'MASVS-STORAGE', 'MASVS-CRYPTO', 'MASVS-AUTH', 'MASVS-NETWORK',
		'MASVS-PLATFORM', 'MASVS-CODE', 'MASVS-RESILIENCE',
		'OAT-001', 'OAT-002', 'OAT-003', 'OAT-004', 'OAT-005', 'OAT-006',
		'OAT-007', 'OAT-008', 'OAT-011', 'OAT-021',
	);

	public function test_any_ref_not_in_the_allowlist_is_rejected(): void {
		$this->forAll(
			Generator\suchThat(
				fn( string $s ) => strlen( $s ) >= 1 && ! in_array( $s, self::KNOWN_OWASP_REFS, true ),
				Generator\string()
			)
		)->then( function ( string $bogus_ref ): void {
			try {
				( new Reference_Validator() )->assert_owasp_refs_valid( array( $bogus_ref ), 'TESTCARD' );
				$this->fail( "Expected rejection of unknown ref \"{$bogus_ref}\"." );
			} catch ( Card_Decode_Exception $exception ) {
				$this->assertStringContainsString( 'TESTCARD', $exception->getMessage() );
			}
		} );
	}
}
