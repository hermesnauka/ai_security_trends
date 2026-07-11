<?php
/**
 * templates/home.php — framework catalogue landing page (US-01, FR-01).
 * Server-rendered; no JavaScript required for this page to be fully usable.
 */

declare( strict_types = 1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

use SecurePress\Service\Framework_Service;
use SecurePress\Templates\Language_Switcher;

$frameworks = ( new Framework_Service() )->list();

get_header();
?>
<main class="securepress securepress-home">
	<?php Language_Switcher::render(); ?>
	<h1><?php esc_html_e( 'SecurePress 2026 — Katalog Frameworków Bezpieczeństwa', 'securepress-2026' ); ?></h1>
	<p class="securepress-disclaimer">
		<?php esc_html_e( 'Treść ma charakter edukacyjny i musi być zweryfikowana wobec oficjalnych źródeł.', 'securepress-2026' ); ?>
	</p>

	<div class="securepress-framework-grid">
		<?php foreach ( $frameworks as $framework ) : ?>
			<a class="securepress-framework-tile" href="<?php echo esc_url( home_url( '/threats/?framework=' . rawurlencode( $framework['code'] ) ) ); ?>">
				<h2><?php echo esc_html( $framework['name'] ); ?></h2>
				<p class="securepress-framework-version"><?php echo esc_html( $framework['version'] ); ?></p>
				<p><?php echo esc_html( $framework['description'] ); ?></p>
				<span class="securepress-threat-count">
					<?php
					echo esc_html(
						sprintf(
							/* translators: %d: number of threats in this framework */
							_n( '%d zagrożenie', '%d zagrożeń', $framework['threatCount'], 'securepress-2026' ),
							$framework['threatCount']
						)
					);
					?>
				</span>
			</a>
		<?php endforeach; ?>
	</div>
</main>
<?php
get_footer();
