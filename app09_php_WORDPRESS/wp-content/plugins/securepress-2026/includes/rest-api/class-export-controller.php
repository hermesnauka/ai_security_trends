<?php

declare( strict_types = 1 );

namespace SecurePress\Rest_Api;

use SecurePress\Cron\Export_Job;
use SecurePress\Data\Export_Job_Repository;
use WP_Error;
use WP_REST_Request;
use WP_REST_Response;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Export_Controller {

	private Export_Job_Repository $repository;

	public function __construct( ?Export_Job_Repository $repository = null ) {
		$this->repository = $repository ?? new Export_Job_Repository();
	}

	/**
	 * FR-17.3/AC-14-adjacent: rejects a missing/invalid format outright
	 * (requirements.md ExportArgsValidator) rather than silently defaulting.
	 */
	public function create( WP_REST_Request $request ): WP_REST_Response|WP_Error {
		$format = (string) ( $request->get_param( 'format' ) ?? '' );

		if ( 'csv' !== $format ) {
			return new WP_Error(
				'securepress_unsupported_format',
				__( 'Only format=csv is currently supported (PDF export is not implemented).', 'securepress-2026' ),
				array( 'status' => 422 )
			);
		}

		$framework_code = $request->get_param( 'framework' );
		$framework_code = is_string( $framework_code ) && '' !== $framework_code ? $framework_code : null;

		$job_id = wp_generate_uuid4();
		$this->repository->create( $job_id, $format, $framework_code );

		// FR-17.3: never block this request on the export itself — a single
		// WP-Cron event runs Export_Job::run() out-of-band.
		wp_schedule_single_event( time(), Export_Job::HOOK, array( $job_id ) );

		return new WP_REST_Response(
			array(
				'jobId'     => $job_id,
				'statusUrl' => rest_url( "securepress/v1/export/status/{$job_id}" ),
			),
			202
		);
	}

	public function status( WP_REST_Request $request ): WP_REST_Response|WP_Error {
		$job_id = (string) $request->get_param( 'jobId' );
		$job    = $this->repository->by_job_id( $job_id );

		if ( null === $job ) {
			return new WP_Error(
				'securepress_not_found',
				__( 'Export job not found.', 'securepress-2026' ),
				array( 'status' => 404 )
			);
		}

		$response = array(
			'jobId'  => $job->job_id,
			'status' => $job->status,
		);

		if ( 'completed' === $job->status && null !== $job->file_path ) {
			$upload_dir              = wp_upload_dir();
			$response['downloadUrl'] = str_replace( $upload_dir['basedir'], $upload_dir['baseurl'], $job->file_path );
		}

		if ( 'failed' === $job->status ) {
			$response['error'] = $job->error_message;
		}

		return new WP_REST_Response( $response, 200 );
	}
}
