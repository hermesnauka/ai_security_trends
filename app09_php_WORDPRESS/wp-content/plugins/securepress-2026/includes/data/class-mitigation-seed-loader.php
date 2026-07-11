<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Seeds sp_mitigations + sp_code_samples from data/mitigations_seed.json and
 * data/code_samples_manifest.json (NFR-03.1: seed data lives under data/ as
 * JSON, never hand-written as PHP array literals mixed into migration code).
 * Idempotent, like Seed_Loader/Card_Ingestion_Service — safe to re-run on
 * every activation/upgrade.
 */
final class Mitigation_Seed_Loader {

	private Mitigation_Repository $mitigations;
	private Code_Sample_Repository $code_samples;
	private Threat_Repository $threats;
	private Card_Repository $cards;

	public function __construct(
		?Mitigation_Repository $mitigations = null,
		?Code_Sample_Repository $code_samples = null,
		?Threat_Repository $threats = null,
		?Card_Repository $cards = null
	) {
		$this->mitigations  = $mitigations ?? new Mitigation_Repository();
		$this->code_samples = $code_samples ?? new Code_Sample_Repository();
		$this->threats       = $threats ?? new Threat_Repository();
		$this->cards         = $cards ?? new Card_Repository();
	}

	public function seed(): void {
		$mitigation_ids_by_slug = array();

		foreach ( $this->load_json( 'mitigations_seed.json' ) as $mitigation ) {
			$threat_id = null;
			if ( ! empty( $mitigation['threatCode'] ) ) {
				$threat = $this->threats->by_code( $mitigation['threatCode'] );
				$threat_id = null !== $threat ? (int) $threat->id : null;
			}

			$card_id = null;
			if ( ! empty( $mitigation['cardId'] ) && null !== $this->cards->by_card_id( $mitigation['cardId'] ) ) {
				$card_id = $mitigation['cardId'];
			}

			$id = $this->mitigations->upsert_seed(
				$mitigation['slug'],
				array(
					'threat_id'       => $threat_id,
					'card_id'         => $card_id,
					'title'           => $mitigation['title'],
					'description'     => $mitigation['description'],
					'mitigation_type' => $mitigation['mitigationType'],
					'effort'          => $mitigation['effort'],
					'effectiveness'   => $mitigation['effectiveness'],
				)
			);

			$mitigation_ids_by_slug[ $mitigation['slug'] ] = $id;
		}

		foreach ( $this->load_json( 'code_samples_manifest.json' ) as $entry ) {
			$mitigation_id = $mitigation_ids_by_slug[ $entry['mitigationSlug'] ] ?? null;

			if ( null === $mitigation_id ) {
				continue;
			}

			$code_path = SECUREPRESS_PLUGIN_DIR . 'data/code_samples/' . $entry['file'];

			if ( ! is_readable( $code_path ) ) {
				continue;
			}

			$this->code_samples->upsert_seed(
				$mitigation_id,
				$entry['language'],
				$entry['sampleType'],
				array(
					'title'          => $entry['title'],
					'description'    => $entry['description'],
					'code'           => (string) file_get_contents( $code_path ),
					'framework_hint' => $entry['frameworkHint'],
					'version_note'   => $entry['versionNote'],
				)
			);
		}
	}

	private function load_json( string $filename ): array {
		$path = SECUREPRESS_PLUGIN_DIR . 'data/' . $filename;

		if ( ! is_readable( $path ) ) {
			return array();
		}

		$decoded = json_decode( (string) file_get_contents( $path ), true );

		return is_array( $decoded ) ? $decoded : array();
	}
}
