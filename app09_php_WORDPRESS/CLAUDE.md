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

**Still not built:** Cornucopia card ingestion (`includes/cards/`, `includes/integrity/`
are empty directories), curation files, mitigations/code-samples data and UI, cron jobs,
admin screens, search/export, matrix/heatmap pages, i18n `.po`/`.mo` files, and all tests
(`tests/`, `e2e/` don't exist yet). `PLAN.md` §6 phases 2–7 remain aspirational — verify
against the filesystem, not this paragraph, before assuming a later-phase feature exists.

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
