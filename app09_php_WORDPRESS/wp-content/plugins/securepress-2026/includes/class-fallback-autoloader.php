<?php

declare( strict_types = 1 );

namespace SecurePress;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * PSR-4-lite autoloader used only when `composer install` has not been run
 * (e.g. a fresh checkout before dependencies are installed). Composer's own
 * generated autoloader is preferred whenever `vendor/autoload.php` exists;
 * this class never touches third-party namespaces such as Symfony\Component\Yaml.
 */
final class Fallback_Autoloader {

	public static function register(): void {
		spl_autoload_register( array( self::class, 'load' ) );
	}

	private static function load( string $class ): void {
		$prefix = __NAMESPACE__ . '\\';

		if ( ! str_starts_with( $class, $prefix ) ) {
			return;
		}

		$relative = substr( $class, strlen( $prefix ) );
		$path     = SECUREPRESS_PLUGIN_DIR . 'includes/' . self::class_to_path( $relative );

		if ( is_readable( $path ) ) {
			require_once $path;
		}
	}

	private static function class_to_path( string $relative ): string {
		$parts     = explode( '\\', $relative );
		$class_name = array_pop( $parts );
		$dirs       = array_map(
			static fn( string $part ): string => strtolower( str_replace( '_', '-', $part ) ),
			$parts
		);
		$file = 'class-' . strtolower( str_replace( '_', '-', $class_name ) ) . '.php';

		return implode( '/', array( ...$dirs, $file ) );
	}
}
