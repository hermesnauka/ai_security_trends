# SharpGuard 2026 — Application Development Plan

**Version:** 1.0
**Date:** 2026-07-07
**Status:** Living document — updated after each sprint planning session
**Directory:** `app10_csharp_react`
**Sibling projects:** `app01_react`/`app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django), `app04_scala_react` (Scala/ZIO), `app05_go_react` (Go), `app06_HASKELL_react` (Haskell), `app07_rust_react` (Rust), `app08_cpp_react` (C++), `app09_php_WORDPRESS` (PHP/WordPress)

---

## 0. Note on the Stack

This application is written **entirely in C#** on **.NET 9** for the backend — no second backend language — with a **React 18 + TypeScript** frontend, matching the React-frontend pattern of `app01_react`/`app04_scala_react`/`app05_go_react`/`app06_HASKELL_react`/`app07_rust_react`/`app08_cpp_react`. It is the ninth backend platform in this course's comparison series (the tenth app overall, counting `app09_php_WORDPRESS`'s platform-based departure), and it returns to the "custom backend + React SPA" architecture after that departure.

**Where C# sits in this series' recurring "how strong is the type-level guarantee, and what is it enforced by" comparison:**

- Like Go, Haskell, Rust, and Java, C# is **garbage-collected and memory-safe by default** — the CWE Top 25 memory-corruption classes `app08_cpp_react`'s entire plan is organized around (use-after-free, buffer overflow, use of uninitialized memory) do not occur in ordinary C# code, the same category of guarantee `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react` each have, achieved here via the CLR's managed memory model rather than Rust's ownership system specifically.
- On the "digital-harms-deck cannot carry a severity" guarantee that recurs throughout this series (`PLAN.md` D-04 in this document), C# offers a **sealed record hierarchy with `switch`-expression exhaustiveness checking** — the second-strongest version of this guarantee in the series after Rust's `enum`/Haskell's ADT, ahead of Go's constructor-omission convention and materially ahead of C++'s `std::variant` (which requires deliberately choosing the `std::visit` idiom) or PHP's database-`CHECK`-constraint-only approach. The honest caveat, stated in full in §4 D-04: C#'s exhaustiveness check (`CS8509`) is a compiler **warning** by default, promoted to a build-breaking **error** only by explicit project configuration — this project makes that configuration explicit and treats it as load-bearing, but it is one `.csproj` edit away from silently reverting to a warning, which is not true of Rust's or Haskell's equivalent (there is no configuration flag that turns off Rust's non-exhaustive-match error).
- On SQL-injection prevention, C#/EF Core sits closer to `app03_python_django`'s Django ORM than to `app05_go_react`'s `sqlc`/`app06_HASKELL_react`'s `hasql-th`/`app07_rust_react`'s `sqlx::query!`: EF Core's LINQ-to-SQL translation always parameterizes generated queries and gives compile-time *C# type* checking of the query expression, but it does not verify the query's *shape* against the live database schema at compile time the way the macro/template-based tools do. This plan states that positioning explicitly (§4 D-02) rather than overclaiming parity with the strongest siblings.
- .NET's tooling is unusually "batteries-included" for this series: a **built-in rate-limiting middleware** (no STM, no Redis Lua script, no hand-rolled atomic token bucket needed for the single-instance case), a **built-in vulnerable-package scanner** (`dotnet list package --vulnerable`, no separate SCA tool required for NuGet dependencies), and **Roslyn analyzers running inside the same compiler pipeline that already produces nullable-reference-type warnings** — this plan leans into that built-in tooling rather than reaching for third-party equivalents where the framework already provides a first-class one (§2).

**Note on code samples:** the application still *teaches* countermeasures in five languages — Python, Java, Go, Scala, and Lua (see §10) — because that is separate, deliberately polyglot **content**, not the application's own runtime. None of those five languages is the application's implementation language; the application itself is C# and TypeScript/JavaScript only.

---

## 1. Project Overview

**Name:** SharpGuard 2026
**Purpose:** A bilingual (Polish/English) reference and learning platform mapping security threats, vulnerabilities and mitigations across **OWASP** (Web Top 10, LLM Top 10, Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, Automated Threats/OAT, MASVS), **MITRE ATLAS**, and **CompTIA Security+ SY0-701 / SecAI+ 2026**, plus the full catalogue of **OWASP Cornucopia-family card decks** found in `docs/OWASP_stories/*.yaml`. Each threat is presented with working countermeasure code in **five languages**: Python, Java, Go, Scala, and Lua.

**Source material:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md` and all six card decks under `docs/OWASP_stories/`:

| File | Edition | Suits |
|---|---|---|
| `webapp-cards-3.0-en.yaml` | OWASP Cornucopia — Website App v3.0 | VE, AT, SM, AZ, CR, C, WC |
| `mobileapp-cards-1.1-en.yaml` | OWASP Cornucopia — Mobile App v1.1 | PC, AA, NS, RS, CRM, CM, WC |
| `__LLM_AI___companion-cards-1.0-en.yaml` | OWASP Cornucopia — Companion (AI/Cloud/DevOps) v1.0 | LLM, CLD, FRE, DVO, BOT, AAI, Common |
| `STRIDE__eop-cards-5.0-en.yaml` | Microsoft "Elevation of Privilege" (STRIDE) v5.0 | SP, TA, RE, ID, DS, EP |
| `RISKS__elevation-of-mlsec-cards-1.0-en.yaml` | "Elevation of MLSec" v1.0 | EMR, EIR, EOR, EDR |
| `dbd-cards-1.0-en.yaml` | Digital-by-Default Harms Deck v1.0 | SCO, ARC, AGE, TRU, POR, COR, WC |

All six decks are in scope from day one of this plan (§11, §15) — the gap the `app04_scala_react` plan initially had (and was later corrected for) is avoided here from the start, as it was for every subsequent sibling.

**UI languages:** Polish (default) and English, switched instantly with no page reload; toggle persisted in `localStorage` under key `sg_locale`, mirrored server-side via `Accept-Language`.

---

## 2. Technology Stack

### Backend (100% C# / .NET 9)
| Layer | Technology | Version (2026) |
|---|---|---|
| Runtime | .NET | 9 (LTS-track) |
| Language | C# | 13, `<Nullable>enable</Nullable>` project-wide |
| Web framework | ASP.NET Core Minimal APIs | 9.x |
| Database access | Entity Framework Core (EF Core), LINQ-to-SQL — always parameterized, compile-time C#-type-checked, but **not** schema-shape-verified at compile time (§4 D-02) | 9.x |
| Database | PostgreSQL 16 (via `Npgsql.EntityFrameworkCore.PostgreSQL`) | — |
| Migrations | EF Core Migrations (`dotnet ef migrations add/update`) | — |
| Cache / rate-limit store | ASP.NET Core's **built-in** `Microsoft.AspNetCore.RateLimiting` middleware (fixed-window/sliding-window/token-bucket policies, no third-party library needed for single-instance limits); Redis (`StackExchange.Redis`) for cross-instance cache | — |
| Background jobs | Hangfire (PostgreSQL storage provider) — persistent job queue with a built-in monitoring dashboard | — |
| Auth | ASP.NET Core JWT Bearer middleware (`Microsoft.AspNetCore.Authentication.JwtBearer`), RS256 | — |
| Password hashing | ASP.NET Core Identity's `PasswordHasher<T>` (PBKDF2, upgradeable to Argon2id via `Konscious.Security.Cryptography` if required by a future security review) | — |
| Validation | `FluentValidation`, plus C# 12 primary-constructor validation in record types | — |
| HTML sanitization | `HtmlSanitizer` (NuGet, allow-list based, actively maintained, widely used in the .NET ecosystem) | — |
| YAML parsing | `YamlDotNet` — its default `Deserializer` **throws on unrecognized YAML properties unless `.IgnoreUnmatchedProperties()` is explicitly called**, i.e. strict rejection is the out-of-the-box default here, not an opt-in (§4 D-08) | — |
| Structured logging | `Serilog`, structured sinks to Loki | — |
| API docs | `Microsoft.AspNetCore.OpenApi` (built into ASP.NET Core 9) → Swagger UI, generated from the same minimal-API route definitions | — |
| Testing | `xUnit` + `FluentAssertions` + `FsCheck` (property-based testing, .NET's QuickCheck/`proptest`/`RapidCheck`/`eris` equivalent) + `WebApplicationFactory<T>` (ASP.NET Core's built-in in-process integration test server) | TDD — see `user_stories+tests.md` |
| SAST | Roslyn analyzers (built into `dotnet build`), `SecurityCodeScan` (dedicated security-focused Roslyn analyzer for SQLi/XSS/weak-crypto patterns), `SonarAnalyzer.CSharp` | — |
| SCA | `dotnet list package --vulnerable` — **built into the .NET CLI**, checks NuGet dependencies against the GitHub Advisory Database with no separate tool required; Trivy for containers | — |

### Frontend
| Layer | Technology | Version |
|---|---|---|
| Framework | React | 18.x (hooks, functional) |
| Language | TypeScript | 5.x |
| Build | Vite | 5.x |
| State | Zustand | — |
| Router | React Router | v6 |
| UI library | Shadcn/UI + Tailwind CSS | — |
| i18n | react-i18next + i18next | — |
| Charts / diagrams | Recharts + D3.js | — |
| Syntax highlight | Shiki | (lazy-loaded per language) |
| DOM sanitization | DOMPurify | 3.x |
| HTTP | fetch + React Query (TanStack Query v5) | — |
| Testing unit | Vitest + React Testing Library | — |
| Testing E2E | Playwright | — |
| Validation | Zod | — |
| MSW | Mock Service Worker 2 | — |

### Infrastructure
| Component | Technology |
|---|---|
| Reverse proxy | Nginx |
| Container | Docker + Docker Compose — the `api` and `worker` services are published via **Native AOT** (`dotnet publish -p:PublishAot=true`), producing a single, self-contained, JIT-free native executable in a minimal runtime-less container image, in the same spirit as `app05_go_react`'s and `app07_rust_react`'s static-binary deployments (§4 D-06) |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Loki + Prometheus (`prometheus-net.AspNetCore`) |
| Secrets | Docker Secrets / GitHub Secrets / `.env` (never committed); `dotnet user-secrets` for local dev only, never in any deployed environment |
| SAST | Roslyn + `SecurityCodeScan` + `SonarAnalyzer.CSharp` + `eslint-plugin-security` (frontend) |
| DAST | OWASP ZAP |
| SCA | `dotnet list package --vulnerable` + `npm audit` + Trivy |

---

## 3. High-Level Architecture

```
Browser (React 18 SPA, PL/EN)
        │
        │  HTTPS
        ▼
  Nginx (port 443)
   ├── /api/v1/*   ─────► `SharpGuard.Api` (ASP.NET Core Minimal API, Native AOT, port 8080)
   │                         ├── Program.cs                — Minimal API endpoint registration
   │                         ├── Endpoints/                 — endpoint group classes (Threats, Cards, Matrix, ...)
   │                         ├── Services/                   — business logic
   │                         ├── Data/                        — EF Core DbContext, entity configurations
   │                         └── Integrity/                    — YAML hash verification (an internal-visibility
   │                                                              class whose Verify() method is called ONLY
   │                                                              from the startup seeding path and the Hangfire
   │                                                              job — never from an Endpoints/ class; enforced
   │                                                              by the `internal` access modifier PLUS an
   │                                                              architecture test using NetArchTest, see D-05)
   │
   └── /*          ─────► React SPA static build (served by Nginx directly)

`SharpGuard.Worker` (same solution, separate published executable + container)
   ├── Hangfire server processing jobs (ExportCsv, ExportPdf, ReingestDeck, PeriodicReverify)
   └── shares SharpGuard.Core (Services, Data, Integrity) as a referenced project, not a copy

PostgreSQL 16   ◄── EF Core, parameterized LINQ-to-SQL (threats, cards, mitigations, users, Hangfire's own tables)
Redis 7         ◄── cross-instance cache; ASP.NET Core's built-in rate limiter handles single-instance limits in-process
```

**Where the trust boundaries are:** `SharpGuard.Api` and `SharpGuard.Worker` are two separately published executables from one solution, sharing a `SharpGuard.Core` class library project — the same OS-process-boundary pattern used since `app05_go_react`. `Integrity.Verify()` is declared `internal` to `SharpGuard.Core`, and only `SharpGuard.Worker`'s job classes (in the same assembly boundary via `InternalsVisibleTo`) and the startup seeding path can call it; `SharpGuard.Api`'s `Endpoints/` classes reference `SharpGuard.Core` only through its `public` service interfaces, which do not expose `Integrity.Verify()`. A `NetArchTest`-based architecture test (§13) additionally asserts, in CI, that no type in the `Endpoints` namespace has a dependency on the `Integrity` namespace — this is the C#-idiomatic version of the same "who can call the security-sensitive function" control every sibling from `app05_go_react` onward builds with its own language's tools.

---

## 4. Architecture Design Decisions

### D-01 — Managed memory, no `unsafe` code
The project sets `<AllowUnsafeBlocks>false</AllowUnsafeBlocks>` in every `.csproj`, making it a compile error to write an `unsafe` block anywhere in this application's own code — the C# equivalent of `app07_rust_react`'s `#![forbid(unsafe_code)]`, though `unsafe` C# and `unsafe` Rust protect against different things: Rust's `unsafe` opts out of the borrow checker's aliasing/lifetime guarantees; C#'s `unsafe` opts out of the CLR's array-bounds/type-safety checks for raw pointer arithmetic. Both are disabled here for the same reason — this application has no legitimate need for either.

### D-02 — EF Core / LINQ: always parameterized, C#-type-checked, but not schema-verified at compile time — stated precisely, not oversold
```csharp
var threats = await db.Threats
    .Where(t => t.FrameworkCode == frameworkCode && t.Severity == severity)
    .ToListAsync();
```
Every LINQ query EF Core translates to SQL is parameterized automatically — there is no code path in idiomatic EF Core usage that concatenates untrusted input into a SQL string. This is a genuine, structural SQL-injection defense, the same category `app03_python_django`'s Django ORM provides. It is **not** the same as `app05_go_react`'s `sqlc`, `app06_HASKELL_react`'s `hasql-th`, or `app07_rust_react`'s `sqlx::query!`, none of which this project claims parity with: those three verify a query's *shape* (column names, parameter types) against the live database schema *at compile time*; EF Core's LINQ provider only checks that the *C# expression* type-checks against the *C# entity model*, and a mismatch between that model and the actual database schema is a *runtime* error, not a compile-time one. Where this project genuinely needs raw SQL (none currently planned, but if ever required for a full-text-search edge case), `FromSqlInterpolated` — never `FromSqlRaw` with string concatenation — is mandated by a `SecurityCodeScan` rule (SR-02.2).

### D-03 — ASP.NET Core's built-in rate-limiting middleware
```csharp
builder.Services.AddRateLimiter(options =>
    options.AddFixedWindowLimiter("public-api", opt =>
    {
        opt.Window = TimeSpan.FromMinutes(1);
        opt.PermitLimit = 60;
    }));
```
No third-party library, no hand-rolled token bucket, no Lua script, no STM — `Microsoft.AspNetCore.RateLimiting` is a first-class ASP.NET Core 9 middleware. This is the most "batteries-included" version of the recurring rate-limiting design decision across this whole series (contrast `app04_scala_react`'s hand-built ZIO STM bucket, `app05_go_react`'s Redis Lua script, `app06_HASKELL_react`'s GHC STM, `app07_rust_react`'s `governor` crate, `app08_cpp_react`'s hand-written atomic bucket, `app09_php_WORDPRESS`'s Transients API).

### D-04 — Sealed record hierarchy + exhaustive `switch` expression for `CardKind` — the second-strongest sum-type guarantee in this series, with its exact limit stated
```csharp
public abstract record CardKind;
public sealed record TechnicalThreat(Severity Severity) : CardKind;
public sealed record DesignHarm : CardKind;

public static Severity? SeverityOf(CardKind kind) => kind switch
{
    TechnicalThreat t => t.Severity,
    DesignHarm       => null,
    // no `_ =>` default arm — an exhaustive switch expression over a sealed hierarchy
};
```
If a future third `CardKind` subtype were added and this `switch` expression were not updated, the compiler emits **warning CS8509** ("the switch expression does not handle all possible values"). This project's `.editorconfig` sets `dotnet_diagnostic.CS8509.severity = error` and every `.csproj` sets `<WarningsAsErrors>CS8509</WarningsAsErrors>`, turning that warning into a build failure. **The honest limit of this guarantee, stated plainly:** unlike Rust's `match` or Haskell's `case` (where non-exhaustiveness is an unconditional language-level error with no configuration flag to disable it), C#'s exhaustiveness check is a *warning promoted to an error by explicit project configuration* — a future contributor could, in principle, remove that configuration line and silently regain the ability to ship non-exhaustive matches. This project's `SEC REVIEW` checklist (`SDLC_analysis.md`) includes verifying that configuration is present on every relevant `.csproj`, precisely because it is not a language-level invariant the way Rust's/Haskell's is.

### D-05 — `internal` visibility + `NetArchTest` as the least-privilege enforcement mechanism
`SharpGuard.Core.Integrity.Verify()` is declared `internal`; `SharpGuard.Api` and `SharpGuard.Worker` are separate assemblies, so C#'s own access-modifier system already prevents `SharpGuard.Api`'s `Endpoints/` classes from referencing it directly across the assembly boundary **unless** `SharpGuard.Core` explicitly grants `[InternalsVisibleTo("SharpGuard.Api")]` — which this project's `AssemblyInfo` does **not** do; only `SharpGuard.Worker` receives that grant. A `NetArchTest`-based test (`ArchitectureTests.EndpointsDoNotDependOnIntegrity`) additionally asserts this at the type-dependency-graph level in CI, catching the case where a future contributor might add the `InternalsVisibleTo` grant to the wrong assembly. This combination — a real compiler-enforced assembly boundary, backed by an architecture test for the one way that boundary could be misconfigured — is the same category of guarantee `app05_go_react`'s `internal/` package plus `depguard` and `app06_HASKELL_react`'s module export list provide, and materially stronger than `app08_cpp_react`'s or `app09_php_WORDPRESS`'s build-graph-script-only equivalents.

### D-06 — Native AOT deployment
`dotnet publish -p:PublishAot=true` produces a single, self-contained native executable with no JIT compilation at runtime and no dependency on a separately-installed .NET runtime in the container image — directly comparable to `app05_go_react`'s static Go binary and `app07_rust_react`'s static Rust binary, and a deliberate departure from the traditional "ASP.NET Core needs the shared framework installed in the container" deployment model every reader might expect from a C#/.NET app. This plan states the trade-off honestly: Native AOT disables runtime reflection-based features (some third-party library integrations, dynamic proxy generation) that this application does not use, so the constraint costs nothing here, but it is a real constraint other .NET projects would need to evaluate.

### D-07 — Smart-constructed record types for security-sensitive identifiers
```csharp
public readonly record struct OwaspRef
{
    public string Value { get; }
    private OwaspRef(string value) => Value = value;
    public static Result<OwaspRef> Create(string raw, IOwaspRefAllowlist allowlist) =>
        allowlist.Contains(raw) ? Result.Success(new OwaspRef(raw)) : Result.Failure<OwaspRef>("Unknown OWASP reference");
}
```
A raw `string` cannot be used where an `OwaspRef` is expected without going through `OwaspRef.Create`, which validates against the allowlist — the same newtype-plus-smart-constructor pattern every sibling from `app05_go_react` onward uses in its own language's idiom, expressed here with a C# `readonly record struct` (a zero-allocation value type).

### D-08 — `YamlDotNet`'s strict-by-default deserialization
```csharp
var deserializer = new DeserializerBuilder()
    .WithNamingConvention(CamelCaseNamingConvention.Instance)
    .Build(); // deliberately NOT calling .IgnoreUnmatchedProperties() — the default (strict) behavior is what this project wants
```
Unlike every sibling's equivalent decision (Go's `KnownFields(true)`, Haskell's `deny_unknown_fields`-style derive, Rust's `#[serde(deny_unknown_fields)]`, C++'s and PHP's hand-written key-enumeration functions — all of which require *opting in* to strictness), `YamlDotNet`'s default `Deserializer` **already rejects unrecognized properties** unless `.IgnoreUnmatchedProperties()` is explicitly called to loosen it. This project simply never calls that method — the strict behavior this whole series has had to build, derive, or hand-write in every other language is, here, the library's out-of-the-box default.

### D-09 — react-i18next with plain-text-only translation values (shared pattern)
Same as every sibling app: `pl.json`/`en.json` values are plain text only. `sg_locale` in `localStorage`; `Accept-Language` set by a fetch interceptor, allowlisted to `pl`/`en` server-side.

---

## 5. Data Model

### 5.1 Core enums and the `CardKind` hierarchy (`SharpGuard.Core/Domain/`)
```csharp
public enum Severity { Critical, High, Medium, Low, Info }
public enum StrideCategory { S, T, R, I, D, E }
public enum SampleType { AttackDemo, Defense }
public enum CodeLanguage { Python, Java, Go, Scala, Lua }
public enum MitigationType { Preventive, Detective, Corrective, Compensating }
public enum Effort { Low, Medium, High }
public enum Effectiveness { Partial, Significant, Full }
public enum RelationshipType { Equivalent, Related, ParentChild, MapsTo }

// See D-04 — this project's strongest type-level security guarantee, with its exact limit stated.
public abstract record CardKind;
public sealed record TechnicalThreat(Severity Severity) : CardKind;
public sealed record DesignHarm : CardKind;
```

### 5.2 Framework
```csharp
public record Framework(
    FrameworkId Id,
    string Code,             // "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS", ...
    string Name,
    string Version,
    string Description,
    string ReferenceUrl
);
```

### 5.3 Threat
```csharp
public record Threat(
    ThreatId Id,
    FrameworkId FrameworkId,
    string Code,              // "LLM01:2025", "A03:2021", "AML.T0051"
    string Title,
    Severity Severity,
    string Category,
    string Description,
    string AttackVector,
    string AttackSurface,
    IReadOnlyList<StrideCategory> Stride,
    IReadOnlyList<string> Tags
);
```

### 5.4 ThreatTranslation *(i18n)*
```csharp
public enum Locale { Pl, En }

public record ThreatTranslation(
    ThreatId ThreatId,
    Locale Locale,
    string Title,
    string Description,
    string AttackVector
);
```

### 5.5 CornucopiaCard *(all six YAML decks — see D-04 for `CardKind`)*
```csharp
public record CornucopiaCard(
    CardId CardId,                       // strong-typed wrapper, e.g. "VE3", "LLM4", "SCO2"
    SuitCode SuitCode,                   // strong-typed wrapper
    string SuitName,
    Edition Edition,                      // Webapp | Mobileapp | Companion | Eop | Mlsec | Dbd
    CardValue Value,                      // Num2..Num10 | Jack | Queen | King | Ace
    CardKind Kind,                        // D-04: TechnicalThreat(Severity) | DesignHarm
    string DescriptionEn,
    string DescriptionPl,
    string? MiscNote,
    string? SourceUrl,
    IReadOnlyList<OwaspRef> OwaspRefs,     // D-07: smart-constructed against an allowlist
    IReadOnlyList<MitreRef> MitreRefs,
    string ContentSha256
);
```

### 5.6 Mitigation
```csharp
public record Mitigation(
    MitigationId Id,
    ThreatId? ThreatId,
    CardId? CardId,
    string Title,
    string Description,
    MitigationType Type,
    Effort Effort,
    Effectiveness Effectiveness,
    IReadOnlyList<CodeSample> CodeSamples   // non-emptiness verified by an FsCheck property
                                              // over seed data, not the type itself — C#'s
                                              // IReadOnlyList<T> has no non-empty variant in
                                              // the BCL, the same accepted gap every sibling
                                              // without a dedicated NonEmpty type states
);
```

### 5.7 CodeSample
```csharp
public record CodeSample(
    CodeSampleId Id,
    CodeLanguage Language,
    SampleType SampleType,
    string Title,
    string Description,
    string Code,
    string FrameworkHint,   // "ASP.NET Core Minimal API + EF Core", "Spring Boot 3.3", "Django ORM"...
    string VersionNote
);
```

### 5.8 CrossReference
```csharp
public record CrossReference(
    CrossReferenceId Id,
    ThreatId SourceThreatId,
    ThreatId TargetThreatId,
    RelationshipType RelationshipType,
    string Description
);
```

### 5.9 ContentHash
```csharp
public record ContentHash(
    string FileName,
    string Sha256Hash,
    DateTimeOffset VerifiedAt,
    bool IsValid,
    string VerifiedBy = "sharpguard-integrity-verifier"
);
```

---

## 6. Development Phases

*(Numbering aligned with the Agile/Scrum sprint plan in `SDLC_analysis.md`, §4.)*

### Phase 1 — Foundation (Sprints 1–2)
Covers: US-01, US-02
- [ ] `dotnet new` solution: `SharpGuard.Core` (class library), `SharpGuard.Api`, `SharpGuard.Worker` (executables), `SharpGuard.Tests`
- [ ] `<Nullable>enable</Nullable>`, `<AllowUnsafeBlocks>false</AllowUnsafeBlocks>`, `<WarningsAsErrors>CS8509</WarningsAsErrors>` in every `.csproj`
- [ ] ASP.NET Core Minimal API bootstrap; `AddRateLimiter` (D-03); security headers middleware (CSP, HSTS, X-Frame-Options)
- [ ] Docker Compose: PostgreSQL 16 + Redis 7 + `api` + `worker` + Nginx
- [ ] EF Core `DbContext` + initial migration for models in §5.1–5.9
- [ ] Seed hosted service loading OWASP Web/LLM/Agentic/API, MITRE ATLAS, CompTIA SecAI+ from JSON
- [ ] `GET /api/v1/frameworks`, `GET /api/v1/threats` (paginated)
- [ ] JWT Bearer middleware — editor/admin roles
- [ ] `Microsoft.AspNetCore.OpenApi` → `/swagger`
- [ ] React scaffold: Vite + Shadcn/UI + Tailwind + Zustand

**Security checkpoint:** `dotnet build` with zero warnings (nullable + `CS8509` both promoted to errors); `SecurityCodeScan` zero findings; security-headers middleware active on every response.

### Phase 2 — Core Threat Browser (Sprints 3–4)
Covers: US-02, US-03, US-04
- [ ] LINQ-to-EF-Core queries: filter threats by framework, severity, stride, category, tag, q
- [ ] `GET /api/v1/threats/{id}` with nested mitigations + code samples
- [ ] React `ThreatBrowserPage`, `ThreatDetailPage` (tabs: Overview | Attack Vectors | Mitigations | Code | Cross-References)
- [ ] `GET /api/v1/cross-references`
- [ ] React `MatrixPage`

**Security checkpoint:** `SecurityCodeScan`'s SQL-injection rule confirms no `FromSqlRaw` with concatenated input anywhere in the codebase.

### Phase 3 — Card Decks & Content Integrity (Sprints 5–7)
Covers: US-05–US-12, US-19
- [ ] `Cards/CardLoader.cs` — `YamlDotNet` strict deserialization (D-08) for **all six** `docs/OWASP_stories/*.yaml` files
- [ ] `Integrity.Verify()` — SHA-256 vs `data/hashes.json`; `internal`-visibility isolated per D-05
- [ ] Card suit browsers: FRE, LLM, AAI, CLD (Companion), SP/TA/RE/ID/DS/EP (STRIDE), EMR/EIR/EOR/EDR (MLSec), PC/AA/NS/RS/CRM/CM (Mobile), VE/AT/SM/AZ/CR/C (Website App), **SCO/ARC/AGE/TRU/POR (Digital-by-Default Harms, US-19 — in scope here, not bolted on later)**
- [ ] `CardKind` (D-04) exhaustively matched everywhere via `switch` expressions; `CS8509`-as-error enforced
- [ ] `AttackDemoWarning` confirmation modal before rendering `AttackDemo` code samples

**Security checkpoint:** malformed/unknown-field YAML throws `YamlException` by default (an `FsCheck` property generates random extra fields and asserts the exception); content hash mismatch aborts ingestion inside a single EF Core transaction.

### Phase 4 — Code Samples: 5 Languages (Sprints 7–9)
Covers: US-13–US-16
- [ ] Code sample seed data for every mitigation × 5 languages (Python, Java, Go, Scala, Lua)
- [ ] Attack-demo / defense sub-tabs, red-bordered warning label
- [ ] MITRE ATLAS Kill-Chain timeline (Recharts)

### Phase 5 — i18n Polish ↔ English (Sprint 9–10)
Covers: US-11 (folded into every story's acceptance criteria, see §15 note)
- [ ] `Accept-Language` middleware — allowlist `pl`/`en`, default `en` server-side (SR-12.1 rationale)
- [ ] `ThreatTranslation` served per-locale; `DescriptionPl` fallback to English with an "EN" badge if missing
- [ ] React `react-i18next`; `LanguageToggle`; `sg_locale` in `localStorage`
- [ ] Code samples **never** translated
- [ ] CI check: i18n key-parity test fails the build on any missing key

### Phase 6 — Search, Export, Matrix Completion (Sprints 10–12)
Covers: US-17, US-18
- [ ] PostgreSQL full-text search (`tsvector` + GIN index) via EF Core's `EF.Functions`
- [ ] Hangfire-based export (`ExportCsvJob`, `ExportPdfJob`), status visible on the Hangfire dashboard (capability-gated) as well as via the public poll endpoint
- [ ] `/matrix/llm`, `/matrix/agentic`, `/matrix/mobile-vs-web`, `/stride-heatmap`, `/matrix/digital-harms`
- [ ] `AddRateLimiter` policy (D-03): 60 req/min/IP on all public list endpoints

### Phase 7 — Hardening, Testing & Release (Sprints 12–14)
Covers: full regression across US-01–US-19
- [ ] `xUnit` + `FsCheck` properties, coverage ≥ 85% on `SharpGuard.Core/Services` (via `coverlet`)
- [ ] `WebApplicationFactory<T>`-based integration tests for every endpoint
- [ ] `NetArchTest` architecture tests (D-05) in CI
- [ ] Playwright (TypeScript) E2E — one scenario per user story
- [ ] Roslyn/`SecurityCodeScan`/`SonarAnalyzer.CSharp` + `dotnet list package --vulnerable` in CI, zero HIGH findings
- [ ] OWASP ZAP full active scan against staging
- [ ] Production images: `api`/`worker` published via Native AOT (D-06), minimal runtime-less container base

---

## 7. API Endpoint Map

### Framework & Threat (base)
```
GET  /api/v1/frameworks
GET  /api/v1/frameworks/{code}
GET  /api/v1/threats?framework=&severity=&stride=&category=&tag=&q=
GET  /api/v1/threats/{id}
GET  /api/v1/threats/{id}/mitigations
GET  /api/v1/threats/{id}/code-samples?language=go
```

### Cornucopia Card Suits (US-05–US-12, US-19)
```
GET  /api/v1/threats?suit=fre                   — Frontend cards (US-05)
GET  /api/v1/threats?suit=llm                   — LLM cards (US-06)
GET  /api/v1/threats?suit=aai                   — Agentic AI cards (US-07)
GET  /api/v1/threats?suit=cld                   — Cloud cards (US-07, folded into DevOps page)
GET  /api/v1/threats/stride/categories          — 6 STRIDE categories (US-08)
GET  /api/v1/threats?suit=sp|ta|re|id|ds|ep     — individual STRIDE suits
GET  /api/v1/threats/mlsec/categories           — 4 MLSec categories (US-09)
GET  /api/v1/threats?suit=emr|eir|eor|edr       — individual MLSec suits
GET  /api/v1/threats/mobile/suits               — 6 Mobile suits (US-10)
GET  /api/v1/threats?suit=pc|aa|ns|rs|crm|cm    — individual Mobile suits
GET  /api/v1/threats?suit=ve|at|sm|az|cr|c      — Website App Cornucopia suits (US-12)
GET  /api/v1/threats?suit=dvo                   — DevOps cards (US-11)
GET  /api/v1/threats?suit=bot                   — Automated Threat cards (US-11)
GET  /api/v1/threats/digital-harms/suits        — 5 Digital-by-Default suits (US-19)
GET  /api/v1/threats?suit=sco|arc|age|tru|por   — individual Digital-by-Default suits (US-19)
```

### Matrix & Visualization
```
GET  /api/v1/matrix/llm
GET  /api/v1/matrix/agentic
GET  /api/v1/matrix/mobile-vs-web
GET  /api/v1/stride-heatmap
GET  /api/v1/cross-references
GET  /api/v1/cross-references?sourceCode=LLM01
```

### Search & Export
```
GET  /api/v1/search?q=prompt+injection
GET  /api/v1/export?format=csv&framework=OWASP_LLM     (enqueues a Hangfire job, returns 202 + poll URL)
GET  /api/v1/export/status/{jobId}
```

### Admin CRUD (JWT — Admin role)
```
POST   /api/v1/admin/threats
PUT    /api/v1/admin/threats/{id}           — HtmlSanitizer applied (D-07-adjacent, see requirements.md SR-03)
DELETE /api/v1/admin/threats/{id}
POST   /api/v1/admin/code-samples
PUT    /api/v1/admin/code-samples/{id}
```
`CornucopiaCard` records (all six decks) have **no** admin write endpoint at all — no such Minimal API route is registered anywhere in `SharpGuard.Api`. They are read-only, written only by the seed hosted service / the `ReingestDeckJob`.

### Health & Ops
```
GET  /api/v1/health                          — ASP.NET Core Health Checks
GET  /api/v1/metrics                         — Prometheus scrape endpoint
GET  /api/v1/admin/integrity/status          — [JWT admin] last verification run per YAML file
/hangfire                                     — [JWT admin] Hangfire's built-in job dashboard
```

---

## 8. React Page & Component Structure

```
Routes:
  /                               → DashboardPage
  /frameworks                     → FrameworkBrowserPage
  /frameworks/:code               → FrameworkDetailPage
  /frameworks/website-app         → WebsiteAppCornucopiaPage   (US-12)
  /frameworks/frontend-security   → FrontendSecurityPage       (US-05)
  /frameworks/llm-security        → LlmSecurityPage            (US-06)
  /frameworks/agentic-ai          → AgenticAiPage               (US-07)
  /frameworks/stride               → StrideCataloguePage         (US-08)
  /frameworks/ml-security          → MlSecurityPage              (US-09)
  /frameworks/mobile-security      → MobileSecurityPage          (US-10)
  /frameworks/devops-security      → DevOpsSecurityPage          (US-11, includes CLD section)
  /frameworks/digital-harms        → DigitalHarmsPage             (US-19)
  /threats                         → ThreatBrowserPage
  /threats/:id                     → ThreatDetailPage
  /matrix, /matrix/llm, /matrix/agentic, /matrix/mobile-vs-web
  /stride-heatmap                  → StrideHeatmapPage (ProtectedRoute)
  /search                          → SearchResultsPage
  /about                           → AboutPage

Components:
  ThreatCard, CornucopiaCard, CodeSamplePanel, SeverityBadge,
  DesignHarmBadge (US-19 — its TypeScript type has no severity field),
  BotWarningModal (US-11), StrideHeatmap, MatrixTable, LanguageToggle
```

---

## 9. C# Solution Layout

```
backend/
├── SharpGuard.sln
├── SharpGuard.Core/                        ← class library, referenced by Api and Worker
│   ├── Domain/
│   │   ├── Enums.cs                        ← Section 5 enums
│   │   ├── CardKind.cs                     ← sealed record hierarchy (D-04)
│   │   └── StrongTypes.cs                  ← ThreatId, CardId, OwaspRef, MitreRef, etc. (D-07)
│   ├── Services/                           ← business logic, thin over Data/
│   ├── Data/
│   │   ├── SharpGuardDbContext.cs          ← EF Core DbContext
│   │   └── Configurations/                  ← IEntityTypeConfiguration<T> per entity
│   ├── Cards/
│   │   └── CardLoader.cs                   ← YamlDotNet decode, calls Integrity.Verify (D-08)
│   └── Integrity/
│       └── Integrity.cs                    ← internal Verify() — isolated per D-05
├── SharpGuard.Api/
│   ├── Program.cs                          ← Minimal API bootstrap, DI, middleware pipeline
│   ├── Endpoints/
│   │   ├── FrameworkEndpoints.cs
│   │   ├── ThreatEndpoints.cs
│   │   ├── CardEndpoints.cs
│   │   ├── MatrixEndpoints.cs
│   │   ├── SearchEndpoints.cs
│   │   ├── ExportEndpoints.cs
│   │   └── AdminEndpoints.cs
│   └── Middleware/
│       ├── SecurityHeadersMiddleware.cs
│       └── (rate limiting configured in Program.cs via AddRateLimiter)
├── SharpGuard.Worker/
│   ├── Program.cs                          ← Hangfire server bootstrap
│   └── Jobs/
│       ├── ExportCsvJob.cs
│       ├── ExportPdfJob.cs
│       ├── ReingestDeckJob.cs
│       └── PeriodicReverifyJob.cs
└── SharpGuard.Tests/
    ├── Unit/                                ← xUnit
    ├── Property/                             ← FsCheck
    ├── Integration/                           ← WebApplicationFactory<T>
    └── Architecture/                          ← NetArchTest (D-05)

frontend/                              ← React 18 + TS + Vite (mirrors app08_cpp_react §8)

data/
├── owasp_web_top10.json
├── owasp_llm_top10.json
├── owasp_agentic_top10.json
├── mitre_atlas.json
├── comptia_secai.json
├── cornucopia/
│   ├── webapp-cards-3.0-en.yaml
│   ├── companion-llm-cards-1.0-en.yaml
│   ├── mobileapp-cards-1.1-en.yaml
│   ├── stride-eop-cards-5.0-en.yaml
│   ├── mlsec-cards-1.0-en.yaml
│   ├── dbd-cards-1.0-en.yaml          ← Digital-by-Default Harms (US-19)
│   └── translations/
│       ├── pl.cards.json
│       └── en.cards.json
├── hashes.json
├── mitre-atlas-allowlist.json
├── ref-allowlists.json
└── code_samples/{python,java,go,scala,lua}/

e2e/
└── *.spec.ts                          ← Playwright, one file per user story (us01..us19)

docker-compose.yml
```

---

## 10. Code Sample Strategy

Every `Mitigation` ships exactly **five** `CodeSample` records (one per language). As in every sibling since `app07_rust_react`, completeness is verified by an `FsCheck` property over the seeded dataset rather than a type-level guarantee — `IReadOnlyList<T>` in the BCL has no non-empty variant.

| Language | Primary framework/library used in samples |
|---|---|
| Python | Django ORM / FastAPI + Pydantic |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | `chi` + `sqlc` + `pgx` |
| Scala | Akka HTTP / http4s, Slick 3.x, ZIO 2 |
| Lua | OpenResty / NGINX Lua, `lua-resty-jwt`, LuaSQL |

```
sampleType: AttackDemo   // VULNERABLE — do not use in production
sampleType: Defense      // SECURE pattern, with a one-line WHY comment
```

**A note on Java as a code-sample language versus this app's own C#:** several code samples for injection-related mitigations pair naturally with a side-by-side comparison against this very application's own EF Core usage (D-02) — Java's Spring Data JPA and C#'s EF Core share enough conceptual DNA (both are managed-runtime, GC'd, mainstream enterprise ORMs) that the Code Samples tab, for the relevant threats, cross-links to this app's own source as an implicit sixth example without adding C# as a seventh formal sample language (the brief specifies five: Python, Java, Go, Scala, Lua).

---

## 11. Security Data Coverage Plan

| Framework | Coverage target | Source |
|---|---|---|
| OWASP Web Top 10 (2021) | A01–A10, all 10 | seeded JSON, cross-refs to `VE/AT/SM/AZ/CR/C` cards |
| OWASP LLM Top 10 (2025) | LLM01–LLM10, all 10 | seeded JSON + `LLM` suit (Companion) |
| OWASP Agentic AI Top 10 (2026) | AgentAI01–10 | seeded JSON + `AAI` suit (Companion) |
| OWASP API Security Top 10 | API1–API10 | seeded JSON |
| OWASP Client-Side Top 10 | C01–C10 | `FRE` suit (Companion) |
| OWASP CI/CD Security Top 10 | CICD-SEC-01–10 | `DVO` suit (Companion) |
| OWASP Automated Threats (OAT) | ≥ 13 of 21 | `BOT` suit (Companion) |
| Cloud misconfiguration (A05/A01:2021) | — | `CLD` suit (Companion), no dedicated OWASP Top 10 of its own |
| OWASP MASVS 2.0 | all 7 categories | `PC/AA/NS/RS/CRM/CM` suits (Mobile) |
| STRIDE | S,T,R,I,D,E — all 6 | `SP/TA/RE/ID/DS/EP` suits (EoP v5.0) |
| Elevation of MLSec | Model/Input/Output/Dataset Risk | `EMR/EIR/EOR/EDR` suits |
| MITRE ATLAS | ≥ 15 techniques across ≥ 5 tactics | seeded JSON, cross-referenced from LLM/AAI/mlsec cards |
| CompTIA Security+ / SecAI+ | ≥ 20 topics | seeded JSON, from `docs/Security Architects...md` mapping table |
| OWASP A04:2021 Insecure Design — Digital-by-Default Harms | Scope/Architecture/Agency/Trust/Porosity | `SCO/ARC/AGE/TRU/POR` suits (US-19) — **not** a technical-vulnerability deck, see D-04 |

---

## 12. Cornucopia Content Pipeline

```
data/cornucopia/
├── webapp-cards-3.0-en.yaml          → VE, AT, SM, AZ, CR, C
├── companion-llm-cards-1.0-en.yaml   → LLM, FRE, DVO, BOT, CLD, AAI
├── mobileapp-cards-1.1-en.yaml       → PC, AA, NS, RS, CRM, CM
├── stride-eop-cards-5.0-en.yaml      → SP, TA, RE, ID, DS, EP
├── mlsec-cards-1.0-en.yaml           → EMR, EIR, EOR, EDR
├── dbd-cards-1.0-en.yaml             → SCO, ARC, AGE, TRU, POR, COR, WC (US-19)
└── translations/
    ├── pl.cards.json
    └── en.cards.json

data/hashes.json                       ← SHA-256 per YAML file
data/mitre-atlas-allowlist.json
data/ref-allowlists.json
```

**Workflow:**
1. PR touching `data/cornucopia/*.yaml` → CODEOWNERS `@security-team`, min. 2 approvals.
2. CI job `yaml-content-integrity`: `YamlDotNet`'s strict-by-default deserialization (D-08) must succeed against every file (any unrecognized shape throws `YamlException`, not partial data) + injection-pattern grep + ref-allowlist validation.
3. Post-merge: a `hash-generator` CI step updates `data/hashes.json`.
4. The seed hosted service and the `ReingestDeckJob` both call `Integrity.Verify()` — on mismatch, ingestion aborts inside a single EF Core transaction (no partial writes) and a `SEC-CARD-HASH-MISMATCH` structured log line fires via Serilog, which Loki alerts on.

---

## 13. Risk Register

| Risk | Mitigation |
|---|---|
| `CS8509`-as-error configuration silently removed from a `.csproj` in a future refactor | SEC REVIEW checklist item verifying `<WarningsAsErrors>CS8509</WarningsAsErrors>` presence on every relevant project; a CI step greps all `.csproj` files for it |
| EF Core migration drifts from the actual database schema (no compile-time schema check exists) | `dotnet ef migrations` applied via CI in a dedicated schema-check job against a real Postgres instance before merge |
| YAML card files tampered in a PR | CODEOWNERS review + `Integrity.Verify()` SHA-256 check, fail-secure |
| Digital-by-Default Harms deck misread as CVE severity | `CardKind` sealed record hierarchy + `CS8509`-as-error (D-04) — strong but configuration-dependent, monitored accordingly |
| Polish translations drift from English source | `ContentSha256` stored per card; translation table flags staleness on English-text change |
| `Integrity.Verify()` called from an unintended assembly | `internal` visibility + `NetArchTest` architecture test (D-05) |
| Hangfire job payload injection | Job arguments are strongly-typed C# method parameters (Hangfire serializes/deserializes them via its own type-aware serializer), not a raw untyped dictionary |
| Native AOT incompatibility surfacing late (a library using unsupported reflection) | `dotnet publish -p:PublishAot=true` run in CI on every PR, not just at release time, so AOT-incompatibility warnings surface immediately |
| Attack-demo code confused with production-safe code | Red border + `AttackDemo` badge + confirmation modal before code is shown/copied |
| Bot scraping the full catalogue | Built-in ASP.NET Core rate limiter, 60 req/min/IP (D-03) |

---

## 14. Directory Layout

```
app10_csharp_react/
├── PLAN.md
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
├── backend/            ← see §9 for full internal layout
├── frontend/            ← React 18 + TS + Vite (mirrors app08_cpp_react structure)
├── e2e/
└── docker-compose.yml
```

---

## 15. User Stories — Complete List

*(Full acceptance criteria and TDD test plans in `user_stories+tests.md`. All six YAML decks — including Digital-by-Default Harms — are covered from the start of this plan.)*

| ID | Role | Need | Goal |
|---|---|---|---|
| US-01 | security engineer | browse security framework catalogue | single access point to all standards |
| US-02 | security engineer | filter threats by framework, severity, STRIDE, tag, q | quickly find threats relevant to my project |
| US-03 | security engineer | see threat details with mitigations and code samples | understand how to implement protection |
| US-04 | CompTIA SecAI+ student | see how LLM01 Prompt Injection maps to MITRE ATLAS AML.T0051 | understand cross-framework dependencies |
| US-05 | React/frontend developer | browse Cornucopia FRE cards (Companion) | map client-side attack scenarios to mitigations |
| US-06 | ML engineer / AI architect | explore OWASP LLM Top 10 via Cornucopia LLM cards with interactive matrix | understand prompt injection, poisoning, excessive agency |
| US-07 | agentic AI / cloud developer | study AAI + CLD cards | design human-in-the-loop safeguards; spot IAM/storage misconfiguration |
| US-08 | security architect / threat modeler | use STRIDE EoP catalogue with interactive heatmap | run structured threat modeling session |
| US-09 | data scientist / ML security engineer | browse MLSec cards (EMR/EIR/EOR/EDR) with MITRE ATLAS refs | identify adversarial ML, model theft, data poisoning |
| US-10 | Android/iOS developer | see OWASP MASVS threats via Mobile App cards | understand mobile vs. web security differences |
| US-11 | DevSecOps engineer | browse DVO/CLD/BOT cards | protect CI/CD pipelines, spot cloud misconfig, defend against bots |
| US-12 | backend developer | browse Website App Cornucopia cards (VE/AT/SM/AZ/CR/C) | map classic OWASP Web Top 10 attack scenarios to mitigations |
| US-13 | Python developer | see a Python code sample for each mitigation | copy a secure implementation pattern |
| US-14 | Java developer | see a Java code sample for each mitigation | compare against this app's own C#/EF Core idioms |
| US-15 | Scala developer | find Scala code samples for supply-chain attacks | implement SCA in a Scala pipeline |
| US-16 | Lua/OpenResty developer | see Lua examples for rate limiting preventing LLM DoS | configure NGINX guardrails for an LLM API proxy |
| US-17 | pentester | search a term and find related threats with defenses | assemble a client test checklist |
| US-18 | team lead | export the filtered threat list to CSV/PDF | include it in a risk register |
| US-19 | public-sector product owner / GRC reviewer | browse the "Digital-by-Default Harms" deck (SCO/ARC/AGE/TRU/POR), clearly separated from technical decks | assess digital-exclusion and opaque-design risk, map to A04:2021 |

*(The Polish↔English language switch is folded into every story's acceptance criteria per FR-18 in `requirements.md` rather than numbered separately here.)*

---

## 16. Milestones & Acceptance Criteria

| Milestone | Deliverable | Done when |
|---|---|---|
| M1 | Working skeleton | `docker compose up` → `SharpGuard.Api` health check 200; React SPA loads |
| M2 | Full data seed | All frameworks + threats + mitigations in DB; API returns correct counts |
| M3 | All six card decks ingested | `Integrity.Verify()` reports `IsValid = true` for all six YAML files, including `dbd-cards-1.0-en.yaml` |
| M4 | Code samples complete | Every mitigation has 5 language samples visible on Threat Detail |
| M5 | Matrix + heatmap | Cross-reference table renders; STRIDE heatmap shows coverage % |
| M6 | i18n complete | PL/EN toggle everywhere; i18n key-parity CI check passes |
| M7 | Search + export work | Full-text search returns highlighted results; CSV/PDF export completes via Hangfire, visible on `/hangfire` dashboard |
| M8 | Digital-by-Default Harms | `DigitalHarmsPage` renders all 5 suits with `DesignHarmBadge`; A04:2021 cross-reference visible; every `CardKind` switch expression confirmed exhaustive (`CS8509`-as-error passing) |
| M9 | Security hardening | Roslyn/`SecurityCodeScan`/`SonarAnalyzer.CSharp`/`dotnet list package --vulnerable` zero HIGH; ZAP full scan zero HIGH; Native AOT publish succeeds with zero incompatibility warnings |
| M10 | Tests green | ≥ 90% of TDD test list in `user_stories+tests.md` passing in CI |
