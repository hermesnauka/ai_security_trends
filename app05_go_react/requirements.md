# GoSentry 2026 — Requirements Specification

**Version:** 1.0
**Date:** 2026-07-07
**Project:** `app05_go_react`
**Sources:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`, `docs/OWASP_stories/*.yaml` (all 6 card decks), `PLAN.md`

---

## 1. Scope

GoSentry 2026 is a bilingual (PL/EN) security-education platform built with a **Go 1.23 backend** (no second backend language) and a **React 18 + TypeScript frontend**. It presents OWASP Web/LLM/Agentic AI/API/Client-Side/CI-CD/Automated-Threats/MASVS content, MITRE ATLAS, CompTIA Security+/SecAI+, and all six OWASP Cornucopia-family card decks under `docs/OWASP_stories/`, each threat/card backed by countermeasure code samples in five languages (Python, Java, Go, Scala, Lua). Java and Scala appear **only** as code-sample content — the application's own runtime is Go and TypeScript/JavaScript only.

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
- FR-03.2 Every mitigation shall list at least one code sample per language (Python, Java, Go, Scala, Lua), each in Attack Demo and Defense sub-tabs.
- FR-03.3 Code samples shall be grouped by language, each with Attack Demo and Defense sub-tabs, rendered with syntax highlighting (Shiki, lazy-loaded per language).
- FR-03.4 Attack-demo code shall require a confirmation modal before the code is shown or copyable.

### FR-04 — Cross-Framework Mapping (US-04)
- FR-04.1 A `/matrix` page shall map threats across frameworks (at minimum OWASP LLM Top 10 ↔ MITRE ATLAS ↔ CompTIA SecAI+).
- FR-04.2 Matrix cells shall link to the corresponding detail page.
- FR-04.3 The "Cross-References" detail tab shall list relationship type (EQUIVALENT/RELATED/MAPS_TO/PARENT_CHILD).

### FR-05 — Cornucopia: Frontend Security (FRE) (US-05)
- FR-05.1 `/frameworks/frontend-security` shall display all Cornucopia `FRE` cards from the **Companion Edition v1.0** (`__LLM_AI___companion-cards-1.0-en.yaml`).
- FR-05.2 Cards shall show card ID, value, suit, PL/EN-selectable description, OWASP reference chips.

### FR-06 — Cornucopia: LLM Security (US-06)
- FR-06.1 `/frameworks/llm-security` shall display all `LLM` suit cards (Companion Edition v1.0).
- FR-06.2 `/matrix/llm` shall map OWASP LLM Top 10 (2025) entries to Cornucopia `LLM` cards, indicating coverage gaps with an empty dashed cell.

### FR-07 — Cornucopia: Agentic AI + Cloud (US-07)
- FR-07.1 `/frameworks/agentic-ai` shall display all `AAI` suit cards; cards with value `K`/`A` shall show an `AUTONOMY RISK` badge.
- FR-07.2 `/matrix/agentic` shall compare OWASP Agentic AI Top 10 (2026) with OWASP LLM Top 10 (2025).
- FR-07.3 `CLD` (Cloud) suit cards shall be displayed on the DevOps page (FR-11) rather than a separate page — Cloud misconfiguration cards cross-reference A05:2021/A01:2021, not a dedicated OWASP Top 10 list.

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
- FR-11.3 DVO and CLD code examples shall be pseudocode only — no working pipeline exploits or real cloud misconfiguration templates.
- FR-11.4 `GET /api/v1/threats?suit=BOT` shall apply rate limiting (60 req/min per IP).

### FR-12 — Cornucopia: Website App Security (US-12)
- FR-12.1 `/frameworks/website-app` shall display all Cornucopia Website App Edition v3.0 cards (VE, AT, SM, AZ, CR, C), grouped by suit — given a dedicated page consistent with FR-05–FR-11, rather than being folded silently into the generic OWASP Web Top 10 threat list.
- FR-12.2 Cards shall cross-reference the OWASP Web Top 10 entry they correspond to (e.g. `VE3` → `A03:2021`).

### FR-13 — Python Code Samples (US-13)
- FR-13.1 Every mitigation with a code sample shall include a Python tab.
- FR-13.2 Python samples shall use Django ORM or FastAPI + Pydantic idioms as appropriate.

### FR-14 — Java Code Samples (US-14)
- FR-14.1 Every mitigation with a code sample shall include a Java tab (Spring Boot 3.3, Spring Security 6, Spring Data JPA).
- FR-14.2 Java code appears **only** as sample content; it is never part of the application's own build.

### FR-15 — Scala Code Samples (US-15)
- FR-15.1 Every mitigation with a code sample shall include a Scala tab (Akka HTTP/http4s, Slick/Doobie, ZIO 2 idioms).

### FR-16 — Lua Code Samples (US-16)
- FR-16.1 Every mitigation with a code sample shall include a Lua tab (OpenResty/NGINX Lua idioms — rate limiting, header injection prevention, WAF rules).

### FR-17 — Global Search & Export (US-17, US-18)
- FR-17.1 A search box shall be present on every page, querying threat/mitigation/card text via PostgreSQL full-text search (`tsvector`).
- FR-17.2 Results shall be grouped by type with highlighted matching excerpts.
- FR-17.3 Users shall be able to export the filtered threat list as CSV or PDF; export shall run as an async `river.Job`, never blocking the HTTP request.
- FR-17.4 The UI shall poll `/api/v1/export/status/:jobId` and offer a download link on completion.

### FR-18 — i18n: Polish ↔ English
- FR-18.1 The application shall support Polish (`pl`, default) and English (`en`) locales only.
- FR-18.2 A `LanguageToggle` in the navbar shall switch locales instantly, with no full page reload.
- FR-18.3 The selected locale shall persist in `localStorage` under key `gs_locale` and be sent as `Accept-Language` on every API request.
- FR-18.4 Threat/card titles, descriptions, and attack-vector text shall be served in the requested locale (allowlisted to `pl`/`en`; unsupported values default to `en` server-side, `pl` client-side per FR-18.1's UI default — see SR-12 for the security rationale of this asymmetry).
- FR-18.5 Code samples shall never be translated; in-code comments remain in English.
- FR-18.6 Missing Polish translations shall fall back to English content with a small "EN" badge — never a blank field.
- FR-18.7 All static UI strings shall be translated in both `pl.json` and `en.json`; a CI key-parity check shall fail the build on any mismatch.

### FR-19 — Cornucopia: Digital-by-Default Harms (US-19)
- FR-19.1 `/frameworks/digital-harms` shall display all Cornucopia `dbd-cards-1.0-en.yaml` cards, grouped by suit (SCO, ARC, AGE, TRU, POR).
- FR-19.2 Each card shall render with a `DesignHarmBadge`, never the `SeverityBadge` used for technical threats — this deck has no CRITICAL/HIGH/MEDIUM/LOW severity, only a design-harm category. This shall be enforced at the Go type level: the constructor for a `DESIGN_HARM` `CornucopiaCard` shall not accept a `Severity` argument at all (see `PLAN.md` §5.5, D-07).
- FR-19.3 Each card shall display a `CrossReference` chip linking to OWASP A04:2021 Insecure Design, and, where relevant, to the CompTIA SecAI+ GRC/AI-Act topic list.
- FR-19.4 The page shall display a disclaimer banner stating that this deck models *service-design harms in public-sector digital services* (source: `digitalbenefits.uk`), not exploitable technical vulnerabilities.
- FR-19.5 Cards shall be filterable by suit and searchable by description keyword, consistent with FR-05–FR-12.
- FR-19.6 Polish translations of all SCO/ARC/AGE/TRU/POR card descriptions shall be reviewed by a native Polish speaker before merge, following the same i18n gate as FR-18.

---

## 3. Security Requirements

### SR-01 — Authentication & Authorization
- SR-01.1 JWT authentication (RS256) via `golang-jwt/jwt` v5, verified in `internal/http/middleware/auth.go`.
- SR-01.2 Admin CRUD endpoints (`/api/v1/admin/*`) require the `ADMIN` role in JWT claims.
- SR-01.3 `/stride-heatmap` requires `ADMIN` or `TRAINER` role.
- SR-01.4 Tokens are stateless; access tokens expire after 1 hour (configurable).
- SR-01.5 Passwords hashed with `bcrypt` (cost ≥ 12).

### SR-02 — SQL Injection Prevention
- SR-02.1 All database queries go through `sqlc`-generated, parameterized Go functions (`PLAN.md` D-02) — no query string is ever built by concatenation or `fmt.Sprintf`.
- SR-02.2 A `golangci-lint` custom rule flags any `fmt.Sprintf`/`+` string building that flows into a `pgx` `Exec`/`Query` call.

### SR-03 — XSS Prevention
- SR-03.1 All Cornucopia card descriptions (`DescriptionPl`, `DescriptionEn`) rendered in React are passed through `DOMPurify.sanitize()`.
- SR-03.2 `dangerouslySetInnerHTML` is never used without DOMPurify wrapping (custom ESLint rule `no-raw-html`).
- SR-03.3 Admin update endpoints (`PUT /api/v1/admin/threats/:id`) sanitize input server-side via `bluemonday.UGCPolicy()` restricted to an explicit allow-list (`PLAN.md` D-04) before persisting. No Java-branded sanitization library is used anywhere in the stack.
- SR-03.4 `Content-Security-Policy` sets `default-src 'self'`; no `unsafe-inline`/`unsafe-eval`.

### SR-04 — Security Headers
- SR-04.1 `SecurityHeaders` middleware injects on every response: CSP, `Strict-Transport-Security` (max-age ≥ 31536000, includeSubDomains), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`.
- SR-04.2 OWASP ZAP active scan shall report 0 HIGH/CRITICAL findings.

### SR-05 — Rate Limiting
- SR-05.1 A Redis Lua-scripted sliding window (`PLAN.md` D-08) enforces 60 req/min/IP on all `/api/v1/*` routes.
- SR-05.2 Exhausted budget returns HTTP 429 with `Retry-After`.
- SR-05.3 `/api/v1/search` additionally enforces a 200-character query-length cap, returning HTTP 422 for longer inputs.

### SR-06 — Content Integrity
- SR-06.1 `internal/integrity.Verify` runs at `cmd/api` boot and inside `cmd/worker`'s scheduled `PeriodicReverify` job.
- SR-06.2 On any SHA-256 mismatch against `data/hashes.json`, the calling process (`cmd/api`, `cmd/seed`, or the `ReingestDeck` job) fails/aborts — fail-secure, no partial writes (single DB transaction).
- SR-06.3 `data/hashes.json` is regenerated only by a CI automation step after a reviewed merge to `main`.
- SR-06.4 `internal/integrity.Verify` is never imported by any package under `internal/http/**` — enforced by a `depguard` lint rule in CI, not review alone (`PLAN.md` D-05).

### SR-07 — Reference ID Allowlists (Typed Identifiers)
- SR-07.1 `OwaspRef`, `MitreRef`, `MavsRef`, `CicdSecRef`, `OatRef` are distinct Go named string types (`PLAN.md` D-07); their smart constructors validate against allowlists loaded from `data/ref-allowlists.json` / `data/mitre-atlas-allowlist.json`.
- SR-07.2 Any admin CRUD request supplying an unknown reference ID is rejected with HTTP 422.

### SR-08 — YAML Parsing Safety
- SR-08.1 All six Cornucopia YAML decks are unmarshalled with `yaml.v3` into a fixed `CardFile` struct using strict/unknown-field-rejecting decoding — never into an untyped `interface{}`/`map[string]any` that could later be misused as an execution vector.
- SR-08.2 This requirement documents that Go's static-target decoding removes the *class* of vulnerability `yaml.safe_load` (Python) and SnakeYAML's `SafeConstructor` (Java) exist to prevent (`PLAN.md` D-09) — it does not imply YAML content itself is trusted; SR-06 integrity verification still applies unconditionally.

### SR-09 — SAST / SCA
- SR-09.1 `golangci-lint` (bundling `gosec`, `staticcheck`, `go vet`, `depguard`) runs on every PR; build fails on any finding.
- SR-09.2 `govulncheck` runs against the Go toolchain and module graph on every PR and nightly; fails on any known-exploitable vulnerability reachable from the actual call graph (not just present in `go.sum`).
- SR-09.3 `npm audit --audit-level=high` fails the frontend build on HIGH/CRITICAL advisories.
- SR-09.4 Trivy scans both container images; fails on HIGH/CRITICAL.

### SR-10 — CSRF / CORS
- SR-10.1 No server-side sessions exist, so classical CSRF does not apply. `CorsMiddleware` allowlists only the configured frontend origin.
- SR-10.2 Preflight `OPTIONS` requests are handled without leaking sensitive headers.

### SR-11 — Code Sample Safety
- SR-11.1 Attack-demo snippets are stored as plain text and never executed server-side (there is no "run this sample" feature).
- SR-11.2 DVO/CLD code examples are pseudocode only.
- SR-11.3 `BotWarningModal` gates any BOT card attack demo; acknowledgement stored in `localStorage`.

### SR-12 — i18n Security
- SR-12.1 `Accept-Language` is allowlisted server-side to `pl`/`en`; unsupported values fall back to `en` with `Content-Language: en` in the response — a deliberately different default than the UI's client-side default of `pl` (FR-18.1), because an unrecognized header value is treated as a caller error to fail safely toward the widest-understood language, not as a UI preference to fail toward Polish.
- SR-12.2 Locale values read from `localStorage` are validated against the allowlist before use.
- SR-12.3 Translation values contain only plain text — no HTML, no interpolation of user input.

### SR-13 — Job Queue Safety
- SR-13.1 Every `river.Job` payload is a typed Go struct validated with `go-playground/validator` at enqueue time — never a raw JSON blob interpreted at execution time.
- SR-13.2 `cmd/worker` runs with the same least-privilege DB role as `cmd/api` (no superuser), and cannot reach `internal/http` handlers directly (no import path exists from `internal/jobs` back into `internal/http`).

---

## 4. Non-Functional Requirements

### NFR-01 — Performance
- NFR-01.1 API endpoints respond in ≤ 200 ms (p95) under 50 concurrent users.
- NFR-01.2 Full-text search (`tsvector` + GIN index) returns results in ≤ 300 ms (p95).
- NFR-01.3 The production frontend initial bundle is ≤ 600 KB gzip.
- NFR-01.4 Shiki language packs are lazy-loaded, one per language, on first use.
- NFR-01.5 `cmd/api`/`cmd/worker` cold-start time is ≤ 200 ms (static-binary startup — no JVM/interpreter warm-up), verified in CI.

### NFR-02 — Usability & Accessibility
- NFR-02.1 Fully responsive from 375 px to 2560 px.
- NFR-02.2 Light and dark mode via a toggle, no page reload.
- NFR-02.3 WCAG 2.1 AA contrast ratios on all interactive elements.
- NFR-02.4 All core flows are fully keyboard-navigable.

### NFR-03 — Maintainability
- NFR-03.1 All seed data lives under `data/` as JSON/YAML, loaded via `cmd/seed` — never hand-written as Go struct literals in migrations.
- NFR-03.2 Every `CodeSample` carries a `VersionNote` so maintainers know when to refresh it.
- NFR-03.3 Go code follows the `internal/{domain,http,service,store,cards,integrity,jobs,config}` layering in `PLAN.md` §9; handlers stay thin, business logic lives in `service`.
- NFR-03.4 `sqlc generate` output is committed to the repo (not generated at build time only) so reviewers can diff generated-code changes.

### NFR-04 — Testability (TDD — see `user_stories+tests.md`)
- NFR-04.1 `internal/service` package test coverage ≥ 85% (`go test -cover`).
- NFR-04.2 Every HTTP handler has an `httptest`-based integration test.
- NFR-04.3 At least one Playwright end-to-end test per user story (US-01–US-19).
- NFR-04.4 Tests are written **before** implementation for every new feature (Red → Green → Refactor); a PR adding production code without a preceding failing test in the same PR fails review.

### NFR-05 — Portability
- NFR-05.1 The full stack (Go `api` + `worker` + PostgreSQL + Redis + Nginx) runs via a single `docker compose up`.
- NFR-05.2 `cmd/api`/`cmd/worker` production images are `FROM scratch` or `gcr.io/distroless/static`, built with `CGO_ENABLED=0`.
- NFR-05.3 Static frontend assets are served by Nginx directly — no external CDN dependency.

### NFR-06 — Internationalization Quality
- NFR-06.1 Language switching completes in under 150 ms perceived latency.
- NFR-06.2 No hardcoded user-visible strings exist in React components; all go through `react-i18next` keys.
- NFR-06.3 API responses serving translated content set `Content-Language: pl` or `Content-Language: en`.

### NFR-07 — Deployment Footprint
- NFR-07.1 The `cmd/api` production container image shall be ≤ 30 MB (a direct, measurable consequence of the static-binary/`scratch`-image approach in D-06, in contrast to the JVM-based sibling apps' typical 150–300 MB images) — verified by a CI size-check step.

---

## 5. Design Constraints & Technology Mandates

- C-01 The application backend shall be written entirely in Go 1.23 — `cmd/api` and `cmd/worker` alike. No other backend runtime language is used anywhere in the application itself.
- C-02 Code **samples** shown to users (Python, Java, Go, Scala, Lua) are educational content, not part of the application's own runtime; Java and Scala appear only as sample-code tabs.
- C-03 No third-party analytics, tracking scripts, or externally-hosted fonts/CDNs.
- C-04 Every page displays a disclaimer that content is educational and must be verified against official sources.
- C-05 The application makes no outbound calls to external threat-intel feeds at runtime; all data is seeded locally from files under `data/`.
- C-06 Every code sample carries a version annotation.
- C-07 Only Polish and English are supported; both `.po`-equivalent JSON files must be complete before a new translation key reaches production.
- C-08 `CornucopiaCard` records (all six decks) are never editable through any UI or API — not even an admin-JWT-gated one. Content changes only through a reviewed PR to the source YAML plus a hash-allowlist update.
- C-09 The Redis instance backing rate limiting/caching is never exposed on a public port.
- C-10 No JVM, Python interpreter, or other managed runtime is present inside the `cmd/api`/`cmd/worker` production container images.

---

## 6. Data Requirements

### DR-01 — Minimum Seeded Data
- DR-01.1 All 10 OWASP Web Top 10 (2021) entries with mitigations and 5-language code samples.
- DR-01.2 All 10 OWASP LLM Top 10 (2025) entries with mitigations and 5-language code samples.
- DR-01.3 Minimum 15 MITRE ATLAS techniques (≥ 5 tactics): AML.T0000, T0002, T0010, T0051, T0018, T0020, T0019, T0041, T0043, T0015, T0012, T0024, T0025, T0029, T0046.
- DR-01.4 All 10 OWASP Agentic AI Top 10 (2026) entries.
- DR-01.5 Minimum 20 CompTIA SecAI+/Security+ SY0-701 topics.
- DR-01.6 Full Cornucopia Website App Edition v3.0 cards (VE, AT, SM, AZ, CR, C suits).
- DR-01.7 Full Cornucopia Companion Edition v1.0 cards (LLM, FRE, DVO, BOT, CLD, AAI suits).
- DR-01.8 Full Cornucopia Mobile App Edition v1.1 cards (PC, AA, NS, RS, CRM, CM suits).
- DR-01.9 Full Cornucopia STRIDE EoP v5.0 cards (78 cards: SP, TA, RE, ID, DS, EP suits).
- DR-01.10 Full Cornucopia MLSec v1.0 cards (52 cards: EMR, EIR, EOR, EDR suits).
- DR-01.11 Full Digital-by-Default Harms v1.0 cards (SCO, ARC, AGE, TRU, POR, COR, WC suits), each with a reviewed Polish translation and a `CrossReference` row to OWASP A04:2021 Insecure Design.

### DR-02 — YAML Source-of-Truth
- DR-02.1 Cornucopia cards are maintained as YAML files in `data/cornucopia/`.
- DR-02.2 `internal/cards/loader.go` loads all six YAML files at `cmd/seed` run time and on `ReingestDeck` job execution; no live-reload from an HTTP-triggered path.
- DR-02.3 Every card row stores `ContentSHA256`, verified against `data/hashes.json` before being marked valid.

### DR-03 — Database Migrations
- DR-03.1 All schema changes are managed via `goose` migrations (`00001_*.sql` through `00010_*.sql`).
- DR-03.2 Migrations are idempotent and forward-only; no destructive `DROP` in non-test migrations.

---

## 7. Abuse Case Requirements

| ID | Threat | Requirement |
|---|---|---|
| AC-01 | SQL injection via `?q=` | `sqlc` parameterized query; `depguard` no-string-concat-into-SQL rule |
| AC-02 | XSS via admin card update | `bluemonday` (server) + DOMPurify (client) |
| AC-03 | CSRF | Stateless JWT; no session; CORS origin allowlist |
| AC-04 | JWT forgery | RS256 key pair; constant-time signature comparison |
| AC-05 | Bot scraping all card suits | Redis sliding-window rate limit 60 req/min; 429 + Retry-After |
| AC-06 | YAML card tampering | SHA-256 `internal/integrity.Verify`; ingestion aborts on mismatch |
| AC-07 | Fake OWASP reference injection via admin | `OwaspRef` typed constructor + allowlist |
| AC-08 | Fake MITRE T-code injection | `MitreRef` typed constructor + allowlist |
| AC-09 | Privilege escalation to `/stride-heatmap` | JWT role check middleware; 401 on missing/invalid token |
| AC-10 | XSS via LLM card description | `DOMPurify.sanitize()` on all `DescriptionPl`/`DescriptionEn` |
| AC-11 | i18n locale injection (`Accept-Language: ../../etc/passwd`) | Locale allowlist (`pl`/`en` only); fallback to `en`, never reflect raw input |
| AC-12 | Clickjacking `/stride-heatmap` | `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` |
| AC-13 | Supply-chain attack via Go module / npm dependency | `govulncheck` + `npm audit` + Trivy; fail on reachable HIGH/CRITICAL |
| AC-14 | Malicious River job payload | Typed `Args` struct + `go-playground/validator` at enqueue time |
| AC-15 | BotWarningModal bypass via direct API call | Server-side check independent of the modal: BOT-suit attack-demo endpoints require the same `bot_warning_ack`-equivalent flag echoed by the client, or return the card without its attack-demo body |
| AC-16 | Digital-by-Default Harms deck misread as a CVE-style severity list | `CardKind`/constructor-level enforcement — a `DESIGN_HARM` card cannot carry a `Severity` value at the Go type level; `DesignHarmBadge` is a distinct component from `SeverityBadge`, verified by a Vitest test |

---

## 8. Traceability Matrix (abbreviated)

| Requirement | User Story | Security Design Decision | Test Coverage |
|---|---|---|---|
| FR-01, FR-02 | US-01, US-02 | D-02 (`sqlc`) | US-01/US-02 Playwright |
| FR-05 | US-05 | D-04, D-07 | US-05 Playwright |
| FR-06 | US-06 | D-07 | US-06 Playwright |
| FR-07 | US-07 | D-07 | US-07 Playwright |
| FR-08 | US-08 | D-03 (JWT), D-08 | US-08 Playwright |
| FR-09 | US-09 | D-07 | US-09 Playwright |
| FR-10 | US-10 | D-07 | US-10 Playwright |
| FR-11 | US-11 | D-08 (rate limit) | US-11 Playwright |
| FR-12 | US-12 | D-07 | US-12 Playwright |
| FR-17 | US-17, US-18 | D-10 (River jobs) | US-17/US-18 Playwright, AC-14 |
| FR-18 | — (cross-cutting i18n) | D-11 | i18n-parity CI test |
| FR-19 | US-19 | D-07 (constructor enforcement) | US-19 Playwright, AC-16 |
| SR-02 | — | D-02 | AC-01 integration test |
| SR-03 | — | D-04 | AC-02, AC-10 integration test |
| SR-05 | — | D-08 | AC-05 integration test |
| SR-06 | — | D-05 | AC-06 integration test |
| SR-07 | — | D-07 | AC-07, AC-08 integration test |
| SR-08 | — | D-09 | Unit test: `yaml.UnmarshalStrict` rejects unknown fields |
| SR-09 | — | — | CI SAST/SCA gates |
| SR-13 | — | D-10 | AC-14 integration test |

---

## 9. Glossary

| Term | Definition |
|---|---|
| `sqlc` | Go code generator producing type-safe query functions from `.sql` files, checked at compile time against the schema |
| `chi` | Lightweight, idiomatic Go HTTP router used for `internal/http` |
| `pgx` | PostgreSQL driver and connection pool for Go |
| `bluemonday` | Pure-Go HTML sanitizer (allow-list based), used server-side instead of any JVM sanitizer library |
| `river` | Postgres-backed background job queue for Go |
| `internal/` | Go compiler-enforced package visibility convention — code outside the module cannot import it |
| Static binary | A compiled Go executable with no external runtime dependency (`CGO_ENABLED=0`), deployable in a `scratch` container |
| `govulncheck` | Official Go tool that reports known vulnerabilities reachable from the actual call graph, not just present in dependencies |
| Cornucopia | OWASP's card-game family for threat modeling (Website App, Mobile App, Companion editions) |
| STRIDE | Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege |
| MITRE ATLAS | Adversarial Threat Landscape for AI Systems |
| MASVS | OWASP Mobile Application Security Verification Standard |
| Digital-by-Default Harms deck | `dbd-cards-1.0-en.yaml` — models service-design harms (exclusion, opaque design) in public-sector digital services; mapped to OWASP A04:2021 Insecure Design, not a technical CVE-style vulnerability |
| `CardKind` | Field distinguishing `TECHNICAL_THREAT` cards (which have a `Severity`) from `DESIGN_HARM` cards (which do not) |
