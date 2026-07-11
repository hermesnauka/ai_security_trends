<?php
/**
 * PHPUnit bootstrap for securepress-2026, using wp-phpunit/wp-phpunit
 * (composer.json dev dependency) rather than a system-wide WP test
 * checkout, so `composer install && vendor/bin/phpunit` is self-contained.
 * Not runnable in this sandbox — no PHP/Composer/MySQL are installed here
 * (see CLAUDE.md) — but is real, standard wp-phpunit integration code.
 */

declare( strict_types = 1 );

$composer_autoload = dirname( __DIR__ ) . '/vendor/autoload.php';

if ( ! file_exists( $composer_autoload ) ) {
	fwrite( STDERR, "Run 'composer install' before running the test suite.\n" );
	exit( 1 );
}

require_once $composer_autoload;

$_tests_dir = getenv( 'WP_TESTS_DIR' );

if ( ! $_tests_dir ) {
	$_tests_dir = dirname( __DIR__ ) . '/vendor/wp-phpunit/wp-phpunit';
}

require_once $_tests_dir . '/includes/functions.php';

/**
 * Loads the plugin the same way a real WordPress install would (via the
 * bootstrap file, not by including individual classes), so activation
 * hooks, dbDelta(), and seeding all run exactly as in production.
 */
function _securepress_manually_load_plugin(): void {
	require dirname( __DIR__ ) . '/securepress-2026.php';
}

tests_add_filter( 'muplugins_loaded', '_securepress_manually_load_plugin' );

require $_tests_dir . '/includes/bootstrap.php';
