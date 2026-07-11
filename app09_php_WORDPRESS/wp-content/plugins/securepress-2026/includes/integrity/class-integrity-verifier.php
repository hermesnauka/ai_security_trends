<?php

declare( strict_types = 1 );

namespace SecurePress\Integrity;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * D-03: this class's only public method is called from the activation hook
 * and from Periodic_Reverify_Job — never from a REST route handler. No
 * process boundary or compiler backstop enforces this (unlike a compiled
 * sibling's worker binary); a custom PHPStan rule (phpstan-rules/) plus code
 * review is the entire enforcement stack, stated as this project's largest
 * structural risk (PLAN.md D-03, §13).
 */
final class Integrity_Verifier {

	/**
	 * @return array<string, bool> filename => is_valid
	 */
	public function verify(): array {
		global $wpdb;

		$hashes_path = SECUREPRESS_PLUGIN_DIR . 'data/hashes.json';
		$expected    = json_decode( (string) file_get_contents( $hashes_path ), true );

		if ( ! is_array( $expected ) ) {
			return array();
		}

		$results = array();
		$table   = $wpdb->prefix . 'sp_content_hashes';

		foreach ( $expected as $filename => $expected_hash ) {
			$path      = SECUREPRESS_PLUGIN_DIR . 'data/cornucopia/' . $filename;
			$is_valid  = is_readable( $path ) && hash_file( 'sha256', $path ) === $expected_hash;
			$results[ $filename ] = $is_valid;

			$wpdb->replace(
				$table,
				array(
					'file_name'   => $filename,
					'sha256_hash' => (string) $expected_hash,
					'verified_at' => current_time( 'mysql', true ),
					'is_valid'    => $is_valid ? 1 : 0,
					'verified_by' => 'securepress-integrity-verifier',
				),
				array( '%s', '%s', '%s', '%d', '%s' )
			);
		}

		return $results;
	}

	public function all_valid(): bool {
		return ! in_array( false, $this->verify(), true );
	}
}
