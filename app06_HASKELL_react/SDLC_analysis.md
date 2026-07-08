# HaskShield 2026 — SSDLC / SDLC Analysis

**Version:** 1.0
**Date:** 2026-07-07
**Document type:** Secure Software Development Lifecycle (SSDLC) analysis, mapped against the classic SDLC
**Scope:** Full lifecycle analysis of the application defined in `PLAN.md`, `requirements.md`, and `user_stories+tests.md`
**Methodology:** Agile — Scrum for planning/cadence, Kanban overlay for the engineering + security workflow
**Dotyczy:** US-01 – US-19 / Haskell (GHC 9.8, servant + hasql-th) + React 18

---

## Executive Summary

HaskShield 2026 carries the same double obligation as its sibling projects (`app01_react`, `app02_angular`, `app03_python_django`, `app04_scala_react`, `app05_go_react`): it **teaches** OWASP/MITRE ATLAS/CompTIA SecAI+ security content, so it must itself **be** secure — an app about SQL Injection that is vulnerable to SQL Injection trains people with a false sense of authority.

This project pushes the series' recurring theme — "use the language's own tools to move a security guarantee from a runtime check to something checked earlier" — to its logical extreme:

1. **Illegal states are made unrepresentable, not merely rejected.** The Digital-by-Default Harms deck (US-19) does not have a nullable severity field that a validator must remember to check — its `CardKind` type has a `DesignHarm` constructor with no severity field at all. This is qualitatively different from a runtime `if` that could be forgotten, and this document treats it as such throughout Phase 1–2.
2. **Effects are visible in types (`PLAN.md` D-03).** A function's signature tells a reviewer, without reading its body, whether it can touch the database, filesystem, or network — this changes what a code review can verify from the diff alone, analyzed in Phase 3.
3. **The trade-offs are stated honestly, not oversold.** GHC's runtime system makes the production image larger than `app05_go_react`'s static Go binary (`PLAN.md` D-09); this document does not claim Haskell "wins" deployment footprint — it documents where the type-system investment pays off (correctness, illegal-state elimination) and where it does not (binary size, cold-start), consistent with this series' practice of stating specific, checkable engineering claims rather than language-tribalism.
4. **The same content-integrity and i18n obligations as every sibling app still apply.** Six externally-authored YAML card decks (`docs/OWASP_stories/*.yaml`, including the non-technical Digital-by-Default Harms deck) are ingested as security-sensitive data, and the application is fully bilingual (PL/EN) with its own translation-review supply chain — a strong type system does not verify a translation is accurate, and this plan does not pretend otherwise.

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
  Threat Model   ADTs make    -Wall -Werror at   SAST(hlint/    Multi-stage      Runtime
  + Compliance   illegal      commit time;       stan)+DAST+   Docker build;    monitoring +
  mapping        states       hasql-th removes   SCA           documented       patch cadence +
  (OWASP/ATLAS/  unrepresent- SQLi class at       (osv-scanner) ≤120MB image     card-deck +
  SecAI+/GDPR)   able (D-01,  compile time                      size            translation
                 D-04, D-08)                                                     integrity review
```

Both models describe the **same six stages**; SSDLC's contribution is that security activities happen *inside* each stage rather than as a single gate before release. §Master Mapping Table at the end of this document ties every classic SDLC stage to its SSDLC activity for this specific project.

---

## Agile Framework: Scrum for Cadence, Kanban for Flow

### Scrum structure

```
Sprint length:      2 weeks
Team size:           3–5 Haskell engineers, 1 frontend/React engineer, 1 QA/security, 1 PL translator part-time
                      (a smaller backend team than the JVM/Go siblings is realistic here — Haskell's
                      type system catches classes of bugs in review that other stacks catch in QA,
                      which shifts effort but does not reduce the total sprint scope)
Velocity target:     ~16–20 story points/sprint (slightly lower than app05_go_react's estimate,
                      reflecting a steeper initial learning curve for contributors new to Haskell —
                      stated honestly here rather than assumed away)
Total duration:      14–16 sprints (~28–32 weeks) — matches PLAN.md §6 phases

Ceremonies:
  Sprint Planning        — Monday, Day 1, 2h max — pulls from the Product Backlog (PLAN.md §15 + this doc's abuse cases)
  Daily Standup          — daily, 15 min, includes a mandatory "any security blocker?" round
  Mid-Sprint Security Gate — Wednesday, Day 7, 30 min — peer review of anything touching auth,
                             Integrity.Verify's export list, hasql-th statements, or odd-jobs Args types
  Sprint Review          — Friday, Day 10, 1h — demo includes a security angle (e.g. "here's a PR
                             that tries to add a Severity field to DesignHarm and fails to compile")
  Sprint Retrospective   — Friday, Day 10, 45 min — one mandatory security-process retro item
```

### Kanban board — security-gated columns

```
BACKLOG → SPRINT → IN DEV → SEC REVIEW → I18N REVIEW → TEST → DONE

  BACKLOG       Product backlog: user stories (US-01..US-19), bugs, abuse cases (AC-01..AC-16)
  SPRINT        Committed for the current sprint
  IN DEV        Actively coded — TDD red/green cycle in progress
  SEC REVIEW    Mandatory gate for anything touching: auth, Integrity.Verify's export list,
                Store/Statements (hasql-th), odd-jobs Args types, or admin/editor permissions
  I18N REVIEW   Mandatory gate for anything adding user-visible strings or card translations —
                a native Polish speaker signs off before merge
  TEST          hspec + QuickCheck + hspec-wai + Vitest + Playwright running in CI
  DONE          Meets the Definition of Done below

WIP limits:  IN DEV ≤ 2/dev · SEC REVIEW ≤ 3 total · I18N REVIEW ≤ 3 total · TEST ≤ 5 total
```

**A Haskell-specific Kanban nuance, stated both ways:** `-Wall -Werror` and `hlint` catch a wide category of mistakes *before compilation succeeds at all*, which — like `app05_go_react`'s pre-commit `golangci-lint` — shortens `SEC REVIEW`'s average residency for issues that are purely mechanical (an unhandled pattern match, an unused import that turns out to hide a forgotten case). It does **not** shorten `SEC REVIEW` for issues about *business logic correctness* (does this authorization rule actually implement least privilege?) — the compiler has no opinion on that, and this project's Kanban cycle-time metric is expected to show a bimodal distribution in `SEC REVIEW`, not a uniformly fast one, which the team should watch for rather than assume away.

### Definition of Done (security- and i18n-enforced)

```
CODE QUALITY
  [ ] cabal test passes; hpc coverage ≥ 85% on src/Service
  [ ] cabal build -Wall -Werror clean; hlint/stan zero findings
  [ ] Every new hasql-th statement compiles against the current migrated schema (no drift possible by construction)

SECURITY GATES
  [ ] hlint + stan zero HIGH-severity findings
  [ ] osv-scanner zero known-vulnerable dependency versions in cabal.project.freeze
  [ ] Peer security review completed for anything in the SEC REVIEW trigger list above
  [ ] No secrets committed (detect-secrets / trufflehog pre-commit hook green)
  [ ] All DB access via hasql-th statements — no Text-concatenated SQL exists (structurally true, spot-checked anyway)
  [ ] Integrity.Verify's module export list unchanged, or changed with explicit SEC REVIEW sign-off

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
| `Integrity.Verify` | Tampering, Elevation of Privilege | → exported to an explicit, tiny caller list; CI greps the module-dependency graph for violations (`PLAN.md` D-05) |
| `Store.Statements` (hasql-th) | Tampering (SQLi) | → all queries checked against the live schema at compile time (D-02) |
| YAML card ingestion | Tampering, Repudiation | → `Data.Yaml.decodeFileEither` into closed ADTs + SHA-256 verification (D-07) |
| PL/EN translation storage | Information Disclosure (mistranslation), Repudiation | → translations stored with a reviewer identity |
| `odd-jobs` queue | Spoofing, Denial of Service | → typed, `FromJSON`-decoded Args validated at enqueue time (D-10) |
| Digital-by-Default Harms deck | (not a STRIDE-shaped risk — a *presentation* risk) | → `CardKind` sum type makes the mis-presentation structurally impossible (D-01) — the STRIDE session itself flagged that this risk doesn't fit STRIDE's categories, which is itself a useful finding documented here rather than force-fit into one |

### 0.2 Security tooling setup

```yaml
# .github/workflows/ci.yml (excerpt)
- name: Lint (SAST)
  run: hlint . && stan check
- name: Build with warnings as errors
  run: cabal build --ghc-options="-Wall -Werror"
- name: SCA
  run: osv-scanner --lockfile=cabal.project.freeze
- name: Container scan
  run: trivy image hasshield-api:latest hasshield-worker:latest
- name: i18n key parity
  run: node scripts/check-i18n-parity.js
- name: DAST baseline (every PR, passive only)
  run: docker run -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://staging.hasshield.local
```

```bash
# pre-commit hook
hlint --no-exit-code . || true    # fast feedback locally; CI is authoritative
```

### 0.3 Branch protection
- `main` requires 1 approval + all CI checks green + no `SEC REVIEW`/`I18N REVIEW` Kanban card still open for the linked issue.
- CODEOWNERS: `@security-team` required for `backend/src/Integrity/`, `backend/src/Store/Statements/`, `data/hashes.json`, and any `docs/OWASP_stories/*.yaml` change.

---

## Phase 1 — Planning & Analysis (Secure Requirements)

### 1.1 Business goals vs security constraints

| Business goal | Security constraint it must respect |
|---|---|
| Teach OWASP/ATLAS/SecAI+ content accurately and fast | Content integrity (`requirements.md` SR-06) must not be sacrificed for speed of publishing |
| Serve both PL and EN learners | Missing translations degrade gracefully (FR-18.6), never a blank/broken page |
| Use Haskell's type system to its full advantage | The type-system investment must target *real* risk (US-19's harms-deck confusion, password/hash mixups) — not become an excuse to under-invest in SAST/DAST/SCA, which remain fully in scope (Phase 4) |
| Cover all six Cornucopia decks, including the non-technical harms deck | The harms deck (US-19) must never be presented as if it had CVE-style severity — FR-19.2, enforced at the type level (D-01) |

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
| SR-02.1 (`hasql-th` compile-time-checked SQL) | SQL Injection | Compile failure if a statement's shape doesn't match the schema; no code path bypasses `hasql-th` to reach the database |
| SR-06.4 (`Integrity.Verify` export list) | A compromised handler forging a "content verified" record | Module export list + CI module-dependency-graph grep |
| SR-08.3 (`prop_unknownFieldsRejected`) | Malicious YAML exploiting lenient/partial decoding | QuickCheck property generating random extra fields |
| FR-19.2 (`CardKind` sum type) | Digital-by-Default Harms deck misread as a CVE-style severity list | `hspec` test asserting the JSON encoding of a `DesignHarm` value has no `severity` key — the strongest form of this guarantee across the whole app series (§Executive Summary point 1) |

### 1.4 Abuse cases (negative user stories)

See `requirements.md` §7 for the full table (AC-01–AC-16). Highlights specific to this project's Haskell/type-level choices:

| ID | Abuse case |
|---|---|
| AC-01 | An attacker crafts a `?q=` value hoping some handler builds SQL by string concatenation instead of `hasql-th` — there is no such code path to exploit, and the abuse-case test documents that fact rather than "catching" an actual vulnerable path. |
| AC-06 | An attacker submits a crafted `docs/OWASP_stories/*.yaml` PR hoping `Cards.Loader` decodes into something looser than the declared ADTs. |
| AC-14 | An attacker (or a bug) enqueues a malformed `odd-jobs` payload hoping the worker executes it without validation. |
| AC-16 | A user copy-pastes the Digital-by-Default Harms deck into a vulnerability report as if `SCO2` were a CVSS-scored finding — the API response for these cards has no `severity` key to have copy-pasted in the first place. |

---

## Phase 2 — Secure Design

### 2.1 Trust boundaries

```
┌─────────────────────────── Untrusted ───────────────────────────┐
│  Browser (any locale, any user)                                  │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ HTTPS, JWT (stateless)
┌────────────────────────────── Trust Boundary 1 ──────────────────┐
│  Nginx → api executable (servant handlers, src/Api/**)             │
│    - validates all input via servant's request-body decoding       │
│      into typed request ADTs (invalid JSON shape = 400 before a    │
│      handler ever runs — this is servant's own contribution,       │
│      distinct from application-level validation)                   │
│    - enforces auth/roles via middleware                             │
│    - MUST NOT import Integrity.Verify (module-graph CI check)       │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ enqueue odd-jobs row (same PostgreSQL, typed Args)
┌────────────────────────────── Trust Boundary 2 ──────────────────┐
│  worker executable (separate compiled binary + container)          │
│    - runs Jobs.*, the ONLY caller of Integrity.Verify               │
│    - has no HTTP listener — unreachable from any browser request   │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ local filesystem read-only
┌────────────────────────────── Trust Boundary 3 ──────────────────┐
│  docs/OWASP_stories/*.yaml + data/hashes.json                     │
│    - treated as security-sensitive content, CODEOWNERS-gated      │
└────────────────────────────────────────────────────────────────────┘
```

**Design decision D-01 (this document; not to be confused with `PLAN.md`'s own D-01, the `CardKind` sum type):** `api` and `worker` are two separately compiled executables from one Cabal package — a real OS-process boundary, the same pattern `app05_go_react` uses with `cmd/api`/`cmd/worker`. The novelty here is `servant`'s contribution *within* Trust Boundary 1: because every route's request/response shape is a Haskell type, a malformed request body is rejected by the framework's own decoding step, before any handler-specific validation logic runs at all — narrowing the surface application code even needs to defend.

### 2.2 Least privilege applied to the data model

- `CornucopiaCard` rows (all six decks) have **no** write path from any HTTP handler — not even an admin-JWT-gated one (`requirements.md` C-08). The `Api.Spec` servant type has no route through which such a request could even be well-typed; only `app/Seed.hs`/the `ReingestDeck` job write them.
- `editor` role can write `Threat`/`Mitigation`/`CodeSample`; only `admin` can delete.
- `worker` runs with the same least-privilege DB role as `api` — no superuser.

### 2.3 STRIDE analysis of the designed architecture

| STRIDE | Applies to | Mitigation already in the design |
|---|---|---|
| Spoofing | Browser→API JWT; unauthenticated job injection | JWT RS256 (`jose`); jobs enqueued only from within `api`'s own service layer |
| Tampering | YAML card content; DB records; SQL queries | `Data.Yaml.decodeFileEither` + SHA-256; `hasql-th`-only writes |
| Repudiation | Who approved a translation or a hash-allowlist update | CODEOWNERS-enforced PR review logged in Git history; `hashVerifiedBy` field |
| Information Disclosure | Error responses; job failure detail | Generic error body to the client; full detail logged server-side only via `katip` |
| Denial of Service | Export jobs; search; card scraping | `odd-jobs` async export (never blocks `api`); STM/Redis rate limit; `tsvector` GIN index |
| Elevation of Privilege | Editor trying to write `CornucopiaCard`; anonymous user hitting admin routes | No write route exists at all for cards; JWT role middleware on every admin route |

### 2.4 Data classification

| Data | Classification | Handling |
|---|---|---|
| Threat/card content (EN + PL) | Public, but integrity-critical | SHA-256 verified, CODEOWNERS-reviewed |
| User accounts (email, password hash) | Personal data | `PasswordHash Bcrypt` (phantom-typed, D-04), never logged as if it were `Password` |
| Bookmarks (anonymous) | Non-personal | `localStorage`, never sent server-side unless authenticated |
| JWT signing key, DB/Redis credentials | Secret | Environment variable / Docker secret, rotated quarterly |

---

## Phase 3 — Implementation (Secure Coding)

### 3.1 Secure coding standards — Haskell

```haskell
-- ALWAYS — hasql-th, compile-time-checked against the live schema
listThreatsByFramework :: Statement (Text, Severity) [Threat]
listThreatsByFramework = [TH.vectorStatement|
  SELECT * FROM threats WHERE framework_code = $1 :: text AND severity = $2 :: severity_enum
  |]

-- ALWAYS — effects visible in the type (D-03); a reviewer can tell this touches IO from the signature alone
getThreat :: ThreatId -> ExceptT ApiError IO Threat

-- ALWAYS — strict, ADT-targeted YAML decoding, unknown fields rejected
instance FromJSON CardFile where
  parseJSON = withObject "CardFile" $ \o -> do
    unrecognized <- pure (HM.keys o \\ knownCardFileKeys)
    unless (null unrecognized) $ fail ("unrecognized fields: " <> show unrecognized)
    CardFile <$> o .: "meta" <*> o .: "suits"

-- NEVER — Text-concatenated SQL (there is no function in this codebase capable of executing one;
-- this comment documents the absence, not a rule that could be violated)
```

### 3.2 Secure coding standards — `odd-jobs`

```haskell
data ExportCsvArgs = ExportCsvArgs
  { exportFormat    :: Text
  , exportFramework :: Text
  } deriving (Generic, FromJSON, ToJSON)

validateArgs :: ExportCsvArgs -> Either ValidationError ExportCsvArgs
validateArgs args
  | T.null (exportFramework args) = Left (ValidationError "framework" "must not be empty")
  | exportFormat args /= "csv"    = Left (ValidationError "format" "must be csv")
  | otherwise                     = Right args
```

### 3.3 Sprint-by-sprint security activities

| Sprint | Feature work | Security activity in parallel |
|---|---|---|
| 1–2 | Foundation, auth | Threat model review of auth flow; `-Wall -Werror` + `hlint` wired into CI (not yet blocking) |
| 3–4 | Threat browser | SAST becomes blocking; first abuse-case test (AC-01, documenting the absent SQLi path) |
| 5–7 | Card decks (all six, including `dbd`) + integrity | AC-06, AC-16 abuse tests written FIRST (TDD) before the ingestion command exists |
| 7–9 | 5-language code samples | Review that no `AttackDemo` sample is runnable without the confirmation gate |
| 9–10 | i18n | I18N REVIEW Kanban column activated |
| 10–12 | Search, export, matrix | AC-14 (`odd-jobs` Args validation) test added; DAST baseline extended to `/export/` and `/search/` |
| 12–14 | Hardening & release | Full ZAP active scan; abuse-case sweep across AC-01..AC-16 |

---

## Phase 4 — Security Testing

### 4.1 Test pyramid with security layers

```
E2E (Playwright)          — includes AC-01..AC-16 abuse-case scenarios end-to-end
hspec-wai integration      — auth/permission boundary tests per handler
hspec examples             — service-layer behavior with concrete fixtures
QuickCheck properties      — invariants over generated data: YAML decode-rejects-unknown-fields,
                             every mitigation has 5 languages, DesignHarm never serializes a severity key
```

### 4.2 SAST
`hlint` (idiomatic-pattern suggestions, some security-relevant — e.g. flags `unsafePerformIO` misuse) and `stan` (a newer static analyzer catching partial-function usage, unused bindings that hide dead branches) run on every PR. GHC's own `-Wall -Werror`, with `-Wincomplete-patterns` specifically, turns an unhandled constructor in any `case` over `CardKind`, `Severity`, or `StrideCategory` into a build failure — the compiler itself performing a category of SAST no external tool needs to.

### 4.3 SCA
`osv-scanner` checks the Cabal/Hackage dependency freeze file against the OSV database on every PR and nightly. `npm audit` and Trivy cover the frontend and both container images.

### 4.4 DAST (OWASP ZAP)
Baseline (passive) scan on every PR against staging; full active scan before each production release, targeting all public `api` routes. `worker` is not a ZAP target because it exposes no HTTP port — verified by a network-level test.

### 4.5 Abuse-case tests (integration level)
```haskell
spec :: Spec
spec = describe "AC-06 YAML loader" $
  it "rejects a card file with an unrecognized top-level key" $ do
    let malicious = "meta:\n  edition: evil\nexec: rm -rf /\n"
    Cards.Loader.decodeCardFile malicious `shouldSatisfy` isLeft

spec2 :: Spec
spec2 = describe "AC-14 ExportCsvArgs" $
  it "rejects args with an empty framework" $
    Jobs.ExportCsv.validateArgs (ExportCsvArgs "csv" "") `shouldSatisfy` isLeft
```

### 4.6 Security regression testing
Every fixed security bug gets a permanent regression test (`hspec` example or QuickCheck property, whichever fits), run on every CI build, never skipped.

---

## Phase 5 — Deployment (Secure Release)

### 5.1 CI/CD pipeline with security gates
```
lint (hlint/stan) → build -Wall -Werror → unit+property tests → SCA (osv-scanner)
   → build multi-stage Docker images → container scan (Trivy) → deploy to staging
   → DAST baseline → E2E (Playwright) → manual QA sign-off → deploy to production (blue/green)
   → DAST full scan (scheduled, not blocking)
```

### 5.2 Infrastructure hardening checklist
```
Nginx        TLS 1.2+/1.3 only; HSTS; security headers; request size limits
api          verbose GHC exception detail disabled in prod; generic error body to clients
worker       no published port at all; only outbound connections to Postgres/Redis
PostgreSQL   least-privilege role for both api and worker (no SUPERUSER); network isolated
Redis        password-protected (requirepass); not exposed on the host
Docker       multi-stage build (haskell:9.8 builder → debian:bookworm-slim runtime), non-root user
```

**Honest deployment-footprint note (Phase 5 analysis, not marketing):** `requirements.md` NFR-07.1 targets ≤ 120 MB for the `api` production image — a testable, CI-enforced number, explicitly *not* claimed to match `app05_go_react`'s ≤ 30 MB static-binary target. This series' practice throughout has been to make deployment-footprint claims specific and checkable rather than comparative marketing, and this is the app where that discipline matters most, given how easy it would be to overclaim "Haskell is also minimal."

### 5.3 Secrets management
`.env` files never committed; JWT signing key, DB/Redis credentials injected via Docker secrets / GitHub Actions secrets, rotated quarterly and immediately on suspected exposure.

---

## Phase 6 — Maintenance & Runtime Monitoring

### 6.1 Runtime monitoring
- `prometheus-client` exposes `/api/v1/metrics`; Grafana dashboards track request latency, rate-limit rejections, `content_integrity_check_ok` gauge, `odd-jobs` queue depth/failure rate.
- A Loki alert `SEC-CARD-HASH-MISMATCH` fires directly from `Integrity.Verify`'s `katip` error log.

### 6.2 Patch management (Kanban)
A dedicated `DEPENDENCY UPDATES` swimlane, fed weekly by Dependabot-equivalent Hackage-freeze-file bumps and `osv-scanner`'s nightly run; any reachable vulnerability auto-creates a `SEC REVIEW`-gated card with a 5-business-day SLA. Note that GHC upgrades themselves (major compiler versions) are tracked on a slower, separate cadence in this swimlane, since they can require broader code changes than a routine dependency bump — a maintenance cost this document states explicitly rather than glossing over.

### 6.3 Incident response (outline)
1. Detect → 2. Contain (feature flag / disable route) → 3. Eradicate (patch — often requires a recompile, since Haskell has no interpreted "hot patch" story comparable to swapping a script file) → 4. Recover (redeploy new images) → 5. Post-mortem, feeding new abuse cases back into Phase 1.

### 6.4 Content & translation review schedule
- Quarterly re-verification that every `CornucopiaCard.cardContentSha256` still matches its source YAML.
- Quarterly Polish translation audit sampling 10% of `cardDescriptionPl` fields against current `cardDescriptionEn` for staleness.

---

## Phase 7 — Haskell-Specific SSDLC Considerations

1. **"Illegal states unrepresentable" is the strongest version of a pattern this whole app series has used.** `app03_python_django` enforced "only this code path may verify content" with an import-graph *test*; `app04_scala_react` used opaque *types* for identifiers; `app05_go_react` used the `internal/` *compiler feature* plus a lint rule. HaskShield's `CardKind` sum type (D-01) goes one step further for the *specific* case of the harms deck's severity: there is no `Severity` field to accidentally populate, not merely a constructor that declines to accept one as a parameter (which a determined refactor could still change). This document treats that difference as one of degree along a spectrum this whole series has been walking, not as a categorically different achievement.
2. **Purity changes what a code review can verify from the diff alone, but does not remove the need for integration testing.** A function with no `IO` in its type cannot have a hidden side effect — a reviewer can trust that fact without running anything. `requirements.md` NFR-04.3 turns this into a concrete rule (pure functions get a QuickCheck property in addition to examples) precisely because "provably has no side effect" is exactly the kind of property random-input testing is good at exercising exhaustively.
3. **Compile-time schema checking (`hasql-th`) moves SQL-shape mistakes earlier than `app05_go_react`'s `sqlc` does, at the cost of needing a live database during compilation.** This is a genuine CI complexity trade-off (Phase 0.2 addresses it with a dedicated schema-check service container) — the plan does not present the earlier-detection benefit as free.
4. **The type system does not verify business-logic correctness, translation accuracy, or the presence of a vulnerability class GHC has no opinion on (e.g., a logically-wrong-but-well-typed authorization check).** Phases 4 and 6 apply exactly the same SAST/DAST/SCA/monitoring rigor as every sibling app for this reason — Haskell changes *where in the SDLC* certain specific guarantees land, not *whether* the rest of the SSDLC is still required.

---

## SDLC × SSDLC Master Mapping Table

| Classic SDLC stage | SSDLC security activity in this project | Primary artifact |
|---|---|---|
| Planning & Analysis | Threat modeling with the project's own STRIDE deck; compliance mapping (GDPR/AI Act/NIS2); abuse cases AC-01–AC-16 | `requirements.md` §1–7, this document Phase 1 |
| Design | Trust-boundary diagram (`api` ↔ `worker` ↔ YAML source); least privilege via servant's typed routes and `Integrity.Verify`'s export list; STRIDE-per-component table | `PLAN.md` §3–5, this document Phase 2 |
| Implementation | Secure Haskell coding standards (`hasql-th`, strict YAML decoding, typed `odd-jobs` args); TDD red-green with security tests (and QuickCheck properties) written first | `user_stories+tests.md`, this document Phase 3 |
| Testing | SAST (`hlint`/`stan`/GHC warnings), SCA (`osv-scanner`), DAST (ZAP), abuse-case integration tests | this document Phase 4 |
| Deployment | CI/CD security gates, multi-stage Docker hardening checklist, secrets management | this document Phase 5 |
| Maintenance | Runtime monitoring, Kanban-driven patch management, incident response, quarterly content/translation integrity review | this document Phase 6 |

---

## Agile Ceremonies — Security & i18n Integration Points

```
Sprint Planning        → New security/i18n stories pulled from backlog alongside features;
                          every card-deck story (US-05–US-12, US-19) is estimated with its Polish
                          translation review as part of the story, not a separate ticket.
Daily Standup          → "Any SEC REVIEW or I18N REVIEW blocker?" is a standing question.
Mid-Sprint Security Gate → Dedicated 30-minute slot for anything touching Integrity.Verify's
                          export list, hasql-th statements, or odd-jobs Args types.
Sprint Review          → Demo always includes one security-relevant moment (e.g., a PR that
                          fails to compile because it tried to add a severity to DesignHarm,
                          or the attack-demo confirmation modal).
Sprint Retrospective   → One mandatory retro item: "did any security or translation issue
                          reach TEST or DONE that SEC REVIEW/I18N REVIEW should have caught?"
```

---

## Summary: SSDLC Compliance Checklist for HaskShield 2026

```
[ ] Threat model exists and is reviewed each quarter (Phase 0, 6.4)
[ ] Integrity.Verify has no importers outside its documented caller list (Phase 2.1, module-graph CI check)
[ ] All SQL access goes through hasql-th statements — zero string-built queries (structurally true, Phase 3.1)
[ ] All six YAML decks decoded into closed ADTs rejecting unknown fields; SHA-256 verified regardless (Phase 7.4)
[ ] SAST (hlint/stan/-Wall -Werror)/SCA (osv-scanner)/DAST (ZAP) are all CI-blocking, not advisory (Phase 4)
[ ] Every abuse case AC-01–AC-16 has an automated regression test (Phase 4.5)
[ ] i18n key parity and translation review are enforced as release gates (Phase 1, I18N REVIEW column)
[ ] Card content (all 6 decks) is read-only in the application and change-controlled at the source
[ ] api and worker are separate executables/containers with no published worker port
[ ] Production image size (≤ 120 MB) is CI-verified and reported honestly against the Go sibling's figure (Phase 5.2)
[ ] Digital-by-Default Harms deck cannot carry a Severity value at the Haskell type level — no severity key
    is ever present in its JSON encoding (Phase 1.3, FR-19.2)
[ ] Kanban board carries explicit SEC REVIEW and I18N REVIEW columns with WIP limits
[ ] Incident response and patch-management processes exist before, not after, first production release
```
