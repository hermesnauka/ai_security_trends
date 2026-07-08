---
type: entity
title: "SecurePress 2026 (app09_php_WORDPRESS)"
address: c-000024
entity_type: product
role: "Security-education WordPress plugin (PHP, no SPA)"
first_mentioned: "[[OWASP Security Course App Series]]"
created: 2026-07-07
updated: 2026-07-07
tags:
  - entity
  - product
  - security
  - ai-security
status: current
related:
  - "[[Security Course App Stack Comparison]]"
  - "[[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]]"
sources:
  - "[[OWASP Security Course App Series]]"
---

# SecurePress 2026 (app09_php_WORDPRESS)

Planning-only security-education app built as a self-contained WordPress 6.8+ plugin: PHP 8.3, vanilla JavaScript (ES2022, no frontend framework), MySQL 8.0 via custom `$wpdb` tables (not Custom Post Types), WordPress REST API + native nonces/capabilities for CSRF/auth, `symfony/yaml`. The first sibling in the series that isn't a custom-built backend at all — it inherits WordPress's attack surface (missing REST `permission_callback`s, XML-RPC abuse, `wp-login.php` credential stuffing) and its mature security tooling (WPScan SCA, native i18n) rather than reinventing them.

## Key Decisions

- Custom `$wpdb` tables + `dbDelta()` — relational filtering (threat × framework × severity × STRIDE) doesn't fit CPT/postmeta
- `$wpdb->prepare()` everywhere, backstopped by the WPCS `WordPress.DB.PreparedSQL` sniff (PHP has no compile-time SQL check equivalent to sqlc/sqlx)
- `Integrity_Verifier::verify()` isolation enforced only by code organization + a custom PHPStan rule — no process/compiler boundary, named the series' weakest isolation mechanism
- WordPress native gettext i18n (PL/EN) instead of a bespoke toggle
- `CornucopiaCard` rows have zero write-capable code paths at all, not just permission-gated

## CardKind Pattern

**Present, database-enforced** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 2, arguably the strongest guarantee in the whole series in its narrow scope. The `sp_cards` table has `card_kind ENUM('technical_threat','design_harm')` and `severity ENUM(...) NULL`, with:

```sql
CONSTRAINT chk_design_harm_has_no_severity
    CHECK (
        (card_kind = 'design_harm'      AND severity IS NULL) OR
        (card_kind = 'technical_threat' AND severity IS NOT NULL)
    )
```

MySQL 8.0.16+ rejects any violating INSERT/UPDATE regardless of code path — REST handler, wp-cli, or an ingestion bug. Verified by a direct-INSERT-bypass test that deliberately skips PHP entirely.

## Testing & Tooling

PHPUnit + `WP_UnitTestCase` + eris (property-based) + wp-browser/Codeception (acceptance) + Playwright (E2E). SAST: PHPCS/WPCS + PHPStan (custom `NoIntegrityVerifierInRestApi` rule). SCA: composer audit + roave/security-advisories + **WPScan** (WordPress-specific vulnerability database).

## Architecture

No React/Vue SPA — server-rendered PHP Template Hierarchy progressively enhanced with vanilla JS (works with JS disabled). No separate worker process — WP-Cron runs inside the same PHP-FPM request lifecycle. WordPress's own auth/session/nonce system replaces the custom JWT+RBAC layer every other sibling uses.
