<?php
/**
 * templates/digital-harms.php — Digital-by-Default Harms deck (US-19,
 * FR-19). Deliberately its own template, not suit-archive.php: this deck
 * must NEVER render a severity badge (FR-19.2), and Card_Service already
 * omits `severity` from the array entirely for card_kind=design_harm, so
 * there is no field here to accidentally print even by copy-paste mistake.
 */

declare( strict_types = 1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

use SecurePress\Service\Card_Service;
use SecurePress\Templates\Language_Switcher;
use SecurePress\Templates\Template_Loader;

$requested_lang = Template_Loader::param( 'lang' );
$locale         = in_array( $requested_lang, array( 'pl', 'en' ), true )
	? $requested_lang
	: ( str_starts_with( get_locale(), 'en' ) ? 'en' : 'pl' );

$cards      = ( new Card_Service() )->by_edition( 'dbd', $locale );
$suit_order = array( 'sco', 'arc', 'age', 'tru', 'por' );
$by_suit    = array_fill_keys( $suit_order, array() );

foreach ( $cards as $card ) {
	$suit = strtolower( $card['suitCode'] );
	if ( isset( $by_suit[ $suit ] ) ) {
		$by_suit[ $suit ][] = $card;
	}
}

get_header();
?>
<main class="securepress securepress-digital-harms" data-testid="digital-harms">
	<?php Language_Switcher::render(); ?>
	<h1><?php esc_html_e( 'Digital-by-Default Harms', 'securepress-2026' ); ?></h1>

	<p class="securepress-harms-disclaimer" data-testid="harms-disclaimer-banner">
		<?php esc_html_e( 'Ta talia nie jest listą podatności technicznych z poziomem severity — modeluje harmy projektowe (wykluczenie cyfrowe, nieprzejrzyste projektowanie) w usługach publicznych, mapowane na OWASP A04:2021 Insecure Design.', 'securepress-2026' ); ?>
	</p>

	<?php foreach ( $suit_order as $suit ) : ?>
		<section data-testid="<?php echo esc_attr( $suit ); ?>-section">
			<h2><?php echo esc_html( strtoupper( $suit ) ); ?></h2>
			<ul class="securepress-card-grid">
				<?php foreach ( $by_suit[ $suit ] as $card ) : ?>
					<li class="securepress-card" data-testid="card-<?php echo esc_attr( $card['cardId'] ); ?>">
						<span class="securepress-card-id"><?php echo esc_html( $card['cardId'] ); ?></span>
						<span class="securepress-design-harm-badge" data-testid="design-harm-badge">
							<?php esc_html_e( 'harm projektowy', 'securepress-2026' ); ?>
						</span>
						<p><?php echo esc_html( $card['description'] ); ?></p>
						<?php if ( ! empty( $card['owaspRefs'] ) ) : ?>
							<p class="securepress-refs">
								<?php foreach ( $card['owaspRefs'] as $ref ) : ?>
									<span class="securepress-ref-chip"><?php echo esc_html( $ref ); ?></span>
								<?php endforeach; ?>
							</p>
						<?php endif; ?>
					</li>
				<?php endforeach; ?>
			</ul>
		</section>
	<?php endforeach; ?>
</main>
<?php
get_footer();
