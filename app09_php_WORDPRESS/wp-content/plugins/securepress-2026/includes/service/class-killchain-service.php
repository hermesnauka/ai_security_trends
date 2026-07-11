<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * PLAN.md §6 Phase 4: MITRE ATLAS Kill-Chain timeline for a threat, backing
 * a vanilla-JS/SVG rendering with no charting-library dependency. Stage data
 * lives in data/mitre_atlas_killchain.json — only the tactic IDs actually
 * confirmed in the source mapping document carry a real ATLAS id (§0.1);
 * other stages are named but carry `id: null` rather than a fabricated code.
 */
final class Killchain_Service {

	/**
	 * @return array<int, array{tactic: string, id: ?string, technique: ?string}>
	 */
	public function for_threat_code( string $threat_code ): array {
		$path = SECUREPRESS_PLUGIN_DIR . 'data/mitre_atlas_killchain.json';

		if ( ! is_readable( $path ) ) {
			return array();
		}

		$decoded = json_decode( (string) file_get_contents( $path ), true );

		if ( ! is_array( $decoded ) || ! isset( $decoded[ $threat_code ] ) ) {
			return array();
		}

		return $decoded[ $threat_code ];
	}
}
