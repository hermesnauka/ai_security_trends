# SecurePress 2026 — WordPress/PHP implementation (app09_php_WORDPRESS)

See `../CLAUDE.md` for the sibling list and shared local-dev notes. SecureVision is a
threat-modeling reference app (browse security frameworks + threats, one hardcoded admin
login). Unlike every other sibling, this app does **not** mirror app01's REST API — see
`../app01_react` only for what Phase-1 parity means elsewhere, not as a contract here.

## Architecture: one WordPress plugin, not a backend + SPA

Every other sibling (app01–app08, app10) pairs a custom backend with a React/Angular SPA.
This app is deliberately different (`PLAN.md` §0, §8) — do not "fix" this:

- **One self-contained plugin** (`securepress-2026`), not split across a plugin + theme.
- **Frontend = WordPress Template Hierarchy** (`includes/templates/*.php`, registered via
  `template_include`), progressively enhanced with vanilla JS (ES2022) calling the WP REST
  API via `fetch`. No React/SPA framework — every page works with JS disabled: JS-dependent
  UI (language toggle, code-sample tabs, kill-chain SVG, export polling) always degrades to a
  server-rendered equivalent rather than breaking.
- **No separate backend service.** `wp-json/securepress/v1/*` routes live in the same
  plugin, served by the same PHP-FPM process as the templates. No `backend/`/`frontend/`
  directory split.

## Current state (verify against the filesystem before trusting this)

The plugin under `wp-content/plugins/securepress-2026/` implements all seven phases from
`PLAN.md` §6 (foundation, browser, card ingestion, mitigations/code samples, i18n,
search/export/matrix, hardening/testing), but **every phase's coverage is a representative
slice, not exhaustive** — this is the single most important thing to know before assuming a
feature is "done":

- **Seeded content:** all frameworks, but only 20 threats (OWASP Web Top 10 + LLM Top 10, in
  full) carry real data; other frameworks (Agentic AI, API, Client-Side, CI/CD, OAT, MASVS,
  MITRE ATLAS, CompTIA) exist as catalogue rows with no seeded threats.
- **Cornucopia cards:** all six raw YAML decks are ingested with real SHA-256 integrity
  checks, but curation (severity/OWASP/MITRE refs) and Polish translations exist for only a
  representative sample of cards per deck (e.g. `VE3`, `AAIK`, `SCO2`, `EMR2`), not every
  card — STRIDE alone has far more cards than are curated.
- **Mitigations:** only 5 mitigations exist (SQL injection, broken access control, prompt
  injection, unbounded-consumption rate limiting, supply-chain dependency integrity), each
  with a real attack-demo + defense code sample in all five languages (Python/Java/Go/Scala/
  Lua). Most seeded threats and cards have no mitigation yet.
- **i18n:** `.pot`/`.po`/`.mo` files exist and are independently verified to parse correctly
  (including 3-form Polish pluralization), but were compiled with one-off Python tooling, not
  WP-CLI/`msgfmt` (neither is installed anywhere this app has been worked on) — see
  `.github/workflows/i18n-check.yml` for the real tool that should supersede that stopgap.
  `AUTONOMY RISK`, `Severity`, and `Digital-by-Default Harms` are deliberately left
  untranslated in both locales (fixed badge/proper-noun terms) — don't "fix" that.
  Conversely, a handful of REST error messages and the `SecurePress Editor` role name are
  authored in English despite Polish being the default locale, so `pl_PL.po` translates
  those specifically — the reverse direction from every other string.
- **Search/export/matrix:** FULLTEXT search and CSV export (WP-Cron based, polled via REST)
  work over whatever content is seeded. PDF export is explicitly rejected (422), not
  implemented — no PDF library exists in `composer.json`. `/matrix/agentic/` and
  `/matrix/mobile-vs-web/` report their own incompleteness/lack-of-formal-mapping rather than
  padding out invented data. `/stride-heatmap/` is a simplified per-category card count, not
  the "per system component" coverage `PLAN.md`'s aspirational text describes.
- **Tests exist for everything above** (`tests/unit`, `tests/property`, `tests/acceptance`,
  `e2e/` at the app root) plus a full CI pipeline (`.github/workflows/`), but **nothing has
  ever been executed** — this environment has no PHP, Composer, MySQL, WordPress, WPScan, or
  ZAP runtime. The one exception: the Playwright E2E specs were genuinely type-checked with a
  real `tsc` (TypeScript fetched via npm), zero errors, across all 20 spec files.
- **Not built at all:** wp-admin CRUD screens (`includes/admin/` is empty), dedicated
  `stride-catalogue.php`/`devops-security.php` templates (both simplified to the generic
  `suit-archive.php` for now).

Two schema additions exist beyond `PLAN.md`'s original §5.1 text, both now documented there
too: a `slug` column on `sp_mitigations`, and a `sp_export_jobs` table + FULLTEXT indexes
(all three added via `ALTER TABLE` rather than embedded in `dbDelta()`'s `CREATE TABLE`
strings, since dbDelta's parser isn't reliable for constraints/FULLTEXT — same reasoning as
the `CHECK`/`FOREIGN KEY` constraints below).

## Key decisions before writing code (full detail: `PLAN.md` §2–5)

- **Storage:** custom `$wpdb` tables (`sp_frameworks`, `sp_threats`, `sp_cards`,
  `sp_mitigations`, `sp_code_samples`, `sp_cross_references`, `sp_content_hashes`,
  `sp_threat_translations`, `sp_export_jobs`) via `dbDelta()` — not CPTs + postmeta (schema:
  `PLAN.md` §5.1). `FOREIGN KEY`/`CHECK`/`FULLTEXT` clauses are added via a separate
  `ALTER TABLE` step in `Schema`, not embedded in the `dbDelta()` strings — dbDelta's parser
  doesn't reliably handle those.
- **Auth:** WordPress users/roles/capabilities (`current_user_can()`), a new
  `securepress_editor` role + `manage_securepress`/`securepress_trainer` capabilities. No JWT
  layer. CSRF via WordPress nonces (`wp_verify_nonce`, `X-WP-Nonce`).
- **API:** WP REST API, namespace `securepress/v1` (`register_rest_route`). Every route
  needs an **explicit** `permission_callback` — an omitted one is a known WP REST vuln
  class. A `suit`/`edition` param on `/threats` delegates to cards instead of a parallel
  `/cards` endpoint (the unified-listing shape `PLAN.md` §7 calls for). Map to WP REST
  conventions, not app01's DTO shapes.
- **SQL safety is runtime-only:** always `$wpdb->prepare()`, no compile-time query
  checking (PHP has none). WPCS `WordPress.DB.PreparedSQL` is the closest lint substitute.
  One guarantee here is *stronger* than any sibling's: the Digital-by-Default Harms
  "no severity on a design-harm card" rule is a MySQL 8.0.16+ `CHECK` constraint
  (`PLAN.md` §4 D-04), enforced even against a raw query outside the app —
  `DesignHarmConstraintTest` in `tests/unit/` exercises this directly.
- **i18n:** WordPress's native gettext (`__()`, `esc_html_e()`, `.pot`/`.po`/`.mo` via
  `load_plugin_textdomain()`) for UI strings — not a bespoke toggle. Threat/card *content*
  translations live in `sp_threat_translations`/`sp_cards.description_pl`, separate from
  UI-string i18n, with an English fallback when no Polish row exists.
- **Versions:** WordPress 6.8+, PHP 8.3, MySQL 8.0.16+ (the `CHECK`-constraint floor) or
  MariaDB 10.11+. Composer (`roave/security-advisories`), `symfony/yaml` for YAML parsing.

## Local dev tooling: scaffolded but unverified

`docker-compose.yml` (WordPress/PHP-FPM + MySQL 8.4 + Redis + Nginx), `nginx/default.conf`,
and the full `.github/workflows/` CI pipeline exist but have never been run — this machine
has no Docker, PHP, Composer, or Node runtime capable of executing any of it (`../CLAUDE.md`).
Treat all of it as unverified-but-structurally-correct source until someone runs it in a real
environment. `wp-env` integration for CI parity is not set up.

## Where to look for more

`PLAN.md` is the primary source: §0 (why this app differs), §3 (architecture — WP-Cron runs
in-process, no separate worker binary), §4 (D-01–D-09 design decisions), §5 (schema), §6
(phased build plan), §7 (endpoint map), §9 (plugin file layout). `requirements.md` has the
full FR/SR/NFR list and abuse-case table; `user_stories+tests.md` has the TDD test plan with
real Polish-translated Cornucopia card examples; `SDLC_analysis.md` has the SSDLC/Agile
analysis, including the release process (§5, pinned versions + staging-first rollout).
