---
type: entity
title: "GoSentry 2026 (app05_go_react)"
address: c-000020
entity_type: product
role: "Security-education web app (Go + React)"
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

# GoSentry 2026 (app05_go_react)

Planning-only security-education app: Go 1.23 as the sole backend language (chi v5, pgx v5, sqlc-generated compile-time-checked SQL), PostgreSQL 16, Redis 7, River (Postgres-backed job queue), React 18 + TypeScript frontend. Explicitly framed as "the most different from a Java mental model" sibling in the series — no exceptions, no DI container, no GC tuning, errors-as-values, a single static binary instead of a JAR/interpreter tree. Repeatedly warns students not to conclude "Go is inherently secure" just because certain bug classes disappear structurally.

## Key Decisions

- Errors as values, no exceptions — only chi's `Recoverer` catches panics, preventing leaked stack traces
- `sqlc` generates compile-time-checked, parameterized queries — SQL injection structurally unavailable, no ORM
- `internal/` package-visibility as compiler-enforced least privilege, backed by a `depguard` lint rule
- Static, CGO-disabled binaries in scratch/distroless images — no shell/JVM/interpreter, ≤30MB
- Opaque named string types (`ThreatCode`, `OwaspRef`, etc.) with validating smart constructors

## CardKind Pattern

**Present, constructor-signature-enforced** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 5. `CardKind` is a Go string enum (`TECHNICAL_THREAT`/`DESIGN_HARM`); the guarantee is enforced at the constructor level — `NewDesignHarmCard(...)` simply has no `Severity` parameter in its signature. Locked in by a unit test, an API-level integration test, and a frontend test that `DesignHarmBadge` never co-renders with `SeverityBadge` — structural but not a language-level sum type with exhaustive matching.

## Testing & Tooling

Go `testing` + `testify` + `httptest`; Vitest + RTL (frontend); Playwright (19 spec files, one per user story). SAST: `golangci-lint` (bundles gosec, staticcheck, go vet, depguard) + eslint-plugin-security. SCA: `govulncheck` (call-graph-aware) + npm audit + Trivy. DAST: OWASP ZAP.

## Architecture

Two separately compiled Go binaries (`cmd/api`, `cmd/worker`) sharing one module — a real OS-process trust boundary; River (Postgres-backed queue) replaces a separate message broker; the worker has no HTTP listener at all.
