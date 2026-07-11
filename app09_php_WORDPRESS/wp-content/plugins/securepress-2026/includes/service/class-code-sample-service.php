<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

use SecurePress\Data\Code_Sample_Repository;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Code_Sample_Service {

	private Code_Sample_Repository $repository;

	public function __construct( ?Code_Sample_Repository $repository = null ) {
		$this->repository = $repository ?? new Code_Sample_Repository();
	}

	public function by_mitigation_id( int $mitigation_id ): array {
		return array_map(
			static fn( object $row ): array => array(
				'language'      => $row->language,
				'sampleType'    => $row->sample_type,
				'title'         => $row->title,
				'description'   => $row->description,
				'code'          => $row->code,
				'frameworkHint' => $row->framework_hint,
				'versionNote'   => $row->version_note,
			),
			$this->repository->by_mitigation_id( $mitigation_id )
		);
	}
}
