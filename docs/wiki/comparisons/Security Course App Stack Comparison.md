---
type: comparison
title: "Security Course App Stack Comparison"
address: c-000014
created: 2026-07-07
updated: 2026-07-07
tags:
  - comparison
  - security
  - ai-security
status: current
subjects:
  - "[[SecureVision 2026 (app01_react)]]"
  - "[[ThreatView 2026 (app02_angular)]]"
  - "[[ThreatCompass 2026 (app03_python_django)]]"
  - "[[ScalaShield 2026 (app04_scala_react)]]"
  - "[[GoSentry 2026 (app05_go_react)]]"
  - "[[HaskShield 2026 (app06_HASKELL_react)]]"
  - "[[RustBastion 2026 (app07_rust_react)]]"
  - "[[CppCitadel 2026 (app08_cpp_react)]]"
  - "[[SecurePress 2026 (app09_php_WORDPRESS)]]"
  - "[[SharpGuard 2026 (app10_csharp_react)]]"
  - "[[SwiftGuard 2026 (app11_swift_ios)]]"
  - "[[KotlinGuard 2026 (app12_kotlin_android)]]"
dimensions:
  - "backend/runtime language"
  - "CardKind guarantee tier"
  - "SAST/SCA tooling"
  - "architectural departures"
verdict: "No single stack 'wins' — each app trades a different guarantee mechanism (type system, database, OS sandbox, code review policy) for a different weakness, and the series' value is in stating each trade-off honestly rather than picking a favorite."
related:
  - "[[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]]"
  - "[[OWASP Security Course App Series]]"
sources:
  - "[[OWASP Security Course App Series]]"
---

# Security Course App Stack Comparison

Twelve planning-only sibling applications (no implementation code — see [[OWASP Security Course App Series]]), each teaching identical OWASP/MITRE ATLAS/CompTIA SecAI+ security content in a different implementation language/stack, with a Polish/English UI toggle. This page is the cross-app comparison table; see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] for the deep dive on the single most instructive recurring design decision across all twelve.

## Stack & Architecture

| App | Name | Backend / Runtime | Frontend | Persistence | Architecture |
|---|---|---|---|---|---|
| app01_react | [[SecureVision 2026 (app01_react)]] | Java 21 / Spring Boot 3.3 | React 18 + TS | PostgreSQL 16 + Redis | Standard client-server |
| app02_angular | [[ThreatView 2026 (app02_angular)]] | Java 21 / Spring Boot 3.3 | Angular 18 | PostgreSQL 16 + Redis | Standard client-server |
| app03_python_django | [[ThreatCompass 2026 (app03_python_django)]] | Python 3.13 / Django 5.2 | Django Templates + HTMX + Alpine.js (no SPA) | PostgreSQL 16 + Redis/Celery | Single-language monolith |
| app04_scala_react | [[ScalaShield 2026 (app04_scala_react)]] | Scala 3.3 / ZIO 2 | React 18 + TS | PostgreSQL 16 + Redis | Standard client-server, pure-FX backend |
| app05_go_react | [[GoSentry 2026 (app05_go_react)]] | Go 1.23 | React 18 + TS | PostgreSQL 16 + Redis/River | Two static binaries (api/worker) |
| app06_HASKELL_react | [[HaskShield 2026 (app06_HASKELL_react)]] | Haskell / GHC 9.8 | React 18 + TS | PostgreSQL 16 + Redis/odd-jobs | Two executables, one Cabal package |
| app07_rust_react | [[RustBastion 2026 (app07_rust_react)]] | Rust (2024 edition) | React 18 + TS | PostgreSQL 16 + Redis/apalis | `forbid(unsafe_code)`, static musl binaries |
| app08_cpp_react | [[CppCitadel 2026 (app08_cpp_react)]] | C++23 / Drogon | React 18 + TS | PostgreSQL 16 + Redis | Deliberate memory-unsafe counter-example |
| app09_php_WORDPRESS | [[SecurePress 2026 (app09_php_WORDPRESS)]] | PHP 8.3 (WordPress plugin) | Server-rendered + vanilla JS | MySQL 8.0 (WordPress) | CMS plugin, no SPA, no separate worker |
| app10_csharp_react | [[SharpGuard 2026 (app10_csharp_react)]] | C# 13 / .NET 9 Minimal APIs | React 18 + TS | PostgreSQL 16 + Hangfire | Native AOT, two executables |
| app11_swift_ios | [[SwiftGuard 2026 (app11_swift_ios)]] | Swift 6 (on-device only) | SwiftUI | SwiftData (embedded SQLite) | No backend at all — native iOS |
| app12_kotlin_android | [[KotlinGuard 2026 (app12_kotlin_android)]] | Kotlin 2.x (on-device only) | Jetpack Compose | Room (embedded SQLite) | No backend at all — native Android, iOS's twin |

## CardKind Guarantee Tier (see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] for full explanation)

| App | Tier | Mechanism |
|---|---|---|
| app06 HaskShield | 1 — Unconditional compile-time | `TechnicalThreat Severity \| DesignHarm`, GHC exhaustiveness |
| app07 RustBastion | 1 — Unconditional compile-time | `enum CardKind`, `clippy -D warnings` exhaustive match |
| app11 SwiftGuard | 1 — Unconditional compile-time | `enum CardKind` + exhaustive `switch` |
| app12 KotlinGuard | 1 — Unconditional compile-time | `sealed interface CardKind` + exhaustive `when` expression |
| app09 SecurePress | 2 — Database-enforced | MySQL `CHECK` constraint, holds independent of any code path |
| app10 SharpGuard | 3 — Compile-time, config-dependent | Sealed `record` + `switch`, `CS8509` promoted via `.editorconfig` (revertible) |
| app08 CppCitadel | 4 — Compile-time, bypassable | `std::variant` + exhaustive `std::visit`, but `std::get_if` bypasses it |
| app05 GoSentry | 5 — Constructor-signature-enforced | `NewDesignHarmCard(...)` has no `Severity` parameter |
| app04 ScalaShield | 6 — DTO field-omission, test-enforced | Separate DTO without `severity` + component separation |
| app03 ThreatCompass | 7 — Runtime convention, one test | Serializer sets `card_kind` field; no model-level constraint |
| app01 SecureVision | 8 — Not present | No CardKind concept; incidental schema separation only |
| app02 ThreatView | 8 — Not present | No CardKind concept; incidental schema separation only |

## SAST / SCA Tooling by Ecosystem

| App | SAST | SCA |
|---|---|---|
| app01/app02 (Java) | SpotBugs + FindSecBugs, SonarQube | OWASP Dependency Check + Trivy |
| app03 (Python) | Bandit | pip-audit + Trivy |
| app04 (Scala) | Scalafix + Wartremover + Scapegoat | sbt-dependency-check + Trivy |
| app05 (Go) | golangci-lint (bundles gosec) | govulncheck (call-graph-aware) + Trivy |
| app06 (Haskell) | hlint, stan, `-Wall -Werror` | osv-scanner + Trivy |
| app07 (Rust) | clippy `-D warnings` | cargo-audit + cargo-deny + cargo-geiger |
| app08 (C++) | clang-tidy, Clang Static Analyzer, cppcheck | OWASP Dependency-Check (CPE mode) + vcpkg/conan audit |
| app09 (PHP/WordPress) | PHPCS/WPCS + PHPStan | composer audit + roave/security-advisories + **WPScan** |
| app10 (C#) | Roslyn analyzers + SecurityCodeScan + SonarAnalyzer | `dotnet list package --vulnerable` (built-in) |
| app11 (Swift) | SwiftLint + Xcode Analyze | **No mature SPM-native tool** — explicitly stated gap, manual quarterly review |
| app12 (Kotlin) | Android Lint + detekt | OWASP Dependency-Check Gradle plugin — closes the exact gap app11 states |

## Notable Architectural Departures

- **No SPA at all**: app03 (Django Templates + HTMX) and app09 (server-rendered WordPress + vanilla JS) — both explicitly reject the React-SPA pattern every other web-backed sibling uses.
- **No backend at all**: app11 (Swift/iOS) and app12 (Kotlin/Android) — the only two fully on-device apps, explicitly designed as structural twins, each stating precisely where the other platform's guarantee differs (see their own pages).
- **Deliberate negative example**: app08 (C++) is explicitly framed as the memory-*unsafe* counter-example to app07 (Rust), with a dedicated fuzzing/sanitizer hardening phase no other sibling has.
- **Self-critique as a design principle**: apps 05, 06, 07, 08, 10, 11, 12 all explicitly state the exact limits of their own strongest guarantees (e.g., "this only works if the developer uses `std::visit` and not `std::get_if`") rather than overclaiming — a pattern worth naming since it's unusual for planning documents to self-undermine their own headline feature this precisely.
