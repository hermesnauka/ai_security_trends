<?php

declare( strict_types = 1 );

namespace SecurePress\Templates;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * WordPress Template Hierarchy integration (PLAN.md §8): PHP templates
 * registered via template_include, progressively enhanced with vanilla JS.
 * No client-side SPA framework — every route below renders a full page
 * server-side and works with JavaScript disabled.
 */
final class Template_Loader {

	public function __construct() {
		add_action( 'init', array( $this, 'register_rewrite_rules' ) );
		add_filter( 'query_vars', array( $this, 'register_query_vars' ) );
	}

	public function register_rewrite_rules(): void {
		add_rewrite_rule( '^security-catalogue/?$', 'index.php?securepress_page=home', 'top' );
		add_rewrite_rule( '^threats/?$', 'index.php?securepress_page=archive-threat', 'top' );
		add_rewrite_rule( '^threats/([0-9]+)/?$', 'index.php?securepress_page=single-threat&securepress_threat_id=$matches[1]', 'top' );
	}

	public function register_query_vars( array $vars ): array {
		$vars[] = 'securepress_page';
		$vars[] = 'securepress_threat_id';

		return $vars;
	}

	public function maybe_override( string $template ): string {
		$page = get_query_var( 'securepress_page' );

		if ( '' === $page || false === $page ) {
			return $template;
		}

		$candidate = SECUREPRESS_PLUGIN_DIR . 'includes/templates/' . $page . '.php';

		return is_readable( $candidate ) ? $candidate : $template;
	}
}
