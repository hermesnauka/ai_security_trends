---
type: entity
title: "SharpGuard 2026 (app10_csharp_react)"
address: c-000025
entity_type: product
role: "Security-education web app (C#/.NET + React)"
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

# SharpGuard 2026 (app10_csharp_react)

Planning-only security-education app: C# 13/.NET 9, ASP.NET Core Minimal APIs, EF Core 9 (Npgsql) against PostgreSQL 16, Hangfire (Postgres-backed jobs), React 18 + TypeScript frontend, Native AOT publishing. Written as an explicit comparative essay against nine sibling apps, rating C#'s type-level guarantees, memory safety, and SQLi defenses relative to each rather than describing itself in isolation — repeatedly stating the exact limits of its own guarantees rather than overclaiming parity with stronger siblings.

## Key Decisions

- `<AllowUnsafeBlocks>false</AllowUnsafeBlocks>` project-wide — bans `unsafe` C#, mirroring Rust's `forbid(unsafe_code)`
- EF Core LINQ always parameterizes SQL, but only type-checks against the entity model, not the live schema at compile time (weaker than sqlc/sqlx)
- ASP.NET Core's built-in `Microsoft.AspNetCore.RateLimiting` middleware — no third-party rate-limit library
- `Integrity.Verify()` marked `internal`, no `InternalsVisibleTo` grant to the API project, enforced further by a `NetArchTest` architecture test in CI
- Native AOT publish of both executables as self-contained, JIT-free native binaries in minimal container images

## CardKind Pattern

**Present, compile-time but config-dependent** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 3. `CardKind` is an `abstract record` with sealed subtypes `TechnicalThreat(Severity Severity)` and `DesignHarm` (no severity field). A `switch` expression with no default arm triggers Roslyn diagnostic `CS8509` — but this is a warning by default, promoted to a build-breaking error only via `.editorconfig`/`<WarningsAsErrors>CS8509</WarningsAsErrors>`. The plan states outright this is weaker than Rust/Haskell/Swift/Kotlin (no unconditional language-level error) and could be silently reverted by removing that config line — mitigated only by a CI grep, a quarterly `.csproj` audit, and a dedicated abuse-case entry (AC-17).

## Testing & Tooling

xUnit + FluentAssertions + FsCheck (property-based) + `WebApplicationFactory<T>` + NetArchTest (architecture boundary tests); Vitest + RTL + Playwright + MSW 2 (frontend/E2E). SAST: Roslyn analyzers + SecurityCodeScan + SonarAnalyzer.CSharp + eslint-plugin-security. SCA: `dotnet list package --vulnerable` (built into the .NET CLI, no external tool needed) + npm audit + Trivy. DAST: OWASP ZAP.

## Architecture

Two separately published executables (`SharpGuard.Api`, `SharpGuard.Worker`) sharing a core library, with a compiler-enforced `internal`/`InternalsVisibleTo` boundary restricting a security function to the worker only. `CornucopiaCard` data has no admin write endpoint anywhere — read-only except via seed/reingest jobs.
