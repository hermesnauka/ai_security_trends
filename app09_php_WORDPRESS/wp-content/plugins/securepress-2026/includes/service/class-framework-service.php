<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

use SecurePress\Data\Framework_Repository;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Framework_Service {

	private Framework_Repository $repository;

	public function __construct( ?Framework_Repository $repository = null ) {
		$this->repository = $repository ?? new Framework_Repository();
	}

	public function list(): array {
		return array_map(
			fn( object $row ): array => $this->to_array( $row ),
			$this->repository->all()
		);
	}

	public function find( string $code ): ?array {
		$row = $this->repository->by_code( $code );

		return null === $row ? null : $this->to_array( $row );
	}

	private function to_array( object $row ): array {
		return array(
			'code'          => $row->code,
			'name'          => $row->name,
			'version'       => $row->version,
			'description'   => $row->description,
			'referenceUrl'  => $row->reference_url,
			'threatCount'   => $this->repository->threat_count( (int) $row->id ),
		);
	}
}
