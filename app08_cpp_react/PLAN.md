# CppCitadel 2026 — Application Development Plan

**Version:** 1.0
**Date:** 2026-07-07
**Status:** Living document — updated after each sprint planning session
**Directory:** `app08_cpp_react`
**Sibling projects:** `app01_react`/`app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django), `app04_scala_react` (Scala/ZIO), `app05_go_react` (Go), `app06_HASKELL_react` (Haskell), `app07_rust_react` (Rust)

---

## 0. Note on the Stack — and Why This Plan Reads Differently From Its Siblings

This application is written **entirely in modern C++ (C++23)** for the backend — no second backend language — with a **React 18 + TypeScript** frontend, matching the React-frontend pattern of the rest of the series. It is the seventh backend ecosystem in this course's comparison series, and it is included **specifically because it is the counter-example**: C++ is the language CISA, the NSA, and allied agencies' 2023–2026 memory-safe-language guidance is steering new development *away from*, and it is the direct ancestor of most of the CWE Top 25's memory-corruption entries (CWE-787 out-of-bounds write, CWE-416 use-after-free, CWE-125 out-of-bounds read, CWE-476 NULL pointer dereference) that `app07_rust_react` eliminated at compile time.

**This plan does not pretend otherwise.** Every prior sibling app used its language's type system or tooling to push a security property earlier in the SDLC, several of them enforced by the compiler with no further effort required. C++ gives this project **none of those guarantees for free**:

- No borrow checker (`app07_rust_react` D-01) — a `std::unique_ptr` or `std::vector` bounds violation is a runtime bug this compiler will not catch, only a well-configured *sanitizer* or *static analyzer* will.
- No macro-checked, schema-verified SQL (`app05_go_react`'s `sqlc`, `app06_HASKELL_react`'s `hasql-th`, `app07_rust_react`'s `sqlx::query!`) — the closest C++ equivalent (`sqlpp11`, §2) gives compile-time query *shape* checking via template metaprogramming, but the ecosystem is far less mature and far less commonly adopted than any of those three.
- No derive-based "reject unknown YAML fields" (Go's `KnownFields(true)`, Haskell's `deny_unknown_fields`-equivalent, Rust's `#[serde(deny_unknown_fields)]`) — `yaml-cpp` requires **hand-written** decode functions that must explicitly enumerate and reject unrecognized keys, and that discipline is enforced by code review and unit tests, not the compiler.
- No compiler-enforced sum type exhaustiveness by default — `std::variant` + `std::visit` **can** give a compile-time guarantee equivalent to Rust's `match`/Haskell's `case` (§4 D-04), but only if the team deliberately adopts the "overloaded visitor" idiom; the language does not make that the path of least resistance the way Rust and Haskell do.

**What this plan does instead** is treat every one of those gaps as a named risk with a named compensating control — static analysis (`clang-tidy`, Clang Static Analyzer, `cppcheck`), dynamic analysis (AddressSanitizer, UndefinedBehaviorSanitizer, ThreadSanitizer running on every test execution), and continuous fuzzing (`libFuzzer`) of every input-parsing surface, none of which the memory-safe siblings *need* to the same degree, and all of which this plan budgets real sprint time for (§6, §13). This is the most process-heavy plan in the series, and that is the point: it demonstrates concretely what "secure by design" costs to approximate in a language that does not provide it by construction, which is exactly the comparison CompTIA SecAI+'s 2026 memory-safe-language topic (seeded here, `requirements.md` DR-01.5) asks students to understand.

**Note on code samples:** the application still *teaches* countermeasures in five languages — Python, Java, Go, Scala, and Lua (see §10) — because that is separate, deliberately polyglot **content**, not the application's own runtime. None of those five languages is the application's implementation language.

---

## 1. Project Overview

**Name:** CppCitadel 2026
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

**UI languages:** Polish (default) and English, switched instantly with no page reload; toggle persisted in `localStorage` under key `cc_locale`, mirrored server-side via `Accept-Language`.

---

## 2. Technology Stack

### Backend (100% C++23)
| Layer | Technology | Version (2026) |
|---|---|---|
| Language | C++ | C++23, GCC 14+ / Clang 18+ |
| Web framework | `Drogon` (async, Tower/Tokio-equivalent event loop, C++20 coroutine support) | 1.9.x |
| Database access | `libpqxx` (official PostgreSQL C++ client, parameterized statements only) + `sqlpp11` for the small subset of hot-path queries that benefit from its compile-time, template-metaprogramming query-shape checking | — |
| Database | PostgreSQL 16 | — |
| Migrations | Hand-authored forward-only SQL, applied via a small `migrate` CLI (`libpqxx`-based) | — |
| Cache / rate-limit store | In-process token bucket guarded by `std::atomic`/`std::mutex` (single instance); Redis 7 (`redis-plus-plus`) for cross-instance cache | — |
| Background jobs | Hand-rolled Postgres-backed job table + a `std::jthread`-based worker pool (no mature C++ ecosystem equivalent to Go's `river`/Rust's `apalis`/Haskell's `odd-jobs` exists — this gap is stated, not papered over, §13) | — |
| Auth | `jwt-cpp` (RS256) | — |
| Password hashing | `libsodium`'s Argon2id bindings — never a hand-rolled hash function (§4 D-06) | — |
| Validation | Hand-written validating constructors returning `std::expected<T, ValidationError>` (C++23) | — |
| HTML sanitization | Custom `SafeHtml` allow-list sanitizer built on Google's `gumbo-parser` (HTML5 parsing) — the same naming convention as the custom sanitizer `app04_scala_react` built for the same reason (no mature pure-C++ allow-list sanitizer exists) | — |
| YAML parsing | `yaml-cpp`, decoded via hand-written functions that explicitly enumerate and reject unrecognized keys (§4 D-03) | — |
| JSON | `nlohmann::json` | — |
| Structured logging | `spdlog` | — |
| API docs | Hand-maintained OpenAPI 3 YAML, validated in CI against the Drogon route table (no single-source-of-truth type-to-schema generator as mature as `utoipa`/`servant-swagger`/`Tapir` exists for C++ — another stated gap) | — |
| Testing | GoogleTest + GoogleMock, `RapidCheck` (property-based testing, C++'s QuickCheck/`proptest` equivalent), Drogon's own test client for HTTP-level tests | TDD — see `user_stories+tests.md` |
| Dynamic analysis | AddressSanitizer + UndefinedBehaviorSanitizer (every test run, `-fsanitize=address,undefined`); ThreadSanitizer (`-fsanitize=thread`) on a dedicated CI job for concurrency-heavy code; Valgrind as a slower, deeper fallback | — |
| Fuzzing | `libFuzzer` (Clang) targeting the YAML loader, JSON deserializers, and every other untrusted-input parsing surface, run continuously in CI (§6, §13) | — |
| SAST | `clang-tidy` (`cppcoreguidelines-*`, `bugprone-*`, `cert-*`, `clang-analyzer-*` checks), Clang Static Analyzer, `cppcheck` | — |
| SCA | `OWASP Dependency-Check` (C/C++ mode via CPE matching) + `vcpkg`/`conan` audit tooling + Trivy (containers) | — |

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
| Container | Docker + Docker Compose — multi-stage build: build image with the full toolchain (GCC/Clang, CMake, Conan) → minimal runtime image with only the shared libraries the binary actually links (`ldd`-verified in CI, §6) |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Loki + Prometheus (`prometheus-cpp` client) |
| Secrets | Docker Secrets / GitHub Secrets / `.env` (never committed) |
| SAST | `clang-tidy` + Clang Static Analyzer + `cppcheck` + `eslint-plugin-security` (frontend) |
| DAST | OWASP ZAP |
| SCA | OWASP Dependency-Check + `npm audit` + Trivy |
| Fuzzing infra | `libFuzzer` corpora persisted between CI runs; OSS-Fuzz-style continuous fuzzing job |

---

## 3. High-Level Architecture

```
Browser (React 18 SPA, PL/EN)
        │
        │  HTTPS
        ▼
  Nginx (port 443)
   ├── /api/v1/*   ─────► `api` binary (Drogon, port 8080)
   │                         ├── src/main.cpp                — Drogon app bootstrap
   │                         ├── src/controllers/             — Drogon HttpController classes
   │                         ├── src/service/                 — business logic
   │                         ├── src/store/                   — libpqxx/sqlpp11 queries + connection pool
   │                         └── src/integrity/                 — YAML hash verification (a header/impl
   │                                                              pair whose verify() free function is
   │                                                              declared only in a header included
   │                                                              by src/bin/seed.cpp and src/jobs — the
   │                                                              controllers/ directory's CMake target
   │                                                              does not link against this translation
   │                                                              unit at all, enforced by build-graph
   │                                                              structure + a CI grep, see D-02)
   │
   └── /*          ─────► React SPA static build (served by Nginx directly)

`worker` binary (same CMake project, separate executable + container)
   ├── std::jthread pool polling the jobs table (jobs::export_csv, jobs::export_pdf,
   │                                             jobs::reingest_deck, jobs::periodic_reverify)
   └── shares src/service, src/store, src/integrity with the api binary (linked as a static library)

PostgreSQL 16   ◄── libpqxx/sqlpp11, parameterized queries only (threats, cards, mitigations, users, jobs table)
Redis 7         ◄── cross-instance cache; in-process atomics handle single-instance rate limiting
```

**Where the trust boundaries are, and where they are weaker than the memory-safe siblings':** `api` and `worker` are two separately compiled binaries linking a shared `libcppcitadel-core.a` static library — the same OS-process-boundary pattern used throughout this series. The `integrity::verify` boundary (D-02) is enforced by *build-graph structure* (the `controllers` CMake target's link line does not include the integrity translation unit) plus a CI grep over `#include` directives — this is a **weaker** guarantee than Go's `internal/` (compiler-enforced), Haskell's module export lists (compiler-enforced), or Rust's module visibility (compiler-enforced): a C++ translation unit that *does* `#include "integrity/verify.hpp"` and link against it will compile successfully, and only the CI grep step catches the violation, not the compiler itself. This plan states that difference explicitly rather than implying parity with the other five apps' mechanisms.

---

## 4. Architecture Design Decisions

### D-01 — RAII and smart pointers as the primary discipline; raw owning pointers are a `clang-tidy`-enforced build failure
No translation unit in this project's own code calls `new`/`delete` directly, or holds a raw pointer as the sole owner of a heap allocation. `std::unique_ptr`/`std::shared_ptr` (with `std::make_unique`/`std::make_shared`) are the only permitted ownership-transferring types; `clang-tidy`'s `cppcoreguidelines-owning-memory` and `cppcoreguidelines-no-malloc` checks are configured as errors (`WarningsAsErrors: '*'` for this check group), failing the build on any violation. This does **not** eliminate memory-corruption bugs the way Rust's borrow checker does — a `std::shared_ptr` cycle can still leak, a `std::vector::operator[]` out-of-bounds access is still undefined behavior at runtime — it reduces the *frequency* of the mistakes most likely to cause them, and shifts detection to AddressSanitizer (D-05) rather than the compiler.

### D-02 — `integrity::verify`'s isolation is enforced by build structure and CI, not the compiler
`src/integrity/verify.hpp`/`.cpp` is compiled into a separate object file that only `src/bin/seed.cpp` and `src/jobs/periodic_reverify.cpp` `#include` and link against. A CI step (`scripts/check_integrity_isolation.py`, a small script over `compile_commands.json`) fails the build if any file under `src/controllers/` transitively includes `integrity/verify.hpp`. This is the same *intent* as `app05_go_react`'s `internal/` + `depguard`, `app06_HASKELL_react`'s module export lists, and `app07_rust_react`'s module visibility — implemented here with strictly weaker tooling, which this plan states rather than glosses over (§0, §3).

### D-03 — `yaml-cpp` with hand-written, unknown-key-rejecting decode functions
```cpp
// src/cards/loader.cpp
CardFile decode_card_file(const YAML::Node& node) {
    static const std::set<std::string> known_top_level_keys = {"meta", "suits"};
    for (const auto& kv : node) {
        if (!known_top_level_keys.contains(kv.first.as<std::string>())) {
            throw CardDecodeError("unrecognized top-level key: " + kv.first.as<std::string>());
        }
    }
    // ... field-by-field decode into CardFile ...
}
```
Unlike Go's `KnownFields(true)`, Haskell's derived `FromJSON` with an unknown-field check, or Rust's `#[serde(deny_unknown_fields)]` — all *declarative, one-line* guarantees — this project's equivalent is a **hand-written, unit-tested function per YAML shape**. `user_stories+tests.md` requires a `RapidCheck` property test per decoder asserting rejection of documents with random extra keys, specifically because there is no compiler or derive-macro backstop if a future contributor adds a new field to `CardFile` and forgets to update this function — the property test is the only thing standing in for what the other five apps get automatically.

### D-04 — `std::variant<TechnicalThreat, DesignHarm>` with an exhaustive `std::visit` — the closest C++ equivalent to a Rust/Haskell sum type, and honestly compared to them
```cpp
struct TechnicalThreat { Severity severity; };
struct DesignHarm {};
using CardKind = std::variant<TechnicalThreat, DesignHarm>;

template<class... Ts> struct overloaded : Ts... { using Ts::operator()...; };
template<class... Ts> overloaded(Ts...) -> overloaded<Ts...>;

std::optional<Severity> severity_of(const CardKind& kind) {
    return std::visit(overloaded{
        [](const TechnicalThreat& t) -> std::optional<Severity> { return t.severity; },
        [](const DesignHarm&)        -> std::optional<Severity> { return std::nullopt; },
    }, kind);
}
```
`std::visit` **does** fail to compile if the `overloaded` set does not cover every alternative in the `variant` — this is a genuine, compiler-enforced exhaustiveness guarantee, not an approximation. The honest caveat (stated here and repeated in `requirements.md` FR-19.2 and `SDLC_analysis.md` Phase 7): this guarantee only holds if every call site uses `std::visit` with an explicit, complete overload set — nothing stops a developer from writing `std::get_if<TechnicalThreat>(&kind)` and silently ignoring the `DesignHarm` case, the way Rust's `match` or Haskell's `case` would refuse to compile without a `_`/wildcard arm. `clang-tidy`'s `bugprone-*` checks do not currently catch this pattern reliably, so this project's Definition of Done requires that any new `CardKind`-inspecting code go through `std::visit`, not `std::get`/`std::get_if`, checked in code review (not by tooling) — the one place in this whole design where the compensating control is pure human process, and this plan says so.

### D-05 — Sanitizers as the primary detection mechanism for what the language does not statically prevent
Every test suite run (`ctest`) executes against two build configurations: a `-fsanitize=address,undefined` build (every CI run) and a `-fsanitize=thread` build (nightly, for concurrency-sensitive code — the job worker pool, the rate limiter). AddressSanitizer catches out-of-bounds access and use-after-free at the point they occur, not merely if they happen to corrupt something a later assertion checks; UndefinedBehaviorSanitizer catches signed-integer overflow, invalid enum values, and null-pointer-arithmetic UB. This is the specific, concrete answer to "what replaces Rust's borrow checker here" — a *runtime*, *test-time* safety net rather than a *compile-time* one, meaning it only catches what the test suite actually exercises (§13 risk register).

### D-06 — Never hand-roll cryptography or parsing primitives
Password hashing uses `libsodium`'s audited Argon2id implementation; JWT signing/verification uses `jwt-cpp` (itself built atop OpenSSL/libsodium primitives, not custom code); HTML parsing for the sanitizer (D-07) uses Google's `gumbo-parser`, not a hand-written HTML tokenizer. This project's own code contains zero cryptographic primitive implementations and zero hand-written parsers for security-sensitive formats — the specific category of C++ CVE history (buffer overflows in bespoke parsers, e.g. Heartbleed-adjacent incidents) this decision exists to avoid by construction of *policy*, since it cannot be avoided by construction of *type system*.

### D-07 — `SafeHtml`: a custom allow-list HTML sanitizer built on `gumbo-parser`
Admin-edited threat/mitigation text is sanitized server-side with a small allow-list (`b`, `i`, `code`, `pre`, `a[href]` with scheme allow-listing) implemented over `gumbo-parser`'s HTML5 parse tree — the same `SafeHtml` naming convention `app04_scala_react` used for its own custom sanitizer, for the same reason (no mature, widely-adopted allow-list sanitizer library exists natively in this ecosystem). The frontend additionally runs `DOMPurify.sanitize()` at render time — defense in depth.

### D-08 — In-process token-bucket rate limiting guarded by `std::atomic`, verified by ThreadSanitizer
```cpp
class TokenBucket {
public:
    bool try_consume() {
        auto now = steady_clock::now();
        auto expected = last_refill_.load(std::memory_order_acquire);
        // ... lock-free refill + consume using compare_exchange_weak ...
    }
private:
    std::atomic<steady_clock::time_point> last_refill_;
    std::atomic<int> tokens_;
};
```
This is the same "no race condition in the rate limiter" property `app04_scala_react` gets from ZIO STM, `app06_HASKELL_react` gets from GHC's STM, and `app07_rust_react` gets from the `Send`/`Sync` type system rejecting unsound sharing at compile time — here it is achieved by careful atomic-operation design *plus* ThreadSanitizer catching any data race the design missed, which is a strictly weaker guarantee than Rust's (a `TSan`-clean test run today does not prove a `TSan`-clean run tomorrow under a code path the tests didn't exercise; Rust's compiler rejects the *unsound program*, not merely the *observed* race).

### D-09 — react-i18next with plain-text-only translation values (shared pattern)
Same as every sibling app: `pl.json`/`en.json` values are plain text only. `cc_locale` in `localStorage`; `Accept-Language` set by a fetch interceptor, allowlisted to `pl`/`en` server-side.

---

## 5. Data Model

### 5.1 Core enums and the `CardKind` variant (`src/domain/types.hpp`)
```cpp
enum class Severity { Critical, High, Medium, Low, Info };
enum class StrideCategory { S, T, R, I, D, E };
enum class SampleType { AttackDemo, Defense };
enum class CodeLanguage { Python, Java, Go, Scala, Lua };
enum class MitigationType { Preventive, Detective, Corrective, Compensating };
enum class Effort { Low, Medium, High };
enum class Effectiveness { Partial, Significant, Full };
enum class RelationshipType { Equivalent, Related, ParentChild, MapsTo };

// See D-04 — this project's strongest (and most honestly-caveated) type-level security guarantee.
struct TechnicalThreat { Severity severity; };
struct DesignHarm {};
using CardKind = std::variant<TechnicalThreat, DesignHarm>;
```

### 5.2 Framework
```cpp
struct Framework {
    FrameworkId id;               // strong-typed UUID wrapper
    std::string code;             // "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS", ...
    std::string name;
    std::string version;
    std::string description;
    std::string reference_url;
};
```

### 5.3 Threat
```cpp
struct Threat {
    ThreatId id;
    FrameworkId framework_id;
    std::string code;             // "LLM01:2025", "A03:2021", "AML.T0051"
    std::string title;
    Severity severity;
    std::string category;
    std::string description;
    std::string attack_vector;
    std::string attack_surface;
    std::vector<StrideCategory> stride;
    std::vector<std::string> tags;
};
```

### 5.4 ThreatTranslation *(i18n)*
```cpp
enum class Locale { Pl, En };

struct ThreatTranslation {
    ThreatId threat_id;
    Locale locale;
    std::string title;
    std::string description;
    std::string attack_vector;
};
```

### 5.5 CornucopiaCard *(all six YAML decks — see D-04 for `CardKind`)*
```cpp
struct CornucopiaCard {
    CardId card_id;                    // strong-typed wrapper, e.g. "VE3", "LLM4", "SCO2"
    SuitCode suit_code;                // strong-typed wrapper
    std::string suit_name;
    Edition edition;                    // Webapp | Mobileapp | Companion | Eop | Mlsec | Dbd
    CardValue value;                    // Num2..Num10 | Jack | Queen | King | Ace
    CardKind kind;                       // D-04: TechnicalThreat{severity} | DesignHarm{}
    std::string description_en;
    std::string description_pl;
    std::optional<std::string> misc_note;
    std::optional<std::string> source_url;
    std::vector<OwaspRef> owasp_refs;    // smart-constructed against an allowlist
    std::vector<MitreRef> mitre_refs;
    std::string content_sha256;
};
```

### 5.6 Mitigation
```cpp
struct Mitigation {
    MitigationId id;
    std::optional<ThreatId> threat_id;
    std::optional<CardId> card_id;
    std::string title;
    std::string description;
    MitigationType type;
    Effort effort;
    Effectiveness effectiveness;
    std::vector<CodeSample> code_samples;   // invariant "non-empty once published" is enforced by
                                              // a unit test + RapidCheck property over seed data,
                                              // NOT the type itself — std::vector has no non-empty
                                              // variant in the standard library, unlike Rust's
                                              // NonEmpty/Haskell's NonEmpty (a stated, accepted gap)
};
```

### 5.7 CodeSample
```cpp
struct CodeSample {
    CodeSampleId id;
    CodeLanguage language;
    SampleType sample_type;
    std::string title;
    std::string description;
    std::string code;
    std::string framework_hint;   // "Drogon + libpqxx", "Spring Boot 3.3", "Django ORM"...
    std::string version_note;
};
```

### 5.8 CrossReference
```cpp
struct CrossReference {
    CrossReferenceId id;
    ThreatId source_threat_id;
    ThreatId target_threat_id;
    RelationshipType relationship_type;
    std::string description;
};
```

### 5.9 ContentHash
```cpp
struct ContentHash {
    std::string file_name;
    std::string sha256_hash;
    std::chrono::system_clock::time_point verified_at;
    bool is_valid;
    std::string verified_by;     // "cpp-integrity-service"
};
```

---

## 6. Development Phases

*(Numbering aligned with the Agile/Scrum sprint plan in `SDLC_analysis.md`, §4. This is the only plan in the series with a dedicated fuzzing/sanitizer phase — Phase 3.5 — because no other sibling needed one at this scale.)*

### Phase 1 — Foundation (Sprints 1–2)
Covers: US-01, US-02
- [ ] CMake project + Conan/vcpkg dependency manifest; `api`, `worker` executables linking a shared `libcppcitadel-core` static library
- [ ] `Drogon` app bootstrap; `SecurityHeaders` middleware (CSP, HSTS, X-Frame-Options)
- [ ] Docker Compose: PostgreSQL 16 + Redis 7 + `api` + `worker` + Nginx
- [ ] Hand-authored SQL migrations for models in §5.1–5.9
- [ ] `src/bin/seed.cpp` loading OWASP Web/LLM/Agentic/API, MITRE ATLAS, CompTIA SecAI+ from JSON
- [ ] `GET /api/v1/frameworks`, `GET /api/v1/threats` (paginated)
- [ ] `jwt-cpp`-based auth middleware — editor/admin roles
- [ ] Hand-maintained OpenAPI 3 YAML + a CI check comparing it against the live Drogon route table
- [ ] React scaffold: Vite + Shadcn/UI + Tailwind + Zustand
- [ ] CI matrix established: Debug+ASan/UBSan build, Release build, nightly TSan build

**Security checkpoint:** `clang-tidy` (cppcoreguidelines/bugprone/cert groups as errors) passes; ASan/UBSan test run is green; zero raw `new`/`delete` in application code (D-01).

### Phase 2 — Core Threat Browser (Sprints 3–4)
Covers: US-02, US-03, US-04
- [ ] Parameterized `libpqxx` queries (never string-concatenated SQL) for filtering by framework, severity, stride, category, tag, q; `sqlpp11` adopted for the threat-list hot path
- [ ] `GET /api/v1/threats/:id` with nested mitigations + code samples
- [ ] React `ThreatBrowserPage`, `ThreatDetailPage` (tabs: Overview | Attack Vectors | Mitigations | Code | Cross-References)
- [ ] `GET /api/v1/cross-references`
- [ ] React `MatrixPage`

**Security checkpoint:** a CI grep rule (`scripts/check_no_string_sql.py`) fails the build on any `+`/`fmt::format`-built string passed to `pqxx::work::exec`; every query call site uses `pqxx::params`/prepared statements only.

### Phase 3 — Card Decks & Content Integrity (Sprints 5–7)
Covers: US-05–US-12, US-19
- [ ] `src/cards/loader.cpp` — hand-written `yaml-cpp` decode functions rejecting unknown keys (D-03) for **all six** `docs/OWASP_stories/*.yaml` files
- [ ] `src/integrity/verify.cpp` — SHA-256 vs `data/hashes.json`; isolated per D-02
- [ ] Card suit browsers: FRE, LLM, AAI, CLD (Companion), SP/TA/RE/ID/DS/EP (STRIDE), EMR/EIR/EOR/EDR (MLSec), PC/AA/NS/RS/CRM/CM (Mobile), VE/AT/SM/AZ/CR/C (Website App), **SCO/ARC/AGE/TRU/POR (Digital-by-Default Harms, US-19 — in scope here, not bolted on later)**
- [ ] `CardKind` (D-04) modeled as `std::variant`; every read site uses `std::visit` with an exhaustive overload set, enforced in code review

**Security checkpoint:** malformed/unknown-field YAML throws `CardDecodeError` (a `RapidCheck` property generates random extra fields and asserts rejection); content hash mismatch aborts ingestion inside a single DB transaction.

### Phase 3.5 — Fuzzing & Sanitizer Hardening (Sprint 7, dedicated — unique to this app in the series)
- [ ] `libFuzzer` harness for `decode_card_file` (all six YAML shapes), the JSON deserializers, and the `Accept-Language`/query-string parsers
- [ ] Fuzzing corpus seeded from the real `docs/OWASP_stories/*.yaml` files plus hand-crafted malformed variants
- [ ] CI job running each fuzz target for a fixed time budget (e.g. 10 minutes) on every PR touching a parsing surface, plus a longer nightly/OSS-Fuzz-style continuous run
- [ ] Any crash/ASan finding from fuzzing becomes a checked-in regression corpus entry, permanently re-run

**Security checkpoint:** zero fuzzer-found crashes or ASan/UBSan findings outstanding before this phase is considered done; this is the phase most directly compensating for the memory-safety guarantee `app07_rust_react` gets from its compiler.

### Phase 4 — Code Samples: 5 Languages (Sprints 8–9)
Covers: US-13–US-16
- [ ] Code sample seed data for every mitigation × 5 languages (Python, Java, Go, Scala, Lua)
- [ ] Attack-demo / defense sub-tabs, red-bordered warning label
- [ ] MITRE ATLAS Kill-Chain timeline (Recharts)

### Phase 5 — i18n Polish ↔ English (Sprint 9–10)
Covers: US-11 (folded into every story's acceptance criteria, see §15 note)
- [ ] `Accept-Language` parsing — allowlist `pl`/`en`, default `en` server-side (SR-13.1 rationale)
- [ ] `ThreatTranslation` served per-locale; `description_pl` fallback to English with an "EN" badge if missing
- [ ] React `react-i18next`; `LanguageToggle`; `cc_locale` in `localStorage`
- [ ] Code samples **never** translated
- [ ] CI check: i18n key-parity test fails the build on any missing key

### Phase 6 — Search, Export, Matrix Completion (Sprints 10–12)
Covers: US-17, US-18
- [ ] PostgreSQL full-text search (`tsvector` + GIN index)
- [ ] Job-table-based export (`jobs::export_csv`, `jobs::export_pdf`) processed by the `worker` thread pool
- [ ] `/matrix/llm`, `/matrix/agentic`, `/matrix/mobile-vs-web`, `/stride-heatmap`, `/matrix/digital-harms`
- [ ] Atomic token-bucket rate limiting (D-08): 60 req/min/IP on all public list endpoints (single-instance; Redis-backed counter added if horizontally scaled)

### Phase 7 — Hardening, Testing & Release (Sprints 12–14)
Covers: full regression across US-01–US-19
- [ ] GoogleTest (unit + `RapidCheck` properties), coverage ≥ 85% on `src/service` (via `gcov`/`llvm-cov`)
- [ ] Drogon test-client integration tests for every controller endpoint
- [ ] Playwright (TypeScript) E2E — one scenario per user story
- [ ] `clang-tidy` + Clang Static Analyzer + `cppcheck` + OWASP Dependency-Check in CI, zero HIGH findings
- [ ] Full ASan/UBSan and nightly TSan suite green; fuzzing corpus stable (no new crashes in the final week)
- [ ] OWASP ZAP full active scan against staging
- [ ] Production images: minimal runtime base with only the shared libraries the binary actually links (verified via `ldd` in CI)

---

## 7. API Endpoint Map

### Framework & Threat (base)
```
GET  /api/v1/frameworks
GET  /api/v1/frameworks/:code
GET  /api/v1/threats?framework=&severity=&stride=&category=&tag=&q=
GET  /api/v1/threats/:id
GET  /api/v1/threats/:id/mitigations
GET  /api/v1/threats/:id/code-samples?language=GO
```

### Cornucopia Card Suits (US-05–US-12, US-19)
```
GET  /api/v1/threats?suit=FRE                   — Frontend cards (US-05)
GET  /api/v1/threats?suit=LLM                   — LLM cards (US-06)
GET  /api/v1/threats?suit=AAI                   — Agentic AI cards (US-07)
GET  /api/v1/threats?suit=CLD                   — Cloud cards (US-07, folded into DevOps page)
GET  /api/v1/threats/stride/categories          — 6 STRIDE categories (US-08)
GET  /api/v1/threats?suit=SP|TA|RE|ID|DS|EP     — individual STRIDE suits
GET  /api/v1/threats/mlsec/categories           — 4 MLSec categories (US-09)
GET  /api/v1/threats?suit=EMR|EIR|EOR|EDR       — individual MLSec suits
GET  /api/v1/threats/mobile/suits               — 6 Mobile suits (US-10)
GET  /api/v1/threats?suit=PC|AA|NS|RS|CRM|CM    — individual Mobile suits
GET  /api/v1/threats?suit=VE|AT|SM|AZ|CR|C      — Website App Cornucopia suits (US-12)
GET  /api/v1/threats?suit=DVO                   — DevOps cards (US-11)
GET  /api/v1/threats?suit=BOT                   — Automated Threat cards (US-11)
GET  /api/v1/threats/digital-harms/suits        — 5 Digital-by-Default suits (US-19)
GET  /api/v1/threats?suit=SCO|ARC|AGE|TRU|POR   — individual Digital-by-Default suits (US-19)
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
GET  /api/v1/export?format=csv&framework=OWASP_LLM     (enqueues a jobs-table row, returns 202 + poll URL)
GET  /api/v1/export/status/:jobId
```

### Admin CRUD (JWT — Admin role)
```
POST   /api/v1/admin/threats
PUT    /api/v1/admin/threats/:id           — SafeHtml sanitize applied (D-07)
DELETE /api/v1/admin/threats/:id
POST   /api/v1/admin/code-samples
PUT    /api/v1/admin/code-samples/:id
```
`CornucopiaCard` rows (all six decks) have **no** admin write endpoint at all. Unlike Go/Haskell/Rust siblings where this is additionally backed by "the route literally does not typecheck," here it is enforced only by "no controller method registers such a route" — reviewed in `SEC REVIEW`, not compiler-verified. They are read-only, written only by `src/bin/seed.cpp`/the `reingest_deck` job.

### Health & Ops
```
GET  /api/v1/health
GET  /api/v1/metrics                        — Prometheus scrape endpoint
GET  /api/v1/admin/integrity/status         — [JWT admin] last verification run per YAML file
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

## 9. C++ Backend Project Layout

```
backend/
├── CMakeLists.txt                     ← top-level, subdirectories for core/api/worker
├── conanfile.txt (or vcpkg.json)
├── core/
│   ├── CMakeLists.txt                 ← builds libcppcitadel-core.a
│   └── src/
│       ├── domain/
│       │   ├── types.hpp              ← Section 5 enums + CardKind variant
│       │   └── strong_types.hpp       ← ThreatId, CardId, OwaspRef, MitreRef, etc.
│       ├── service/                   ← business logic
│       ├── store/
│       │   ├── queries/*.cpp          ← libpqxx / sqlpp11 call sites
│       │   └── pool.hpp
│       ├── cards/
│       │   └── loader.cpp             ← YAML → CornucopiaCard, calls integrity::verify (D-03)
│       └── integrity/
│           └── verify.hpp/.cpp        ← isolated per D-02
├── api/
│   ├── CMakeLists.txt                 ← links core; does NOT include integrity/verify.hpp
│   └── src/
│       ├── main.cpp                   ← Drogon app bootstrap
│       ├── controllers/
│       │   ├── FrameworkController.cpp
│       │   ├── ThreatController.cpp
│       │   ├── CardController.cpp
│       │   ├── MatrixController.cpp
│       │   ├── SearchController.cpp
│       │   ├── ExportController.cpp
│       │   └── AdminController.cpp
│       └── middleware/
│           ├── AuthFilter.cpp         ← jwt-cpp verification
│           ├── RateLimitFilter.cpp    ← atomic token bucket (D-08)
│           ├── SecurityHeadersFilter.cpp
│           └── CorsFilter.cpp
├── worker/
│   ├── CMakeLists.txt                 ← links core, including integrity
│   └── src/
│       ├── main.cpp                   ← std::jthread pool bootstrap
│       └── jobs/
│           ├── export_csv.cpp
│           ├── export_pdf.cpp
│           ├── reingest_deck.cpp
│           └── periodic_reverify.cpp
├── fuzz/
│   ├── fuzz_card_loader.cpp           ← libFuzzer harness (Phase 3.5)
│   └── corpus/                        ← seed corpus, checked in
├── tests/
│   ├── unit/*.cpp                     ← GoogleTest
│   ├── property/*.cpp                 ← RapidCheck
│   └── integration/*.cpp              ← Drogon test client
└── migrations/                        ← forward-only SQL

frontend/                              ← React 18 + TS + Vite (mirrors app07_rust_react §8)

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

Every `Mitigation` ships exactly **five** `CodeSample` values. Unlike `app07_rust_react` (a non-empty-vector type) or `app06_HASKELL_react` (`NonEmpty`), this project's `std::vector<CodeSample>` has no type-level non-emptiness guarantee (§5.6) — completeness is verified by a `RapidCheck` property over the seeded dataset and a CI seed-data linter, a runtime/test-time check rather than a type-level one, consistent with this project's overall theme.

| Language | Primary framework/library used in samples |
|---|---|
| Python | Django ORM / FastAPI + Pydantic |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | `chi` + `sqlc` + `pgx` |
| Scala | Akka HTTP / http4s, Slick 3.x, ZIO 2 |
| Lua | OpenResty / NGINX Lua, `lua-resty-jwt`, LuaSQL |

```
sample_type: AttackDemo   // VULNERABLE — do not use in production
sample_type: Defense      // SECURE pattern, with a one-line WHY comment
```

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
| CompTIA Security+ / SecAI+ | ≥ 20 topics, **explicitly including CWE Top 25 memory-safety weaknesses and CISA/NSA memory-safe-language migration guidance** as a topic that this app's own implementation choice is directly relevant to | seeded JSON, from `docs/Security Architects...md` mapping table |
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
2. CI job `yaml-content-integrity`: the hand-written `decode_card_file` function (D-03) must succeed against every file (any unrecognized shape throws `CardDecodeError`, not partial data) + injection-pattern grep + ref-allowlist validation + a fuzzing pass over the actual file contents as a seed corpus entry (Phase 3.5).
3. Post-merge: a `hash-generator` CI step updates `data/hashes.json`.
4. `src/bin/seed.cpp` and the `reingest_deck` job both call `integrity::verify` — on mismatch, ingestion aborts inside a single DB transaction (no partial writes) and a `SEC-CARD-HASH-MISMATCH` structured log line fires via `spdlog::error`, which Loki alerts on.

---

## 13. Risk Register

*(This register is longer, and its entries are more often "mitigated by process/tooling" rather than "prevented by the type system," than any other app in this series — that asymmetry is the point of this plan, not an oversight.)*

| Risk | Mitigation |
|---|---|
| Memory-corruption bug (buffer overflow, use-after-free) in application code | RAII/smart-pointer discipline (D-01) + `clang-tidy` + ASan/UBSan on every test run + continuous fuzzing (Phase 3.5) — a **detection-and-prevention-by-process** stack, not a compile-time guarantee; a bug in an untested code path can still ship |
| Data race in the rate limiter or worker pool | Atomic-operation design (D-08) + nightly ThreadSanitizer run — same caveat: only as good as test coverage of concurrent code paths |
| YAML card files tampered in a PR | CODEOWNERS review + `integrity::verify` SHA-256 check, fail-secure |
| A future contributor adds a `CornucopiaCard` field and forgets to update the hand-written YAML decoder or the `std::visit` overload set | `RapidCheck` properties (decoder) + code-review requirement that all `CardKind` reads go through `std::visit` (D-04) — both are process controls, not compiler-enforced ones, and this is flagged as this project's single largest structural risk versus its Go/Haskell/Rust siblings |
| Digital-by-Default Harms deck misread as CVE severity | `CardKind` variant (D-04) — a `DesignHarm` value cannot carry a `Severity` at the type level, *given* callers use `std::visit` correctly (see the risk above) |
| Polish translations drift from English source | `content_sha256` stored per card; translation table flags staleness on English-text change |
| `integrity::verify` linked into `controllers/` by accident | CI build-graph grep (D-02) — weaker than a compiler-enforced boundary; a reviewer must not approve a PR that adds the `#include` even if CI hasn't yet caught it |
| No mature C++ ecosystem equivalent to `sqlc`/`hasql-th`/`sqlx::query!`/`river`/`apalis`/`odd-jobs` | `sqlpp11` adopted for hot-path queries where feasible; hand-rolled job-table worker pool for the rest — both are more code this project must maintain and test itself than any sibling app needed to write |
| Attack-demo code confused with production-safe code | Red border + `AttackDemo` badge + confirmation modal before code is shown/copied |
| Bot scraping the full catalogue | Atomic/Redis rate limit 60 req/min/IP (D-08) |

---

## 14. Directory Layout

```
app08_cpp_react/
├── PLAN.md
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
├── backend/            ← see §9 for full internal layout
├── frontend/            ← React 18 + TS + Vite (mirrors app07_rust_react structure)
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
| US-14 | Java developer | see a Java code sample for each mitigation | compare against this app's own C++ implementation idioms |
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
| M1 | Working skeleton | `docker compose up` → `api` health check 200; React SPA loads |
| M2 | Full data seed | All frameworks + threats + mitigations in DB; API returns correct counts |
| M3 | All six card decks ingested | `integrity::verify` reports `is_valid = true` for all six YAML files, including `dbd-cards-1.0-en.yaml` |
| M3.5 | Fuzzing baseline established | `libFuzzer` runs 10+ minutes per PR touching a parsing surface with zero new crashes; nightly continuous run has a stable, checked-in corpus |
| M4 | Code samples complete | Every mitigation has 5 language samples visible on Threat Detail |
| M5 | Matrix + heatmap | Cross-reference table renders; STRIDE heatmap shows coverage % |
| M6 | i18n complete | PL/EN toggle everywhere; i18n key-parity CI check passes |
| M7 | Search + export work | Full-text search returns highlighted results; CSV/PDF export completes via the worker pool |
| M8 | Digital-by-Default Harms | `DigitalHarmsPage` renders all 5 suits with `DesignHarmBadge`; A04:2021 cross-reference visible; every `CardKind`-inspecting code path reviewed to confirm it uses `std::visit`, not `std::get`/`std::get_if` |
| M9 | Security hardening | `clang-tidy`/Clang Static Analyzer/`cppcheck`/OWASP Dependency-Check zero HIGH; ASan/UBSan/TSan clean; ZAP full scan zero HIGH |
| M10 | Tests green | ≥ 90% of TDD test list in `user_stories+tests.md` passing in CI |
