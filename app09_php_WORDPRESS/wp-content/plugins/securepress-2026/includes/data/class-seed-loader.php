<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Idempotent seed routine run from the activation hook (NFR-03.1: seed data
 * lives under data/ as JSON, never hand-written as PHP array literals mixed
 * into migration code). This Phase-1 seed covers the frameworks catalogue in
 * full and a representative subset of threats per framework — full DR-01
 * content-completeness is later-phase content work, not a foundation-scaffold
 * concern.
 */
final class Seed_Loader {

	private Framework_Repository $frameworks;
	private Threat_Repository $threats;

	public function __construct(
		?Framework_Repository $frameworks = null,
		?Threat_Repository $threats = null
	) {
		$this->frameworks = $frameworks ?? new Framework_Repository();
		$this->threats    = $threats ?? new Threat_Repository();
	}

	public function seed(): void {
		foreach ( $this->load_json( 'frameworks.json' ) as $framework ) {
			$this->frameworks->upsert(
				$framework['code'],
				$framework['name'],
				$framework['version'],
				$framework['description'],
				$framework['referenceUrl']
			);
		}

		foreach ( $this->load_json( 'threats_seed.json' ) as $threat ) {
			if ( $this->threats->code_exists( $threat['code'] ) ) {
				continue;
			}

			$framework = $this->frameworks->by_code( $threat['frameworkCode'] );

			if ( null === $framework ) {
				continue;
			}

			$this->threats->insert_seed_threat( (int) $framework->id, $threat );
		}
	}

	private function load_json( string $filename ): array {
		$path = SECUREPRESS_PLUGIN_DIR . 'data/' . $filename;

		if ( ! is_readable( $path ) ) {
			return array();
		}

		$contents = file_get_contents( $path );
		$decoded  = json_decode( (string) $contents, true );

		return is_array( $decoded ) ? $decoded : array();
	}
}
