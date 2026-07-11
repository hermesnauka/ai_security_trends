<?php
/**
 * templates/stride-heatmap.php — STRIDE coverage heatmap (US-08, FR-08.2).
 * SR-01.3: requires manage_securepress or securepress_trainer — this is the
 * front-end template-level gate; the REST route (Rest_Api::require_trainer_capability)
 * enforces the same rule independently for the JSON data itself.
 */

declare( strict_types = 1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

use SecurePress\Service\Matrix_Service;
use SecurePress\Templates\Language_Switcher;

if ( ! is_user_logged_in() ) {
	status_header( 401 );
	get_header();
	?>
	<main class="securepress">
		<p><?php esc_html_e( 'Musisz się zalogować, aby zobaczyć tę stronę.', 'securepress-2026' ); ?></p>
	</main>
	<?php
	get_footer();
	return;
}

if ( ! current_user_can( 'manage_securepress' ) && ! current_user_can( 'securepress_trainer' ) ) {
	status_header( 403 );
	get_header();
	?>
	<main class="securepress">
		<p><?php esc_html_e( 'Nie masz uprawnień, aby zobaczyć tę stronę.', 'securepress-2026' ); ?></p>
	</main>
	<?php
	get_footer();
	return;
}

$heatmap = ( new Matrix_Service() )->stride_heatmap();

get_header();
?>
<main class="securepress securepress-stride-heatmap" data-testid="stride-heatmap">
	<?php Language_Switcher::render(); ?>
	<h1><?php esc_html_e( 'Heatmapa STRIDE', 'securepress-2026' ); ?></h1>
	<p class="securepress-phase-note">
		<?php esc_html_e( 'Uproszczona heatmapa: liczba kuratorowanych kart per kategoria STRIDE, nie pokrycie per komponent systemu.', 'securepress-2026' ); ?>
	</p>

	<div class="securepress-stride-heatmap-grid" data-testid="stride-heatmap-data" data-heatmap="<?php echo esc_attr( wp_json_encode( $heatmap['categories'] ) ); ?>">
		<?php foreach ( $heatmap['categories'] as $category => $count ) : ?>
			<div class="securepress-stride-cell" data-testid="stride-cell-<?php echo esc_attr( strtolower( $category ) ); ?>">
				<strong><?php echo esc_html( $category ); ?></strong>
				<span><?php echo esc_html( (string) $count ); ?></span>
			</div>
		<?php endforeach; ?>
	</div>
</main>
<?php
get_footer();
