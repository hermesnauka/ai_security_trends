---
type: entity
title: "ScalaShield 2026 (app04_scala_react)"
address: c-000019
entity_type: product
role: "Security-education web app (Scala/ZIO + React)"
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

# ScalaShield 2026 (app04_scala_react)

Planning-only security-education app: Scala 3.3 LTS + ZIO 2 + ZIO HTTP + ZIO Quill (compile-time-checked SQL ORM), PostgreSQL 16, Redis 7, React 18 + TypeScript frontend. A purely functional, effect-typed backend (no bare try/catch, exhaustive `AppError` matching) that deliberately avoids "Java-branded" security libraries — a custom pure-Scala `SafeHtml` allowlist sanitizer instead of OWASP Java HTML Sanitizer, `jwt-scala` instead of `jjwt` — as an explicit stack-purity stance.

## Key Decisions

- ZIO effect system throughout: all side effects typed, exhaustive `AppError` matching, no silent failure
- ZIO Quill: macro-verified SQL queries, eliminating SQL injection at compile time
- `ContentIntegrityVerifier` as a `ZLayer` — SHA-256 mismatch triggers `ZIO.die`, server cannot start
- Opaque types (`ThreatCode`, `CardId`, `OwaspRef`, etc.) with allowlist smart constructors
- Rate limiting via ZIO STM token bucket (atomic, deadlock-free)

## CardKind Pattern

**Present, DTO-level field omission** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 6. The Digital-by-Default Harms deck (US-19) uses a `cardKind: "DESIGN_HARM"` field served via a separate `DigitalHarmsService` DTO omitting `severity` entirely, paired with a React `DesignHarmBadge` component that never shares props with `SeverityBadge` — verified by a dedicated Vitest test (AC-16), not a compile-time sum type or DB constraint.

## Testing & Tooling

ZIO Test + Testcontainers Scala; Vitest + RTL (frontend unit); Playwright + axe-playwright (E2E, WCAG 2.1 AA). SAST: Scalafix + Wartremover + Scapegoat + eslint-plugin-security. SCA: sbt-dependency-check + npm audit + Trivy. DAST: OWASP ZAP.

## Architecture

Standard client-server web app. YAML content pipeline is the system of record, gated by CODEOWNERS review, an ajv-schema + injection-grep CI job, and a bot-updated SHA-256 hash manifest; `ContentIntegrityVerifier` kills the app on any mismatch at boot.
