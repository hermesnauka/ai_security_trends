<?php

declare( strict_types = 1 );

namespace SecurePress\Cards;

use SecurePress\Data\Card_Repository;
use SecurePress\Integrity\Integrity_Verifier;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Orchestrates the ingestion pipeline called from the activation hook and
 * from Reingest_Deck_Job/Periodic_Reverify_Job only (D-03, D-07): verify
 * every deck's SHA-256 (SR-06.1), then decode + curate + upsert inside a
 * single transaction per deck so a mismatch or decode failure aborts with
 * no partial writes (SR-06.2).
 */
final class Card_Ingestion_Service {

	private Integrity_Verifier $integrity_verifier;
	private Card_Loader $loader;
	private Card_Repository $repository;

	public function __construct(
		?Integrity_Verifier $integrity_verifier = null,
		?Card_Loader $loader = null,
		?Card_Repository $repository = null
	) {
		$this->integrity_verifier = $integrity_verifier ?? new Integrity_Verifier();
		$this->loader              = $loader ?? new Card_Loader();
		$this->repository          = $repository ?? new Card_Repository();
	}

	/**
	 * @return array{ingested: int, skipped: string[]}
	 */
	public function ingest_all(): array {
		global $wpdb;

		$hash_results = $this->integrity_verifier->verify();
		$skipped      = array();
		$ingested     = 0;

		foreach ( Card_Loader::deck_manifest() as $manifest_entry ) {
			$file = $manifest_entry['file'];

			if ( isset( $hash_results[ $file ] ) && ! $hash_results[ $file ] ) {
				// SEC-CARD-HASH-MISMATCH (PLAN.md §12): this deck is skipped
				// entirely rather than ingested with unverified content.
				$skipped[] = $file;
				continue;
			}

			$wpdb->query( 'START TRANSACTION' );

			try {
				foreach ( $this->loader->load_deck( $manifest_entry ) as $row ) {
					$this->repository->upsert( $row );
				}
				$wpdb->query( 'COMMIT' );
				++$ingested;
			} catch ( Card_Decode_Exception $exception ) {
				$wpdb->query( 'ROLLBACK' );
				$skipped[] = $file;
			}
		}

		return array( 'ingested' => $ingested, 'skipped' => $skipped );
	}
}
