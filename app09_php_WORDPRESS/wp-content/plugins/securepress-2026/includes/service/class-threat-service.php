<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

use SecurePress\Data\Threat_Filter;
use SecurePress\Data\Threat_Repository;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Threat_Service {

	private Threat_Repository $repository;
	private Mitigation_Service $mitigation_service;

	public function __construct( ?Threat_Repository $repository = null, ?Mitigation_Service $mitigation_service = null ) {
		$this->repository         = $repository ?? new Threat_Repository();
		$this->mitigation_service = $mitigation_service ?? new Mitigation_Service();
	}

	public function list( Threat_Filter $filter ): array {
		$rows = $this->repository->search( $filter );

		return array(
			'content'       => array_map( array( $this, 'to_summary' ), $rows ),
			'totalElements' => $this->repository->count( $filter ),
			'number'        => $filter->page,
			'size'          => $filter->size,
		);
	}

	public function find( int $id ): ?array {
		$row = $this->repository->by_id( $id );

		return null === $row ? null : $this->to_detail( $row );
	}

	private function to_summary( object $row ): array {
		return array(
			'id'            => (int) $row->id,
			'code'          => $row->code,
			'title'         => $row->title,
			'severity'      => $row->severity,
			'category'      => $row->category,
			'stride'        => $row->stride,
			'frameworkCode' => $row->framework_code,
			'tags'          => json_decode( $row->tags, true ) ?: array(),
		);
	}

	private function to_detail( object $row ): array {
		return array(
			'id'            => (int) $row->id,
			'code'          => $row->code,
			'title'         => $row->title,
			'severity'      => $row->severity,
			'category'      => $row->category,
			'description'   => $row->description,
			'attackVector'  => $row->attack_vector,
			'attackSurface' => $row->attack_surface,
			'stride'        => $row->stride,
			'tags'          => json_decode( $row->tags, true ) ?: array(),
			// FR-02: threat detail nests mitigations + their code samples.
			'mitigations'   => $this->mitigation_service->for_threat_id( (int) $row->id ),
		);
	}
}
