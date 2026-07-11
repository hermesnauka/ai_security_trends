<?php

declare( strict_types = 1 );

namespace SecurePress\Cards;

use SecurePress\Service\Reference_Validator;
use Symfony\Component\Yaml\Yaml;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * D-08: symfony/yaml decode (no custom-tag/object-support flags enabled,
 * so no arbitrary-object-instantiation gadget class) + hand-written
 * allow-list validation, since PHP has no derive-macro or strict-decode
 * mechanism. §0.1: the raw YAML carries only id/value/url/desc/misc — every
 * severity/card_kind/owasp_refs/mitre_refs value is merged in from a
 * separate, reviewed curation file, never read from the YAML itself.
 */
final class Card_Loader {

	private const ALLOWED_ROOT_KEYS  = array( 'meta', 'suits' );
	private const ALLOWED_META_KEYS  = array( 'edition', 'component', 'language', 'version' );
	private const ALLOWED_SUIT_KEYS  = array( 'id', 'name', 'cards', 'sentences' );
	private const ALLOWED_CARD_KEYS  = array( 'id', 'value', 'url', 'desc', 'misc' );
	private const RESERVED_JSON_KEYS = array( '_comment' );

	/**
	 * @return array<int, array{
	 *     edition: string, deck_file: string
	 * }>
	 */
	public static function deck_manifest(): array {
		return array(
			array(
				'file'        => 'webapp-cards-3.0-en.yaml',
				'edition'     => 'webapp',
				'curation'    => 'webapp.curation.json',
				'design_harm' => false,
			),
			array(
				'file'        => 'mobileapp-cards-1.1-en.yaml',
				'edition'     => 'mobileapp',
				'curation'    => 'mobileapp.curation.json',
				'design_harm' => false,
			),
			array(
				'file'        => 'companion-llm-cards-1.0-en.yaml',
				'edition'     => 'companion',
				'curation'    => 'companion.curation.json',
				'design_harm' => false,
			),
			array(
				'file'        => 'stride-eop-cards-5.0-en.yaml',
				'edition'     => 'eop',
				'curation'    => 'stride-eop.curation.json',
				'design_harm' => false,
			),
			array(
				'file'        => 'mlsec-cards-1.0-en.yaml',
				'edition'     => 'mlsec',
				'curation'    => 'mlsec.curation.json',
				'design_harm' => false,
			),
			array(
				'file'        => 'dbd-cards-1.0-en.yaml',
				'edition'     => 'dbd',
				'curation'    => 'dbd.curation.json',
				'design_harm' => true,
			),
		);
	}

	private Reference_Validator $reference_validator;

	public function __construct( ?Reference_Validator $reference_validator = null ) {
		$this->reference_validator = $reference_validator ?? new Reference_Validator();
	}

	/**
	 * Loads every deck in deck_manifest() and, only once every deck's card
	 * IDs are known, checks the shared pl.cards.json translations file for
	 * an orphaned key (AC-19's guarantee, extended to the one JSON file that
	 * isn't scoped to a single deck and so can't be checked inside
	 * load_deck() without rejecting every other deck's legitimate entries).
	 *
	 * @return array<int, array<string, mixed>>
	 */
	public function load_all(): array {
		$all_rows      = array();
		$all_card_ids  = array();

		foreach ( self::deck_manifest() as $manifest_entry ) {
			$rows = $this->load_deck( $manifest_entry );
			foreach ( $rows as $row ) {
				$all_card_ids[ $row['card_id'] ] = true;
			}
			$all_rows = array( ...$all_rows, ...$rows );
		}

		$translations_path = SECUREPRESS_PLUGIN_DIR . 'data/cornucopia/translations/pl.cards.json';
		$translations       = $this->load_json_map( $translations_path, null, 'translation' );

		foreach ( array_keys( $translations ) as $card_id ) {
			if ( ! isset( $all_card_ids[ $card_id ] ) ) {
				throw new Card_Decode_Exception(
					"translations/pl.cards.json references card_id \"{$card_id}\" absent from every deck's raw YAML."
				);
			}
		}

		return $all_rows;
	}

	/**
	 * @return array<int, array<string, mixed>> card rows ready for Card_Repository::upsert()
	 */
	public function load_deck( array $manifest_entry ): array {
		$base = SECUREPRESS_PLUGIN_DIR . 'data/cornucopia/';

		$deck = $this->decode_yaml( $base . $manifest_entry['file'] );
		$this->assert_allowed_keys( $deck, self::ALLOWED_ROOT_KEYS, 'root' );

		if ( isset( $deck['meta'] ) ) {
			$this->assert_allowed_keys( $deck['meta'], self::ALLOWED_META_KEYS, 'meta' );
		}

		$raw_cards = $this->extract_cards( $deck['suits'] ?? array() );
		$known_ids = array_keys( $raw_cards );

		$curation     = $this->load_json_map( $base . 'curation/' . $manifest_entry['curation'], $known_ids, 'curation' );
		$translations = $this->load_json_map( $base . 'translations/pl.cards.json', null, 'translation' );

		$rows = array();

		foreach ( $raw_cards as $card_id => $card ) {
			$rows[] = $this->build_row(
				$card_id,
				$card,
				$manifest_entry,
				$curation[ $card_id ] ?? null,
				$translations[ $card_id ] ?? null
			);
		}

		return $rows;
	}

	private function decode_yaml( string $path ): array {
		if ( ! is_readable( $path ) ) {
			throw new Card_Decode_Exception( "Deck file not readable: {$path}" );
		}

		$decoded = Yaml::parseFile( $path );

		if ( ! is_array( $decoded ) ) {
			throw new Card_Decode_Exception( "Deck file did not decode to an array: {$path}" );
		}

		return $decoded;
	}

	private function extract_cards( array $suits ): array {
		$cards = array();

		foreach ( $suits as $suit ) {
			$this->assert_allowed_keys( $suit, self::ALLOWED_SUIT_KEYS, 'suit' );

			// The "Common"/metadata suit (e.g. deck title/version blurb) has a
			// `sentences` key instead of `cards` — it carries no threat data
			// and is deliberately skipped, not treated as a decode error.
			if ( ! isset( $suit['cards'] ) ) {
				continue;
			}

			foreach ( $suit['cards'] as $card ) {
				$this->assert_allowed_keys( $card, self::ALLOWED_CARD_KEYS, 'card' );

				if ( ! isset( $card['id'], $card['value'], $card['desc'] ) ) {
					throw new Card_Decode_Exception( 'Card is missing a required id/value/desc field.' );
				}

				$cards[ $card['id'] ] = array(
					'suit_code' => $suit['id'],
					'suit_name' => $suit['name'],
					'value'     => (string) $card['value'],
					'url'       => $card['url'] ?? null,
					'desc'      => $card['desc'],
					'misc'      => $card['misc'] ?? null,
				);
			}
		}

		return $cards;
	}

	private function build_row( string $card_id, array $card, array $manifest_entry, ?array $curation, ?string $translation ): array {
		$is_design_harm = (bool) $manifest_entry['design_harm'];
		$card_kind      = $is_design_harm ? 'design_harm' : 'technical_threat';

		if ( $is_design_harm ) {
			$severity = null;
		} else {
			if ( null === $curation || ! isset( $curation['severity'] ) ) {
				throw new Card_Decode_Exception( "Card {$card_id} has no curated severity (required for technical_threat cards)." );
			}
			$severity = (string) $curation['severity'];
		}

		$owasp_refs = $curation['owasp_refs'] ?? array();
		$mitre_refs = $curation['mitre_refs'] ?? array();

		$this->reference_validator->assert_owasp_refs_valid( $owasp_refs, $card_id );
		$this->reference_validator->assert_mitre_refs_valid( $mitre_refs, $card_id );

		$description_en = $card['desc'];
		$description_pl = $translation ?? $description_en;

		return array(
			'card_id'        => $card_id,
			'suit_code'      => $card['suit_code'],
			'suit_name'      => $card['suit_name'],
			'edition'        => $manifest_entry['edition'],
			'card_value'     => $card['value'],
			'is_critical'    => in_array( $card['value'], array( 'K', 'Q', 'A' ), true ) ? 1 : 0,
			'card_kind'      => $card_kind,
			'severity'       => $severity,
			'description_en' => $description_en,
			'description_pl' => $description_pl,
			'misc_note'      => $card['misc'],
			'source_url'     => $card['url'],
			'owasp_refs'     => $owasp_refs,
			'mitre_refs'     => $mitre_refs,
			'content_sha256' => hash( 'sha256', $card_id . '|' . $card['value'] . '|' . ( $card['url'] ?? '' ) . '|' . $description_en . '|' . ( $card['misc'] ?? '' ) ),
		);
	}

	/**
	 * @param string[]|null $known_ids when non-null, every key in the loaded
	 *                                  map must exist in this list (AC-19) —
	 *                                  used for curation files (deck-scoped);
	 *                                  the shared translations file is not
	 *                                  deck-scoped so this check is skipped
	 *                                  there and happens per-lookup instead.
	 */
	private function load_json_map( string $path, ?array $known_ids, string $kind ): array {
		if ( ! is_readable( $path ) ) {
			return array();
		}

		$decoded = json_decode( (string) file_get_contents( $path ), true );

		if ( ! is_array( $decoded ) ) {
			throw new Card_Decode_Exception( "Malformed {$kind} file: {$path}" );
		}

		foreach ( self::RESERVED_JSON_KEYS as $reserved ) {
			unset( $decoded[ $reserved ] );
		}

		if ( null !== $known_ids ) {
			foreach ( array_keys( $decoded ) as $card_id ) {
				if ( ! in_array( $card_id, $known_ids, true ) ) {
					throw new Card_Decode_Exception(
						"{$kind} file {$path} references card_id \"{$card_id}\" absent from its deck's raw YAML."
					);
				}
			}
		}

		return $decoded;
	}

	private function assert_allowed_keys( array $data, array $allowed, string $context ): void {
		foreach ( array_keys( $data ) as $key ) {
			if ( ! in_array( $key, $allowed, true ) ) {
				throw new Card_Decode_Exception( "Unknown key \"{$key}\" in {$context}." );
			}
		}
	}
}
