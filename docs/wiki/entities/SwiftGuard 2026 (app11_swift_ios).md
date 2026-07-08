---
type: entity
title: "SwiftGuard 2026 (app11_swift_ios)"
address: c-000026
entity_type: product
role: "Security-education native iOS app (Swift, no backend)"
first_mentioned: "[[OWASP Security Course App Series]]"
created: 2026-07-07
updated: 2026-07-07
tags:
  - entity
  - product
  - security
  - ai-security
  - mobile
status: current
related:
  - "[[Security Course App Stack Comparison]]"
  - "[[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]]"
  - "[[KotlinGuard 2026 (app12_kotlin_android)]]"
sources:
  - "[[OWASP Security Course App Series]]"
---

# SwiftGuard 2026 (app11_swift_ios)

Planning-only, native iOS security-education app: Swift 6 (strict concurrency), SwiftUI, SwiftData (`@Model` over embedded SQLite), `Observation` framework, `#Predicate` macro for queries, Sign in with Apple + CloudKit for the one optional networked feature (bookmark sync), Keychain Services for the sync token. The series' most complete architectural departure yet — **no client-server model at all**: no backend, no REST API, no database server, entirely on-device. Its own threat model is substantially the same content it teaches (OWASP MASVS + the Mobile Cornucopia deck).

## Key Decisions

- App Sandbox/entitlements/code-signing — kernel-enforced process isolation independent of app code correctness, the strongest OS-level guarantee in the series
- Two local Swift Package targets (`SwiftGuardData`/`SwiftGuardUI`) giving `internal` access control real cross-target teeth
- SwiftData `#Predicate` macro — compile-time-checked, inherently parameterized queries, eliminating SQL-injection surface entirely
- Custom `LocalizationManager` with `Bundle` swizzling — in-app PL/EN toggle independent of device system language, no restart
- Hand-written `Decodable` unknown-key rejection, compensating for Swift's default lenient decoding (opposite default from [[SharpGuard 2026 (app10_csharp_react)]]'s YamlDotNet)

## CardKind Pattern

**Present, unconditional compile-time** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 1. `enum CardKind { case technicalThreat(severity: Severity); case designHarm }` — `Severity` is only reachable as an associated value on `.technicalThreat`. An exhaustive `switch` with no `default:` case makes omitting a case an unconditional Swift compiler error, stronger than [[SharpGuard 2026 (app10_csharp_react)]]'s config-dependent `CS8509`. A SwiftLint custom rule additionally flags any stray `default:` arm added to a `CardKind` switch — the one way a developer could opt out.

## Testing & Tooling

XCTest (unit/integration, in-memory `ModelContainer`); SwiftCheck (property-based); XCUITest (native UI/E2E, replaces Playwright, one file per user story). SAST: SwiftLint (custom rules) + Xcode Analyze. SCA: **no mature SPM-native tool exists as of 2026** — explicitly stated gap, mitigated by manual quarterly review against the GitHub Advisory Database. DAST and Trivy explicitly marked "not applicable" rather than silently omitted, since there's no network API or container image.

## Architecture

No backend, database server, or web frontend exists anywhere; SQL injection, CSRF, and DAST become structurally inapplicable. Distribution requires passing **Apple App Review** — an external, independent, days-long gate with no equivalent in any other sibling's pipeline. Directly paired with [[KotlinGuard 2026 (app12_kotlin_android)]] as the series' Android twin.
