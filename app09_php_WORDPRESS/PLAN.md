# SecurePress 2026 — Application Development Plan

**Version:** 1.0
**Date:** 2026-07-07
**Status:** Living document — updated after each sprint planning session
**Directory:** `app09_php_WORDPRESS`
**Sibling projects:** `app01_react`/`app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django), `app04_scala_react` (Scala/ZIO), `app05_go_react` (Go), `app06_HASKELL_react` (Haskell), `app07_rust_react` (Rust), `app08_cpp_react` (C++)

---

## 0. Note on the Stack — and Why This Plan Looks Different From Every Sibling So Far

This application is built **entirely on WordPress**, using **PHP 8.3** and **vanilla JavaScript** (plus MySQL 8, "if needed" per the brief — and it is needed, since WordPress requires a MySQL/MariaDB database by design). It is the eighth backend/platform choice in this course's comparison series, and the first that is not a custom-built backend at all: it is a **plugin for an existing, enormously widely-deployed CMS platform**, and that changes what "secure by design" means in a way none of `app01_react` through `app08_cpp_react` had to address.

**Three structural differences from every prior sibling, stated up front:**

1. **No custom React SPA frontend.** The user's brief specifies PHP and JavaScript for this app, and WordPress's own idiomatic pattern is server-rendered PHP templates (the WordPress *Template Hierarchy*) progressively enhanced with vanilla JavaScript calling the WordPress REST API — not a client-side single-page application. This plan follows that idiom deliberately rather than bolting a React SPA onto WordPress (which is possible, and is exactly how the Gutenberg block editor itself works, but would be an unusual choice for the public-facing browsing experience this app needs, and is not what was asked for). §8 describes this in full.
2. **The application inherits an enormous, pre-existing attack surface and an equally enormous, pre-existing security tooling ecosystem.** WordPress powers a large fraction of the web and has a correspondingly long, well-documented history of vulnerability classes (plugin/theme supply-chain CVEs, missing REST API `permission_callback`s, unescaped output, unprepared SQL, XML-RPC amplification abuse, credential stuffing against `wp-login.php`). This plan does not pretend those risks are hypothetical — it treats WordPress's own hardening guidance (the WordPress Security Whitepaper, the Plugin Handbook's security section) as a primary source alongside OWASP, and cites the WPScan vulnerability database as this project's WordPress-specific Software Composition Analysis (SCA) source, in addition to the SCA every sibling app already does for its own dependencies (§2, §13).
3. **Several security guarantees other apps got from their language's compiler are, here, either weaker (no compile-time SQL shape checking at all — PHP has no such mechanism, full stop, not even the template-metaprogramming approximation `app08_cpp_react`'s `sqlpp11` provides) or, in one specific and interesting case, *stronger* than any sibling's: the Digital-by-Default Harms deck's "cannot carry a severity" guarantee is enforced by a **MySQL `CHECK` constraint at the schema level** (§4 D-04) — a guarantee that holds even against a raw SQL query run outside the application entirely, which no compiler-level guarantee in any prior sibling can claim, since all of those depend on going through the application's own type-checked code paths.**

**Note on code samples:** the application still *teaches* countermeasures in five languages — Python, Java, Go, Scala, and Lua (see §10) — because that is separate, deliberately polyglot **content**, not the application's own runtime. None of those five languages is the application's implementation language; the application itself is PHP, JavaScript, and SQL only, running on WordPress.

---

## 1. Project Overview

**Name:** SecurePress 2026
**Form factor:** A single, self-contained WordPress plugin (`securepress-2026`) — deliberately **not** split across a plugin and a theme, so the application's functionality does not depend on which theme is active (a WordPress-specific application of least-coupling, discussed in `SDLC_analysis.md` Phase 2).
**Purpose:** A bilingual (Polish/English) reference and learning platform mapping security threats, vulnerabilities and mitigations across **OWASP** (Web Top 10, LLM Top 10, Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, Automated Threats/OAT, MASVS), **MITRE ATLAS**, and **CompTIA Security+ SY0-701 / SecAI+ 2026**, plus the full catalogue of **OWASP Cornucopia-family card decks** found in `docs/OWASP_stories/*.yaml`. Each threat is presented with working countermeasure code in **five languages**: Python, Java, Go, Scala, and Lua.

**Source material:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md` and all six card decks under `docs/OWASP_stories/`:

| File | Edition | Suits |
|---|---|---|
| `webapp-cards-3.0-en.yaml` | OWASP Cornucopia — Website App v3.0 | VE, AT, SM, AZ, CR, C, WC |
| `mobileapp-cards-1.1-en.yaml` | OWASP Cornucopia — Mobile App v1.1 | PC, AA, NS, RS, CRM, CM, WC |
| `__LLM_AI___companion-cards-1.0-en.yaml` | OWASP Cornucopia — Companion (AI/Cloud/DevOps) v1.0 | LLM, CLD, FRE, DVO, BOT, AAI, Common |
| `STRIDE__eop-cards-5.0-en.yaml` | Microsoft "Elevation of Privilege" (STRIDE) v5.0 | SP, TA, RE, ID, DS, EP |
| `RISKS__elevation-of-mlsec-cards-1.0-en.yaml` | "Elevation of MLSec" v1.0 | EMR, EIR, EOR, EDR |
| `dbd-cards-1.0-en.yaml` | Digital-by-Default Harms Deck v1.0 | SCO, ARC, AGE, TRU, POR, COR, WC |

All six decks are in scope from day one of this plan (§11, §15) — the gap the `app04_scala_react` plan initially had (and was later corrected for) is avoided here from the start, as it was for every subsequent sibling.

**UI languages:** Polish (default) and English, switched via WordPress's own multilingual mechanism — this app does **not** need a bespoke `localStorage`-keyed toggle the way every custom-built sibling did, because WordPress's native i18n system (§4 D-05) already solves locale switching at the platform level; this plan uses it rather than reinventing it.

---

## 2. Technology Stack

### Platform & Backend
| Layer | Technology | Version (2026) |
|---|---|---|
| CMS platform | WordPress | 6.8+ |
| Language | PHP | 8.3 |
| Database | MySQL | 8.0+ (MariaDB 10.11+ also supported) — required by WordPress itself, and used directly by this plugin for its own custom tables |
| Data access | `$wpdb` with `$wpdb->prepare()` for every parameterized query — WordPress's native, and only, DB abstraction | — |
| Custom data storage | Custom database tables (via `dbDelta()` in the activation hook) rather than Custom Post Types + postmeta — chosen because the relational filtering this app needs (threats by framework × severity × STRIDE × tag simultaneously, cross-references, per-language code samples) does not fit postmeta's key-value/serialized-blob model efficiently (§5) | — |
| API layer | WordPress REST API (`register_rest_route`, namespace `securepress/v1`), every route with an explicit `permission_callback` | — |
| Background jobs | WP-Cron (`wp_schedule_event`), backed by a real system crontab entry (`DISABLE_WP_CRON` set, cron triggered externally) rather than WordPress's default page-view-triggered pseudo-cron, for reliability on a low-traffic educational site | — |
| Cache / rate-limit store | WordPress Transients API (`get_transient`/`set_transient`), backed by a persistent object cache (Redis via a standard object-cache drop-in) rather than the `wp_options` table default, for atomicity under concurrent requests | — |
| Auth | WordPress's own user/role/capability system (`current_user_can()`); no separate JWT layer — admin/editor content management reuses `wp-admin` logins directly, which is the WordPress-idiomatic choice this plan makes deliberately rather than reimplementing auth | — |
| CSRF protection | WordPress nonces (`wp_nonce_field`, `check_ajax_referer`, `wp_verify_nonce`, and the REST API's own `X-WP-Nonce` header mechanism) | — |
| Output escaping | WordPress's contextual escaping API family: `esc_html()`, `esc_attr()`, `esc_url()`, `esc_js()`, and `wp_kses()`/`wp_kses_post()` for the small HTML allow-list needed in mitigation descriptions | — |
| YAML parsing | `symfony/yaml` (Composer) — chosen specifically because, unlike some YAML libraries in other ecosystems, it does not support arbitrary object instantiation from tags by default, so it does not carry the same historical deserialization-gadget risk class (§4 D-08) | — |
| Password hashing | WordPress core's own hashing (`wp_hash_password`, now Argon2i/Argon2id-backed as of WP 6.8's password-hashing overhaul) — not reimplemented by this plugin | — |
| Dependency management | Composer, with `roave/security-advisories` included to make known-vulnerable package combinations fail `composer install` outright | — |
| i18n | WordPress's native gettext-based system: `__()`, `_e()`, `esc_html__()`, `.pot`/`.po`/`.mo` files, loaded via `load_plugin_textdomain()` | — |
| Structured logging | Monolog (Composer), writing to a dedicated log channel outside the web root | — |
| Testing | PHPUnit + `WP_UnitTestCase` (via `wp-env`/`wp-phpunit`), `eris` (property-based testing for PHP, this ecosystem's QuickCheck/`proptest`/`RapidCheck` equivalent), `wp-browser`/Codeception for WordPress-aware integration tests | TDD — see `user_stories+tests.md` |
| SAST | PHP_CodeSniffer with the **WordPress Coding Standards (WPCS)** ruleset, whose `WordPress.Security.*` and `WordPress.DB.PreparedSQL` sniffs are purpose-built for exactly this ecosystem's historical vulnerability classes; PHPStan (static type analysis, gradual typing via PHPDoc) | — |
| SCA | `composer audit` + `roave/security-advisories` (PHP-package-level) **and** the **WPScan vulnerability database** (WordPress-plugin/theme/core-specific — a source with no equivalent need in any custom-backend sibling, since none of them run on top of a platform with its own CVE feed) | — |

### Frontend (deliberately PHP-rendered + vanilla JS, not React)
| Layer | Technology |
|---|---|
| Rendering | WordPress Template Hierarchy — PHP templates (`archive-threat.php`, `single-threat.php`, taxonomy/suit archive templates) registered by the plugin via `template_include` |
| Client-side enhancement | Vanilla JavaScript (ES2022), no framework — filter panels, tab switching, and the language toggle are implemented as small, dependency-free JS modules enqueued via `wp_enqueue_script()` |
| API calls from JS | `window.fetch` against the REST API (`securepress/v1`), authenticated read-only public calls need no nonce; state-changing admin calls include `wp_rest_nonce` |
| Styling | Plain CSS (custom properties for theming), enqueued via `wp_enqueue_style()` — no build step required, though a minimal esbuild/Vite step is used only to bundle/minify the vanilla JS modules for production |
| Syntax highlight | Prism.js (self-hosted, not CDN-loaded, consistent with every sibling's no-external-CDN constraint) |
| I18n on the client | Strings needed in JS are localized via `wp_localize_script()`/`wp_set_script_translations()` — again, WordPress's own mechanism, not a bespoke JSON file |

### Infrastructure
| Component | Technology |
|---|---|
| Web/PHP runtime | Nginx + PHP-FPM (or Apache + `mod_php`), Docker Compose for local/staging parity |
| Container | Docker Compose: `wordpress` (PHP-FPM) + `mysql` + `redis` (object cache) + `nginx` |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Loki + Prometheus (`php-fpm_exporter`, `mysqld_exporter`) |
| Secrets | `wp-config.php` constants sourced from environment variables / Docker secrets — never committed |
| SAST | PHPCS/WPCS + PHPStan + `eslint-plugin-security` (the small amount of vanilla JS) |
| DAST | OWASP ZAP |
| SCA | `composer audit` + `roave/security-advisories` + WPScan CLI/API + `npm audit` (build tooling only) + Trivy (containers) |

---

## 3. High-Level Architecture

```
Browser (PHP-rendered pages, vanilla JS enhancement, PL/EN via WP locale)
        │
        │  HTTPS
        ▼
  Nginx (port 443) → PHP-FPM
   ├── WordPress core bootstrap (wp-load.php)
   │     └── securepress-2026 plugin
   │           ├── includes/rest-api/           — register_rest_route handlers, securepress/v1
   │           ├── includes/templates/           — archive-threat.php, single-threat.php, etc.
   │           │                                    (registered via template_include)
   │           ├── includes/service/              — business logic, framework-agnostic of WP hooks
   │           ├── includes/data/                 — $wpdb table access, all queries via prepare()
   │           ├── includes/integrity/              — YAML hash verification (a class whose
   │           │                                       verify() method is called ONLY from the
   │           │                                       activation hook and the WP-Cron job — never
   │           │                                       from a REST route handler; enforced by code
   │           │                                       review + a static-analysis rule, see D-03)
   │           ├── includes/cron/                  — wp_schedule_event handlers (export, re-ingest,
   │           │                                       periodic integrity re-check)
   │           └── includes/admin/                  — wp-admin settings page, integrity status dashboard
   │
   └── /wp-json/securepress/v1/*  — the only HTTP surface JS on the page talks to directly

MySQL 8      ◄── $wpdb, prepared statements only (custom tables: threats, cards, mitigations,
                  code_samples, cross_references, content_hashes, threat_translations)
Redis        ◄── WordPress object cache (transients-backed rate limiting, response caching)
```

**Where the trust boundaries are, and how they compare to a custom-backend sibling's:** there is no separate `worker` process in this architecture — WP-Cron jobs run *inside* the same PHP-FPM request lifecycle (a visit triggers due cron jobs, or, per this plan's NFR-05.4, a real system cron hits `wp-cron.php` directly on a schedule). This means the "only the worker can call `integrity::verify`" boundary every custom-backend sibling enforced with a **separate compiled binary** is, here, enforced entirely by **code organization and review** within a single PHP process — no process boundary exists to fall back on at all. This is a materially weaker isolation guarantee than any sibling from `app05_go_react` onward, and this plan states that directly rather than implying parity (§4 D-03, §13).

---

## 4. Architecture Design Decisions

### D-01 — Custom `$wpdb` tables instead of Custom Post Types, with `dbDelta()`-managed schema
`CornucopiaCard`, `Threat`, `Mitigation`, `CodeSample`, `CrossReference`, `ContentHash`, and `ThreatTranslation` are each a dedicated table created by the plugin's activation hook via `dbDelta()`. This is the WordPress-recommended pattern for structured, relationally-queried data that does not fit the CPT+postmeta model efficiently — the same category of decision `app05_go_react` made choosing `sqlc` over an ORM, expressed here in WordPress's own idiom rather than a general-purpose one.

### D-02 — `$wpdb->prepare()` on every query — a runtime-only guarantee, and this plan says so
```php
$threats = $wpdb->get_results(
    $wpdb->prepare(
        "SELECT * FROM {$wpdb->prefix}sp_threats WHERE framework_code = %s AND severity = %s",
        $framework_code,
        $severity
    )
);
```
Every custom query in this plugin uses `$wpdb->prepare()`'s `%s`/`%d`/`%f` placeholders — never string interpolation of untrusted input into SQL. **Unlike `app05_go_react`'s `sqlc`, `app06_HASKELL_react`'s `hasql-th`, or `app07_rust_react`'s `sqlx::query!`, this gives no compile-time guarantee at all** — PHP has no macro or type system capable of checking a query's shape against the schema before it runs. The WPCS `WordPress.DB.PreparedSQL` sniff (SAST, §2) is this project's closest available substitute: a linter rule that flags likely-unprepared query construction, catching the same *pattern* `app08_cpp_react`'s CI grep catches for C++, with the same category of limitation (pattern-matching, not schema-verification).

### D-03 — `Integrity_Verifier::verify()` isolation is enforced by code organization and review, not a process or compiler boundary
`includes/integrity/class-integrity-verifier.php` exposes a single public method, called only from the plugin's activation hook and from `includes/cron/class-periodic-reverify-job.php`. No REST route handler under `includes/rest-api/` calls it, and a custom PHPStan rule (`SecurePress\PHPStan\NoIntegrityVerifierInRestApi`) fails static analysis if a class under the `RestApi` namespace references `Integrity_Verifier`. This is the same *intent* as every prior sibling's isolation mechanism, implemented with the **weakest** tooling in the series so far: no compiler, no separate OS process (§3) — a static-analysis rule plus code review is the entire enforcement stack, and this is named explicitly as this project's largest structural risk (§13).

### D-04 — A MySQL `CHECK` constraint enforces the Digital-by-Default Harms deck's "no severity" rule — arguably the strongest version of this guarantee in the whole series
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
MySQL 8.0.16+ *enforces* `CHECK` constraints (earlier versions silently ignored them — this plan requires 8.0.16+ specifically for this reason, stated in §2). An `INSERT`/`UPDATE` violating this constraint is rejected **by the database engine itself**, regardless of which code path attempts it — a raw query run from `wp-cli`, a bug in a future REST handler, or a mistake in the YAML ingestion code would all be rejected identically. This is a genuinely different, and in one specific sense *stronger*, guarantee than any prior sibling's: `app07_rust_react`'s `#![forbid(unsafe_code)]` and `app06_HASKELL_react`'s sum type both depend on the *application's own code* being the only path to the data; a DB-level `CHECK` constraint holds even if the application layer is bypassed entirely. It is narrower in scope (it only enforces this one invariant, not general memory safety or general type correctness), and this plan is explicit about that scope rather than overstating it.

### D-05 — WordPress's native i18n system — the most mature i18n infrastructure in this entire series, used as-is rather than reinvented
```php
// PHP
esc_html_e( 'Threat Catalogue', 'securepress-2026' );

// JS (after wp_set_script_translations())
__( 'Threat Catalogue', 'securepress-2026' );
```
Every prior sibling built its own PL/EN switch — a `localStorage` key, a `LocaleMiddleware`, an `Accept-Language` allowlist, a `.po`/`.json` translation-file pipeline it had to design from scratch. This app instead uses WordPress core's own gettext-based i18n system, in continuous production use across hundreds of thousands of plugins and themes for two decades, with its own translation-management ecosystem (`translate.wordpress.org`, `.pot` file generation via `wp i18n make-pot`). This plan treats "use the platform's mature, battle-tested mechanism instead of building a bespoke one" as the correct engineering choice here, in the same spirit that every prior sibling chose its own language's most mature available tool for its own analogous problem.

### D-06 — Nonces for CSRF, capabilities for authorization — WordPress's native equivalents to JWT + RBAC
Every state-changing admin action (editing a `Threat`, re-running integrity verification from the dashboard) requires a valid WordPress nonce (`wp_verify_nonce()` server-side, `X-WP-Nonce` header for REST calls) and a capability check (`current_user_can( 'manage_securepress' )`, a custom capability granted only to the `administrator` and a new `securepress_editor` role this plugin registers). There is no separate JWT-based auth layer, unlike every prior sibling — WordPress's session-cookie-plus-nonce model is the platform-native mechanism, and reimplementing JWT auth alongside it would add an unnecessary second authentication system rather than a security improvement.

### D-07 — `CornucopiaCard` rows are never writable through any REST route or admin UI form
The plugin registers **zero** REST routes and **zero** wp-admin edit screens capable of writing to the `sp_cards` table. The only code paths that write it are the activation hook's initial ingestion and the periodic re-ingestion Cron job (§4 D-03). Unlike a capability check (which could, in principle, be granted to more users over time), this is enforced by **the absence of any write-capable code at all** — the same category of guarantee `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react` achieve via their router's type system having no such route, here achieved by simply never writing that code, verified by code review and a "grep for `INSERT`/`UPDATE` against `sp_cards` outside `includes/integrity` and `includes/cron`" CI check.

### D-08 — `symfony/yaml` for YAML parsing — no arbitrary-object gadget class by default, stated the same way as every sibling's equivalent note
`symfony/yaml`'s `Yaml::parse()` does not construct arbitrary PHP objects from YAML tags unless explicitly configured to do so via `Yaml::PARSE_CUSTOM_TAGS` or object-support flags this plugin never enables. As with `app05_go_react`'s D-09, `app06_HASKELL_react`'s D-07, `app07_rust_react`'s D-09, and `app08_cpp_react`'s D-03, this plan states plainly that this removes a specific vulnerability *class* — it does not imply the YAML *content* is trusted; SHA-256 integrity verification (D-03) still applies unconditionally. Decoded data is additionally validated field-by-field against an explicit allow-list of expected keys before being written to the database (PHP has no derive-macro or strict-decode-by-default mechanism, so — like `app08_cpp_react` — this allow-list check is hand-written and covered by an `eris` property test, not compiler-enforced).

### D-09 — Rate limiting via the Transients API backed by Redis
```php
$key = 'sp_ratelimit_' . md5( $ip_address );
$count = (int) get_transient( $key );
if ( $count >= 60 ) {
    return new WP_Error( 'rate_limited', __( 'Too many requests', 'securepress-2026' ), array( 'status' => 429 ) );
}
set_transient( $key, $count + 1, MINUTE_IN_SECONDS );
```
With a persistent Redis-backed object cache, WordPress's Transients API provides atomic `INCR`-equivalent behavior suitable for this purpose (the default DB-table-backed transient storage does not, and is explicitly not used for this reason — a distinction this plan states rather than leaving implicit).

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
    stride         VARCHAR(6)   NOT NULL DEFAULT '', -- e.g. "SI" for combined Spoof+InfoDisclosure
    tags           TEXT NOT NULL DEFAULT '[]',       -- JSON array (MySQL 8 native JSON type)
    FOREIGN KEY (framework_id) REFERENCES {$wpdb->prefix}sp_frameworks(id)
) ENGINE=InnoDB;

-- {$wpdb->prefix}sp_threat_translations  (i18n for threat CONTENT — distinct from D-05's UI i18n)
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

-- {$wpdb->prefix}sp_cards  (all six YAML decks — see D-04 for the CHECK constraint)
CREATE TABLE {$wpdb->prefix}sp_cards (
    card_id           VARCHAR(10)  NOT NULL PRIMARY KEY,   -- "VE3", "LLM4", "SPX", "EMR2", "SCO2"
    suit_code         VARCHAR(10)  NOT NULL,
    suit_name         VARCHAR(100) NOT NULL,
    edition           VARCHAR(20)  NOT NULL,                -- webapp, mobileapp, companion, eop, mlsec, dbd
    card_value        VARCHAR(2)   NOT NULL,                 -- "2".."10","J","Q","K","A"
    is_critical       TINYINT(1)   NOT NULL DEFAULT 0,
    card_kind         ENUM('technical_threat','design_harm') NOT NULL,
    severity          ENUM('critical','high','medium','low','info') NULL,
    description_en    TEXT NOT NULL,
    description_pl    TEXT NOT NULL,
    misc_note         TEXT NULL,
    source_url        VARCHAR(500) NULL,
    owasp_refs        JSON NOT NULL,
    mitre_refs        JSON NOT NULL,
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
```

All tables use the `{$wpdb->prefix}` prefix (respecting a site's configured table prefix, standard WordPress practice) and `InnoDB` (required for foreign keys and `CHECK` constraint enforcement).

---

## 6. Development Phases

*(Numbering aligned with the Agile/Scrum sprint plan in `SDLC_analysis.md`, §4.)*

### Phase 1 — Foundation (Sprints 1–2)
Covers: US-01, US-02
- [ ] Plugin scaffold (`securepress-2026.php` header, `includes/` PSR-4 autoloaded classes via Composer)
- [ ] Activation hook: `dbDelta()` creates all tables in §5.1
- [ ] Docker Compose: WordPress (PHP-FPM) + MySQL 8 + Redis + Nginx, `wp-env` for local dev parity with CI
- [ ] Seed routine (triggered from the activation hook, idempotent) loading OWASP Web/LLM/Agentic/API, MITRE ATLAS, CompTIA SecAI+ from JSON
- [ ] `GET /wp-json/securepress/v1/frameworks`, `GET /wp-json/securepress/v1/threats` (paginated), both with public `permission_callback` returning `true` (read-only, no auth needed) — **explicitly set**, since an *omitted* `permission_callback` is itself a well-known WordPress REST API vulnerability class this plan calls out (`SDLC_analysis.md` Phase 1)
- [ ] `securepress_editor` custom role + `manage_securepress` capability registered
- [ ] Base PHP templates: `archive-threat.php`, `single-threat.php`, registered via `template_include`
- [ ] Vanilla JS module bootstrap (`assets/js/threat-browser.js`) enqueued via `wp_enqueue_script()`

**Security checkpoint:** PHPCS/WPCS run with zero `WordPress.Security.*`/`WordPress.DB.PreparedSQL` findings; every registered REST route has an explicit `permission_callback`.

### Phase 2 — Core Threat Browser (Sprints 3–4)
Covers: US-02, US-03, US-04
- [ ] `$wpdb->prepare()`-based filtering: framework, severity, stride, category, tag, q
- [ ] `GET /wp-json/securepress/v1/threats/{id}` with nested mitigations + code samples
- [ ] PHP templates render server-side; vanilla JS enhances the filter panel via `fetch()` against the same REST routes (progressive enhancement — the PHP-rendered page works with JavaScript disabled, a deliberate accessibility/resilience property no prior sibling's SPA architecture had)
- [ ] `GET /wp-json/securepress/v1/cross-references`
- [ ] `/matrix/` page template

**Security checkpoint:** WPCS `WordPress.DB.PreparedSQL` sniff passes on every new query; a manual review confirms the page is fully usable with JavaScript disabled (progressive-enhancement acceptance criterion, unique to this app in the series).

### Phase 3 — Card Decks & Content Integrity (Sprints 5–7)
Covers: US-05–US-12, US-19
- [ ] `includes/cards/class-card-loader.php` — `symfony/yaml` decode + explicit allow-list key validation for **all six** `docs/OWASP_stories/*.yaml` files
- [ ] `Integrity_Verifier::verify()` — SHA-256 vs `data/hashes.json`; called only from activation + Cron (D-03)
- [ ] Card suit archive templates: FRE, LLM, AAI, CLD (Companion), SP/TA/RE/ID/DS/EP (STRIDE), EMR/EIR/EOR/EDR (MLSec), PC/AA/NS/RS/CRM/CM (Mobile), VE/AT/SM/AZ/CR/C (Website App), **SCO/ARC/AGE/TRU/POR (Digital-by-Default Harms, US-19 — in scope here, not bolted on later)**
- [ ] `chk_design_harm_has_no_severity` `CHECK` constraint (D-04) verified with an explicit failing-insert test
- [ ] `AttackDemoWarning` confirmation dialog (vanilla JS `<dialog>` element) before rendering `attack_demo` code samples

**Security checkpoint:** malformed/unknown-field YAML is rejected before any DB write (an `eris` property generates random extra keys and asserts rejection); content hash mismatch aborts ingestion inside a single `$wpdb` transaction; a direct SQL `INSERT` attempting to violate the `CHECK` constraint is confirmed to fail at the database layer, independent of PHP code.

### Phase 4 — Code Samples: 5 Languages (Sprints 7–9)
Covers: US-13–US-16
- [ ] Code sample seed data for every mitigation × 5 languages (Python, Java, Go, Scala, Lua)
- [ ] Attack-demo / defense sub-tabs (vanilla JS tab switcher), red-bordered warning label
- [ ] MITRE ATLAS Kill-Chain timeline (a small vanilla-JS/SVG rendering, no charting framework dependency)

### Phase 5 — i18n Polish ↔ English (Sprint 9–10)
Covers: US-11 (folded into every story's acceptance criteria, see §15 note)
- [ ] `.pot` file generated via `wp i18n make-pot`; `.po`/`.mo` for `pl_PL` and `en_US` committed
- [ ] `load_plugin_textdomain()` wired to the site's active WordPress locale (`switch_to_locale()`-aware for logged-in-user language preference, and a front-end language switcher using WPML-style or a lightweight custom `?lang=` query-var approach, documented in `requirements.md` FR-18)
- [ ] `sp_threat_translations` served per-locale for threat *content* (distinct from D-05's UI-string i18n)
- [ ] Code samples **never** translated
- [ ] CI check: `wp i18n make-pot --skip-audit` diff against committed `.pot` fails the build on drift (this project's equivalent of every sibling's i18n key-parity check)

### Phase 6 — Search, Export, Matrix Completion (Sprints 10–12)
Covers: US-17, US-18
- [ ] MySQL `FULLTEXT` index on `sp_threats`/`sp_cards` description columns; `MATCH...AGAINST` queries via `$wpdb->prepare()`
- [ ] WP-Cron job (`securepress_export_job`) generating CSV/PDF exports, polled via a REST status route
- [ ] `/matrix/llm/`, `/matrix/agentic/`, `/matrix/mobile-vs-web/`, `/stride-heatmap/`, `/matrix/digital-harms/` templates
- [ ] Transients-based rate limiting (D-09): 60 req/min/IP on all public list routes

### Phase 7 — Hardening, Testing & Release (Sprints 12–14)
Covers: full regression across US-01–US-19
- [ ] PHPUnit + `WP_UnitTestCase` suite, `eris` properties, coverage ≥ 85% on `includes/service`
- [ ] `wp-browser`/Codeception integration tests against a real WordPress + MySQL instance
- [ ] Playwright (TypeScript) E2E — one scenario per user story, run against the PHP-rendered pages
- [ ] PHPCS/WPCS + PHPStan + `composer audit` + WPScan CLI scan in CI, zero HIGH findings
- [ ] OWASP ZAP full active scan against staging
- [ ] Production: WordPress core, this plugin, and all Composer dependencies pinned and updated via a controlled release process — **not** WordPress's default auto-update-everything posture, given this plugin's custom DB schema needs migration coordination

---

## 7. API Endpoint Map

### Framework & Threat (base) — namespace `securepress/v1`
```
GET  /wp-json/securepress/v1/frameworks
GET  /wp-json/securepress/v1/frameworks/{code}
GET  /wp-json/securepress/v1/threats?framework=&severity=&stride=&category=&tag=&q=
GET  /wp-json/securepress/v1/threats/{id}
GET  /wp-json/securepress/v1/threats/{id}/mitigations
GET  /wp-json/securepress/v1/threats/{id}/code-samples?language=go
```

### Cornucopia Card Suits (US-05–US-12, US-19)
```
GET  /wp-json/securepress/v1/threats?suit=fre                   — Frontend cards (US-05)
GET  /wp-json/securepress/v1/threats?suit=llm                   — LLM cards (US-06)
GET  /wp-json/securepress/v1/threats?suit=aai                   — Agentic AI cards (US-07)
GET  /wp-json/securepress/v1/threats?suit=cld                   — Cloud cards (US-07, folded into DevOps page)
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
```

### Matrix & Visualization
```
GET  /wp-json/securepress/v1/matrix/llm
GET  /wp-json/securepress/v1/matrix/agentic
GET  /wp-json/securepress/v1/matrix/mobile-vs-web
GET  /wp-json/securepress/v1/stride-heatmap        [nonce/capability-gated — see SR-01]
GET  /wp-json/securepress/v1/cross-references
GET  /wp-json/securepress/v1/cross-references?sourceCode=LLM01
```

### Search & Export
```
GET  /wp-json/securepress/v1/search?q=prompt+injection
GET  /wp-json/securepress/v1/export?format=csv&framework=OWASP_LLM   (enqueues a WP-Cron job, returns 202 + poll URL)
GET  /wp-json/securepress/v1/export/status/{jobId}
```

### Admin (wp-admin screens, capability-gated — NOT plain REST routes for content mutation)
```
wp-admin/admin.php?page=securepress-threats          — CRUD for Threat/Mitigation/CodeSample (manage_securepress)
wp-admin/admin.php?page=securepress-integrity         — integrity verification status dashboard (manage_securepress)
```
`CornucopiaCard` rows (all six decks) have **no** corresponding wp-admin edit screen and **no** REST write route (D-07) — the plugin simply contains no code capable of writing to `sp_cards` outside ingestion.

### Health & Ops
```
GET  /wp-json/securepress/v1/health
GET  /wp-json/securepress/v1/metrics                 [capability-gated]
GET  /wp-json/securepress/v1/integrity/status         [capability-gated] — last verification run per YAML file
```

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
  /about/                                    → a normal WordPress Page (editable via Gutenberg —
                                                 the only place in this app where the block editor's
                                                 own React-based UI is used, for ordinary CMS content,
                                                 not for the app's data-driven pages)

Vanilla JS modules (assets/js/, no framework, ES modules):
  threat-browser.js        — filter panel, debounced fetch() against /threats, result rendering
  code-sample-panel.js      — language tab switching, attack-demo confirmation <dialog>, copy-to-clipboard
  language-toggle.js        — reads/writes the site's locale query-var, re-fetches translated content
  stride-heatmap.js         — renders the heatmap from JSON (no charting library dependency)
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
│   ├── service/                        ← business logic, no direct $wpdb calls (delegates to data/)
│   ├── cards/
│   │   └── class-card-loader.php       ← symfony/yaml decode + allow-list validation (D-08)
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
│   ├── mitre_atlas.json
│   ├── comptia_secai.json
│   ├── cornucopia/
│   │   ├── webapp-cards-3.0-en.yaml
│   │   ├── companion-llm-cards-1.0-en.yaml
│   │   ├── mobileapp-cards-1.1-en.yaml
│   │   ├── stride-eop-cards-5.0-en.yaml
│   │   ├── mlsec-cards-1.0-en.yaml
│   │   ├── dbd-cards-1.0-en.yaml       ← Digital-by-Default Harms (US-19)
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

Every `Mitigation` ships exactly **five** `CodeSample` rows. Unlike `app07_rust_react` or `app06_HASKELL_react`, there is no type-level non-emptiness guarantee (PHP arrays have no such concept) — completeness is verified by an `eris` property over the seeded dataset and a CI seed-data linter, consistent with `app08_cpp_react`'s equivalent, runtime-only guarantee.

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

**A note on Java as a code-sample language versus WordPress's own PHP:** several code samples for injection-related mitigations pair naturally with a direct comparison to this very plugin's own `$wpdb->prepare()` usage (D-02) — the Threat Detail page's Code Samples tab, for the relevant threats, includes a callout linking to the plugin's own source as a sixth, implicit "PHP" example, without adding PHP as a seventh formal sample language (the brief specifies five: Python, Java, Go, Scala, Lua).

---

## 11. Security Data Coverage Plan

| Framework | Coverage target | Source |
|---|---|---|
| OWASP Web Top 10 (2021) | A01–A10, all 10 | seeded JSON, cross-refs to `VE/AT/SM/AZ/CR/C` cards |
| OWASP LLM Top 10 (2025) | LLM01–LLM10, all 10 | seeded JSON + `LLM` suit (Companion) |
| OWASP Agentic AI Top 10 (2026) | AgentAI01–10 | seeded JSON + `AAI` suit (Companion) |
| OWASP API Security Top 10 | API1–API10 | seeded JSON |
| OWASP Client-Side Top 10 | C01–C10 | `FRE` suit (Companion) |
| OWASP CI/CD Security Top 10 | CICD-SEC-01–10 | `DVO` suit (Companion) |
| OWASP Automated Threats (OAT) | ≥ 13 of 21 | `BOT` suit (Companion) |
| Cloud misconfiguration (A05/A01:2021) | — | `CLD` suit (Companion), no dedicated OWASP Top 10 of its own |
| OWASP MASVS 2.0 | all 7 categories | `PC/AA/NS/RS/CRM/CM` suits (Mobile) |
| STRIDE | S,T,R,I,D,E — all 6 | `SP/TA/RE/ID/DS/EP` suits (EoP v5.0) |
| Elevation of MLSec | Model/Input/Output/Dataset Risk | `EMR/EIR/EOR/EDR` suits |
| MITRE ATLAS | ≥ 15 techniques across ≥ 5 tactics | seeded JSON, cross-referenced from LLM/AAI/mlsec cards |
| CompTIA Security+ / SecAI+ | ≥ 20 topics, **explicitly including WordPress/CMS-specific threat classes** (plugin/theme supply-chain compromise, missing REST `permission_callback`, XML-RPC amplification abuse, `wp-login.php` credential stuffing) as a topic this app's own platform choice makes directly relevant | seeded JSON, from `docs/Security Architects...md` mapping table plus a WordPress-specific supplement |
| OWASP A04:2021 Insecure Design — Digital-by-Default Harms | Scope/Architecture/Agency/Trust/Porosity | `SCO/ARC/AGE/TRU/POR` suits (US-19) — **not** a technical-vulnerability deck, see D-04 |

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
└── translations/
    └── pl.cards.json

data/hashes.json                       ← SHA-256 per YAML file
data/mitre-atlas-allowlist.json
data/ref-allowlists.json
```

**Workflow:**
1. PR touching `data/cornucopia/*.yaml` → CODEOWNERS `@security-team`, min. 2 approvals.
2. CI job `yaml-content-integrity`: `symfony/yaml` parse + hand-written allow-list key validation (D-08) must succeed against every file + injection-pattern grep + ref-allowlist validation + an attempted `INSERT` against a scratch DB verifying the `CHECK` constraint (D-04) still rejects a malformed `card_kind`/`severity` combination.
3. Post-merge: a `hash-generator` CI step updates `data/hashes.json`.
4. The activation hook and `Periodic_Reverify_Job` both call `Integrity_Verifier::verify()` — on mismatch, ingestion aborts inside a single `$wpdb` transaction (no partial writes) and a `SEC-CARD-HASH-MISMATCH` log line fires via Monolog, which Loki alerts on.

---

## 13. Risk Register

*(Several entries here name a weaker enforcement mechanism than any custom-backend sibling had available — stated directly, not softened.)*

| Risk | Mitigation |
|---|---|
| SQL injection via a future query that skips `$wpdb->prepare()` | WPCS `WordPress.DB.PreparedSQL` sniff (pattern-based, not schema-verified — no PHP tooling gives the latter) + code review |
| `Integrity_Verifier::verify()` called from an unintended path | Custom PHPStan rule + code review — **no process boundary or compiler backstop exists at all**, the weakest version of this control in the series |
| A REST route registered without an explicit `permission_callback` | A well-known, historically real WordPress REST API vulnerability class; mitigated by a CI check grepping `register_rest_route` calls for a present `permission_callback` argument, plus mandatory code review |
| Digital-by-Default Harms deck misread as CVE severity | `chk_design_harm_has_no_severity` MySQL `CHECK` constraint (D-04) — **enforced independent of application code**, the one place this project's guarantee is stronger, not weaker, than a sibling's |
| Plugin/theme/core supply-chain compromise (the single most common real-world WordPress attack vector) | WPScan vulnerability database scan in CI + controlled, non-automatic updates with a staging-first rollout (`SDLC_analysis.md` Phase 6) |
| `wp-login.php` credential stuffing | Rate limiting via the Transients API (D-09) applied to login attempts specifically, in addition to the REST API; a login-attempt-limiting mu-plugin as defense in depth |
| XML-RPC amplification/pingback abuse | `xmlrpc.php` disabled entirely via `add_filter( 'xmlrpc_enabled', '__return_false' )`, since this plugin has no legitimate use for it |
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

*(The Polish↔English language switch is folded into every story's acceptance criteria per FR-18 in `requirements.md` rather than numbered separately here — WordPress's native i18n mechanism, D-05, is used throughout.)*

---

## 16. Milestones & Acceptance Criteria

| Milestone | Deliverable | Done when |
|---|---|---|
| M1 | Working skeleton | `docker compose up` → WordPress admin reachable, plugin activated, `wp-json/securepress/v1/frameworks` returns JSON |
| M2 | Full data seed | All frameworks + threats + mitigations in DB; API returns correct counts |
| M3 | All six card decks ingested | `Integrity_Verifier` reports `is_valid = 1` for all six YAML files, including `dbd-cards-1.0-en.yaml` |
| M3.5 | `CHECK` constraint verified | A direct SQL `INSERT` attempting `card_kind='design_harm', severity='high'` is confirmed to fail at the MySQL layer in an automated test |
| M4 | Code samples complete | Every mitigation has 5 language samples visible on Threat Detail |
| M5 | Matrix + heatmap | Cross-reference table renders; STRIDE heatmap shows coverage % |
| M6 | i18n complete | PL/EN switch works via WordPress's native locale mechanism everywhere; `.pot` drift check passes in CI |
| M7 | Search + export work | Full-text search returns highlighted results; CSV/PDF export completes via WP-Cron |
| M8 | Digital-by-Default Harms | `digital-harms.php` template renders all 5 suits with a design-harm badge; A04:2021 cross-reference visible; no `severity` value ever returned for these cards, confirmed at both the API and DB layer |
| M9 | Security hardening | PHPCS/WPCS + PHPStan + `composer audit` + WPScan scan zero HIGH; ZAP full scan zero HIGH; `xmlrpc.php` confirmed disabled |
| M10 | Tests green | ≥ 90% of TDD test list in `user_stories+tests.md` passing in CI |
