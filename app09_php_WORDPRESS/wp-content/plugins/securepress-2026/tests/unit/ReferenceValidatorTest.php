<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use SecurePress\Cards\Card_Decode_Exception;
use SecurePress\Service\Reference_Validator;
use WP_UnitTestCase;

final class ReferenceValidatorTest extends WP_UnitTestCase {

	public function test_accepts_known_owasp_ref(): void {
		$this->expectNotToPerformAssertions();
		( new Reference_Validator() )->assert_owasp_refs_valid( array( 'A03:2021' ), 'TEST1' );
	}

	public function test_rejects_unknown_owasp_ref(): void {
		$this->expectException( Card_Decode_Exception::class );
		( new Reference_Validator() )->assert_owasp_refs_valid( array( 'A99:9999' ), 'TEST1' );
	}

	public function test_rejects_unknown_mitre_ref(): void {
		$this->expectException( Card_Decode_Exception::class );
		( new Reference_Validator() )->assert_mitre_refs_valid( array( 'AML.T9999' ), 'TEST1' );
	}

	public function test_accepts_empty_ref_arrays(): void {
		$this->expectNotToPerformAssertions();
		$validator = new Reference_Validator();
		$validator->assert_owasp_refs_valid( array(), 'TEST1' );
		$validator->assert_mitre_refs_valid( array(), 'TEST1' );
	}
}
