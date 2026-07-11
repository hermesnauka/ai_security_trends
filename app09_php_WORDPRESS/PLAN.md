# SecurePress 2026 — Application Development Plan

**Version:** 2.0
**Date:** 2026-07-11
**Status:** Living document — updated after each sprint planning session
**Directory:** `app09_php_WORDPRESS`
**Sibling projects:** `app01_react`/`app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django), `app04_scala_react` (Scala/ZIO), `app05_go_react` (Go), `app06_HASKELL_react` (Haskell), `app07_rust_react` (Rust), `app08_cpp_react` (C++), `app10_csharp_react` (C#/.NET)

---

## 0. Note on the Stack — and Why This Plan Looks Different From Every Sibling

This application is built **entirely on WordPress**, using **PHP 8.3** and **vanilla JavaScript** (plus MySQL 8, required by WordPress itself and used directly by this plugin for its own tables). It is a **plugin for an existing, enormously widely-deployed CMS platform**, not a custom-built backend, and that changes what "secure by design" means compared to every custom-backend sibling.

**Three structural differences, stated up front:**

1. **No custom React/Angular SPA frontend.** WordPress's idiomatic pattern — the *Template Hierarchy*, PHP templates progressively enhanced with vanilla JavaScript calling the WordPress REST API — is used deliberately instead of bolting a client-side SPA onto WordPress. §8 covers this in full.
2. **The application inherits WordPress's own enormous, pre-existing attack surface and its equally enormous pre-existing security tooling ecosystem.** This plan treats WordPress's own hardening guidance (Security Whitepaper, Plugin Handbook security section) and the WPScan vulnerability database as primary sources alongside OWASP (§2, §13).
3. **Some guarantees other apps got from a compiler are here either weaker (no compile-time SQL shape-checking — PHP has none) or, in one specific case, *stronger*: the Digital-by-Default Harms deck's "cannot carry a severity" rule is enforced by a MySQL `CHECK` constraint (§4 D-04) — a guarantee that holds even against a raw SQL query run outside the application entirely.**

**Note on code samples:** the application teaches countermeasures in five languages — Python, Java, Go, Scala, and Lua (§10) — as deliberately polyglot **content**, not the application's own runtime. The application itself is PHP, JavaScript, and SQL only.

---

## 0.1 Source Material — What It Actually Contains (read before treating any framework as "already documented")

Two source locations exist one level up, at `../docs/`:

| Source | What it actually covers | What it does NOT cover |
|---|---|---|
| `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md` (~3,000 lines, mostly Polish) | OWASP LLM Top 10 (LLM01–LLM10, full descriptions), OWASP Web Top 10 (A01–A10, full descriptions), MITRE ATLAS (tactic IDs TA0003/TA0008/TA0012/TA0013/TA0014, technique IDs incl. AML.T0010, AML.T0020, AML.T0024, AML.T0029, AML.T0043, AML.T0051), CompTIA Security+ SY0-701 and SecAI+ topic buckets, a STRIDE↔OWASP mapping table, one worked multi-stage attack chain, and one Java/LangChain4j code sample. | OWASP Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, Automated Threats (OAT), MASVS — **none of these are enumerated in this file at all**. No Python/Go/Scala/Lua code anywhere in it. No WordPress/CMS-specific content. |
| `docs/OWASP_stories/*.yaml` (six Cornucopia-family decks) | Card `id`, `value`, `url` (where present), and a free-text `desc`/`misc` scenario per card, across all six decks' suits (VE/AT/SM/AZ/CR/C, PC/AA/NS/RS/CRM/CM, LLM/CLD/FRE/DVO/BOT/AAI, SP/TA/RE/ID/DS/EP, EMR/EIR/EOR/EDR, SCO/ARC/AGE/TRU/POR/COR) plus Wild Card suits per deck. | **No `severity`, `card_kind`, design-harm/technical-threat marker, or OWASP/MITRE/CWE cross-reference field exists in any of the six files.** `url`, where present, always points back to `cornucopia.owasp.org` or `digitalbenefits.uk`, never to an external framework ID. |

**Consequence for this plan, stated plainly:** the framework families with no numbered IDs in either source (Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, OAT, MASVS) are covered in this app by (a) mapping the relevant Cornucopia suit (AAI, DVO+BOT, FRE, mobile suits) to the corresponding published OWASP list, and (b) hand-authoring the specific numbered mappings, severities, and `card_kind` classification during content curation (§4 D-04, D-08, §12) — not by extracting them from a source file that doesn't contain them. Every `severity` value and every `owasp_refs`/`mitre_refs` value in `sp_cards` (§5.1) is **curated content the maintainers write**, validated by an allow-list at ingestion time, not parsed out of the YAML. This is a stronger, more honest statement of provenance than the v1.0 plan made.

---

## 1. Project Overview

**Name:** SecurePress 2026
**Form factor:** A single, self-contained WordPress plugin (`securepress-2026`) — deliberately **not** split across a plugin and a theme, so functionality does not depend on which theme is active.
**Purpose:** A bilingual (Polish/English) reference and learning platform mapping security threats, vulnerabilities and mitigations across **OWASP** (Web Top 10, LLM Top 10, Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, Automated Threats/OAT, MASVS), **MITRE ATLAS**, and **CompTIA Security+ SY0-701 / SecAI+ 2026**, plus the full catalogue of **OWASP Cornucopia-family card decks** in `docs/OWASP_stories/*.yaml`. Each threat is presented with working countermeasure code in **five languages**: Python, Java, Go, Scala, and Lua.

**UI languages:** Polish (default) and English, with a visible switch on every page letting the user toggle PL→EN and EN→PL at will, via WordPress's own multilingual mechanism (§4 D-05) rather than a bespoke `localStorage` toggle. All UI chrome and all threat/card content ships in both languages from day one — this is not an aspirational later phase (§15).

---

## 2. Technology Stack

### Platform & Backend
| Layer | Technology | Version (2026) |
|---|---|---|
| CMS platform | WordPress | 6.8+ |
| Language | PHP | 8.3 |
| Database | MySQL 8.0.16+ (MariaDB 10.11+ also supported) — required by WordPress itself, used directly by this plugin for its own custom tables | — |
| Data access | `$wpdb` with `$wpdb->prepare()` for every parameterized query | — |
| Custom data storage | Custom `$wpdb` tables via `dbDelta()`, not Custom Post Types + postmeta — the multi-dimensional filtering this app needs (framework × severity × STRIDE × tag, cross-references, per-language code samples) doesn't fit postmeta's key-value model (§5) | — |
| API layer | WordPress REST API (`register_rest_route`, namespace `securepress/v1`), every route with an explicit `permission_callback` | — |
| Background jobs | WP-Cron (`wp_schedule_event`), `DISABLE_WP_CRON` set, triggered by a real system crontab entry rather than page-view-triggered pseudo-cron | — |
| Cache / rate-limit store | WordPress Transients API, backed by a persistent Redis object cache (not the default `wp_options`-table storage, which isn't atomic) | — |
| Auth | WordPress's own user/role/capability system (`current_user_can()`); no JWT layer | — |
| CSRF protection | WordPress nonces (`wp_nonce_field`, `check_ajax_referer`, `wp_verify_nonce`), REST API's `X-WP-Nonce` header | — |
| Output escaping | `esc_html()`, `esc_attr()`, `esc_url()`, `esc_js()`, `wp_kses()`/`wp_kses_post()` | — |
| YAML parsing | `symfony/yaml` (Composer) — no arbitrary object instantiation from tags by default (§4 D-08) | — |
| Password hashing | WordPress core's own (`wp_hash_password`, Argon2i/Argon2id-backed since WP 6.8) | — |
| Dependency management | Composer, with `roave/security-advisories` | — |
| i18n | WordPress's native gettext system: `__()`, `_e()`, `esc_html__()`, `.pot`/`.po`/`.mo`, `load_plugin_textdomain()` | — |
| Structured logging | Monolog, dedicated channel outside the web root | — |
| Testing | PHPUnit + `WP_UnitTestCase` (`wp-env`/`wp-phpunit`), `eris` (property-based testing), `wp-browser`/Codeception | TDD — see `user_stories+tests.md` |
| SAST | PHP_CodeSniffer + WordPress Coding Standards (WPCS) — `WordPress.Security.*`, `WordPress.DB.PreparedSQL`; PHPStan | — |
| SCA | `composer audit` + `roave/security-advisories` + the WPScan vulnerability database (WordPress-plugin/theme/core-specific) | — |

### Frontend (deliberately PHP-rendered + vanilla JS, not React)
| Layer | Technology |
|---|---|
| Rendering | WordPress Template Hierarchy — PHP templates (`archive-threat.php`, `single-threat.php`, suit/edition archive templates), registered via `template_include` |
| Client-side enhancement | Vanilla JavaScript (ES2022), no framework — filter panels, tab switching, language toggle as small dependency-free JS modules via `wp_enqueue_script()` |
| API calls from JS | `window.fetch` against `securepress/v1`; public reads need no nonce, admin writes include `wp_rest_nonce` |
| Styling | Plain CSS (custom properties for theming) via `wp_enqueue_style()`; a minimal esbuild/Vite step only to bundle/minify the JS modules |
| Syntax highlight | Prism.js, self-hosted (no external CDN) |
| I18n on the client | `wp_localize_script()`/`wp_set_script_translations()` |

### Infrastructure
| Component | Technology |
|---|---|
| Web/PHP runtime | Nginx + PHP-FPM, Docker Compose for local/staging parity |
| Container | Docker Compose: `wordpress` (PHP-FPM) + `mysql` + `redis` + `nginx` |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Loki + Prometheus (`php-fpm_exporter`, `mysqld_exporter`) |
| Secrets | `wp-config.php` constants from environment variables / Docker secrets, never committed |
| SAST | PHPCS/WPCS + PHPStan + `eslint-plugin-security` |
| DAST | OWASP ZAP |
| SCA | `composer audit` + `roave/security-advisories` + WPScan CLI/API + `npm audit` (build tooling) + Trivy (containers) |

---

## 3. High-Level Architecture

```
Browser (PHP-rendered pages, vanilla JS enhancement, PL/EN via WP locale)
        │  HTTPS
        ▼
  Nginx (443) → PHP-FPM
   ├── WordPress core bootstrap (wp-load.php)
   │     └── securepress-2026 plugin
   │           ├── includes/rest-api/    — register_rest_route handlers, securepress/v1
   │           ├── includes/templates/   — archive-threat.php, single-threat.php, etc.
   │           ├── includes/service/     — business logic, WP-hook-agnostic
   │           ├── includes/data/        — $wpdb table access, all queries via prepare()
   │           ├── includes/integrity/   — YAML hash verification; verify() called ONLY from
   │           │                           the activation hook and WP-Cron — never a REST
   │           │                           handler (enforced by review + static analysis, D-03)
   │           ├── includes/cron/        — wp_schedule_event handlers
   │           └── includes/admin/       — wp-admin settings + integrity dashboard
   │
   └── /wp-json/securepress/v1/*  — the only HTTP surface JS on the page talks to

MySQL 8      ◄── $wpdb, prepared statements only
Redis        ◄── WordPress object cache (rate limiting, response caching)
```

There is no separate `worker` process: WP-Cron jobs run *inside* the PHP-FPM request lifecycle (or a real system cron hits `wp-cron.php` directly, NFR-05.4). The "only the worker calls `integrity::verify`" boundary every custom-backend sibling enforces with a separate compiled binary is, here, enforced entirely by code organization and review within one PHP process — a materially weaker isolation guarantee than any sibling from `app05_go_react` onward, stated directly (§4 D-03, §13).

---

## 4. Architecture Design Decisions

### D-01 — Custom `$wpdb` tables instead of Custom Post Types, `dbDelta()`-managed
`Threat`, `Mitigation`, `CodeSample`, `CrossReference`, `ContentHash`, `ThreatTranslation`, and `CornucopiaCard` are each a dedicated table created by the activation hook via `dbDelta()` — the WordPress-recommended pattern for relationally-queried structured data that postmeta's key-value model doesn't fit efficiently.

### D-02 — `$wpdb->prepare()` on every query — a runtime-only guarantee, stated as such
```php
$threats = $wpdb->get_results(
    $wpdb->prepare(
        "SELECT * FROM {$wpdb->prefix}sp_threats WHERE framework_code = %s AND severity = %s",
        $framework_code, $severity
    )
);
```
Every query uses `%s`/`%d`/`%f` placeholders, never string interpolation of untrusted input. Unlike `app05_go_react`'s `sqlc`, `app06_HASKELL_react`'s `hasql-th`, or `app07_rust_react`'s `sqlx::query!`, this gives **no compile-time guarantee at all** — PHP has no macro or type system capable of checking a query's shape against the schema before it runs. The WPCS `WordPress.DB.PreparedSQL` sniff is the closest available substitute: pattern-matching, not schema-verification.

### D-03 — `Integrity_Verifier::verify()` isolation is enforced by code organization and review, not a process or compiler boundary
`includes/integrity/class-integrity-verifier.php` exposes one public method, called only from the activation hook and `includes/cron/class-periodic-reverify-job.php`. A custom PHPStan rule (`SecurePress\PHPStan\NoIntegrityVerifierInRestApi`) fails static analysis if a class under the `RestApi` namespace references `Integrity_Verifier`. No compiler, no separate OS process — a static-analysis rule plus code review is the entire enforcement stack, named as this project's largest structural risk (§13).

### D-04 — A MySQL `CHECK` constraint enforces the Digital-by-Default Harms deck's "no severity" rule — and severity/card_kind are curated data, not parsed from source
```sql
CREATE TABLE {$wpdb->prefix}sp_cards (
    card_id       VARCHAR(10)  NOT NULL PRIMARY KEY,
    suit_code     VARCHAR(10)  NOT NULL,
    edition       VARCHAR(20)  NOT NULL,
    card_kind     ENUM('technical_threat','design_harm') NOT NULL,
    severity      ENUM('critical','high','medium','low','info') NULL,
    -- ...
    CONSTRAINT chk_design_harm_has_no_severity
        CHECK (
            (card_kind = 'design_harm'     AND severity IS NULL) OR
            (card_kind = 'technical_threat' AND severity IS NOT NULL)
        )
) ENGINE=InnoDB;
```
Per §0.1, the raw `dbd-cards-1.0-en.yaml` file has **no field at all** indicating design-harm status — `card_kind` is assigned by the loader based on *which of the six files a card came from* (every card in `dbd-cards-1.0-en.yaml` → `design_harm`, `severity = NULL`; every card in the other five decks → `technical_threat`, with a maintainer-curated `severity`). MySQL 8.0.16+ *enforces* this `CHECK` regardless of which code path attempts the write — a raw `wp-cli` query, a future REST handler bug, or a curation mistake are all rejected identically by the database engine itself. This is genuinely stronger, in this one narrow respect, than any sibling's compiler-level guarantee, since those all depend on the application's own code being the only path to the data.

### D-05 — WordPress's native i18n system, used as-is, with a visible PL⇄EN switch on every page
```php
// PHP
esc_html_e( 'Threat Catalogue', 'securepress-2026' );
// JS (after wp_set_script_translations())
__( 'Threat Catalogue', 'securepress-2026' );
```
Every prior custom-backend sibling built its own PL/EN switch from scratch. This app uses WordPress core's own gettext-based i18n system instead (`translate.wordpress.org`, `wp i18n make-pot`). A `language-toggle.js` module (§8) renders a visible PL⇄EN control in the header on every template; switching re-fetches translated `sp_threats`/`sp_cards` content for the current page without a full reload where practical, and always works via a plain link (no-JS fallback) since progressive enhancement (§8) applies to this control too.

### D-06 — Nonces for CSRF, capabilities for authorization
Every state-changing admin action requires a valid WordPress nonce (`wp_verify_nonce()`, `X-WP-Nonce` for REST) and a capability check (`current_user_can( 'manage_securepress' )`), granted to `administrator` and a new `securepress_editor` role this plugin registers. No separate JWT layer.

### D-07 — `CornucopiaCard` rows are never writable through any REST route or admin UI form
The plugin registers **zero** REST routes and **zero** wp-admin edit screens capable of writing `sp_cards`. Only the activation hook's initial ingestion and the periodic re-ingestion Cron job (D-03) write it — enforced by the absence of any write-capable code at all, verified by code review and a CI grep for `INSERT`/`UPDATE` against `sp_cards` outside `includes/integrity`/`includes/cron`.

### D-08 — `symfony/yaml` for parsing, plus a hand-written allow-list — because curated fields (severity, owasp_refs, mitre_refs) don't exist in the source
`Yaml::parse()` does not construct arbitrary PHP objects from tags unless explicitly enabled (never is, here) — this removes a specific vulnerability class, it does not imply the YAML *content* is trusted; SHA-256 integrity verification (D-03) still applies unconditionally. Per §0.1, the six source files carry only `id`/`value`/`url`/`desc`/`misc` — every `severity`, `card_kind`, `owasp_refs`, and `mitre_refs` value in `sp_cards` is added by a **separate, versioned curation file** (`data/cornucopia/curation/*.json`, one per deck, keyed by `card_id`) that the loader merges with the raw YAML at ingestion time, itself validated against an explicit allow-list of expected keys (PHP has no derive-macro or strict-decode-by-default mechanism, so this check is hand-written, covered by an `eris` property test).

### D-09 — Rate limiting via the Transients API backed by Redis
```php
$key = 'sp_ratelimit_' . md5( $ip_address );
$count = (int) get_transient( $key );
if ( $count >= 60 ) {
    return new WP_Error( 'rate_limited', __( 'Too many requests', 'securepress-2026' ), array( 'status' => 429 ) );
}
set_transient( $key, $count + 1, MINUTE_IN_SECONDS );
```
A persistent Redis-backed object cache gives the Transients API atomic `INCR`-equivalent behavior; the default DB-table-backed transient storage is explicitly not used for this reason.

---

## 5. Data Model

### 5.1 Custom tables (created via `dbDelta()`)

```sql
-- {$wpdb->prefix}sp_frameworks
CREATE TABLE {$wpdb->prefix}sp_frameworks (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code          VARCHAR(32)  NOT NULL UNIQUE,   -- "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS", ...
    name          VARCHAR(200) NOT NULL,
    version       VARCHAR(20)  NOT NULL,
    description   TEXT NOT NULL,
    reference_url VARCHAR(500) NOT NULL
) ENGINE=InnoDB;

-- {$wpdb->prefix}sp_threats
CREATE TABLE {$wpdb->prefix}sp_threats (
    id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    framework_id   BIGINT UNSIGNED NOT NULL,
    code           VARCHAR(40)  NOT NULL,          -- "LLM01:2025", "A03:2021", "AML.T0051"
    title          VARCHAR(300) NOT NULL,
    severity       ENUM('critical','high','medium','low','info') NOT NULL,
    category       VARCHAR(100) NOT NULL,
    description    TEXT NOT NULL,
    attack_vector  TEXT NOT NULL,
    attack_surface TEXT NOT NULL,
    stride         VARCHAR(6)   NOT NULL DEFAULT '',
    tags           TEXT NOT NULL DEFAULT '[]',      -- JSON array (MySQL 8 native JSON)
    FOREIGN KEY (framework_id) REFERENCES {$wpdb->prefix}sp_frameworks(id)
) ENGINE=InnoDB;

-- {$wpdb->prefix}sp_threat_translations  (content i18n — distinct from D-05's UI i18n)
CREATE TABLE {$wpdb->prefix}sp_threat_translations (
    id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    threat_id     BIGINT UNSIGNED NOT NULL,
    locale        ENUM('pl','en') NOT NULL,
    title         VARCHAR(300) NOT NULL,
    description   TEXT NOT NULL,
    attack_vector TEXT NOT NULL,
    UNIQUE KEY uq_threat_locale (threat_id, locale),
    FOREIGN KEY (threat_id) REFERENCES {$wpdb->prefix}sp_threats(id)
) ENGINE=InnoDB;

-- {$wpdb->prefix}sp_cards  (all six YAML decks; severity/card_kind/refs are curated, see D-04/D-08)
CREATE TABLE {$wpdb->prefix}sp_cards (
    card_id           VARCHAR(10)  NOT NULL PRIMARY KEY,   -- "VE3", "LLM4", "SPX", "EMR2", "SCO2"
    suit_code         VARCHAR(10)  NOT NULL,
    suit_name         VARCHAR(100) NOT NULL,
    edition           VARCHAR(20)  NOT NULL,               -- webapp, mobileapp, companion, eop, mlsec, dbd
    card_value        VARCHAR(2)   NOT NULL,
    is_critical       TINYINT(1)   NOT NULL DEFAULT 0,
    card_kind         ENUM('technical_threat','design_harm') NOT NULL,
    severity          ENUM('critical','high','medium','low','info') NULL,
    description_en    TEXT NOT NULL,
    description_pl    TEXT NOT NULL,
    misc_note         TEXT NULL,
    source_url        VARCHAR(500) NULL,
    owasp_refs        JSON NOT NULL,   -- curated, e.g. ["LLM01:2025"] — see D-08
    mitre_refs        JSON NOT NULL,   -- curated, e.g. ["AML.T0051"]
    content_sha256    CHAR(64) NOT NULL,
    CONSTRAINT chk_design_harm_has_no_severity CHECK (
        (card_kind = 'design_harm'     AND severity IS NULL) OR
        (card_kind = 'technical_threat' AND severity IS NOT NULL)
    ),
    INDEX idx_suit (suit_code), INDEX idx_edition (edition)
) ENGINE=InnoDB;

-- {$wpdb->prefix}sp_mitigations
CREATE TABLE {$wpdb->prefix}sp_mitigations (
    id             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    slug           VARCHAR(100) NOT NULL UNIQUE, -- stable seed-data key, e.g. "sql-injection-prevention"
    threat_id      BIGINT UNSIGNED NULL,
    card_id        VARCHAR(10) NULL,
    title          VARCHAR(300) NOT NULL,
    description    TEXT NOT NULL,
    mitigation_type ENUM('preventive','detective','corrective','compensating') NOT NULL,
    effort         ENUM('low','medium','high') NOT NULL,
    effectiveness  ENUM('partial','significant','full') NOT NULL,
    FOREIGN KEY (threat_id) REFERENCES {$wpdb->prefix}sp_threats(id),
    FOREIGN KEY (card_id)   REFERENCES {$wpdb->prefix}sp_cards(card_id)
) ENGINE=InnoDB;

-- {$wpdb->prefix}sp_code_samples
CREATE TABLE {$wpdb->prefix}sp_code_samples (
    id              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    mitigation_id   BIGINT UNSIGNED NOT NULL,
    language        ENUM('python','java','go','scala','lua') NOT NULL,
    sample_type     ENUM('attack_demo','defense') NOT NULL,
    title           VARCHAR(200) NOT NULL,
    description     TEXT NOT NULL,
    code            MEDIUMTEXT NOT NULL,
    framework_hint  VARCHAR(100) NOT NULL,
    version_note    VARCHAR(100) NOT NULL,
    FOREIGN KEY (mitigation_id) REFERENCES {$wpdb->prefix}sp_mitigations(id)
) ENGINE=InnoDB;

-- {$wpdb->prefix}sp_cross_references
CREATE TABLE {$wpdb->prefix}sp_cross_references (
    id                 BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    source_threat_id   BIGINT UNSIGNED NOT NULL,
    target_threat_id   BIGINT UNSIGNED NOT NULL,
    relationship_type  ENUM('equivalent','related','parent_child','maps_to') NOT NULL,
    description        TEXT NOT NULL,
    FOREIGN KEY (source_threat_id) REFERENCES {$wpdb->prefix}sp_threats(id),
    FOREIGN KEY (target_threat_id) REFERENCES {$wpdb->prefix}sp_threats(id)
) ENGINE=InnoDB;

-- {$wpdb->prefix}sp_content_hashes
CREATE TABLE {$wpdb->prefix}sp_content_hashes (
    file_name    VARCHAR(100) NOT NULL PRIMARY KEY,
    sha256_hash  CHAR(64)     NOT NULL,
    verified_at  DATETIME     NOT NULL,
    is_valid     TINYINT(1)   NOT NULL,
    verified_by  VARCHAR(30)  NOT NULL DEFAULT 'securepress-integrity-verifier'
) ENGINE=InnoDB;

-- {$wpdb->prefix}sp_export_jobs  (FR-17.3/17.4, Phase 6 — added when export was built, format is
-- CSV-only: no PDF library is in composer.json, so a 'pdf' value is rejected at the API layer
-- rather than silently downgraded)
CREATE TABLE {$wpdb->prefix}sp_export_jobs (
    job_id         VARCHAR(36)  NOT NULL PRIMARY KEY,
    status         ENUM('pending','processing','completed','failed') NOT NULL DEFAULT 'pending',
    format         ENUM('csv') NOT NULL,
    framework_code VARCHAR(32) NULL,
    file_path      VARCHAR(500) NULL,
    error_message  VARCHAR(500) NULL,
    created_at     DATETIME NOT NULL,
    completed_at   DATETIME NULL
) ENGINE=InnoDB;

-- FULLTEXT indexes (FR-17.1, Phase 6): added via ALTER TABLE rather than embedded in the
-- CREATE TABLE statements above, for the same dbDelta()-reliability reason as D-02/D-04's
-- FOREIGN KEY/CHECK constraints (PLAN.md §4 D-02, D-04).
-- ALTER TABLE {$wpdb->prefix}sp_threats ADD FULLTEXT INDEX ft_threats_search (title, description);
-- ALTER TABLE {$wpdb->prefix}sp_cards   ADD FULLTEXT INDEX ft_cards_search (description_en, description_pl);
```

All tables use `{$wpdb->prefix}` and `InnoDB` (required for foreign keys and `CHECK` enforcement).

---

## 6. Development Phases

*(Numbering aligned with the Agile/Scrum sprint plan in `SDLC_analysis.md`.)*

### Phase 1 — Foundation (Sprints 1–2) — Covers US-01, US-02
- [ ] Plugin scaffold (`securepress-2026.php` header, PSR-4 autoloaded `includes/` via Composer)
- [ ] Activation hook: `dbDelta()` creates all §5.1 tables
- [ ] Docker Compose: WordPress (PHP-FPM) + MySQL 8 + Redis + Nginx, `wp-env` for CI parity
- [ ] Seed routine (idempotent, from activation hook) loading OWASP Web/LLM/Agentic/API, MITRE ATLAS, CompTIA SecAI+ from curated JSON
- [ ] `GET /wp-json/securepress/v1/frameworks`, `GET /wp-json/securepress/v1/threats` (paginated), both with **explicit** public `permission_callback` returning `true`
- [ ] `securepress_editor` role + `manage_securepress` capability
- [ ] Base templates: `archive-threat.php`, `single-threat.php`
- [ ] Vanilla JS bootstrap (`assets/js/threat-browser.js`), PL⇄EN switch visible in the header

**Security checkpoint:** PHPCS/WPCS zero `WordPress.Security.*`/`WordPress.DB.PreparedSQL` findings; every route has an explicit `permission_callback`.

### Phase 2 — Core Threat Browser (Sprints 3–4) — Covers US-02, US-03, US-04
- [ ] `$wpdb->prepare()`-based filtering: framework, severity, stride, category, tag, q
- [ ] `GET /wp-json/securepress/v1/threats/{id}` with nested mitigations + code samples
- [ ] PHP templates render server-side; vanilla JS enhances the filter panel via `fetch()` (page works with JS disabled)
- [ ] `GET /wp-json/securepress/v1/cross-references`, `/matrix/` page template

**Security checkpoint:** WPCS `WordPress.DB.PreparedSQL` passes on every new query; manual review confirms full JS-disabled usability.

### Phase 3 — Card Decks & Content Integrity (Sprints 5–7) — Covers US-05–US-12, US-19
- [ ] `includes/cards/class-card-loader.php` — `symfony/yaml` decode + curation-file merge + allow-list validation for all six decks (D-08)
- [ ] `Integrity_Verifier::verify()` — SHA-256 vs `data/hashes.json`; called only from activation + Cron (D-03)
- [ ] Suit archive templates: FRE, LLM, AAI, CLD (Companion), SP/TA/RE/ID/DS/EP (STRIDE), EMR/EIR/EOR/EDR (MLSec), PC/AA/NS/RS/CRM/CM (Mobile), VE/AT/SM/AZ/CR/C (Website App), **SCO/ARC/AGE/TRU/POR (Digital-by-Default Harms, US-19)**
- [ ] `chk_design_harm_has_no_severity` verified with an explicit failing-insert test
- [ ] `AttackDemoWarning` confirmation `<dialog>` before rendering `attack_demo` samples

**Security checkpoint:** malformed/unknown-field YAML rejected before any DB write (`eris` generates random extra keys, asserts rejection); hash mismatch aborts ingestion inside one `$wpdb` transaction; a direct `INSERT` violating the `CHECK` constraint confirmed to fail at the DB layer.

### Phase 4 — Code Samples: 5 Languages (Sprints 7–9) — Covers US-13–US-16
- [ ] Code sample seed data for every mitigation × 5 languages (Python, Java, Go, Scala, Lua) — original content, authored for this project (§0.1: no source file supplies these)
- [ ] Attack-demo / defense sub-tabs, red-bordered warning label
- [ ] MITRE ATLAS Kill-Chain timeline (vanilla-JS/SVG, no charting dependency)

### Phase 5 — i18n Polish ↔ English (Sprint 9–10) — Covers US-11/FR-18 (folded into every story)
- [ ] `.pot` via `wp i18n make-pot`; `.po`/`.mo` for `pl_PL` and `en_US` committed
- [ ] `load_plugin_textdomain()` wired to the site locale; front-end `?lang=` switcher, visible on every page (D-05)
- [ ] `sp_threat_translations` served per-locale for threat content
- [ ] Code samples **never** translated
- [ ] CI check: `wp i18n make-pot --skip-audit` diff against committed `.pot` fails the build on drift

### Phase 6 — Search, Export, Matrix Completion (Sprints 10–12) — Covers US-17, US-18
- [ ] MySQL `FULLTEXT` index on `sp_threats`/`sp_cards`; `MATCH...AGAINST` via `$wpdb->prepare()`
- [ ] WP-Cron job (`securepress_export_job`) generating CSV/PDF, polled via a REST status route
- [ ] `/matrix/llm/`, `/matrix/agentic/`, `/matrix/mobile-vs-web/`, `/stride-heatmap/`, `/matrix/digital-harms/`
- [ ] Transients-based rate limiting (D-09): 60 req/min/IP on all public list routes

### Phase 7 — Hardening, Testing & Release (Sprints 12–14) — Full regression US-01–US-19
- [ ] PHPUnit + `WP_UnitTestCase` suite, `eris` properties, ≥ 85% coverage on `includes/service`
- [ ] `wp-browser`/Codeception integration tests against real WordPress + MySQL
- [ ] Playwright (TypeScript) E2E — one scenario per user story
- [ ] PHPCS/WPCS + PHPStan + `composer audit` + WPScan CLI, zero HIGH findings
- [ ] OWASP ZAP full active scan against staging
- [ ] Production: plugin + Composer deps pinned, controlled release process — not WordPress's auto-update-everything default, given custom-schema migration coordination

---

## 7. API Endpoint Map

```
GET  /wp-json/securepress/v1/frameworks
GET  /wp-json/securepress/v1/frameworks/{code}
GET  /wp-json/securepress/v1/threats?framework=&severity=&stride=&category=&tag=&q=
GET  /wp-json/securepress/v1/threats/{id}
GET  /wp-json/securepress/v1/threats/{id}/mitigations
GET  /wp-json/securepress/v1/threats/{id}/code-samples?language=go

GET  /wp-json/securepress/v1/threats?suit=fre                   — Frontend cards (US-05)
GET  /wp-json/securepress/v1/threats?suit=llm                   — LLM cards (US-06)
GET  /wp-json/securepress/v1/threats?suit=aai                   — Agentic AI cards (US-07)
GET  /wp-json/securepress/v1/threats?suit=cld                   — Cloud cards (US-07)
GET  /wp-json/securepress/v1/threats/stride/categories          — 6 STRIDE categories (US-08)
GET  /wp-json/securepress/v1/threats?suit=sp|ta|re|id|ds|ep     — individual STRIDE suits
GET  /wp-json/securepress/v1/threats/mlsec/categories           — 4 MLSec categories (US-09)
GET  /wp-json/securepress/v1/threats?suit=emr|eir|eor|edr       — individual MLSec suits
GET  /wp-json/securepress/v1/threats/mobile/suits               — 6 Mobile suits (US-10)
GET  /wp-json/securepress/v1/threats?suit=pc|aa|ns|rs|crm|cm    — individual Mobile suits
GET  /wp-json/securepress/v1/threats?suit=ve|at|sm|az|cr|c      — Website App Cornucopia suits (US-12)
GET  /wp-json/securepress/v1/threats?suit=dvo                   — DevOps cards (US-11)
GET  /wp-json/securepress/v1/threats?suit=bot                   — Automated Threat cards (US-11)
GET  /wp-json/securepress/v1/threats/digital-harms/suits        — 5 Digital-by-Default suits (US-19)
GET  /wp-json/securepress/v1/threats?suit=sco|arc|age|tru|por   — individual Digital-by-Default suits (US-19)

GET  /wp-json/securepress/v1/matrix/llm
GET  /wp-json/securepress/v1/matrix/agentic
GET  /wp-json/securepress/v1/matrix/mobile-vs-web
GET  /wp-json/securepress/v1/stride-heatmap        [nonce/capability-gated — SR-01]
GET  /wp-json/securepress/v1/cross-references
GET  /wp-json/securepress/v1/cross-references?sourceCode=LLM01

GET  /wp-json/securepress/v1/search?q=prompt+injection
GET  /wp-json/securepress/v1/export?format=csv&framework=OWASP_LLM   (202 + poll URL)
GET  /wp-json/securepress/v1/export/status/{jobId}

wp-admin/admin.php?page=securepress-threats          — CRUD for Threat/Mitigation/CodeSample (manage_securepress)
wp-admin/admin.php?page=securepress-integrity         — integrity verification dashboard (manage_securepress)

GET  /wp-json/securepress/v1/health
GET  /wp-json/securepress/v1/metrics                 [capability-gated]
GET  /wp-json/securepress/v1/integrity/status         [capability-gated]
```
`CornucopiaCard` rows have **no** wp-admin edit screen and **no** REST write route (D-07).

---

## 8. Front-End Page & Template Structure (PHP + Vanilla JS, Not React)

```
Template Hierarchy registrations (via template_include):
  /                                        → templates/home.php (framework tiles, quick search)
  /threats/                                 → templates/archive-threat.php (filter panel, results grid)
  /threats/{slug}/                          → templates/single-threat.php (tabs: Overview | Attack
                                                Vectors | Mitigations | Code | Cross-References)
  /frameworks/website-app/                  → templates/suit-archive.php?edition=webapp   (US-12)
  /frameworks/frontend-security/            → templates/suit-archive.php?suit=fre         (US-05)
  /frameworks/llm-security/                 → templates/suit-archive.php?suit=llm         (US-06)
  /frameworks/agentic-ai/                   → templates/suit-archive.php?suit=aai         (US-07)
  /frameworks/stride/                       → templates/stride-catalogue.php               (US-08)
  /frameworks/ml-security/                  → templates/suit-archive.php?edition=mlsec     (US-09)
  /frameworks/mobile-security/              → templates/suit-archive.php?edition=mobileapp (US-10)
  /frameworks/devops-security/              → templates/devops-security.php (DVO+CLD+BOT)   (US-11)
  /frameworks/digital-harms/                → templates/digital-harms.php                    (US-19)
  /matrix/                                   → templates/matrix.php
  /stride-heatmap/                           → templates/stride-heatmap.php (capability-gated)
  /search/                                   → templates/search-results.php
  /about/                                    → a normal WordPress Page (Gutenberg-edited CMS
                                                 content, not the app's own data-driven pages)

Vanilla JS modules (assets/js/, no framework, ES modules):
  threat-browser.js        — filter panel, debounced fetch() against /threats
  code-sample-panel.js      — language tab switching, attack-demo confirmation <dialog>, copy button
  language-toggle.js        — visible PL⇄EN switch: reads/writes the site locale query-var,
                                re-fetches translated content; degrades to a plain link with JS off
  stride-heatmap.js         — renders the heatmap from JSON (no charting library)
  bot-warning-modal.js      — confirmation dialog before BOT suit attack-demo content (US-11)
```

---

## 9. WordPress Plugin File Layout

```
wp-content/plugins/securepress-2026/
├── securepress-2026.php               ← plugin header, bootstrap
├── composer.json / composer.lock       ← symfony/yaml, monolog, roave/security-advisories
├── includes/
│   ├── class-plugin.php                ← activation/deactivation hooks, dbDelta() calls
│   ├── data/
│   │   ├── class-threat-repository.php
│   │   ├── class-card-repository.php
│   │   ├── class-mitigation-repository.php
│   │   └── class-content-hash-repository.php
│   ├── service/                        ← business logic, no direct $wpdb calls
│   ├── cards/
│   │   └── class-card-loader.php       ← symfony/yaml decode + curation merge + allow-list (D-08)
│   ├── integrity/
│   │   └── class-integrity-verifier.php ← isolated per D-03
│   ├── rest-api/
│   │   ├── class-framework-controller.php
│   │   ├── class-threat-controller.php
│   │   ├── class-card-controller.php
│   │   ├── class-matrix-controller.php
│   │   ├── class-search-controller.php
│   │   └── class-export-controller.php
│   ├── cron/
│   │   ├── class-export-job.php
│   │   ├── class-reingest-deck-job.php
│   │   └── class-periodic-reverify-job.php
│   ├── admin/
│   │   ├── class-threats-admin-page.php
│   │   └── class-integrity-dashboard.php
│   └── templates/                       ← PHP templates, §8
├── assets/
│   ├── js/                              ← vanilla JS modules, §8
│   └── css/
├── data/
│   ├── owasp_web_top10.json
│   ├── owasp_llm_top10.json
│   ├── owasp_agentic_top10.json
│   ├── owasp_api_top10.json
│   ├── owasp_client_side_top10.json
│   ├── owasp_cicd_top10.json
│   ├── owasp_oat.json
│   ├── owasp_masvs.json
│   ├── mitre_atlas.json
│   ├── comptia_secai.json
│   ├── cornucopia/
│   │   ├── webapp-cards-3.0-en.yaml
│   │   ├── companion-llm-cards-1.0-en.yaml
│   │   ├── mobileapp-cards-1.1-en.yaml
│   │   ├── stride-eop-cards-5.0-en.yaml
│   │   ├── mlsec-cards-1.0-en.yaml
│   │   ├── dbd-cards-1.0-en.yaml       ← Digital-by-Default Harms (US-19)
│   │   ├── curation/                   ← hand-authored severity/card_kind/owasp_refs/mitre_refs
│   │   │   └── *.curation.json          per deck, keyed by card_id (D-08)
│   │   └── translations/
│   │       └── pl.cards.json
│   ├── hashes.json
│   ├── mitre-atlas-allowlist.json
│   ├── ref-allowlists.json
│   └── code_samples/{python,java,go,scala,lua}/
├── languages/
│   ├── securepress-2026.pot
│   ├── securepress-2026-pl_PL.po/.mo
│   └── securepress-2026-en_US.po/.mo
├── tests/
│   ├── unit/                            ← PHPUnit + WP_UnitTestCase
│   ├── property/                        ← eris
│   └── acceptance/                      ← wp-browser/Codeception
└── e2e/
    └── *.spec.ts                        ← Playwright, one file per user story (us01..us19)
```

---

## 10. Code Sample Strategy

Every `Mitigation` ships exactly **five** `CodeSample` rows — **original content authored for this project** (§0.1: no source material supplies multi-language code). Completeness is verified by an `eris` property over the seeded dataset and a CI seed-data linter, not a type-level guarantee (PHP arrays have no non-emptiness concept).

| Language | Primary framework/library used in samples |
|---|---|
| Python | Django ORM / FastAPI + Pydantic |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | `chi` + `sqlc` + `pgx` |
| Scala | Akka HTTP / http4s, Slick 3.x, ZIO 2 |
| Lua | OpenResty / NGINX Lua, `lua-resty-jwt`, LuaSQL |

```
sample_type: attack_demo   // VULNERABLE — do not use in production
sample_type: defense       // SECURE pattern, with a one-line WHY comment
```

**PHP as an implicit sixth example:** for injection-related mitigations, the Threat Detail page's Code Samples tab links to this very plugin's own `$wpdb->prepare()` usage (D-02) as a callout — without adding PHP as a seventh formal sample language (the brief specifies five: Python, Java, Go, Scala, Lua).

---

## 11. Security Data Coverage Plan

| Framework | Coverage target | Source (per §0.1) |
|---|---|---|
| OWASP Web Top 10 (2021) | A01–A10, all 10 | `docs/Security Architects...md` (full descriptions present) + `VE/AT/SM/AZ/CR/C` cards |
| OWASP LLM Top 10 (2025) | LLM01–LLM10, all 10 | `docs/Security Architects...md` (full descriptions present) + `LLM` suit |
| OWASP Agentic AI Top 10 (2026) | AgentAI01–10 | **curated/authored** — not in either source file; cross-referenced to `AAI` suit |
| OWASP API Security Top 10 | API1–API10 | **curated/authored** — not in either source file |
| OWASP Client-Side Top 10 | C01–C10 | **curated/authored**, cross-referenced to `FRE` suit |
| OWASP CI/CD Security Top 10 | CICD-SEC-01–10 | **curated/authored**, cross-referenced to `DVO` suit |
| OWASP Automated Threats (OAT) | ≥ 13 of 21 | **curated/authored**, cross-referenced to `BOT` suit |
| Cloud misconfiguration (A05/A01:2021) | — | `CLD` suit, no dedicated OWASP Top 10 of its own |
| OWASP MASVS 2.0 | all 7 categories | **curated/authored**, cross-referenced to `PC/AA/NS/RS/CRM/CM` suits |
| STRIDE | S,T,R,I,D,E — all 6 | `docs/Security Architects...md` (STRIDE↔OWASP mapping present) + `SP/TA/RE/ID/DS/EP` suits |
| Elevation of MLSec | Model/Input/Output/Dataset Risk | `EMR/EIR/EOR/EDR` suits (source `desc`/`misc` text) |
| MITRE ATLAS | ≥ 15 techniques across ≥ 5 tactics | `docs/Security Architects...md` (TA0003/TA0008/TA0012/TA0013/TA0014; AML.T0010/T0020/T0024/T0029/T0043/T0051 present) + curated extensions |
| CompTIA Security+ / SecAI+ | ≥ 20 topics, **including WordPress/CMS-specific classes** (plugin/theme supply-chain compromise, missing REST `permission_callback`, XML-RPC abuse, `wp-login.php` credential stuffing — none present in source, authored as a WordPress-specific supplement) | `docs/Security Architects...md` topic buckets + WordPress-specific supplement |
| OWASP A04:2021 Insecure Design — Digital-by-Default Harms | Scope/Architecture/Agency/Trust/Porosity | `SCO/ARC/AGE/TRU/POR` suits (US-19) — not a technical-vulnerability deck, see D-04 |

Every row marked "curated/authored" above still gets the same integrity-verification and allow-list treatment as extracted content (D-03, D-08) — "authored" describes provenance, not a lower bar for review.

---

## 12. Cornucopia Content Pipeline

```
data/cornucopia/
├── webapp-cards-3.0-en.yaml          → VE, AT, SM, AZ, CR, C
├── companion-llm-cards-1.0-en.yaml   → LLM, FRE, DVO, BOT, CLD, AAI
├── mobileapp-cards-1.1-en.yaml       → PC, AA, NS, RS, CRM, CM
├── stride-eop-cards-5.0-en.yaml      → SP, TA, RE, ID, DS, EP
├── mlsec-cards-1.0-en.yaml           → EMR, EIR, EOR, EDR
├── dbd-cards-1.0-en.yaml             → SCO, ARC, AGE, TRU, POR, COR, WC (US-19)
├── curation/*.curation.json          → severity, card_kind, owasp_refs, mitre_refs per card_id (D-08)
└── translations/
    └── pl.cards.json

data/hashes.json                       ← SHA-256 per YAML file (raw source only — curation files
                                          are versioned in git and reviewed via normal PR diff)
data/mitre-atlas-allowlist.json
data/ref-allowlists.json
```

**Workflow:**
1. PR touching `data/cornucopia/*.yaml` or `curation/*.json` → CODEOWNERS `@security-team`, min. 2 approvals.
2. CI job `yaml-content-integrity`: `symfony/yaml` parse + allow-list key validation (D-08) on every raw file + curation-file schema validation + injection-pattern grep + ref-allowlist validation + an attempted `INSERT` against a scratch DB verifying the `CHECK` constraint (D-04) still rejects a malformed `card_kind`/`severity` combination.
3. Post-merge: `hash-generator` CI step updates `data/hashes.json` (raw YAML only).
4. Activation hook and `Periodic_Reverify_Job` both call `Integrity_Verifier::verify()` — on mismatch, ingestion aborts inside a single `$wpdb` transaction (no partial writes), `SEC-CARD-HASH-MISMATCH` logged via Monolog, alerted on by Loki.

---

## 13. Risk Register

| Risk | Mitigation |
|---|---|
| SQL injection via a future query that skips `$wpdb->prepare()` | WPCS `WordPress.DB.PreparedSQL` sniff (pattern-based, not schema-verified) + code review |
| `Integrity_Verifier::verify()` called from an unintended path | Custom PHPStan rule + code review — no process boundary or compiler backstop exists at all, the weakest version of this control in the series |
| A REST route registered without an explicit `permission_callback` | A well-known, historically real WordPress REST API vulnerability class; CI check grepping `register_rest_route` for a present `permission_callback` + mandatory review |
| Digital-by-Default Harms deck misread as CVE severity | `chk_design_harm_has_no_severity` MySQL `CHECK` constraint (D-04) — enforced independent of application code |
| A curation file (`curation/*.json`) assigns a wrong severity or a fabricated OWASP/MITRE reference, since none exists in the raw YAML (§0.1) | CODEOWNERS review + ref-allowlist validation against known-good ID lists (D-08) — this is a new risk this v2.0 plan states explicitly that v1.0 did not, since v1.0 assumed the source data already carried these fields |
| Plugin/theme/core supply-chain compromise | WPScan vulnerability database scan in CI + controlled, non-automatic updates with staging-first rollout |
| `wp-login.php` credential stuffing | Rate limiting via Transients API (D-09) on login attempts + REST API; login-attempt-limiting mu-plugin as defense in depth |
| XML-RPC amplification/pingback abuse | `xmlrpc.php` disabled via `add_filter( 'xmlrpc_enabled', '__return_false' )` |
| Polish translations drift from English source | `content_sha256` stored per card; translation table flags staleness on English-text change |
| YAML card files tampered in a PR | CODEOWNERS review + `Integrity_Verifier::verify()` SHA-256 check, fail-secure |
| Attack-demo code confused with production-safe code | Red border + `attack_demo` badge + confirmation `<dialog>` before code is shown/copied |
| Bot scraping the full catalogue | Transients/Redis rate limit 60 req/min/IP (D-09) |

---

## 14. Directory Layout

```
app09_php_WORDPRESS/
├── PLAN.md
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
├── wp-content/plugins/securepress-2026/   ← see §9 for full internal layout
├── e2e/
└── docker-compose.yml
```

---

## 15. User Stories — Complete List

*(Full acceptance criteria and TDD test plans in `user_stories+tests.md`. All six YAML decks — including Digital-by-Default Harms — are covered from the start of this plan.)*

| ID | Role | Need | Goal |
|---|---|---|---|
| US-01 | security engineer | browse security framework catalogue | single access point to all standards |
| US-02 | security engineer | filter threats by framework, severity, STRIDE, tag, q | quickly find threats relevant to my project |
| US-03 | security engineer | see threat details with mitigations and code samples | understand how to implement protection |
| US-04 | CompTIA SecAI+ student | see how LLM01 Prompt Injection maps to MITRE ATLAS AML.T0051 | understand cross-framework dependencies |
| US-05 | WordPress/PHP developer | browse Cornucopia FRE cards (Companion) | map client-side attack scenarios to mitigations |
| US-06 | ML engineer / AI architect | explore OWASP LLM Top 10 via Cornucopia LLM cards with interactive matrix | understand prompt injection, poisoning, excessive agency |
| US-07 | agentic AI / cloud developer | study AAI + CLD cards | design human-in-the-loop safeguards; spot IAM/storage misconfiguration |
| US-08 | security architect / threat modeler | use STRIDE EoP catalogue with interactive heatmap | run structured threat modeling session |
| US-09 | data scientist / ML security engineer | browse MLSec cards (EMR/EIR/EOR/EDR) with MITRE ATLAS refs | identify adversarial ML, model theft, data poisoning |
| US-10 | Android/iOS developer | see OWASP MASVS threats via Mobile App cards | understand mobile vs. web security differences |
| US-11 | DevSecOps engineer / WordPress site administrator | browse DVO/CLD/BOT cards, and separately harden this very WordPress installation against the same classes | protect CI/CD pipelines, spot cloud misconfig, defend against bots and against WordPress-specific automated attacks |
| US-12 | backend developer | browse Website App Cornucopia cards (VE/AT/SM/AZ/CR/C) | map classic OWASP Web Top 10 attack scenarios to mitigations |
| US-13 | Python developer | see a Python code sample for each mitigation | copy a secure implementation pattern |
| US-14 | Java developer | see a Java code sample for each mitigation | compare against this app's own PHP/WordPress idioms |
| US-15 | Scala developer | find Scala code samples for supply-chain attacks | implement SCA in a Scala pipeline |
| US-16 | Lua/OpenResty developer | see Lua examples for rate limiting preventing LLM DoS | configure NGINX guardrails for an LLM API proxy |
| US-17 | pentester | search a term and find related threats with defenses | assemble a client test checklist |
| US-18 | team lead | export the filtered threat list to CSV/PDF | include it in a risk register |
| US-19 | public-sector product owner / GRC reviewer | browse the "Digital-by-Default Harms" deck (SCO/ARC/AGE/TRU/POR), clearly separated from technical decks | assess digital-exclusion and opaque-design risk, map to A04:2021 |

*(The Polish↔English language switch is folded into every story's acceptance criteria per FR-18 in `requirements.md` — WordPress's native i18n mechanism, D-05, used throughout, with a visible switch control on every page.)*

---

## 16. Milestones & Acceptance Criteria

| Milestone | Deliverable | Done when |
|---|---|---|
| M1 | Working skeleton | `docker compose up` → WordPress admin reachable, plugin activated, `wp-json/securepress/v1/frameworks` returns JSON |
| M2 | Full data seed | All frameworks + threats + mitigations in DB; API returns correct counts |
| M3 | All six card decks ingested | `Integrity_Verifier` reports `is_valid = 1` for all six YAML files, including `dbd-cards-1.0-en.yaml`; every card has a curated `card_kind` |
| M3.5 | `CHECK` constraint verified | A direct SQL `INSERT` attempting `card_kind='design_harm', severity='high'` confirmed to fail at the MySQL layer in an automated test |
| M4 | Code samples complete | Every mitigation has 5 language samples visible on Threat Detail |
| M5 | Matrix + heatmap | Cross-reference table renders; STRIDE heatmap shows coverage % |
| M6 | i18n complete | Visible PL⇄EN switch works via WordPress's native locale mechanism on every page; `.pot` drift check passes in CI |
| M7 | Search + export work | Full-text search returns highlighted results; CSV/PDF export completes via WP-Cron |
| M8 | Digital-by-Default Harms | `digital-harms.php` renders all 5 suits with a design-harm badge; A04:2021 cross-reference visible; no `severity` value ever returned for these cards, confirmed at both API and DB layer |
| M9 | Security hardening | PHPCS/WPCS + PHPStan + `composer audit` + WPScan scan zero HIGH; ZAP full scan zero HIGH; `xmlrpc.php` confirmed disabled |
| M10 | Tests green | ≥ 90% of TDD test list in `user_stories+tests.md` passing in CI |
