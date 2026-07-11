<?php
/**
 * templates/matrix.php — cross-framework matrix landing + sub-views (US-04,
 * FR-04, FR-06.2, FR-07.2, FR-10.2). One parameterized template for
 * /matrix/, /matrix/llm/, /matrix/agentic/, /matrix/mobile-vs-web/, in the
 * same spirit as suit-archive.php's ?suit=/?edition= parameterization.
 */

declare( strict_types = 1 );

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

use SecurePress\Service\Matrix_Service;
use SecurePress\Templates\Language_Switcher;
use SecurePress\Templates\Template_Loader;

$type    = Template_Loader::param( 'securepress_matrix_type' ) ?? '';
$service = new Matrix_Service();

get_header();
?>
<main class="securepress securepress-matrix" data-testid="matrix">
	<?php Language_Switcher::render(); ?>
	<h1><?php esc_html_e( 'Macierze Cross-Framework', 'securepress-2026' ); ?></h1>

	<?php if ( '' === $type ) : ?>
		<ul>
			<li><a href="<?php echo esc_url( home_url( '/matrix/llm/' ) ); ?>"><?php esc_html_e( 'OWASP LLM Top 10 ↔ Karty Cornucopia LLM', 'securepress-2026' ); ?></a></li>
			<li><a href="<?php echo esc_url( home_url( '/matrix/agentic/' ) ); ?>"><?php esc_html_e( 'OWASP Agentic AI Top 10 ↔ OWASP LLM Top 10', 'securepress-2026' ); ?></a></li>
			<li><a href="<?php echo esc_url( home_url( '/matrix/mobile-vs-web/' ) ); ?>"><?php esc_html_e( 'MASVS 2.0 ↔ OWASP Web Top 10', 'securepress-2026' ); ?></a></li>
		</ul>

	<?php elseif ( 'llm' === $type ) : ?>
		<h2><?php esc_html_e( 'OWASP LLM Top 10 ↔ Karty Cornucopia LLM', 'securepress-2026' ); ?></h2>
		<?php $llm = $service->llm(); ?>
		<table data-testid="matrix-llm">
			<?php foreach ( $llm['rows'] as $row ) : ?>
				<tr>
					<td><strong><?php echo esc_html( $row['threatCode'] ); ?></strong> — <?php echo esc_html( $row['threatTitle'] ); ?></td>
					<td>
						<?php if ( array() === $row['cardIds'] ) : ?>
							<span class="securepress-matrix-gap">—</span>
						<?php else : ?>
							<?php echo esc_html( implode( ', ', $row['cardIds'] ) ); ?>
						<?php endif; ?>
					</td>
				</tr>
			<?php endforeach; ?>
		</table>

	<?php elseif ( 'agentic' === $type ) : ?>
		<h2><?php esc_html_e( 'OWASP Agentic AI Top 10 ↔ OWASP LLM Top 10', 'securepress-2026' ); ?></h2>
		<?php $agentic = $service->agentic(); ?>
		<?php if ( null !== $agentic['note'] ) : ?>
			<p class="securepress-phase-note"><?php echo esc_html( $agentic['note'] ); ?></p>
		<?php endif; ?>
		<p><?php esc_html_e( 'Karty AAI (Agentic AI):', 'securepress-2026' ); ?> <?php echo esc_html( implode( ', ', $agentic['aaiCardIds'] ) ); ?></p>

	<?php elseif ( 'mobile-vs-web' === $type ) : ?>
		<h2><?php esc_html_e( 'MASVS 2.0 ↔ OWASP Web Top 10', 'securepress-2026' ); ?></h2>
		<p class="securepress-phase-note">
			<?php esc_html_e( 'Zestawienie porównawcze, nie formalny crosswalk — MASVS i OWASP Web Top 10 opisują różne warstwy aplikacji.', 'securepress-2026' ); ?>
		</p>
		<?php $mvw = $service->mobile_vs_web(); ?>
		<h3><?php esc_html_e( 'Kategorie MASVS', 'securepress-2026' ); ?></h3>
		<ul>
			<?php foreach ( $mvw['masvsCategories'] as $category => $card_ids ) : ?>
				<li><strong><?php echo esc_html( $category ); ?></strong>: <?php echo esc_html( implode( ', ', $card_ids ) ); ?></li>
			<?php endforeach; ?>
		</ul>
		<h3><?php esc_html_e( 'OWASP Web Top 10', 'securepress-2026' ); ?></h3>
		<ul>
			<?php foreach ( $mvw['webTop10'] as $threat ) : ?>
				<li><strong><?php echo esc_html( $threat['code'] ); ?></strong> — <?php echo esc_html( $threat['title'] ); ?></li>
			<?php endforeach; ?>
		</ul>
	<?php endif; ?>
</main>
<?php
get_footer();
