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
		<?php if ( array() === $threat['mitigations'] ) : ?>
			<p><?php esc_html_e( 'Brak jeszcze zdefiniowanych mitigacji dla tego zagrożenia.', 'securepress-2026' ); ?></p>
		<?php endif; ?>
		<?php foreach ( $threat['mitigations'] as $mitigation ) : ?>
			<article class="securepress-mitigation" data-testid="mitigation-<?php echo esc_attr( $mitigation['slug'] ); ?>">
				<h3><?php echo esc_html( $mitigation['title'] ); ?></h3>
				<p><?php echo esc_html( $mitigation['description'] ); ?></p>
				<p class="securepress-mitigation-meta">
					<span><?php esc_html_e( 'Typ:', 'securepress-2026' ); ?> <?php echo esc_html( $mitigation['mitigationType'] ); ?></span>
					<span><?php esc_html_e( 'Nakład:', 'securepress-2026' ); ?> <?php echo esc_html( $mitigation['effort'] ); ?></span>
					<span><?php esc_html_e( 'Skuteczność:', 'securepress-2026' ); ?> <?php echo esc_html( $mitigation['effectiveness'] ); ?></span>
				</p>
			</article>
		<?php endforeach; ?>
	</section>

	<section id="code-samples" data-testid="code-samples">
		<h2><?php esc_html_e( 'Próbki Kodu', 'securepress-2026' ); ?></h2>
		<?php foreach ( $threat['mitigations'] as $mitigation ) : ?>
			<?php
			$by_language = array();
			foreach ( $mitigation['codeSamples'] as $sample ) {
				$by_language[ $sample['language'] ][] = $sample;
			}
			$languages = array_keys( $by_language );
			?>
			<div class="securepress-code-panel" data-testid="code-panel-<?php echo esc_attr( $mitigation['slug'] ); ?>">
				<h3><?php echo esc_html( $mitigation['title'] ); ?></h3>
				<?php if ( array() === $languages ) : ?>
					<p><?php esc_html_e( 'Brak jeszcze próbek kodu dla tej mitigacji.', 'securepress-2026' ); ?></p>
				<?php endif; ?>
				<div class="securepress-language-tabs" role="tablist">
					<?php foreach ( $languages as $index => $lang ) : ?>
						<button type="button" data-language-tab="<?php echo esc_attr( $lang ); ?>"
							aria-selected="<?php echo 0 === $index ? 'true' : 'false'; ?>">
							<?php echo esc_html( strtoupper( $lang ) ); ?>
						</button>
					<?php endforeach; ?>
				</div>
				<?php foreach ( $languages as $lang ) : ?>
					<div data-language-body="<?php echo esc_attr( $lang ); ?>">
						<?php foreach ( $by_language[ $lang ] as $sample ) : ?>
							<?php if ( 'defense' === $sample['sampleType'] ) : ?>
								<div class="securepress-code-defense">
									<p class="securepress-code-sample-title"><?php echo esc_html( $sample['title'] ); ?></p>
									<pre><code><?php echo esc_html( $sample['code'] ); ?></code></pre>
									<p class="securepress-code-framework-hint"><?php echo esc_html( $sample['frameworkHint'] ); ?> — <?php echo esc_html( $sample['versionNote'] ); ?></p>
								</div>
							<?php else : ?>
								<details class="securepress-code-attack-demo" data-testid="attack-demo">
									<summary class="securepress-attack-demo-label">
										<?php esc_html_e( 'ATTACK DEMO — kod podatny, kliknij aby potwierdzić i zobaczyć (nie używać w produkcji)', 'securepress-2026' ); ?>
									</summary>
									<pre data-testid="attack-demo-code-body"><code><?php echo esc_html( $sample['code'] ); ?></code></pre>
								</details>
							<?php endif; ?>
						<?php endforeach; ?>
					</div>
				<?php endforeach; ?>
			</div>
		<?php endforeach; ?>
	</section>

	<section id="cross-references">
		<h2><?php esc_html_e( 'Powiązania Cross-Framework', 'securepress-2026' ); ?></h2>

		<?php $kill_chain = ( new \SecurePress\Service\Killchain_Service() )->for_threat_code( $threat['code'] ); ?>
		<?php if ( array() !== $kill_chain ) : ?>
			<h3><?php esc_html_e( 'Oś czasu MITRE ATLAS (Kill-Chain)', 'securepress-2026' ); ?></h3>
			<!--
				No-JS baseline: a plain ordered list, fully readable without any
				script. mitre-killchain.js progressively enhances this exact
				markup into an SVG timeline (PLAN.md §6 Phase 4) — it never
				replaces this list, only adds a rendering next to it, so the
				list stays present and correct even if the enhancement fails.
			-->
			<ol class="securepress-killchain" data-testid="killchain" data-killchain="<?php echo esc_attr( wp_json_encode( $kill_chain ) ); ?>">
				<?php foreach ( $kill_chain as $stage ) : ?>
					<li>
						<strong><?php echo esc_html( $stage['tactic'] ); ?></strong>
						<?php if ( null !== $stage['id'] ) : ?>
							<span class="securepress-killchain-tactic-id"><?php echo esc_html( $stage['id'] ); ?></span>
						<?php endif; ?>
						<?php if ( null !== $stage['technique'] ) : ?>
							<span class="securepress-killchain-technique"><?php echo esc_html( $stage['technique'] ); ?></span>
						<?php endif; ?>
					</li>
				<?php endforeach; ?>
			</ol>
			<div class="securepress-killchain-svg" data-testid="killchain-svg" aria-hidden="true"></div>
		<?php endif; ?>
	</section>
</main>
<?php
get_footer();
