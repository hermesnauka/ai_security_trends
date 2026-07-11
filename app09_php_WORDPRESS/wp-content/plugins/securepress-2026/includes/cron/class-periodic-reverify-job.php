<?php

declare( strict_types = 1 );

namespace SecurePress\Cron;

use SecurePress\Cards\Card_Ingestion_Service;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * D-03: one of only two call sites permitted to trigger integrity
 * verification (the other is the activation hook in class-plugin.php).
 * Registered via wp_schedule_event; WP-Cron runs in-process (PLAN.md §3 —
 * no separate worker binary exists in this architecture), so this is a
 * plain scheduled hook callback, not a standalone process.
 */
final class Periodic_Reverify_Job {

	public const HOOK = 'securepress_periodic_reverify';

	public static function register(): void {
		add_action( self::HOOK, array( self::class, 'run' ) );

		if ( ! wp_next_scheduled( self::HOOK ) ) {
			wp_schedule_event( time(), 'daily', self::HOOK );
		}
	}

	public static function run(): void {
		( new Card_Ingestion_Service() )->ingest_all();
	}
}
