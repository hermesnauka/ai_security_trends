<?php
/**
 * templates/suit-archive.php — generic Cornucopia suit/edition archive
 * (PLAN.md §8: one parameterized template backs /frameworks/website-app/,
 * /frameworks/frontend-security/, /frameworks/llm-security/, etc. via
 * ?suit=/?edition= rather than one file per suit). US-05–US-10, US-12.
 */

declare( strict_types = 1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

use SecurePress\Service\Card_Service;
use SecurePress\Templates\Language_Switcher;
use SecurePress\Templates\Template_Loader;

$suit    = Template_Loader::param( 'suit' );
$edition = Template_Loader::param( 'edition' );
$requested_lang = Template_Loader::param( 'lang' );
$locale  = in_array( $requested_lang, array( 'pl', 'en' ), true )
	? $requested_lang
	: ( str_starts_with( get_locale(), 'en' ) ? 'en' : 'pl' );

$card_service = new Card_Service();
$cards        = $suit ? $card_service->by_suit( $suit, $locale ) : ( $edition ? $card_service->by_edition( $edition, $locale ) : array() );

get_header();
?>
<main class="securepress securepress-suit-archive" data-testid="suit-archive">
	<?php Language_Switcher::render(); ?>
	<h1>
		<?php
		echo esc_html(
			$suit
				? sprintf(
					/* translators: %s: Cornucopia suit code, e.g. FRE, LLM */
					__( 'Karty Cornucopia — Suit %s', 'securepress-2026' ),
					strtoupper( $suit )
				)
				: sprintf(
					/* translators: %s: Cornucopia deck edition, e.g. webapp, mlsec */
					__( 'Karty Cornucopia — %s', 'securepress-2026' ),
					$edition ?? ''
				)
		);
		?>
	</h1>

	<ul class="securepress-card-grid">
		<?php foreach ( $cards as $card ) : ?>
			<li class="securepress-card" data-testid="card-<?php echo esc_attr( $card['cardId'] ); ?>">
				<span class="securepress-card-id"><?php echo esc_html( $card['cardId'] ); ?></span>
				<?php if ( $card['isCritical'] ) : ?>
					<span class="securepress-autonomy-risk-badge" data-testid="autonomy-risk-badge">
						<?php esc_html_e( 'AUTONOMY RISK', 'securepress-2026' ); ?>
					</span>
				<?php endif; ?>
				<?php if ( 'design_harm' === $card['cardKind'] ) : ?>
					<span class="securepress-design-harm-badge" data-testid="design-harm-badge">
						<?php esc_html_e( 'harm projektowy', 'securepress-2026' ); ?>
					</span>
				<?php else : ?>
					<span class="securepress-severity-badge securepress-severity-<?php echo esc_attr( $card['severity'] ); ?>" data-testid="severity-badge">
						<?php echo esc_html( $card['severity'] ); ?>
					</span>
				<?php endif; ?>
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

	<?php if ( array() === $cards ) : ?>
		<p><?php esc_html_e( 'Brak kart dla podanego suit/edition.', 'securepress-2026' ); ?></p>
	<?php endif; ?>
</main>
<?php
get_footer();
