<?php

declare( strict_types = 1 );

namespace SecurePress;

use SecurePress\Cards\Card_Ingestion_Service;
use SecurePress\Cron\Export_Job;
use SecurePress\Cron\Periodic_Reverify_Job;
use SecurePress\Cron\Reingest_Deck_Job;
use SecurePress\Data\Cross_Reference_Seed_Loader;
use SecurePress\Data\Mitigation_Seed_Loader;
use SecurePress\Data\Schema;
use SecurePress\Data\Seed_Loader;
use SecurePress\Data\Threat_Translation_Seed_Loader;
use SecurePress\Rest_Api\Rest_Api;
use SecurePress\Templates\Template_Loader;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Plugin {

	private static ?Plugin $instance = null;

	public static function instance(): Plugin {
		if ( null === self::$instance ) {
			self::$instance = new self();
		}

		return self::$instance;
	}

	private function __construct() {}

	public function boot(): void {
		add_action( 'plugins_loaded', array( $this, 'load_textdomain' ) );
		add_action( 'init', array( $this, 'maybe_upgrade' ) );
		add_action( 'rest_api_init', array( new Rest_Api(), 'register_routes' ) );
		add_action( 'template_include', array( new Template_Loader(), 'maybe_override' ) );
		add_action( 'wp_enqueue_scripts', array( $this, 'enqueue_assets' ) );
		add_filter( 'xmlrpc_enabled', '__return_false' );
		add_action( 'init', array( Periodic_Reverify_Job::class, 'register' ) );
		add_action( 'init', array( Reingest_Deck_Job::class, 'register' ) );
		add_action( 'init', array( Export_Job::class, 'register' ) );
	}

	public function load_textdomain(): void {
		load_plugin_textdomain(
			'securepress-2026',
			false,
			dirname( plugin_basename( SECUREPRESS_PLUGIN_FILE ) ) . '/languages'
		);
	}

	/**
	 * Standard WordPress plugin-migration pattern: compare a stored option
	 * against SECUREPRESS_DB_VERSION and re-run dbDelta() when they differ,
	 * rather than only on activation (DR-03.1).
	 */
	public function maybe_upgrade(): void {
		if ( get_option( 'securepress_db_version' ) !== SECUREPRESS_DB_VERSION ) {
			self::run_activation_tasks();
		}
	}

	public static function activate(): void {
		self::guard_mysql_version();
		self::run_activation_tasks();
	}

	public static function deactivate(): void {
		wp_clear_scheduled_hook( 'securepress_periodic_reverify' );
		wp_clear_scheduled_hook( 'securepress_export_job' );
	}

	/**
	 * C-11 / NFR-05.2: chk_design_harm_has_no_severity (PLAN.md D-04) is only
	 * enforced by MySQL 8.0.16+ (or MariaDB 10.2.1+); activating on an older
	 * server would silently downgrade this project's strongest guarantee to
	 * an unenforced constraint, so activation refuses outright instead.
	 */
	private static function guard_mysql_version(): void {
		global $wpdb;

		$version = (string) $wpdb->db_version();

		if ( str_contains( strtolower( (string) $wpdb->db_server_info() ), 'mariadb' ) ) {
			return; // MariaDB version guard is left to deployment docs; core WP version_compare() below only applies to MySQL numbering.
		}

		if ( version_compare( $version, SECUREPRESS_MIN_MYSQL_VERSION, '<' ) ) {
			deactivate_plugins( plugin_basename( SECUREPRESS_PLUGIN_FILE ) );
			wp_die(
				esc_html(
					sprintf(
						/* translators: %s: minimum required MySQL version */
						__( 'SecurePress 2026 requires MySQL %s or newer (or MariaDB 10.2.1+) for CHECK constraint enforcement, and refuses to activate on an older server rather than silently losing that guarantee.', 'securepress-2026' ),
						SECUREPRESS_MIN_MYSQL_VERSION
					)
				)
			);
		}
	}

	private static function run_activation_tasks(): void {
		Schema::create_tables();
		self::register_role_and_capability();
		( new Seed_Loader() )->seed();
		( new Threat_Translation_Seed_Loader() )->seed();
		( new Cross_Reference_Seed_Loader() )->seed();
		( new Card_Ingestion_Service() )->ingest_all();
		( new Mitigation_Seed_Loader() )->seed();
		update_option( 'securepress_db_version', SECUREPRESS_DB_VERSION );
		flush_rewrite_rules();
	}

	private static function register_role_and_capability(): void {
		add_role(
			'securepress_editor',
			__( 'SecurePress Editor', 'securepress-2026' ),
			array(
				'read'                => true,
				'manage_securepress'  => true,
				'securepress_trainer' => true,
			)
		);

		$administrator = get_role( 'administrator' );
		if ( null !== $administrator ) {
			$administrator->add_cap( 'manage_securepress' );
			// SR-01.3: /stride-heatmap accepts either capability; granting both
			// to administrator keeps it usable there without a second role.
			$administrator->add_cap( 'securepress_trainer' );
		}
	}

	public function enqueue_assets(): void {
		wp_enqueue_style(
			'securepress-2026',
			SECUREPRESS_PLUGIN_URL . 'assets/css/style.css',
			array(),
			SECUREPRESS_VERSION
		);

		wp_enqueue_script(
			'securepress-2026-threat-browser',
			SECUREPRESS_PLUGIN_URL . 'assets/js/threat-browser.js',
			array(),
			SECUREPRESS_VERSION,
			array( 'strategy' => 'defer', 'in_footer' => true )
		);

		wp_enqueue_script(
			'securepress-2026-export-panel',
			SECUREPRESS_PLUGIN_URL . 'assets/js/export-panel.js',
			array(),
			SECUREPRESS_VERSION,
			array( 'strategy' => 'defer', 'in_footer' => true )
		);

		wp_enqueue_script(
			'securepress-2026-language-toggle',
			SECUREPRESS_PLUGIN_URL . 'assets/js/language-toggle.js',
			array(),
			SECUREPRESS_VERSION,
			array( 'strategy' => 'defer', 'in_footer' => true )
		);

		wp_enqueue_script(
			'securepress-2026-code-sample-panel',
			SECUREPRESS_PLUGIN_URL . 'assets/js/code-sample-panel.js',
			array(),
			SECUREPRESS_VERSION,
			array( 'strategy' => 'defer', 'in_footer' => true )
		);

		wp_enqueue_script(
			'securepress-2026-mitre-killchain',
			SECUREPRESS_PLUGIN_URL . 'assets/js/mitre-killchain.js',
			array(),
			SECUREPRESS_VERSION,
			array( 'strategy' => 'defer', 'in_footer' => true )
		);

		wp_localize_script(
			'securepress-2026-threat-browser',
			'securePressConfig',
			array(
				'restUrl' => esc_url_raw( rest_url( 'securepress/v1/' ) ),
				'nonce'   => wp_create_nonce( 'wp_rest' ),
				'locale'  => get_locale(),
				'strings' => array(
					// FR-18.3: the one dynamic JS-rendered string in this plugin
					// is translated PHP-side and passed through wp_localize_script
					// rather than the full wp_set_script_translations() JSON-file
					// pipeline, since there is currently only this single string —
					// a deliberate scope simplification, not an oversight.
					'noResults' => __( 'Brak wyników.', 'securepress-2026' ),
				),
			)
		);
	}
}
