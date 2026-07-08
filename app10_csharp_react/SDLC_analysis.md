# SharpGuard 2026 — SSDLC / SDLC Analysis

**Version:** 1.0
**Date:** 2026-07-07
**Document type:** Secure Software Development Lifecycle (SSDLC) analysis, mapped against the classic SDLC
**Scope:** Full lifecycle analysis of the application defined in `PLAN.md`, `requirements.md`, and `user_stories+tests.md`
**Methodology:** Agile — Scrum for planning/cadence, Kanban overlay for the engineering + security workflow
**Dotyczy:** US-01 – US-19 / C# / .NET 9 (ASP.NET Core Minimal API + EF Core) + React 18

---

## Executive Summary

SharpGuard 2026 carries the same double obligation as its sibling projects (`app01_react` through `app09_php_WORDPRESS`): it **teaches** OWASP/MITRE ATLAS/CompTIA SecAI+ security content, so it must itself **be** secure — an app about SQL Injection that is vulnerable to SQL Injection trains people with a false sense of authority. This project's SSDLC emphasis follows from where C#/.NET sits in this series' recurring comparison:

1. **Memory safety, without the ownership-model trade-offs `app07_rust_react` has to manage.** The CLR's garbage-collected, bounds-checked memory model closes the same CWE Top 25 memory-corruption class `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react` each close, achieved via a different mechanism than any of them (a managed runtime rather than compile-time ownership tracking or a pure functional runtime) — and `<AllowUnsafeBlocks>false</AllowUnsafeBlocks>` (`PLAN.md` D-01) removes even the CLR's own escape hatch from this project's own code.
2. **A near-Rust/Haskell sum-type exhaustiveness guarantee, with its exact limit named precisely.** C#'s sealed record hierarchies plus `switch`-expression exhaustiveness checking (`CS8509`) give the Digital-by-Default Harms deck's "cannot carry a severity" rule (`PLAN.md` D-04) real compile-time teeth — but only because this project promotes that warning to an error via explicit project configuration, a setting that could, in principle, be quietly removed. This document treats that as an ongoing, monitored risk (§6.2), not a one-time architectural decision.
3. **Unusually toolchain-integrated SAST/SCA, and this plan uses what's built in rather than reaching past it.** `dotnet list package --vulnerable` (SCA, built into the CLI) and Roslyn analyzers producing nullable-reference-type warnings (SAST, built into `dotnet build` itself) mean several security-testing activities other siblings had to wire up as separate tools are, here, already running on every developer's machine before CI even starts.
4. **The same content-integrity and i18n obligations as every sibling app still apply.** Six externally-authored YAML card decks, including the non-technical Digital-by-Default Harms deck, are ingested as security-sensitive data, and the application is fully bilingual (PL/EN) with its own translation-review supply chain — unaffected by any of the above.

The lifecycle below follows **Agile Scrum for cadence, with a Kanban board carrying explicit security-gate columns**, per the requested focus on Agile/Scrum/Kanban.

---

## SSDLC vs Classic SDLC — Where Security Moves

```
Classic SDLC (security bolted on late):
  Planning & Analysis → Design → Implementation → Testing → Deployment → Maintenance
                                                        ↑
                                          Security testing added HERE — too late,
                                          architecture and code are already frozen.

SSDLC ("Shift Left" — security integrated at every stage, several checks already
   running before a PR is even opened):
  Secure          Secure       Secure            Secure          Secure           Secure
  Planning &  →   Design   →   Implementation →  Testing     →   Deployment   →   Maintenance
  Analysis        │            │                 │               │                │
    ↑             ↑            ↑                 ↑               ↑                ↑
  Threat model   internal +   Nullable ref      Roslyn/         Native AOT       Runtime
  + Compliance   NetArchTest  types + CS8509-   SecurityCode    static binary;   monitoring +
  mapping        (D-05) +     as-error at        Scan + dotnet   ldd-verified     patch cadence +
  (OWASP/ATLAS/  least priv.  dotnet-build       list package    minimal image    card-deck +
  SecAI+/GDPR)                time; EF Core       --vulnerable                     translation
                              parameterizes       (already                         integrity +
                              by default          running                          CS8509-config
                                                   locally)                         review
```

Both models describe the **same six stages**; SSDLC's contribution is that security activities happen *inside* each stage rather than as a single gate before release. This project's version of the diagram is notable for how many of its "Testing" and "Implementation" boxes are already active on a developer's own machine during `dotnet build`, before any CI pipeline runs at all — a genuine "shift left," though this document is careful to note (§Phase 7) that "shifted left in the toolchain" is not the same claim as "compiler-enforced with no configuration dependency," which is why FR-19.2's guarantee still gets its own monitored risk entry.

---

## Agile Framework: Scrum for Cadence, Kanban for Flow

### Scrum structure

```
Sprint length:      2 weeks
Team size:           3–4 C#/.NET engineers, 1 frontend/React engineer, 1 QA/security engineer,
                      1 PL translator part-time
Velocity target:     ~20–24 story points/sprint — comparable to app05_go_react's and
                      app07_rust_react's estimates, reflecting .NET's mature tooling and the
                      large pool of enterprise C# developers this course's Java-background
                      audience can draw an especially direct comparison to (app01_react/
                      app02_angular are Java/Spring Boot; this app is, in a real sense, "the
                      same kind of developer, a different mainstream managed-runtime language")
Total duration:      14 sprints (~28 weeks) — matches PLAN.md §6 phases

Ceremonies:
  Sprint Planning        — Monday, Day 1, 2h max — pulls from the Product Backlog (PLAN.md §15 + this doc's abuse cases)
  Daily Standup          — daily, 15 min, includes a mandatory "any security blocker?" round
  Mid-Sprint Security Gate — Wednesday, Day 7, 30 min — peer review of anything touching auth,
                             Integrity's internal-visibility boundary, EF Core query construction,
                             or CardKind switch-expression exhaustiveness
  Sprint Review          — Friday, Day 10, 1h — demo includes a security angle (e.g. "here's a
                             PR that removed a switch arm and failed the build on CS8509")
  Sprint Retrospective   — Friday, Day 10, 45 min — one mandatory security-process retro item
```

### Kanban board — security-gated columns

```
BACKLOG → SPRINT → IN DEV → SEC REVIEW → I18N REVIEW → TEST → DONE

  BACKLOG       Product backlog: user stories (US-01..US-19), bugs, abuse cases (AC-01..AC-17)
  SPRINT        Committed for the current sprint
  IN DEV        Actively coded — TDD red/green cycle in progress; `dotnet build -warnaserror`
                run locally means several classes of mistake never even reach a commit
  SEC REVIEW    Mandatory gate for anything touching: auth, Integrity's internal visibility,
                EF Core query construction, CardKind exhaustiveness, or project-file
                (`.csproj`) configuration changes specifically
  I18N REVIEW   Mandatory gate for anything adding user-visible strings or card translations —
                a native Polish speaker signs off before merge
  TEST          xUnit + FsCheck + WebApplicationFactory + NetArchTest + Vitest + Playwright
  DONE          Meets the Definition of Done below

WIP limits:  IN DEV ≤ 2/dev · SEC REVIEW ≤ 3 total · I18N REVIEW ≤ 3 total · TEST ≤ 5 total
```

**A .NET-specific Kanban nuance:** because nullable-reference-type warnings and `CS8509` are surfaced by `dotnet build` itself — the same command every developer runs continuously in their IDE — a meaningful fraction of this project's "SAST" happens before a PR is even opened, the same effect `app05_go_react`'s pre-commit `golangci-lint` and `app07_rust_react`'s `cargo build` have. This project's Kanban cycle-time metric for `SEC REVIEW` is expected to be short for build-time-catchable issues, for the same reason those two siblings' were — but `SEC REVIEW` retains one item with no build-time backstop at all: verifying that the `<WarningsAsErrors>CS8509</WarningsAsErrors>` configuration itself hasn't been quietly removed from a `.csproj`, since a missing configuration line produces no warning of its own.

### Definition of Done (security- and i18n-enforced)

```
CODE QUALITY
  [ ] dotnet test passes (xUnit + FsCheck); coverage ≥ 85% on SharpGuard.Core/Services
  [ ] dotnet build -warnaserror clean (nullable reference warnings + CS8509 both promoted to errors)
  [ ] Every relevant .csproj confirmed to still declare <AllowUnsafeBlocks>false</AllowUnsafeBlocks>,
      <Nullable>enable</Nullable>, and (where applicable) <WarningsAsErrors>CS8509</WarningsAsErrors>

SECURITY GATES
  [ ] Roslyn/SecurityCodeScan/SonarAnalyzer.CSharp zero findings at or above configured severity
  [ ] dotnet list package --vulnerable --include-transitive reports zero known-vulnerable packages
  [ ] Peer security review completed for anything in the SEC REVIEW trigger list above
  [ ] No secrets committed (detect-secrets / trufflehog pre-commit hook green)
  [ ] All DB access via EF Core LINQ — no FromSqlRaw with concatenated input (SecurityCodeScan rule)
  [ ] Integrity.Verify()'s internal visibility unchanged, or changed with explicit SEC REVIEW sign-off,
      confirmed by the NetArchTest suite

I18N GATES
  [ ] i18n key-parity check passes — zero missing keys in either pl.json or en.json
  [ ] Any new/changed card translation reviewed and signed off by a native Polish speaker
  [ ] No hardcoded user-visible string added outside react-i18next keys

DOCUMENTATION
  [ ] requirements.md traceability updated if scope changed
  [ ] user_stories+tests.md TDD test list updated for the story being closed
```

---

## Phase 0 — Sprint Zero: SSDLC & Tooling Setup

### 0.1 Threat modeling session (dogfooding the project's own STRIDE deck)

| Component | STRIDE categories in scope | Key finding → design decision |
|---|---|---|
| `Integrity.Verify()` | Tampering, Elevation of Privilege | → `internal` visibility, no `InternalsVisibleTo` grant to `SharpGuard.Api`; `NetArchTest` backstop (`PLAN.md` D-05) |
| EF Core queries | Tampering (SQLi) | → LINQ-only, always parameterized (D-02) — the session explicitly noted this is weaker than `app05_go_react`'s/`app06_HASKELL_react`'s/`app07_rust_react`'s compile-time schema verification, and recorded that gap rather than assuming parity |
| YAML card ingestion | Tampering, Repudiation | → `YamlDotNet`'s strict-by-default deserialization (D-08) + SHA-256 |
| PL/EN translation storage | Information Disclosure (mistranslation), Repudiation | → translations stored with a reviewer identity |
| `CardKind`/`Severity` invariant | (a presentation risk, not cleanly STRIDE-shaped) | → sealed record hierarchy + `CS8509`-as-error (D-04) — the session flagged the configuration-dependency of this control explicitly, the same way `app08_cpp_react`'s session flagged its own `std::visit`-idiom dependency |
| Hangfire job queue | Spoofing, Denial of Service | → strongly-typed job arguments, Hangfire's own type-aware serializer (D-network-adjacent, see `requirements.md` SR-14) |

### 0.2 Security tooling setup

```yaml
# .github/workflows/ci.yml (excerpt)
- name: Build with warnings as errors
  run: dotnet build -warnaserror
- name: SecurityCodeScan / SonarAnalyzer
  run: dotnet build /p:RunAnalyzersDuringBuild=true
- name: SCA
  run: dotnet list package --vulnerable --include-transitive
- name: Architecture tests
  run: dotnet test SharpGuard.Tests/Architecture
- name: .csproj configuration linter
  run: python scripts/check_csproj_settings.py backend/**/*.csproj
- name: Native AOT compatibility check
  run: dotnet publish backend/SharpGuard.Api -p:PublishAot=true
- name: Container scan
  run: trivy image sharpguard-api:latest sharpguard-worker:latest
- name: i18n key parity
  run: node scripts/check-i18n-parity.js
- name: DAST baseline (every PR, passive only)
  run: docker run -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://staging.sharpguard.local
```

### 0.3 Branch protection
- `main` requires 1 approval + all CI checks green + no `SEC REVIEW`/`I18N REVIEW` Kanban card still open for the linked issue.
- CODEOWNERS: `@security-team` required for `backend/SharpGuard.Core/Integrity/`, `backend/**/*.csproj` (specifically for the configuration-linter's trigger surface), `data/hashes.json`, and any `docs/OWASP_stories/*.yaml` change.

---

## Phase 1 — Planning & Analysis (Secure Requirements)

### 1.1 Business goals vs security constraints

| Business goal | Security constraint it must respect |
|---|---|
| Teach OWASP/ATLAS/SecAI+ content accurately and fast | Content integrity (`requirements.md` SR-06) must not be sacrificed for speed of publishing |
| Serve both PL and EN learners | Missing translations degrade gracefully (FR-18.6), never a blank/broken page |
| Use C#'s type system to its full advantage | The `CS8509`-as-error guarantee (FR-19.2) must be monitored as a configuration setting, not assumed permanent — Phase 6.2 exists specifically for this |
| Cover all six Cornucopia decks, including the non-technical harms deck | The harms deck (US-19) must never be presented as if it had CVE-style severity |

### 1.2 Compliance requirements mapping

| Regulation / standard | Relevance | Where it lands in requirements.md |
|---|---|---|
| GDPR / RODO | User accounts, bookmarks, translator reviewer identity | SR-01 (auth), no unnecessary PII |
| EU AI Act (transparency, Art. 13) | `dbd` harms deck explicitly references this | FR-19.3, DR-01.11 |
| NIS2 / Polish KSC | Educational content on GRC topics | DR-01.5 |
| WCAG 2.1 AA | Public-facing educational tool | NFR-02.3 |

### 1.3 Security requirements traceability (excerpt)

| Requirement | Threat addressed | Verified by |
|---|---|---|
| SR-02.1 (EF Core parameterization) | SQL Injection | `SecurityCodeScan` rule forbidding `FromSqlRaw` with concatenation; integration test |
| SR-06.4 (`Integrity.Verify()` internal visibility) | A compromised endpoint forging a "content verified" record | Assembly-level `internal` (compiler-enforced across the assembly boundary) + `NetArchTest` for the intra-solution case |
| SR-08.1 (`AllowUnsafeBlocks=false`) | Memory-corruption vulnerabilities | Compile error on any `unsafe` block |
| SR-09.1/SR-09.2 (`YamlDotNet` strict-by-default) | Malicious YAML exploiting lenient decoding | `FsCheck` property; and, uniquely in this series, verified by the *absence* of a call to a loosening method rather than the presence of a strictness-enabling one |
| FR-19.2 (`CardKind` + `CS8509`-as-error) | Digital-by-Default Harms deck misread as a CVE-style severity list | Integration test asserting the JSON encoding of a `DesignHarm` value carries no severity, **plus** the `.csproj` configuration linter (Phase 0.2) verifying the error-promotion setting is still present |

### 1.4 Abuse cases (negative user stories)

See `requirements.md` §7 for the full table (AC-01–AC-17). Highlights specific to this project's C#/.NET choices:

| ID | Abuse case |
|---|---|
| AC-01 | An attacker crafts a `?q=` value hoping some endpoint uses `FromSqlRaw` with string concatenation instead of parameterized LINQ — `SecurityCodeScan` exists specifically to catch this pattern before merge. |
| AC-06 | An attacker submits a crafted `docs/OWASP_stories/*.yaml` PR hoping `CardLoader` has, somewhere, called `.IgnoreUnmatchedProperties()` to loosen the default strict deserialization. |
| AC-16 | A user copy-pastes the Digital-by-Default Harms deck into a vulnerability report as if `SCO2` were a CVSS-scored finding — mitigated by the exhaustive `switch` expression, *provided* the `CS8509`-as-error configuration is intact. |
| AC-17 | A future refactor removes `<WarningsAsErrors>CS8509</WarningsAsErrors>` from a `.csproj` (perhaps while "cleaning up build warnings" without realizing this one is load-bearing) — the one abuse case in this series that specifically targets project *configuration* rather than application *code*, caught only by the dedicated CI linter step (Phase 0.2), not by any test of the application's runtime behavior. |

---

## Phase 2 — Secure Design

### 2.1 Trust boundaries

```
┌─────────────────────────── Untrusted ───────────────────────────┐
│  Browser (any locale, any user)                                  │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ HTTPS, JWT (stateless)
┌────────────────────────────── Trust Boundary 1 ──────────────────┐
│  Nginx → SharpGuard.Api (Minimal API endpoints)                    │
│    - validates all input via endpoint parameter binding + FluentValidation │
│    - enforces auth/roles via ASP.NET Core authorization policies   │
│    - CANNOT call Integrity.Verify() — internal to SharpGuard.Core, │
│      no InternalsVisibleTo grant to this assembly (compiler-        │
│      enforced across the assembly boundary, D-05)                   │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ enqueue Hangfire job (same PostgreSQL, strongly-typed args)
┌────────────────────────────── Trust Boundary 2 ──────────────────┐
│  SharpGuard.Worker (separate published executable + container)    │
│    - runs Jobs/*, the ONLY assembly granted InternalsVisibleTo     │
│      for SharpGuard.Core.Integrity                                 │
│    - has no HTTP listener — unreachable from any browser request   │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ local filesystem read-only
┌────────────────────────────── Trust Boundary 3 ──────────────────┐
│  docs/OWASP_stories/*.yaml + data/hashes.json                     │
│    - treated as security-sensitive content, CODEOWNERS-gated      │
└────────────────────────────────────────────────────────────────────┘
```

**Design decision D-01 (this document; distinct from `PLAN.md`'s own D-01, disabling `unsafe`):** `SharpGuard.Api` and `SharpGuard.Worker` are two separately published executables from one solution — the same OS-process-boundary pattern used since `app05_go_react`. What's specific to C# here is that the *intra-solution* visibility boundary (which assembly can see `internal` members of `SharpGuard.Core`) is a genuine compiler-enforced mechanism, not merely a convention — `[InternalsVisibleTo("SharpGuard.Api")]` simply is not present in `SharpGuard.Core`'s assembly attributes, so `SharpGuard.Api` cannot reference `Integrity.Verify()` even if a developer tries; the compiler rejects it. This is materially stronger than `app08_cpp_react`'s build-graph-script equivalent and `app09_php_WORDPRESS`'s code-review-only equivalent, and comparable to `app05_go_react`'s `internal/` package convention.

### 2.2 Least privilege applied to the data model

- `CornucopiaCard` records (all six decks) have **no** write path from any HTTP endpoint at all (`requirements.md` C-08) — no such Minimal API route is registered; only the seed hosted service and `ReingestDeckJob` write them.
- `Editor` role can write `Threat`/`Mitigation`/`CodeSample`; only `Admin` can delete.
- `SharpGuard.Worker` runs with the same least-privilege DB role as `SharpGuard.Api` — no superuser.

### 2.3 STRIDE analysis of the designed architecture

| STRIDE | Applies to | Mitigation already in the design |
|---|---|---|
| Spoofing | Browser→API JWT; unauthenticated job injection | JWT RS256; jobs enqueued only from within `SharpGuard.Api`'s own service layer |
| Tampering | YAML card content; DB records; SQL queries | `YamlDotNet` strict decoding + SHA-256; EF Core LINQ-only writes |
| Repudiation | Who approved a translation or a hash-allowlist update | CODEOWNERS-enforced PR review logged in Git history; `VerifiedBy` field |
| Information Disclosure | Error responses; job failure detail | Generic error responses (`IExceptionHandler`); full detail logged server-side only via Serilog |
| Denial of Service | Export jobs; search; card scraping | Hangfire async export (never blocks the API); built-in ASP.NET Core rate limiter; `tsvector` GIN index |
| Elevation of Privilege | Editor trying to write `CornucopiaCard`; anonymous user hitting admin routes | No write route exists at all for cards; authorization policy on every admin endpoint |

### 2.4 Data classification

| Data | Classification | Handling |
|---|---|---|
| Threat/card content (EN + PL) | Public, but integrity-critical | SHA-256 verified, CODEOWNERS-reviewed |
| User accounts (email, password hash) | Personal data | ASP.NET Core Identity's `PasswordHasher<T>`, never logged |
| Bookmarks (anonymous) | Non-personal | `localStorage`, never sent server-side unless authenticated |
| JWT signing key, DB/Redis credentials | Secret | Environment variable / Docker secret, rotated quarterly |

---

## Phase 3 — Implementation (Secure Coding)

### 3.1 Secure coding standards — C#

```csharp
// ALWAYS — EF Core LINQ, always parameterized
var threats = await db.Threats
    .Where(t => t.FrameworkCode == frameworkCode)
    .ToListAsync();

// ALWAYS — nullable reference types make "did I forget a null check" a compile-time warning
public Threat? FindThreat(ThreatId id) => _threats.SingleOrDefault(t => t.Id == id);
// callers MUST check for null before dereferencing, or the compiler warns (promoted to error)

// ALWAYS — exhaustive switch expressions over CardKind (D-04)
public static Severity? SeverityOf(CardKind kind) => kind switch
{
    TechnicalThreat t => t.Severity,
    DesignHarm       => null,
    // deliberately no `_ =>` — CS8509 fires, and is an error, if a new CardKind subtype appears
};

// ALWAYS — strict YAML decoding is the YamlDotNet default; simply never call .IgnoreUnmatchedProperties()

// NEVER — FromSqlRaw with string-interpolated/concatenated input
// db.Threats.FromSqlRaw($"SELECT * FROM threats WHERE code = '{code}'") // FORBIDDEN, SecurityCodeScan-flagged
```

### 3.2 Secure coding standards — Hangfire jobs

```csharp
public class ExportCsvJob
{
    public async Task ExecuteAsync(string format, string framework) // strongly-typed parameters —
                                                                       // Hangfire's serializer rejects
                                                                       // a shape mismatch before this
                                                                       // method body ever runs
    {
        var validated = ExportArgsValidator.Validate(new ExportCsvArgs(format, framework));
        if (!validated.IsValid)
        {
            _logger.LogWarning("Rejected export job: {Error}", validated.Error);
            return;
        }
        // ... proceed ...
    }
}
```

### 3.3 Sprint-by-sprint security activities

| Sprint | Feature work | Security activity in parallel |
|---|---|---|
| 1–2 | Foundation, auth | Threat model review of auth flow; `dotnet build -warnaserror` wired into CI (not yet blocking) |
| 3–4 | Threat browser | SAST becomes blocking; first abuse-case test (AC-01, `SecurityCodeScan`) |
| 5–7 | Card decks (all six, including `dbd`) + integrity | AC-06, AC-16 abuse tests written FIRST (TDD) before the ingestion code exists |
| 7–9 | 5-language code samples | Review that no `AttackDemo` sample is runnable without the confirmation gate |
| 9–10 | i18n | I18N REVIEW Kanban column activated |
| 10–12 | Search, export, matrix | AC-14 (Hangfire job type-safety) test added; DAST baseline extended to `/export/` and `/search/` |
| 12–14 | Hardening & release | Full ZAP active scan; abuse-case sweep across AC-01..AC-17; first Native AOT publish dry-run confirms no reflection-based incompatibility |

---

## Phase 4 — Security Testing

### 4.1 Test pyramid with security layers

```
E2E (Playwright)                  — includes AC-01..AC-17 abuse-case scenarios end-to-end
WebApplicationFactory integration  — auth/permission boundary tests per endpoint
NetArchTest architecture tests      — the assembly-visibility boundary (D-05), verified continuously
xUnit unit                          — service-layer behavior with concrete fixtures
FsCheck properties                  — invariants over generated data: YAML decode-rejects-unknown-
                                       fields, every mitigation has 5 languages
```

### 4.2 SAST — already partially running before CI
Nullable-reference-type warnings and `CS8509` are Roslyn diagnostics surfaced by `dotnet build` itself — every developer sees them in their IDE continuously, not only in CI. `SecurityCodeScan` and `SonarAnalyzer.CSharp` add dedicated security-pattern detection (SQL injection, weak crypto, path traversal) on top of the compiler's own general-purpose analysis. This project's CI step (`-warnaserror`) simply makes the same signal a developer already sees locally into a release-blocking gate — there is very little "shift" required, because the tooling was already shifted left by the platform itself.

### 4.3 SCA — built into the CLI
`dotnet list package --vulnerable --include-transitive` checks every NuGet dependency, direct and transitive, against the GitHub Advisory Database, with no separate tool installation required — a first-class `dotnet` CLI subcommand. `npm audit` and Trivy cover the frontend and both container images respectively.

### 4.4 DAST (OWASP ZAP)
Baseline (passive) scan on every PR against staging; full active scan before each production release, targeting all public API routes. `SharpGuard.Worker` is not a ZAP target because it exposes no HTTP port — verified by a network-level test.

### 4.5 Abuse-case tests (integration level)
```csharp
[Fact]
public void Ac06_YamlLoader_RejectsUnrecognizedTopLevelKey()
{
    var malicious = "meta:\n  edition: evil\nexec: rm -rf /\n";
    Action act = () => CardLoader.Decode(malicious);
    act.Should().Throw<YamlException>();
}

[Fact]
public void Ac17_CsprojFiles_StillDeclareCs8509AsError()
{
    var csprojFiles = Directory.GetFiles("backend", "*.csproj", SearchOption.AllDirectories)
        .Where(f => RequiresExhaustivenessCheck(f));
    foreach (var file in csprojFiles)
    {
        File.ReadAllText(file).Should().Contain("<WarningsAsErrors>CS8509</WarningsAsErrors>");
    }
}
```

### 4.6 Security regression testing
Every fixed security bug gets a permanent regression test, run on every CI build, never skipped.

---

## Phase 5 — Deployment (Secure Release)

### 5.1 CI/CD pipeline with security gates
```
build -warnaserror → unit+property tests → architecture tests (NetArchTest) → SAST (SecurityCodeScan)
   → SCA (dotnet list package --vulnerable) → Native AOT publish dry-run → build container images
   → container scan (Trivy) → deploy to staging → DAST baseline → E2E (Playwright)
   → manual QA sign-off → deploy to production (blue/green) → DAST full scan (scheduled, not blocking)
```

### 5.2 Infrastructure hardening checklist
```
Nginx           TLS 1.2+/1.3 only; HSTS; security headers; request size limits
SharpGuard.Api   custom IExceptionHandler converts any unhandled exception to a generic 500 body;
                 full detail logged server-side only via Serilog
SharpGuard.Worker no published port at all; only outbound connections to Postgres/Redis
PostgreSQL       least-privilege role for both api and worker (no SUPERUSER); network isolated
Redis            password-protected; not exposed on the host
Docker           Native AOT-published images, no separate .NET runtime installed in the container;
                 non-root user
```

### 5.3 Secrets management
`.env` files never committed; JWT signing key, DB/Redis credentials injected via Docker secrets / GitHub Actions secrets, rotated quarterly and immediately on suspected exposure. `dotnet user-secrets` is used only for local development and is explicitly never present in a deployed environment.

---

## Phase 6 — Maintenance & Runtime Monitoring

### 6.1 Runtime monitoring
- `prometheus-net.AspNetCore` exposes `/api/v1/metrics`; Grafana dashboards track request latency, rate-limit rejections, `content_integrity_check_ok` gauge, Hangfire queue depth/failure rate (visible both in Grafana and on Hangfire's own built-in `/hangfire` dashboard).
- A Loki alert `SEC-CARD-HASH-MISMATCH` fires directly from `Integrity.Verify()`'s Serilog error entry.

### 6.2 Patch management (Kanban) — including the configuration-monitoring activity unique to this project
A dedicated `DEPENDENCY UPDATES` swimlane, fed weekly by Dependabot (NuGet + npm + Docker base images) and `dotnet list package --vulnerable`'s nightly run; any reachable vulnerability auto-creates a `SEC REVIEW`-gated card with a 5-business-day SLA. **A second, smaller recurring task on this same swimlane — with no direct equivalent in any prior sibling's maintenance schedule — is a quarterly grep-based audit confirming every relevant `.csproj` still declares `<WarningsAsErrors>CS8509</WarningsAsErrors>`, `<Nullable>enable</Nullable>`, and `<AllowUnsafeBlocks>false</AllowUnsafeBlocks>`.** This exists because these three settings, unlike a language-level guarantee, can be silently reverted by an unrelated refactor (e.g., someone "cleaning up" a `.csproj` file) with no build failure signaling the loss until the specific bug the setting was preventing actually occurs.

### 6.3 Incident response (outline)
1. Detect → 2. Contain (feature flag / disable route) → 3. Eradicate (patch — for a project-configuration regression specifically, this includes restoring the missing `.csproj` setting and adding a regression test to the linter, not merely fixing the immediate symptom) → 4. Recover (redeploy) → 5. Post-mortem, feeding new abuse cases back into Phase 1.

### 6.4 Content & translation review schedule
- Quarterly re-verification that every `CornucopiaCard.ContentSha256` still matches its source YAML.
- Quarterly Polish translation audit sampling 10% of `DescriptionPl` fields against current `DescriptionEn` for staleness.

---

## Phase 7 — C#-Specific SSDLC Considerations

1. **"Shifted left into the toolchain" and "compiler-enforced with no configuration dependency" are different claims, and this project is careful to use the right one for each guarantee.** Nullable-reference-type warnings, `SecurityCodeScan` findings, and `dotnet list package --vulnerable` results are all genuinely available before a PR is opened — a real, valuable shift-left property. The `CardKind` exhaustiveness guarantee (FR-19.2) is *also* compiler-enforced, but conditionally: it depends on a project-file setting that is not itself protected by the same mechanism it enables. This document treats the two as different in kind, not degree, and gives the second its own monitoring activity (Phase 6.2) specifically because the first category doesn't need one.
2. **The CLR's managed memory model closes the same bug class `app07_rust_react`'s ownership model does, via a different, and in this series' terms equally legitimate, mechanism.** This project does not claim Rust's specific guarantee (no garbage collector, deterministic destruction, `Send`/`Sync`-checked concurrency) — it claims the CWE Top 25 memory-corruption outcome is prevented, by a different architecture, with different runtime cost trade-offs (GC pauses versus Rust's zero-cost abstractions) that this document does not attempt to adjudicate as "better," only as "different, and both real."
3. **EF Core's relationship to `sqlc`/`hasql-th`/`sqlx::query!` is best understood as "the same problem, solved one level higher," not "a weaker version of the same solution."** Those three tools verify a query's *shape* against the live schema; EF Core verifies the *LINQ expression* against the *C# entity model*, and relies on migrations to keep that model synchronized with the schema separately. This is a real, structural difference in where verification happens, not merely a difference in tool maturity — and Phase 0.1's threat-modeling session recorded it as a named gap for exactly this reason.
4. **This app, more than any other custom-backend sibling, is a natural direct comparison point for the course's Java-background audience**, since C#/.NET and Java/Spring Boot (`app01_react`/`app02_angular`) occupy the same "mainstream, managed-runtime, enterprise-oriented" position in the industry, arrived at independently. Where they differ (nullable reference types with build-enforceable strictness; native, framework-level rate limiting; a CLI-integrated SCA tool; Native AOT as a first-class publish target) is precisely the material most useful for that audience to study side by side with what they already know.

---

## SDLC × SSDLC Master Mapping Table

| Classic SDLC stage | SSDLC security activity in this project | Primary artifact |
|---|---|---|
| Planning & Analysis | Threat modeling with the project's own STRIDE deck; compliance mapping (GDPR/AI Act/NIS2); abuse cases AC-01–AC-17 | `requirements.md` §1–7, this document Phase 1 |
| Design | Trust-boundary diagram (`SharpGuard.Api` ↔ `SharpGuard.Worker` ↔ YAML source) with a compiler-enforced assembly-visibility boundary; STRIDE-per-component table | `PLAN.md` §3–5, this document Phase 2 |
| Implementation | Secure C# coding standards (EF Core LINQ, strict YAML decoding, exhaustive `switch` expressions, `unsafe` disabled); TDD red-green with security tests (and `FsCheck` properties) written first | `user_stories+tests.md`, this document Phase 3 |
| Testing | SAST (Roslyn/`SecurityCodeScan`/`SonarAnalyzer.CSharp`, largely already active pre-CI), SCA (`dotnet list package --vulnerable`), DAST (ZAP), architecture tests (`NetArchTest`), abuse-case integration tests | this document Phase 4 |
| Deployment | CI/CD security gates, Native AOT static-binary hardening checklist, secrets management | this document Phase 5 |
| Maintenance | Runtime monitoring, Kanban-driven patch management (including quarterly `.csproj` configuration audits), incident response, quarterly content/translation integrity review | this document Phase 6 |

---

## Agile Ceremonies — Security & i18n Integration Points

```
Sprint Planning        → New security/i18n stories pulled from backlog alongside features;
                          every card-deck story (US-05–US-12, US-19) is estimated with its Polish
                          translation review as part of the story, not a separate ticket.
Daily Standup          → "Any SEC REVIEW or I18N REVIEW blocker?" is a standing question.
Mid-Sprint Security Gate → Dedicated 30-minute slot for anything touching Integrity's assembly
                          visibility, EF Core query construction, or CardKind exhaustiveness/
                          .csproj configuration.
Sprint Review          → Demo always includes one security-relevant moment (e.g., a PR that
                          fails the build because it removed a switch arm, or the attack-demo
                          confirmation modal).
Sprint Retrospective   → One mandatory retro item: "did any security or translation issue
                          reach TEST or DONE that SEC REVIEW/I18N REVIEW should have caught?"
```

---

## Summary: SSDLC Compliance Checklist for SharpGuard 2026

```
[ ] Threat model exists and is reviewed each quarter (Phase 0, 6.4)
[ ] Integrity.Verify() is internal with no InternalsVisibleTo grant to SharpGuard.Api — compiler-
    enforced across the assembly boundary, NetArchTest-verified within the solution (Phase 2.1)
[ ] All SQL access goes through EF Core LINQ — zero FromSqlRaw-with-concatenation (Phase 3.1)
[ ] All six YAML decks decoded via YamlDotNet's strict-by-default deserializer; SHA-256 verified
    regardless (Phase 3, D-08)
[ ] SAST (Roslyn/SecurityCodeScan)/SCA (dotnet list package --vulnerable)/DAST (ZAP) are all
    CI-blocking, and largely already active during local development (Phase 4)
[ ] Every abuse case AC-01–AC-17 has an automated regression test (Phase 4.5)
[ ] i18n key parity and translation review are enforced as release gates (Phase 1, I18N REVIEW column)
[ ] Card content (all 6 decks) is read-only in the application and change-controlled at the source
[ ] SharpGuard.Api and SharpGuard.Worker are separate executables/containers with no published worker port
[ ] Every relevant .csproj is quarterly-audited for the presence of AllowUnsafeBlocks=false,
    Nullable=enable, and WarningsAsErrors=CS8509 (Phase 6.2) — this project's unique configuration-
    drift risk, with no equivalent monitoring need in any language-level-guaranteed sibling
[ ] Digital-by-Default Harms deck cannot carry a Severity value, given the above configuration
    holds — verified by both a JSON-encoding test and the configuration audit (Phase 1.3, FR-19.2)
[ ] Kanban board carries explicit SEC REVIEW and I18N REVIEW columns with WIP limits
[ ] Incident response and patch-management processes exist before, not after, first production release
```
