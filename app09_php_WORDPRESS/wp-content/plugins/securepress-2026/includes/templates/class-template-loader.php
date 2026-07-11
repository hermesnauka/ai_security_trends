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

	/**
	 * @var array<string, array{page: string, param: string}> slug => target,
	 *      per PLAN.md §8's /frameworks/{slug}/ route table. `stride` and
	 *      `devops-security` are simplified to suit-archive.php here rather
	 *      than the dedicated stride-catalogue.php/devops-security.php from
	 *      §8 — the heatmap/DVO+CLD+BOT-combined views are follow-up work,
	 *      not part of this ingestion pass.
	 */
	private const FRAMEWORK_SLUGS = array(
		'website-app'       => array( 'page' => 'suit-archive', 'param' => 'edition=webapp' ),
		'frontend-security' => array( 'page' => 'suit-archive', 'param' => 'suit=fre' ),
		'llm-security'      => array( 'page' => 'suit-archive', 'param' => 'suit=llm' ),
		'agentic-ai'        => array( 'page' => 'suit-archive', 'param' => 'suit=aai' ),
		'ml-security'       => array( 'page' => 'suit-archive', 'param' => 'edition=mlsec' ),
		'mobile-security'   => array( 'page' => 'suit-archive', 'param' => 'edition=mobileapp' ),
		'stride'            => array( 'page' => 'suit-archive', 'param' => 'edition=eop' ),
		'devops-security'   => array( 'page' => 'suit-archive', 'param' => 'suit=dvo' ),
		'digital-harms'     => array( 'page' => 'digital-harms', 'param' => '' ),
	);

	public function register_rewrite_rules(): void {
		add_rewrite_rule( '^security-catalogue/?$', 'index.php?securepress_page=home', 'top' );
		add_rewrite_rule( '^threats/?$', 'index.php?securepress_page=archive-threat', 'top' );
		add_rewrite_rule( '^threats/([0-9]+)/?$', 'index.php?securepress_page=single-threat&securepress_threat_id=$matches[1]', 'top' );
		add_rewrite_rule( '^search/?$', 'index.php?securepress_page=search-results', 'top' );
		add_rewrite_rule( '^matrix/?$', 'index.php?securepress_page=matrix', 'top' );
		add_rewrite_rule( '^matrix/([a-z-]+)/?$', 'index.php?securepress_page=matrix&securepress_matrix_type=$matches[1]', 'top' );
		add_rewrite_rule( '^stride-heatmap/?$', 'index.php?securepress_page=stride-heatmap', 'top' );

		foreach ( self::FRAMEWORK_SLUGS as $slug => $target ) {
			$query = 'index.php?securepress_page=' . $target['page'];
			if ( '' !== $target['param'] ) {
				$query .= '&' . $target['param'];
			}
			add_rewrite_rule( '^frameworks/' . preg_quote( $slug, '/' ) . '/?$', $query, 'top' );
		}
	}

	public function register_query_vars( array $vars ): array {
		$vars[] = 'securepress_page';
		$vars[] = 'securepress_threat_id';
		$vars[] = 'securepress_matrix_type';
		$vars[] = 'suit';
		$vars[] = 'edition';
		$vars[] = 'lang';
		$vars[] = 'q';

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

	/**
	 * Reads a param from the literal query string first (so /threats/?suit=fre
	 * keeps working exactly as before) and falls back to the WordPress query
	 * var populated by a pretty-permalink rewrite match (/frameworks/.../).
	 */
	public static function param( string $key ): ?string {
		if ( isset( $_GET[ $key ] ) ) {
			return sanitize_text_field( wp_unslash( (string) $_GET[ $key ] ) );
		}

		$value = get_query_var( $key );

		return '' !== $value && false !== $value ? sanitize_text_field( (string) $value ) : null;
	}
}
