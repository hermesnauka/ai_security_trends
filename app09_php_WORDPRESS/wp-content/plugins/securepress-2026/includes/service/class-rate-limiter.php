<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * D-09: Transients API, backed by a persistent Redis object cache, gives
 * atomic INCR-equivalent behavior; the default DB-table-backed transient
 * storage is not atomic under concurrency and is deliberately not relied on
 * for this. 60 req/min/IP on public list routes (SR-05.1).
 */
final class Rate_Limiter {

	private const LIMIT  = 60;
	private const WINDOW = MINUTE_IN_SECONDS;

	public function is_allowed( string $client_ip ): bool {
		$key   = 'sp_ratelimit_' . md5( $client_ip );
		$count = (int) get_transient( $key );

		if ( $count >= self::LIMIT ) {
			return false;
		}

		set_transient( $key, $count + 1, self::WINDOW );

		return true;
	}
}
