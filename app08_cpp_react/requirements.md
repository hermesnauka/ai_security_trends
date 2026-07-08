# CppCitadel 2026 — Requirements Specification

**Version:** 1.0
**Date:** 2026-07-07
**Project:** `app08_cpp_react`
**Sources:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`, `docs/OWASP_stories/*.yaml` (all 6 card decks), `PLAN.md`

---

## 1. Scope

CppCitadel 2026 is a bilingual (PL/EN) security-education platform built with a **modern C++23 backend** (no second backend language) and a **React 18 + TypeScript frontend**. It presents OWASP Web/LLM/Agentic AI/API/Client-Side/CI-CD/Automated-Threats/MASVS content, MITRE ATLAS, CompTIA Security+/SecAI+, and all six OWASP Cornucopia-family card decks under `docs/OWASP_stories/`, each threat/card backed by countermeasure code samples in five languages (Python, Java, Go, Scala, Lua). None of those five sample languages is the application's own implementation language — the application's runtime is C++ and TypeScript/JavaScript only.

**This document differs from its `app03`–`app07` siblings in one structural way, stated up front rather than left implicit:** where those specifications could point to a compiler feature or macro system as the *enforcement mechanism* for a security requirement, several requirements here are enforced by **tooling that runs after the code compiles** (sanitizers, fuzzers, static analyzers) or by **code-review discipline**, because C++ does not provide the equivalent compile-time guarantee. Every such requirement below says so explicitly in its own text, not only in a separate caveats section.

---

## 2. Functional Requirements

### FR-01 — Framework Catalog (US-01)
- FR-01.1 The home page shall list all supported frameworks: OWASP Web Top 10, LLM Top 10, Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, Automated Threats (OAT), MASVS 2.0, MITRE ATLAS, CompTIA Security+/SecAI+, and the six Cornucopia-family card decks.
- FR-01.2 Each tile shall show name, version, description, reference URL, and threat/card count.
- FR-01.3 Clicking a tile shall navigate to that framework's threat/card list.

### FR-02 — Threat & Card Browser (US-02)
- FR-02.1 A unified, filterable, searchable list shall cover all threats and all Cornucopia cards.
- FR-02.2 Filters (combinable): framework/edition, suit, severity, STRIDE category, category, tag, `q` free text.
- FR-02.3 Sorting: severity (highest first), framework code, alphabetical.
- FR-02.4 Filtering shall debounce at 300 ms and update results without a full page reload.

### FR-03 — Threat / Card Detail Page (US-03)
- FR-03.1 Each threat/card shall have a stable-URL detail page with tabs: Overview | Attack Vectors | Mitigations | Code Samples | Cross-References.
- FR-03.2 Every mitigation shall list at least one code sample per language (Python, Java, Go, Scala, Lua), each in Attack Demo and Defense sub-tabs. Unlike `app06_HASKELL_react`'s `NonEmpty` or `app07_rust_react`'s non-empty vector wrapper, this is verified by a `RapidCheck` property over the seeded dataset and a CI seed-data linter, **not** a type-level guarantee — `std::vector<CodeSample>` admits an empty vector at the type level, and this requirement's enforcement is entirely at data-population and test time.
- FR-03.3 Code samples shall be grouped by language, each with Attack Demo and Defense sub-tabs, rendered with syntax highlighting (Shiki, lazy-loaded per language).
- FR-03.4 Attack-demo code shall require a confirmation modal before the code is shown or copyable.

### FR-04 — Cross-Framework Mapping (US-04)
- FR-04.1 A `/matrix` page shall map threats across frameworks (at minimum OWASP LLM Top 10 ↔ MITRE ATLAS ↔ CompTIA SecAI+).
- FR-04.2 Matrix cells shall link to the corresponding detail page.
- FR-04.3 The "Cross-References" detail tab shall list relationship type (Equivalent/Related/MapsTo/ParentChild).

### FR-05 — Cornucopia: Frontend Security (FRE) (US-05)
- FR-05.1 `/frameworks/frontend-security` shall display all Cornucopia `FRE` cards from the **Companion Edition v1.0** (`__LLM_AI___companion-cards-1.0-en.yaml`).
- FR-05.2 Cards shall show card ID, value, suit, PL/EN-selectable description, OWASP reference chips.

### FR-06 — Cornucopia: LLM Security (US-06)
- FR-06.1 `/frameworks/llm-security` shall display all `LLM` suit cards (Companion Edition v1.0).
- FR-06.2 `/matrix/llm` shall map OWASP LLM Top 10 (2025) entries to Cornucopia `LLM` cards, indicating coverage gaps with an empty dashed cell.

### FR-07 — Cornucopia: Agentic AI + Cloud (US-07)
- FR-07.1 `/frameworks/agentic-ai` shall display all `AAI` suit cards; cards with value `K`/`A` shall show an `AUTONOMY RISK` badge.
- FR-07.2 `/matrix/agentic` shall compare OWASP Agentic AI Top 10 (2026) with OWASP LLM Top 10 (2025).
- FR-07.3 `CLD` (Cloud) suit cards shall be displayed on the DevOps page (FR-11) rather than a separate page.

### FR-08 — Cornucopia: STRIDE EoP (US-08)
- FR-08.1 `/frameworks/stride` shall display all 78 STRIDE EoP v5.0 cards, grouped by the 6 STRIDE suits.
- FR-08.2 `/stride-heatmap` shall require authentication and show per-system-component STRIDE coverage.

### FR-09 — Cornucopia: ML Security (MLSec) (US-09)
- FR-09.1 `/frameworks/ml-security` shall display all 52 MLSec v1.0 cards (EMR/EIR/EOR/EDR).
- FR-09.2 Cards shall show MITRE ATLAS reference chips; adversarial-ML/model-extraction cards shall carry an `ML-SPECIFIC` badge.

### FR-10 — Cornucopia: Mobile App Security (US-10)
- FR-10.1 `/frameworks/mobile-security` shall display all Mobile App Edition v1.1 cards (PC/AA/NS/RS/CRM/CM).
- FR-10.2 `/matrix/mobile-vs-web` shall compare MASVS 2.0 categories with OWASP Web Top 10.

### FR-11 — Cornucopia: DevOps + Cloud + BOT Security (US-11)
- FR-11.1 `/frameworks/devops-security` shall contain a DVO section (CICD-SEC chips), a CLD section (A05:2021/A01:2021 chips), and a BOT section (OAT chips).
- FR-11.2 A `BotWarningModal` confirmation dialog shall appear before any BOT suit card is shown; acknowledgement stored in `localStorage` under `bot_warning_ack`.
- FR-11.3 DVO and CLD code examples shall be pseudocode only.
- FR-11.4 `GET /api/v1/threats?suit=BOT` shall apply rate limiting (60 req/min per IP).

### FR-12 — Cornucopia: Website App Security (US-12)
- FR-12.1 `/frameworks/website-app` shall display all Cornucopia Website App Edition v3.0 cards (VE, AT, SM, AZ, CR, C), grouped by suit.
- FR-12.2 Cards shall cross-reference the OWASP Web Top 10 entry they correspond to (e.g. `VE3` → `A03:2021`).

### FR-13 — Python Code Samples (US-13)
- FR-13.1 Every mitigation with a code sample shall include a Python tab (Django ORM or FastAPI + Pydantic idioms).

### FR-14 — Java Code Samples (US-14)
- FR-14.1 Every mitigation with a code sample shall include a Java tab (Spring Boot 3.3, Spring Security 6, Spring Data JPA).
- FR-14.2 Java code appears **only** as sample content; it is never part of the application's own build.

### FR-15 — Scala Code Samples (US-15)
- FR-15.1 Every mitigation with a code sample shall include a Scala tab (Akka HTTP/http4s, Slick/Doobie, ZIO 2 idioms).

### FR-16 — Lua Code Samples (US-16)
- FR-16.1 Every mitigation with a code sample shall include a Lua tab (OpenResty/NGINX Lua idioms).

### FR-17 — Global Search & Export (US-17, US-18)
- FR-17.1 A search box shall be present on every page, querying threat/mitigation/card text via PostgreSQL full-text search (`tsvector`).
- FR-17.2 Results shall be grouped by type with highlighted matching excerpts.
- FR-17.3 Users shall be able to export the filtered threat list as CSV or PDF; export shall run as an async job processed by the `worker` thread pool, never blocking the HTTP request.
- FR-17.4 The UI shall poll `/api/v1/export/status/:jobId` and offer a download link on completion.

### FR-18 — i18n: Polish ↔ English
- FR-18.1 The application shall support Polish and English locales only; the UI defaults to **Polish** on first visit.
- FR-18.2 A `LanguageToggle` in the navbar shall switch locales instantly, with no full page reload.
- FR-18.3 The selected locale shall persist in `localStorage` under key `cc_locale` and be sent as `Accept-Language` on every API request.
- FR-18.4 Threat/card titles, descriptions, and attack-vector text shall be served in the requested locale (allowlisted to `pl`/`en`).
- FR-18.5 Code samples shall never be translated; in-code comments remain in English.
- FR-18.6 Missing Polish translations shall fall back to English content with a small "EN" badge — never a blank field.
- FR-18.7 All static UI strings shall be translated in both `pl.json` and `en.json`; a CI key-parity check shall fail the build on any mismatch.

### FR-19 — Cornucopia: Digital-by-Default Harms (US-19)
- FR-19.1 `/frameworks/digital-harms` shall display all Cornucopia `dbd-cards-1.0-en.yaml` cards, grouped by suit (SCO, ARC, AGE, TRU, POR).
- FR-19.2 Each card shall render with a `DesignHarmBadge`, never the `SeverityBadge` used for technical threats. Server-side, this shall be enforced by the `CardKind` variant (`PLAN.md` D-04: `std::variant<TechnicalThreat, DesignHarm>`) — the JSON serialization of a `DesignHarm` value shall have no severity field at all. **Caveat, stated here rather than only in the design document:** this guarantee holds only if every server-side code path that inspects a `CardKind` uses `std::visit` with an exhaustive overload set (compiler-enforced) rather than `std::get`/`std::get_if` on a single alternative (not compiler-enforced) — `PLAN.md` D-04 requires the former via code review, and the JSON-encoding test in `user_stories+tests.md` exists specifically to catch a regression to the latter.
- FR-19.3 Each card shall display a `CrossReference` chip linking to OWASP A04:2021 Insecure Design, and, where relevant, to the CompTIA SecAI+ GRC/AI-Act topic list.
- FR-19.4 The page shall display a disclaimer banner stating that this deck models *service-design harms in public-sector digital services* (source: `digitalbenefits.uk`), not exploitable technical vulnerabilities.
- FR-19.5 Cards shall be filterable by suit and searchable by description keyword, consistent with FR-05–FR-12.
- FR-19.6 Polish translations of all SCO/ARC/AGE/TRU/POR card descriptions shall be reviewed by a native Polish speaker before merge, following the same i18n gate as FR-18.

---

## 3. Security Requirements

### SR-01 — Authentication & Authorization
- SR-01.1 JWT authentication (RS256) via `jwt-cpp`.
- SR-01.2 Admin CRUD endpoints (`/api/v1/admin/*`) require the `Admin` role in JWT claims.
- SR-01.3 `/stride-heatmap` requires `Admin` or `Trainer` role.
- SR-01.4 Tokens are stateless; access tokens expire after 1 hour (configurable).
- SR-01.5 Passwords are hashed with `libsodium`'s Argon2id implementation (`PLAN.md` D-06) — never a hand-written hash function.

### SR-02 — SQL Injection Prevention
- SR-02.1 All database access goes through `libpqxx` parameterized statements (`pqxx::params`) or `sqlpp11`'s compile-time-checked query builder for hot-path queries (`PLAN.md` §2). No query is ever built by string concatenation or `fmt::format` interpolation of untrusted input.
- SR-02.2 CI runs `scripts/check_no_string_sql.py`, a grep-based check that fails the build if a `+`/`fmt::format`-built `std::string` flows into `pqxx::work::exec`/`exec_params`. **This is a weaker guarantee than `app05_go_react`'s `sqlc`, `app06_HASKELL_react`'s `hasql-th`, or `app07_rust_react`'s `sqlx::query!`**, all of which fail the *build* if a query's shape doesn't match the schema — this project's check only catches the *string-concatenation pattern*, not query-shape/schema drift, and this gap is accepted and documented rather than misrepresented as equivalent.

### SR-03 — XSS Prevention
- SR-03.1 All Cornucopia card descriptions (`description_pl`, `description_en`) rendered in React are passed through `DOMPurify.sanitize()`.
- SR-03.2 `dangerouslySetInnerHTML` is never used without DOMPurify wrapping (custom ESLint rule `no-raw-html`).
- SR-03.3 Admin update endpoints (`PUT /api/v1/admin/threats/:id`) sanitize input server-side via the custom `SafeHtml` sanitizer built on `gumbo-parser` (`PLAN.md` D-07) before persisting.
- SR-03.4 `Content-Security-Policy` sets `default-src 'self'`; no `unsafe-inline`/`unsafe-eval`.

### SR-04 — Security Headers
- SR-04.1 `SecurityHeadersFilter` injects on every response: CSP, `Strict-Transport-Security` (max-age ≥ 31536000, includeSubDomains), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`.
- SR-04.2 OWASP ZAP active scan shall report 0 HIGH/CRITICAL findings.

### SR-05 — Rate Limiting
- SR-05.1 An in-process, `std::atomic`-guarded token bucket (`PLAN.md` D-08) enforces 60 req/min/IP on all `/api/v1/*` routes on a single instance; a Redis-backed counter is added as a second layer if horizontally scaled.
- SR-05.2 Exhausted budget returns HTTP 429 with `Retry-After`.
- SR-05.3 `/api/v1/search` additionally enforces a 200-character query-length cap, returning HTTP 422 for longer inputs.
- SR-05.4 The rate limiter's concurrency safety shall be verified by a nightly ThreadSanitizer test run, not asserted from the implementation's design alone.

### SR-06 — Content Integrity
- SR-06.1 `integrity::verify` runs from `src/bin/seed.cpp` at first load and from the `periodic_reverify` job on a schedule.
- SR-06.2 On any SHA-256 mismatch against `data/hashes.json`, the calling process aborts — fail-secure, no partial writes (single DB transaction).
- SR-06.3 `data/hashes.json` is regenerated only by a CI automation step after a reviewed merge to `main`.
- SR-06.4 `integrity::verify`'s isolation from `src/controllers/**` is verified by a CI build-graph check (`PLAN.md` D-02) — a weaker mechanism than a compiler-enforced module boundary (contrast `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react`), and code review is a required second layer, not a redundant one.

### SR-07 — Reference ID Allowlists (Strong Types with Validating Constructors)
- SR-07.1 `OwaspRef`, `MitreRef`, `MavsRef`, `CicdSecRef`, `OatRef` are distinct strong-typed wrapper structs with static factory functions (`OwaspRef::create(raw, allowlist) -> std::expected<OwaspRef, ValidationError>`) validating against allowlists loaded from `data/ref-allowlists.json` / `data/mitre-atlas-allowlist.json`.
- SR-07.2 Any admin CRUD request supplying an unknown reference ID is rejected with HTTP 422.

### SR-08 — Memory Safety (the central, honestly-scoped requirement of this specification)
- SR-08.1 No translation unit in this project's own code shall call `new`/`delete` directly, hold a raw owning pointer, or use a C-style array where `std::array`/`std::vector`/`std::span` is applicable (`PLAN.md` D-01). `clang-tidy`'s `cppcoreguidelines-owning-memory` and related checks are configured as build-failing errors.
- SR-08.2 Every CI test run executes against an `-fsanitize=address,undefined` build; a nightly job additionally runs an `-fsanitize=thread` build for concurrency-sensitive code (the worker pool, the rate limiter). Any sanitizer finding is a release blocker.
- SR-08.3 `libFuzzer` harnesses (`PLAN.md` Phase 3.5) target the YAML loader, JSON deserializers, and any other function parsing untrusted or semi-trusted input; each runs for a fixed time budget on every relevant PR and continuously (nightly/OSS-Fuzz-style) outside PRs.
- SR-08.4 **This requirement explicitly does not claim parity with `app07_rust_react`'s SR-08 (`#![forbid(unsafe_code)]`).** SR-08.1–SR-08.3 are detective and probabilistic controls (they catch what review, static analysis, and test/fuzz execution actually exercise); Rust's guarantee is preventive and total for its own code (a memory-safety violation fails to compile, full stop, independent of test coverage). This document states that difference because conflating "we have ASan in CI" with "we cannot have this bug class" would be a false claim, and this series' consistent practice is not to make false claims about what a stack guarantees.

### SR-09 — YAML Parsing Safety
- SR-09.1 All six Cornucopia YAML decks are decoded via hand-written `decode_card_file`-style functions (`PLAN.md` D-03) that explicitly enumerate and reject unrecognized top-level and nested keys.
- SR-09.2 A `RapidCheck` property (`rc::check("card file decoder rejects unknown fields", ...)`) generates YAML documents with random extra keys and asserts decoding throws `CardDecodeError`.
- SR-09.3 **This requirement documents an accepted gap versus `app05_go_react` (`KnownFields(true)`), `app06_HASKELL_react` (derived `FromJSON` + property test), and `app07_rust_react` (`#[serde(deny_unknown_fields)]`)**: those are one-line, declarative, and automatically re-verified whenever the target struct changes; this project's equivalent is hand-maintained code that a future contributor must remember to update when `CornucopiaCard`'s shape changes, backed only by the property test in SR-09.2 to catch drift.

### SR-10 — SAST / Fuzzing / SCA
- SR-10.1 `clang-tidy` (`cppcoreguidelines-*`, `bugprone-*`, `cert-*`, `clang-analyzer-*` check groups) runs on every PR; build fails on any finding at or above the configured severity.
- SR-10.2 Clang Static Analyzer and `cppcheck` run as complementary SAST passes on every PR.
- SR-10.3 `libFuzzer` targets (SR-08.3) run on every PR touching a parsing surface and continuously outside PRs.
- SR-10.4 OWASP Dependency-Check (C/C++ CPE-matching mode) and `vcpkg`/`conan` audit tooling run against the dependency manifest on every PR and nightly.
- SR-10.5 `npm audit --audit-level=high` fails the frontend build on HIGH/CRITICAL advisories.
- SR-10.6 Trivy scans both container images; fails on HIGH/CRITICAL.

### SR-11 — CSRF / CORS
- SR-11.1 No server-side sessions exist, so classical CSRF does not apply. `CorsFilter` allowlists only the configured frontend origin.
- SR-11.2 Preflight `OPTIONS` requests are handled without leaking sensitive headers.

### SR-12 — Code Sample Safety
- SR-12.1 Attack-demo snippets are stored as plain text and never executed server-side.
- SR-12.2 DVO/CLD code examples are pseudocode only.
- SR-12.3 `BotWarningModal` gates any BOT card attack demo; acknowledgement stored in `localStorage`.

### SR-13 — i18n Security
- SR-13.1 `Accept-Language` is allowlisted server-side to `pl`/`en`; unsupported values fall back to `en` with `Content-Language: en` in the response — a deliberately different default than the UI's client-side default of `pl` (FR-18.1).
- SR-13.2 Locale values read from `localStorage` are validated against the two-variant `Locale` enum before use.
- SR-13.3 Translation values contain only plain text — no HTML, no interpolation of user input.

### SR-14 — Job Queue Safety
- SR-14.1 Every job-table row's payload is parsed via `nlohmann::json`'s explicit-schema `from_json` overloads with unrecognized-field rejection, following the same discipline as SR-09.
- SR-14.2 The `worker` binary runs with the same least-privilege DB role as `api` (no superuser), and cannot reach `controllers::*` handlers — there is no `#include` path from `jobs/*` back into `controllers/*`, checked by the same CI build-graph tool as SR-06.4.

---

## 4. Non-Functional Requirements

### NFR-01 — Performance
- NFR-01.1 API endpoints respond in ≤ 200 ms (p95) under 50 concurrent users.
- NFR-01.2 Full-text search (`tsvector` + GIN index) returns results in ≤ 300 ms (p95).
- NFR-01.3 The production frontend initial bundle is ≤ 600 KB gzip.
- NFR-01.4 Shiki language packs are lazy-loaded, one per language, on first use.
- NFR-01.5 `api`/`worker` cold-start time is ≤ 100 ms (no runtime/GC initialization) — comparable to `app07_rust_react`'s figure, measured rather than assumed.

### NFR-02 — Usability & Accessibility
- NFR-02.1 Fully responsive from 375 px to 2560 px.
- NFR-02.2 Light and dark mode via a toggle, no page reload.
- NFR-02.3 WCAG 2.1 AA contrast ratios on all interactive elements.
- NFR-02.4 All core flows are fully keyboard-navigable.

### NFR-03 — Maintainability
- NFR-03.1 All seed data lives under `data/` as JSON/YAML, loaded via `src/bin/seed.cpp` — never hand-written as C++ struct literals in migrations.
- NFR-03.2 Every `CodeSample` carries a `version_note` so maintainers know when to refresh it.
- NFR-03.3 C++ code follows the `domain/service/store/cards/integrity` (core) plus `controllers/middleware` (api) plus `jobs` (worker) layering in `PLAN.md` §9; handlers stay thin, business logic lives in `service`.
- NFR-03.4 Every public function in `core` that takes untrusted input (YAML, JSON, HTTP request bodies) has a corresponding unit test asserting rejection of at least one malformed case, in addition to the fuzzing coverage in SR-08.3 — a deliberate belt-and-suspenders requirement given SR-09.3's stated gap.

### NFR-04 — Testability (TDD — see `user_stories+tests.md`)
- NFR-04.1 `core::service` code coverage ≥ 85% (via `gcov`/`llvm-cov`).
- NFR-04.2 Every Drogon controller endpoint has a Drogon-test-client-based integration test.
- NFR-04.3 Every untrusted-input-parsing function shall have at least one `RapidCheck` property test in addition to example-based GoogleTest cases.
- NFR-04.4 At least one Playwright end-to-end test per user story (US-01–US-19).
- NFR-04.5 Tests are written **before** implementation for every new feature (Red → Green → Refactor); a PR adding production code without a preceding failing test in the same PR fails review.

### NFR-05 — Portability
- NFR-05.1 The full stack (C++ `api` + `worker` + PostgreSQL + Redis + Nginx) runs via a single `docker compose up`.
- NFR-05.2 `api`/`worker` production images use a minimal runtime base containing only the shared libraries the binary actually links, verified via `ldd` in a CI step.
- NFR-05.3 Static frontend assets are served by Nginx directly — no external CDN dependency.

### NFR-06 — Internationalization Quality
- NFR-06.1 Language switching completes in under 150 ms perceived latency.
- NFR-06.2 No hardcoded user-visible strings exist in React components; all go through `react-i18next` keys.
- NFR-06.3 API responses serving translated content set `Content-Language: pl` or `Content-Language: en`.

### NFR-07 — Deployment Footprint
- NFR-07.1 The `api` production container image target is ≤ 60 MB, verified by a CI size-check step. This is explicitly **not** claimed to match `app07_rust_react`'s ≤ 25 MB target — a C++ binary dynamically linking OpenSSL, `libpqxx`'s PostgreSQL client libraries, and Drogon's own dependencies typically carries more shared-library weight than a `musl`-static Rust binary unless aggressively statically linked, which this project does not attempt by default given the added build complexity. The number is stated as a target to hit and measure, not a guaranteed win over any sibling.

---

## 5. Design Constraints & Technology Mandates

- C-01 The application backend shall be written entirely in C++23 — `api` and `worker` alike. No other backend runtime language is used anywhere in the application itself.
- C-02 Code **samples** shown to users (Python, Java, Go, Scala, Lua) are educational content, not part of the application's own runtime; none of these five languages is the application's implementation language.
- C-03 No third-party analytics, tracking scripts, or externally-hosted fonts/CDNs.
- C-04 Every page displays a disclaimer that content is educational and must be verified against official sources.
- C-05 The application makes no outbound calls to external threat-intel feeds at runtime; all data is seeded locally from files under `data/`.
- C-06 Every code sample carries a version annotation.
- C-07 Only Polish and English are supported; both translation files must be complete before a new translation key reaches production.
- C-08 `CornucopiaCard` records (all six decks) are never editable through any UI or API. Content changes only through a reviewed PR to the source YAML plus a hash-allowlist update.
- C-09 The Redis instance backing cross-instance caching is never exposed on a public port.
- C-10 No `new`/`delete`, raw owning pointer, or C-style unchecked array indexing shall exist in this project's own C++ code (`PLAN.md` D-01); `std::span`/`std::vector`/bounds-checked access are used throughout.
- C-11 No hand-written cryptographic primitive or hand-written parser for a security-sensitive format (passwords, JWTs, HTML) shall exist in this project's own code — only audited libraries (`libsodium`, `jwt-cpp`, `gumbo-parser`) (`PLAN.md` D-06).

---

## 6. Data Requirements

### DR-01 — Minimum Seeded Data
- DR-01.1 All 10 OWASP Web Top 10 (2021) entries with mitigations and 5-language code samples.
- DR-01.2 All 10 OWASP LLM Top 10 (2025) entries with mitigations and 5-language code samples.
- DR-01.3 Minimum 15 MITRE ATLAS techniques (≥ 5 tactics): AML.T0000, T0002, T0010, T0051, T0018, T0020, T0019, T0041, T0043, T0015, T0012, T0024, T0025, T0029, T0046.
- DR-01.4 All 10 OWASP Agentic AI Top 10 (2026) entries.
- DR-01.5 Minimum 20 CompTIA SecAI+/Security+ SY0-701 topics, including CWE Top 25 memory-safety weaknesses and CISA/NSA memory-safe-language migration guidance as an explicit topic — with this application's own implementation stack (C++) cited as a live, in-context example of the pre-migration state the guidance addresses, and `app07_rust_react` cross-referenced as the post-migration comparison.
- DR-01.6 Full Cornucopia Website App Edition v3.0 cards (VE, AT, SM, AZ, CR, C suits).
- DR-01.7 Full Cornucopia Companion Edition v1.0 cards (LLM, FRE, DVO, BOT, CLD, AAI suits).
- DR-01.8 Full Cornucopia Mobile App Edition v1.1 cards (PC, AA, NS, RS, CRM, CM suits).
- DR-01.9 Full Cornucopia STRIDE EoP v5.0 cards (78 cards: SP, TA, RE, ID, DS, EP suits).
- DR-01.10 Full Cornucopia MLSec v1.0 cards (52 cards: EMR, EIR, EOR, EDR suits).
- DR-01.11 Full Digital-by-Default Harms v1.0 cards (SCO, ARC, AGE, TRU, POR, COR, WC suits), each with a reviewed Polish translation and a `CrossReference` row to OWASP A04:2021 Insecure Design.

### DR-02 — YAML Source-of-Truth
- DR-02.1 Cornucopia cards are maintained as YAML files in `data/cornucopia/`.
- DR-02.2 `src/cards/loader.cpp` loads all six YAML files at `src/bin/seed.cpp` run time and on `reingest_deck` job execution; no live-reload from an HTTP-triggered path.
- DR-02.3 Every card row stores `content_sha256`, verified against `data/hashes.json` before being marked valid.

### DR-03 — Database Migrations
- DR-03.1 All schema changes are managed via hand-authored, forward-only SQL migration files, applied by a small CLI tool.
- DR-03.2 Migrations are idempotent; no destructive `DROP` in non-test migrations.

---

## 7. Abuse Case Requirements

| ID | Threat | Requirement |
|---|---|---|
| AC-01 | SQL injection via `?q=` | `libpqxx` parameterized statements / `sqlpp11`; CI grep forbids string-built queries |
| AC-02 | XSS via admin card update | `SafeHtml` (server) + DOMPurify (client) |
| AC-03 | CSRF | Stateless JWT; no session; CORS origin allowlist |
| AC-04 | JWT forgery | RS256 key pair; constant-time signature comparison (`jwt-cpp`'s verification path, itself built on audited crypto) |
| AC-05 | Bot scraping all card suits | Atomic/Redis rate limit 60 req/min; 429 + Retry-After |
| AC-06 | YAML card tampering | SHA-256 `integrity::verify`; ingestion aborts on mismatch |
| AC-07 | Fake OWASP reference injection via admin | `OwaspRef::create` + allowlist |
| AC-08 | Fake MITRE T-code injection | `MitreRef::create` + allowlist |
| AC-09 | Privilege escalation to `/stride-heatmap` | JWT role check middleware; 401 on missing/invalid token |
| AC-10 | XSS via LLM card description | `DOMPurify.sanitize()` on all `description_pl`/`description_en` |
| AC-11 | i18n locale injection (`Accept-Language: ../../etc/passwd`) | `Locale` is a closed two-variant enum; unparseable input never reaches business logic, falls back to `En` |
| AC-12 | Clickjacking `/stride-heatmap` | `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` |
| AC-13 | Supply-chain attack via a vcpkg/Conan or npm dependency | OWASP Dependency-Check + `npm audit` + Trivy |
| AC-14 | Malicious job payload | `nlohmann::json` explicit-schema parsing rejecting unknown fields, validated at enqueue time |
| AC-15 | BotWarningModal bypass via direct API call | Server-side check independent of the modal |
| AC-16 | Digital-by-Default Harms deck misread as a CVE-style severity list | `CardKind` variant (`PLAN.md` D-04) — a `DesignHarm` value cannot carry a `Severity` if read via `std::visit`; a JSON-encoding integration test asserts the absence, and code review is required to catch any `std::get`/`std::get_if` regression the test alone might miss |
| AC-17 | Memory-corruption vulnerability (buffer overflow, use-after-free) in application code | RAII/smart-pointer discipline + `clang-tidy` + ASan/UBSan on every test run + continuous fuzzing (SR-08). **Unlike `app07_rust_react`'s AC-17, this is a detective control layered several ways, not a compile-time prevention** — a bug in a code path with insufficient test/fuzz coverage can still ship, and this document does not claim otherwise. |

---

## 8. Traceability Matrix (abbreviated)

| Requirement | User Story | Security Design Decision | Test Coverage |
|---|---|---|---|
| FR-01, FR-02 | US-01, US-02 | SR-02 (parameterized queries) | US-01/US-02 Playwright |
| FR-05 | US-05 | D-07 (SafeHtml) | US-05 Playwright |
| FR-06 | US-06 | SR-07 | US-06 Playwright |
| FR-07 | US-07 | SR-07 | US-07 Playwright |
| FR-08 | US-08 | D-08 (rate limit), auth | US-08 Playwright |
| FR-09 | US-09 | SR-07 | US-09 Playwright |
| FR-10 | US-10 | SR-07 | US-10 Playwright |
| FR-11 | US-11 | D-08 | US-11 Playwright |
| FR-12 | US-12 | SR-07 | US-12 Playwright |
| FR-17 | US-17, US-18 | Job-table worker pool | US-17/US-18 Playwright, AC-14 |
| FR-18 | — (cross-cutting i18n) | D-09 | i18n-parity CI test |
| FR-19 | US-19 | D-04 (variant, review-dependent) | US-19 Playwright, AC-16 |
| SR-02 | — | D-01/§2 (libpqxx/sqlpp11) | AC-01 integration test |
| SR-03 | — | D-07 | AC-02, AC-10 integration test |
| SR-05 | — | D-08 | AC-05 integration test, nightly TSan |
| SR-06 | — | D-02 | AC-06 integration test |
| SR-07 | — | — | AC-07, AC-08 integration test |
| SR-08 | — | D-01, D-05 | AC-17; ASan/UBSan CI job; libFuzzer corpus |
| SR-09 | — | D-03 | `RapidCheck`: unknown-field rejection property |
| SR-10 | — | — | CI SAST/fuzzing/SCA gates |
| SR-14 | — | — | AC-14 integration test |

---

## 9. Glossary

| Term | Definition |
|---|---|
| RAII (Resource Acquisition Is Initialization) | The C++ idiom of binding resource lifetime to object scope, implemented here via smart pointers instead of manual `new`/`delete` |
| AddressSanitizer (ASan) | A compiler-instrumented runtime tool detecting out-of-bounds access and use-after-free at the moment they occur, during test execution |
| UndefinedBehaviorSanitizer (UBSan) | A compiler-instrumented runtime tool detecting undefined-behavior patterns (signed overflow, invalid enum values, etc.) during test execution |
| ThreadSanitizer (TSan) | A compiler-instrumented runtime tool detecting data races during test execution |
| `libFuzzer` | A coverage-guided fuzzing engine (part of the LLVM/Clang toolchain) used here to continuously generate adversarial input for parsing functions |
| `std::variant` / `std::visit` | C++17+ standard-library sum type and its exhaustiveness-checked pattern-matching mechanism, used here as the closest analogue to Rust's `enum`/Haskell's ADT |
| `sqlpp11` | A C++ library providing compile-time, template-metaprogramming-checked SQL query construction |
| `libpqxx` | The official C++ client library for PostgreSQL |
| `gumbo-parser` | Google's HTML5 parsing library, used here as the basis for a custom allow-list HTML sanitizer (`SafeHtml`) |
| CWE Top 25 | MITRE's annually updated list of the most dangerous software weaknesses; several top entries (buffer overflow, use-after-free) are memory-safety issues C++ does not prevent by construction |
| CISA/NSA memory-safe-language guidance | Public 2023–2026 guidance recommending new development use memory-safe languages; this app is included in the series as the explicit pre-migration comparison point against `app07_rust_react` |
| Cornucopia | OWASP's card-game family for threat modeling (Website App, Mobile App, Companion editions) |
| STRIDE | Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege |
| MITRE ATLAS | Adversarial Threat Landscape for AI Systems |
| MASVS | OWASP Mobile Application Security Verification Standard |
| Digital-by-Default Harms deck | `dbd-cards-1.0-en.yaml` — models service-design harms (exclusion, opaque design) in public-sector digital services; mapped to OWASP A04:2021 Insecure Design, not a technical CVE-style vulnerability |
