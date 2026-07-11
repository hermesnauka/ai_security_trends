<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Property;

use Eris\Generator;
use Eris\TestTrait;
use SecurePress\Cards\Card_Decode_Exception;
use SecurePress\Cards\Card_Loader;
use WP_UnitTestCase;

/**
 * D-08/SR-09.2: PHP has no derive-macro or strict-decode-by-default
 * mechanism, so the allow-list check in Card_Loader is hand-written code —
 * more test cases partially compensate for the lack of a language-level
 * guarantee (PLAN.md D-08, user_stories+tests.md's "Zasada TDD" note).
 *
 * Each property writes a temporary, randomly-perturbed deck file directly
 * under data/cornucopia/ (Card_Loader has no injectable base path) and
 * always removes it in a finally block, even on assertion failure.
 *
 * expectException() is deliberately NOT used here: it is designed for one
 * assertion per test method, and eris calls the ->then() callback many times
 * per test method (once per generated value) — asserting via an explicit
 * try/catch/fail is the pattern that actually re-arms correctly on every
 * iteration.
 */
final class CardLoaderPropertyTest extends WP_UnitTestCase {

	use TestTrait;

	public function test_rejects_unknown_top_level_key(): void {
		$this->forAll( Generator\suchThat( fn( string $s ) => strlen( $s ) >= 3, Generator\string() ) )
			->then( function ( string $extra_key ): void {
				$filename = $this->write_temp_deck(
					"meta:\n  edition: webapp\n  component: cards\n  language: en\n  version: '3.0'\n"
					. "{$extra_key}: unexpected\nsuits: []\n"
				);

				try {
					$this->assert_decode_throws( $filename );
				} finally {
					$this->remove_temp_deck( $filename );
				}
			} );
	}

	public function test_rejects_unknown_card_key(): void {
		$this->forAll( Generator\suchThat( fn( string $s ) => strlen( $s ) >= 3 && ! in_array( $s, array( 'id', 'value', 'url', 'desc', 'misc' ), true ), Generator\string() ) )
			->then( function ( string $extra_key ): void {
				$filename = $this->write_temp_deck(
					"meta:\n  edition: webapp\n  component: cards\n  language: en\n  version: '3.0'\n"
					. "suits:\n- id: VE\n  name: Test\n  cards:\n  - id: VE2\n    value: '2'\n    desc: test\n    {$extra_key}: unexpected\n"
				);

				try {
					$this->assert_decode_throws( $filename );
				} finally {
					$this->remove_temp_deck( $filename );
				}
			} );
	}

	private function assert_decode_throws( string $filename ): void {
		try {
			( new Card_Loader() )->load_deck(
				array( 'file' => $filename, 'edition' => 'webapp', 'curation' => 'webapp.curation.json', 'design_harm' => false )
			);
			$this->fail( 'Expected Card_Decode_Exception was not thrown for an unknown key.' );
		} catch ( Card_Decode_Exception $exception ) {
			$this->assertNotEmpty( $exception->getMessage() );
		}
	}

	private function write_temp_deck( string $yaml ): string {
		$filename = '_eris_tmp_' . wp_generate_password( 12, false ) . '.yaml';
		file_put_contents( SECUREPRESS_PLUGIN_DIR . 'data/cornucopia/' . $filename, $yaml );

		return $filename;
	}

	private function remove_temp_deck( string $filename ): void {
		$path = SECUREPRESS_PLUGIN_DIR . 'data/cornucopia/' . $filename;

		if ( file_exists( $path ) ) {
			unlink( $path );
		}
	}
}
