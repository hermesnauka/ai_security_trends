<?php
/**
 * templates/single-threat.php — threat detail page (US-03, FR-03).
 * Tabs are same-page anchored sections that work without JavaScript;
 * code-sample-panel.js provides tabbed switching as a progressive enhancement.
 */

declare( strict_types = 1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

use SecurePress\Service\Threat_Service;
use SecurePress\Templates\Language_Switcher;

$threat_id = (int) get_query_var( 'securepress_threat_id' );
$threat    = ( new Threat_Service() )->find( $threat_id );

if ( null === $threat ) {
	global $wp_query;
	$wp_query->set_404();
	status_header( 404 );
	get_header();
	echo '<main class="securepress"><p>' . esc_html__( 'Zagrożenie nie zostało znalezione.', 'securepress-2026' ) . '</p></main>';
	get_footer();
	return;
}

get_header();
?>
<main class="securepress securepress-threat-detail" data-testid="threat-detail">
	<?php Language_Switcher::render(); ?>
	<h1>
		<span class="securepress-threat-code"><?php echo esc_html( $threat['code'] ); ?></span>
		<?php echo esc_html( $threat['title'] ); ?>
	</h1>
	<span class="securepress-severity-badge securepress-severity-<?php echo esc_attr( $threat['severity'] ); ?>" data-testid="severity-badge">
		<?php echo esc_html( $threat['severity'] ); ?>
	</span>

	<nav class="securepress-tabs">
		<a href="#overview"><?php esc_html_e( 'Przegląd', 'securepress-2026' ); ?></a>
		<a href="#attack-vectors"><?php esc_html_e( 'Wektory Ataku', 'securepress-2026' ); ?></a>
		<a href="#mitigations"><?php esc_html_e( 'Mitigacje', 'securepress-2026' ); ?></a>
		<a href="#code-samples"><?php esc_html_e( 'Kod', 'securepress-2026' ); ?></a>
		<a href="#cross-references"><?php esc_html_e( 'Powiązania', 'securepress-2026' ); ?></a>
	</nav>

	<section id="overview">
		<h2><?php esc_html_e( 'Przegląd', 'securepress-2026' ); ?></h2>
		<p><?php echo esc_html( $threat['description'] ); ?></p>
	</section>

	<section id="attack-vectors">
		<h2><?php esc_html_e( 'Wektory Ataku', 'securepress-2026' ); ?></h2>
		<p><?php echo esc_html( $threat['attackVector'] ); ?></p>
		<h3><?php esc_html_e( 'Powierzchnia Ataku', 'securepress-2026' ); ?></h3>
		<p><?php echo esc_html( $threat['attackSurface'] ); ?></p>
	</section>

	<section id="mitigations">
		<h2><?php esc_html_e( 'Mitigacje', 'securepress-2026' ); ?></h2>
		<p class="securepress-phase-note">
			<?php esc_html_e( 'Mitigacje i próbki kodu w 5 językach są ładowane w kolejnej fazie budowy (PLAN.md Faza 3–4).', 'securepress-2026' ); ?>
		</p>
	</section>

	<section id="code-samples" data-testid="code-samples">
		<h2><?php esc_html_e( 'Próbki Kodu', 'securepress-2026' ); ?></h2>
	</section>

	<section id="cross-references">
		<h2><?php esc_html_e( 'Powiązania Cross-Framework', 'securepress-2026' ); ?></h2>
	</section>
</main>
<?php
get_footer();
