<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Threat_Filter {

	public function __construct(
		public readonly ?string $framework_code = null,
		public readonly ?string $severity = null,
		public readonly ?string $stride = null,
		public readonly ?string $category = null,
		public readonly ?string $tag = null,
		public readonly ?string $query = null,
		public readonly int $page = 1,
		public readonly int $size = 20,
	) {}

	public static function from_request( \WP_REST_Request $request ): self {
		return new self(
			framework_code: self::string_param( $request, 'framework' ),
			severity: self::string_param( $request, 'severity' ),
			stride: self::string_param( $request, 'stride' ),
			category: self::string_param( $request, 'category' ),
			tag: self::string_param( $request, 'tag' ),
			query: self::string_param( $request, 'q' ),
			page: max( 1, (int) $request->get_param( 'page' ) ?: 1 ),
			size: min( 100, max( 1, (int) $request->get_param( 'size' ) ?: 20 ) ),
		);
	}

	private static function string_param( \WP_REST_Request $request, string $key ): ?string {
		$value = $request->get_param( $key );

		return ( is_string( $value ) && '' !== $value ) ? $value : null;
	}
}
