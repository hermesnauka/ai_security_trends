# SecurePress 2026 — SSDLC / SDLC Analysis

**Version:** 1.0
**Date:** 2026-07-07
**Document type:** Secure Software Development Lifecycle (SSDLC) analysis, mapped against the classic SDLC
**Scope:** Full lifecycle analysis of the application defined in `PLAN.md`, `requirements.md`, and `user_stories+tests.md`
**Methodology:** Agile — Scrum for planning/cadence, Kanban overlay for the engineering + security workflow
**Dotyczy:** US-01 – US-19 / WordPress 6.8+ (PHP 8.3, vanilla JS, MySQL 8)

---

## Executive Summary

SecurePress 2026 carries the same double obligation as its sibling projects (`app01_react` through `app08_cpp_react`): it **teaches** OWASP/MITRE ATLAS/CompTIA SecAI+ security content, so it must itself **be** secure — an app about SQL Injection that is vulnerable to SQL Injection trains people with a false sense of authority. This project's SSDLC is organized around a fact none of the prior eight apps had to contend with: **it is not a custom-built application at all — it is a plugin extending an existing platform that ~40% of the web already runs, with its own decades-long, extensively documented vulnerability history and its own mature, purpose-built security tooling ecosystem.**

Three consequences follow, and this document is built around them:

1. **This project inherits WordPress's attack surface, not just its own code's.** Threat modeling (Phase 0/1) must account for WordPress-specific, historically real vulnerability classes — missing REST API `permission_callback`s, XML-RPC amplification abuse, plugin/theme supply-chain compromise, `wp-login.php` credential stuffing — none of which appear in any custom-backend sibling's threat model, because none of them run on a platform with its own multi-decade CVE history.
2. **This project also inherits WordPress's security tooling maturity, and this plan uses it rather than reinventing weaker alternatives.** WordPress's nonce system (CSRF), capability system (RBAC), and gettext-based i18n infrastructure are each more battle-tested, in continuous production use across hundreds of thousands of codebases, than anything a from-scratch custom backend could build in this project's timeline — and this plan uses them as-is (`PLAN.md` D-05, D-06) rather than building bespoke equivalents the way every prior sibling had to.
3. **On the specific question of compile-time-adjacent guarantees, this project sits in an unusual position: weaker than every memory-safe sibling on almost every axis, but with one guarantee — the Digital-by-Default Harms deck's "cannot carry a severity" rule — arguably *stronger* than any of them, because it is enforced by a MySQL `CHECK` constraint at the schema level (`PLAN.md` D-04), independent of which code (or which future code, or which direct database client) touches the data.** This document treats that asymmetry precisely, the same way `app08_cpp_react`'s document treated its own honestly-scoped gaps.

The lifecycle below follows **Agile Scrum for cadence, with a Kanban board carrying explicit security-gate columns**, per the requested focus on Agile/Scrum/Kanban.

---

## SSDLC vs Classic SDLC — Where Security Moves on a Platform You Don't Fully Control

```
Classic SDLC (security bolted on late):
  Planning & Analysis → Design → Implementation → Testing → Deployment → Maintenance
                                                        ↑
                                          Security testing added HERE — too late,
                                          architecture and code are already frozen.

SSDLC as this project achieves it (platform-aware "Shift Left"):
  Secure          Secure       Secure            Secure          Secure           Secure
  Planning &  →   Design   →   Implementation →  Testing     →   Deployment   →   Maintenance
  Analysis        │            │                 │               │                │
    ↑             ↑            ↑                 ↑               ↑                ↑
  Threat model   Reuse WP's   $wpdb->prepare()  WPCS security   Controlled,       Runtime
  incl. WP-      native       + nonces + wp_kses  sniffs +      staging-first     monitoring +
  specific       nonce/       (review-enforced,  PHPStan +      core/plugin/      WPScan-tracked
  history +      capability/  not compiler-       composer      theme updates     patch cadence +
  compliance     i18n systems  enforced) + a       audit +       (NOT WP's         card-deck +
  mapping        instead of    DB CHECK            WPScan scan   default auto-      translation
  (OWASP/ATLAS/  rebuilding    constraint for                    update posture)    integrity review
  SecAI+/GDPR/   them          one specific
  WP CVE                       invariant (D-04)
  history)
```

Both models describe the **same six stages**; SSDLC's contribution is that security activities happen *inside* each stage rather than as a single gate before release. This project's version of the diagram differs from every prior sibling's in the same structural place `app08_cpp_react`'s did — several boxes say "review-enforced" rather than "compiler-enforced" — but adds a row no sibling needed: reusing a mature platform's own security mechanisms instead of building new ones, which is itself a security decision, not merely a convenience.

---

## Agile Framework: Scrum for Cadence, Kanban for Flow

### Scrum structure

```
Sprint length:      2 weeks
Team size:           2–3 PHP/WordPress engineers (fewer than the custom-backend siblings' typical
                      estimate, reflecting how much this project reuses rather than builds — see
                      rationale below), 1 QA/security engineer with WordPress-specific experience
                      (WPCS, WPScan), 1 PL translator part-time
Velocity target:     ~20–24 story points/sprint — HIGHER than every custom-backend sibling's
                      estimate. This is not a claim that PHP/WordPress developers are faster in
                      general; it reflects that auth, CSRF protection, RBAC, and i18n — each a
                      multi-sprint build for every custom-backend sibling — are here a matter of
                      correctly USING WordPress core functionality that already exists, tested,
                      and battle-hardened by the platform's own two-decade history.
Total duration:      14 sprints (~28 weeks) — comparable to the earlier custom-backend siblings,
                      despite the velocity difference above, because Phase 3's card-deck ingestion
                      work and the new WordPress-specific hardening activities (§0.2, Phase 6)
                      absorb roughly the sprint budget the reused-infrastructure savings free up

Ceremonies:
  Sprint Planning        — Monday, Day 1, 2h max — pulls from the Product Backlog (PLAN.md §15 + this doc's abuse cases)
  Daily Standup          — daily, 15 min, includes a mandatory "any security blocker?" round AND
                             a "any new WPScan/WordPress-core-update advisory overnight?" round —
                             a question with no equivalent in any custom-backend sibling's standup
  Mid-Sprint Security Gate — Wednesday, Day 7, 30 min — peer review of anything touching
                             Integrity_Verifier's isolation, raw $wpdb query construction, REST
                             route permission_callbacks, or output escaping
  Sprint Review          — Friday, Day 10, 1h — demo includes a security angle (e.g. "here's a PR
                             that registered a REST route without a permission_callback, and the
                             CI check that caught it")
  Sprint Retrospective   — Friday, Day 10, 45 min — one mandatory security-process retro item
```

### Kanban board — security-gated columns

```
BACKLOG → SPRINT → IN DEV → SEC REVIEW → I18N REVIEW → TEST → WP-HARDENING → DONE

  BACKLOG        Product backlog: user stories (US-01..US-19), bugs, abuse cases (AC-01..AC-18)
  SPRINT         Committed for the current sprint
  IN DEV         Actively coded — TDD red/green cycle in progress
  SEC REVIEW     Mandatory gate for anything touching: $wpdb queries, Integrity_Verifier's
                 isolation, REST route registration (permission_callback present?), output
                 escaping, or capability checks
  I18N REVIEW    Mandatory gate for anything adding user-visible strings or card translations
  TEST           PHPUnit + eris + WP_UnitTestCase + wp-browser + Playwright running in CI
  WP-HARDENING   A column with no equivalent on any custom-backend sibling's board — new/changed
                 code sits here until it has been checked against the current WPScan vulnerability
                 database AND against WordPress's own security changelog for the target core version
  DONE           Meets the Definition of Done below

WIP limits:  IN DEV ≤ 2/dev · SEC REVIEW ≤ 3 total · I18N REVIEW ≤ 3 total · TEST ≤ 5 total ·
             WP-HARDENING ≤ 3 total
```

**The Kanban-metrics honesty point for this project, in the same spirit as `app08_cpp_react`'s:** `SEC REVIEW` here is not shortened by a compiler the way it is for `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react`, but it *is* shortened, for a specific and different reason, by how much less new security-relevant code this project writes in the first place — there is no bespoke JWT implementation to review, no bespoke rate-limiter design to review, no bespoke i18n pipeline to review, because WordPress core already provides tested versions of all three. The `WP-HARDENING` column exists to catch the risk this reuse strategy specifically introduces: that this project is only as secure as the *version* of WordPress core, and the *other* plugins/themes, deployed alongside it — a risk category unique to building on a shared platform.

### Definition of Done (security- and i18n-enforced)

```
CODE QUALITY
  [ ] PHPUnit (+ eris) passes; coverage ≥ 85% on includes/service
  [ ] PHPCS --standard=WordPress-Extra zero findings; PHPStan analyse clean

SECURITY GATES
  [ ] WPCS WordPress.Security.* and WordPress.DB.PreparedSQL sniffs zero findings
  [ ] Every new register_rest_route() call has an explicit permission_callback (CI grep + review)
  [ ] composer audit + roave/security-advisories pass against composer.lock
  [ ] WPScan scan shows no new HIGH/CRITICAL findings against WordPress core, this plugin, or any
      other plugin/theme in the deployment
  [ ] Peer security review completed for anything in the SEC REVIEW trigger list above
  [ ] No secrets committed (detect-secrets / trufflehog pre-commit hook green)
  [ ] Integrity_Verifier::verify()'s isolation unchanged, or changed with explicit SEC REVIEW sign-off
  [ ] Any change to the sp_cards schema re-verifies the chk_design_harm_has_no_severity CHECK
      constraint with a direct-INSERT bypass test

I18N GATES
  [ ] wp i18n make-pot diff against the committed .pot file is empty
  [ ] Any new/changed card translation reviewed and signed off by a native Polish speaker
  [ ] No hardcoded user-visible string added outside WordPress's __()/_e()/esc_html__() family

DOCUMENTATION
  [ ] requirements.md traceability updated if scope changed
  [ ] user_stories+tests.md TDD test list updated for the story being closed
```

---

## Phase 0 — Sprint Zero: SSDLC & Tooling Setup

### 0.1 Threat modeling session (dogfooding the project's own STRIDE deck, PLUS WordPress's own security history)

This session runs in two parts, because this project has two threat surfaces every custom-backend sibling's session did not: its own code, and the platform underneath it.

| Component | STRIDE categories in scope | Key finding → design decision |
|---|---|---|
| `Integrity_Verifier::verify()` | Tampering, Elevation of Privilege | → isolated by code organization + PHPStan rule + review (`PLAN.md` D-03) — flagged in the session as the **weakest** isolation mechanism in the whole series, since there is no process boundary and no compiler backstop at all |
| `$wpdb` queries | Tampering (SQLi) | → `$wpdb->prepare()` + WPCS sniff (D-02) — flagged, like `app08_cpp_react`'s equivalent row, as pattern-based only, with no schema-shape verification possible in PHP |
| YAML card ingestion | Tampering, Repudiation | → `symfony/yaml` (no object-instantiation gadget class by default) + hand-written allow-list validation + SHA-256 (D-08) |
| `sp_cards.card_kind`/`severity` | (a presentation/data-integrity risk, not cleanly STRIDE-shaped) | → the `CHECK` constraint (D-04) — the session specifically noted this as the one place a *database*-layer control, not an *application*-layer one, is the right tool |
| **WordPress core / plugin / theme supply chain** (no equivalent row exists in any custom-backend sibling's session) | Tampering, Elevation of Privilege | → WPScan vulnerability database scan added to CI; controlled, staging-first update process (not WordPress's default unattended auto-update) — `SDLC_analysis.md` Phase 5/6 |
| **`wp-login.php` and XML-RPC** (platform-inherited attack surface, no equivalent row exists in any custom-backend sibling's session) | Spoofing (credential stuffing), Denial of Service (XML-RPC pingback amplification) | → login rate limiting, `xmlrpc.php` disabled entirely (`requirements.md` SR-14) |

### 0.2 Security tooling setup

```yaml
# .github/workflows/ci.yml (excerpt)
- name: PHPCS / WPCS (SAST)
  run: vendor/bin/phpcs --standard=WordPress-Extra --extensions=php includes/
- name: PHPStan
  run: vendor/bin/phpstan analyse -c phpstan.neon
- name: REST route permission_callback check
  run: python scripts/check_permission_callbacks.py includes/rest-api/
- name: SCA — Composer
  run: composer audit
- name: SCA — WordPress ecosystem
  run: wpscan --url http://localhost:8080 --enumerate p,t --api-token "$WPSCAN_API_TOKEN"
- name: Container scan
  run: trivy image securepress-2026-wordpress:latest
- name: i18n .pot drift check
  run: wp i18n make-pot . /tmp/generated.pot && diff languages/securepress-2026.pot /tmp/generated.pot
- name: DAST baseline (every PR, passive only)
  run: docker run -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://staging.securepress.local
```

### 0.3 Branch protection
- `main` requires 1 approval + all CI checks green + no `SEC REVIEW`/`I18N REVIEW`/`WP-HARDENING` Kanban card still open for the linked issue.
- CODEOWNERS: `@security-team` required for `includes/integrity/`, `includes/data/`, `includes/rest-api/` (specifically for `permission_callback` review), `data/hashes.json`, and any `docs/OWASP_stories/*.yaml` change.

---

## Phase 1 — Planning & Analysis (Secure Requirements)

### 1.1 Business goals vs security constraints

| Business goal | Security constraint it must respect |
|---|---|
| Teach OWASP/ATLAS/SecAI+ content accurately and fast | Content integrity (`requirements.md` SR-06) must not be sacrificed for speed of publishing |
| Reuse WordPress's mature auth/CSRF/i18n infrastructure rather than rebuilding it | Reuse must not become an excuse to skip verifying it is *configured* correctly (e.g., a `permission_callback` is still required on every route even though the underlying REST framework is WordPress core's own) |
| Cover all six Cornucopia decks, including the non-technical harms deck | The harms deck (US-19) must never be presented as if it had CVE-style severity — FR-19.2, enforced at the database layer (D-04) |
| Ship on a platform with its own independent update cadence | This plugin's own release process must not assume WordPress core, or any co-installed plugin/theme, is automatically safe — WPScan scanning and controlled updates (Phase 6) exist specifically because that assumption would be false |

### 1.2 Compliance requirements mapping

| Regulation / standard | Relevance | Where it lands in requirements.md |
|---|---|---|
| GDPR / RODO | User accounts (reusing WordPress's own), bookmarks, translator reviewer identity | SR-01, no unnecessary PII beyond what WordPress core already manages |
| EU AI Act (transparency, Art. 13) | `dbd` harms deck explicitly references this | FR-19.3, DR-01.11 |
| NIS2 / Polish KSC | Educational content on GRC topics | DR-01.5 |
| WordPress-specific supply-chain/hardening guidance (WPScan advisories, WordPress Security Whitepaper) | This app's own platform choice makes this directly relevant; seeded as CompTIA SecAI+ content | DR-01.5 |
| WCAG 2.1 AA | Public-facing educational tool; server-rendered pages give a stronger accessibility baseline by construction (NFR-02.4) | NFR-02.3 |

### 1.3 Security requirements traceability (excerpt)

| Requirement | Threat addressed | Verified by |
|---|---|---|
| SR-02.1/SR-02.2 (`$wpdb->prepare()` + WPCS sniff) | SQL Injection | WPCS `WordPress.DB.PreparedSQL` finding + integration test — pattern-based, no schema-verification exists in PHP tooling, stated explicitly |
| SR-06.4 (`Integrity_Verifier` isolation) | A compromised REST handler forging a "content verified" record | PHPStan custom rule + code review — the weakest isolation mechanism in this series |
| SR-08.1/SR-08.2 (`CHECK` constraint) | Digital-by-Default Harms deck misread as a CVE-style severity list | A direct-`INSERT`-bypass integration test asserting MySQL itself rejects the violating row — **independent of any PHP code path**, this project's strongest guarantee |
| SR-14.1 (`xmlrpc_enabled` filter) | XML-RPC pingback amplification/enumeration abuse — a real, WordPress-specific historical attack class | A unit test asserting the filter returns `false` |

### 1.4 Abuse cases (negative user stories)

See `requirements.md` §7 for the full table (AC-01–AC-18). Highlights specific to this project's WordPress choices:

| ID | Abuse case |
|---|---|
| AC-14 | A future contributor registers a new REST route and forgets the `permission_callback` argument — historically, this exact mistake has been a real, exploited WordPress REST API vulnerability class across multiple plugins; the CI grep check exists specifically because there is no framework-level default that fails safe here (an omitted `permission_callback` in older WordPress versions defaulted to *public*, not *denied*). |
| AC-16 | A user copy-pastes the Digital-by-Default Harms deck into a vulnerability report as if `SCO2` were a CVSS-scored finding — mitigated at the database layer regardless of which application code path is involved, the one abuse case in this whole series whose mitigation does not depend on any PHP code being correct. |
| AC-17/AC-18 | Credential stuffing against `wp-login.php` and XML-RPC amplification/enumeration abuse — both are attack classes that exist *because this application runs on WordPress*, not because of anything this plugin's own code does; they would not appear in any custom-backend sibling's abuse case table at all. |

---

## Phase 2 — Secure Design

### 2.1 Trust boundaries

```
┌─────────────────────────── Untrusted ───────────────────────────┐
│  Browser (any locale, any user)                                  │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ HTTPS, WordPress session cookie + nonce
┌────────────────────────────── Trust Boundary 1 ──────────────────┐
│  Nginx → PHP-FPM → WordPress core → securepress-2026 plugin       │
│    (includes/rest-api/**, includes/templates/**)                   │
│    - validates all input via WordPress's REST arg schema + hand-  │
│      written validators                                            │
│    - enforces auth/roles via current_user_can()                    │
│    - MUST NOT call Integrity_Verifier::verify() (review + static   │
│      analysis, NOT a process or compiler boundary — the single     │
│      request lifecycle contains everything)                        │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ same PHP-FPM process, different code path (WP-Cron trigger)
┌────────────────────────────── Trust Boundary 2 ──────────────────┐
│  includes/cron/* — the intended sole caller of Integrity_Verifier  │
│    - triggered by a real system crontab hitting wp-cron.php,       │
│      NOT a separate OS process or container (unlike every          │
│      custom-backend sibling's dedicated worker binary)             │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ local filesystem read-only
┌────────────────────────────── Trust Boundary 3 ──────────────────┐
│  docs/OWASP_stories/*.yaml + data/hashes.json                     │
│    - treated as security-sensitive content, CODEOWNERS-gated      │
└────────────────────────────────────────────────────────────────────┘
                                 │
┌────────────────────────────── Trust Boundary 4 ──────────────────┐
│  MySQL 8 — chk_design_harm_has_no_severity CHECK constraint (D-04) │
│    - the ONLY boundary in this architecture enforced independent  │
│      of any PHP code path whatsoever                               │
└────────────────────────────────────────────────────────────────────┘
```

**Design decision D-01 (this document; distinct from `PLAN.md`'s own D-01, custom `$wpdb` tables):** unlike every custom-backend sibling from `app05_go_react` onward, this project has **no separate worker process** — WP-Cron jobs run inside the same PHP-FPM request lifecycle as everything else. Trust Boundary 2 above is therefore not a process boundary at all, only a code-path distinction verified by review and static analysis. This is named as this project's single largest architectural difference from every sibling that came before it, and its largest structural risk (§13).

### 2.2 Least privilege applied to the data model

- `CornucopiaCard` rows (all six decks) have **no** write path from any REST route or wp-admin screen at all (`requirements.md` C-08) — no such code exists in the plugin, the same category of guarantee (absence of capability, not merely denial of it) every custom-backend sibling from `app05_go_react` onward achieves via its router's type system, achieved here by simply never writing the code and verifying that with a grep-based CI check plus review.
- `securepress_editor` capability can write `Threat`/`Mitigation`/`CodeSample`; only `administrator` (WordPress's own top capability tier) can delete.
- The one place least privilege is enforced independent of any application code at all: the `sp_cards` `CHECK` constraint (D-04).

### 2.3 STRIDE analysis of the designed architecture

| STRIDE | Applies to | Mitigation already in the design |
|---|---|---|
| Spoofing | Browser→WordPress session cookie; `wp-login.php` credential stuffing | WordPress core session auth; login-attempt rate limiting (SR-05.4) |
| Tampering | YAML card content; DB records; SQL queries; the `card_kind`/`severity` invariant | `symfony/yaml` + allow-list validation + SHA-256; `$wpdb->prepare()`-only writes; `CHECK` constraint (the one Tampering sub-case with a database-layer, not merely application-layer, control) |
| Repudiation | Who approved a translation or a hash-allowlist update | CODEOWNERS-enforced PR review logged in Git history; `verified_by` field |
| Information Disclosure | Error responses; WordPress version/plugin enumeration | Generic error responses; WordPress version string hidden from `<meta generator>` and REST index; author-archive user enumeration disabled (SR-14.4) |
| Denial of Service | Export jobs; search; card scraping; XML-RPC pingback amplification | WP-Cron async export; Transients/Redis rate limit; MySQL `FULLTEXT` index; `xmlrpc.php` disabled entirely (SR-14.1) |
| Elevation of Privilege | Editor trying to write `CornucopiaCard`; anonymous user hitting capability-gated routes | No write route exists at all for cards; `current_user_can()` on every admin route |

### 2.4 Data classification

| Data | Classification | Handling |
|---|---|---|
| Threat/card content (EN + PL) | Public, but integrity-critical | SHA-256 verified, CODEOWNERS-reviewed |
| User accounts (email, password hash) | Personal data | WordPress core's own `wp_hash_password` (Argon2id-backed as of WP 6.8), not reimplemented |
| Bookmarks (anonymous) | Non-personal | Cookie/`sessionStorage`, never sent server-side unless authenticated |
| WordPress secret keys/salts, DB credentials | Secret | `wp-config.php` constants sourced from environment variables, never committed |

---

## Phase 3 — Implementation (Secure Coding)

### 3.1 Secure coding standards — PHP / WordPress

```php
// ALWAYS — $wpdb->prepare(), never string interpolation
$wpdb->get_results(
    $wpdb->prepare( "SELECT * FROM {$wpdb->prefix}sp_threats WHERE framework_code = %s", $code )
);

// ALWAYS — capability checks before any privileged action
if ( ! current_user_can( 'manage_securepress' ) ) {
    return new WP_Error( 'rest_forbidden', __( 'Insufficient permissions.', 'securepress-2026' ), array( 'status' => 403 ) );
}

// ALWAYS — nonces on state-changing requests
check_ajax_referer( 'securepress_admin_action', 'nonce' );

// ALWAYS — contextual output escaping
printf( '<h1>%s</h1>', esc_html( $threat->title ) );
echo wp_kses_post( $threat->description ); // limited HTML allow-list, not raw output

// ALWAYS — explicit permission_callback on every registered route
register_rest_route( 'securepress/v1', '/threats', array(
    'methods'             => 'GET',
    'callback'            => array( $this, 'list_threats' ),
    'permission_callback' => '__return_true', // explicit, reviewed public-read decision — NOT an omission
) );

// NEVER — string-interpolated SQL, or a REST route with no permission_callback argument at all
```

### 3.2 Secure coding standards — WP-Cron jobs

```php
add_action( 'securepress_export_job', function ( array $args ) {
    $validated = Export_Args_Validator::validate( $args ); // rejects unrecognized keys, same
                                                             // discipline as the YAML loader (D-08)
    if ( is_wp_error( $validated ) ) {
        error_log( 'SecurePress export job rejected: ' . $validated->get_error_message() );
        return;
    }
    // ... proceed with $validated only ...
} );
```

### 3.3 Sprint-by-sprint security activities

| Sprint | Feature work | Security activity in parallel |
|---|---|---|
| 1–2 | Foundation, custom tables, auth reuse | Threat model review of auth flow; WPCS/PHPStan wired into CI (not yet blocking); `permission_callback` grep check added |
| 3–4 | Threat browser | SAST becomes blocking; first abuse-case test (AC-01, WPCS PreparedSQL sniff) |
| 5–7 | Card decks (all six, including `dbd`) + integrity + `CHECK` constraint | AC-06, AC-16 abuse tests written FIRST (TDD) before the ingestion code exists; the `CHECK` constraint bypass test is written before the migration that creates it |
| 7–9 | 5-language code samples | Review that no `attack_demo` sample is runnable without the confirmation gate |
| 9–10 | i18n | I18N REVIEW Kanban column activated; `.pot` drift check made blocking |
| 10–12 | Search, export, matrix, WordPress hardening (XML-RPC, login rate limit) | AC-14 (job payload validation) test added; AC-17/AC-18 (WordPress-specific hardening) tests added; DAST baseline extended to `/export/` and `/search/` |
| 12–14 | Hardening & release | Full ZAP active scan; abuse-case sweep across AC-01..AC-18; first full WPScan scan against the staged deployment |

---

## Phase 4 — Security Testing

### 4.1 Test pyramid with security layers

```
E2E (Playwright)                  — includes AC-01..AC-18 abuse-case scenarios end-to-end
wp-browser/Codeception acceptance  — real WordPress + MySQL instance, JS-disabled scenarios included
WP_UnitTestCase REST integration    — auth/permission boundary tests per route
PHPUnit unit                        — service-layer behavior with concrete fixtures
eris properties                     — invariants over generated data: YAML decode-rejects-unknown-
                                       fields, every mitigation has 5 languages
Direct-SQL bypass tests             — the layer with NO equivalent in any prior sibling's plan:
                                       tests that deliberately skip the application layer entirely
                                       to prove the database CHECK constraint holds on its own
```

### 4.2 SAST
PHPCS with the WordPress Coding Standards ruleset runs on every PR; its `WordPress.Security.*` and `WordPress.DB.PreparedSQL` sniffs are purpose-built, by the WordPress plugin-review community, for exactly the vulnerability classes historically most common in this ecosystem — arguably a more *targeted* SAST tool for this project's specific risk profile than a general-purpose linter would be, even though (like `app08_cpp_react`'s `clang-tidy`) it is pattern-based, not proof-based. PHPStan adds general static type analysis plus the custom `NoIntegrityVerifierInRestApi` rule (`PLAN.md` D-03).

### 4.3 SCA — with a WordPress-specific layer no sibling needed
`composer audit`/`roave/security-advisories` cover this plugin's own PHP dependencies, the same category of check every sibling performs for its own ecosystem. **The WPScan vulnerability database scan is additional and specific to this project**: it checks WordPress core itself, this plugin, and every other plugin/theme in the deployment against a database purpose-built for this platform — there is no equivalent concept for a custom-built Go/Rust/Haskell/C++ backend, because none of them run atop a shared platform with independently-versioned, independently-vulnerable co-installed components.

### 4.4 DAST (OWASP ZAP)
Baseline (passive) scan on every PR against staging; full active scan before each production release, targeting all public routes and templates.

### 4.5 Abuse-case tests (integration level)
```php
public function test_ac14_route_registered_without_permission_callback_would_be_caught(): void {
    $routes = rest_get_server()->get_routes( 'securepress/v1' );
    foreach ( $routes as $route => $handlers ) {
        foreach ( $handlers as $handler ) {
            $this->assertArrayHasKey( 'permission_callback', $handler, "Route {$route} is missing permission_callback" );
        }
    }
}

public function test_ac16_check_constraint_rejects_bypass_via_direct_sql(): void {
    // see US-19's DesignHarmConstraintTest — this abuse case is verified at the DB layer directly
}
```

### 4.6 Security regression testing
Every fixed security bug gets a permanent regression test, run on every CI build, never skipped.

---

## Phase 5 — Deployment (Secure Release)

### 5.1 CI/CD pipeline with security gates
```
lint (PHPCS/WPCS) → static analysis (PHPStan) → unit+property tests (PHPUnit/eris)
   → SCA (composer audit + WPScan) → acceptance tests (wp-browser against a real WP+MySQL instance)
   → container scan (Trivy) → deploy to staging → DAST baseline → E2E (Playwright)
   → manual QA sign-off → deploy to production (staged, plugin-version-pinned)
   → DAST full scan (scheduled, not blocking)
```

### 5.2 Infrastructure hardening checklist
```
Nginx           TLS 1.2+/1.3 only; HSTS; security headers; request size limits; block direct
                access to wp-config.php, xmlrpc.php (404, not just disabled at the app layer)
PHP-FPM          display_errors=Off in production; error detail logged server-side only
WordPress core   version string hidden; DISALLOW_FILE_EDIT set; auto-updates limited to minor/
                 security releases only, with staging-first verification for anything larger
MySQL            least-privilege DB user for the WordPress/plugin connection (no GRANT ALL);
                 network isolated; CHECK constraint enforcement confirmed active (version ≥ 8.0.16)
Redis            password-protected; not exposed on the host
Docker           non-root PHP-FPM process where the base image supports it
```

**On this project's deployment-footprint story, for consistency with the series' practice of stating specific numbers rather than vague comparisons:** a WordPress deployment's footprint is dominated by WordPress core itself, a large, fixed baseline no custom-backend sibling carries — `requirements.md` NFR-07.1 states this plainly rather than attempting a footprint comparison that would measure two different things.

### 5.3 Secrets management
`wp-config.php` secret constants (DB credentials, WordPress salts, any API tokens) are sourced from environment variables / Docker secrets, never committed; rotated quarterly and immediately on suspected exposure.

---

## Phase 6 — Maintenance & Runtime Monitoring

### 6.1 Runtime monitoring
- `php-fpm_exporter` and `mysqld_exporter` feed Prometheus; Grafana dashboards track request latency, rate-limit rejections, `content_integrity_check_ok` gauge, WP-Cron job queue depth/failure rate.
- A Loki alert `SEC-CARD-HASH-MISMATCH` fires directly from `Integrity_Verifier`'s Monolog error entry.
- **A monitoring signal with no equivalent in any custom-backend sibling's plan:** a scheduled job (itself a WP-Cron job, deliberately outside this plugin's own security-sensitive code path) polls the WPScan API for new advisories affecting the deployed WordPress core version or any co-installed plugin/theme, and pages the on-call rotation on any new HIGH/CRITICAL finding — a recurring external-advisory check no custom-backend sibling's own dependency graph requires in the same form, because none of them run atop a shared, independently-versioned platform.

### 6.2 Patch management (Kanban)
A dedicated `DEPENDENCY UPDATES` swimlane, fed weekly by Dependabot-equivalent tooling for Composer, plus the WPScan advisory poll from §6.1; any reachable vulnerability auto-creates a `SEC REVIEW`-gated card with a 5-business-day SLA. **WordPress core updates are handled on their own sub-lane**, staging-first, because a core update can change REST API behavior, capability defaults, or i18n loading in ways a Composer dependency bump for a custom backend typically does not — this asymmetry is itself a documented risk this swimlane exists to manage.

### 6.3 Incident response (outline)
1. Detect (monitoring alert, WPScan advisory, or user report) → 2. Contain (deactivate the affected feature via a feature-flag option, or, if the finding is in WordPress core/another plugin rather than this plugin's own code, coordinate with the hosting/ops team on an emergency core/plugin update) → 3. Eradicate (patch — for a finding in this plugin's own code, following the same fix-plus-regression-test discipline as every sibling; for a finding in WordPress core or a third-party plugin, applying the vendor's patch and re-running the full WPScan/ZAP suite) → 4. Recover (redeploy) → 5. Post-mortem, feeding new abuse cases back into Phase 1.

### 6.4 Content & translation review schedule
- Quarterly re-verification that every `CornucopiaCard.content_sha256` still matches its source YAML.
- Quarterly Polish translation audit sampling 10% of `description_pl` fields against current `description_en` for staleness.
- Quarterly re-confirmation that the `chk_design_harm_has_no_severity` `CHECK` constraint is still active and enforced (a MySQL configuration or version regression, e.g. a downgrade or a misconfigured replica, could silently disable `CHECK` enforcement — a risk unique to this project's DB-layer guarantee, checked explicitly rather than assumed permanent).

---

## Phase 7 — WordPress-Specific SSDLC Considerations

1. **Reusing a mature platform's security infrastructure is a legitimate SSDLC strategy, not a shortcut — provided the reuse is verified, not merely assumed.** WordPress's nonce, capability, and i18n systems are each more battle-tested than anything this project could build from scratch in its timeline. This document's Definition of Done and CI gates exist specifically to verify this project *uses* those systems correctly (an explicit `permission_callback` on every route, a capability check before every privileged action, escaping at every output site) — the platform being mature does not mean this plugin's own usage of it is automatically correct.
2. **This project inherits a shared platform's attack surface, and that surface is not fully under this project's control.** No custom-backend sibling has an equivalent to "another, unrelated plugin on the same WordPress installation gets compromised, and that compromise reaches this plugin's data because they share one database and one PHP process." This is named explicitly as a structural risk (§13 in `PLAN.md`) rather than left implicit, and it is the direct motivation for the `WP-HARDENING` Kanban column and the WPScan-based monitoring in Phase 6.
3. **The Digital-by-Default Harms deck's database-level `CHECK` constraint is this project's one guarantee that is arguably stronger, not weaker, than any prior sibling's — and it is worth being precise about *why*.** `app06_HASKELL_react`'s sum type and `app07_rust_react`'s enum both depend on the *application's own compiled code* being the only path to the data; a bug in a different part of either app's own codebase could not violate the invariant, but a *sufficiently privileged raw SQL client* bypassing the application entirely, in principle, still could not violate a `CHECK` constraint either — the same as those two apps' guarantees in that specific respect. Where this project's guarantee differs, and is broader, is that it holds even if a *future PHP code path this project's own authors have not yet written* attempts a violation — there is no compiler to consult when writing that future code, so the safety net has to live somewhere else, and here it lives in the schema.
4. **This is the series' first app where "the frontend framework" is a deliberate non-choice, and that non-choice has its own security properties worth naming.** A server-rendered, progressively-enhanced page (FR-02.4, NFR-02.4) is fully functional and auditable with JavaScript disabled — a categorically different, and in some respects stronger, resilience property than any SPA-based sibling can claim, precisely because there is less client-side logic to have a bug (or a supply-chain-compromised dependency) in, in the first place.

---

## SDLC × SSDLC Master Mapping Table

| Classic SDLC stage | SSDLC security activity in this project | Primary artifact |
|---|---|---|
| Planning & Analysis | Threat modeling with the project's own STRIDE deck AND WordPress's own vulnerability history; compliance mapping (GDPR/AI Act/NIS2/WordPress-specific hardening guidance); abuse cases AC-01–AC-18 | `requirements.md` §1–7, this document Phase 1 |
| Design | Trust-boundary diagram spanning application, WP-Cron, and database layers; least privilege via capabilities and the absence of write routes; STRIDE-per-component table | `PLAN.md` §3–5, this document Phase 2 |
| Implementation | Secure PHP/WordPress coding standards (`$wpdb->prepare()`, nonces, capabilities, escaping, strict YAML validation); TDD red-green with security tests (and `eris` properties) written first | `user_stories+tests.md`, this document Phase 3 |
| Testing | SAST (WPCS/PHPStan), SCA (Composer + **WPScan**), DAST (ZAP), direct-SQL `CHECK`-constraint bypass tests, abuse-case integration tests | this document Phase 4 |
| Deployment | CI/CD security gates, platform-aware hardening checklist, controlled staging-first update process, secrets management | this document Phase 5 |
| Maintenance | Runtime monitoring (including WPScan advisory polling), Kanban-driven patch management with a dedicated WordPress-core sub-lane, incident response, quarterly content/translation/constraint-enforcement review | this document Phase 6 |

---

## Agile Ceremonies — Security & i18n Integration Points

```
Sprint Planning        → New security/i18n stories pulled from backlog alongside features;
                          every card-deck story (US-05–US-12, US-19) is estimated with its Polish
                          translation review as part of the story, not a separate ticket.
Daily Standup          → "Any SEC REVIEW, I18N REVIEW, or WP-HARDENING blocker?" is a standing
                          question — the third clause has no equivalent in any custom-backend
                          sibling's standup.
Mid-Sprint Security Gate → Dedicated 30-minute slot for anything touching Integrity_Verifier's
                          isolation, raw $wpdb query construction, REST permission_callbacks, or
                          output escaping.
Sprint Review          → Demo always includes one security-relevant moment (e.g., a REST route
                          PR caught missing its permission_callback, or the attack-demo dialog).
Sprint Retrospective   → One mandatory retro item: "did any security or translation issue reach
                          TEST or DONE that SEC REVIEW/I18N REVIEW/WP-HARDENING should have caught?"
```

---

## Summary: SSDLC Compliance Checklist for SecurePress 2026

```
[ ] Threat model exists (including WordPress-specific attack classes) and is reviewed each quarter (Phase 0, 6.4)
[ ] Integrity_Verifier::verify() has no callers under includes/rest-api/ — PHPStan rule + review,
    the weakest isolation mechanism in this series, monitored accordingly (Phase 2.1)
[ ] All SQL access goes through $wpdb->prepare() — WPCS-checked, review-verified, not compiler-verified (Phase 3.1)
[ ] All six YAML decks decoded via symfony/yaml + hand-written allow-list validation; SHA-256
    verified regardless (Phase 3, D-08)
[ ] The chk_design_harm_has_no_severity CHECK constraint is confirmed active via a direct-SQL
    bypass test on every schema change (Phase 4.1, 6.4)
[ ] Every REST route has an explicit permission_callback — CI-enforced (Phase 1.4, 4.5)
[ ] SAST (WPCS/PHPStan)/SCA (Composer audit + WPScan)/DAST (ZAP) are all CI-blocking (Phase 4)
[ ] Every abuse case AC-01–AC-18 has an automated regression test (Phase 4.5)
[ ] i18n key parity (.pot drift) and translation review are enforced as release gates (Phase 1, I18N REVIEW column)
[ ] Card content (all 6 decks) is read-only in the application and change-controlled at the source
[ ] xmlrpc.php is disabled; wp-login.php has attempt rate limiting (Phase 0.1, SR-14)
[ ] WordPress core, this plugin, and all co-installed plugins/themes are tracked against the
    WPScan vulnerability database on an ongoing basis, not just at release time (Phase 6.1)
[ ] Digital-by-Default Harms deck cannot carry a Severity value — enforced at the MySQL schema
    layer, independent of any application code (Phase 1.3, FR-19.2, this project's strongest guarantee)
[ ] Kanban board carries explicit SEC REVIEW, I18N REVIEW, and WP-HARDENING columns with WIP limits
[ ] Incident response and patch-management processes exist before, not after, first production release
```
