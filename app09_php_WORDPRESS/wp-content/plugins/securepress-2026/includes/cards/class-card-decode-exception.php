<?php

declare( strict_types = 1 );

namespace SecurePress\Cards;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Thrown by Card_Loader for any of: an unknown top-level/suit/card YAML key
 * (D-08 allow-list), a curation or translation entry whose card_id is absent
 * from the raw deck (AC-19), or a technical-threat card missing a curated
 * severity. Ingestion aborts entirely rather than skipping the bad row.
 */
final class Card_Decode_Exception extends \RuntimeException {}
