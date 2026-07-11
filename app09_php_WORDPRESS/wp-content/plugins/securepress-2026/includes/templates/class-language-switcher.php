<?php

declare( strict_types = 1 );

namespace SecurePress\Templates;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * FR-18.2: a visible PL<->EN switch on every template. Renders as a plain
 * pair of <a> links so the no-JS path always works; language-toggle.js
 * intercepts the click as a progressive enhancement only.
 */
final class Language_Switcher {

	public static function render(): void {
		$current = self::current_locale();
		$base    = remove_query_arg( 'lang' );

		printf(
			'<nav class="securepress-language-toggle" data-securepress-language-toggle aria-label="%s">',
			esc_attr__( 'Wybór języka', 'securepress-2026' )
		);

		foreach ( array( 'pl' => 'Polski', 'en' => 'English' ) as $locale => $label ) {
			printf(
				'<a href="%1$s" data-lang="%2$s" aria-current="%3$s">%4$s</a>',
				esc_url( add_query_arg( 'lang', $locale, $base ) ),
				esc_attr( $locale ),
				$locale === $current ? 'true' : 'false',
				esc_html( $label )
			);
		}

		echo '</nav>';
	}

	private static function current_locale(): string {
		$requested = isset( $_GET['lang'] ) ? sanitize_text_field( wp_unslash( $_GET['lang'] ) ) : '';

		if ( in_array( $requested, array( 'pl', 'en' ), true ) ) {
			return $requested;
		}

		// SR-13.1: unrecognized values fall back to the site default rather
		// than being echoed back or used to build a filename/path.
		return str_starts_with( get_locale(), 'en' ) ? 'en' : 'pl';
	}
}
