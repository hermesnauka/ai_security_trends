# RubyGuard 2026 — Application Development Plan

**Version:** 1.0
**Date:** 2026-07-11
**Status:** Living document — updated after each sprint planning session
**Directory:** `app13_ruby_FastApi`
**Sibling projects:** `app01_react`/`app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django),
`app04_scala_react` (Scala/ZIO), `app05_go_react` (Go), `app06_HASKELL_react` (Haskell), `app07_rust_react` (Rust),
`app08_cpp_react` (C++), `app09_php_WORDPRESS` (PHP/WordPress), `app10_csharp_react` (C#/.NET),
`app11_swift_ios` (Swift/iOS, offline), `app12_kotlin_android` (Kotlin/Android, offline)

> **Correction note (2026-07-11):** the four planning docs previously in this directory
> (`PLAN.md`, `requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md`, `CLAUDE.md`)
> were an accidental byte-for-byte duplicate of `app12_kotlin_android`'s KotlinGuard
> content — wrong stack, wrong directory, wrong everything. All five files are rewritten
> from scratch here for this app's actual stack.

---

## 0. Note on the Stack — a Ruby Backend, FastAPI in Spirit

This application's backend is written entirely in **Ruby**, using **Grape** — a
declarative, DSL-based REST API framework for Rack — deliberately chosen (over the
simpler, more minimal Sinatra) because it is the closest real Ruby analogue to Python's
**FastAPI**, the framework hinted at by this directory's name:

- **Declarative parameter validation.** FastAPI validates request bodies/query params
  against Pydantic models with type hints; Grape's `params do requires :severity, type:
  String, values: %w[critical high medium low info] end` block plays the exact same role
  — invalid input is rejected before a single line of endpoint logic runs, with an
  auto-generated 400 error, not a hand-rolled `if params[:severity].nil?` check.
- **Automatic OpenAPI/Swagger documentation.** FastAPI's signature "you get `/docs` for
  free" feature is provided here by `grape-swagger`, which introspects the same `params`
  blocks used for validation and generates a live OpenAPI 3.0 document — the same
  single-source-of-truth relationship between validation and documentation FastAPI is
  known for, not two things a developer must keep in sync by hand.
- **What genuinely does NOT carry over: async/await.** FastAPI's other defining feature is
  native `async def` endpoints on an ASGI server (Uvicorn). Ruby has no equivalent
  language-level async/await in mainstream use for this kind of app; this project uses
  Rack's conventional synchronous request model, served by **Puma** with its
  multi-process/multi-thread worker pool — Ruby's actual, idiomatic answer to concurrency,
  not a simulated async layer bolted on to look like FastAPI. This is stated explicitly
  here rather than glossed over: **do not** claim this app is "as async as FastAPI" —
  it isn't, and doesn't need to be for this workload (see §13 risk register).
- **Unlike `app11_swift_ios`/`app12_kotlin_android`, this app has a real client-server
  model** and follows the shared Phase-1 API contract `../CLAUDE.md` documents, the same
  way `app02`, `app03`, `app05`, `app07`, `app08`, `app10` do — this app's own
  `/api/v1/...` routes are supposed to match what `app01_react`'s Spring Boot backend
  *actually implements*, not reinvent a shape. See §7 for the exact route table and where,
  if anywhere, this plan states an intentional deviation (there is exactly one, matching
  `app05_go_react`'s precedent of stating deviations explicitly rather than silently).

**Note on code samples:** the application still *teaches* countermeasures in five
languages — Python, Java, Go, Scala, and Lua (§10) — because that is separate,
deliberately polyglot **content**, not the application's own runtime. Ruby is not one of
the five sample languages, the same "sample language ≠ implementation language" rule every
sibling in this series follows (e.g. Kotlin is the app12 implementation language and is
also not one of the five).

---

## 0.1 Source Material — What Actually Exists vs. What's Curated

Per this series' now-standard provenance section (first introduced for `app09_php_WORDPRESS`,
carried forward by every sibling since): `docs/Security Architects+ Comptia+OWASP LLM
top10__v01b.md` covers, in detail: the **OWASP Top 10 for LLM Applications (2025/2026)**,
the **OWASP Top 10 (Web Application, 2021)**, **MITRE ATLAS™** (with real technique IDs,
e.g. `AML.T0051`), and **CompTIA Security+ SY0-701 / SecAI+ 2026** exam-objective topics
(GRC, NIS2/UKSC references, AI-as-target / AI-as-weapon / AI-as-defense framing). It does
**NOT** cover OWASP Agentic AI Top 10, OWASP API Security Top 10, OWASP Client-Side Top 10,
OWASP CI/CD Security Top 10, OASIS/OAT (Automated Threats), or OWASP MASVS in any
comparable depth — those framework rows exist in this app's catalogue with no seeded
threats, exactly like every sibling.

The six raw YAML decks under `docs/OWASP_stories/` (`webapp-cards-3.0-en.yaml`,
`mobileapp-cards-1.1-en.yaml`, `__LLM_AI___companion-cards-1.0-en.yaml`,
`STRIDE__eop-cards-5.0-en.yaml`, `RISKS__elevation-of-mlsec-cards-1.0-en.yaml`,
`dbd-cards-1.0-en.yaml`) contain **only** `id`/`value`/`url`/`desc`/`misc` fields per card —
**no** `severity`, no `card_kind`, no OWASP/MITRE cross-reference field exists in any raw
source file. Every severity, design-harm/technical-threat classification, and
OWASP/MITRE reference shown anywhere in this app is **curated content this team authors**,
merged in at ingestion time — never a value extracted from the YAML. This is the same
D-06-adjacent distinction every sibling since app09 states explicitly, because it is easy
to forget while writing ingestion code and assume the YAML "must" carry a severity field
somewhere.

---

## 1. Project Overview

**Name:** RubyGuard 2026
**Purpose:** A bilingual (Polish/English) reference and learning web application mapping
security threats, vulnerabilities and mitigations across **OWASP** (Web Top 10, LLM Top
10, Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10,
Automated Threats/OAT, MASVS), **MITRE ATLAS**, and **CompTIA Security+ SY0-701 / SecAI+
2026**, plus the full catalogue of **OWASP Cornucopia-family card decks** found in
`docs/OWASP_stories/*.yaml`. Each threat is presented with working countermeasure code in
**five languages**: Python, Java, Go, Scala, and Lua.

**UI languages:** Polish (default) and English, switched instantly with no page reload, via
a `LanguageToggle` component backed by a small client-side i18n store (§4 D-05) — not a
server round-trip per toggle.

---

## 2. Technology Stack

### Backend
| Layer | Technology | Version (2026) |
|---|---|---|
| Language | Ruby | 3.4 |
| API framework | **Grape** (Rack-based, declarative REST DSL) | 2.x |
| App server | **Puma** (multi-process + thread pool) | 6.x |
| ORM | **Sequel** (chosen over ActiveRecord — usable standalone without pulling in all of Rails; its `Sequel::Model` dataset API is a closer stylistic match to Grape's own minimalism) | 5.x |
| Database | **PostgreSQL** — the same shared, Docker-less local instance every backend sibling on this machine uses (`../CLAUDE.md` "Local dev environment"); this app owns its own `rubyguard` role/DB | 16 |
| Migrations | `Sequel::Migration` (plain Ruby migration files, `db/migrations/`) | — |
| Auth | **JWT, HS256**, shared `JWT_SECRET` — matches `app01_react`'s actual contract exactly (`ruby-jwt` gem); no key pair, no RS256 (that is `app05_go_react`'s one stated, intentional exception, not a pattern to copy) | — |
| Validation/docs | Grape `params` blocks + `grape-swagger` (auto-generated OpenAPI 3.0 at `/api/v1/swagger_doc`) — the FastAPI-equivalent pairing (§0) | — |
| Serialization | `Grape::Entity` for response shaping (explicit allow-listed fields per entity — never `to_json` on a raw Sequel model row, which would leak every column) | — |
| Password hashing | `bcrypt` (the one hardcoded admin credential, §4 D-01, is still bcrypt-hashed at rest, never compared in plaintext) | — |
| Rate limiting | `rack-attack` (per-IP throttling on `/api/v1/auth/login` — brute-force mitigation, SR-05-equivalent) | — |
| Testing | **RSpec** (unit + request specs, TDD — see `user_stories+tests.md`) + **`rantly`** (Ruby's closest property-based-testing library to QuickCheck/SwiftCheck/Kotest-property — used for the "every mitigation has all 5 languages" completeness property, §10) | — |
| SAST | **Brakeman** (Ruby/Rack-aware static analyzer — SQL injection, mass assignment, command injection checks) | — |
| SCA | **`bundler-audit`** (checks `Gemfile.lock` against the Ruby Advisory Database) | — |
| Lint/style | **RuboCop** (with `rubocop-performance` and a security-leaning custom cop set) | — |

### Frontend
| Layer | Technology | Version (2026) |
|---|---|---|
| Language | **Vanilla JavaScript (ES2022 modules), no framework** — a deliberate choice, not an oversight (see below) | — |
| Markup/styling | Plain HTML5 + CSS (custom properties for theming, no preprocessor) | — |
| HTTP | native `fetch` | — |
| i18n | a small hand-written `i18n.js` store (PL/EN string tables + `data-i18n` attribute binding), not a library — this app's own D-05 | — |
| Build | **esbuild** (bundling + minification only — no framework compiler step needed since there is no framework) | — |
| Testing | **Playwright** (this series' standard E2E tool for every browser-based frontend) + `vitest` for the handful of pure-JS unit-testable modules (`i18n.js`, API client wrappers) | — |

**Why no frontend framework, unlike every other backend+SPA sibling (app01/02/05/07/08/10
all pair with React or Angular):** this is a deliberate differentiator for the course
comparison, not an oversight or a cost-cutting shortcut. Given the backend's own guiding
principle is minimalism (Grape over Rails, Sequel over ActiveRecord), a framework-free
frontend keeps that principle consistent end-to-end, and gives this course's comparison
matrix a genuine "zero-framework, zero-build-step-for-logic" data point it currently
lacks. This is a real, load-bearing decision documented here so nobody "fixes" it into
React later without noticing it was intentional (§4 D-08).

### Infrastructure (shared conventions, see `../CLAUDE.md`)
| Component | Technology |
|---|---|
| Local dev (no Docker) | `scripts/local-dev-up.sh`/`local-dev-down.sh`, portable Ruby toolchain, ensures the `rubyguard` Postgres role/DB exists on the shared local instance |
| Containerized dev/CI | `docker-compose.yml` (Ruby/Puma + Postgres 16 + Nginx reverse proxy in front of Puma) |
| CI | GitHub Actions — RSpec, Brakeman, `bundler-audit`, RuboCop, Playwright |
| Reverse proxy (containerized) | Nginx — serves the built frontend `dist/` as static files and proxies `/api/*` to Puma |

---

## 3. Architecture

```
Browser (vanilla JS SPA-ish frontend, client-side routing via History API)
   │  fetch() + JWT bearer token (localStorage)
   ▼
Nginx (containerized only) ──proxy /api/*──▶ Puma ──▶ Grape API (Ruby)
                                                          │
                                                          ▼
                                                    Sequel ORM
                                                          │
                                                          ▼
                                                    PostgreSQL (`rubyguard` DB)
```

No message queue, no background job runner, no cache layer — the seeded dataset (20
threats, ~40 curated cards, 5 mitigations) is small enough that a plain indexed Postgres
query answers every list/filter/search endpoint well within budget (SR-08-equivalent: p95
< 200ms for any single endpoint against the seeded dataset). CSV export (§6 Phase 6) is
generated synchronously in-request for the same reason — no async job/polling endpoint is
needed at this data volume, a deliberate, stated simplification versus `app09_php_WORDPRESS`'s
WP-Cron-based async export (that app's larger, WordPress-hosting-constrained environment
justified async there; this one's data volume does not require it here).

---

## 4. Key Design Decisions

- **D-01 — Auth:** one hardcoded admin user (`admin`/bcrypt-hashed password from an env
  var, never committed), JWT HS256 on successful login, `Authorization: Bearer <token>` on
  every subsequent request. Matches `app01_react`'s actual `JwtService` shape — no OAuth,
  no user registration, no roles beyond `ADMIN` (Phase-1 parity, not the 19-user-story
  aspirational RBAC vision `requirements.md` §2 also documents).
- **D-02 — Grape `params` blocks are this app's compile-time-adjacent guarantee.** Unlike
  `app05_go_react`'s `sqlc`/`app07_rust_react`'s `sqlx::query!` (genuine compile-time SQL
  verification) or `app12_kotlin_android`'s Room `@Query` (KSP-verified at build time),
  Ruby has no compile step at all — Grape's `params` validation is a **runtime** guarantee,
  checked on every request, not a build-time one. This is stated precisely rather than
  oversold: Ruby sits at the dynamically-typed end of this series' compile-time-guarantee
  spectrum, the same tier as `app03_python_django`'s Django REST Framework serializers.
- **D-03 — `card_kind` (technical-threat-vs-design-harm) has no sum-type enforcement in
  Ruby the way Swift's `enum`/Kotlin's `sealed interface`/Rust's `enum`/Haskell's ADT give
  every other sibling.** This app models it as a `card_kind` string column with a
  **Postgres `CHECK` constraint** (`card_kind IN ('technical_threat', 'design_harm')`)
  plus an application-level second `CHECK` mirroring `app09_php_WORDPRESS`'s D-04 rule: a
  `design_harm` row's `severity` column MUST be `NULL` (`(card_kind = 'design_harm' AND
  severity IS NULL) OR (card_kind = 'technical_threat' AND severity IS NOT NULL)`) —
  runtime-enforced by the database itself, not the strongest tier in this series (that's
  Rust/Haskell/Swift/Kotlin's compiler-enforced sum types) but a real, DB-enforced
  guarantee stronger than "just don't do that in application code."
- **D-04 — SQL safety is runtime-only, like every dynamically-typed sibling
  (app03/app09).** Sequel's parameterized dataset API (`where(code: params[:code])`, never
  string interpolation into raw SQL) is the actual guarantee; RuboCop's
  `Sequel/*` cops (where available) and Brakeman's SQL-injection checks are the closest
  static-analysis substitute for what a type system would otherwise catch.
- **D-05 — i18n is a hand-written client-side store, not a library**, because the surface
  area (two locales, a few dozen UI strings, plus per-threat `description_pl`/`description_en`
  content columns) doesn't justify pulling in `i18next` or similar. `LanguageToggle`
  writes the chosen locale to `localStorage` and re-renders the current view — no page
  reload, no server round-trip. Threat/card **content** i18n (description text) is a
  `description_en`/`description_pl` column pair on the relevant tables, with an English
  fallback when no Polish translation row/value exists yet (FR-18.6-equivalent), the same
  pattern every sibling uses.
- **D-06 — every Cornucopia YAML deck is decoded with an explicit allow-listed-keys
  check**, the same D-06 guarantee every sibling in this series states: Ruby's `Psych`
  (YAML) and `JSON.parse` are both lenient by default (unknown keys silently ignored, the
  same end of the spectrum as Swift's `Codable` and PHP's default JSON decoding) — this
  app's `CardFileLoader` hand-checks `raw.keys - ALLOWED_KEYS` and raises
  `CardDecodeError::UnrecognizedFields` if non-empty, rather than relying on a strict
  decoder default the way Kotlin's kotlinx.serialization or C#'s `YamlDotNet`
  (`app10_csharp_react`) provide "for free."
- **D-07 — no CSRF token scheme is needed.** This is a stateless JWT-bearer-token API
  (no cookies, no server-side session) consumed by a same-origin frontend — CSRF is a
  cookie-based-session attack class this architecture doesn't have the surface for, the
  same reasoning every JWT-bearer sibling in this series states.
- **D-08 — the framework-free frontend (§2) is deliberate**, not a shortcut — see the
  rationale there. `AboutView`'s copy states this explicitly to a curious code reader, the
  same way `app09_php_WORDPRESS`'s README states its WordPress-vs-SPA choice.
- **D-09 — code samples are read-only, bundled, never executed** (matches every sibling's
  attack-demo-gate pattern, §10): an attack-demo sample requires an explicit
  confirm-to-reveal interaction in the frontend before its code is rendered, the same UX
  gate `app09`'s `<details>`-based reveal, `app11`'s `.confirmationDialog`, and `app12`'s
  `AlertDialog` all implement.

---

## 5. Data Model (PostgreSQL, via Sequel migrations)

```
frameworks         (code PK, name, version, description, reference_url)
threats            (code PK, framework_code FK, title, severity, category,
                     description_en, description_pl, attack_vector, attack_surface,
                     stride text[], tags text[])
cards              (card_id PK, suit_code, suit_name, edition, value, card_kind,
                     severity NULL-able (CHECK, D-03), description_en, description_pl,
                     misc_note NULL-able, source_url NULL-able,
                     owasp_refs text[], mitre_refs text[], content_sha256, is_critical bool)
mitigations        (slug PK, threat_code FK NULL-able, card_id FK NULL-able, title,
                     description, mitigation_type, effort, effectiveness)
code_samples       (id PK serial, mitigation_slug FK, language, sample_type, title,
                     description, code text, framework_hint, version_note)
cross_references   (id PK serial, source_threat_code FK, target_threat_code,
                     target_threat_title, relationship_type, description)
content_hashes     (file_name PK, sha256_hash, verified_at, is_valid, verified_by)
users              (id PK, username unique, password_digest, role) — exactly one seeded row
```

`CHECK` constraints (D-03) and foreign keys are added via explicit `alter_table` migration
steps, mirroring `app09_php_WORDPRESS`'s reasoning: Sequel's plain-Ruby migration DSL
handles `CHECK`/`FOREIGN KEY` natively and correctly (unlike WordPress's `dbDelta()`), so
this is simpler here than it was for app09 — no separate parser-limitation workaround
needed, just ordinary Sequel migration syntax.

---

## 6. Phased Build Plan

1. **Foundation** — Gemfile, Grape/Puma/Sequel wiring, Postgres migrations, JWT auth
   (`POST /api/v1/auth/login`), `frameworks`/`threats` endpoints, seed loader for
   `frameworks.json`/`threats_seed.json`.
2. **Card ingestion** — `CardFileLoader` (YAML decode + allow-listed-keys check, D-06),
   curation JSON merge (severity/refs), `ReferenceValidator` (OWASP/MITRE allowlist check),
   SHA-256 integrity check against `hashes.json`, seed all 6 decks.
3. **Mitigations + code samples** — 5 real mitigations, each with a real attack-demo +
   defense sample in all 5 languages (content reused verbatim from `app09`/`app11`/`app12`
   — language-agnostic educational content, not re-authored).
4. **i18n** — `description_en`/`description_pl` columns populated, `LanguageToggle` +
   `i18n.js` store, Polish default.
5. **Search/export/matrix** — Postgres `ILIKE`-based search (no full-text index yet, same
   honest-scope-gap pattern as every sibling's plain-CONTAINS search), synchronous CSV
   export, LLM↔MITRE-ATLAS matrix endpoint, STRIDE heatmap endpoint.
6. **Hardening/testing** — Brakeman, `bundler-audit`, RuboCop, full RSpec suite (unit +
   request specs), `rantly` property tests, Playwright E2E suite.

---

## 7. API Contract (matches `../CLAUDE.md`'s canonical Phase-1 contract)

```
POST /api/v1/auth/login        {username, password} -> {token, tokenType:"Bearer", role:"ADMIN"} | 401
GET  /api/v1/frameworks        -> Framework[]
GET  /api/v1/frameworks/:code  -> Framework | 404
GET  /api/v1/threats           ?frameworkCode&severity&stride&tag&q&page&size&sort -> Page<ThreatSummary>
GET  /api/v1/threats/:id       -> ThreatDetail | 404
GET  /health                   -> {"status":"UP"}
```

`Page<T> = {content, totalElements, totalPages, number, size}` — mirrors Spring Data's
envelope shape exactly, computed by hand in this Grape API (Ruby has no equivalent
framework-native paging envelope the way Spring Data provides one), so the response body
shape matches `app01_react` even though nothing generates it automatically here. Error
body on 4xx: `{timestamp, status, error, message}`, also hand-built to match.

**One intentional addition beyond the shared contract, not a deviation from it:**
`GET /api/v1/cards`, `GET /api/v1/cards/:cardId`, `GET /api/v1/mitigations/:threatCode`,
`GET /api/v1/matrix/llm`, `GET /api/v1/matrix/stride-heatmap`, `GET /api/v1/search?q=`,
`GET /api/v1/export.csv` — these exist because the shared Phase-1 contract only covers
`app01_react`'s original threat/framework scope, and every sibling that also carries the
Cornucopia-card/mitigation/matrix content (app03, app09, app11, app12, and now this one)
adds its own equivalent routes for that content, none of which app01 has reason to define.

---

## 8. Frontend Views

```
IndexView          → framework tiles (US-01)
ThreatBrowserView   → filterable list (US-02)
ThreatDetailView    → overview / attack vectors / mitigations / code samples / cross-refs (US-03)
CardSuitView        → generic, parameterized by suit or edition (US-05–US-12)
DigitalHarmsView    → dedicated — must never render a severity badge (US-19, D-03)
MatrixView          → LLM↔MITRE-ATLAS, STRIDE heatmap (US-04, US-08)
SearchView          → free-text search across threats + cards (US-17)
LoginView           → the one hardcoded admin account
AboutView           → states the framework-free-frontend decision (D-08) explicitly
```

---

## 9. Repository/Directory Layout

```
app13_ruby_FastApi/
├── backend/
│   ├── Gemfile / Gemfile.lock
│   ├── config.ru                       ← Rack entry point
│   ├── app/
│   │   ├── api/                        ← Grape::API classes, one per resource
│   │   ├── entities/                   ← Grape::Entity response shapers
│   │   ├── models/                     ← Sequel::Model classes
│   │   └── services/                   ← CardFileLoader, ReferenceValidator, ContentSeeder, IntegrityChecker, JwtService
│   ├── config/
│   │   ├── environment.rb              ← Rack::Attack rate-limit config (SR-05), DB/Sequel setup
│   │   └── puma.rb
│   ├── db/
│   │   ├── migrations/
│   │   └── seeds/                      ← frameworks.json, threats_seed.json, cornucopia/*.yaml, code_samples/{python,java,go,scala,lua}/
│   └── spec/                           ← RSpec unit + request specs, rantly properties
├── frontend/
│   ├── src/
│   │   ├── views/
│   │   ├── i18n.js
│   │   ├── api-client.js
│   │   └── main.js
│   ├── index.html
│   └── e2e/                            ← Playwright specs
├── docker-compose.yml
├── PLAN.md / requirements.md / SDLC_analysis.md / user_stories+tests.md / CLAUDE.md
```

---

## 10. Code Sample Strategy

Every `Mitigation` ships exactly **five** `CodeSample` records (one attack-demo + one
defense per language would be ten total per mitigation; PLAN.md's own scope is 5
mitigations × 5 languages × 2 sample types = 50 samples total, verbatim-reused content
from `app09`/`app11`/`app12`). Completeness (every mitigation has all 5 languages, both
sample types) is verified by an `rantly`-based property test over the seeded dataset, not
a type-level guarantee — Ruby has no `NonEmpty`/exhaustive-coverage collection type.

---

## 11. Threat Model Summary

This app's own attack surface: a public read-heavy REST API plus one authenticated
admin-only write surface (not yet built beyond login, Phase-1 parity). Primary risks:
SQL injection (mitigated by D-04, Sequel's parameterized API), brute-force login
(mitigated by `rack-attack`), JWT secret leakage (env-var only, never committed, rotated
independently per environment), and dependency vulnerabilities (mitigated by
`bundler-audit` in CI). No file upload surface exists in Phase-1 scope, eliminating an
entire attack class other siblings' export/import features must consider.

---

## 12. CI/CD Pipeline

GitHub Actions: `bundle exec rspec` → `brakeman` → `bundler-audit check` → `rubocop` →
Playwright E2E (against a docker-compose-launched stack) → build frontend `dist/` via
`esbuild` → (manual approval gate) → staging → production, the same staged rollout shape
`SDLC_analysis.md` §5 describes in full.

---

## 13. Risk Register

| Risk | Mitigation |
|---|---|
| Ruby's dynamic typing means a typo'd column name fails at request time, not build time | RSpec request-spec coverage on every endpoint; Sequel raises a clear `Sequel::DatabaseError` rather than silently returning wrong data |
| Puma's synchronous worker model could bottleneck under genuinely async-shaped load (many slow concurrent I/O-bound requests) | Not a real risk at this app's seeded data volume/expected traffic (a course reference app, not a production service) — stated here so it isn't silently assumed to not exist |
| `grape-swagger`'s generated OpenAPI doc could drift from actual behavior if a `params` block is bypassed | Brakeman + RSpec request specs catch behavioral drift; `params` blocks are the only validation path used anywhere in this codebase, by convention enforced in code review |
| Framework-free frontend risks becoming an unmaintainable pile of DOM manipulation as views grow | Views are single-responsibility ES modules with one `render(state)` function each — a deliberately small, consistent internal convention, not "no structure at all" |
