# HaskShield 2026 — Application Development Plan

**Version:** 1.0
**Date:** 2026-07-07
**Status:** Living document — updated after each sprint planning session
**Directory:** `app06_HASKELL_react`
**Sibling projects:** `app01_react` (Java/Spring Boot), `app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django), `app04_scala_react` (Scala/ZIO), `app05_go_react` (Go)

---

## 0. Note on the Stack

This application is written **entirely in Haskell** (GHC 9.8) for the backend — no second backend language — with a **React 18 + TypeScript** frontend, matching the React-frontend pattern of `app01_react`/`app04_scala_react`/`app05_go_react`. This is the fifth backend ecosystem in the course's comparison series (Java/Spring Boot ×2, Python/Django, Scala/ZIO, Go, and now Haskell), and deliberately the most different from a Java developer's mental model of any of them: no mutable state by default, no `null`, effects visible in function signatures, and a type system expressive enough to make certain bug classes **impossible to compile**, not merely "unlikely if you remember the linter rule."

**Why this matters for the course:** every prior sibling app used its language's type system or tooling to push a security property earlier in the SDLC — Django's ORM, ZIO Quill's macros, Go's `sqlc`. Haskell takes the same idea further than any of them: several of the security requirements below are enforced not by a validator function that could be forgotten, not by a lint rule that could be disabled, but by **the data types themselves being unable to represent the invalid state at all**. This plan calls out each such case explicitly (see §4 Architecture Design Decisions) so it reads as a specific, checkable engineering claim, not a slogan.

**Note on code samples:** the application still *teaches* countermeasures in five languages — Python, Java, Go, Scala, and Lua (see §10) — because that is separate, deliberately polyglot **content**, not the application's own runtime. Java, Python, Go, and Scala appear only as sample-code tabs; the application itself never depends on a JVM, a Python interpreter, or a second compiled language.

---

## 1. Project Overview

**Name:** HaskShield 2026
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

All six decks are in scope from day one of this plan (§11, §15) — the gap the `app04_scala_react` plan initially had (and had to be corrected for) is avoided here from the start.

**UI languages:** Polish (default) and English, switched instantly with no page reload; toggle persisted in `localStorage` under key `hs_locale`, mirrored server-side via `Accept-Language`.

---

## 2. Technology Stack

### Backend (100% Haskell)
| Layer | Technology | Version (2026) |
|---|---|---|
| Compiler | GHC | 9.8 (via GHCup) |
| Build tool | Cabal (+ optional Stack) | — |
| Web framework | `servant` — type-level API specification generating both the server and the OpenAPI doc from one source of truth | `servant-server` 0.20.x |
| Database access | `hasql` + `hasql-th` — statements are quasi-quoted SQL, type-checked against the live schema at **compile time** | — |
| Database | PostgreSQL 16 | — |
| Migrations | `squawk`-checked SQL migrations run via `postgres-migration` or a small custom runner | — |
| Cache / rate-limit store | native `Control.Concurrent.STM` (GHC runtime feature, not a library) for in-process rate limiting; Redis 7 (`hedis`) for cross-instance cache | — |
| Background jobs | `odd-jobs` — PostgreSQL-backed job queue for Haskell (export, YAML re-ingestion, periodic integrity re-check) | — |
| Auth | `jose` (JOSE/JWT/JWK, RS256) | — |
| Password hashing | `password` package — uses **phantom types** so a `PasswordHash Bcrypt` value and a raw `Password` value are different types; the compiler rejects code that compares or logs a hash as if it were plaintext, or vice versa | — |
| Validation | `validation` / hand-written smart constructors returning `Either ValidationError a` | — |
| HTML sanitization | `xss-sanitize` — pure-Haskell allow-list sanitizer | — |
| YAML parsing | `Data.Yaml` (`aeson`-based `FromJSON` instances) — decodes only into explicitly declared algebraic data types | — |
| Structured logging | `katip` | — |
| API docs | `servant-swagger` → OpenAPI 3 / Swagger UI, generated from the same types that define the routes | — |
| Testing | `hspec` + `QuickCheck` (property-based testing) + `hspec-wai` (HTTP-level tests against the WAI application) | TDD — see `user_stories+tests.md` |
| SAST | `hlint`, GHC `-Wall -Werror` (including `-Wincomplete-patterns`), `stan` | — |
| SCA | `osv-scanner` (Hackage/Cabal dependency advisories) + Trivy (containers) | — |

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
| Container | Docker + Docker Compose — multi-stage build: `haskell:9.8` builder → `debian:bookworm-slim` runtime (GHC's RTS is not as minimal as a Go static binary; this plan is explicit about that trade-off, see §4 D-09) |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Loki + Prometheus (`prometheus-client` Haskell bindings) |
| Secrets | Docker Secrets / GitHub Secrets / `.env` (never committed) |
| SAST | `hlint` + `stan` + `eslint-plugin-security` (frontend) |
| DAST | OWASP ZAP |
| SCA | `osv-scanner` + `npm audit` + Trivy |

---

## 3. High-Level Architecture

```
Browser (React 18 SPA, PL/EN)
        │
        │  HTTPS
        ▼
  Nginx (port 443)
   ├── /api/v1/*   ─────► Haskell `api` executable (Warp + servant, port 8080)
   │                         ├── app/Main.hs                — Warp server entrypoint
   │                         ├── src/Api/                    — servant API type + handlers
   │                         ├── src/Service/                — business logic, pure where possible
   │                         ├── src/Store/                  — hasql-th statements + pool
   │                         └── src/Integrity/               — YAML hash verification (called ONLY
   │                                                              by app/Seed.hs and the odd-jobs
   │                                                              worker, never by an Api handler —
   │                                                              enforced by module export lists, D-05)
   │
   └── /*          ─────► React SPA static build (served by Nginx directly)

`worker` executable (same Cabal package, separate binary + container)
   ├── odd-jobs consumer (Jobs.ExportCsv, Jobs.ExportPdf, Jobs.ReingestDeck, Jobs.PeriodicReverify)
   └── shares src/Service, src/Store, src/Integrity with the api executable

PostgreSQL 16   ◄── hasql pool, compile-time-checked statements (threats, cards, mitigations, users, odd-jobs' own tables)
Redis 7         ◄── cross-instance cache; STM handles single-instance rate limiting in-process
```

**Where the trust boundaries are:** `api` and `worker` are **two separately compiled executables** from the same Cabal package — a real OS-process boundary. `src/Integrity`'s hash-verification function is exported from its module's explicit export list to `app/Seed.hs` and `Jobs.PeriodicReverify` only; `src/Api/Handler/*` modules do not import `Integrity` at all, and a CI step (`grep`-based, backed by `ghc-pkg`/`cabal`'s own module dependency graph) fails the build if that import ever appears. This is the same design discipline `app03_python_django` (import-graph test), `app04_scala_react` (opaque types), and `app05_go_react` (`internal/` + `depguard`) each apply with their own language's tools.

---

## 4. Architecture Design Decisions

### D-01 — Illegal states unrepresentable: the Digital-by-Default Harms deck cannot have a severity, by construction
```haskell
data CardKind
  = TechnicalThreat Severity          -- ^ every card from the other 5 decks
  | DesignHarm                        -- ^ every card from dbd-cards-1.0-en.yaml (US-19)
```
There is no `Severity` field reachable from a `DesignHarm` value — not a `Maybe Severity` that could accidentally be filled in, not a nullable column, but a **different data constructor with no such field at all**. `getSeverity :: CardKind -> Maybe Severity` is the only way to ask, and it must return `Nothing` for `DesignHarm` by the type's shape, not by a branch someone could get wrong. This is the strongest version of the same guarantee `app05_go_react` builds with a constructor that omits the parameter and `app04_scala_react` builds with a sealed hierarchy — here it is a plain sum type, arguably Haskell's most basic feature, doing the whole job.

### D-02 — `hasql-th`: SQL checked against the real schema at compile time
Every query is written as a quasi-quoted SQL string (`[TH.resultlessStatement| ... |]`); `hasql-th` connects to a real (test) database at compile time and verifies the statement parses and its parameter/result shapes match declared Haskell types. A typo in a column name, or a parameter-count mismatch, is a **compile error**, not a test failure discovered later — the same class of guarantee `sqlc` gives `app05_go_react` and ZIO Quill gives `app04_scala_react`, achieved here via Template Haskell instead of code generation or macros.

### D-03 — Effects are visible in the type signature
A function of type `getThreat :: ThreatId -> Threat` cannot exist for a value that must come from a database — Haskell forces it to be `getThreat :: ThreatId -> IO Threat` (or `... -> ExceptT ApiError IO Threat`). This means a code reviewer can tell, from the type signature alone and without reading the body, whether a function can touch the database, the filesystem, or the network. `src/Service/Pricing.hs`-style "pure business logic" functions are given types with no `IO` at all, and QuickCheck property tests can exercise them exhaustively precisely because they cannot have hidden side effects (§ user_stories+tests.md).

### D-04 — `password`'s phantom types prevent plaintext/hash confusion
```haskell
newtype Password        = Password  Text          -- raw, user-supplied
newtype PasswordHash a  = PasswordHash Text        -- 'a' is a phantom type, e.g. Bcrypt
hashPassword :: Password -> IO (PasswordHash Bcrypt)
checkPassword :: Password -> PasswordHash Bcrypt -> Bool
```
It is a compile error to pass a `PasswordHash` where a `Password` is expected (or log one as if it were the other) — the two are structurally different types even though both wrap `Text`. This directly prevents an entire class of "accidentally logged/compared the wrong one" bugs that a Java/Scala/Go `String`-typed password field cannot catch at compile time.

### D-05 — Module export lists as the least-privilege enforcement mechanism
`src/Integrity/Verify.hs` declares `module Integrity.Verify (verify) where` — GHC will not let any other module see helper functions not in that list, and CI additionally greps the full build's module-dependency graph (`cabal build --dry-run` output) to assert `Api.Handler.*` never depends on `Integrity.Verify`. This is the same discipline `app05_go_react` gets from `internal/` + `depguard`, expressed with Haskell's own module-visibility feature plus one CI check for the intra-package case GHC's visibility rules don't cover on their own.

### D-06 — STM (Software Transactional Memory) for rate limiting — a language runtime feature, not a library
```haskell
rateLimit :: TVar TokenBucket -> STM Bool
rateLimit bucketVar = do
  bucket <- readTVar bucketVar
  case consumeToken bucket of
    Nothing -> pure False
    Just bucket' -> writeTVar bucketVar bucket' >> pure True
```
`atomically (rateLimit bucketVar)` is composable and race-free by construction — GHC's runtime, not a third-party STM reimplementation, guarantees the transaction. This is a deliberate teaching parallel to `app04_scala_react`'s ZIO STM (a library that reimplements the same idea on the JVM) and a contrast with `app05_go_react`'s Redis-Lua-script approach (atomic because Redis is single-threaded, not because Go has STM) — three different ways to get the same "no race condition in the rate limiter" property, from three different starting points.

### D-07 — `Data.Yaml`/`aeson` decode into ADTs — no arbitrary-object gadget class, same story as Go, stated the same way
`FromJSON` instances for `CardFile` are hand-written or derived, targeting a closed set of Haskell data types; there is no equivalent of a "construct any object the parser recognizes" fallback path. As with `app05_go_react`'s D-09, this plan states plainly that this removes a specific vulnerability *class* (the one `yaml.safe_load`/`SafeConstructor` exist to prevent in Python/Java) without implying the YAML *content* is trustworthy — SHA-256 integrity verification (D-05) still applies unconditionally.

### D-08 — `NonEmpty`, `Natural`, and refined newtypes instead of raw primitives
Where a list must never be empty (e.g., a `Threat` must have at least one `Mitigation` once published) the type is `NonEmpty Mitigation`, not `[Mitigation]` with a runtime check. Where a count must never be negative (rate-limit budget, retry count) the type is `Natural`, not `Int`. These choices move "must not be empty"/"must not be negative" from a runtime assertion (that could be forgotten in one of several call sites) to a type the compiler enforces at every call site simultaneously.

### D-09 — Honest trade-off: image size and cold-start
Unlike `app05_go_react`'s `scratch`-based ~30 MB static binary, a GHC-compiled executable links against its runtime system (RTS) and typically produces a larger artifact (target: ≤ 120 MB production image, still far below a JVM image with a bundled JRE). Cold-start is fast (no JIT warm-up, no class loading) but not as instant as Go's. This plan states the comparison honestly (`requirements.md` NFR-07) rather than implying Haskell gets Go's exact deployment-footprint story for free — the two languages get *different* security-relevant properties from their compilation models, and both are documented on their own terms.

### D-10 — `odd-jobs`: Postgres-backed job queue, same database as the app
Background work (export, YAML re-ingestion, periodic integrity re-check) is enqueued as rows in the same PostgreSQL database `odd-jobs` polls — no separate broker to secure for job dispatch (Redis remains in use only for cross-instance response caching, D-06 covers in-process rate limiting via STM instead). Job payloads are Haskell records with `FromJSON`/`ToJSON` instances, decoded the same safe way as the Cornucopia YAML (D-07).

### D-11 — react-i18next with plain-text-only translation values (shared pattern)
Same as `app01_react`/`app04_scala_react`/`app05_go_react`: `pl.json`/`en.json` values are plain text only. `hs_locale` in `localStorage`; `Accept-Language` set by a fetch interceptor, allowlisted to `pl`/`en` server-side.

---

## 5. Data Model

### 5.1 Core sum/enum types (`src/Domain/Types.hs`)
```haskell
data Severity = Critical | High | Medium | Low | Info
  deriving (Show, Eq, Ord)

data StrideCategory = S | T | R | I | D | E
  deriving (Show, Eq, Ord, Enum, Bounded)

data SampleType = AttackDemo | Defense
  deriving (Show, Eq)

data CodeLanguage = Python | Java | Go | Scala | Lua
  deriving (Show, Eq, Enum, Bounded)

data MitigationType = Preventive | Detective | Corrective | Compensating
  deriving (Show, Eq)

data Effort = LowEffort | MediumEffort | HighEffort
  deriving (Show, Eq)

data Effectiveness = Partial | Significant | Full
  deriving (Show, Eq)

data RelationshipType = Equivalent | Related | ParentChild | MapsTo
  deriving (Show, Eq)

-- See D-01: the crux of this project's strongest type-level security guarantee.
data CardKind = TechnicalThreat Severity | DesignHarm
  deriving (Show, Eq)
```

### 5.2 Framework
```haskell
data Framework = Framework
  { frameworkId           :: FrameworkId          -- newtype UUID
  , frameworkCode         :: Text                 -- "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS", ...
  , frameworkName          :: Text
  , frameworkVersion       :: Text
  , frameworkDescription   :: Text
  , frameworkReferenceUrl :: Text
  }
```

### 5.3 Threat
```haskell
data Threat = Threat
  { threatId            :: ThreatId
  , threatFrameworkId    :: FrameworkId
  , threatCode           :: Text                  -- "LLM01:2025", "A03:2021", "AML.T0051"
  , threatTitle          :: Text
  , threatSeverity       :: Severity
  , threatCategory        :: Text
  , threatDescription     :: Text
  , threatAttackVector    :: Text
  , threatAttackSurface   :: Text
  , threatStride          :: [StrideCategory]
  , threatTags            :: [Text]
  }
```

### 5.4 ThreatTranslation *(i18n)*
```haskell
data Locale = Pl | En deriving (Show, Eq)

data ThreatTranslation = ThreatTranslation
  { ttThreatId     :: ThreatId
  , ttLocale       :: Locale
  , ttTitle        :: Text
  , ttDescription   :: Text
  , ttAttackVector :: Text
  }
```

### 5.5 CornucopiaCard *(all six YAML decks — see D-01 for `CardKind`)*
```haskell
data CornucopiaCard = CornucopiaCard
  { cardId            :: CardId                   -- newtype Text, e.g. "VE3", "LLM4", "SCO2"
  , cardSuitCode       :: SuitCode                 -- newtype Text
  , cardSuitName        :: Text
  , cardEdition         :: Edition                 -- Webapp | Mobileapp | Companion | Eop | Mlsec | Dbd
  , cardValue           :: CardValue                -- Num2 .. Num10 | Jack | Queen | King | Ace
  , cardKind            :: CardKind                 -- D-01: TechnicalThreat Severity | DesignHarm
  , cardDescriptionEn   :: Text
  , cardDescriptionPl   :: Text
  , cardMiscNote        :: Maybe Text
  , cardSourceUrl       :: Maybe Text
  , cardOwaspRefs       :: [OwaspRef]                -- newtype Text, smart-constructed against an allowlist
  , cardMitreRefs       :: [MitreRef]
  , cardContentSha256   :: Text
  }
```

### 5.6 Mitigation
```haskell
data Mitigation = Mitigation
  { mitigationId            :: MitigationId
  , mitigationThreatId       :: Maybe ThreatId
  , mitigationCardId         :: Maybe CardId
  , mitigationTitle          :: Text
  , mitigationDescription    :: Text
  , mitigationType           :: MitigationType
  , mitigationEffort         :: Effort
  , mitigationEffectiveness  :: Effectiveness
  , mitigationCodeSamples    :: NonEmpty CodeSample  -- D-08: never empty once published
  }
```

### 5.7 CodeSample
```haskell
data CodeSample = CodeSample
  { sampleId            :: CodeSampleId
  , sampleLanguage        :: CodeLanguage
  , sampleType           :: SampleType
  , sampleTitle          :: Text
  , sampleDescription    :: Text
  , sampleCode           :: Text
  , sampleFrameworkHint  :: Text                   -- "servant + hasql-th", "Spring Boot 3.3", "Django ORM"...
  , sampleVersionNote    :: Text
  }
```

### 5.8 CrossReference
```haskell
data CrossReference = CrossReference
  { crossRefId               :: CrossReferenceId
  , crossRefSourceThreatId    :: ThreatId
  , crossRefTargetThreatId    :: ThreatId
  , crossRefRelationshipType  :: RelationshipType
  , crossRefDescription       :: Text
  }
```

### 5.9 ContentHash
```haskell
data ContentHash = ContentHash
  { hashFileName    :: Text
  , hashSha256       :: Text
  , hashVerifiedAt   :: UTCTime
  , hashIsValid      :: Bool
  , hashVerifiedBy   :: Text                        -- "haskell-integrity-service"
  }
```

---

## 6. Development Phases

*(Numbering aligned with the Agile/Scrum sprint plan in `SDLC_analysis.md`, §4.)*

### Phase 1 — Foundation (Sprints 1–2)
Covers: US-01, US-02
- [ ] `cabal init`; packages `api`, `worker` sharing a `hasshield-core` library (`src/Domain`, `src/Service`, `src/Store`, `src/Integrity`)
- [ ] `servant` API type skeleton; Warp server with `SecurityHeaders` middleware (CSP, HSTS, X-Frame-Options)
- [ ] Docker Compose: PostgreSQL 16 + Redis 7 + `api` + `worker` + Nginx
- [ ] SQL migrations for models in §5.1–5.9; `hasql-th` statements compiled against a migration-applied test DB in CI
- [ ] `app/Seed.hs` loading OWASP Web/LLM/Agentic/API, MITRE ATLAS, CompTIA SecAI+ from JSON
- [ ] `GET /api/v1/frameworks`, `GET /api/v1/threats` (paginated)
- [ ] `jose`-based JWT middleware — editor/admin roles
- [ ] `servant-swagger` → `/api/v1/docs/swagger-ui/`
- [ ] React scaffold: Vite + Shadcn/UI + Tailwind + Zustand

**Security checkpoint:** `-Wall -Werror` (including `-Wincomplete-patterns`) compiles clean; `hlint`/`stan` zero findings; `SecurityHeaders` active on every response.

### Phase 2 — Core Threat Browser (Sprints 3–4)
Covers: US-02, US-03, US-04
- [ ] `hasql-th` statements: filter threats by framework, severity, stride, category, tag, q
- [ ] `GET /api/v1/threats/:id` with nested mitigations + code samples
- [ ] React `ThreatBrowserPage`, `ThreatDetailPage` (tabs: Overview | Attack Vectors | Mitigations | Code | Cross-References)
- [ ] `GET /api/v1/cross-references`
- [ ] React `MatrixPage`

**Security checkpoint:** every `hasql-th` statement compiles only if it type-checks against the live schema (D-02); no `Text`-concatenated SQL exists anywhere in the codebase (there is no code path capable of building one without going through `hasql-th`).

### Phase 3 — Card Decks & Content Integrity (Sprints 5–7)
Covers: US-05–US-12, US-19
- [ ] `src/Cards/Loader.hs` — `Data.Yaml.decodeFileEither` into `CardFile` ADTs for **all six** `docs/OWASP_stories/*.yaml` files
- [ ] `src/Integrity/Verify.hs` — SHA-256 vs `data/hashes.json`; exported only to `app/Seed.hs` and `Jobs.PeriodicReverify` (D-05)
- [ ] Card suit browsers: FRE, LLM, AAI, CLD (Companion), SP/TA/RE/ID/DS/EP (STRIDE), EMR/EIR/EOR/EDR (MLSec), PC/AA/NS/RS/CRM/CM (Mobile), VE/AT/SM/AZ/CR/C (Website App), **SCO/ARC/AGE/TRU/POR (Digital-by-Default Harms, US-19 — in scope here, not bolted on later)**
- [ ] `CardKind` (D-01) enforced by the type itself: no JSON/DB round-trip path can produce a `DesignHarm` value carrying a severity
- [ ] `AttackDemoWarning` confirmation modal before rendering `AttackDemo` code samples

**Security checkpoint:** malformed/unknown-field YAML fails `FromJSON` parsing (QuickCheck property test generates random extra fields and asserts decode failure); content hash mismatch aborts ingestion inside a single DB transaction.

### Phase 4 — Code Samples: 5 Languages (Sprints 7–9)
Covers: US-13–US-16
- [ ] Code sample seed data for every mitigation × 5 languages (Python, Java, Go, Scala, Lua)
- [ ] Attack-demo / defense sub-tabs, red-bordered warning label
- [ ] MITRE ATLAS Kill-Chain timeline (Recharts)

### Phase 5 — i18n Polish ↔ English (Sprint 9–10)
Covers: US-11 (folded into every story's acceptance criteria, see §15 note)
- [ ] `Accept-Language` middleware — allowlist `pl`/`en`, default `en` server-side (SR-12.1 rationale)
- [ ] `ThreatTranslation` served per-locale; `cardDescriptionPl` fallback to English with an "EN" badge if missing
- [ ] React `react-i18next`; `LanguageToggle`; `hs_locale` in `localStorage`
- [ ] Code samples **never** translated
- [ ] CI check: i18n key-parity test fails the build on any missing key

### Phase 6 — Search, Export, Matrix Completion (Sprints 10–12)
Covers: US-17, US-18
- [ ] PostgreSQL full-text search (`tsvector` + GIN index)
- [ ] `odd-jobs`-based export (`Jobs.ExportCsv`, `Jobs.ExportPdf`)
- [ ] `/matrix/llm`, `/matrix/agentic`, `/matrix/mobile-vs-web`, `/stride-heatmap`, `/matrix/digital-harms`
- [ ] STM-based rate limiting (D-06): 60 req/min/IP on all public list endpoints (single-instance; Redis-backed counter added if horizontally scaled)

### Phase 7 — Hardening, Testing & Release (Sprints 12–14)
Covers: full regression across US-01–US-19
- [ ] `hspec` + `QuickCheck` suite, coverage ≥ 85% on `src/Service` (via `hpc`)
- [ ] `hspec-wai` integration tests for every handler
- [ ] Playwright (TypeScript) E2E — one scenario per user story
- [ ] `hlint` + `stan` + `osv-scanner` in CI, zero HIGH findings
- [ ] OWASP ZAP full active scan against staging
- [ ] Production images: `api`/`worker` multi-stage Docker build, `debian-slim` runtime, ≤ 120 MB (D-09)

---

## 7. API Endpoint Map

### Framework & Threat (base)
```
GET  /api/v1/frameworks
GET  /api/v1/frameworks/:code
GET  /api/v1/threats?framework=&severity=&stride=&category=&tag=&q=
GET  /api/v1/threats/:id
GET  /api/v1/threats/:id/mitigations
GET  /api/v1/threats/:id/code-samples?language=Haskell   (n.b. "Haskell" is not a sample language — see C-02; the query accepts only PYTHON|JAVA|GO|SCALA|LUA)
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
GET  /api/v1/export?format=csv&framework=OWASP_LLM     (enqueues odd-jobs Job, returns 202 + poll URL)
GET  /api/v1/export/status/:jobId
```

### Admin CRUD (JWT — Admin role)
```
POST   /api/v1/admin/threats
PUT    /api/v1/admin/threats/:id           — xss-sanitize applied
DELETE /api/v1/admin/threats/:id
POST   /api/v1/admin/code-samples
PUT    /api/v1/admin/code-samples/:id
```
`CornucopiaCard` rows (all six decks) have **no** admin write endpoint at all. They are read-only, written only by `app/Seed.hs`/the `ReingestDeck` job — servant's API type simply has no route for it, so it is not just unenforced-by-convention, it does not typecheck for a client to even construct such a request against this server's type.

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
  DesignHarmBadge (US-19 — cannot even receive a severity prop; its TypeScript type has none),
  BotWarningModal (US-11), StrideHeatmap, MatrixTable, LanguageToggle
```

---

## 9. Haskell Backend Package Layout

```
backend/
├── hasshield.cabal                    ← defines library `hasshield-core` + executables `api`, `worker`
├── cabal.project
├── app/
│   ├── Main.hs                        ← `api` executable entrypoint (Warp + servant)
│   ├── Worker.hs                      ← `worker` executable entrypoint (odd-jobs consumer)
│   └── Seed.hs                        ← one-shot seeding + initial card ingestion
├── src/
│   ├── Domain/
│   │   ├── Types.hs                   ← Section 5 ADTs, zero IO
│   │   └── Newtypes.hs                ← ThreatId, CardId, OwaspRef, MitreRef, etc.
│   ├── Api/
│   │   ├── Spec.hs                    ← the servant API type (single source of truth)
│   │   ├── Server.hs                  ← handler wiring
│   │   └── Handler/
│   │       ├── Framework.hs
│   │       ├── Threat.hs
│   │       ├── Card.hs
│   │       ├── Matrix.hs
│   │       ├── Search.hs
│   │       ├── Export.hs
│   │       └── Admin.hs
│   ├── Middleware/
│   │   ├── Auth.hs                    ← jose JWT verification
│   │   ├── RateLimit.hs               ← STM token bucket (D-06)
│   │   ├── SecurityHeaders.hs
│   │   └── Cors.hs
│   ├── Service/                       ← business logic; many functions have NO IO in their type (D-03)
│   ├── Store/
│   │   ├── Statements/*.hs            ← hasql-th quasi-quoted SQL
│   │   └── Pool.hs
│   ├── Cards/
│   │   └── Loader.hs                  ← YAML → CornucopiaCard, calls Integrity.verify
│   ├── Integrity/
│   │   └── Verify.hs                  ← module Integrity.Verify (verify) where — D-05
│   └── Jobs/
│       ├── ExportCsv.hs
│       ├── ExportPdf.hs
│       ├── ReingestDeck.hs
│       └── PeriodicReverify.hs
├── test/
│   ├── Spec.hs                        ← hspec discovery root
│   ├── Service/*Spec.hs               ← hspec + QuickCheck properties
│   └── Api/*Spec.hs                   ← hspec-wai
└── migrations/                        ← forward-only SQL

frontend/                              ← React 18 + TS + Vite (mirrors app05_go_react §8)

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

Every `Mitigation` ships exactly **five** `CodeSample` values, enforced at the type level by `mitigationCodeSamples :: NonEmpty CodeSample` (D-08) — a `Mitigation` with zero samples cannot be constructed at all, and seed-data completeness (all five languages present) is additionally checked by a QuickCheck property over the seeded dataset, not just eyeballed.

| Language | Primary framework/library used in samples |
|---|---|
| Python | Django ORM / FastAPI + Pydantic |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | `chi` + `sqlc` + `pgx` |
| Scala | Akka HTTP / http4s, Slick 3.x, ZIO 2 |
| Lua | OpenResty / NGINX Lua, `lua-resty-jwt`, LuaSQL |

```
sampleType: AttackDemo   -- VULNERABLE — do not use in production
sampleType: Defense      -- SECURE pattern, with a one-line WHY comment
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
| CompTIA Security+ / SecAI+ | ≥ 20 topics | seeded JSON, from `docs/Security Architects...md` mapping table |
| OWASP A04:2021 Insecure Design — Digital-by-Default Harms | Scope/Architecture/Agency/Trust/Porosity | `SCO/ARC/AGE/TRU/POR` suits (US-19) — **not** a technical-vulnerability deck, see D-01 |

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
2. CI job `yaml-content-integrity`: `Data.Yaml.decodeFileEither` must succeed against the `CardFile` ADT (any unrecognized shape is a parse failure, not partial data) + injection-pattern grep + ref-allowlist validation.
3. Post-merge: a `hash-generator` CI step updates `data/hashes.json`.
4. `app/Seed.hs` and the `ReingestDeck` job both call `Integrity.Verify.verify` — on mismatch, ingestion aborts inside a single DB transaction (no partial writes) and a `SEC-CARD-HASH-MISMATCH` structured log line fires via `katip`, which Loki alerts on.

---

## 13. Risk Register

| Risk | Mitigation |
|---|---|
| `hasql-th` compile-time DB check slows CI / requires a live DB at build time | A dedicated `schema-check` CI service container; local dev uses the same Docker Compose Postgres |
| YAML card files tampered in a PR | CODEOWNERS review + `Integrity.Verify` SHA-256 check, fail-secure |
| Digital-by-Default Harms deck misread as CVE severity | `CardKind` sum type (D-01) — structurally cannot happen, not just discouraged |
| Polish translations drift from English source | `cardContentSha256` stored per card; translation table flags staleness on English-text change |
| `Integrity.Verify` called from an unintended module | Module export list (D-05) + CI module-dependency-graph grep |
| `odd-jobs` payload injection | Job `Args` are `FromJSON`-decoded Haskell records, validated the same way as Cornucopia YAML — never a raw `Value` interpreted at execution time |
| GHC production image larger than the Go sibling's | Documented honestly (D-09); multi-stage build still keeps it far below a JVM-based image |
| STM rate limiter is per-instance only | Documented limitation; horizontal scaling adds a Redis-backed counter as a second layer, not a silent gap |
| Attack-demo code confused with production-safe code | Red border + `AttackDemo` badge + confirmation modal before code is shown/copied |
| Bot scraping the full catalogue | STM/Redis rate limit 60 req/min/IP (D-06) |

---

## 14. Directory Layout

```
app06_HASKELL_react/
├── PLAN.md
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
├── backend/            ← see §9 for full internal layout
├── frontend/            ← React 18 + TS + Vite (mirrors app05_go_react structure)
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
| US-14 | Java developer | see a Java code sample for each mitigation | compare against a statically-typed alternative's idioms |
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
| M3 | All six card decks ingested | `Integrity.Verify` reports `hashIsValid=True` for all six YAML files, including `dbd-cards-1.0-en.yaml` |
| M4 | Code samples complete | Every mitigation has 5 language samples visible on Threat Detail |
| M5 | Matrix + heatmap | Cross-reference table renders; STRIDE heatmap shows coverage % |
| M6 | i18n complete | PL/EN toggle everywhere; i18n key-parity CI check passes |
| M7 | Search + export work | Full-text search returns highlighted results; CSV/PDF export completes via `odd-jobs` |
| M8 | Digital-by-Default Harms | `DigitalHarmsPage` renders all 5 suits with `DesignHarmBadge`; A04:2021 cross-reference visible; the API's response type has no `severity` field for these cards at all (not merely `null`) |
| M9 | Security hardening | `hlint`/`stan`/`osv-scanner` zero HIGH; ZAP full scan zero HIGH |
| M10 | Tests green | ≥ 90% of TDD test list in `user_stories+tests.md` passing in CI |
