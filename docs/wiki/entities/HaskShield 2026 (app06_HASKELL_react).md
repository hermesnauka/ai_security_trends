---
type: entity
title: "HaskShield 2026 (app06_HASKELL_react)"
address: c-000021
entity_type: product
role: "Security-education web app (Haskell + React)"
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

# HaskShield 2026 (app06_HASKELL_react)

Planning-only security-education app: Haskell (GHC 9.8), `servant` (type-level API), `hasql`/`hasql-th` (compile-time-checked SQL), PostgreSQL 16, `odd-jobs` (Postgres-backed queue), React 18 + TypeScript frontend. The fifth backend ecosystem in the comparison series, pushing the "shift security left into the type system" theme further than any sibling — several guarantees hold because invalid states are literally unrepresentable in the data types, not merely validated against.

## Key Decisions

- `hasql-th`: SQL is quasi-quoted and checked against a live schema at compile time — typos become compile errors, not test failures
- Effects visible in type signatures (IO vs. pure) — reviewers verify side-effect scope from signatures alone
- `password` package phantom types distinguish `Password` from `PasswordHash Bcrypt` at compile time
- Module export lists + CI module-graph grep restrict `Integrity.Verify` to specific callers
- STM token-bucket rate limiting — race-free atomicity from the GHC runtime, no third-party library

## CardKind Pattern

**Present, strongest tier in the series** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 1. `CardKind = TechnicalThreat Severity | DesignHarm` — `DesignHarm` is a distinct constructor carrying no severity field at all (not `Maybe Severity`). GHC `-Wincomplete-patterns -Werror` forces exhaustive handling of every `CardKind` case; `hspec` tests additionally assert the `severity` key is entirely absent (not null) from `DesignHarm` API responses.

## Testing & Tooling

hspec + QuickCheck (property-based) + hspec-wai (backend); Vitest + RTL (frontend); Playwright (E2E). SAST: hlint, stan, GHC `-Wall -Werror`. SCA: osv-scanner (Cabal/Hackage) + npm audit + Trivy.

## Architecture

Two separately compiled executables (`api`, `worker`) from one Cabal package sharing a core library — a real OS-process trust boundary. Cornucopia card data has no admin write endpoint at all — unrepresentable at the API-type level, not just permission-gated.
