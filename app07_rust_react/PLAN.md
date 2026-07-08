# RustBastion 2026 — Application Development Plan

**Version:** 1.0
**Date:** 2026-07-07
**Status:** Living document — updated after each sprint planning session
**Directory:** `app07_rust_react`
**Sibling projects:** `app01_react`/`app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django), `app04_scala_react` (Scala/ZIO), `app05_go_react` (Go), `app06_HASKELL_react` (Haskell)

---

## 0. Note on the Stack

This application is written **entirely in Rust** (stable toolchain, 2024 edition) for the backend — no second backend language — with a **React 18 + TypeScript** frontend, matching the React-frontend pattern of `app01_react`/`app04_scala_react`/`app05_go_react`/`app06_HASKELL_react`. This is the sixth backend ecosystem in the course's comparison series, and the one most directly aligned with where the industry's own 2026 security guidance is pointing: CISA, the NSA, and multiple national cybersecurity agencies have publicly urged migration to **memory-safe languages** for new development, naming Rust specifically. This plan treats that not as a marketing line but as a concrete engineering property to state and verify (§4 Architecture Design Decisions, D-01).

**Why this matters for the course:** every prior sibling app used its language's type system or tooling to push one or more *logical* security properties earlier in the SDLC (Django's ORM, ZIO Quill, `sqlc`, Haskell's ADTs). Rust adds a property none of the JVM/Python/Go/Haskell siblings can make in the same way: **the compiler statically eliminates an entire class of memory-corruption vulnerabilities** (use-after-free, double-free, buffer overflows, data races) *without* a garbage collector — the ownership/borrow-checker system enforces this at compile time, for zero runtime cost. This is the specific property behind CISA's 2026 guidance, and this plan is explicit that it is a **different** class of guarantee than the SQL-injection-prevention or illegal-states-unrepresentable properties the other five apps demonstrate — Rust's memory-safety guarantee has essentially no bearing on, say, a business-logic authorization bug, and this plan does not conflate the two.

**Note on code samples:** the application still *teaches* countermeasures in five languages — Python, Java, Go, Scala, and Lua (see §10) — because that is separate, deliberately polyglot **content**, not the application's own runtime. None of those five languages is the application's implementation language; the app itself never depends on a JVM, a Python interpreter, or a second compiled language.

---

## 1. Project Overview

**Name:** RustBastion 2026
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

All six decks are in scope from day one of this plan (§11, §15) — the gap the `app04_scala_react` plan initially had (and was later corrected for) is avoided here from the start, as it was for `app05_go_react` and `app06_HASKELL_react`.

**UI languages:** Polish (default) and English, switched instantly with no page reload; toggle persisted in `localStorage` under key `rb_locale`, mirrored server-side via `Accept-Language`.

---

## 2. Technology Stack

### Backend (100% Rust, `#![forbid(unsafe_code)]` at the application crate root)
| Layer | Technology | Version (2026) |
|---|---|---|
| Language | Rust | stable, 2024 edition |
| Async runtime | Tokio | 1.x |
| Web framework | `axum` (built on Tokio + Tower) | 0.8.x |
| Database access | `sqlx` — `query!`/`query_as!` macros checked against a live schema at **compile time** | 0.8.x |
| Database | PostgreSQL 16 | — |
| Migrations | `sqlx migrate` | — |
| Cache / rate-limit store | in-process `governor` (GCRA token bucket, `Arc`-shared, data-race-free by the type system, not by discipline) for single-instance limits; Redis 7 (`redis-rs`) for cross-instance cache | — |
| Background jobs | `apalis` — PostgreSQL-backed job queue for Rust/Tokio (export, YAML re-ingestion, periodic integrity re-check) | — |
| Auth | `jsonwebtoken` (RS256) | — |
| Password hashing | `argon2` crate (Argon2id — memory-hard, the current OWASP-recommended default, a deliberate step up from the `bcrypt` used in `app05_go_react`/`app06_HASKELL_react`) | — |
| Validation | `validator` crate (derive-based) + hand-written smart constructors | — |
| HTML sanitization | `ammonia` — pure-Rust, allow-list HTML sanitizer built on `html5ever` | — |
| YAML parsing | `serde_yaml` with `#[serde(deny_unknown_fields)]` on every target struct | — |
| Structured logging | `tracing` + `tracing-subscriber` | — |
| API docs | `utoipa` → OpenAPI 3 / Swagger UI, generated from the same handler/type annotations that define the routes | — |
| Testing | built-in `#[test]`/`#[tokio::test]` + `proptest` (property-based testing) + `axum-test`/`reqwest` (HTTP-level tests) | TDD — see `user_stories+tests.md` |
| SAST | `clippy` (`-D warnings`), `cargo-geiger` (reports `unsafe` usage across the dependency tree) | — |
| SCA | `cargo audit` + `cargo-deny` (RustSec advisory database + license/duplicate-version checks) + Trivy (containers) | — |

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
| Container | Docker + Docker Compose — multi-stage build: `rust:1.8x` builder (musl target) → `FROM scratch` runtime for a fully static binary with no libc dependency at all |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Loki + Prometheus (`metrics` + `metrics-exporter-prometheus` crates) |
| Secrets | Docker Secrets / GitHub Secrets / `.env` (never committed) |
| SAST | `clippy -D warnings` + `cargo-geiger` + `eslint-plugin-security` (frontend) |
| DAST | OWASP ZAP |
| SCA | `cargo audit` + `cargo-deny` + `npm audit` + Trivy |

---

## 3. High-Level Architecture

```
Browser (React 18 SPA, PL/EN)
        │
        │  HTTPS
        ▼
  Nginx (port 443)
   ├── /api/v1/*   ─────► Rust `api` binary (Axum + Tokio, port 8080)
   │                         ├── src/bin/api.rs             — Axum server entrypoint
   │                         ├── src/routes/                — Axum routers + extractors
   │                         ├── src/service/                — business logic
   │                         ├── src/store/                  — sqlx queries + PgPool
   │                         └── src/integrity/                — YAML hash verification (module
   │                                                              is `pub(crate)`, and its `verify`
   │                                                              function is re-exported only to
   │                                                              src/bin/seed.rs and src/jobs — never
   │                                                              reachable from src/routes, enforced by
   │                                                              visibility + a CI check, see D-05)
   │
   └── /*          ─────► React SPA static build (served by Nginx directly)

`worker` binary (same Cargo workspace, separate binary + container)
   ├── apalis job consumer (jobs::export_csv, jobs::export_pdf,
   │                        jobs::reingest_deck, jobs::periodic_reverify)
   └── shares src/service, src/store, src/integrity with the api binary

PostgreSQL 16   ◄── sqlx pool, compile-time-checked queries (threats, cards, mitigations, users, apalis' own tables)
Redis 7         ◄── cross-instance cache; governor handles single-instance rate limiting in-process
```

**Where the trust boundaries are:** `api` and `worker` are **two separately compiled binaries** from one Cargo workspace — a real OS-process boundary, the same pattern used by `app05_go_react` (`cmd/api`/`cmd/worker`) and `app06_HASKELL_react` (`api`/`worker` executables). `src/integrity`'s `verify` function is `pub(crate)` with an explicit `pub(crate) use` re-export list naming only `src/bin/seed.rs` and `src/jobs::periodic_reverify` — Rust's module visibility keywords (`pub`, `pub(crate)`, `pub(super)`) enforce this at compile time within the crate, and a CI step (`cargo modules` graph inspection) additionally fails the build if any `src/routes/**` module ends up depending on `src/integrity` through a transitive path.

---

## 4. Architecture Design Decisions

### D-01 — `#![forbid(unsafe_code)]`: memory safety as a compile-time, crate-wide guarantee
```rust
// src/lib.rs (application crate root)
#![forbid(unsafe_code)]
```
This attribute makes it a **hard compile error** for a single `unsafe` block to exist anywhere in the application's own crate — not a lint warning that can be silenced, not a code-review convention, a build failure. Combined with Rust's ownership and borrow-checker rules (enforced regardless of this attribute, in every Rust program), this eliminates, for all code this project writes, the entire class of memory-corruption vulnerabilities that motivate CISA's 2026 memory-safe-language guidance: use-after-free (CWE-416), double-free (CWE-415), out-of-bounds read/write (CWE-125/CWE-787), and NULL-pointer dereference (CWE-476, which cannot occur at all — Rust has no null; absence is `Option::None`, checked exhaustively by the compiler). `cargo-geiger` (§2, SAST) additionally reports `unsafe` usage in the *dependency* tree, since `#![forbid(unsafe_code)]` only covers this project's own code — a fact this plan states rather than glosses over.

### D-02 — `sqlx::query!`: compile-time-checked SQL, verified against the real schema
Every query uses `sqlx::query!`/`query_as!`, which connects to a `DATABASE_URL` (a real or CI-provisioned schema-migrated database) **at compile time** and verifies the SQL parses and its parameter/result types match the annotated Rust types. A typo in a column name, or a type mismatch, is a compile error — the same class of guarantee `sqlc` gives `app05_go_react`, ZIO Quill gives `app04_scala_react`, and `hasql-th` gives `app06_HASKELL_react`, achieved here via Rust's macro system checking against a live connection.

### D-03 — Ownership and `Send`/`Sync` make data races a compile error, not a runtime risk
Any type shared across the `governor` rate limiter's async tasks or the `apalis` worker pool must implement `Send` (safe to transfer between threads) and, if shared by reference, `Sync` (safe to access concurrently) — the compiler verifies this for every type used this way, at every call site, with no annotation needed beyond what naturally falls out of the type's definition. This is the same "no race condition in the rate limiter" property `app04_scala_react` gets from ZIO STM and `app06_HASKELL_react` gets from GHC's STM — Rust's version is enforced by the type system rejecting the *program* if a data race is possible, rather than by a runtime transactional mechanism preventing the race from having an effect. The two approaches (compile-time rejection vs. runtime atomicity) are different tools solving the same class of problem, and this plan treats them as siblings, not as one being "better."

### D-04 — `ammonia`: pure-Rust, allow-list HTML sanitization
Admin-edited threat/mitigation text is sanitized server-side with `ammonia::Builder` restricted to a small allow-list (`b`, `i`, `code`, `pre`, `a[href]` with scheme allow-listing) before persisting. The frontend additionally runs `DOMPurify.sanitize()` at render time — defense in depth, with no JVM library anywhere in the chain (the same principle `app05_go_react` established with `bluemonday` and `app06_HASKELL_react` established with `xss-sanitize`).

### D-05 — Module visibility (`pub(crate)`) plus a dependency-graph CI check as the least-privilege mechanism
`src/integrity::verify` is visible only within the crate, and further, only two call sites are permitted to invoke it (`src/bin/seed.rs`, `src/jobs::periodic_reverify`) — enforced by keeping the function un-re-exported from any module `src/routes` could import, plus a CI step that fails if `cargo modules generate graph` shows an edge from any `routes::*` module to `integrity`. This is the same discipline `app03_python_django` (import-graph test), `app04_scala_react` (opaque types), `app05_go_react` (`internal/` + `depguard`), and `app06_HASKELL_react` (module export lists) each apply with their own language's tools.

### D-06 — `Option<T>`/`Result<T, E>` instead of null and exceptions
Rust has no null pointer and no exceptions for expected error paths — a function that might not find a threat returns `Option<Threat>`; a function that might fail returns `Result<Threat, ApiError>`. The compiler requires every `match`/`?`-usage to account for both cases (an unhandled `Result` produces an "unused `Result` that must be used" warning, promoted to an error via `#[must_use]` and `clippy -D warnings`). This removes the "forgot to check" bug class the same way `app06_HASKELL_react`'s `Maybe`/`Either` do, using Rust's own enum-based equivalents.

### D-07 — Smart-constructed newtypes for security-sensitive identifiers
```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OwaspRef(String);

impl OwaspRef {
    pub fn new(raw: &str, allowlist: &OwaspRefAllowlist) -> Result<Self, ValidationError> {
        allowlist.contains(raw).then(|| Self(raw.to_owned())).ok_or(ValidationError::UnknownOwaspRef)
    }
}
```
A raw `String` cannot be used where an `OwaspRef` is expected without going through `OwaspRef::new`, which validates against the allowlist — the same pattern `app05_go_react`'s named types and `app06_HASKELL_react`'s smart constructors use, expressed with Rust's own newtype idiom (a zero-cost wrapper — no runtime overhead versus a raw `String`).

### D-08 — `apalis`: Postgres-backed job queue, same database as the app
Background work (export, YAML re-ingestion, periodic integrity re-check) is enqueued as rows in the same PostgreSQL database `apalis` polls — no separate broker to secure for job dispatch (Redis remains in use only for cross-instance response caching; D-03 covers in-process rate limiting via `governor` instead). Job payloads are `serde`-deserialized Rust structs with `#[serde(deny_unknown_fields)]`, decoded the same safe way as the Cornucopia YAML (D-09).

### D-09 — `serde_yaml` with `deny_unknown_fields` — no arbitrary-type gadget class, same story as Go and Haskell, stated the same way
`FromJSON`-equivalent `Deserialize` derives for `CardFile` target a closed set of Rust structs/enums with `#[serde(deny_unknown_fields)]`; there is no equivalent of a "construct any object the parser recognizes" fallback. As with `app05_go_react`'s D-09 and `app06_HASKELL_react`'s D-07, this plan states plainly that this removes a specific vulnerability *class* (the one `yaml.safe_load`/`SafeConstructor` exist to prevent in Python/Java) without implying the YAML *content* is trustworthy — SHA-256 integrity verification (D-05) still applies unconditionally.

### D-10 — `#![forbid(unsafe_code)]` applied to `CardKind`: the Digital-by-Default Harms deck cannot carry a severity
```rust
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(tag = "kind", content = "value")]
pub enum CardKind {
    TechnicalThreat(Severity),   // every card from the other 5 decks
    DesignHarm,                  // every card from dbd-cards-1.0-en.yaml (US-19) — no fields at all
}
```
There is no `Severity` reachable from a `DesignHarm` value — a different enum variant with no payload, not a `nullable`/`Option<Severity>` that could accidentally be filled in. `match`ing on `CardKind` without handling both variants is a compile error (`clippy`'s exhaustiveness check via `-D warnings`, backed by the language's own non-exhaustive-match error). This is the same guarantee `app06_HASKELL_react` builds with a sum type — Rust's `enum` is the direct equivalent of a Haskell ADT for this purpose, and this plan treats the two as the same idea in two languages rather than a Haskell-exclusive trick.

### D-11 — react-i18next with plain-text-only translation values (shared pattern)
Same as every sibling app: `pl.json`/`en.json` values are plain text only. `rb_locale` in `localStorage`; `Accept-Language` set by a fetch interceptor, allowlisted to `pl`/`en` server-side.

---

## 5. Data Model

### 5.1 Core enums (`src/domain/types.rs`)
```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub enum Severity { Critical, High, Medium, Low, Info }

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum StrideCategory { S, T, R, I, D, E }

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum SampleType { AttackDemo, Defense }

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum CodeLanguage { Python, Java, Go, Scala, Lua }

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum MitigationType { Preventive, Detective, Corrective, Compensating }

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Effort { Low, Medium, High }

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Effectiveness { Partial, Significant, Full }

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum RelationshipType { Equivalent, Related, ParentChild, MapsTo }

// See D-10 — this project's strongest type-level security guarantee.
#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
#[serde(tag = "kind", content = "value")]
pub enum CardKind { TechnicalThreat(Severity), DesignHarm }
```

### 5.2 Framework
```rust
pub struct Framework {
    pub id: FrameworkId,               // newtype around Uuid
    pub code: String,                  // "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS", ...
    pub name: String,
    pub version: String,
    pub description: String,
    pub reference_url: String,
}
```

### 5.3 Threat
```rust
pub struct Threat {
    pub id: ThreatId,
    pub framework_id: FrameworkId,
    pub code: String,                  // "LLM01:2025", "A03:2021", "AML.T0051"
    pub title: String,
    pub severity: Severity,
    pub category: String,
    pub description: String,
    pub attack_vector: String,
    pub attack_surface: String,
    pub stride: Vec<StrideCategory>,
    pub tags: Vec<String>,
}
```

### 5.4 ThreatTranslation *(i18n)*
```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum Locale { Pl, En }

pub struct ThreatTranslation {
    pub threat_id: ThreatId,
    pub locale: Locale,
    pub title: String,
    pub description: String,
    pub attack_vector: String,
}
```

### 5.5 CornucopiaCard *(all six YAML decks — see D-10 for `CardKind`)*
```rust
pub struct CornucopiaCard {
    pub card_id: CardId,                 // newtype String, e.g. "VE3", "LLM4", "SCO2"
    pub suit_code: SuitCode,             // newtype String
    pub suit_name: String,
    pub edition: Edition,                // Webapp | Mobileapp | Companion | Eop | Mlsec | Dbd
    pub value: CardValue,                 // Num2..Num10 | Jack | Queen | King | Ace
    pub kind: CardKind,                   // D-10: TechnicalThreat(Severity) | DesignHarm
    pub description_en: String,
    pub description_pl: String,
    pub misc_note: Option<String>,
    pub source_url: Option<String>,
    pub owasp_refs: Vec<OwaspRef>,         // D-07: smart-constructed against an allowlist
    pub mitre_refs: Vec<MitreRef>,
    pub content_sha256: String,
}
```

### 5.6 Mitigation
```rust
pub struct Mitigation {
    pub id: MitigationId,
    pub threat_id: Option<ThreatId>,
    pub card_id: Option<CardId>,
    pub title: String,
    pub description: String,
    pub mitigation_type: MitigationType,
    pub effort: Effort,
    pub effectiveness: Effectiveness,
    pub code_samples: Vec1<CodeSample>,    // Vec1: a hand-rolled or `nonempty` crate wrapper —
                                             // a Mitigation cannot be constructed with zero samples
}
```

### 5.7 CodeSample
```rust
pub struct CodeSample {
    pub id: CodeSampleId,
    pub language: CodeLanguage,
    pub sample_type: SampleType,
    pub title: String,
    pub description: String,
    pub code: String,
    pub framework_hint: String,          // "axum + sqlx", "Spring Boot 3.3", "Django ORM"...
    pub version_note: String,
}
```

### 5.8 CrossReference
```rust
pub struct CrossReference {
    pub id: CrossReferenceId,
    pub source_threat_id: ThreatId,
    pub target_threat_id: ThreatId,
    pub relationship_type: RelationshipType,
    pub description: String,
}
```

### 5.9 ContentHash
```rust
pub struct ContentHash {
    pub file_name: String,
    pub sha256_hash: String,
    pub verified_at: DateTime<Utc>,
    pub is_valid: bool,
    pub verified_by: String,             // "rust-integrity-service"
}
```

---

## 6. Development Phases

*(Numbering aligned with the Agile/Scrum sprint plan in `SDLC_analysis.md`, §4.)*

### Phase 1 — Foundation (Sprints 1–2)
Covers: US-01, US-02
- [ ] `cargo new --lib rustbastion-core`; workspace members `api`, `worker`, sharing `rustbastion-core` (`src/domain`, `src/service`, `src/store`, `src/integrity`)
- [ ] `#![forbid(unsafe_code)]` at the crate root of every workspace member (D-01)
- [ ] `axum` router skeleton; `SecurityHeaders` Tower middleware (CSP, HSTS, X-Frame-Options)
- [ ] Docker Compose: PostgreSQL 16 + Redis 7 + `api` + `worker` + Nginx
- [ ] `sqlx migrate` migrations for models in §5.1–5.9; `cargo sqlx prepare` cached query metadata committed for offline CI builds
- [ ] `src/bin/seed.rs` loading OWASP Web/LLM/Agentic/API, MITRE ATLAS, CompTIA SecAI+ from JSON
- [ ] `GET /api/v1/frameworks`, `GET /api/v1/threats` (paginated)
- [ ] `jsonwebtoken`-based auth middleware — editor/admin roles
- [ ] `utoipa` → `/api/v1/docs/swagger-ui/`
- [ ] React scaffold: Vite + Shadcn/UI + Tailwind + Zustand

**Security checkpoint:** `cargo clippy -- -D warnings` passes; `cargo-geiger` reports zero `unsafe` blocks in `rustbastion-core`/`api`/`worker`; `SecurityHeaders` active on every response.

### Phase 2 — Core Threat Browser (Sprints 3–4)
Covers: US-02, US-03, US-04
- [ ] `sqlx::query!` statements: filter threats by framework, severity, stride, category, tag, q
- [ ] `GET /api/v1/threats/:id` with nested mitigations + code samples
- [ ] React `ThreatBrowserPage`, `ThreatDetailPage` (tabs: Overview | Attack Vectors | Mitigations | Code | Cross-References)
- [ ] `GET /api/v1/cross-references`
- [ ] React `MatrixPage`

**Security checkpoint:** every `sqlx::query!` invocation compiles only if it type-checks against the schema (D-02); no `String`-formatted SQL exists anywhere (there is no code path capable of building one without going through `sqlx::query!`/`query_as!`).

### Phase 3 — Card Decks & Content Integrity (Sprints 5–7)
Covers: US-05–US-12, US-19
- [ ] `src/cards/loader.rs` — `serde_yaml::from_str` into `#[serde(deny_unknown_fields)]` structs for **all six** `docs/OWASP_stories/*.yaml` files
- [ ] `src/integrity/mod.rs` — SHA-256 vs `data/hashes.json`; `verify` visible only to `src/bin/seed.rs` and `jobs::periodic_reverify` (D-05)
- [ ] Card suit browsers: FRE, LLM, AAI, CLD (Companion), SP/TA/RE/ID/DS/EP (STRIDE), EMR/EIR/EOR/EDR (MLSec), PC/AA/NS/RS/CRM/CM (Mobile), VE/AT/SM/AZ/CR/C (Website App), **SCO/ARC/AGE/TRU/POR (Digital-by-Default Harms, US-19 — in scope here, not bolted on later)**
- [ ] `CardKind` (D-10) enforced by the type itself: no deserialization path can produce a `DesignHarm` value carrying a severity
- [ ] `AttackDemoWarning` confirmation modal before rendering `AttackDemo` code samples

**Security checkpoint:** malformed/unknown-field YAML fails `Deserialize` (a `proptest` property generates random extra fields and asserts decode failure); content hash mismatch aborts ingestion inside a single DB transaction.

### Phase 4 — Code Samples: 5 Languages (Sprints 7–9)
Covers: US-13–US-16
- [ ] Code sample seed data for every mitigation × 5 languages (Python, Java, Go, Scala, Lua)
- [ ] Attack-demo / defense sub-tabs, red-bordered warning label
- [ ] MITRE ATLAS Kill-Chain timeline (Recharts)

### Phase 5 — i18n Polish ↔ English (Sprint 9–10)
Covers: US-11 (folded into every story's acceptance criteria, see §15 note)
- [ ] `Accept-Language` extractor — allowlist `pl`/`en`, default `en` server-side (SR-12.1 rationale)
- [ ] `ThreatTranslation` served per-locale; `description_pl` fallback to English with an "EN" badge if missing
- [ ] React `react-i18next`; `LanguageToggle`; `rb_locale` in `localStorage`
- [ ] Code samples **never** translated
- [ ] CI check: i18n key-parity test fails the build on any missing key

### Phase 6 — Search, Export, Matrix Completion (Sprints 10–12)
Covers: US-17, US-18
- [ ] PostgreSQL full-text search (`tsvector` + GIN index)
- [ ] `apalis`-based export (`jobs::export_csv`, `jobs::export_pdf`)
- [ ] `/matrix/llm`, `/matrix/agentic`, `/matrix/mobile-vs-web`, `/stride-heatmap`, `/matrix/digital-harms`
- [ ] `governor`-based rate limiting (D-03): 60 req/min/IP on all public list endpoints (single-instance; Redis-backed counter added if horizontally scaled)

### Phase 7 — Hardening, Testing & Release (Sprints 12–14)
Covers: full regression across US-01–US-19
- [ ] `cargo test` (unit + `proptest` properties), coverage ≥ 85% on `src/service` (via `cargo-tarpaulin` or `cargo-llvm-cov`)
- [ ] `axum-test`/`reqwest`-based integration tests for every handler
- [ ] Playwright (TypeScript) E2E — one scenario per user story
- [ ] `clippy -D warnings` + `cargo audit` + `cargo-deny` + `cargo-geiger` in CI, zero HIGH findings
- [ ] OWASP ZAP full active scan against staging
- [ ] Production images: `api`/`worker` as fully static `musl`-target binaries in `FROM scratch` — no libc, no shell, no interpreter at all inside the running container

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
GET  /api/v1/export?format=csv&framework=OWASP_LLM     (enqueues apalis job, returns 202 + poll URL)
GET  /api/v1/export/status/:jobId
```

### Admin CRUD (JWT — Admin role)
```
POST   /api/v1/admin/threats
PUT    /api/v1/admin/threats/:id           — ammonia sanitize applied (D-04)
DELETE /api/v1/admin/threats/:id
POST   /api/v1/admin/code-samples
PUT    /api/v1/admin/code-samples/:id
```
`CornucopiaCard` rows (all six decks) have **no** admin write endpoint at all. The Axum router simply has no route registered for it — not merely unenforced by role middleware, it does not exist for a client to even attempt to call. They are read-only, written only by `src/bin/seed.rs`/the `reingest_deck` job.

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

## 9. Rust Backend Workspace Layout

```
backend/
├── Cargo.toml                         ← workspace: members = ["core", "api", "worker"]
├── core/
│   ├── Cargo.toml
│   └── src/
│       ├── lib.rs                     ← #![forbid(unsafe_code)] (D-01)
│       ├── domain/
│       │   ├── types.rs               ← Section 5 enums
│       │   └── newtypes.rs            ← ThreatId, CardId, OwaspRef, MitreRef, etc. (D-07)
│       ├── service/                   ← business logic
│       ├── store/
│       │   ├── queries/*.rs           ← sqlx::query! call sites
│       │   └── pool.rs
│       ├── cards/
│       │   └── loader.rs              ← YAML → CornucopiaCard, calls integrity::verify
│       └── integrity/
│           └── mod.rs                 ← pub(crate) fn verify(...) — D-05
├── api/
│   ├── Cargo.toml                     ← #![forbid(unsafe_code)]
│   └── src/
│       ├── main.rs                    ← Axum server entrypoint
│       ├── routes/
│       │   ├── framework.rs
│       │   ├── threat.rs
│       │   ├── card.rs
│       │   ├── matrix.rs
│       │   ├── search.rs
│       │   ├── export.rs
│       │   └── admin.rs
│       └── middleware/
│           ├── auth.rs                ← jsonwebtoken verification
│           ├── rate_limit.rs          ← governor GCRA bucket (D-03)
│           ├── security_headers.rs
│           └── cors.rs
├── worker/
│   ├── Cargo.toml                     ← #![forbid(unsafe_code)]
│   └── src/
│       ├── main.rs                    ← apalis job consumer entrypoint
│       └── jobs/
│           ├── export_csv.rs
│           ├── export_pdf.rs
│           ├── reingest_deck.rs
│           └── periodic_reverify.rs
├── tests/
│   ├── integration/*.rs               ← axum-test / reqwest against a running app
│   └── property/*.rs                  ← proptest suites
└── migrations/                        ← sqlx migrate, forward-only SQL

frontend/                              ← React 18 + TS + Vite (mirrors app06_HASKELL_react §8)

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

Every `Mitigation` ships exactly **five** `CodeSample` values, enforced at the type level by a non-empty vector wrapper (`PLAN.md` §5.6) — a `Mitigation` with zero samples cannot be constructed, and seed-data completeness (all five languages present) is additionally checked by a `proptest` property over the seeded dataset.

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
| CompTIA Security+ / SecAI+ | ≥ 20 topics, including memory-safe-language guidance as a 2026 GRC/architecture topic | seeded JSON, from `docs/Security Architects...md` mapping table |
| OWASP A04:2021 Insecure Design — Digital-by-Default Harms | Scope/Architecture/Agency/Trust/Porosity | `SCO/ARC/AGE/TRU/POR` suits (US-19) — **not** a technical-vulnerability deck, see D-10 |

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
2. CI job `yaml-content-integrity`: `serde_yaml::from_str` must succeed against the `#[serde(deny_unknown_fields)]` `CardFile` struct (any unrecognized shape is a parse failure, not partial data) + injection-pattern grep + ref-allowlist validation.
3. Post-merge: a `hash-generator` CI step updates `data/hashes.json`.
4. `src/bin/seed.rs` and the `reingest_deck` job both call `integrity::verify` — on mismatch, ingestion aborts inside a single DB transaction (no partial writes) and a `SEC-CARD-HASH-MISMATCH` structured log line fires via `tracing::error!`, which Loki alerts on.

---

## 13. Risk Register

| Risk | Mitigation |
|---|---|
| `sqlx::query!` compile-time DB check requires a live/offline-cached schema at build time | `cargo sqlx prepare` metadata committed to the repo; CI uses the same Docker Compose Postgres |
| YAML card files tampered in a PR | CODEOWNERS review + `integrity::verify` SHA-256 check, fail-secure |
| Digital-by-Default Harms deck misread as CVE severity | `CardKind` enum (D-10) — structurally cannot happen, not just discouraged |
| Polish translations drift from English source | `content_sha256` stored per card; translation table flags staleness on English-text change |
| `integrity::verify` called from an unintended module | Module visibility (D-05) + CI dependency-graph check |
| `apalis` payload injection | Job payloads are `#[serde(deny_unknown_fields)]` structs, validated the same way as Cornucopia YAML — never a raw `serde_json::Value` interpreted at execution time |
| `unsafe` code hiding in a dependency | `cargo-geiger` reports dependency-tree `unsafe` usage; reviewed as part of dependency-update PRs, not just at initial adoption |
| `governor` rate limiter is per-instance only | Documented limitation; horizontal scaling adds a Redis-backed counter as a second layer, not a silent gap |
| Attack-demo code confused with production-safe code | Red border + `AttackDemo` badge + confirmation modal before code is shown/copied |
| Bot scraping the full catalogue | `governor`/Redis rate limit 60 req/min/IP (D-03) |

---

## 14. Directory Layout

```
app07_rust_react/
├── PLAN.md
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
├── backend/            ← see §9 for full internal layout
├── frontend/            ← React 18 + TS + Vite (mirrors app06_HASKELL_react structure)
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
| US-14 | Java developer | see a Java code sample for each mitigation | compare against a memory-safe alternative's idioms |
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
| M4 | Code samples complete | Every mitigation has 5 language samples visible on Threat Detail |
| M5 | Matrix + heatmap | Cross-reference table renders; STRIDE heatmap shows coverage % |
| M6 | i18n complete | PL/EN toggle everywhere; i18n key-parity CI check passes |
| M7 | Search + export work | Full-text search returns highlighted results; CSV/PDF export completes via `apalis` |
| M8 | Digital-by-Default Harms | `DigitalHarmsPage` renders all 5 suits with `DesignHarmBadge`; A04:2021 cross-reference visible; the API's JSON for these cards has no `severity` field at all |
| M9 | Security hardening | `clippy`/`cargo audit`/`cargo-deny`/`cargo-geiger` zero HIGH; ZAP full scan zero HIGH; zero `unsafe` blocks in application code |
| M10 | Tests green | ≥ 90% of TDD test list in `user_stories+tests.md` passing in CI |
