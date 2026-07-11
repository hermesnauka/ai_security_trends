# SecurePress 2026 — WordPress/PHP implementation (app09_php_WORDPRESS)

See `../CLAUDE.md` for the sibling list and shared local-dev notes. SecureVision is a
threat-modeling reference app (browse security frameworks + threats, one hardcoded admin
login). Unlike every other sibling, this app does **not** mirror app01's REST API — see
`../app01_react` only for what Phase-1 parity means elsewhere, not as a contract here.

## Current state

Planning docs (`PLAN.md`, `requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md`)
plus a **Phase 1 foundation scaffold** of the plugin exist under
`wp-content/plugins/securepress-2026/`: plugin bootstrap, `composer.json`, `dbDelta()`
schema + constraint-add step for all 8 tables (`includes/data/class-schema.php`),
activation/role registration (`includes/class-plugin.php`), `Framework`/`Threat`
repositories + services, REST routes for `frameworks`/`threats`/`health` with explicit
`permission_callback`s and Transients-based rate limiting, three PHP templates
(`home.php`, `archive-threat.php`, `single-threat.php`) with a working PL⇄EN language
switch, and three vanilla-JS modules (`threat-browser.js`, `language-toggle.js`,
`code-sample-panel.js`). Seed data covers the full frameworks catalogue plus OWASP Web
Top 10 (A01–A10) and OWASP LLM Top 10 (LLM01–10) threats. `docker-compose.yml` +
`nginx/default.conf` exist but are untested on this machine (no Docker here, per
`../CLAUDE.md`) and no `composer install`/`vendor/` has been run.

**Cornucopia card ingestion is now built** (PLAN.md §6 Phase 3, though it was requested in
this session as "Phase 2" — a numbering mismatch worth knowing about, not a contradiction):
`includes/cards/class-card-loader.php` (symfony/yaml decode + curation-file merge +
allow-list validation, D-08), `includes/integrity/class-integrity-verifier.php` (SHA-256
check, D-03, called only from activation + `includes/cron/class-periodic-reverify-job.php`),
`includes/service/class-reference-validator.php` (SR-07), `Card_Repository`/`Card_Service`,
and a `suit`/`edition` param on the existing `/threats` REST route that delegates to cards
(PLAN.md §7's unified-listing requirement) rather than a parallel `/cards` endpoint. All six
raw YAML decks are copied into `data/cornucopia/` with a real `data/hashes.json`. Curation
(`data/cornucopia/curation/*.curation.json`) and Polish translations
(`data/cornucopia/translations/pl.cards.json`) cover a **representative sample of cards per
deck** (the same ones already referenced in `user_stories+tests.md`'s test sketches, e.g.
`VE3`, `AAIK`, `SCO2`, `EMR2`) — not the full card count in any deck (STRIDE alone has far
more than what's curated here). Extending curation to every remaining card is real
content-authorship work meant to go through the `PLAN.md` §12 CODEOWNERS review process, not
something to assume is complete. `suit-archive.php` (generic, `?suit=`/`?edition=`) and
`digital-harms.php` (dedicated — never renders severity) exist for `/frameworks/{slug}/`;
`stride-catalogue.php`'s dedicated heatmap and `devops-security.php`'s combined DVO+CLD+BOT
view from `PLAN.md` §8 are simplified to `suit-archive.php` for now, not built as their own
templates yet.

**Mitigations + 5-language code samples are now built** (PLAN.md §6 Phase 4): `sp_mitigations`
gained a `slug` column (not in the original PLAN.md §5.1 text — added and documented there
too) so seed data can upsert idempotently by a stable key instead of a fragile options-table
lookup. `Mitigation_Repository`/`Service`, `Code_Sample_Repository`/`Service`, and
`Mitigation_Seed_Loader` (wired into activation after cards) seed **5 representative
mitigations** — SQL injection (A03), broken access control (A01), prompt injection (LLM01),
rate-limiting for unbounded consumption (LLM10 + card `LLM2`), and supply-chain dependency
integrity (A08) — each with a real attack_demo + defense code pair in all five languages
(50 files total under `data/code_samples/{python,java,go,scala,lua}/`, manifest in
`data/code_samples_manifest.json`). **Not every seeded threat has a mitigation yet** — only
these 5, matching the same representative-slice pattern as card curation. `single-threat.php`
now renders real mitigations + tabbed code samples: language bodies are server-rendered fully
visible (JS only collapses them into tabs once loaded, so nothing is JS-only), and the
attack-demo gate is a native `<details>`/`<summary>` disclosure (not a `<dialog>` — a
`<dialog>` can't be opened at all without JavaScript, which would have broken the JS-disabled
requirement). A MITRE ATLAS kill-chain timeline (`assets/js/mitre-killchain.js`, SVG, no
charting dependency) renders for the 4 threats with data in `data/mitre_atlas_killchain.json`,
alongside — never replacing — a plain `<ol>` that is the actual accessible/no-JS content.

**i18n `.pot`/`.po`/`.mo` files are now built** (PLAN.md §6 Phase 5), with two things worth
knowing before touching them:

1. **This sandbox has neither WP-CLI nor `msgfmt`/`gettext` tools installed**, so
   `languages/securepress-2026.pot`/`-pl_PL.po`/`-en_US.po` were produced by a one-off Python
   extraction script (not committed — it was a throwaway), and the two `.mo` binaries were
   compiled by a hand-written GNU-MO-format writer, independently verified by reading them
   back with Python's stdlib `gettext` module (including correct 3-form Polish pluralization:
   n=22 → "zagrożenia", not "zagrożeń"). `.github/workflows/i18n-check.yml` wires in the
   *real* `wp i18n make-pot`/`make-mo` tools as the ongoing drift-check (FR-18.7/NFR-06.3) —
   that workflow has never actually run in this repo (no CI runner has executed it yet), and
   the real tool's regenerated `.pot` may format entries slightly differently than the Python
   stopgap that produced the current committed file, even though its content should agree.
2. **A future run of the real `wp i18n make-pot` tool must not "fix" a few deliberately
   untranslated terms** — `AUTONOMY RISK` and `Severity` are fixed English badge/label terms
   kept as-is in both `pl_PL.po` and `en_US.po` (matching the "ATTACK DEMO" convention already
   in the mixed-language sentence at `single-threat.php`), and `Digital-by-Default Harms` is a
   proper noun left untranslated everywhere in this project, including `user_stories+tests.md`.
   Separately, a handful of msgids are **authored in English** even though Polish is the
   default locale — `Framework not found.`, `Threat not found.`, `Too many requests.`,
   `Search query must be 200 characters or fewer.`, `SecurePress Editor`, and the MySQL-version
   guard message in `class-plugin.php` — these are REST error responses and one admin role
   name; `pl_PL.po` carries real Polish translations for them (not identity), which is the
   reverse direction from every other string in this plugin.

`sp_threat_translations` (FR-18.4) is also now actually used — it was defined in the schema
since Phase 1 but nothing populated or read it until now.
`includes/data/class-threat-translation-repository.php` +
`class-threat-translation-seed-loader.php` seed **Polish translations for all 20 seeded
threats** (the full OWASP Web + LLM Top 10 set, not a smaller slice this time), and
`Threat_Service::list()`/`find()` now take a `$locale` parameter with an EN fallback
(FR-18.6), wired from `?lang=` in `Threat_Controller`, `archive-threat.php`, and
`single-threat.php`.

**Still not built:** mitigations/code samples for any threat or card beyond the 5 from Phase
4, admin screens (`includes/admin/` is an empty directory), search/export (Phase 6), the
dedicated stride-heatmap/matrix pages, and all tests (`tests/`, `e2e/` don't exist yet —
nothing in this plugin has been executed against a real WordPress+MySQL instance; no
`composer install` has been run either). Verify against the filesystem, not this paragraph,
before assuming a later-phase feature exists.

## Architecture: one WordPress plugin, not a backend + SPA

Every other sibling (app01–app08, app10) pairs a custom backend with a React/Angular SPA.
This app is deliberately different (`PLAN.md` §0, §8) — do not "fix" this:

- **One self-contained plugin** (`securepress-2026`), not split across a plugin + theme.
- **Frontend = WordPress Template Hierarchy** (`archive-threat.php`, `single-threat.php`,
  registered via `template_include`), progressively enhanced with vanilla JS (ES2022)
  calling the WP REST API via `fetch`. No React/SPA framework — pages must work with JS
  disabled.
- **No separate backend service.** `wp-json/securepress/v1/*` routes live in the same
  plugin, served by the same PHP-FPM process as the templates. No `backend/`/`frontend/`
  directory split.

## Key decisions before writing code (full detail: `PLAN.md` §2–5)

- **Storage:** custom `$wpdb` tables (`sp_frameworks`, `sp_threats`, `sp_cards`,
  `sp_mitigations`, `sp_code_samples`, `sp_cross_references`, `sp_content_hashes`,
  `sp_threat_translations`) via `dbDelta()` — not CPTs + postmeta (schema: PLAN.md §5.1).
- **Auth:** WordPress users/roles/capabilities (`current_user_can()`), a new
  `securepress_editor` role + `manage_securepress` capability. No JWT layer. CSRF via
  WordPress nonces (`wp_verify_nonce`, `X-WP-Nonce`).
- **API:** WP REST API, namespace `securepress/v1` (`register_rest_route`). Every route
  needs an **explicit** `permission_callback` — an omitted one is a known WP REST vuln
  class. Map to WP REST conventions, not app01's DTO shapes.
- **SQL safety is runtime-only:** always `$wpdb->prepare()`, no compile-time query
  checking (PHP has none). WPCS `WordPress.DB.PreparedSQL` is the closest lint substitute.
  One guarantee here is *stronger* than any sibling's: the Digital-by-Default Harms
  "no severity on a design-harm card" rule is a MySQL 8.0.16+ `CHECK` constraint
  (PLAN.md §4 D-04), enforced even against a raw query outside the app.
- **i18n:** WordPress's native gettext (`__()`, `esc_html_e()`, `.pot`/`.po`/`.mo` via
  `load_plugin_textdomain()`) for UI strings — not a bespoke toggle. Threat *content*
  translations live in `sp_threat_translations`, separate from UI-string i18n.
- **Versions:** WordPress 6.8+, PHP 8.3, MySQL 8.0.16+ (the `CHECK`-constraint floor) or
  MariaDB 10.11+. Composer (`roave/security-advisories`), `symfony/yaml` for parsing.

## Local dev tooling: scaffolded but unverified

`docker-compose.yml` (WordPress/PHP-FPM + MySQL 8.4 + Redis + Nginx) and
`nginx/default.conf` exist at the app root, per `PLAN.md` Phase 1, but have never been
run — this machine has no Docker (`../CLAUDE.md`), so treat them as unverified source
until someone runs `docker compose up --build` somewhere Docker is available. `wp-env`
integration for CI parity is not set up yet.

## Where to look for more

`PLAN.md` is the primary source: §0 (why this app differs), §3 (architecture — WP-Cron
runs in-process, no separate worker binary), §4 (D-01–D-09 design decisions), §5 (schema),
§6 (build plan), §7 (endpoint map).
