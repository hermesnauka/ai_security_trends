<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Seeds sp_cross_references from data/cross_references_seed.json (NFR-03.1).
 * Covers 4 genuinely-defensible OWASP-Web <-> OWASP-LLM relationships — not
 * an exhaustive cross-framework matrix, the same representative-slice scope
 * as every other seed step in this plugin.
 */
final class Cross_Reference_Seed_Loader {

	private Threat_Repository $threats;
	private Cross_Reference_Repository $cross_references;

	public function __construct(
		?Threat_Repository $threats = null,
		?Cross_Reference_Repository $cross_references = null
	) {
		$this->threats          = $threats ?? new Threat_Repository();
		$this->cross_references = $cross_references ?? new Cross_Reference_Repository();
	}

	public function seed(): void {
		$path = SECUREPRESS_PLUGIN_DIR . 'data/cross_references_seed.json';

		if ( ! is_readable( $path ) ) {
			return;
		}

		$decoded = json_decode( (string) file_get_contents( $path ), true );

		if ( ! is_array( $decoded ) ) {
			return;
		}

		foreach ( $decoded as $entry ) {
			$source = $this->threats->by_code( $entry['sourceCode'] );
			$target = $this->threats->by_code( $entry['targetCode'] );

			if ( null === $source || null === $target ) {
				continue;
			}

			$this->cross_references->upsert_seed(
				(int) $source->id,
				(int) $target->id,
				$entry['relationshipType'],
				$entry['description']
			);
		}
	}
}
