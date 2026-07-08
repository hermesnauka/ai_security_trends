---
type: source
title: "OWASP Security Course App Series"
address: c-000013
source_type: data
author: ""
date_published: 2026-07-07
url: ""
confidence: high
created: 2026-07-07
updated: 2026-07-07
tags:
  - source
  - security
  - ai-security
  - owasp
  - education
status: current
related:
  - "[[Security Course App Stack Comparison]]"
  - "[[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]]"
  - "[[OWASP LLM Top 10]]"
  - "[[MITRE ATLAS]]"
  - "[[CompTIA SecAI+]]"
  - "[[STRIDE Threat Modeling]]"
key_claims:
  - "12 planning-only sibling applications (no implementation code) each teach identical OWASP/MITRE ATLAS/CompTIA SecAI+ security content in a different implementation language/stack, with a Polish/English UI toggle."
  - "Each app's plan includes a recurring 'CardKind' design-decision case study — distinguishing technical-vulnerability cards (which carry a Severity) from design-harm cards (which structurally cannot) — implemented with a measurably different strength of guarantee per language (see the 8-tier ranking in the CardKind concept page)."
  - "Two apps (Swift/iOS, Kotlin/Android) depart completely from the client-server model used by the other ten, running fully on-device with no backend at all, and are explicitly designed as structural twins of each other."
  - "One app (C++) is deliberately framed as the memory-unsafe counter-example to its Rust sibling; one app (PHP/WordPress) departs from the React-SPA pattern entirely; one app (Python/Django) is a single-language monolith with no separate frontend framework."
sources:
  - ".raw/app01_react/*"
  - ".raw/app02_angular/*"
  - ".raw/app03_python_django/*"
  - ".raw/app04_scala_react/*"
  - ".raw/app05_go_react/*"
  - ".raw/app06_HASKELL_react/*"
  - ".raw/app07_rust_react/*"
  - ".raw/app08_cpp_react/*"
  - ".raw/app09_php_WORDPRESS/*"
  - ".raw/app10_csharp_react/*"
  - ".raw/app11_swift_ios/*"
  - ".raw/app12_kotlin_android/*"
  - ".raw/docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md"
---

# Source: OWASP Security Course App Series

**Type**: Batch of 12 planning-document sets (48 files total: `PLAN.md`, `requirements.md`, `user_stories+tests.md`, `SDLC_analysis.md` per app), produced for an "AI in Programming" course for experienced Java developers.
**Directories**: `.raw/app01_react/` through `.raw/app12_kotlin_android/`, plus a duplicate copy of an already-ingested source at `.raw/docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md` (identical SHA-256 hash to `.raw/Instrukcja do Gry Security Architects+ Comptia+OWASP LLM top10__v01b.md`, already covered by [[Security Architects Game and SecAI Threat Landscape]] — not re-ingested).

## Summary

Twelve sibling applications, each a **planning-only** exercise (PLAN.md + requirements.md + user_stories+tests.md + SDLC_analysis.md, no actual implementation code), all teaching the same underlying security curriculum — OWASP Web/LLM/Agentic AI/API/Client-Side/CI-CD Top 10s, MITRE ATLAS, CompTIA Security+/SecAI+, and the full OWASP Cornucopia card-deck family (Web App, Mobile App, Companion LLM/AAI, STRIDE EoP, Elevation of MLSec, and the Digital-by-Default Harms deck) — but each implemented end-to-end in a different language/stack, with a mandatory Polish/English UI toggle and code samples in five fixed "content" languages (Python, Java, Go, Scala, Lua) regardless of the app's own implementation language.

| App | Name | Stack |
|---|---|---|
| app01_react | [[SecureVision 2026 (app01_react)]] | Java/Spring Boot + React |
| app02_angular | [[ThreatView 2026 (app02_angular)]] | Java/Spring Boot + Angular |
| app03_python_django | [[ThreatCompass 2026 (app03_python_django)]] | Python/Django (single-language monolith) |
| app04_scala_react | [[ScalaShield 2026 (app04_scala_react)]] | Scala/ZIO + React |
| app05_go_react | [[GoSentry 2026 (app05_go_react)]] | Go + React |
| app06_HASKELL_react | [[HaskShield 2026 (app06_HASKELL_react)]] | Haskell + React |
| app07_rust_react | [[RustBastion 2026 (app07_rust_react)]] | Rust + React |
| app08_cpp_react | [[CppCitadel 2026 (app08_cpp_react)]] | C++ + React (deliberate unsafe counter-example) |
| app09_php_WORDPRESS | [[SecurePress 2026 (app09_php_WORDPRESS)]] | PHP/WordPress plugin (no SPA) |
| app10_csharp_react | [[SharpGuard 2026 (app10_csharp_react)]] | C#/.NET + React |
| app11_swift_ios | [[SwiftGuard 2026 (app11_swift_ios)]] | Swift/iOS (no backend) |
| app12_kotlin_android | [[KotlinGuard 2026 (app12_kotlin_android)]] | Kotlin/Android (no backend, iOS's twin) |

## Pages Created from This Source

- [[Security Course App Stack Comparison]] — full comparison table (stack, CardKind tier, SAST/SCA tooling, architectural departures)
- [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] — the 8-tier cross-cutting design-pattern deep dive
- One entity page per app (12 total, linked in the table above)

## Key Findings

1. **The series functions as a live comparative case study in type-system and platform guarantee strength**, not just a set of independent apps — the same design problem (CardKind) gets a measurably different, honestly-stated guarantee level in each stack. See [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] for the full ranking.
2. **Every app's plan explicitly states the limits of its own strongest guarantee** rather than overclaiming — e.g. C++'s exhaustive `std::visit` check is explicitly flagged as bypassable via `std::get_if`; C#'s `CS8509` is explicitly flagged as config-reversible. This self-critical framing recurs across apps 05–12.
3. **Mobile apps 11 (Swift/iOS) and 12 (Kotlin/Android) are the only fully on-device siblings**, explicitly designed as structural twins, each stating precisely where the platforms' guarantees genuinely differ (IPC surface, SCA tooling maturity, JSON decoding strictness defaults, app-store review cadence) instead of assuming the other's conclusions transfer unchanged.
4. **This source overlaps thematically but not textually** with the earlier-ingested [[Security Architects Game and SecAI Threat Landscape]] — both concern the same underlying OWASP/MITRE/CompTIA course content, but this source is 12 concrete software-architecture case studies built *from* that content, while the earlier source is the raw research/translation transcript *behind* it.

## Raw Files

`.raw/app01_react/` through `.raw/app12_kotlin_android/` (4 files each, ~30-155KB per file). A duplicate copy of the course's master reference document exists at `.raw/docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md` — identical hash to the already-ingested top-level copy, not re-ingested (see `.raw/.manifest.json`). `.raw/docs/OWASP_stories/*.yaml` (the 6 raw Cornucopia card decks) were out of scope for this ingest (`docs/*.*` does not match files inside a subdirectory) and remain unread.
