<?php

declare( strict_types = 1 );

namespace SecurePress\Data;

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

final class Export_Job_Repository {

	public function create( string $job_id, string $format, ?string $framework_code ): void {
		global $wpdb;

		$wpdb->insert(
			$wpdb->prefix . 'sp_export_jobs',
			array(
				'job_id'         => $job_id,
				'status'         => 'pending',
				'format'         => $format,
				'framework_code' => $framework_code,
				'created_at'     => current_time( 'mysql', true ),
			),
			array( '%s', '%s', '%s', '%s', '%s' )
		);
	}

	public function mark_processing( string $job_id ): void {
		$this->update( $job_id, array( 'status' => 'processing' ), array( '%s' ) );
	}

	public function mark_completed( string $job_id, string $file_path ): void {
		$this->update(
			$job_id,
			array(
				'status'       => 'completed',
				'file_path'    => $file_path,
				'completed_at' => current_time( 'mysql', true ),
			),
			array( '%s', '%s', '%s' )
		);
	}

	public function mark_failed( string $job_id, string $error_message ): void {
		$this->update(
			$job_id,
			array(
				'status'        => 'failed',
				'error_message' => $error_message,
				'completed_at'  => current_time( 'mysql', true ),
			),
			array( '%s', '%s', '%s' )
		);
	}

	public function by_job_id( string $job_id ): ?object {
		global $wpdb;

		$table = $wpdb->prefix . 'sp_export_jobs';

		$row = $wpdb->get_row(
			$wpdb->prepare( "SELECT * FROM {$table} WHERE job_id = %s", $job_id ) // phpcs:ignore WordPress.DB.PreparedSQL.NotPrepared
		);

		return $row instanceof \stdClass ? $row : null;
	}

	private function update( string $job_id, array $data, array $formats ): void {
		global $wpdb;

		$wpdb->update(
			$wpdb->prefix . 'sp_export_jobs',
			$data,
			array( 'job_id' => $job_id ),
			$formats,
			array( '%s' )
		);
	}
}
