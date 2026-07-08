---
type: entity
title: "KotlinGuard 2026 (app12_kotlin_android)"
address: c-000027
entity_type: product
role: "Security-education native Android app (Kotlin, no backend)"
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
  - "[[SwiftGuard 2026 (app11_swift_ios)]]"
sources:
  - "[[OWASP Security Course App Series]]"
---

# KotlinGuard 2026 (app12_kotlin_android)

Planning-only, native Android security-education app, 100% Kotlin: Jetpack Compose (Material 3), Room over embedded SQLite (KSP-processed), `ViewModel`/`StateFlow`, `kotlinx.serialization`+`kaml` (strict decoding), WorkManager, optional Google Sign-In + Cloud Firestore sync isolated to a single `SyncCoordinator` class. Explicitly the Android structural twin of [[SwiftGuard 2026 (app11_swift_ios)]] — same "no client-server model" departure — with a dedicated section stating precisely where Android's guarantees differ from iOS's (larger IPC/exported-component surface, Room's compile-time SQL verification vs. `#Predicate`, opposite JSON-strictness defaults) rather than assuming equivalence.

## Key Decisions

- Android per-app Linux UID + SELinux sandbox — kernel-enforced, same category as iOS App Sandbox but with a larger IPC attack surface
- Every component `android:exported="false"` except the launcher `MainActivity` — closes Android's historically real exported-component vulnerability class, lint-enforced
- Room `@Query` compile-time SQL verification via KSP — parses/validates the SQL string against the schema at build time, stronger than iOS's `#Predicate`
- `LocaleController` via `AppCompatDelegate.setApplicationLocales` — instant PL/EN switch, no restart
- `kotlinx.serialization`/`kaml` strict decoding (`ignoreUnknownKeys = false`) — opposite default from iOS `Codable`, enforced by a `detekt` custom rule

## CardKind Pattern

**Present, unconditional compile-time** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 1. `sealed interface CardKind` with `TechnicalThreat(val severity: Severity)` (data class) and `DesignHarm` (data object). Every read site uses a `when` **expression** (not statement) with no `else` branch, making an unhandled case an unconditional compile error — same strongest tier as Swift/Rust/Haskell, unlike C#'s revertible `CS8509`. Stated caveat: using `when` as a *statement*, or adding a catch-all `else` "just in case," silently defeats the guarantee — mitigated by a SEC REVIEW checklist item and a `CardKindExhaustivenessPropertyTest` retained as living documentation even though it's "almost redundant" with the compiler guarantee.

## Testing & Tooling

JUnit 5 + Kotest (property-based) + Compose UI Testing (`createAndroidComposeRule`, one file per user story). SAST: Android Lint (`ExportedContentQuery`, `TrustAllX509TrustManager`, `AllowBackup`, `AllowAllHostnameVerifier`) + detekt (custom rules banning `ignoreUnknownKeys=true` and `rawQuery`). SCA: **OWASP Dependency-Check Gradle plugin** against the NVD — explicitly stated to close the SCA maturity gap [[SwiftGuard 2026 (app11_swift_ios)]] accepts for Swift Package Manager.

## Architecture

No server backend at all; the only network-reachable path is the optional Firestore bookmark-sync feature on Google-managed infrastructure — no DAST-equivalent phase exists. Distribution: Internal → Closed/Open testing → Google Play production, with staged rollout; Google Play review is described as generally faster/more automated than Apple App Review but explicitly not to be treated as a formality.
