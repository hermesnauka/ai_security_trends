# SecurePress 2026 — WordPress/PHP implementation (app09_php_WORDPRESS)

The WordPress implementation. See `../CLAUDE.md` for the sibling list and
shared local-dev-tooling notes — SecureVision is a threat-modeling reference
app (browse security frameworks + threats, one hardcoded admin login); see
`../app01_react` for the Phase-1 reference behavior this app deliberately does
NOT mirror (see below).

## Nothing is built yet

This directory currently contains only four planning documents — `PLAN.md`,
`requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md` — and nothing else. No
`includes/`, no plugin bootstrap file, no `composer.json`, no Docker Compose, no
`nginx/`, no `scripts/`. Those docs describe a large aspirational 19-user-story end
state (six OWASP Cornucopia-family card decks, MITRE ATLAS, CompTIA SecAI+, five-language
code samples, bilingual PL/EN content). **None of it exists yet.** Whoever starts coding
here is scaffolding from zero, not extending existing code — don't assume any file
mentioned below already exists; check first.

## This is a WordPress plugin, not a backend+SPA — deliberately, don't "fix" that

Every other sibling (app01–app08, app10) pairs a custom backend with a React or Angular
SPA and treats app01's REST API as a contract to mirror. **This app does not work that
way, on purpose**, per `PLAN.md` §0 and §8:

- The whole thing is **one self-contained WordPress plugin** (`securepress-2026`),
  deliberately not split across a plugin + theme, so functionality doesn't depend on
  which theme is active.
- Frontend is **WordPress's own Template Hierarchy** (PHP templates like
  `archive-threat.php`, `single-threat.php`, registered via `template_include`),
  progressively enhanced with small vanilla-JS (ES2022) modules calling the WordPress
  REST API via `fetch`. **There is no React SPA.** Pages must work with JavaScript
  disabled — a deliberate accessibility/resilience property unique to this app in the
  series. Do not introduce a client-side SPA framework here; it would fight the platform.
- There is no separate "backend API service" to stand up — `wp-json/securepress/v1/*`
  routes are registered inside the same plugin, served by the same PHP-FPM process that
  renders the templates. No `backend/` vs `frontend/` directory split like the siblings.

## Key WordPress-specific decisions to know before writing code (full detail: `PLAN.md` §2–5)

- **Data storage:** custom `$wpdb` tables (`sp_frameworks`, `sp_threats`, `sp_cards`,
  `sp_mitigations`, `sp_code_samples`, `sp_cross_references`, `sp_content_hashes`,
  `sp_threat_translations`), created via `dbDelta()` in the activation hook — **not**
  Custom Post Types + postmeta (rejected: postmeta's key-value model doesn't fit the
  multi-dimensional filtering this app needs). See PLAN.md §5.1 for full schema.
- **Auth/admin:** WordPress's own user/role/capability system (`current_user_can()`),
  reusing `wp-admin` logins directly. **No separate JWT layer** — a new `securepress_editor`
  role + `manage_securepress` capability are registered instead. CSRF via WordPress
  nonces (`wp_verify_nonce`, `X-WP-Nonce`), not a custom CSRF token scheme.
- **"API contract":** the WordPress REST API, namespace `securepress/v1`
  (`register_rest_route`), e.g. `GET /wp-json/securepress/v1/frameworks`,
  `GET /wp-json/securepress/v1/threats?framework=&severity=&stride=&tag=&q=`. Every
  route needs an **explicit** `permission_callback` (an omitted one is a known WP REST
  vuln class — PLAN.md calls this out specifically). This is NOT meant to mirror
  app01's `/api/v1/...` shape; map to WP REST conventions, not app01's Java DTOs.
- **SQL safety is runtime-only:** every query goes through `$wpdb->prepare()` — PHP has
  no compile-time query-shape checking (unlike `sqlc`/`hasql-th`/`sqlx` in other
  siblings). WPCS's `WordPress.DB.PreparedSQL` sniff is the closest substitute.
  Conversely, one guarantee is *stronger* here than any sibling: the Digital-by-Default
  Harms "no severity on a design-harm card" rule is enforced by a MySQL 8.0.16+ `CHECK`
  constraint (PLAN.md §4 D-04), which holds even against a raw SQL query outside the app.
- **i18n:** WordPress's native gettext system (`__()`, `esc_html_e()`, `.pot`/`.po`/`.mo`
  via `load_plugin_textdomain()`) for UI strings — not a bespoke `localStorage` toggle
  like every custom-backend sibling built. Threat *content* translations are a separate
  `sp_threat_translations` table.
- **Versions:** WordPress 6.8+, PHP 8.3, MySQL 8.0.16+ (the `CHECK`-constraint floor) or
  MariaDB 10.11+. Composer for PHP deps (`roave/security-advisories`), `symfony/yaml`
  for YAML parsing (no arbitrary-object gadget class by default).

## No local dev tooling exists yet either

PLAN.md's Phase 1 calls for Docker Compose (WordPress/PHP-FPM + MySQL + Redis + Nginx)
and `wp-env`, but none of that is scaffolded in this directory yet. This machine has no
Docker anyway (see `../CLAUDE.md`) — whoever starts Phase 1 needs to decide/build the
actual local WP+MySQL setup (Docker Compose file, `scripts/`, `nginx/` config) the way
`app06_HASKELL_react/CLAUDE.md` documents its own no-Docker workaround.

## Where to look for more

`PLAN.md` is the primary source — §0 (why this app looks different), §3 (architecture
diagram, including the explicit note that WP-Cron runs in-process, unlike the separate
worker binaries every custom-backend sibling has), §4 (D-01 through D-09 design
decisions with rationale), §5 (full schema), §6 (phased build plan), §7 (endpoint map).
