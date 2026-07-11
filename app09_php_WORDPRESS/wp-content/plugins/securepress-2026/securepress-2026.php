<?php
/**
 * Plugin Name:       SecurePress 2026
 * Plugin URI:        https://github.com/hermesnauka/ai_security_trends
 * Description:       Bilingual (PL/EN) security-education platform mapping OWASP, MITRE ATLAS,
 *                     and CompTIA Security+/SecAI+ threats to Cornucopia-family card decks, with
 *                     five-language countermeasure code samples.
 * Version:           0.1.0
 * Requires at least: 6.8
 * Requires PHP:      8.3
 * Author:            SecurePress 2026 contributors
 * License:           GPL-2.0-or-later
 * License URI:       https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain:       securepress-2026
 * Domain Path:       /languages
 */

declare( strict_types = 1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

define( 'SECUREPRESS_VERSION', '0.1.0' );
define( 'SECUREPRESS_DB_VERSION', '1' );
define( 'SECUREPRESS_PLUGIN_FILE', __FILE__ );
define( 'SECUREPRESS_PLUGIN_DIR', plugin_dir_path( __FILE__ ) );
define( 'SECUREPRESS_PLUGIN_URL', plugin_dir_url( __FILE__ ) );
define( 'SECUREPRESS_MIN_MYSQL_VERSION', '8.0.16' );

$securepress_autoload = SECUREPRESS_PLUGIN_DIR . 'vendor/autoload.php';
if ( file_exists( $securepress_autoload ) ) {
	require_once $securepress_autoload;
} else {
	require_once SECUREPRESS_PLUGIN_DIR . 'includes/class-fallback-autoloader.php';
	SecurePress\Fallback_Autoloader::register();
}

register_activation_hook( __FILE__, array( SecurePress\Plugin::class, 'activate' ) );
register_deactivation_hook( __FILE__, array( SecurePress\Plugin::class, 'deactivate' ) );

SecurePress\Plugin::instance()->boot();
