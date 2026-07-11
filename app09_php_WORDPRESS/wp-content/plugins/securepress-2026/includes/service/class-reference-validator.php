<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

use SecurePress\Cards\Card_Decode_Exception;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * SR-07: OwaspRef/MitreRef values are validated against allowlists loaded
 * from data/ref-allowlists.json / data/mitre-atlas-allowlist.json before any
 * write to owasp_refs/mitre_refs. Every value here is curated content
 * (PLAN.md §0.1) — this class is what stops a curation-file typo or a
 * fabricated reference from ever reaching the database.
 */
final class Reference_Validator {

	private array $owasp_allowlist;
	private array $mitre_allowlist;

	public function __construct() {
		$this->owasp_allowlist = $this->load( 'ref-allowlists.json', 'owasp_refs' );
		$this->mitre_allowlist = $this->load( 'mitre-atlas-allowlist.json', 'mitre_refs' );
	}

	/**
	 * @param string[] $refs
	 */
	public function assert_owasp_refs_valid( array $refs, string $card_id ): void {
		$this->assert_valid( $refs, $this->owasp_allowlist, $card_id, 'owasp_refs' );
	}

	/**
	 * @param string[] $refs
	 */
	public function assert_mitre_refs_valid( array $refs, string $card_id ): void {
		$this->assert_valid( $refs, $this->mitre_allowlist, $card_id, 'mitre_refs' );
	}

	/**
	 * @param string[] $refs
	 * @param string[] $allowlist
	 */
	private function assert_valid( array $refs, array $allowlist, string $card_id, string $field ): void {
		foreach ( $refs as $ref ) {
			if ( ! in_array( $ref, $allowlist, true ) ) {
				throw new Card_Decode_Exception(
					sprintf( 'Unknown %s value "%s" curated for card %s is not in the allowlist.', $field, $ref, $card_id )
				);
			}
		}
	}

	/**
	 * @return string[]
	 */
	private function load( string $filename, string $key ): array {
		$path = SECUREPRESS_PLUGIN_DIR . 'data/' . $filename;

		if ( ! is_readable( $path ) ) {
			return array();
		}

		$decoded = json_decode( (string) file_get_contents( $path ), true );

		return is_array( $decoded ) && isset( $decoded[ $key ] ) && is_array( $decoded[ $key ] )
			? $decoded[ $key ]
			: array();
	}
}
