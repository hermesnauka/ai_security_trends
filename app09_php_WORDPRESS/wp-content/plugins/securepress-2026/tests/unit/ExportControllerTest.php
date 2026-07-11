<?php

declare( strict_types = 1 );

namespace SecurePress\Tests\Unit;

use WP_REST_Request;
use WP_UnitTestCase;

final class ExportControllerTest extends WP_UnitTestCase {

	public function test_enqueues_job_and_returns_202(): void {
		$request = new WP_REST_Request( 'GET', '/securepress/v1/export' );
		$request->set_param( 'format', 'csv' );
		$request->set_param( 'framework', 'OWASP_LLM' );

		$response = rest_get_server()->dispatch( $request );

		$this->assertSame( 202, $response->get_status() );
		$this->assertNotEmpty( $response->get_data()['jobId'] );
	}

	/**
	 * PDF is explicitly not implemented (no PDF library in composer.json) —
	 * this must fail closed with 422, not silently fall back to CSV.
	 */
	public function test_rejects_pdf_format(): void {
		$request = new WP_REST_Request( 'GET', '/securepress/v1/export' );
		$request->set_param( 'format', 'pdf' );

		$response = rest_get_server()->dispatch( $request );

		$this->assertSame( 422, $response->get_status() );
	}

	public function test_rejects_missing_format(): void {
		$request = new WP_REST_Request( 'GET', '/securepress/v1/export' );

		$response = rest_get_server()->dispatch( $request );

		$this->assertSame( 422, $response->get_status() );
	}

	public function test_status_404s_for_unknown_job_id(): void {
		$request = new WP_REST_Request( 'GET', '/securepress/v1/export/status/not-a-real-job-id' );

		$response = rest_get_server()->dispatch( $request );

		$this->assertSame( 404, $response->get_status() );
	}
}
