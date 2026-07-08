# CppCitadel 2026 — SSDLC / SDLC Analysis

**Version:** 1.0
**Date:** 2026-07-07
**Document type:** Secure Software Development Lifecycle (SSDLC) analysis, mapped against the classic SDLC
**Scope:** Full lifecycle analysis of the application defined in `PLAN.md`, `requirements.md`, and `user_stories+tests.md`
**Methodology:** Agile — Scrum for planning/cadence, Kanban overlay for the engineering + security workflow
**Dotyczy:** US-01 – US-19 / C++23 (Drogon + libpqxx/sqlpp11) + React 18

---

## Executive Summary

CppCitadel 2026 carries the same double obligation as its sibling projects (`app01_react` through `app07_rust_react`): it **teaches** OWASP/MITRE ATLAS/CompTIA SecAI+ security content, so it must itself **be** secure — an app about SQL Injection that is vulnerable to SQL Injection trains people with a false sense of authority. For this app, that obligation is harder to meet, and this document says so throughout rather than only in one section.

This project is the series' deliberate counter-example, and its SSDLC emphasis follows directly from that role:

1. **Every compile-time guarantee the other six apps used to move a security property earlier in the SDLC is either weaker here or absent entirely.** No borrow checker, no macro-checked SQL with the same maturity as `sqlc`/`hasql-th`/`sqlx::query!`, no declarative "reject unknown YAML fields," and only a partial, review-dependent version of exhaustive sum-type matching (`std::variant`/`std::visit`, `PLAN.md` D-04). This document does not treat any of these as solved; each has a named compensating control and a named residual risk.
2. **The compensating controls this plan relies on — sanitizers, fuzzing, static analysis, disciplined RAII — are all *detective* or *probabilistic*, not *preventive* and *total*.** `app07_rust_react`'s `#![forbid(unsafe_code)]` fails the build the moment a violation is written, independent of test coverage. This project's AddressSanitizer/UndefinedBehaviorSanitizer/`libFuzzer` stack only catches what a test or a fuzz run actually exercises. Phase 4 and the Executive risk framing throughout this document are explicit about that difference, because overstating it would itself be a teaching error in an app whose subject matter is security honesty.
3. **This is exactly the comparison CompTIA SecAI+'s 2026 curriculum, and CISA/NSA's public guidance, asks students to be able to make**, and this app's own SDLC is the concrete "before" picture against `app07_rust_react`'s "after" picture — both are seeded as cross-referenced CompTIA SecAI+ content (`requirements.md` DR-01.5).
4. **The rest of the series' obligations still apply unchanged.** Six externally-authored YAML card decks, including the non-technical Digital-by-Default Harms deck, are ingested as security-sensitive data, and the application is fully bilingual (PL/EN) with its own translation-review supply chain — none of that is affected by memory-safety posture.

The lifecycle below follows **Agile Scrum for cadence, with a Kanban board carrying explicit security-gate columns**, per the requested focus on Agile/Scrum/Kanban.

---

## SSDLC vs Classic SDLC — Where Security Moves (and Where It Cannot Move, Here)

```
Classic SDLC (security bolted on late):
  Planning & Analysis → Design → Implementation → Testing → Deployment → Maintenance
                                                        ↑
                                          Security testing added HERE — too late,
                                          architecture and code are already frozen.

SSDLC as this project can actually achieve it ("Shift Left," with an honest ceiling):
  Secure          Secure       Secure            Secure          Secure           Secure
  Planning &  →   Design   →   Implementation →  Testing     →   Deployment   →   Maintenance
  Analysis        │            │                 │               │                │
    ↑             ↑            ↑                 ↑               ↑                ↑
  Threat Model   Build-graph  RAII/smart ptrs   SAST(clang-tidy)  Minimal-runtime  Runtime
  + Compliance   isolation +  + parameterized   + continuous      image; ldd-      monitoring +
  mapping        least priv.  queries (review-   fuzzing +        verified deps    patch cadence +
  (OWASP/ATLAS/  (D-02, D-07, enforced, not      ASan/UBSan/TSan                    card-deck +
  SecAI+/GDPR/   review-      compiler-           on EVERY test                     translation
  CISA memory-   dependent)   enforced)           run — this is                     integrity review
  safety)                                          where most of                    + dependency-
                                                    this project's                   tree unsafe-
                                                    "shift left"                     equivalent
                                                    budget goes                       tracking
```

Both models describe the **same six stages**; SSDLC's contribution is that security activities happen *inside* each stage rather than as a single gate before release. The difference in this project's version of the diagram, versus every prior sibling's, is that several of its "Design" and "Implementation" boxes say "review-enforced" rather than "compiler-enforced" — that is the specific, checkable claim this whole document is built around, not a stylistic choice.

---

## Agile Framework: Scrum for Cadence, Kanban for Flow

### Scrum structure

```
Sprint length:      2 weeks
Team size:           4–6 C++ engineers (more than any other backend sibling's estimate — see
                      rationale below), 1 frontend/React engineer, 1 QA/security engineer with
                      fuzzing/sanitizer experience specifically, 1 PL translator part-time
Velocity target:     ~14–18 story points/sprint — lower than every memory-safe sibling's estimate.
                      This is not a claim that C++ developers are slower in general; it reflects
                      that this specific project budgets real sprint time for activities
                      (writing fuzz harnesses, triaging sanitizer findings, hand-writing YAML
                      decoders that other apps get from a one-line derive) that literally do not
                      exist as line items in the other six apps' sprint plans.
Total duration:      16 sprints (~32 weeks) — the longest in the series, driven by Phase 3.5
                      (a dedicated fuzzing/sanitizer-hardening phase with no equivalent elsewhere)

Ceremonies:
  Sprint Planning        — Monday, Day 1, 2h max — pulls from the Product Backlog (PLAN.md §15 + this doc's abuse cases)
  Daily Standup          — daily, 15 min, includes a mandatory "any security blocker?" round AND
                             a "any new sanitizer/fuzzer finding overnight?" round — the second
                             question has no equivalent in any other sibling's standup
  Mid-Sprint Security Gate — Wednesday, Day 7, 30 min — peer review of anything touching
                             integrity::verify's isolation, raw pointer/array usage, YAML decode
                             functions, or CardKind std::visit vs std::get usage
  Sprint Review          — Friday, Day 10, 1h — demo includes a security angle (e.g. "here's a
                             fuzzer-found crash from last week, and the regression corpus entry
                             that now prevents it from recurring silently")
  Sprint Retrospective   — Friday, Day 10, 45 min — one mandatory security-process retro item
```

### Kanban board — security-gated columns

```
BACKLOG → SPRINT → IN DEV → SEC REVIEW → I18N REVIEW → TEST → FUZZ/SANITIZE → DONE

  BACKLOG        Product backlog: user stories (US-01..US-19), bugs, abuse cases (AC-01..AC-17)
  SPRINT         Committed for the current sprint
  IN DEV         Actively coded — TDD red/green cycle in progress
  SEC REVIEW     Mandatory gate for anything touching: auth, integrity::verify's isolation,
                 raw memory management, YAML decode functions, CardKind reads, or admin/editor
                 permissions — this column's review checklist is longer than any sibling's
  I18N REVIEW    Mandatory gate for anything adding user-visible strings or card translations
  TEST           GoogleTest + RapidCheck + Drogon test client + Vitest + Playwright running in CI
  FUZZ/SANITIZE  A column that does NOT exist on any other sibling app's board — new/changed
                 parsing code sits here until it has a clean ASan/UBSan run and, for new parsing
                 surfaces, an initial fuzzing pass with no crashes found in a fixed time budget
  DONE           Meets the Definition of Done below

WIP limits:  IN DEV ≤ 2/dev · SEC REVIEW ≤ 3 total · I18N REVIEW ≤ 3 total · TEST ≤ 5 total ·
             FUZZ/SANITIZE ≤ 4 total (a wider limit than the others, because fuzzing runs take
             longer than a typical review and the column would otherwise become a bottleneck)
```

**The central Kanban-metrics honesty point for this project:** where `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react` each observed that compiler-enforced checks shorten `SEC REVIEW`'s average residency for mechanical issues, this project's `SEC REVIEW` column is expected to run **longer**, on average, than any sibling's — because several checks those languages' compilers perform automatically (memory safety, exhaustive matching, unknown-field rejection) are, here, checklist items a human reviewer must actively verify. The new `FUZZ/SANITIZE` column exists specifically to take *some* of that burden off human review and put it onto automated, if imperfect, tooling — but it adds its own wall-clock time (a fuzz run takes minutes, not seconds) that this project's velocity estimate above already accounts for.

### Definition of Done (security- and i18n-enforced)

```
CODE QUALITY
  [ ] ctest passes (including RapidCheck); coverage ≥ 85% on core::service
  [ ] clang-format --dry-run clean; clang-tidy zero findings (cppcoreguidelines/bugprone/cert groups)
  [ ] Zero raw new/delete or owning raw pointers in changed code (grep + clang-tidy)

SECURITY GATES
  [ ] ASan+UBSan test run green on this change
  [ ] Any new/changed parsing function has a corresponding libFuzzer harness with a clean
      10-minute run and zero new crashes
  [ ] OWASP Dependency-Check / vcpkg-audit pass against the dependency manifest
  [ ] Peer security review completed for anything in the SEC REVIEW trigger list above,
      SPECIFICALLY including manual verification that any new CardKind-reading code uses
      std::visit with an exhaustive overload set, not std::get/std::get_if
  [ ] No secrets committed (detect-secrets / trufflehog pre-commit hook green)
  [ ] All DB access via libpqxx parameterized statements / sqlpp11 — CI grep for string-built SQL passes
  [ ] integrity::verify's build-graph isolation unchanged, or changed with explicit SEC REVIEW sign-off

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
| `integrity::verify` | Tampering, Elevation of Privilege | → isolated by build-graph structure + CI check (`PLAN.md` D-02) — the session explicitly flagged this as **weaker** than the equivalent control in every memory-safe sibling, and recorded it as an accepted, monitored risk rather than a solved one |
| `store` (libpqxx/sqlpp11 queries) | Tampering (SQLi) | → parameterized statements only, CI grep for string-built SQL (D-01/§2) |
| YAML card ingestion | Tampering, Repudiation | → hand-written decode functions rejecting unknown keys + SHA-256 verification (D-03) — flagged as the single largest "silent drift" risk in the whole system (§13 risk register) |
| PL/EN translation storage | Information Disclosure (mistranslation), Repudiation | → translations stored with a reviewer identity |
| Memory-corruption vulnerabilities (buffer overflow, use-after-free) | Tampering (via corruption), and arguably a category STRIDE doesn't name well | → RAII discipline + ASan/UBSan on every test run + continuous fuzzing (D-01, D-05) — the session spent more time on this single row than any other, and concluded that **no design decision fully closes it**, only reduces its likelihood and improves detection speed |
| Digital-by-Default Harms deck | (a presentation risk, not STRIDE-shaped) | → `std::variant`/`std::visit` makes the mis-presentation a compile error *if* the idiom is followed; the session flagged the "if" as the residual risk (D-04) |

### 0.2 Security tooling setup

```yaml
# .github/workflows/ci.yml (excerpt)
- name: Lint (SAST)
  run: clang-tidy -p build --config-file=.clang-tidy $(find backend/core backend/api backend/worker -name '*.cpp')
- name: Build with sanitizers
  run: |
    cmake -B build-san -DSANITIZE=address,undefined
    cmake --build build-san
    ctest --test-dir build-san
- name: Fuzz targets (time-boxed)
  run: |
    for target in fuzz_card_loader fuzz_json_decoder fuzz_accept_language; do
      ./build-fuzz/$target -max_total_time=600 fuzz/corpus/$target
    done
- name: SCA
  run: dependency-check.sh --project cppcitadel --scan backend/ --format JSON
- name: Container scan
  run: trivy image cppcitadel-api:latest cppcitadel-worker:latest
- name: i18n key parity
  run: node scripts/check-i18n-parity.js
- name: DAST baseline (every PR, passive only)
  run: docker run -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://staging.cppcitadel.local
```

```bash
# nightly-only job, not per-PR (too slow for the PR feedback loop)
cmake -B build-tsan -DSANITIZE=thread && cmake --build build-tsan && ctest --test-dir build-tsan --label-regex concurrency
```

### 0.3 Branch protection
- `main` requires 1 approval + all CI checks green + no `SEC REVIEW`/`I18N REVIEW`/`FUZZ/SANITIZE` Kanban card still open for the linked issue.
- CODEOWNERS: `@security-team` required for `backend/core/src/integrity/`, `backend/core/src/store/`, `backend/core/src/cards/loader.cpp`, `data/hashes.json`, and any `docs/OWASP_stories/*.yaml` change.

---

## Phase 1 — Planning & Analysis (Secure Requirements)

### 1.1 Business goals vs security constraints

| Business goal | Security constraint it must respect |
|---|---|
| Teach OWASP/ATLAS/SecAI+ content accurately and fast | Content integrity (`requirements.md` SR-06) must not be sacrificed for speed of publishing |
| Serve both PL and EN learners | Missing translations degrade gracefully (FR-18.6), never a blank/broken page |
| Demonstrate the pre-migration state honestly, as this series' explicit counter-example | Every claim of "mitigation" in this document must name whether it is compiler-enforced, tool-enforced, or review-enforced — never blur the three |
| Cover all six Cornucopia decks, including the non-technical harms deck | The harms deck (US-19) must never be presented as if it had CVE-style severity — FR-19.2, enforced *if the `std::visit` idiom is followed*, which is itself a stated residual risk |

### 1.2 Compliance requirements mapping

| Regulation / standard | Relevance | Where it lands in requirements.md |
|---|---|---|
| GDPR / RODO | User accounts, bookmarks, translator reviewer identity | SR-01 (auth), no unnecessary PII |
| EU AI Act (transparency, Art. 13) | `dbd` harms deck explicitly references this | FR-19.3, DR-01.11 |
| NIS2 / Polish KSC | Educational content on GRC topics | DR-01.5 |
| CISA/NSA memory-safe-language guidance (2023–2026) | This app is the explicit pre-migration comparison point in the series; the guidance is seeded as CompTIA SecAI+ content with this app cited by name | DR-01.5 |
| CWE Top 25 | Several top entries are memory-corruption weaknesses this app's own stack does not prevent by construction — seeded as content, with SR-08's compensating controls as the "how we manage this in practice" answer | DR-01.5 |
| WCAG 2.1 AA | Public-facing educational tool | NFR-02.3 |

### 1.3 Security requirements traceability (excerpt)

| Requirement | Threat addressed | Verified by |
|---|---|---|
| SR-02.1/SR-02.2 (parameterized queries + CI grep) | SQL Injection | Grep-based CI check + integration test — **not** a compile-time schema check like every memory-safe sibling has; SR-02.2 states this gap explicitly |
| SR-06.4 (`integrity::verify` build-graph isolation) | A compromised controller forging a "content verified" record | CI build-graph check — weaker than a compiler-enforced module boundary, stated as such |
| SR-08.1–SR-08.4 (RAII + ASan/UBSan + fuzzing) | Memory-corruption vulnerabilities | Sanitizer-clean CI runs + fuzzing corpus with no outstanding crashes — a detective, not preventive, control, and SR-08.4 says so in its own text |
| SR-09.1–SR-09.3 (hand-written YAML decoders + property test) | Malicious YAML exploiting lenient decoding | `RapidCheck` property generating random extra fields — with SR-09.3 stating the maintenance-drift risk this approach carries versus a derive-macro equivalent |
| FR-19.2 (`CardKind` variant, `std::visit`-dependent) | Digital-by-Default Harms deck misread as a CVE-style severity list | Integration test asserting the JSON encoding of a `DesignHarm` value carries no severity, **plus** a mandatory code-review checklist item, because the test alone cannot catch every possible future `std::get_if` misuse the way a Rust/Haskell compiler would |

### 1.4 Abuse cases (negative user stories)

See `requirements.md` §7 for the full table (AC-01–AC-17). Highlights specific to this project's C++ choices:

| ID | Abuse case |
|---|---|
| AC-01 | An attacker crafts a `?q=` value hoping some controller builds SQL by string concatenation instead of a parameterized statement — the CI grep exists specifically because, unlike `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react`, there is no compiler backstop if the grep pattern is evaded by an unanticipated string-building idiom. |
| AC-06 | An attacker submits a crafted `docs/OWASP_stories/*.yaml` PR hoping `cards::loader`'s hand-written decoder has a gap the property test's random-key generation doesn't happen to hit. |
| AC-16 | A user copy-pastes the Digital-by-Default Harms deck into a vulnerability report as if `SCO2` were a CVSS-scored finding — mitigated *unless* a future code change reads `CardKind` via `std::get_if` instead of `std::visit`, which is the one abuse case in this whole series whose mitigation strength depends on a coding-idiom choice rather than a language feature. |
| AC-17 | A contributor introduces a buffer-overflow-shaped bug in ordinary, `unsafe`-free C++ code (no `unsafe` keyword exists in C++ to avoid in the first place) — caught, if at all, by `clang-tidy`, ASan/UBSan on a test run that exercises the buggy path, or a fuzz harness that happens to generate the triggering input. This is the series' one abuse case with **no compile-time prevention available in principle**, not merely in this project's current implementation. |

---

## Phase 2 — Secure Design

### 2.1 Trust boundaries

```
┌─────────────────────────── Untrusted ───────────────────────────┐
│  Browser (any locale, any user)                                  │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ HTTPS, JWT (stateless)
┌────────────────────────────── Trust Boundary 1 ──────────────────┐
│  Nginx → api binary (Drogon controllers, controllers/**)           │
│    - validates all input via hand-written validators              │
│    - enforces auth/roles via middleware                            │
│    - MUST NOT #include integrity/verify.hpp (CI build-graph check, │
│      NOT a compiler error — a determined or careless change that   │
│      adds the #include still compiles successfully)                │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ insert jobs-table row (same PostgreSQL, JSON payload)
┌────────────────────────────── Trust Boundary 2 ──────────────────┐
│  worker binary (separate compiled binary + container)              │
│    - runs jobs/*, the intended sole caller of integrity::verify     │
│    - has no HTTP listener — unreachable from any browser request   │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ local filesystem read-only
┌────────────────────────────── Trust Boundary 3 ──────────────────┐
│  docs/OWASP_stories/*.yaml + data/hashes.json                     │
│    - treated as security-sensitive content, CODEOWNERS-gated      │
└────────────────────────────────────────────────────────────────────┘
```

**Design decision D-01 (this document; distinct from `PLAN.md`'s own D-01, RAII discipline):** `api` and `worker` are two separately compiled binaries linking a shared static library — the same OS-process-boundary pattern every sibling uses. What is specific and worth stating plainly here: in Go/Haskell/Rust, the boundary between "the sensitive function" and "code that must not call it" is enforced by the same mechanism (module/package visibility) that the *compiler* checks on every build. In this project, that boundary is enforced by build *configuration* (which CMake target links which object file) plus a *separate* CI script parsing `compile_commands.json` — two more moving parts than the memory-safe siblings need, and two more places this specific guarantee could silently break if either is misconfigured.

### 2.2 Least privilege applied to the data model

- `CornucopiaCard` rows (all six decks) have **no** write path from any HTTP controller — not even an admin-JWT-gated one (`requirements.md` C-08). Enforced by "no controller method registers such a route," verified in code review at PR time, not by the router's type system refusing to compile such a route (contrast every memory-safe sibling).
- `editor` role can write `Threat`/`Mitigation`/`CodeSample`; only `admin` can delete.
- `worker` runs with the same least-privilege DB role as `api` — no superuser.

### 2.3 STRIDE analysis of the designed architecture

| STRIDE | Applies to | Mitigation already in the design |
|---|---|---|
| Spoofing | Browser→API JWT; unauthenticated job injection | JWT RS256 (`jwt-cpp`); jobs enqueued only from within `api`'s own service layer |
| Tampering | YAML card content; DB records; SQL queries; memory corruption | Hand-written decoders + SHA-256; parameterized-query-only writes; RAII + ASan/UBSan + fuzzing (detective, not preventive, for the memory-corruption sub-case) |
| Repudiation | Who approved a translation or a hash-allowlist update | CODEOWNERS-enforced PR review logged in Git history; `verified_by` field |
| Information Disclosure | Error responses; job failure detail | Generic error body to the client; full detail logged server-side only via `spdlog` |
| Denial of Service | Export jobs; search; card scraping | Job-table + worker-pool async export (never blocks `api`); atomic/Redis rate limit; `tsvector` GIN index |
| Elevation of Privilege | Editor trying to write `CornucopiaCard`; anonymous user hitting admin routes | No write route exists at all for cards (review-verified, not type-verified); JWT role middleware on every admin route |

### 2.4 Data classification

| Data | Classification | Handling |
|---|---|---|
| Threat/card content (EN + PL) | Public, but integrity-critical | SHA-256 verified, CODEOWNERS-reviewed |
| User accounts (email, password hash) | Personal data | `libsodium` Argon2id, never a hand-rolled hash, never logged |
| Bookmarks (anonymous) | Non-personal | `localStorage`, never sent server-side unless authenticated |
| JWT signing key, DB/Redis credentials | Secret | Environment variable / Docker secret, rotated quarterly |

---

## Phase 3 — Implementation (Secure Coding)

### 3.1 Secure coding standards — C++

```cpp
// ALWAYS — smart pointers, never raw owning pointers
auto threat = std::make_unique<Threat>(/* ... */);

// ALWAYS — parameterized queries
pqxx::work tx{conn};
auto result = tx.exec_params(
    "SELECT * FROM threats WHERE framework_code = $1 AND severity = $2",
    frameworkCode, static_cast<int>(severity));

// ALWAYS — bounds-checked views, never raw pointer+length
void processCards(std::span<const CornucopiaCard> cards);

// ALWAYS — std::expected instead of exceptions on the hot request path (C++23)
std::expected<Threat, ApiError> getThreat(ThreatId id);

// ALWAYS — hand-written YAML decoders enumerate and reject unknown keys explicitly (D-03)

// NEVER — a raw new/delete pair, a C-style array with manual bounds tracking, or a
// hand-written crypto/HTML-parsing routine (D-06); all forbidden by clang-tidy + code review,
// NOT by the compiler — this comment is a policy statement, not a language guarantee
```

### 3.2 Secure coding standards — background jobs

```cpp
struct ExportCsvArgs {
    std::string format;
    std::string framework;
};

// nlohmann::json explicit from_json, rejecting unrecognized keys — same discipline as YAML (D-03)
void from_json(const nlohmann::json& j, ExportCsvArgs& args) {
    static const std::set<std::string> knownKeys = {"format", "framework"};
    for (auto& [key, _] : j.items()) {
        if (!knownKeys.contains(key)) throw JobDecodeError("unrecognized key: " + key);
    }
    j.at("format").get_to(args.format);
    j.at("framework").get_to(args.framework);
}

std::expected<void, ValidationError> validateExportArgs(const ExportCsvArgs& args) {
    if (args.framework.empty()) return std::unexpected(ValidationError{"framework", "must not be empty"});
    if (args.format != "csv") return std::unexpected(ValidationError{"format", "must be csv"});
    return {};
}
```

### 3.3 Sprint-by-sprint security activities

| Sprint | Feature work | Security activity in parallel |
|---|---|---|
| 1–2 | Foundation, auth | Threat model review of auth flow; `clang-tidy` + ASan/UBSan wired into CI (not yet blocking) |
| 3–4 | Threat browser | SAST/sanitizers become blocking; first abuse-case test (AC-01, CI grep for string-built SQL) |
| 5–7 | Card decks (all six, including `dbd`) + integrity | AC-06, AC-16 abuse tests written FIRST (TDD) before the ingestion code exists |
| 7 | **Fuzzing & sanitizer hardening (dedicated, Phase 3.5)** | `libFuzzer` harnesses for every parsing surface stood up; initial corpus seeded; nightly TSan job activated |
| 8–9 | 5-language code samples | Review that no `AttackDemo` sample is runnable without the confirmation gate |
| 9–10 | i18n | I18N REVIEW Kanban column activated |
| 10–12 | Search, export, matrix | AC-14 (job payload validation) test added; DAST baseline extended to `/export/` and `/search/` |
| 12–14 | Hardening & release | Full ZAP active scan; abuse-case sweep across AC-01..AC-17; fuzzing corpora reviewed for stability before release cut |

---

## Phase 4 — Security Testing

### 4.1 Test pyramid with security layers

```
E2E (Playwright)              — includes AC-01..AC-17 abuse-case scenarios end-to-end
Drogon test-client integration — auth/permission boundary tests per controller
GoogleTest unit                — service-layer behavior with concrete fixtures
RapidCheck properties          — invariants over generated data: YAML decode-rejects-unknown-fields,
                                 every mitigation has 5 languages, DesignHarm never serializes severity
libFuzzer continuous fuzzing   — the layer with NO equivalent in any memory-safe sibling's plan,
                                 because those languages' compilers already close most of what
                                 fuzzing exists to find here
```

### 4.2 SAST
`clang-tidy` (`cppcoreguidelines-*`, `bugprone-*`, `cert-*`, `clang-analyzer-*` check groups) and Clang Static Analyzer run on every PR; `cppcheck` as a third, complementary pass. Unlike `app07_rust_react`'s `#![forbid(unsafe_code)]`, none of these tools can turn a memory-safety violation into a build failure with full confidence — they flag *patterns* correlated with such violations, with both false positives and false negatives possible. This document treats their CI-blocking status as "raises the cost of shipping the bug," not "makes the bug impossible."

### 4.3 Dynamic analysis and fuzzing (this project's primary answer to "what replaces a borrow checker")
Every `ctest` run executes against an `-fsanitize=address,undefined` build on every PR, and an `-fsanitize=thread` build nightly. `libFuzzer` harnesses target every function parsing untrusted or semi-trusted input (YAML, JSON, `Accept-Language`, query strings), each running for a fixed time budget on every relevant PR and continuously outside PRs. A crash found by fuzzing becomes a permanent, checked-in regression corpus entry — this is the closest this project gets to "once caught, can never silently regress," which is a categorically weaker guarantee than "cannot be written in the first place," and this document does not describe it as anything stronger.

### 4.4 SCA
OWASP Dependency-Check (C/C++ CPE-matching mode) and `vcpkg`/`conan` audit tooling run against the dependency manifest on every PR and nightly. `npm audit` and Trivy cover the frontend and both container images.

### 4.5 DAST (OWASP ZAP)
Baseline (passive) scan on every PR against staging; full active scan before each production release, targeting all public `api` routes. `worker` is not a ZAP target because it exposes no HTTP port — verified by a network-level test.

### 4.6 Abuse-case tests (integration level)
```cpp
TEST(AbuseCaseTest, Ac06YamlLoaderRejectsUnrecognizedTopLevelKey) {
    std::string malicious = "meta:\n  edition: evil\nexec: rm -rf /\n";
    EXPECT_THROW(decode_card_file(YAML::Load(malicious)), CardDecodeError);
}

TEST(AbuseCaseTest, Ac14ExportCsvArgsRejectsEmptyFramework) {
    ExportCsvArgs args{.format = "csv", .framework = ""};
    EXPECT_FALSE(validateExportArgs(args).has_value());
}
```

### 4.7 Security regression testing
Every fixed security bug (including every fuzzer-found crash) gets a permanent regression test or corpus entry, run on every CI build, never skipped.

---

## Phase 5 — Deployment (Secure Release)

### 5.1 CI/CD pipeline with security gates
```
lint (clang-tidy) → build+test with ASan/UBSan → fuzz targets (time-boxed) → nightly TSan
   → SCA (Dependency-Check/vcpkg audit) → build runtime images → ldd dependency verification
   → container scan (Trivy) → deploy to staging → DAST baseline → E2E (Playwright)
   → manual QA sign-off → deploy to production (blue/green) → DAST full scan (scheduled, not blocking)
```

### 5.2 Infrastructure hardening checklist
```
Nginx        TLS 1.2+/1.3 only; HSTS; security headers; request size limits
api          uncaught-exception handler converts any escaping exception to a generic 500 body;
             full detail logged server-side only via spdlog
worker       no published port at all; only outbound connections to Postgres/Redis
PostgreSQL   least-privilege role for both api and worker (no SUPERUSER); network isolated
Redis        password-protected (requirepass); not exposed on the host
Docker       minimal runtime base image; ldd-verified to contain only libraries the binary
             actually links; non-root user
```

**Deployment-footprint claim, stated with an explicit disclaimer (Phase 5 analysis, not marketing):** `requirements.md` NFR-07.1 targets ≤ 60 MB for the `api` production image — a real target, but explicitly **not** claimed to beat `app07_rust_react`'s ≤ 25 MB figure, because this project dynamically links OpenSSL, `libpqxx`'s PostgreSQL client stack, and Drogon's dependencies rather than pursuing full static linking, which would add build complexity this project's plan does not currently budget for. Where the series' practice throughout has been "state the number and verify it in CI," this is the one app where the number is expected, upfront, to be less favorable than at least one sibling's — and this document says so rather than picking a rosier, unverified estimate.

### 5.3 Secrets management
`.env` files never committed; JWT signing key, DB/Redis credentials injected via Docker secrets / GitHub Actions secrets, rotated quarterly and immediately on suspected exposure.

---

## Phase 6 — Maintenance & Runtime Monitoring

### 6.1 Runtime monitoring
- `prometheus-cpp` exposes `/api/v1/metrics`; Grafana dashboards track request latency, rate-limit rejections, `content_integrity_check_ok` gauge, job-table queue depth/failure rate.
- A Loki alert `SEC-CARD-HASH-MISMATCH` fires directly from `integrity::verify`'s `spdlog::error` call.
- **A monitoring signal with no equivalent in any memory-safe sibling's plan:** production crash reports (core dumps, if enabled in a controlled environment, or structured panic-equivalent logs) are treated as security-relevant by default and routed to the same on-call rotation as a security incident, not merely an availability one — because a crash in C++ is a plausible symptom of a memory-safety bug that testing/fuzzing missed, not only a plain reliability issue.

### 6.2 Patch management (Kanban)
A dedicated `DEPENDENCY UPDATES` swimlane, fed weekly by Dependabot-equivalent tooling for `vcpkg`/Conan manifests, npm, and Docker base images, plus OWASP Dependency-Check's nightly run; any reachable vulnerability auto-creates a `SEC REVIEW`-gated card with a 5-business-day SLA. Compiler/toolchain upgrades (GCC/Clang major versions) are tracked on a separate, slower cadence given the potential for new `clang-tidy`/sanitizer behavior changes to surface latent issues — itself treated as a *feature* of upgrading (more/better detection), not merely a maintenance cost.

### 6.3 Incident response (outline)
1. Detect (monitoring alert, crash report, or fuzzer/sanitizer finding) → 2. Contain (feature flag / disable route) → 3. Eradicate (patch — for a memory-safety root cause, this step includes asking "why didn't ASan/a fuzz harness/clang-tidy catch this," and, if the answer is "no harness existed for this code path," adding one as part of the fix, not as a follow-up ticket) → 4. Recover (redeploy) → 5. Post-mortem, feeding new abuse cases *and new fuzz targets* back into Phase 1/3.5.

### 6.4 Content & translation review schedule
- Quarterly re-verification that every `CornucopiaCard.content_sha256` still matches its source YAML.
- Quarterly Polish translation audit sampling 10% of `description_pl` fields against current `description_en` for staleness.
- Quarterly review of the `CardKind`-reading code paths across the codebase, specifically checking for any `std::get`/`std::get_if` usage that should be `std::visit` — a recurring check with no equivalent need in the memory-safe siblings' maintenance schedules.

---

## Phase 7 — C++-Specific SSDLC Considerations (the counter-example, stated fully)

1. **Nothing in this plan closes the memory-safety gap; everything in it narrows the window in which a bug can hide.** RAII discipline reduces the *rate* of mistakes; `clang-tidy` and Clang Static Analyzer catch *patterns*; ASan/UBSan catch *exercised* violations at test time; fuzzing *widens* what "exercised" means beyond what example-based tests happen to cover. Stacking all four is genuinely effective in practice — it is also, provably, not the same as a borrow checker, because each layer's coverage is bounded by what it was configured or run against, and `app07_rust_react`'s guarantee is not.
2. **The series' own comparison is the point, and this document tries to make it precise rather than rhetorical.** "C++ is less safe than Rust" is a slogan; "this project's SQL-injection defense is a CI grep pattern plus an integration test, where `app07_rust_react`'s is a compile failure on query-shape mismatch" is a specific, falsifiable claim a reader can go verify against both repositories' actual CI configuration. Every SR-0x requirement in `requirements.md` for this app was written to support a claim of the second kind, not the first.
3. **Fuzzing is the one activity this app needs that none of the other six do at this intensity, and it deserves to be budgeted like a first-class phase, not an afterthought.** Phase 3.5's existence as a dedicated sprint, with its own milestone (M3.5 in `PLAN.md` §16), reflects that the "shift left" a memory-safe language gets from its compiler has to be approximated here by continuously *running* something, indefinitely, for the life of the project — a recurring operational cost, not a one-time investment.
4. **This app is, precisely because of all the above, a legitimate and valuable teaching artifact — not merely a "wrong answer" placed alongside six "right answers."** A huge fraction of security engineering work in the real world is exactly this: making a memory-unsafe legacy or performance-critical codebase defensible through process, because a full rewrite in a memory-safe language is not always available. This project's SDLC is a worked example of what that costs in real sprint time, real tooling investment, and real residual risk — which is arguably more directly useful to a working security engineer than a sixth demonstration of "and here the compiler prevents it."

---

## SDLC × SSDLC Master Mapping Table

| Classic SDLC stage | SSDLC security activity in this project | Primary artifact |
|---|---|---|
| Planning & Analysis | Threat modeling with the project's own STRIDE deck; compliance mapping (GDPR/AI Act/NIS2/CISA memory-safety guidance, cited by name); abuse cases AC-01–AC-17 | `requirements.md` §1–7, this document Phase 1 |
| Design | Trust-boundary diagram (`api` ↔ `worker` ↔ YAML source) with explicit compiler-vs-tooling-vs-review annotations; STRIDE-per-component table | `PLAN.md` §3–5, this document Phase 2 |
| Implementation | Secure C++ coding standards (RAII, parameterized queries, hand-written strict decoders, `std::variant`/`std::visit`); TDD red-green with security tests (and `RapidCheck` properties) written first | `user_stories+tests.md`, this document Phase 3 |
| Testing | SAST (`clang-tidy`/Clang Static Analyzer/`cppcheck`), dynamic analysis (ASan/UBSan/TSan), continuous fuzzing (`libFuzzer`), SCA (Dependency-Check), DAST (ZAP), abuse-case integration tests | this document Phase 4 |
| Deployment | CI/CD security gates, minimal-runtime-image hardening checklist with `ldd` verification, secrets management | this document Phase 5 |
| Maintenance | Runtime monitoring (with crash reports treated as security signals), Kanban-driven patch management, incident response tied back to fuzz-target coverage, quarterly content/translation/`std::visit`-usage review | this document Phase 6 |

---

## Agile Ceremonies — Security & i18n Integration Points

```
Sprint Planning        → New security/i18n stories pulled from backlog alongside features;
                          every card-deck story (US-05–US-12, US-19) is estimated with its Polish
                          translation review as part of the story, not a separate ticket; any
                          story adding a new input-parsing surface is estimated WITH its fuzz
                          harness as part of the same story, not a follow-up.
Daily Standup          → "Any SEC REVIEW, I18N REVIEW, or FUZZ/SANITIZE blocker?" is a standing
                          question — the third clause has no equivalent in any sibling's standup.
Mid-Sprint Security Gate → Dedicated 30-minute slot for anything touching integrity::verify's
                          isolation, raw memory management, YAML decoders, or CardKind reads.
Sprint Review          → Demo always includes one security-relevant moment (e.g., a fuzzer-found
                          crash and its new regression corpus entry, or the attack-demo modal).
Sprint Retrospective   → One mandatory retro item: "did any security or translation issue reach
                          TEST or DONE that SEC REVIEW/I18N REVIEW/FUZZ-SANITIZE should have caught?"
```

---

## Summary: SSDLC Compliance Checklist for CppCitadel 2026

```
[ ] Threat model exists and is reviewed each quarter (Phase 0, 6.4)
[ ] integrity::verify's build-graph isolation checked in CI on every PR (Phase 2.1) — reviewed
    quarterly as a standing risk, not treated as permanently solved (contrast every sibling)
[ ] All SQL access goes through parameterized statements — CI grep + review, not a compiler check (Phase 3.1)
[ ] All six YAML decks decoded via hand-written, unknown-key-rejecting functions; RapidCheck
    properties cover drift risk; SHA-256 verified regardless (Phase 3, D-03)
[ ] Every input-parsing surface has a libFuzzer harness with a stable, checked-in corpus (Phase 3.5, 4.3)
[ ] ASan+UBSan clean on every PR; TSan clean nightly (Phase 4.3)
[ ] SAST (clang-tidy/CSA/cppcheck)/SCA (Dependency-Check)/DAST (ZAP) are all CI-blocking (Phase 4)
[ ] Every abuse case AC-01–AC-17 has an automated regression test, with AC-17 acknowledged as the
    one case with no compile-time prevention available in principle (Phase 1.4, 4.6)
[ ] i18n key parity and translation review are enforced as release gates (Phase 1, I18N REVIEW column)
[ ] Card content (all 6 decks) is read-only in the application (review-verified) and change-controlled at the source
[ ] api and worker are separate binaries/containers with no published worker port
[ ] Production image size (≤ 60 MB) is CI-verified and reported honestly against both memory-safe
    siblings' figures, without claiming an unearned advantage (Phase 5.2)
[ ] Digital-by-Default Harms deck cannot carry a Severity value IF all CardKind reads use std::visit
    — quarterly code audit confirms no std::get/std::get_if regression exists (Phase 1.3, 6.4, FR-19.2)
[ ] Kanban board carries explicit SEC REVIEW, I18N REVIEW, and FUZZ/SANITIZE columns with WIP limits
[ ] Incident response and patch-management processes exist before, not after, first production release
```
