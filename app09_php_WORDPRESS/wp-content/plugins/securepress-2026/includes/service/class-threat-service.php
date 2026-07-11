<?php

declare( strict_types = 1 );

namespace SecurePress\Service;

use SecurePress\Data\Threat_Filter;
use SecurePress\Data\Threat_Repository;
use SecurePress\Data\Threat_Translation_Repository;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Threat_Service {

	private Threat_Repository $repository;
	private Threat_Translation_Repository $translations;
	private Mitigation_Service $mitigation_service;

	public function __construct(
		?Threat_Repository $repository = null,
		?Threat_Translation_Repository $translations = null,
		?Mitigation_Service $mitigation_service = null
	) {
		$this->repository         = $repository ?? new Threat_Repository();
		$this->translations       = $translations ?? new Threat_Translation_Repository();
		$this->mitigation_service = $mitigation_service ?? new Mitigation_Service();
	}

	public function list( Threat_Filter $filter, string $locale = 'en' ): array {
		$rows = $this->repository->search( $filter );

		return array(
			'content'       => array_map( fn( object $row ): array => $this->to_summary( $row, $locale ), $rows ),
			'totalElements' => $this->repository->count( $filter ),
			'number'        => $filter->page,
			'size'          => $filter->size,
		);
	}

	public function find( int $id, string $locale = 'en' ): ?array {
		$row = $this->repository->by_id( $id );

		return null === $row ? null : $this->to_detail( $row, $locale );
	}

	/**
	 * FR-18.4/FR-18.6: locale content comes from sp_threat_translations when
	 * a 'pl' row exists for this threat; otherwise it falls back to the base
	 * English row — never a blank field. English callers skip the lookup
	 * entirely, since the base row already is the English content.
	 */
	private function localized( object $row, string $locale ): array {
		if ( 'pl' !== $locale ) {
			return array(
				'title'        => $row->title,
				'description'  => $row->description,
				'attackVector' => $row->attack_vector,
			);
		}

		$translation = $this->translations->by_threat_and_locale( (int) $row->id, 'pl' );

		return array(
			'title'        => $translation->title ?? $row->title,
			'description'  => $translation->description ?? $row->description,
			'attackVector' => $translation->attack_vector ?? $row->attack_vector,
		);
	}

	private function to_summary( object $row, string $locale ): array {
		$localized = $this->localized( $row, $locale );

		return array(
			'id'            => (int) $row->id,
			'code'          => $row->code,
			'title'         => $localized['title'],
			'severity'      => $row->severity,
			'category'      => $row->category,
			'stride'        => $row->stride,
			'frameworkCode' => $row->framework_code,
			'tags'          => json_decode( $row->tags, true ) ?: array(),
		);
	}

	private function to_detail( object $row, string $locale ): array {
		$localized = $this->localized( $row, $locale );

		return array(
			'id'            => (int) $row->id,
			'code'          => $row->code,
			'title'         => $localized['title'],
			'severity'      => $row->severity,
			'category'      => $row->category,
			'description'   => $localized['description'],
			'attackVector'  => $localized['attackVector'],
			'attackSurface' => $row->attack_surface,
			'stride'        => $row->stride,
			'tags'          => json_decode( $row->tags, true ) ?: array(),
			// FR-02: threat detail nests mitigations + their code samples.
			'mitigations'   => $this->mitigation_service->for_threat_id( (int) $row->id ),
		);
	}
}
