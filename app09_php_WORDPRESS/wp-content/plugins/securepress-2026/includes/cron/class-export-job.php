<?php

declare( strict_types = 1 );

namespace SecurePress\Cron;

use SecurePress\Data\Export_Job_Repository;
use SecurePress\Data\Threat_Filter;
use SecurePress\Data\Threat_Repository;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * FR-17.3: export runs as a WP-Cron job, never blocking the HTTP request
 * that triggers it (Export_Controller::create() only enqueues this via
 * wp_schedule_single_event() and returns 202 immediately). PDF is not
 * implemented — Export_Controller rejects format=pdf outright (SR-12-style
 * fail-closed on an unsupported value) rather than silently downgrading to
 * CSV, since PLAN.md's composer.json has no PDF library and faking PDF
 * output would be worse than not offering it.
 */
final class Export_Job {

	public const HOOK = 'securepress_export_job';

	public static function register(): void {
		add_action( self::HOOK, array( self::class, 'run' ), 10, 1 );
	}

	public static function run( string $job_id ): void {
		$repository = new Export_Job_Repository();
		$job        = $repository->by_job_id( $job_id );

		if ( null === $job ) {
			return;
		}

		$repository->mark_processing( $job_id );

		try {
			$file_path = self::write_csv( $job_id, $job->framework_code );
			$repository->mark_completed( $job_id, $file_path );
		} catch ( \Throwable $exception ) {
			$repository->mark_failed( $job_id, $exception->getMessage() );
		}
	}

	private static function write_csv( string $job_id, ?string $framework_code ): string {
		$threats = ( new Threat_Repository() )->search(
			new Threat_Filter( framework_code: $framework_code, page: 1, size: 1000 )
		);

		$upload_dir = wp_upload_dir();
		$export_dir = trailingslashit( $upload_dir['basedir'] ) . 'securepress-exports';

		if ( ! is_dir( $export_dir ) ) {
			wp_mkdir_p( $export_dir );
		}

		$file_path = trailingslashit( $export_dir ) . $job_id . '.csv';
		$handle    = fopen( $file_path, 'w' ); // phpcs:ignore WordPress.WP.AlternativeFunctions.file_system_read_fopen -- writing to the uploads dir, not reading arbitrary user-supplied paths.

		if ( false === $handle ) {
			throw new \RuntimeException( 'Could not open export file for writing.' );
		}

		fputcsv( $handle, array( 'code', 'title', 'severity', 'category', 'framework_code' ) );

		foreach ( $threats as $threat ) {
			fputcsv(
				$handle,
				array( $threat->code, $threat->title, $threat->severity, $threat->category, $threat->framework_code )
			);
		}

		fclose( $handle );

		return $file_path;
	}
}
