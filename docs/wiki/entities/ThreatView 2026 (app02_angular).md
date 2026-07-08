---
type: entity
title: "ThreatView 2026 (app02_angular)"
address: c-000017
entity_type: product
role: "Security-education web app (Java/Spring Boot + Angular)"
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
  - "[[SecureVision 2026 (app01_react)]]"
sources:
  - "[[OWASP Security Course App Series]]"
---

# ThreatView 2026 (app02_angular)

Planning-only security-education web app, explicitly framed as the "Angular sibling" to [[SecureVision 2026 (app01_react)]]: Java 21/Spring Boot 3.3 backend (Spring Security 6, Spring Data JPA), PostgreSQL 16 + Redis 7, Angular 18 (standalone components + Angular Material). Positioned as a full-stack Java/Spring reference implementation rather than a lightweight or serverless one, covering all five OWASP Cornucopia deck editions plus attack/defense code samples in five languages (Python, Java, Go, Scala, Lua) per threat.

## Key Decisions

- Angular strict mode + `strictTemplates`, eliminating unchecked `any`/unsanitized `[innerHTML]` at compile time
- `DomSanitizer` as the sole HTML rendering path — `bypassSecurityTrustHtml` forbidden via ESLint rule
- Stateless JWT (no sessions) — removes CSRF/session-fixation surface
- `ContentIntegrityVerifier` fail-secure at startup (SHA-256 mismatch stops the app booting)
- Server-side allowlist validators for every reference ID type (OWASP/MITRE/MASVS/CICD-SEC/OAT)

## CardKind Pattern

**Not present** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 8. `Threat` (severity enum) and `CornucopiaCard` (`isCritical: Boolean`, no severity field) are two independently modeled entities with no shared discriminating type or explicit guarantee.

## Testing & Tooling

JUnit 5 + Mockito + Testcontainers + JaCoCo (≥80% coverage); Jest + Angular Testing Library + MSW (frontend); Cypress + cypress-axe (E2E, WCAG 2.1 AA). SAST: SpotBugs + FindSecBugs + eslint-plugin-security. SCA: OWASP Dependency Check + npm audit + Trivy. DAST: OWASP ZAP full active scan.

## Architecture

Standard client-server web app — Angular SPA + Spring Boot REST API + PostgreSQL + Redis + Nginx, Docker Compose. Card content authored as version-controlled, integrity-verified YAML "security assets" rather than freely editable data.
