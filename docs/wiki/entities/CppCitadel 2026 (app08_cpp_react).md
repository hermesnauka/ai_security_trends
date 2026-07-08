---
type: entity
title: "CppCitadel 2026 (app08_cpp_react)"
address: c-000023
entity_type: product
role: "Security-education web app (C++, deliberate memory-unsafe counter-example)"
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
  - "[[RustBastion 2026 (app07_rust_react)]]"
sources:
  - "[[OWASP Security Course App Series]]"
---

# CppCitadel 2026 (app08_cpp_react)

Planning-only security-education app: C++23 (GCC 14+/Clang 18+), Drogon (async coroutine web framework), libpqxx + sqlpp11, PostgreSQL 16, Redis 7, React 18 + TypeScript frontend. The 7th backend in the series, and explicitly framed as the **deliberate counter-example** to [[RustBastion 2026 (app07_rust_react)]]: the plan names every compile-time guarantee its memory-safe siblings get "for free" and states plainly that C++ lacks it, substituting sanitizers/fuzzing/static analysis/code review instead. Uniquely has a dedicated "Phase 3.5 — Fuzzing & Sanitizer Hardening" sprint with no equivalent in any sibling.

## Key Decisions

- RAII/smart-pointer discipline, no raw `new`/`delete` — no borrow checker exists, so enforced by `clang-tidy` as build-breaking
- `integrity::verify` isolation via build-graph structure + CI grep — weaker than the compiler-enforced module boundaries in Go/Haskell/Rust siblings
- `yaml-cpp` with hand-written, unit/property-tested unknown-key-rejecting decoders
- AddressSanitizer/UBSan/ThreadSanitizer as the primary (runtime, detective) safety net replacing compile-time memory safety
- Atomic (`std::atomic`/CAS) token-bucket rate limiter, correctness backstopped only by nightly TSan

## CardKind Pattern

**Present, but developer-bypassable** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 4. `CardKind = std::variant<TechnicalThreat{Severity}, DesignHarm{}>`; reading it via `std::visit` with an exhaustive "overloaded" lambda set is genuinely compile-time exhaustiveness-checked. However, nothing stops a developer from using `std::get_if<TechnicalThreat>` and silently ignoring `DesignHarm`, entirely bypassing the check — backstopped only by code-review policy (Definition of Done requires `std::visit`, never `std::get`/`std::get_if`). The plan names this as the project's single largest structural risk versus its Rust/Haskell/Go siblings.

## Testing & Tooling

GoogleTest + GoogleMock + RapidCheck (property-based) + Drogon test client; Vitest + RTL + Playwright (frontend/E2E). SAST: clang-tidy, Clang Static Analyzer, cppcheck. SCA: OWASP Dependency-Check (C/C++ CPE mode) + vcpkg/conan audit + npm audit + Trivy. Dynamic analysis: ASan/UBSan every run, TSan nightly, libFuzzer continuous/per-PR.

## Architecture

Two separately compiled binaries (`api`, `worker`) sharing a static core library; a dedicated "FUZZ/SANITIZE" Kanban column; a whole SDLC document section devoted to stating which security properties are compiler-enforced vs. tool-enforced vs. pure human-review policy — an unusually self-critical framing for a planning document.
