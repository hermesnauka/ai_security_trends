# GoSentry 2026 — SSDLC / SDLC Analysis

**Version:** 1.0
**Date:** 2026-07-07
**Document type:** Secure Software Development Lifecycle (SSDLC) analysis, mapped against the classic SDLC
**Scope:** Full lifecycle analysis of the application defined in `PLAN.md`, `requirements.md`, and `user_stories+tests.md`
**Methodology:** Agile — Scrum for planning/cadence, Kanban overlay for the engineering + security workflow
**Dotyczy:** US-01 – US-19 / Go 1.23 (chi + sqlc + pgx) + React 18

---

## Executive Summary

GoSentry 2026 carries the same double obligation as its sibling projects (`app01_react`, `app02_angular`, `app03_python_django`, `app04_scala_react`): it **teaches** OWASP/MITRE ATLAS/CompTIA SecAI+ security content, so it must itself **be** secure — an app about SQL Injection that is vulnerable to SQL Injection trains people with a false sense of authority.

This project's specific lifecycle emphasis follows from its choice of Go as the sole backend language:

1. **Compile-time and toolchain guarantees replace a class of runtime security testing that Java/Python/Scala need.** `sqlc` makes SQL injection a compile error, not a runtime finding; `go vet`/`staticcheck` catch entire bug classes before a test even runs. This shifts *when* in the SSDLC certain checks matter, and this document is explicit about which checks move earlier versus which ones (SAST, DAST, dependency scanning) remain exactly as necessary as for any other stack.
2. **A genuinely small deployable artifact changes the Deployment and Maintenance phases.** A statically-linked, `scratch`-container Go binary has no interpreter, no JVM, and (per `PLAN.md` D-06) a measurably smaller patch surface than the JVM/Python-based sibling apps — this is analyzed concretely in Phase 5/6 below, not just asserted.
3. **The same content-integrity and i18n obligations as `app03_python_django`/`app04_scala_react` still apply.** Six externally-authored YAML card decks (`docs/OWASP_stories/*.yaml`, including the non-technical Digital-by-Default Harms deck) are ingested as security-sensitive data, and the application is fully bilingual (PL/EN) with its own translation-review supply chain.

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
  Threat Model   internal/    go vet/staticcheck/ SAST(gosec)+   Static-binary    Runtime
  + Compliance   package      gosec at commit    DAST+SCA        scratch image;   monitoring +
  mapping        boundaries + time; sqlc removes (govulncheck)   30 MB image;     patch cadence +
  (OWASP/ATLAS/  least priv.  SQLi class at                      no interpreter   card-deck +
  SecAI+/GDPR)   (D-05, D-07) compile time                       inside           translation
                                                                                    integrity review
```

Both models describe the **same six stages**; SSDLC's contribution is that security activities happen *inside* each stage rather than as a single gate before release. §Master Mapping Table at the end of this document ties every classic SDLC stage to its SSDLC activity for this specific project.

---

## Agile Framework: Scrum for Cadence, Kanban for Flow

### Scrum structure

```
Sprint length:      2 weeks
Team size:           4–6 (3 Go engineers, 1 frontend/React engineer, 1 QA/security, 1 PL translator part-time)
Velocity target:     ~18–22 story points/sprint
Total duration:      14 sprints (~28 weeks) — matches PLAN.md §6 phases

Ceremonies:
  Sprint Planning        — Monday, Day 1, 2h max — pulls from the Product Backlog (PLAN.md §15 + this doc's abuse cases)
  Daily Standup          — daily, 15 min, includes a mandatory "any security blocker?" round
  Mid-Sprint Security Gate — Wednesday, Day 7, 30 min — peer review of anything touching auth, `internal/integrity`,
                             `internal/store` (sqlc queries), or River job argument types
  Sprint Review          — Friday, Day 10, 1h — demo includes a security angle (e.g. "here's a PR that adds a
                             `fmt.Sprintf`-built query and gets rejected by CI before a human even looks at it")
  Sprint Retrospective   — Friday, Day 10, 45 min — one mandatory security-process retro item
```

### Kanban board — security-gated columns

```
BACKLOG → SPRINT → IN DEV → SEC REVIEW → I18N REVIEW → TEST → DONE

  BACKLOG       Product backlog: user stories (US-01..US-19), bugs, abuse cases (AC-01..AC-16)
  SPRINT        Committed for the current sprint
  IN DEV        Actively coded — TDD red/green cycle in progress
  SEC REVIEW    Mandatory gate for anything touching: auth, `internal/integrity`, `internal/store`
                queries, River job Args types, or admin/editor permissions
  I18N REVIEW   Mandatory gate for anything adding user-visible strings or card translations —
                a native Polish speaker signs off before merge
  TEST          go test + httptest + Vitest + Playwright running in CI
  DONE          Meets the Definition of Done below

WIP limits:  IN DEV ≤ 2/dev · SEC REVIEW ≤ 3 total · I18N REVIEW ≤ 3 total · TEST ≤ 5 total
```

**A Go-specific Kanban nuance:** because `golangci-lint`/`go vet` run in seconds (no JVM/interpreter startup cost), this project runs them as a **pre-commit hook**, not only in CI — so a PR can arrive at the `IN DEV → SEC REVIEW` transition already free of an entire category of findings. This measurably shortens the `SEC REVIEW` column's average residency time versus the JVM-based sibling apps, and the Kanban board's cycle-time metric (tracked per column, per sprint) is expected to show it — a concrete, observable consequence of the toolchain choice, not just an assertion.

### Definition of Done (security- and i18n-enforced)

```
CODE QUALITY
  [ ] go test ./... passes; coverage ≥ 85% on internal/service
  [ ] gofmt/goimports clean; golangci-lint zero findings
  [ ] sqlc generate output committed and matches .sql sources (no drift)

SECURITY GATES
  [ ] gosec + staticcheck zero HIGH findings (bundled in golangci-lint)
  [ ] govulncheck zero reachable known vulnerabilities
  [ ] Peer security review completed for anything in the SEC REVIEW trigger list above
  [ ] No secrets committed (detect-secrets / trufflehog pre-commit hook green)
  [ ] All DB access via sqlc-generated functions — grep check for fmt.Sprintf building SQL forbidden
  [ ] internal/integrity.Verify has no importers under internal/http/** (depguard rule)

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

Sprint Zero opens with a structured threat-modeling session run using the STRIDE Elevation-of-Privilege deck this application itself will later serve (`docs/OWASP_stories/STRIDE__eop-cards-5.0-en.yaml`).

| Component | STRIDE categories in scope | Key finding → design decision |
|---|---|---|
| `internal/integrity` | Tampering, Elevation of Privilege | → `Verify()` only reachable from `cmd/api` boot and `cmd/worker`'s scheduled job — enforced by `depguard`, not just review (`PLAN.md` D-05) |
| `internal/store` (sqlc queries) | Tampering (SQLi) | → all queries generated by `sqlc` from `.sql` files, checked at compile time against the schema (D-02) |
| YAML card ingestion (`cmd/seed`, `ReingestDeck` job) | Tampering, Repudiation | → `yaml.UnmarshalStrict` into a fixed struct + SHA-256 verification (D-09) |
| PL/EN translation storage | Information Disclosure (mistranslation), Repudiation (who approved it?) | → translations stored with a reviewer identity, never machine-translated at request time |
| River job queue | Spoofing, Denial of Service | → typed `Args` structs validated at enqueue time (D-10, SR-13) |

### 0.2 Security tooling setup (added to CI and pre-commit before any feature branch merges)

```yaml
# .github/workflows/ci.yml (excerpt)
- name: Go vet + lint (SAST)
  run: golangci-lint run ./...
- name: Go SCA
  run: govulncheck ./...
- name: sqlc drift check
  run: sqlc generate && git diff --exit-code internal/store/sqlc-generated
- name: Container scan
  run: trivy image gosentry-api:latest gosentry-worker:latest
- name: i18n key parity
  run: node scripts/check-i18n-parity.js
- name: DAST baseline (every PR, passive only)
  run: docker run -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://staging.gosentry.local
```

```bash
# .git/hooks/pre-commit (installed via `make hooks`)
golangci-lint run --fast
gofmt -l . && exit 1 || true
```

### 0.3 Branch protection
- `main` requires 1 approval + all CI checks green + no `SEC REVIEW`/`I18N REVIEW` Kanban card still open for the linked issue.
- CODEOWNERS: `@security-team` required for `backend/internal/integrity/`, `backend/internal/store/queries/`, `data/hashes.json`, and any `docs/OWASP_stories/*.yaml` change.

---

## Phase 1 — Planning & Analysis (Secure Requirements)

### 1.1 Business goals vs security constraints

| Business goal | Security constraint it must respect |
|---|---|
| Teach OWASP/ATLAS/SecAI+ content accurately and fast | Content integrity (`requirements.md` SR-06) must not be sacrificed for speed of publishing |
| Serve both PL and EN learners | Missing translations degrade gracefully (FR-18.6), never a blank/broken page |
| Ship a minimal-footprint Go binary | Minimal footprint must not become an excuse to skip SAST/DAST/SCA — see Phase 4 |
| Cover all six Cornucopia decks, including the non-technical harms deck | The harms deck (US-19) must never be presented as if it had CVE-style severity — FR-19.2 |

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
| SR-02.1 (`sqlc` parameterized queries) | SQL Injection | Compile-time: a raw string cannot reach `pgx.Exec` without going through generated code; `depguard` rule blocks `fmt.Sprintf` flowing into query calls |
| SR-06.4 (`internal/integrity.Verify` import boundary) | A compromised HTTP handler forging a "content verified" record | `depguard` CI rule + `TestNoHandlerImportsIntegrity` (Go `go/packages` import-graph test) |
| SR-08 (`yaml.UnmarshalStrict`) | Malicious YAML exploiting arbitrary-object deserialization | Unit test asserting unknown YAML fields cause a decode error |
| FR-19.2 (harms-deck constructor has no `Severity` param) | Digital-by-Default Harms deck misread as a CVE-style severity list | `TestNewDesignHarmCard_HasNoSeverityField` — documents the constructor's fixed shape |

### 1.4 Abuse cases (negative user stories)

See `requirements.md` §7 for the full table (AC-01–AC-16). Highlights specific to this project's Go/River/typed-identifier choices:

| ID | Abuse case |
|---|---|
| AC-01 | An attacker crafts a `?q=` value hoping some handler builds SQL with `fmt.Sprintf` instead of a `sqlc` query. |
| AC-06 | An attacker submits a crafted `docs/OWASP_stories/*.yaml` PR hoping `internal/cards/loader.go` decodes into an untyped map that a later code path treats unsafely. |
| AC-14 | An attacker (or a bug) enqueues a malformed River job payload hoping `cmd/worker` executes it without validation. |
| AC-16 | A user copy-pastes the Digital-by-Default Harms deck into a vulnerability report as if `SCO2` were a CVSS-scored finding, because the UI failed to visually distinguish it. |

---

## Phase 2 — Secure Design

### 2.1 Trust boundaries

```
┌─────────────────────────── Untrusted ───────────────────────────┐
│  Browser (any locale, any user)                                  │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ HTTPS, JWT (stateless)
┌────────────────────────────── Trust Boundary 1 ──────────────────┐
│  Nginx → cmd/api (chi router, internal/http/**)                   │
│    - validates all input via go-playground/validator              │
│    - enforces auth/roles via middleware                            │
│    - MUST NOT import internal/integrity (depguard-enforced)        │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ enqueue river.Job row (same PostgreSQL, typed Args)
┌────────────────────────────── Trust Boundary 2 ──────────────────┐
│  cmd/worker (separate compiled binary + container)                 │
│    - runs internal/jobs/*, the ONLY caller of internal/integrity   │
│    - has no HTTP listener — unreachable from any browser request   │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ local filesystem read-only
┌────────────────────────────── Trust Boundary 3 ──────────────────┐
│  docs/OWASP_stories/*.yaml + data/hashes.json                     │
│    - treated as security-sensitive content, CODEOWNERS-gated      │
└────────────────────────────────────────────────────────────────────┘
```

**Design decision D-01 (this document):** `cmd/api` and `cmd/worker` are **two separately compiled Go binaries** sharing one module — not two threads of the same process, not a feature flag. This is a real OS-process boundary obtained essentially for free from Go's `cmd/*` convention, giving the same "who can call the security-sensitive function" guarantee that `app03_python_django` builds with an import-graph test and `app04_scala_react` builds with opaque types (see `PLAN.md` §3, §4 D-05).

### 2.2 Least privilege applied to the data model

- `CornucopiaCard` rows (all six decks) have **no** write path from any HTTP handler at all — not even an admin-JWT-gated one (`requirements.md` C-08). Only `cmd/seed`/`cmd/worker`'s `ReingestDeck` job writes them, inside a DB transaction.
- `editor` role can write `Threat`/`Mitigation`/`CodeSample`; only `admin` can delete.
- `cmd/worker` runs with the same least-privilege DB role as `cmd/api` — no superuser — because process separation alone is not sufficient if both processes have unbounded DB rights (SR-13.2).

### 2.3 STRIDE analysis of the designed architecture

| STRIDE | Applies to | Mitigation already in the design |
|---|---|---|
| Spoofing | Browser→API JWT; unauthenticated River job injection | JWT RS256 auth; jobs enqueued only from within `cmd/api`'s own service layer, never from user-controlled JSON directly |
| Tampering | YAML card content; DB records; SQL queries | `yaml.UnmarshalStrict` + SHA-256; ORM-free but `sqlc`-parameterized-only writes; CSRF n/a (stateless) |
| Repudiation | Who approved a translation or a hash-allowlist update | CODEOWNERS-enforced PR review logged in Git history; `ContentHash.VerifiedBy` field |
| Information Disclosure | Error responses; job failure detail | Generic 500 body to the client; full error + stack logged server-side only via `slog` |
| Denial of Service | Export jobs; search; card scraping | River async export (never blocks `cmd/api`); Redis sliding-window rate limit; `tsvector` GIN index |
| Elevation of Privilege | Editor trying to write `CornucopiaCard`; anonymous user hitting admin routes | No write path exists at all for cards (not just role-gated); JWT role middleware on every admin route |

### 2.4 Data classification

| Data | Classification | Handling |
|---|---|---|
| Threat/card content (EN + PL) | Public, but integrity-critical | SHA-256 verified, CODEOWNERS-reviewed |
| User accounts (email, password hash) | Personal data | `bcrypt` (cost ≥ 12), never logged |
| Bookmarks (anonymous) | Non-personal | `localStorage`, never sent server-side unless authenticated |
| JWT signing key, DB/Redis credentials | Secret | Environment variable / Docker secret, rotated quarterly |

---

## Phase 3 — Implementation (Secure Coding)

### 3.1 Secure coding standards — Go

```go
// ALWAYS — sqlc-generated, parameterized queries
// internal/store/queries/threats.sql:
//   -- name: ListThreatsByFramework :many
//   SELECT * FROM threats WHERE framework_code = $1 AND severity = $2;
threats, err := q.ListThreatsByFramework(ctx, frameworkCode, severity)

// ALWAYS — errors as values, no swallowed errors
threat, err := store.GetThreat(ctx, id)
if err != nil {
    return nil, fmt.Errorf("get threat %s: %w", id, err) // wrapped, never discarded
}

// ALWAYS — strict YAML decoding into a fixed struct
dec := yaml.NewDecoder(f)
dec.KnownFields(true) // rejects unknown fields — closest Go equivalent to "unknown-field-safe" parsing
var cardFile CardFile
if err := dec.Decode(&cardFile); err != nil {
    return fmt.Errorf("decode card file: %w", err)
}

// NEVER — string-built SQL
// query := fmt.Sprintf("SELECT * FROM threats WHERE code = '%s'", code) // FORBIDDEN, caught by depguard + gosec G201
```

### 3.2 Secure coding standards — River jobs

```go
// internal/jobs/export_csv.go
type ExportCSVArgs struct {
	Format    string `json:"format" validate:"oneof=csv"`
	Framework string `json:"framework" validate:"required,alphanum"`
}

func (w *ExportCSVWorker) Work(ctx context.Context, job *river.Job[ExportCSVArgs]) error {
	if err := validate.Struct(job.Args); err != nil {
		return fmt.Errorf("invalid export args: %w", err) // rejected before any DB/file work happens
	}
	// ... business logic calls internal/service, never internal/store directly ...
}
```

### 3.3 Sprint-by-sprint security activities

| Sprint | Feature work | Security activity in parallel |
|---|---|---|
| 1–2 | Foundation, auth | Threat model review of auth flow; `golangci-lint` wired into CI (not yet blocking) |
| 3–4 | Threat browser | SAST becomes blocking; first abuse-case test (AC-01, sqlc parameterization) |
| 5–7 | Card decks (all six, including `dbd`) + integrity | AC-06, AC-16 abuse tests written FIRST (TDD) before the ingestion command exists |
| 7–9 | 5-language code samples | Review that no `ATTACK_DEMO` sample is runnable without the confirmation gate |
| 9–10 | i18n | I18N REVIEW Kanban column activated |
| 10–12 | Search, export, matrix | AC-14 (River job validation) test added; DAST baseline extended to `/export/` and `/search/` |
| 12–14 | Hardening & release | Full ZAP active scan; abuse-case sweep across AC-01..AC-16 |

---

## Phase 4 — Security Testing

### 4.1 Test pyramid with security layers

```
E2E (Playwright)         — includes AC-01..AC-16 abuse-case scenarios end-to-end
httptest integration     — auth/permission boundary tests per handler
Unit tests (go test)     — sqlc query behavior, YAML strict-decode rejection, typed-identifier
                            constructors, River Args validation
```

### 4.2 SAST
`golangci-lint` bundles `gosec` (SQL injection patterns, hardcoded credentials, weak crypto), `staticcheck` (correctness/simplicity issues), and `go vet` (suspicious constructs) — all run on every PR and, per Phase 0's Kanban note, in a pre-commit hook. A custom `depguard` rule enforces the `internal/http` → `internal/integrity` import ban.

### 4.3 SCA
`govulncheck` — Go's official vulnerability scanner — reports only vulnerabilities **reachable from the actual call graph**, not merely present in `go.sum`; this reduces false-positive noise compared to a naive dependency-list scanner and is run on every PR plus nightly. `npm audit` and Trivy cover the frontend and both container images.

### 4.4 DAST (OWASP ZAP)
Baseline (passive) scan on every PR against staging; full active scan before each production release, targeting all public `cmd/api` routes. `cmd/worker` is not a ZAP target because it exposes no HTTP port at all — verified by a network-level test asserting a connection attempt from outside the Docker network is refused.

### 4.5 Abuse-case tests (integration level)
```go
func TestAC06_YamlLoader_RejectsUnknownFields(t *testing.T) {
	malicious := []byte("suits:\n- id: EVIL\n  exec: rm -rf /\n")
	_, err := cards.DecodeCardFile(bytes.NewReader(malicious))
	assert.Error(t, err) // KnownFields(true) rejects the unrecognized "exec" key
}

func TestAC14_ExportCSVArgs_RejectsMissingFramework(t *testing.T) {
	args := jobs.ExportCSVArgs{Format: "csv"}
	err := validate.Struct(args)
	assert.Error(t, err)
}
```

### 4.6 Security regression testing
Every fixed security bug gets a permanent regression test, run on every CI build, never skipped.

---

## Phase 5 — Deployment (Secure Release)

### 5.1 CI/CD pipeline with security gates
```
lint/vet → unit tests → SAST (golangci-lint) → SCA (govulncheck) → build static binaries
   → build scratch images → container scan (Trivy) → deploy to staging → DAST baseline
   → E2E (Playwright) → manual QA sign-off → deploy to production (blue/green)
   → DAST full scan (scheduled, not blocking)
```

### 5.2 Infrastructure hardening checklist
```
Nginx        TLS 1.2+/1.3 only; HSTS; security headers; request size limits
cmd/api      DEBUG-level verbose errors disabled in prod; generic 500 body
cmd/worker   no published port at all; only outbound connections to Postgres/Redis
PostgreSQL   least-privilege role for both api and worker (no SUPERUSER); network isolated
Redis        password-protected (requirepass); not exposed on the host
Docker       cmd/api and cmd/worker images: FROM scratch or distroless/static, non-root UID,
             CGO_ENABLED=0 — no shell, no package manager, no interpreter inside the container
```

**Concrete deployment-footprint comparison (Phase 5 analysis, not marketing):** `PLAN.md` NFR-07.1 sets a ≤ 30 MB target for the `cmd/api` production image, verified by a CI size-check step. This is a testable SSDLC claim, not an assertion — the CI job fails the build if the image exceeds the budget, which is the same rigor this plan applies to test coverage or SAST findings.

### 5.3 Secrets management
`.env` files never committed; JWT signing key, DB/Redis credentials injected via Docker secrets / GitHub Actions secrets, rotated quarterly and immediately on suspected exposure.

---

## Phase 6 — Maintenance & Runtime Monitoring

### 6.1 Runtime monitoring
- `prometheus/client_golang` exposes `/api/v1/metrics`; Grafana dashboards track request latency, rate-limit rejections, `content_integrity_check_ok` gauge, River job queue depth/failure rate.
- A Loki alert `SEC-CARD-HASH-MISMATCH` fires directly from `internal/integrity`'s `slog.Error` call.

### 6.2 Patch management (Kanban)
A dedicated `DEPENDENCY UPDATES` swimlane, fed weekly by Dependabot (Go modules + npm + Docker base images) and `govulncheck`'s nightly run; any reachable vulnerability auto-creates a `SEC REVIEW`-gated card with a 5-business-day SLA. Go's comparatively small, curated dependency tree (versus a typical Java/Node backend) is expected to keep this swimlane's average size measurably smaller — tracked as a Kanban metric, not assumed.

### 6.3 Incident response (outline)
1. Detect → 2. Contain (feature flag / disable route) → 3. Eradicate (patch, often a single `go get -u` + `go mod tidy` for a Go-only backend) → 4. Recover (redeploy — a new static binary, no dependency-resolution surprises at runtime) → 5. Post-mortem, feeding new abuse cases back into Phase 1.

### 6.4 Content & translation review schedule
- Quarterly re-verification that every `CornucopiaCard.ContentSHA256` still matches its source YAML.
- Quarterly Polish translation audit sampling 10% of `DescriptionPl` fields against current `DescriptionEn` for staleness.

---

## Phase 7 — Go-Specific SSDLC Considerations (unique to this project vs. the JVM/Python siblings)

1. **Static typing removes a vulnerability class, but the plan says so explicitly rather than relying on it silently.** `PLAN.md` D-09 and `requirements.md` SR-08 both state plainly that Go's `yaml.v3` decoding into a fixed struct removes the "arbitrary object construction from untrusted YAML" gadget class that motivates `yaml.safe_load`/`SafeConstructor` elsewhere — and both immediately add that SHA-256 integrity verification (SR-06) still applies unconditionally, because "the parser can't be tricked into RCE" is not the same claim as "the content is trustworthy."
2. **Compile-time SQL safety changes *when* SR-02 is verified, not *whether* it needs a runtime test too.** `sqlc` prevents most SQL-injection-shaped mistakes from compiling at all, but `requirements.md` SR-02.2 and the AC-01 abuse-case test still exist — a generated function called with attacker-controlled arguments in a logically wrong way (e.g., an `OR 1=1`-equivalent business-logic bug rather than a syntax injection) is a different failure mode compile-time typing does not catch.
3. **Small dependency graphs shrink the SCA surface but do not remove Phase 4 obligations.** `govulncheck` is call-graph-aware specifically so a genuinely small, mostly-stdlib Go backend does not lull the team into skipping SCA — the tool still runs on every PR (Phase 4.3), and the smaller graph is treated as a benefit to remediation *speed*, not a reason to lower the bar.
4. **The `internal/` package boundary is a compiler feature repurposed as a least-privilege control.** Unlike `app03_python_django`'s import-graph unit test or `app04_scala_react`'s opaque types, Go's `internal/` visibility rule is enforced by the compiler itself for cross-module access; this project adds `depguard` specifically to close the remaining gap (intra-module access from `internal/http` into `internal/integrity`), because the compiler alone does not prevent that.

---

## SDLC × SSDLC Master Mapping Table

| Classic SDLC stage | SSDLC security activity in this project | Primary artifact |
|---|---|---|
| Planning & Analysis | Threat modeling with the project's own STRIDE deck; compliance mapping (GDPR/AI Act/NIS2); abuse cases AC-01–AC-16 | `requirements.md` §1–7, this document Phase 1 |
| Design | Trust-boundary diagram (`cmd/api` ↔ `cmd/worker` ↔ YAML source); least privilege on `CornucopiaCard` and `internal/integrity`; STRIDE-per-component table | `PLAN.md` §3–5, this document Phase 2 |
| Implementation | Secure Go coding standards (`sqlc`, strict YAML, typed River args); TDD red-green with security tests written first | `user_stories+tests.md`, this document Phase 3 |
| Testing | SAST (`golangci-lint`), SCA (`govulncheck`), DAST (ZAP), abuse-case integration tests | this document Phase 4 |
| Deployment | CI/CD security gates, static-binary hardening checklist, secrets management | this document Phase 5 |
| Maintenance | Runtime monitoring, Kanban-driven patch management, incident response, quarterly content/translation integrity review | this document Phase 6 |

---

## Agile Ceremonies — Security & i18n Integration Points

```
Sprint Planning        → New security/i18n stories pulled from backlog alongside features;
                          every card-deck story (US-05–US-12, US-19) is estimated with its Polish
                          translation review as part of the story, not a separate ticket.
Daily Standup          → "Any SEC REVIEW or I18N REVIEW blocker?" is a standing question.
Mid-Sprint Security Gate → Dedicated 30-minute slot for anything touching internal/integrity,
                          internal/store queries, or River job Args types.
Sprint Review          → Demo always includes one security-relevant moment (e.g., a PR that
                          `depguard` blocked, or the attack-demo confirmation modal).
Sprint Retrospective   → One mandatory retro item: "did any security or translation issue
                          reach TEST or DONE that SEC REVIEW/I18N REVIEW should have caught?"
```

---

## Summary: SSDLC Compliance Checklist for GoSentry 2026

```
[ ] Threat model exists and is reviewed each quarter (Phase 0, 6.4)
[ ] internal/integrity.Verify has no importers under internal/http/** (depguard-enforced, Phase 2.1)
[ ] All SQL access goes through sqlc-generated functions — zero string-built queries (Phase 3.1)
[ ] All six YAML decks decoded with KnownFields(true); SHA-256 verified regardless (Phase 7.1)
[ ] SAST (golangci-lint)/SCA (govulncheck)/DAST (ZAP) are all CI-blocking, not advisory (Phase 4)
[ ] Every abuse case AC-01–AC-16 has an automated regression test (Phase 4.5)
[ ] i18n key parity and translation review are enforced as release gates (Phase 1, I18N REVIEW column)
[ ] Card content (all 6 decks) is read-only in the application and change-controlled at the source
[ ] cmd/api and cmd/worker are separate binaries/containers with no published worker port
[ ] Production images are static, scratch/distroless, ≤ 30 MB, CI-verified (Phase 5.2)
[ ] Digital-by-Default Harms deck cannot carry a Severity value at the Go type level (Phase 1.3, FR-19.2)
[ ] Kanban board carries explicit SEC REVIEW and I18N REVIEW columns with WIP limits
[ ] Incident response and patch-management processes exist before, not after, first production release
```
