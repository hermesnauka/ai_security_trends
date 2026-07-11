<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

use SecurePress\Data\Mitigation_Repository;
use SecurePress\Data\Threat_Repository;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Mitigation_Service {

	private Mitigation_Repository $repository;
	private Threat_Repository $threat_repository;
	private Code_Sample_Service $code_sample_service;

	public function __construct(
		?Mitigation_Repository $repository = null,
		?Threat_Repository $threat_repository = null,
		?Code_Sample_Service $code_sample_service = null
	) {
		$this->repository          = $repository ?? new Mitigation_Repository();
		$this->threat_repository   = $threat_repository ?? new Threat_Repository();
		$this->code_sample_service = $code_sample_service ?? new Code_Sample_Service();
	}

	public function for_threat_code( string $threat_code ): array {
		$threat = $this->threat_repository->by_code( $threat_code );

		if ( null === $threat ) {
			return array();
		}

		return $this->to_array_list( $this->repository->by_threat_id( (int) $threat->id ) );
	}

	public function for_threat_id( int $threat_id ): array {
		return $this->to_array_list( $this->repository->by_threat_id( $threat_id ) );
	}

	public function for_card_id( string $card_id ): array {
		return $this->to_array_list( $this->repository->by_card_id( $card_id ) );
	}

	private function to_array_list( array $rows ): array {
		return array_map( array( $this, 'to_array' ), $rows );
	}

	private function to_array( object $row ): array {
		return array(
			'id'             => (int) $row->id,
			'slug'           => $row->slug,
			'title'          => $row->title,
			'description'    => $row->description,
			'mitigationType' => $row->mitigation_type,
			'effort'         => $row->effort,
			'effectiveness'  => $row->effectiveness,
			'codeSamples'    => $this->code_sample_service->by_mitigation_id( (int) $row->id ),
		);
	}
}
