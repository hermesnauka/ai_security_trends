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
use SecurePress\Templates\Template_Loader;

$filter = new Threat_Filter(
	framework_code: isset( $_GET['framework'] ) ? sanitize_text_field( wp_unslash( $_GET['framework'] ) ) : null,
	severity: isset( $_GET['severity'] ) ? sanitize_text_field( wp_unslash( $_GET['severity'] ) ) : null,
	stride: isset( $_GET['stride'] ) ? sanitize_text_field( wp_unslash( $_GET['stride'] ) ) : null,
	category: isset( $_GET['category'] ) ? sanitize_text_field( wp_unslash( $_GET['category'] ) ) : null,
	tag: isset( $_GET['tag'] ) ? sanitize_text_field( wp_unslash( $_GET['tag'] ) ) : null,
	query: isset( $_GET['q'] ) ? sanitize_text_field( wp_unslash( $_GET['q'] ) ) : null,
);

$requested_lang = Template_Loader::param( 'lang' );
$locale         = in_array( $requested_lang, array( 'pl', 'en' ), true )
	? $requested_lang
	: ( str_starts_with( get_locale(), 'en' ) ? 'en' : 'pl' );

$result = ( new Threat_Service() )->list( $filter, $locale );

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

	<?php
	// FR-17.3/17.4: the no-JS baseline is a plain link to the REST endpoint —
	// it returns {jobId, statusUrl} JSON rather than a file, which is
	// functional but not seamless without JavaScript. export-panel.js
	// intercepts the click and polls status/offers a download link inline.
	$export_url = rest_url( 'securepress/v1/export' );
	if ( null !== $filter->framework_code ) {
		$export_url = add_query_arg( 'framework', $filter->framework_code, $export_url );
	}
	$export_url = add_query_arg( 'format', 'csv', $export_url );
	?>
	<div class="securepress-export-panel" data-testid="export-panel" data-export-url="<?php echo esc_url( $export_url ); ?>">
		<a href="<?php echo esc_url( $export_url ); ?>" data-testid="export-trigger">
			<?php esc_html_e( 'Eksportuj do CSV', 'securepress-2026' ); ?>
		</a>
		<span data-testid="export-status"></span>
	</div>
</main>
<?php
get_footer();
