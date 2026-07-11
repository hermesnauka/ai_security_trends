<?php
/**
 * templates/archive-threat.php — filterable threat browser (US-02, FR-02).
 * Server-rendered first paint from the current query string; threat-browser.js
 * enhances this progressively with debounced fetch()-driven filtering. The
 * server-rendered result set below already reflects any ?framework=&severity=
 * etc. query-string filters, so this page is fully usable with JS disabled.
 */

declare( strict_types = 1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

use SecurePress\Data\Threat_Filter;
use SecurePress\Service\Threat_Service;
use SecurePress\Templates\Language_Switcher;

$filter = new Threat_Filter(
	framework_code: isset( $_GET['framework'] ) ? sanitize_text_field( wp_unslash( $_GET['framework'] ) ) : null,
	severity: isset( $_GET['severity'] ) ? sanitize_text_field( wp_unslash( $_GET['severity'] ) ) : null,
	stride: isset( $_GET['stride'] ) ? sanitize_text_field( wp_unslash( $_GET['stride'] ) ) : null,
	category: isset( $_GET['category'] ) ? sanitize_text_field( wp_unslash( $_GET['category'] ) ) : null,
	tag: isset( $_GET['tag'] ) ? sanitize_text_field( wp_unslash( $_GET['tag'] ) ) : null,
	query: isset( $_GET['q'] ) ? sanitize_text_field( wp_unslash( $_GET['q'] ) ) : null,
);

$result = ( new Threat_Service() )->list( $filter );

get_header();
?>
<main class="securepress securepress-threat-archive" data-testid="threat-archive">
	<?php Language_Switcher::render(); ?>
	<h1><?php esc_html_e( 'Przeglądarka Zagrożeń', 'securepress-2026' ); ?></h1>

	<form class="securepress-filter-panel" method="get" action="<?php echo esc_url( home_url( '/threats/' ) ); ?>">
		<label>
			<?php esc_html_e( 'Szukaj', 'securepress-2026' ); ?>
			<input type="search" name="q" id="threat-search" maxlength="200"
				value="<?php echo esc_attr( $filter->query ?? '' ); ?>">
		</label>
		<label>
			<?php esc_html_e( 'Severity', 'securepress-2026' ); ?>
			<select name="severity">
				<option value=""><?php esc_html_e( 'Wszystkie', 'securepress-2026' ); ?></option>
				<?php foreach ( array( 'critical', 'high', 'medium', 'low', 'info' ) as $severity ) : ?>
					<option value="<?php echo esc_attr( $severity ); ?>" <?php selected( $filter->severity, $severity ); ?>>
						<?php echo esc_html( $severity ); ?>
					</option>
				<?php endforeach; ?>
			</select>
		</label>
		<button type="submit"><?php esc_html_e( 'Filtruj', 'securepress-2026' ); ?></button>
	</form>

	<ul class="securepress-threat-results" id="threat-results">
		<?php foreach ( $result['content'] as $threat ) : ?>
			<li class="securepress-threat-card" data-testid="threat-result">
				<a href="<?php echo esc_url( home_url( '/threats/' . $threat['id'] . '/' ) ); ?>">
					<span class="securepress-threat-code"><?php echo esc_html( $threat['code'] ); ?></span>
					<span class="securepress-threat-title"><?php echo esc_html( $threat['title'] ); ?></span>
					<span class="securepress-severity-badge securepress-severity-<?php echo esc_attr( $threat['severity'] ); ?>">
						<?php echo esc_html( $threat['severity'] ); ?>
					</span>
				</a>
			</li>
		<?php endforeach; ?>
	</ul>

	<?php if ( array() === $result['content'] ) : ?>
		<p><?php esc_html_e( 'Brak wyników dla podanych filtrów.', 'securepress-2026' ); ?></p>
	<?php endif; ?>
</main>
<?php
get_footer();
