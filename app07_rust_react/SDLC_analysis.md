# RustBastion 2026 — SSDLC / SDLC Analysis

**Version:** 1.0
**Date:** 2026-07-07
**Document type:** Secure Software Development Lifecycle (SSDLC) analysis, mapped against the classic SDLC
**Scope:** Full lifecycle analysis of the application defined in `PLAN.md`, `requirements.md`, and `user_stories+tests.md`
**Methodology:** Agile — Scrum for planning/cadence, Kanban overlay for the engineering + security workflow
**Dotyczy:** US-01 – US-19 / Rust (stable, 2024 edition, axum + sqlx) + React 18

---

## Executive Summary

RustBastion 2026 carries the same double obligation as its sibling projects (`app01_react`, `app02_angular`, `app03_python_django`, `app04_scala_react`, `app05_go_react`, `app06_HASKELL_react`): it **teaches** OWASP/MITRE ATLAS/CompTIA SecAI+ security content, so it must itself **be** secure — an app about SQL Injection that is vulnerable to SQL Injection trains people with a false sense of authority.

This project's lifecycle emphasis follows directly from Rust's specific, and specifically 2026-relevant, contribution to this series:

1. **Memory safety without a garbage collector, and it is exactly what CISA/NSA's 2026 guidance is about.** Public agencies have explicitly recommended migrating new development to memory-safe languages; Rust is the language most directly named in that guidance among this series' six backend choices. `PLAN.md` D-01 (`#![forbid(unsafe_code)]`) is not a slogan here — it is a specific, compile-time-enforced, CI-checkable claim, and this document treats it with the same rigor as every other security requirement, including stating its limits (SR-08.3: it says nothing about business-logic correctness).
2. **This is a *different axis* of security guarantee than the rest of the series, not a "better" one.** `app03_python_django` through `app06_HASKELL_react` each demonstrated a way to push *logical* correctness (SQL shape, illegal states, YAML deserialization safety) earlier into compile time. Rust adds *physical memory safety* to that list — a property orthogonal to, not a superset of, the others. RustBastion still needs `sqlx::query!` for the SQL-injection guarantee (D-02) and a `CardKind` enum for the harms-deck guarantee (D-10) — memory safety alone would not have given it either.
3. **The same content-integrity and i18n obligations as every sibling app still apply.** Six externally-authored YAML card decks, including the non-technical Digital-by-Default Harms deck, are ingested as security-sensitive data, and the application is fully bilingual (PL/EN) with its own translation-review supply chain — none of that is affected by which language the backend is written in.

The lifecycle below follows **Agile Scrum for cadence, with a Kanban board carrying explicit security-gate columns**, per the requested focus on Agile/Scrum/Kanban.

---

## SSDLC vs Classic SDLC — Where Security Moves

```
Classic SDLC (security bolted on late):
  Planning & Analysis → Design → Implementation → Testing → Deployment → Maintenance
                                                        ↑
                                          Security testing added HERE — too late,
                                          architecture and code are already frozen.

SSDLC ("Shift Left" — security integrated at every stage):
  Secure          Secure       Secure            Secure          Secure           Secure
  Planning &  →   Design   →   Implementation →  Testing     →   Deployment   →   Maintenance
  Analysis        │            │                 │               │                │
    ↑             ↑            ↑                 ↑               ↑                ↑
  Threat Model   Module       #![forbid(unsafe_  SAST(clippy)+   Static musl      Runtime
  + Compliance   visibility + code)] at commit;   DAST+SCA        binary, FROM     monitoring +
  mapping        least priv.  sqlx::query!        (cargo audit/   scratch, ≤25MB   patch cadence +
  (OWASP/ATLAS/  (D-05, D-07) removes SQLi at      cargo-deny/                     card-deck +
  SecAI+/GDPR)                compile time         cargo-geiger)                   translation
                                                                                    integrity review
```

Both models describe the **same six stages**; SSDLC's contribution is that security activities happen *inside* each stage rather than as a single gate before release. §Master Mapping Table at the end of this document ties every classic SDLC stage to its SSDLC activity for this specific project.

---

## Agile Framework: Scrum for Cadence, Kanban for Flow

### Scrum structure

```
Sprint length:      2 weeks
Team size:           3–5 Rust engineers, 1 frontend/React engineer, 1 QA/security, 1 PL translator part-time
Velocity target:     ~18–22 story points/sprint (comparable to app05_go_react's estimate — Rust's
                      learning curve is steeper than Go's for contributors new to ownership/borrowing,
                      but shallower than adopting Haskell's effect-typing discipline from scratch;
                      stated as a team-composition assumption, not a universal claim)
Total duration:      14 sprints (~28 weeks) — matches PLAN.md §6 phases

Ceremonies:
  Sprint Planning        — Monday, Day 1, 2h max — pulls from the Product Backlog (PLAN.md §15 + this doc's abuse cases)
  Daily Standup          — daily, 15 min, includes a mandatory "any security blocker?" round
  Mid-Sprint Security Gate — Wednesday, Day 7, 30 min — peer review of anything touching auth,
                             integrity::verify's visibility, sqlx query modules, or apalis job payload types
  Sprint Review          — Friday, Day 10, 1h — demo includes a security angle (e.g. "here's a PR
                             that tries to add an unsafe block and fails to compile the whole crate")
  Sprint Retrospective   — Friday, Day 10, 45 min — one mandatory security-process retro item
```

### Kanban board — security-gated columns

```
BACKLOG → SPRINT → IN DEV → SEC REVIEW → I18N REVIEW → TEST → DONE

  BACKLOG       Product backlog: user stories (US-01..US-19), bugs, abuse cases (AC-01..AC-17)
  SPRINT        Committed for the current sprint
  IN DEV        Actively coded — TDD red/green cycle in progress
  SEC REVIEW    Mandatory gate for anything touching: auth, integrity::verify's caller list,
                sqlx query modules, apalis job payload types, or admin/editor permissions
  I18N REVIEW   Mandatory gate for anything adding user-visible strings or card translations —
                a native Polish speaker signs off before merge
  TEST          cargo test (+ proptest) + axum-test + Vitest + Playwright running in CI
  DONE          Meets the Definition of Done below

WIP limits:  IN DEV ≤ 2/dev · SEC REVIEW ≤ 3 total · I18N REVIEW ≤ 3 total · TEST ≤ 5 total
```

**A Rust-specific Kanban nuance:** `cargo clippy -- -D warnings` and `#![forbid(unsafe_code)]` catch an entire category of mistakes at `cargo build` time, before a PR can even be opened for review — this is a *stronger* form of the same effect `app05_go_react`'s pre-commit `golangci-lint` and `app06_HASKELL_react`'s `-Wall -Werror` produce, because a memory-safety violation in this project's own code is not merely flagged, it is **impossible to compile**. This project's Kanban cycle-time metric for `SEC REVIEW` is expected to show that memory-safety-class issues essentially never reach that column at all (they die at `cargo build`), while business-logic authorization issues still take the same human-review time they would in any other stack — the team should track both figures separately rather than reporting one blended "security review speed" number that would misrepresent which category improved.

### Definition of Done (security- and i18n-enforced)

```
CODE QUALITY
  [ ] cargo test passes (including proptest); coverage ≥ 85% on core::service
  [ ] cargo fmt --check clean; cargo clippy -- -D warnings zero findings
  [ ] cargo sqlx prepare metadata committed and matches .sql query call sites (no drift)

SECURITY GATES
  [ ] Zero unsafe blocks in core/api/worker (#![forbid(unsafe_code)] enforces this at compile time)
  [ ] cargo-geiger dependency-tree unsafe report reviewed; unexpected growth flagged in SEC REVIEW
  [ ] cargo audit + cargo deny check pass against Cargo.lock
  [ ] Peer security review completed for anything in the SEC REVIEW trigger list above
  [ ] No secrets committed (detect-secrets / trufflehog pre-commit hook green)
  [ ] All DB access via sqlx::query!/query_as! — no format!-built SQL exists (structurally true, spot-checked anyway)
  [ ] integrity::verify's visibility/caller list unchanged, or changed with explicit SEC REVIEW sign-off

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
| `integrity::verify` | Tampering, Elevation of Privilege | → visible only to two documented callers; CI checks the module dependency graph (`PLAN.md` D-05) |
| `store` (sqlx queries) | Tampering (SQLi) | → all queries checked against the live schema at compile time (D-02) |
| YAML card ingestion | Tampering, Repudiation | → `serde_yaml` + `deny_unknown_fields` + SHA-256 verification (D-09) |
| PL/EN translation storage | Information Disclosure (mistranslation), Repudiation | → translations stored with a reviewer identity |
| `apalis` job queue | Spoofing, Denial of Service | → typed, `deny_unknown_fields`-validated payloads at enqueue time (D-08) |
| Application memory safety | (not a STRIDE-shaped risk in the usual sense — closer to Tampering-via-corruption) | → `#![forbid(unsafe_code)]` at every crate root (D-01); this is the one place the STRIDE session's own categories didn't map cleanly onto the mitigation, and the team noted that explicitly rather than force-fitting it |
| Digital-by-Default Harms deck | (a presentation risk, not STRIDE-shaped either) | → `CardKind` enum makes the mis-presentation structurally impossible (D-10) |

### 0.2 Security tooling setup

```yaml
# .github/workflows/ci.yml (excerpt)
- name: Lint (SAST)
  run: cargo clippy --all-targets -- -D warnings
- name: Unsafe code audit (dependency tree)
  run: cargo geiger --output-format GitHubMarkdown >> $GITHUB_STEP_SUMMARY
- name: SCA
  run: cargo audit && cargo deny check
- name: Container scan
  run: trivy image rustbastion-api:latest rustbastion-worker:latest
- name: i18n key parity
  run: node scripts/check-i18n-parity.js
- name: DAST baseline (every PR, passive only)
  run: docker run -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://staging.rustbastion.local
```

```bash
# pre-commit hook
cargo fmt --check
cargo clippy --all-targets -- -D warnings
```

### 0.3 Branch protection
- `main` requires 1 approval + all CI checks green + no `SEC REVIEW`/`I18N REVIEW` Kanban card still open for the linked issue.
- CODEOWNERS: `@security-team` required for `backend/core/src/integrity/`, `backend/core/src/store/`, `data/hashes.json`, and any `docs/OWASP_stories/*.yaml` change.

---

## Phase 1 — Planning & Analysis (Secure Requirements)

### 1.1 Business goals vs security constraints

| Business goal | Security constraint it must respect |
|---|---|
| Teach OWASP/ATLAS/SecAI+ content accurately and fast | Content integrity (`requirements.md` SR-06) must not be sacrificed for speed of publishing |
| Serve both PL and EN learners | Missing translations degrade gracefully (FR-18.6), never a blank/broken page |
| Demonstrate memory-safe-language benefits honestly | The memory-safety claim (SR-08) must not be presented as covering logic bugs, SQLi, or translation accuracy — each of those has its own, separate, mitigation |
| Cover all six Cornucopia decks, including the non-technical harms deck | The harms deck (US-19) must never be presented as if it had CVE-style severity — FR-19.2, enforced at the type level (D-10) |

### 1.2 Compliance requirements mapping

| Regulation / standard | Relevance | Where it lands in requirements.md |
|---|---|---|
| GDPR / RODO | User accounts, bookmarks, translator reviewer identity | SR-01 (auth), no unnecessary PII |
| EU AI Act (transparency, Art. 13) | `dbd` harms deck explicitly references this | FR-19.3, DR-01.11 |
| NIS2 / Polish KSC | Educational content on GRC topics | DR-01.5 |
| CISA/NSA memory-safe-language guidance (2023–2026) | Directly motivates this app's stack choice and is itself seeded as a CompTIA SecAI+ GRC topic | DR-01.5 |
| WCAG 2.1 AA | Public-facing educational tool | NFR-02.3 |

### 1.3 Security requirements traceability (excerpt)

| Requirement | Threat addressed | Verified by |
|---|---|---|
| SR-02.1 (`sqlx::query!` compile-time-checked SQL) | SQL Injection | Compile failure if a query's shape doesn't match the schema; `clippy.toml` disallowed-methods rule blocks raw string-built execution |
| SR-06.4 (`integrity::verify` visibility) | A compromised handler forging a "content verified" record | Module visibility + CI dependency-graph check |
| SR-08.1 (`#![forbid(unsafe_code)]`) | Memory-corruption vulnerabilities (CWE-416, CWE-415, CWE-125/787, CWE-476) | Compile error on any `unsafe` block in application crates; verified simply by the build succeeding |
| SR-09.3 (`prop_unknown_fields_rejected`) | Malicious YAML exploiting lenient/partial decoding | `proptest` property generating random extra fields |
| FR-19.2 (`CardKind` enum) | Digital-by-Default Harms deck misread as a CVE-style severity list | Integration test asserting the JSON encoding of a `DesignHarm` value carries no severity |

### 1.4 Abuse cases (negative user stories)

See `requirements.md` §7 for the full table (AC-01–AC-17). Highlights specific to this project's Rust/memory-safety choices:

| ID | Abuse case |
|---|---|
| AC-01 | An attacker crafts a `?q=` value hoping some handler builds SQL by string formatting instead of `sqlx::query!` — there is no such code path, and the abuse-case test documents that fact. |
| AC-06 | An attacker submits a crafted `docs/OWASP_stories/*.yaml` PR hoping `cards::loader` decodes into something looser than the declared, `deny_unknown_fields` types. |
| AC-14 | An attacker (or a bug) enqueues a malformed `apalis` payload hoping the worker executes it without validation. |
| AC-16 | A user copy-pastes the Digital-by-Default Harms deck into a vulnerability report as if `SCO2` were a CVSS-scored finding — the API response for these cards has no severity value to have copy-pasted in the first place. |
| AC-17 | A contributor (or a compromised dependency update) introduces a buffer-overflow-shaped bug via an `unsafe` block — this fails to compile in application code; the same class of bug in a *dependency* is caught, not prevented, by `cargo-geiger`'s reporting plus ordinary `cargo audit` advisory tracking. |

---

## Phase 2 — Secure Design

### 2.1 Trust boundaries

```
┌─────────────────────────── Untrusted ───────────────────────────┐
│  Browser (any locale, any user)                                  │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ HTTPS, JWT (stateless)
┌────────────────────────────── Trust Boundary 1 ──────────────────┐
│  Nginx → api binary (Axum handlers, routes/**)                    │
│    - validates all input via Axum extractors + validator derive   │
│    - enforces auth/roles via middleware                            │
│    - MUST NOT import integrity (module-visibility + CI graph check)│
└───────────────────────────────┬──────────────────────────────────┘
                                 │ enqueue apalis row (same PostgreSQL, typed payload)
┌────────────────────────────── Trust Boundary 2 ──────────────────┐
│  worker binary (separate compiled binary + container)              │
│    - runs jobs::*, the ONLY caller of integrity::verify             │
│    - has no HTTP listener — unreachable from any browser request   │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ local filesystem read-only
┌────────────────────────────── Trust Boundary 3 ──────────────────┐
│  docs/OWASP_stories/*.yaml + data/hashes.json                     │
│    - treated as security-sensitive content, CODEOWNERS-gated      │
└────────────────────────────────────────────────────────────────────┘
```

**Design decision D-01 (this document; distinct from `PLAN.md`'s own D-01, `#![forbid(unsafe_code)]`):** `api` and `worker` are two separately compiled binaries from one Cargo workspace — the same OS-process-boundary pattern `app05_go_react` and `app06_HASKELL_react` use. What's specific to Rust here is that the boundary *inside* Trust Boundary 1 — between `routes` and `integrity` — is enforced by the same tool (the Rust compiler's module-visibility rules) that also enforces memory safety project-wide, rather than needing a separate mechanism.

### 2.2 Least privilege applied to the data model

- `CornucopiaCard` rows (all six decks) have **no** write path from any HTTP handler — not even an admin-JWT-gated one (`requirements.md` C-08). The Axum router has no route through which such a request could even be constructed; only `src/bin/seed.rs`/the `reingest_deck` job write them.
- `editor` role can write `Threat`/`Mitigation`/`CodeSample`; only `admin` can delete.
- `worker` runs with the same least-privilege DB role as `api` — no superuser.

### 2.3 STRIDE analysis of the designed architecture

| STRIDE | Applies to | Mitigation already in the design |
|---|---|---|
| Spoofing | Browser→API JWT; unauthenticated job injection | JWT RS256 (`jsonwebtoken`); jobs enqueued only from within `api`'s own service layer |
| Tampering | YAML card content; DB records; SQL queries; memory corruption | `serde_yaml` + `deny_unknown_fields` + SHA-256; `sqlx::query!`-only writes; `#![forbid(unsafe_code)]` rules out memory-corruption-based tampering in this project's own code |
| Repudiation | Who approved a translation or a hash-allowlist update | CODEOWNERS-enforced PR review logged in Git history; `verified_by` field |
| Information Disclosure | Error responses; job failure detail | Generic error body to the client; full detail logged server-side only via `tracing` |
| Denial of Service | Export jobs; search; card scraping | `apalis` async export (never blocks `api`); `governor`/Redis rate limit; `tsvector` GIN index |
| Elevation of Privilege | Editor trying to write `CornucopiaCard`; anonymous user hitting admin routes | No write route exists at all for cards; JWT role middleware on every admin route |

### 2.4 Data classification

| Data | Classification | Handling |
|---|---|---|
| Threat/card content (EN + PL) | Public, but integrity-critical | SHA-256 verified, CODEOWNERS-reviewed |
| User accounts (email, password hash) | Personal data | `argon2` (Argon2id), never logged |
| Bookmarks (anonymous) | Non-personal | `localStorage`, never sent server-side unless authenticated |
| JWT signing key, DB/Redis credentials | Secret | Environment variable / Docker secret, rotated quarterly |

---

## Phase 3 — Implementation (Secure Coding)

### 3.1 Secure coding standards — Rust

```rust
// ALWAYS — sqlx::query!, checked against the live schema at compile time
let threats = sqlx::query_as!(
    Threat,
    "SELECT * FROM threats WHERE framework_code = $1 AND severity = $2",
    framework_code, severity as Severity
)
.fetch_all(&pool)
.await?;

// ALWAYS — Result/Option, no exceptions, no null
fn get_threat(id: ThreatId) -> Result<Threat, ApiError> { /* ... */ }

// ALWAYS — strict, deny_unknown_fields YAML decoding
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct CardFile {
    meta: Meta,
    suits: Vec<Suit>,
}

// ALWAYS — every crate root
#![forbid(unsafe_code)]

// NEVER — format!-built SQL (there is no function in this codebase capable of executing one;
// this comment documents the absence, enforced additionally by a clippy.toml disallowed-methods rule)
```

### 3.2 Secure coding standards — `apalis` jobs

```rust
#[derive(Debug, Serialize, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ExportCsvArgs {
    pub format: String,
    pub framework: String,
}

pub fn validate_args(args: &ExportCsvArgs) -> Result<(), ValidationError> {
    if args.framework.is_empty() {
        return Err(ValidationError::new("framework", "must not be empty"));
    }
    if args.format != "csv" {
        return Err(ValidationError::new("format", "must be csv"));
    }
    Ok(())
}
```

### 3.3 Sprint-by-sprint security activities

| Sprint | Feature work | Security activity in parallel |
|---|---|---|
| 1–2 | Foundation, auth | Threat model review of auth flow; `#![forbid(unsafe_code)]` + `clippy -D warnings` wired into CI (not yet blocking) |
| 3–4 | Threat browser | SAST becomes blocking; first abuse-case test (AC-01, documenting the absent SQLi path) |
| 5–7 | Card decks (all six, including `dbd`) + integrity | AC-06, AC-16 abuse tests written FIRST (TDD) before the ingestion command exists |
| 7–9 | 5-language code samples | Review that no `AttackDemo` sample is runnable without the confirmation gate |
| 9–10 | i18n | I18N REVIEW Kanban column activated |
| 10–12 | Search, export, matrix | AC-14 (`apalis` payload validation) test added; DAST baseline extended to `/export/` and `/search/` |
| 12–14 | Hardening & release | Full ZAP active scan; abuse-case sweep across AC-01..AC-17; `cargo-geiger` dependency report reviewed one final time before release |

---

## Phase 4 — Security Testing

### 4.1 Test pyramid with security layers

```
E2E (Playwright)          — includes AC-01..AC-17 abuse-case scenarios end-to-end
axum-test integration      — auth/permission boundary tests per handler
Unit tests (#[test])       — service-layer behavior with concrete fixtures
proptest properties        — invariants over generated data: YAML decode-rejects-unknown-fields,
                             every mitigation has 5 languages, DesignHarm never serializes a severity
```

### 4.2 SAST
`cargo clippy --all-targets -- -D warnings` runs on every PR and in a pre-commit hook — it catches a wide range of correctness and style issues, several with direct security relevance (e.g., `clippy::unwrap_used` flags panics on the request path, which this project denies in `routes/**`). `#![forbid(unsafe_code)]` is enforced by the compiler itself, not by `clippy`, and cannot be worked around by adjusting lint configuration — only by removing the attribute, which is itself a `SEC REVIEW`-gated change per the Definition of Done.

### 4.3 SCA
`cargo audit` checks `Cargo.lock` against the RustSec advisory database; `cargo-deny` additionally enforces license and duplicate-dependency-version policy. `cargo-geiger` is run as a *reporting* tool, not a pass/fail gate by default — its output (how much `unsafe` exists in the dependency tree) is a input to human judgment during dependency-update review, tracked in the SEC REVIEW column when it changes materially. `npm audit` and Trivy cover the frontend and both container images.

### 4.4 DAST (OWASP ZAP)
Baseline (passive) scan on every PR against staging; full active scan before each production release, targeting all public `api` routes. `worker` is not a ZAP target because it exposes no HTTP port — verified by a network-level test.

### 4.5 Abuse-case tests (integration level)
```rust
#[test]
fn ac06_yaml_loader_rejects_unrecognized_top_level_key() {
    let malicious = "meta:\n  edition: evil\nexec: rm -rf /\n";
    assert!(serde_yaml::from_str::<CardFile>(malicious).is_err());
}

#[test]
fn ac14_export_csv_args_rejects_empty_framework() {
    let args = ExportCsvArgs { format: "csv".into(), framework: "".into() };
    assert!(jobs::export_csv::validate_args(&args).is_err());
}
```

### 4.6 Security regression testing
Every fixed security bug gets a permanent regression test (unit, property, or integration, whichever fits), run on every CI build, never skipped.

---

## Phase 5 — Deployment (Secure Release)

### 5.1 CI/CD pipeline with security gates
```
lint (clippy) → unsafe audit (cargo-geiger) → build (sqlx compile-time check) → unit+property tests
   → SCA (cargo audit/cargo deny) → build static musl images → container scan (Trivy)
   → deploy to staging → DAST baseline → E2E (Playwright) → manual QA sign-off
   → deploy to production (blue/green) → DAST full scan (scheduled, not blocking)
```

### 5.2 Infrastructure hardening checklist
```
Nginx        TLS 1.2+/1.3 only; HSTS; security headers; request size limits
api          panics caught by a top-level Tower layer, converted to a generic 500 body; full
             panic detail logged server-side only via tracing
worker       no published port at all; only outbound connections to Postgres/Redis
PostgreSQL   least-privilege role for both api and worker (no SUPERUSER); network isolated
Redis        password-protected (requirepass); not exposed on the host
Docker       FROM scratch, musl-target fully static binaries — no libc, no shell, no package
             manager, no interpreter inside the running container at all
```

**Deployment-footprint claim, stated as testable (Phase 5 analysis, not marketing):** `requirements.md` NFR-07.1 targets ≤ 25 MB for the `api` production image, expected to be at or below `app05_go_react`'s ≤ 30 MB target and below `app06_HASKELL_react`'s ≤ 120 MB target, because a `musl`-static Rust binary bundles no garbage collector or language runtime at all. This series' consistent practice has been to state deployment-footprint numbers as CI-verified facts once measured, not as claims — this is the app most likely to look good on that axis, and the discipline is to confirm it with the actual CI size-check step rather than assume it.

### 5.3 Secrets management
`.env` files never committed; JWT signing key, DB/Redis credentials injected via Docker secrets / GitHub Actions secrets, rotated quarterly and immediately on suspected exposure.

---

## Phase 6 — Maintenance & Runtime Monitoring

### 6.1 Runtime monitoring
- `metrics` + `metrics-exporter-prometheus` expose `/api/v1/metrics`; Grafana dashboards track request latency, rate-limit rejections, `content_integrity_check_ok` gauge, `apalis` queue depth/failure rate.
- A Loki alert `SEC-CARD-HASH-MISMATCH` fires directly from `integrity::verify`'s `tracing::error!` call.

### 6.2 Patch management (Kanban)
A dedicated `DEPENDENCY UPDATES` swimlane, fed weekly by Dependabot (Cargo + npm + Docker base images) and `cargo audit`'s nightly run; any reachable vulnerability auto-creates a `SEC REVIEW`-gated card with a 5-business-day SLA. `cargo-geiger`'s report is reviewed on the same cadence, specifically watching for dependency updates that introduce new `unsafe` usage — a signal this swimlane tracks that a typical dependency-update review in another language wouldn't have an equivalent for.

### 6.3 Incident response (outline)
1. Detect → 2. Contain (feature flag / disable route) → 3. Eradicate (patch, usually a `cargo update` + recompile for a dependency issue, or a code fix for a logic issue — memory-corruption-class root causes are structurally excluded for this project's own code, narrowing this step's usual scope) → 4. Recover (redeploy new static binaries) → 5. Post-mortem, feeding new abuse cases back into Phase 1.

### 6.4 Content & translation review schedule
- Quarterly re-verification that every `CornucopiaCard.content_sha256` still matches its source YAML.
- Quarterly Polish translation audit sampling 10% of `description_pl` fields against current `description_en` for staleness.

---

## Phase 7 — Rust-Specific SSDLC Considerations

1. **Memory safety is a real, checkable, CI-enforced property here — and this document is explicit about what it does and does not cover.** SR-08.3 states plainly that `#![forbid(unsafe_code)]` says nothing about business-logic correctness, translation accuracy, or any vulnerability class outside memory corruption. This project's abuse case AC-17 exists specifically to give this guarantee the same "here is the test that would fail if this broke" treatment every other requirement in this series gets, rather than letting it stand as an unverified architectural claim.
2. **This is a genuinely different kind of guarantee than the rest of the series, and the series' overall lesson is clearer for having both kinds represented.** `app03_python_django` through `app06_HASKELL_react` each pushed a *logical-correctness* property earlier (SQL shape, illegal states, safe deserialization). RustBastion adds a *physical-safety* property (no memory corruption) that none of those languages' type systems address at all — Go and Haskell are also memory-safe, but via garbage collection, a runtime cost Rust's ownership model avoids. Phase 2's STRIDE session already surfaced that this property doesn't map cleanly onto STRIDE's categories, which is itself worth stating rather than smoothing over.
3. **`cargo-geiger` closes the one gap `#![forbid(unsafe_code)]` leaves open, and this document treats that gap honestly.** The forbid-attribute only covers code this project's own crates compile — a dependency can still contain `unsafe`. Phase 4.3 makes `cargo-geiger`'s dependency-tree report a standing input to dependency-review judgment (not an automated pass/fail gate, since some `unsafe` in low-level dependencies like the TLS or SQL driver stack is often unavoidable and audited upstream) — a nuance a purely "we forbid unsafe code" summary would miss.
4. **Compile-time SQL checking (`sqlx::query!`) needs a live/cached schema at build time, the same operational trade-off `app05_go_react`'s `sqlc` and `app06_HASKELL_react`'s `hasql-th` accept.** Phase 0.2's CI setup and NFR-03.4's `cargo sqlx prepare`-committed-metadata requirement address this the same way those siblings do — this project does not get the compile-time-SQL-safety benefit "for free" any more than they did.

---

## SDLC × SSDLC Master Mapping Table

| Classic SDLC stage | SSDLC security activity in this project | Primary artifact |
|---|---|---|
| Planning & Analysis | Threat modeling with the project's own STRIDE deck; compliance mapping (GDPR/AI Act/NIS2/CISA memory-safety guidance); abuse cases AC-01–AC-17 | `requirements.md` §1–7, this document Phase 1 |
| Design | Trust-boundary diagram (`api` ↔ `worker` ↔ YAML source); least privilege via Axum's typed routes and `integrity::verify`'s caller list; STRIDE-per-component table | `PLAN.md` §3–5, this document Phase 2 |
| Implementation | Secure Rust coding standards (`sqlx::query!`, strict YAML decoding, typed `apalis` payloads, `#![forbid(unsafe_code)]`); TDD red-green with security tests (and `proptest` properties) written first | `user_stories+tests.md`, this document Phase 3 |
| Testing | SAST (`clippy`), memory-safety enforcement + dependency audit (`cargo-geiger`), SCA (`cargo audit`/`cargo-deny`), DAST (ZAP), abuse-case integration tests | this document Phase 4 |
| Deployment | CI/CD security gates, static-musl-binary hardening checklist, secrets management | this document Phase 5 |
| Maintenance | Runtime monitoring, Kanban-driven patch management (including `unsafe`-growth tracking), incident response, quarterly content/translation integrity review | this document Phase 6 |

---

## Agile Ceremonies — Security & i18n Integration Points

```
Sprint Planning        → New security/i18n stories pulled from backlog alongside features;
                          every card-deck story (US-05–US-12, US-19) is estimated with its Polish
                          translation review as part of the story, not a separate ticket.
Daily Standup          → "Any SEC REVIEW or I18N REVIEW blocker?" is a standing question.
Mid-Sprint Security Gate → Dedicated 30-minute slot for anything touching integrity::verify's
                          caller list, sqlx query modules, or apalis payload types.
Sprint Review          → Demo always includes one security-relevant moment (e.g., a PR that
                          fails to compile because it added an unsafe block, or the attack-demo
                          confirmation modal).
Sprint Retrospective   → One mandatory retro item: "did any security or translation issue
                          reach TEST or DONE that SEC REVIEW/I18N REVIEW should have caught?"
```

---

## Summary: SSDLC Compliance Checklist for RustBastion 2026

```
[ ] Threat model exists and is reviewed each quarter (Phase 0, 6.4)
[ ] integrity::verify has no importers outside its documented caller list (Phase 2.1, module-graph CI check)
[ ] All SQL access goes through sqlx::query!/query_as! — zero string-built queries (structurally true, Phase 3.1)
[ ] All six YAML decks decoded into deny_unknown_fields types; SHA-256 verified regardless (Phase 7.4→ see D-09)
[ ] Zero unsafe blocks in api/worker/core crates (#![forbid(unsafe_code)], compiler-enforced, Phase 4.2)
[ ] cargo-geiger dependency-tree unsafe report reviewed on every dependency update (Phase 6.2)
[ ] SAST (clippy)/SCA (cargo audit + cargo-deny)/DAST (ZAP) are all CI-blocking, not advisory (Phase 4)
[ ] Every abuse case AC-01–AC-17 has an automated regression test (Phase 4.5)
[ ] i18n key parity and translation review are enforced as release gates (Phase 1, I18N REVIEW column)
[ ] Card content (all 6 decks) is read-only in the application and change-controlled at the source
[ ] api and worker are separate binaries/containers with no published worker port
[ ] Production image size (≤ 25 MB) is CI-verified and reported honestly against both other siblings' figures (Phase 5.2)
[ ] Digital-by-Default Harms deck cannot carry a Severity value at the Rust type level — no severity
    value is ever present in its JSON encoding (Phase 1.3, FR-19.2)
[ ] Kanban board carries explicit SEC REVIEW and I18N REVIEW columns with WIP limits
[ ] Incident response and patch-management processes exist before, not after, first production release
```
