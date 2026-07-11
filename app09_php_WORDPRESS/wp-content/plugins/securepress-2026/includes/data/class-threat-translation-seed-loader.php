<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Seeds sp_threat_translations from data/threat_translations_seed.json
 * (NFR-03.1). Covers only the 20 threats seeded by Seed_Loader (OWASP Web +
 * LLM Top 10) — the same representative-slice scope as every other seed
 * step in this plugin, not every threat this app will eventually catalogue.
 */
final class Threat_Translation_Seed_Loader {

	private Threat_Repository $threats;
	private Threat_Translation_Repository $translations;

	public function __construct(
		?Threat_Repository $threats = null,
		?Threat_Translation_Repository $translations = null
	) {
		$this->threats      = $threats ?? new Threat_Repository();
		$this->translations = $translations ?? new Threat_Translation_Repository();
	}

	public function seed(): void {
		$path = SECUREPRESS_PLUGIN_DIR . 'data/threat_translations_seed.json';

		if ( ! is_readable( $path ) ) {
			return;
		}

		$decoded = json_decode( (string) file_get_contents( $path ), true );

		if ( ! is_array( $decoded ) ) {
			return;
		}

		foreach ( $decoded as $entry ) {
			$threat = $this->threats->by_code( $entry['code'] );

			if ( null === $threat ) {
				continue;
			}

			$this->translations->upsert(
				(int) $threat->id,
				$entry['locale'],
				array(
					'title'         => $entry['title'],
					'description'   => $entry['description'],
					'attack_vector' => $entry['attack_vector'],
				)
			);
		}
	}
}
