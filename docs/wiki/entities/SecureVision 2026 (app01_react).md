---
type: entity
title: "SecureVision 2026 (app01_react)"
address: c-000016
entity_type: product
role: "Security-education web app (Java/Spring Boot + React)"
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
  - "[[ThreatView 2026 (app02_angular)]]"
sources:
  - "[[OWASP Security Course App Series]]"
---

# SecureVision 2026 (app01_react)

Planning-only (no implementation code) security-education web app: Java 21/Spring Boot 3.3 (Spring Security 6, Spring Data JPA), PostgreSQL 16, Redis 7, React 18 + TypeScript frontend. The first app in the [[OWASP Security Course App Series]], and the only one framed explicitly as needing to avoid every vulnerability class it teaches ("an app teaching SQL injection defense that is itself SQL-injectable is not just ironic — it is dangerous"). Covers the full OWASP Cornucopia card catalogue (Web App, Companion LLM/AAI/FRE/DVO/BOT/CLD, Mobile, STRIDE EoP, MLSec editions) plus a SHA-256-hashed, CODEOWNERS-gated YAML content-integrity pipeline.

## Key Decisions

- Pagination on all list endpoints (DoS prevention)
- UUID (not sequential integer) IDs, preventing IDOR enumeration
- Separate read/write DB users (`sv_reader`/`sv_writer`) — least privilege if compromised
- JPA/JPQL only, no raw SQL, enforced by a CI grep check
- JWT stored in httpOnly cookie, not localStorage

## CardKind Pattern

**Not present** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 8. `Threat` always carries a severity enum; `CornucopiaCard` is a separate entity with no severity field at all, an incidental schema difference rather than an explicit guarantee.

## Testing & Tooling

JUnit 5 + Mockito + Testcontainers (backend); Vitest + RTL + MSW (frontend); Playwright (E2E). SAST: SpotBugs + FindSecBugs + SonarQube. SCA: OWASP Dependency Check + npm audit + Trivy. DAST: OWASP ZAP.

## Architecture

Standard client-server web app — React SPA + Spring Boot REST API + PostgreSQL + Redis behind Nginx, Docker Compose. No unusual departures beyond the security-hardened content-integrity pipeline. See [[ThreatView 2026 (app02_angular)]], its explicit Angular sibling with an otherwise near-identical backend.
