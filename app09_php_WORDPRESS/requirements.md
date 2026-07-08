# SecurePress 2026 — Requirements Specification

**Version:** 1.0
**Date:** 2026-07-07
**Project:** `app09_php_WORDPRESS`
**Sources:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`, `docs/OWASP_stories/*.yaml` (all 6 card decks), `PLAN.md`

---

## 1. Scope

SecurePress 2026 is a bilingual (PL/EN) security-education platform built as a **single, self-contained WordPress plugin** — PHP 8.3, vanilla JavaScript, and MySQL 8, with no other backend runtime language and no client-side framework (React, Vue, etc.). It presents OWASP Web/LLM/Agentic AI/API/Client-Side/CI-CD/Automated-Threats/MASVS content, MITRE ATLAS, CompTIA Security+/SecAI+, and all six OWASP Cornucopia-family card decks under `docs/OWASP_stories/`, each threat/card backed by countermeasure code samples in five languages (Python, Java, Go, Scala, Lua). None of those five sample languages is the application's own implementation language.

**This document, like `app08_cpp_react`'s before it, is explicit about where its enforcement mechanisms are weaker than a custom-backend sibling's — and about the one place (the Digital-by-Default Harms deck's data-layer `CHECK` constraint, FR-19.2) where this project's guarantee is arguably stronger than any prior sibling's.** Every requirement below states its enforcement mechanism by name (database constraint, WPCS lint rule, code review, WordPress core function) rather than leaving it implicit.

---

## 2. Functional Requirements

### FR-01 — Framework Catalog (US-01)
- FR-01.1 The home template shall list all supported frameworks: OWASP Web Top 10, LLM Top 10, Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, Automated Threats (OAT), MASVS 2.0, MITRE ATLAS, CompTIA Security+/SecAI+, and the six Cornucopia-family card decks.
- FR-01.2 Each tile shall show name, version, description, reference URL, and threat/card count, rendered server-side in PHP.
- FR-01.3 Clicking a tile shall navigate to that framework's threat/card archive template.

### FR-02 — Threat & Card Browser (US-02)
- FR-02.1 A unified, filterable, searchable list shall cover all threats and all Cornucopia cards, server-rendered on first load and enhanced client-side by `threat-browser.js` for subsequent filtering.
- FR-02.2 Filters (combinable): framework/edition, suit, severity, STRIDE category, category, tag, `q` free text.
- FR-02.3 Sorting: severity (highest first), framework code, alphabetical.
- FR-02.4 Filtering shall debounce at 300 ms and update results via `fetch()` against the REST API without a full page reload; the equivalent filtered results shall also be reachable via standard query-string URL parameters that work with JavaScript disabled (progressive enhancement — no other app in this series has this specific requirement, because none of them are server-rendered by default).

### FR-03 — Threat / Card Detail Page (US-03)
- FR-03.1 Each threat/card shall have a stable-URL detail page (`single-threat.php`) with tabs: Overview | Attack Vectors | Mitigations | Code Samples | Cross-References, implemented as same-page anchored sections that work without JavaScript, with `code-sample-panel.js` providing tabbed switching as an enhancement.
- FR-03.2 Every mitigation shall list at least one code sample per language (Python, Java, Go, Scala, Lua), each in Attack Demo and Defense sub-tabs. As in `app08_cpp_react`, this is verified by an `eris` property test and a CI seed-data linter — PHP has no type-level non-empty-collection guarantee.
- FR-03.3 Code samples shall be grouped by language, each with Attack Demo and Defense sub-tabs, rendered with syntax highlighting (self-hosted Prism.js).
- FR-03.4 Attack-demo code shall require confirming a `<dialog>` element before the code is shown or copyable.

### FR-04 — Cross-Framework Mapping (US-04)
- FR-04.1 A `/matrix/` template shall map threats across frameworks (at minimum OWASP LLM Top 10 ↔ MITRE ATLAS ↔ CompTIA SecAI+).
- FR-04.2 Matrix cells shall link to the corresponding detail page.
- FR-04.3 The "Cross-References" section shall list relationship type (Equivalent/Related/MapsTo/ParentChild).

### FR-05 — Cornucopia: Frontend Security (FRE) (US-05)
- FR-05.1 `/frameworks/frontend-security/` shall display all Cornucopia `FRE` cards from the **Companion Edition v1.0** (`__LLM_AI___companion-cards-1.0-en.yaml`).
- FR-05.2 Cards shall show card ID, value, suit, PL/EN-selectable description, OWASP reference chips.

### FR-06 — Cornucopia: LLM Security (US-06)
- FR-06.1 `/frameworks/llm-security/` shall display all `LLM` suit cards (Companion Edition v1.0).
- FR-06.2 `/matrix/llm/` shall map OWASP LLM Top 10 (2025) entries to Cornucopia `LLM` cards, indicating coverage gaps with an empty dashed cell.

### FR-07 — Cornucopia: Agentic AI + Cloud (US-07)
- FR-07.1 `/frameworks/agentic-ai/` shall display all `AAI` suit cards; cards with value `K`/`A` shall show an `AUTONOMY RISK` badge.
- FR-07.2 `/matrix/agentic/` shall compare OWASP Agentic AI Top 10 (2026) with OWASP LLM Top 10 (2025).
- FR-07.3 `CLD` (Cloud) suit cards shall be displayed on the DevOps template (FR-11) rather than a separate one.

### FR-08 — Cornucopia: STRIDE EoP (US-08)
- FR-08.1 `/frameworks/stride/` shall display all 78 STRIDE EoP v5.0 cards, grouped by the 6 STRIDE suits.
- FR-08.2 `/stride-heatmap/` shall require the `manage_securepress` capability (or a new `securepress_trainer` capability) and show per-system-component STRIDE coverage.

### FR-09 — Cornucopia: ML Security (MLSec) (US-09)
- FR-09.1 `/frameworks/ml-security/` shall display all 52 MLSec v1.0 cards (EMR/EIR/EOR/EDR).
- FR-09.2 Cards shall show MITRE ATLAS reference chips; adversarial-ML/model-extraction cards shall carry an `ML-SPECIFIC` badge.

### FR-10 — Cornucopia: Mobile App Security (US-10)
- FR-10.1 `/frameworks/mobile-security/` shall display all Mobile App Edition v1.1 cards (PC/AA/NS/RS/CRM/CM).
- FR-10.2 `/matrix/mobile-vs-web/` shall compare MASVS 2.0 categories with OWASP Web Top 10.

### FR-11 — Cornucopia: DevOps + Cloud + BOT Security, and WordPress-specific hardening (US-11)
- FR-11.1 `/frameworks/devops-security/` shall contain a DVO section (CICD-SEC chips), a CLD section (A05:2021/A01:2021 chips), and a BOT section (OAT chips).
- FR-11.2 A `bot-warning-modal.js`-driven confirmation `<dialog>` shall appear before any BOT suit card's attack-demo content is shown; acknowledgement stored in a same-origin cookie or `sessionStorage`.
- FR-11.3 DVO and CLD code examples shall be pseudocode only.
- FR-11.4 `GET /wp-json/securepress/v1/threats?suit=bot` shall apply rate limiting (60 req/min per IP).
- FR-11.5 This story additionally covers hardening the WordPress installation itself as a worked example: `xmlrpc.php` disabled, login-attempt rate limiting on `wp-login.php`, `DISALLOW_FILE_EDIT` set, and the WPScan-flagged surface documented in `SDLC_analysis.md` — presented on the DevOps page as a "this very site" case study cross-referenced to the DVO/BOT cards it demonstrates.

### FR-12 — Cornucopia: Website App Security (US-12)
- FR-12.1 `/frameworks/website-app/` shall display all Cornucopia Website App Edition v3.0 cards (VE, AT, SM, AZ, CR, C), grouped by suit.
- FR-12.2 Cards shall cross-reference the OWASP Web Top 10 entry they correspond to (e.g. `VE3` → `A03:2021`).

### FR-13 — Python Code Samples (US-13)
- FR-13.1 Every mitigation with a code sample shall include a Python tab (Django ORM or FastAPI + Pydantic idioms).

### FR-14 — Java Code Samples (US-14)
- FR-14.1 Every mitigation with a code sample shall include a Java tab (Spring Boot 3.3, Spring Security 6, Spring Data JPA).
- FR-14.2 Java code appears **only** as sample content; it is never part of the application's own build.

### FR-15 — Scala Code Samples (US-15)
- FR-15.1 Every mitigation with a code sample shall include a Scala tab (Akka HTTP/http4s, Slick/Doobie, ZIO 2 idioms).

### FR-16 — Lua Code Samples (US-16)
- FR-16.1 Every mitigation with a code sample shall include a Lua tab (OpenResty/NGINX Lua idioms).

### FR-17 — Global Search & Export (US-17, US-18)
- FR-17.1 A search box shall be present on every template, querying threat/mitigation/card text via MySQL `FULLTEXT` indexes (`MATCH...AGAINST`).
- FR-17.2 Results shall be grouped by type with highlighted matching excerpts.
- FR-17.3 Users shall be able to export the filtered threat list as CSV or PDF; export shall run as a WP-Cron job, never blocking the HTTP request that triggers it.
- FR-17.4 The UI shall poll `/wp-json/securepress/v1/export/status/{jobId}` and offer a download link on completion.

### FR-18 — i18n: Polish ↔ English (via WordPress's native mechanism, not a bespoke one)
- FR-18.1 The application shall support Polish and English locales only; the site's WordPress locale setting determines the default, with Polish as this plugin's shipped default configuration.
- FR-18.2 A `language-toggle.js`-driven control in the site header shall switch locales by setting a `?lang=` query variable (or, for logged-in users, their WordPress user-locale preference via `get_user_locale()`), re-fetching translated content without a full page reload where feasible, and falling back to a normal page navigation with JavaScript disabled.
- FR-18.3 All static UI strings shall be wrapped in WordPress's core i18n functions (`__()`, `_e()`, `esc_html__()`, etc.) and present in both `languages/securepress-2026-pl_PL.po`/`.mo` and `languages/securepress-2026-en_US.po`/`.mo`.
- FR-18.4 Threat/card titles, descriptions, and attack-vector text (a separate concern from FR-18.3's UI strings) shall be served in the requested locale from `sp_threat_translations`/`sp_cards.description_pl`/`description_en`.
- FR-18.5 Code samples shall never be translated; in-code comments remain in English.
- FR-18.6 Missing Polish translations shall fall back to English content with a small "EN" badge — never a blank field.
- FR-18.7 CI shall run `wp i18n make-pot` and fail the build if the generated `.pot` file differs from the committed one (this project's equivalent of every sibling's i18n key-parity check).

### FR-19 — Cornucopia: Digital-by-Default Harms (US-19)
- FR-19.1 `/frameworks/digital-harms/` shall display all Cornucopia `dbd-cards-1.0-en.yaml` cards, grouped by suit (SCO, ARC, AGE, TRU, POR).
- FR-19.2 Each card shall render with a design-harm badge, never the severity badge used for technical threats. This shall be enforced at **two independent layers, stronger together than any single prior sibling's mechanism**: (a) the `sp_cards.card_kind` column plus the `chk_design_harm_has_no_severity` MySQL `CHECK` constraint (`PLAN.md` D-04), which rejects any row where `card_kind = 'design_harm'` and `severity` is non-NULL **at the database engine level, regardless of which code path attempts the write**; and (b) the REST API response for these cards omitting the `severity` field entirely when `card_kind = 'design_harm'`, verified by an integration test. Layer (a) is this specification's strongest data-integrity guarantee precisely because it does not depend on any PHP code being correct.
- FR-19.3 Each card shall display a cross-reference chip linking to OWASP A04:2021 Insecure Design, and, where relevant, to the CompTIA SecAI+ GRC/AI-Act topic list.
- FR-19.4 The template shall display a disclaimer banner stating that this deck models *service-design harms in public-sector digital services* (source: `digitalbenefits.uk`), not exploitable technical vulnerabilities.
- FR-19.5 Cards shall be filterable by suit and searchable by description keyword, consistent with FR-05–FR-12.
- FR-19.6 Polish translations of all SCO/ARC/AGE/TRU/POR card descriptions shall be reviewed by a native Polish speaker before merge, following the same i18n gate as FR-18.

---

## 3. Security Requirements

### SR-01 — Authentication & Authorization
- SR-01.1 Admin content management uses WordPress's own session-cookie authentication; no separate JWT layer is introduced (`PLAN.md` D-06).
- SR-01.2 Admin wp-admin screens and any capability-sensitive REST route require `current_user_can( 'manage_securepress' )`, a capability granted to `administrator` and a new `securepress_editor` role registered by this plugin.
- SR-01.3 `/stride-heatmap/` and its backing REST route require `manage_securepress` or a new `securepress_trainer` capability.
- SR-01.4 Every state-changing action (forms, AJAX calls) requires a valid WordPress nonce, verified via `wp_verify_nonce()`/`check_ajax_referer()`; every state-changing REST route requires the `X-WP-Nonce` header, verified by WordPress's REST API nonce middleware.
- SR-01.5 Passwords are hashed by WordPress core's own mechanism (`wp_hash_password`); this plugin implements no password hashing of its own.

### SR-02 — SQL Injection Prevention
- SR-02.1 All database access goes through `$wpdb->prepare()` with `%s`/`%d`/`%f` placeholders (`PLAN.md` D-02). **This gives no compile-time guarantee** — PHP has no mechanism equivalent to `sqlc`/`hasql-th`/`sqlx::query!`/even `app08_cpp_react`'s `sqlpp11` template-metaprogramming approximation. The guarantee here is entirely: (a) the `WordPress.DB.PreparedSQL` WPCS sniff pattern-matching likely-unprepared queries, and (b) code review.
- SR-02.2 CI fails the build on any WPCS `WordPress.DB.PreparedSQL` finding.

### SR-03 — XSS Prevention
- SR-03.1 All output derived from user or card data uses WordPress's contextual escaping functions: `esc_html()` for text nodes, `esc_attr()` for HTML attributes, `esc_url()` for links, `esc_js()` for inline script contexts, and `wp_kses_post()`/a custom `wp_kses()` allow-list for the limited HTML permitted in mitigation descriptions.
- SR-03.2 The WPCS `WordPress.Security.EscapeOutput` sniff runs on every PR and fails the build on any un-escaped output pattern it detects.
- SR-03.3 Admin-edited threat/mitigation text is passed through `wp_kses()` with an explicit allow-list (`b`, `i`, `code`, `pre`, `a[href]`) before persisting, in addition to output-time escaping — defense in depth, the same two-layer pattern every sibling app uses with its own sanitizer.
- SR-03.4 `Content-Security-Policy` (set via a response header, since WordPress core does not set one by default) uses `default-src 'self'`; no `unsafe-inline`/`unsafe-eval`.

### SR-04 — Security Headers
- SR-04.1 A response-header filter (`send_headers` action) injects on every response: CSP, `Strict-Transport-Security` (max-age ≥ 31536000, includeSubDomains), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`. WordPress core does not set these by default, and this plugin does not rely on the hosting environment to have done so either — it sets them itself.
- SR-04.2 OWASP ZAP active scan shall report 0 HIGH/CRITICAL findings.

### SR-05 — Rate Limiting
- SR-05.1 The Transients API, backed by a persistent Redis object cache (`PLAN.md` D-09), enforces 60 req/min/IP on all public `securepress/v1` REST routes.
- SR-05.2 Exhausted budget returns HTTP 429 with `Retry-After`.
- SR-05.3 `/wp-json/securepress/v1/search` additionally enforces a 200-character query-length cap, returning HTTP 422 for longer inputs.
- SR-05.4 `wp-login.php` login attempts are separately rate-limited (a well-known WordPress hardening requirement independent of this plugin's own REST API, included because this app is also a worked example of securing the WordPress installation it runs on, per FR-11.5).

### SR-06 — Content Integrity
- SR-06.1 `Integrity_Verifier::verify()` runs from the plugin activation hook and from `Periodic_Reverify_Job`.
- SR-06.2 On any SHA-256 mismatch against `data/hashes.json`, the calling code aborts — fail-secure, no partial writes (a single `$wpdb` transaction, using `$wpdb->query( 'START TRANSACTION' )`/`COMMIT`/`ROLLBACK` since `$wpdb` has no built-in transaction API).
- SR-06.3 `data/hashes.json` is regenerated only by a CI automation step after a reviewed merge to `main`.
- SR-06.4 `Integrity_Verifier::verify()` is called from no code under `includes/rest-api/`, verified by a custom PHPStan rule and code review (`PLAN.md` D-03) — **the weakest isolation mechanism in this entire series**, since there is no process boundary (contrast every sibling from `app05_go_react` onward) and no compiler-enforced module visibility (contrast `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react`) to fall back on.

### SR-07 — Reference ID Allowlists
- SR-07.1 `OwaspRef`, `MitreRef`, `MavsRef`, `CicdSecRef`, `OatRef` values are validated against allowlists loaded from `data/ref-allowlists.json` / `data/mitre-atlas-allowlist.json` inside a small `Reference_Validator` class before any write to `owasp_refs`/`mitre_refs` JSON columns.
- SR-07.2 Any admin CRUD request supplying an unknown reference ID is rejected with HTTP 422 / a `WP_Error`.

### SR-08 — Digital-by-Default Harms Data Integrity (the strongest guarantee in this specification)
- SR-08.1 The `sp_cards` table's `chk_design_harm_has_no_severity` `CHECK` constraint (`PLAN.md` D-04, requires MySQL 8.0.16+) is the primary enforcement mechanism for FR-19.2, verified by an automated test that attempts a violating `INSERT` directly via `$wpdb->query()` (bypassing all application-layer validation) and asserts MySQL rejects it.
- SR-08.2 This requirement is stated as stronger, in this one specific and narrow respect, than any prior sibling's equivalent (`app06_HASKELL_react`'s sum type, `app07_rust_react`'s enum, `app08_cpp_react`'s `std::variant`) precisely because those all depend on the application's own code being the only path to the data, while a database `CHECK` constraint holds against any client of the database, including future code this plugin's authors have not yet written.

### SR-09 — YAML Parsing Safety
- SR-09.1 All six Cornucopia YAML decks are decoded via `symfony\yaml`'s `Yaml::parseFile()` (never with custom-tag/object-support flags enabled) followed by hand-written allow-list key validation against a `CardFile` shape (`PLAN.md` D-08) — PHP has no derive-macro or strict-decode-by-default mechanism, so this discipline is hand-maintained code, the same accepted gap `app08_cpp_react` states for its own hand-written decoders.
- SR-09.2 An `eris` property test generates YAML documents with random extra keys and asserts rejection.
- SR-09.3 This requirement documents the same accepted gap versus `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react`'s declarative, derive-based unknown-field rejection that `app08_cpp_react`'s SR-09.3 documents for C++.

### SR-10 — SAST / SCA
- SR-10.1 PHPCS with the WordPress Coding Standards ruleset runs on every PR; `WordPress.Security.*` and `WordPress.DB.PreparedSQL` findings are build-failing.
- SR-10.2 PHPStan (with the custom `NoIntegrityVerifierInRestApi` rule, `PLAN.md` D-03) runs on every PR.
- SR-10.3 `composer audit` and `roave/security-advisories` run against `composer.lock` on every PR and nightly.
- SR-10.4 **The WPScan vulnerability database is scanned against this plugin, the WordPress core version, and every other plugin/theme in the deployment on every PR and nightly** — a WordPress-specific SCA source with no equivalent need in any custom-backend sibling.
- SR-10.5 `npm audit --audit-level=high` fails the build tooling's own dependency check (the small esbuild/Vite step used only to bundle vanilla JS, per `PLAN.md` §2) on HIGH/CRITICAL advisories.
- SR-10.6 Trivy scans the WordPress/PHP-FPM container image; fails on HIGH/CRITICAL.

### SR-11 — CSRF
- SR-11.1 Every state-changing form and AJAX call uses WordPress nonces (SR-01.4); this is the platform's native CSRF defense and is used exclusively, rather than introducing a second mechanism.

### SR-12 — Code Sample Safety
- SR-12.1 Attack-demo snippets are stored as plain text and never executed server-side.
- SR-12.2 DVO/CLD code examples are pseudocode only.
- SR-12.3 A confirmation `<dialog>` gates any BOT card attack demo (FR-11.2).

### SR-13 — i18n Security
- SR-13.1 The `?lang=` query variable and `get_user_locale()` value are validated against the two-value allowlist (`pl`, `en`) before use; an unrecognized value falls back to the site's default WordPress locale.
- SR-13.2 Translation values (both `.po`-sourced UI strings and `sp_threat_translations` content) contain only plain text/limited allow-listed HTML — no unescaped interpolation of user input.

### SR-14 — WordPress-Specific Platform Hardening (no equivalent requirement category in any custom-backend sibling)
- SR-14.1 `xmlrpc.php` is disabled via `add_filter( 'xmlrpc_enabled', '__return_false' )`.
- SR-14.2 `DISALLOW_FILE_EDIT` is set in `wp-config.php`, preventing plugin/theme file editing from wp-admin.
- SR-14.3 WordPress core, this plugin, and all Composer dependencies are updated via a controlled, staging-first process — not WordPress's default unattended auto-update posture — given this plugin's custom DB schema migration needs.
- SR-14.4 The WordPress REST API's user-enumeration-via-author-archive behavior is disabled or rate-limited, since it is a well-known reconnaissance vector this app's own OAT/BOT content teaches about.

---

## 4. Non-Functional Requirements

### NFR-01 — Performance
- NFR-01.1 API endpoints respond in ≤ 250 ms (p95) under 50 concurrent users — a slightly more relaxed target than the compiled-language siblings', reflecting PHP-FPM's process-per-request model versus a long-running async runtime.
- NFR-01.2 MySQL `FULLTEXT` search returns results in ≤ 400 ms (p95).
- NFR-01.3 The vanilla-JS bundle (all modules combined, minified) is ≤ 100 KB gzip — deliberately tiny, since there is no framework runtime to ship at all.
- NFR-01.4 Prism.js language grammars are lazy-loaded, one per language, on first use.

### NFR-02 — Usability & Accessibility
- NFR-02.1 Fully responsive from 375 px to 2560 px.
- NFR-02.2 Light and dark mode via a CSS-custom-property toggle, no page reload.
- NFR-02.3 WCAG 2.1 AA contrast ratios on all interactive elements.
- NFR-02.4 All core flows are fully keyboard-navigable, and, per FR-02.4/FR-03.1, fully functional with JavaScript disabled — a stronger accessibility baseline than any SPA-based sibling can claim by construction.

### NFR-03 — Maintainability
- NFR-03.1 All seed data lives under `data/` as JSON/YAML, loaded via the activation hook — never hand-written as PHP array literals mixed into migration code.
- NFR-03.2 Every `CodeSample` row carries a `version_note` so maintainers know when to refresh it.
- NFR-03.3 PHP code follows the `data/service/cards/integrity/rest-api/cron/admin` layering in `PLAN.md` §9; REST controllers stay thin, business logic lives in `service`.
- NFR-03.4 The plugin is versioned independently of WordPress core and of any theme; activating it on a fresh WordPress install with any standard theme active must fully function (no theme-specific dependency), verified by a CI test matrix against at least two different default WordPress themes.

### NFR-04 — Testability (TDD — see `user_stories+tests.md`)
- NFR-04.1 `includes/service` code coverage ≥ 85% (via PHPUnit's coverage report, `xdebug`/`pcov`-backed).
- NFR-04.2 Every REST controller has a `WP_UnitTestCase`-based integration test using WordPress's own REST API testing helpers (`WP_REST_Request`).
- NFR-04.3 Every untrusted-input-parsing function (YAML decoder, reference validators) shall have at least one `eris` property test in addition to example-based PHPUnit cases.
- NFR-04.4 At least one Playwright end-to-end test per user story (US-01–US-19), run against the PHP-rendered pages.
- NFR-04.5 Tests are written **before** implementation for every new feature (Red → Green → Refactor); a PR adding production code without a preceding failing test in the same PR fails review.

### NFR-05 — Portability
- NFR-05.1 The full stack (WordPress/PHP-FPM + MySQL 8 + Redis + Nginx) runs via a single `docker compose up`, using `wp-env` for parity between local dev and CI.
- NFR-05.2 The plugin activates cleanly on a standard WordPress 6.8+ install without requiring any non-standard server configuration beyond PHP 8.3 and MySQL 8.0.16+ (for `CHECK` constraint support, `PLAN.md` D-04).
- NFR-05.3 Static assets (CSS, JS, Prism.js grammars) are self-hosted via `wp_enqueue_*` — no external CDN dependency.
- NFR-05.4 WP-Cron is disabled from its default page-view-triggered mode (`define( 'DISABLE_WP_CRON', true )`) and driven by a real system crontab entry hitting `wp-cron.php` on a fixed schedule, for reliability independent of site traffic.

### NFR-06 — Internationalization Quality
- NFR-06.1 Language switching completes in under 150 ms perceived latency where the client-side enhancement path is used; a full page navigation (no-JS fallback) is acceptable and expected to be slower, by design (NFR-02.4).
- NFR-06.2 No hardcoded user-visible string exists in PHP templates outside WordPress's `__()`/`_e()`/`esc_html__()` family, nor in JS outside `wp_set_script_translations()`-loaded strings.
- NFR-06.3 `wp i18n make-pot` run in CI produces no diff against the committed `.pot` file.

### NFR-07 — Deployment Footprint
- NFR-07.1 This requirement category, present in every custom-backend sibling's specification, does not apply in the same form here: a WordPress installation's footprint is dominated by WordPress core itself (a fixed, large baseline no sibling app carries), not by this plugin. The plugin's own code footprint (excluding WordPress core, Composer dependencies, and seed data) targets ≤ 5 MB, measured and reported for completeness rather than compared against the custom-backend siblings' image-size figures, which measure a fundamentally different thing.

---

## 5. Design Constraints & Technology Mandates

- C-01 The application shall be built entirely as a WordPress plugin in PHP 8.3, with vanilla JavaScript for client-side enhancement and MySQL 8.0.16+ as the database. No other backend runtime language, and no client-side JavaScript framework, is used anywhere in the application itself.
- C-02 Code **samples** shown to users (Python, Java, Go, Scala, Lua) are educational content, not part of the application's own runtime; none of these five languages is the application's implementation language.
- C-03 No third-party analytics, tracking scripts, or externally-hosted fonts/CDNs; all assets self-hosted via `wp_enqueue_*`.
- C-04 Every page displays a disclaimer that content is educational and must be verified against official sources.
- C-05 The application makes no outbound calls to external threat-intel feeds at runtime; all data is seeded locally from files under `data/`.
- C-06 Every code sample carries a version annotation.
- C-07 Only Polish and English are supported; both `.po`/`.mo` files must be complete before a new translation string reaches production.
- C-08 `CornucopiaCard` rows (all six decks) are never editable through any UI or API — no such code exists in the plugin at all (`PLAN.md` D-07), not merely a capability-gated form. Content changes only through a reviewed PR to the source YAML plus a hash-allowlist update.
- C-09 The Redis instance backing the object cache/rate limiter is never exposed on a public port.
- C-10 The plugin's functionality shall not depend on any specific WordPress theme being active (NFR-03.4) — a WordPress-specific application of least-coupling.
- C-11 The `chk_design_harm_has_no_severity` `CHECK` constraint (D-04) requires MySQL 8.0.16+ or MariaDB 10.2.1+ with `CHECK` enforcement enabled; the plugin's activation routine verifies the database version and refuses to activate on an unsupported version rather than silently degrading to an unenforced constraint.

---

## 6. Data Requirements

### DR-01 — Minimum Seeded Data
- DR-01.1 All 10 OWASP Web Top 10 (2021) entries with mitigations and 5-language code samples.
- DR-01.2 All 10 OWASP LLM Top 10 (2025) entries with mitigations and 5-language code samples.
- DR-01.3 Minimum 15 MITRE ATLAS techniques (≥ 5 tactics): AML.T0000, T0002, T0010, T0051, T0018, T0020, T0019, T0041, T0043, T0015, T0012, T0024, T0025, T0029, T0046.
- DR-01.4 All 10 OWASP Agentic AI Top 10 (2026) entries.
- DR-01.5 Minimum 20 CompTIA SecAI+/Security+ SY0-701 topics, including WordPress/CMS-specific supply-chain and hardening topics (plugin/theme CVEs, XML-RPC abuse, REST API `permission_callback` omission) as an explicit, cross-referenced topic set.
- DR-01.6 Full Cornucopia Website App Edition v3.0 cards (VE, AT, SM, AZ, CR, C suits).
- DR-01.7 Full Cornucopia Companion Edition v1.0 cards (LLM, FRE, DVO, BOT, CLD, AAI suits).
- DR-01.8 Full Cornucopia Mobile App Edition v1.1 cards (PC, AA, NS, RS, CRM, CM suits).
- DR-01.9 Full Cornucopia STRIDE EoP v5.0 cards (78 cards: SP, TA, RE, ID, DS, EP suits).
- DR-01.10 Full Cornucopia MLSec v1.0 cards (52 cards: EMR, EIR, EOR, EDR suits).
- DR-01.11 Full Digital-by-Default Harms v1.0 cards (SCO, ARC, AGE, TRU, POR, COR, WC suits), each with a reviewed Polish translation and a cross-reference row to OWASP A04:2021 Insecure Design.

### DR-02 — YAML Source-of-Truth
- DR-02.1 Cornucopia cards are maintained as YAML files in `data/cornucopia/`.
- DR-02.2 `Card_Loader` loads all six YAML files at plugin activation and on `Reingest_Deck_Job` execution; no live-reload from a REST-triggered path.
- DR-02.3 Every card row stores `content_sha256`, verified against `data/hashes.json` before being marked valid.

### DR-03 — Database Migrations
- DR-03.1 All schema changes are managed via `dbDelta()`-compatible `CREATE TABLE`/`ALTER TABLE` statements versioned alongside the plugin, run on activation and on version-upgrade detection (`update_option( 'securepress_db_version', ... )` comparison, the standard WordPress plugin migration pattern).
- DR-03.2 Migrations are idempotent (as required by `dbDelta()`'s own contract) and forward-only; no destructive `DROP` in production migration paths.

---

## 7. Abuse Case Requirements

| ID | Threat | Requirement |
|---|---|---|
| AC-01 | SQL injection via `?q=` | `$wpdb->prepare()`; WPCS `WordPress.DB.PreparedSQL` sniff — **pattern-based, no schema-verification exists in PHP tooling** |
| AC-02 | XSS via admin card update | `wp_kses()` allow-list (server) + WPCS `WordPress.Security.EscapeOutput` (output-time) |
| AC-03 | CSRF | WordPress nonces on every state-changing action (SR-01.4/SR-11.1) |
| AC-04 | Session/auth bypass | WordPress core's own auth-cookie mechanism; no custom auth code to have a bug in |
| AC-05 | Bot scraping all card suits | Transients/Redis rate limit 60 req/min; 429 + Retry-After |
| AC-06 | YAML card tampering | SHA-256 `Integrity_Verifier::verify()`; ingestion aborts on mismatch |
| AC-07 | Fake OWASP reference injection via admin | `Reference_Validator` + allowlist |
| AC-08 | Fake MITRE T-code injection | `Reference_Validator` + allowlist |
| AC-09 | Privilege escalation to `/stride-heatmap/` | `current_user_can()` capability check; WordPress core denies unauthenticated/under-privileged access |
| AC-10 | XSS via LLM card description | `esc_html()`/`wp_kses_post()` at every output site (SR-03) |
| AC-11 | i18n locale injection (`?lang=../../etc/passwd`) | `?lang=` allowlisted to `pl`/`en`; unrecognized values fall back to the site default (SR-13.1) |
| AC-12 | Clickjacking `/stride-heatmap/` | `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` (SR-04.1) |
| AC-13 | Supply-chain attack via a Composer or WordPress plugin/theme dependency | `composer audit`/`roave/security-advisories` + **WPScan vulnerability database scan** + Trivy |
| AC-14 | REST route registered without a `permission_callback` | CI check grepping every `register_rest_route()` call for a present `permission_callback` argument (a well-documented, real WordPress REST API vulnerability class) |
| AC-15 | BotWarningModal bypass via direct API call | Server-side check independent of the `<dialog>` element |
| AC-16 | Digital-by-Default Harms deck misread as a CVE-style severity list | `chk_design_harm_has_no_severity` MySQL `CHECK` constraint (SR-08) — enforced independent of application code, verified by a direct-`INSERT` bypass test |
| AC-17 | `wp-login.php` credential stuffing | Login-attempt rate limiting (SR-05.4) + WordPress's own login-failure hooks monitored |
| AC-18 | XML-RPC pingback amplification/enumeration abuse | `xmlrpc.php` disabled entirely (SR-14.1) |

---

## 8. Traceability Matrix (abbreviated)

| Requirement | User Story | Security Design Decision | Test Coverage |
|---|---|---|---|
| FR-01, FR-02 | US-01, US-02 | D-01/D-02 (custom tables, prepared queries) | US-01/US-02 Playwright |
| FR-05 | US-05 | SR-03 | US-05 Playwright |
| FR-06 | US-06 | SR-07 | US-06 Playwright |
| FR-07 | US-07 | SR-07 | US-07 Playwright |
| FR-08 | US-08 | D-06 (capabilities), D-09 (rate limit) | US-08 Playwright |
| FR-09 | US-09 | SR-07 | US-09 Playwright |
| FR-10 | US-10 | SR-07 | US-10 Playwright |
| FR-11 | US-11 | D-09, SR-14 | US-11 Playwright |
| FR-12 | US-12 | SR-07 | US-12 Playwright |
| FR-17 | US-17, US-18 | WP-Cron (D-09-adjacent) | US-17/US-18 Playwright, AC-14 |
| FR-18 | — (cross-cutting i18n) | D-05 | `.pot` drift CI test |
| FR-19 | US-19 | D-04 (CHECK constraint) | US-19 Playwright, AC-16 |
| SR-02 | — | D-02 | AC-01 integration test |
| SR-03 | — | — | AC-02, AC-10 integration test |
| SR-05 | — | D-09 | AC-05 integration test |
| SR-06 | — | D-03 | AC-06 integration test |
| SR-08 | — | D-04 | AC-16 direct-INSERT bypass test |
| SR-09 | — | D-08 | `eris`: unknown-field rejection property |
| SR-10 | — | — | CI SAST/SCA/WPScan gates |
| SR-14 | — | — | AC-17, AC-18 |

---

## 9. Glossary

| Term | Definition |
|---|---|
| `$wpdb` | WordPress's built-in database access class, wrapping `mysqli`/PDO with a `prepare()` method for parameterized queries |
| `dbDelta()` | WordPress core function that creates/updates custom database tables idempotently from a `CREATE TABLE` statement, used in plugin activation hooks |
| Nonce (WordPress) | A one-time, context-bound token used as WordPress's native CSRF defense, distinct from a cryptographic nonce in the general sense |
| Capability | WordPress's fine-grained permission unit (e.g. `manage_securepress`), assigned to roles, checked via `current_user_can()` |
| `permission_callback` | The mandatory (as of WP 4.7+) authorization callback for a REST API route; historically, routes shipped without one have been a real vulnerability class |
| WPCS (WordPress Coding Standards) | The official PHPCS ruleset for WordPress code, including security-specific sniffs (`WordPress.Security.*`, `WordPress.DB.PreparedSQL`) |
| WPScan | A vulnerability database and scanner specific to WordPress core, plugins, and themes |
| `eris` | A property-based testing library for PHP, this ecosystem's equivalent to QuickCheck/`proptest`/`RapidCheck` |
| `CHECK` constraint | A database-schema-level rule (here, in MySQL 8.0.16+) that the database engine enforces on every write, independent of which application code performs it |
| Progressive enhancement | Building a page to be fully functional with server-rendered HTML alone, then layering JavaScript on top as an enhancement rather than a requirement — the governing frontend principle of this app, in contrast to every SPA-based sibling |
| Cornucopia | OWASP's card-game family for threat modeling (Website App, Mobile App, Companion editions) |
| STRIDE | Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege |
| MITRE ATLAS | Adversarial Threat Landscape for AI Systems |
| MASVS | OWASP Mobile Application Security Verification Standard |
| Digital-by-Default Harms deck | `dbd-cards-1.0-en.yaml` — models service-design harms (exclusion, opaque design) in public-sector digital services; mapped to OWASP A04:2021 Insecure Design, not a technical CVE-style vulnerability |
