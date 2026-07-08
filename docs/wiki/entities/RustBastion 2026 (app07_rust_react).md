---
type: entity
title: "RustBastion 2026 (app07_rust_react)"
address: c-000022
entity_type: product
role: "Security-education web app (Rust + React)"
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
  - "[[CppCitadel 2026 (app08_cpp_react)]]"
sources:
  - "[[OWASP Security Course App Series]]"
---

# RustBastion 2026 (app07_rust_react)

Planning-only security-education app: Rust (2024 edition, stable), axum on Tokio, sqlx (compile-time-checked queries against PostgreSQL 16), Redis 7, apalis (Postgres-backed job queue), React 18 + TypeScript frontend. The sixth sibling in the series; explicitly framed around a *different axis* of guarantee than its predecessors — compile-time-enforced memory safety without a GC, aligned with 2026 CISA/NSA memory-safe-language guidance — while explicitly refusing to conflate memory safety with business-logic/security correctness.

## Key Decisions

- `#![forbid(unsafe_code)]` at every crate root — any `unsafe` block is a compile error, eliminating use-after-free/double-free/OOB/null-deref in the app's own code
- `sqlx::query!`/`query_as!` — SQL verified against a live/cached schema at compile time
- Ownership + `Send`/`Sync` — data races across async tasks are compiler-rejected, not runtime-guarded
- `pub(crate)` visibility + a CI `cargo modules` dependency-graph check for least privilege
- Smart-constructed newtypes (e.g. `OwaspRef::new`) validate reference IDs against allowlists at zero runtime cost

## CardKind Pattern

**Present, strongest tier in the series** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 1. `CardKind` is a Rust enum (`TechnicalThreat(Severity) | DesignHarm`); `DesignHarm` carries no payload at all. Any `match` missing a variant is a compile error (backed by `clippy -D warnings`) — no code path can construct a `DesignHarm` with a severity. Additionally tested: a `proptest`/integration test asserts API responses for the harms suit never contain a severity value.

## Testing & Tooling

Built-in `#[test]`/`#[tokio::test]` + `proptest` (property-based) + `axum-test`/`reqwest`; Vitest + RTL + Playwright (frontend/E2E). SAST: `cargo clippy -D warnings` + eslint-plugin-security. SCA: `cargo audit` + `cargo-deny` + `cargo-geiger` (reports dependency-tree `unsafe`) + npm audit + Trivy.

## Architecture

`api` and `worker` are two separately compiled binaries from one Cargo workspace — a real OS-process trust boundary; production images are static `musl` binaries in `FROM scratch` containers (no libc/shell/interpreter). Directly contrasted against [[CppCitadel 2026 (app08_cpp_react)]], its deliberate memory-unsafe counter-example sibling.
