<?php

declare( strict_types = 1 );

namespace SecurePress\Cron;

use SecurePress\Cards\Card_Ingestion_Service;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Manually-triggerable re-ingestion (e.g. from the integrity dashboard,
 * includes/admin/, once built) — distinct from Periodic_Reverify_Job's
 * automatic daily schedule, but calling the same ingestion path.
 */
final class Reingest_Deck_Job {

	public const HOOK = 'securepress_reingest_deck';

	public static function register(): void {
		add_action( self::HOOK, array( self::class, 'run' ) );
	}

	public static function run(): void {
		( new Card_Ingestion_Service() )->ingest_all();
	}
}
