<?php
/**
 * templates/search-results.php — global search (US-17, FR-17.1/17.2).
 * Server-rendered from the ?q= query string, fully usable without JS.
 */

declare( strict_types = 1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

use SecurePress\Service\Search_Service;
use SecurePress\Templates\Language_Switcher;
use SecurePress\Templates\Template_Loader;

$query = isset( $_GET['q'] ) ? sanitize_text_field( wp_unslash( $_GET['q'] ) ) : '';

$requested_lang = Template_Loader::param( 'lang' );
$locale         = in_array( $requested_lang, array( 'pl', 'en' ), true )
	? $requested_lang
	: ( str_starts_with( get_locale(), 'en' ) ? 'en' : 'pl' );

$results = '' !== trim( $query ) && strlen( $query ) <= 200
	? ( new Search_Service() )->search( $query, $locale )
	: array( 'threats' => array(), 'cards' => array() );

get_header();
?>
<main class="securepress securepress-search-results" data-testid="search-results">
	<?php Language_Switcher::render(); ?>
	<h1><?php esc_html_e( 'Wyszukiwanie', 'securepress-2026' ); ?></h1>

	<form class="securepress-filter-panel" method="get" action="<?php echo esc_url( home_url( '/search/' ) ); ?>">
		<label>
			<?php esc_html_e( 'Szukaj', 'securepress-2026' ); ?>
			<input type="search" name="q" maxlength="200" value="<?php echo esc_attr( $query ); ?>">
		</label>
		<button type="submit"><?php esc_html_e( 'Szukaj', 'securepress-2026' ); ?></button>
	</form>

	<?php if ( '' !== trim( $query ) ) : ?>
		<h2><?php esc_html_e( 'Zagrożenia', 'securepress-2026' ); ?></h2>
		<?php if ( array() === $results['threats'] ) : ?>
			<p><?php esc_html_e( 'Brak wyników wśród zagrożeń.', 'securepress-2026' ); ?></p>
		<?php endif; ?>
		<ul class="securepress-search-result-list" data-testid="search-threats">
			<?php foreach ( $results['threats'] as $threat ) : ?>
				<li>
					<a href="<?php echo esc_url( home_url( '/threats/' . $threat['id'] . '/' ) ); ?>">
						<strong><?php echo esc_html( $threat['code'] ); ?></strong> — <?php echo esc_html( $threat['title'] ); ?>
					</a>
					<p><?php echo wp_kses( $threat['excerpt'], array( 'mark' => array() ) ); ?></p>
				</li>
			<?php endforeach; ?>
		</ul>

		<h2><?php esc_html_e( 'Karty Cornucopia', 'securepress-2026' ); ?></h2>
		<?php if ( array() === $results['cards'] ) : ?>
			<p><?php esc_html_e( 'Brak wyników wśród kart.', 'securepress-2026' ); ?></p>
		<?php endif; ?>
		<ul class="securepress-search-result-list" data-testid="search-cards">
			<?php foreach ( $results['cards'] as $card ) : ?>
				<li>
					<strong><?php echo esc_html( $card['cardId'] ); ?></strong>
					<span class="securepress-search-result-meta">(<?php echo esc_html( strtoupper( $card['suitCode'] ) ); ?>, <?php echo esc_html( $card['edition'] ); ?>)</span>
					<p><?php echo wp_kses( $card['excerpt'], array( 'mark' => array() ) ); ?></p>
				</li>
			<?php endforeach; ?>
		</ul>
	<?php endif; ?>
</main>
<?php
get_footer();
