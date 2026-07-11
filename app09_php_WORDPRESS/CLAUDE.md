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

**Search/export/matrix are now built** (PLAN.md §6 Phase 6). Three schema additions beyond
the original PLAN.md §5.1 text (now documented there too, same pattern as the mitigations
`slug` column in Phase 4): a `sp_export_jobs` table, and FULLTEXT indexes on
`sp_threats(title, description)` / `sp_cards(description_en, description_pl)` — both added
via `ALTER TABLE` in `Schema::add_fulltext_indexes()`/`add_export_jobs...` rather than
embedded in the `dbDelta()` `CREATE TABLE` strings, for the same reliability reason as
D-02/D-04's constraints. Specifics worth knowing:

- **Search** (`Search_Repository`/`Service`, `GET /search`, `search-results.php`): real
  `MATCH...AGAINST` natural-language-mode search across both threats and cards, with
  server-side `<mark>`-highlighted excerpts.
- **Export** (`sp_export_jobs`, `Export_Job` cron class, `Export_Controller`,
  `export-panel.js`): **CSV only — PDF is explicitly rejected with a 422**, not silently
  downgraded, since `composer.json` has no PDF library. The REST create route never blocks
  on the export itself; `wp_schedule_single_event()` runs `Export_Job::run()` out-of-band,
  polled via `/export/status/{jobId}`. The no-JS baseline is a plain link to the REST
  endpoint that returns `{jobId, statusUrl}` JSON directly — functional, not seamless;
  `export-panel.js` intercepts the click and polls for a download link.
- **Matrix / cross-references / STRIDE heatmap** (`Matrix_Service`/`Controller`, `matrix.php`,
  `stride-heatmap.php`): `/matrix/llm/` has real data on both sides (OWASP LLM Top 10 threats
  × Cornucopia LLM cards, matched via each card's curated `owasp_refs`). `/matrix/agentic/`
  returns an **honest empty-state** — no OWASP Agentic AI Top 10 threats are seeded at all
  (`requirements.md` DR-01.4), so it shows only the AAI suit cards with a note, rather than
  fabricating comparison rows. `/matrix/mobile-vs-web/` is a side-by-side juxtaposition, not
  a formal crosswalk — no official MASVS↔Web-Top-10 mapping exists since they cover different
  application layers. `/stride-heatmap/` (capability-gated, `manage_securepress` or the new
  `securepress_trainer` capability — 401 if logged out, 403 if logged in but lacking the
  capability) is a simplified count of curated STRIDE-suit cards per category, **not**
  "per system component" as `PLAN.md`'s own aspirational description reads — this schema has
  no system-component entity to attach coverage to. `sp_cross_references` (defined since
  Phase 1, unused until now) is seeded with **4 genuinely-defensible** OWASP-Web↔OWASP-LLM
  relationships (e.g. A03:2021 Injection ↔ LLM01:2025 Prompt Injection), not an exhaustive
  cross-framework matrix, and now renders on `single-threat.php` alongside the kill-chain.
- The `.pot`/`.po`/`.mo` files from Phase 5 were regenerated to include the ~24 new strings
  this phase introduced, using the same one-off Python tooling (see the i18n note above) —
  independently re-verified with Python's `gettext` module after regenerating.

**Hardening/testing/release (PLAN.md §6 Phase 7) is now built too — read this before trusting
any "it's tested" assumption.** This sandbox has no PHP, Composer, MySQL, WordPress, Node
(it does, actually — see below), WPScan, or ZAP runtime capable of *executing* any of this;
everything in this paragraph is real, structurally-correct source that has never been run
end-to-end, same caveat as `docker-compose.yml` since Phase 1:

- **PHPUnit** (`tests/unit/`, 11 test classes) — bootstrap (`tests/bootstrap.php`) uses
  `wp-phpunit/wp-phpunit` so `composer install && vendor/bin/phpunit` is self-contained, no
  system-wide WP checkout needed. Covers `Framework_Service`, `Threat_Service` (incl. locale
  fallback), `Card_Service` (incl. the FR-19.2(b) severity-key-omission check),
  `Mitigation_Service` (incl. the `lua-resty-limit-req` assertion), `Search_Service`,
  `Matrix_Service` (incl. the honest-empty-state assertion), `Reference_Validator`,
  `Card_Loader`, `Integrity_Verifier`, `Rate_Limiter`, and REST controllers
  (`ThreatControllerTest`, `ExportControllerTest`, `StrideHeatmapControllerTest` — the last one
  asserts 401 vs 403 are genuinely different responses). **`DesignHarmConstraintTest` is the
  one test in this whole project that actually exercises the D-04 `CHECK`-constraint claim** —
  a raw `$wpdb->query()` bypassing every repository/service, same as the sketch in
  `user_stories+tests.md`.
- **eris property tests** (`tests/property/`) — `CardLoaderPropertyTest` writes randomly-keyed
  temp deck files directly under `data/cornucopia/` (Card_Loader has no injectable base path)
  and cleans them up in a `finally` block; `ReferenceValidatorPropertyTest` asserts any string
  outside the fixed allowlist is rejected. Both use explicit try/catch/fail instead of
  `expectException()`, since the latter isn't safe to call once per eris iteration.
- **wp-browser/Codeception** (`codeception.yml`, `tests/acceptance/`, 5 Cest files) —
  `AttackDemoConfirmationCest`, `DigitalHarmsCest`, `NoJsFilteringCest`, `RateLimitCest`,
  `ThreatBrowserCest`. `tests/Support/AcceptanceTester.php` is hand-written (normally
  `codecept build` generates it — not runnable here) and safe to overwrite.
- **Playwright E2E** (`e2e/` at the **app root**, not inside the plugin — a Node/TypeScript
  toolchain, not a WP concern) — one spec file per user story, US-01 through US-19 (US-08 is
  split into an unauthenticated and a `-authenticated` file so the 401-vs-logged-in-admin cases
  don't conflict under Playwright's per-project `storageState`; see `auth.setup.ts` and the
  `chromium-authenticated` project in `playwright.config.ts`). **This is the one part of Phase
  7 actually verified in this session** — `npx tsc --noEmit` was run for real (TypeScript 7.0.2
  + `@playwright/test` + `@types/node`, network access worked) against all 20 spec files with
  zero errors, then the temporary `node_modules`/`package-lock.json` were deleted since they
  aren't meant to be committed.
- **CI** (`.github/workflows/ci.yml`, `zap-scan.yml`, plus `i18n-check.yml` from Phase 5) — the
  full SAST → SCA → PHPUnit → Codeception → Playwright pipeline `SDLC_analysis.md` describes,
  wired as real GitHub Actions jobs. ZAP's full active scan is separate (`workflow_dispatch` +
  weekly schedule) since it needs a deployed staging target, not an ephemeral CI container.
  **None of these workflows have ever executed in this repo.**
- **Release process** was already documented in `SDLC_analysis.md` §5 (Deployment) from the
  original authoring — pinned versions, staging-first rollout, not WordPress's default
  auto-update-everything — so nothing new was added there.

**Still not built:** mitigations/code samples for any threat or card beyond the 5 from Phase
4, admin screens (`includes/admin/` is an empty directory), the dedicated
`stride-catalogue.php`/`devops-security.php` templates (still simplified to `suit-archive.php`).
Every `PLAN.md` §6 phase now has *some* real implementation, but coverage within each phase is
consistently a representative slice, not exhaustive — verify against the filesystem, not this
paragraph, before assuming full completeness of any feature.

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
