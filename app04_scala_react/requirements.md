# ScalaShield 2026 — Requirements Specification

**Application:** app04_scala_react  
**Version:** 1.0  
**Date:** 2026-07-07  
**Status:** Baseline (maps to US-01–US-18, PLAN.md v1.0)

---

## 1. Scope

ScalaShield 2026 is a security reference and interactive learning platform. It presents threats, vulnerabilities, and mitigations from six major security frameworks alongside their Cornucopia card mappings. Countermeasure code samples are provided in five languages. The platform is localised in Polish and English. The backend is implemented in **Scala 3.3 LTS + ZIO 2 + ZIO HTTP**; the frontend in **React 18 + TypeScript**.

---

## 2. Functional Requirements

### FR-01 — Framework Catalogue (US-01)
- FR-01.1 The system shall display a catalogue of all supported security frameworks: OWASP Web Top 10 (2021), OWASP LLM Top 10 (2025), OWASP API Security Top 10, OWASP Agentic AI Top 10 (2026), MITRE ATLAS, CompTIA Security+ SY0-701, and CompTIA SecAI+ 2026.
- FR-01.2 Each framework entry shall show: name, version, official reference URL, brief description (PL/EN), and total threat count.
- FR-01.3 The `GET /api/v1/frameworks` endpoint shall return all frameworks as a JSON array.

### FR-02 — Threat Browser with Filtering (US-02)
- FR-02.1 The system shall list all threats with pagination (default page size 20, max 100).
- FR-02.2 Threats shall be filterable by: frameworkCode, severity (CRITICAL / HIGH / MEDIUM / LOW / INFO), STRIDE category (S/T/R/I/D/E), tag, free-text query `q` (max 200 characters), Cornucopia suit code, owaspRef, mitreRef.
- FR-02.3 Combining multiple filters shall apply all constraints with AND logic.
- FR-02.4 Each threat in the list view shall display: code (e.g. LLM01:2025), title, severity badge, STRIDE category chips, and framework name.

### FR-03 — Threat Detail with Mitigations and Code Samples (US-03)
- FR-03.1 The threat detail page shall show four tabs: Overview | Mitigations | Code | Cross-References.
- FR-03.2 Each mitigation shall display: title, description, type (PREVENTIVE / DETECTIVE / CORRECTIVE / COMPENSATING), effort, and effectiveness.
- FR-03.3 Code samples shall be grouped by language (Python / Java / Go / Scala / Lua), each with Attack Demo and Defense sub-tabs.
- FR-03.4 The `GET /api/v1/threats/:id` response shall include nested mitigations and a reference to available code samples.

### FR-04 — Cross-Framework Matrix (US-04)
- FR-04.1 The matrix page shall display a mapping table: OWASP Web Top 10 × OWASP LLM Top 10 × MITRE ATLAS × CompTIA SecAI+.
- FR-04.2 Each cell shall link to the relevant threat detail page.
- FR-04.3 `GET /api/v1/cross-references` shall return all cross-references; `GET /api/v1/cross-references?sourceCode=LLM01` shall filter by source code.

### FR-05 — STRIDE Heatmap (US-05)
- FR-05.1 An authenticated page (`/stride-heatmap`) shall render a Recharts heatmap showing STRIDE category coverage by system component.
- FR-05.2 Each cell shall encode severity via color (green → red scale).
- FR-05.3 The page shall require a valid JWT with role ADMIN or TRAINER; unauthenticated users shall be redirected to a login prompt.
- FR-05.4 `GET /api/v1/stride-heatmap` shall be protected by `authAspect`.

### FR-06 — Full-Text Search (US-06)
- FR-06.1 The system shall expose a global search bar (in the top navigation).
- FR-06.2 `GET /api/v1/search?q=<term>` shall perform full-text search over threat titles, descriptions, attack vectors, and card descriptions.
- FR-06.3 Results shall include highlighted fragments (via PostgreSQL `ts_headline`).
- FR-06.4 Search results shall be paginated; the query parameter `q` shall be limited to 200 characters.

### FR-07 — Export (US-07)
- FR-07.1 `GET /api/v1/export?format=csv&frameworkCode=<code>` shall return a UTF-8 CSV file of all threats and their mitigations for the specified framework.
- FR-07.2 `GET /api/v1/export?format=pdf&frameworkCode=<code>` shall return a PDF of the same content.
- FR-07.3 CSV export shall quote all fields to prevent formula injection.

### FR-08 — MITRE ATLAS Kill-Chain Timeline (US-08)
- FR-08.1 A dedicated page (or section within ThreatDetail) shall render a horizontal Recharts bar chart mapping MITRE ATLAS techniques to their kill-chain phases (Reconnaissance, Resource Development, Initial Access, Execution, Persistence, Evasion, Discovery, Collection, Exfiltration, Impact).
- FR-08.2 Clicking a bar shall navigate to the corresponding threat detail page.

### FR-09 — Scala Code Samples (US-09)
- FR-09.1 Every threat that has a code sample shall include a Scala tab in `CodeSamplePanel`.
- FR-09.2 Scala samples shall use ZIO HTTP 3.x, ZIO Quill, and ZIO 2 idioms where applicable.

### FR-10 — Lua Code Samples (US-10)
- FR-10.1 Every threat that has a code sample shall include a Lua tab in `CodeSamplePanel`.
- FR-10.2 Lua samples shall use OpenResty / NGINX Lua idioms where applicable (rate limiting, header injection prevention, WAF rules).

### FR-11 — i18n: Polish ↔ English (US-11)
- FR-11.1 The application shall support Polish (`pl`) and English (`en`) locales.
- FR-11.2 A `LanguageToggle` component in the navbar shall switch locales.
- FR-11.3 The selected locale shall be persisted in `localStorage` under key `ss_locale`.
- FR-11.4 Threat titles, descriptions, and attack-vector text shall be served in the requested locale via the `Accept-Language` header (allowlisted to `pl` or `en` only).
- FR-11.5 Code samples shall never be translated.
- FR-11.6 On locale switch, all visible text (navigation, badges, descriptions) shall update without a full page reload.

### FR-12 — Cornucopia: Frontend Security (FRE) (US-12)
- FR-12.1 A dedicated page (`/frameworks/frontend-security`) shall display all Cornucopia FRE cards from the **Companion Edition v1.0** (not the Website App Edition — `FRE` is a Companion-deck suit, per `__LLM_AI___companion-cards-1.0-en.yaml`).
- FR-12.2 Each card shall show: card ID, value, suit, description (PL/EN selectable), OWASP reference chips.
- FR-12.3 Cards shall be filterable by value and searchable by description keyword.

### FR-13 — Cornucopia: LLM Security (US-13)
- FR-13.1 A dedicated page (`/frameworks/llm-security`) shall display all Cornucopia LLM suit cards from the Companion Edition v1.0.
- FR-13.2 An interactive matrix page (`/matrix/llm`) shall map OWASP LLM Top 10 (2025) entries to corresponding Cornucopia LLM cards.
- FR-13.3 Cross-framework coverage gaps shall be visually indicated (empty cell with dash).

### FR-14 — Cornucopia: Agentic AI (AAI) (US-14)
- FR-14.1 A dedicated page (`/frameworks/agentic-ai`) shall display all Cornucopia AAI suit cards from the Companion Edition v1.0.
- FR-14.2 Cards with suit values K and A (AAIK, AAIQ) shall display an `AUTONOMY RISK` badge.
- FR-14.3 An interactive matrix page (`/matrix/agentic`) shall compare OWASP Agentic AI Top 10 (2026) with OWASP LLM Top 10 (2025) showing which LLM threats compose into which Agent threats.

### FR-15 — Cornucopia: STRIDE EoP (US-15)
- FR-15.1 A catalogue page (`/frameworks/stride`) shall display all 78 Cornucopia STRIDE EoP v5.0 cards, grouped by STRIDE category (6 suits × 13 cards).
- FR-15.2 The STRIDE heatmap (`/stride-heatmap`) shall require authentication and show system-component-level coverage (ref FR-05).
- FR-15.3 `GET /api/v1/threats/stride/categories` shall return the 6 categories with card counts.

### FR-16 — Cornucopia: ML Security (MLSec) (US-16)
- FR-16.1 A dedicated page (`/frameworks/ml-security`) shall display all 52 Cornucopia MLSec v1.0 cards (4 suits: EMR, EIR, EOR, EDR × 13 cards).
- FR-16.2 Cards shall display MITRE ATLAS reference chips (e.g. AML.T0051).
- FR-16.3 Cards that represent adversarial ML or model extraction risks shall display an `ML-SPECIFIC` badge.
- FR-16.4 `GET /api/v1/threats/mlsec/categories` shall return the 4 categories.

### FR-17 — Cornucopia: Mobile App Security (US-17)
- FR-17.1 A dedicated page (`/frameworks/mobile-security`) shall display all Cornucopia Mobile App Edition v1.1 cards (6 suits: PC, AA, NS, RS, CRM, CM × 13 cards).
- FR-17.2 A matrix page (`/matrix/mobile-vs-web`) shall compare MASVS 2.0 categories with OWASP Web Top 10 entries.
- FR-17.3 `GET /api/v1/threats/mobile/suits` shall return mobile suit definitions.

### FR-18 — Cornucopia: DevOps + Cloud + BOT Security (US-18)
- FR-18.1 A dedicated page (`/frameworks/devops-security`) shall contain:
  - A DVO section (OWASP Top 10 CI/CD Security Risks) with CICD-SEC chips.
  - A CLD section (Cloud, Companion Edition v1.0) covering over-permissive IAM roles, publicly exposed storage, and missing audit logging — with no dedicated OWASP Top 10 list to chip against, so cards instead cross-reference OWASP A05:2021 Security Misconfiguration and A01:2021 Broken Access Control.
  - A BOT section (OWASP Automated Threats) with OAT chips.
- FR-18.2 A `BotWarningModal` confirmation dialog shall appear before the user can view any BOT suit card. The acknowledgement shall be stored in `localStorage` under key `bot_warning_ack`.
- FR-18.3 DVO and CLD code examples shall show only pseudocode — no working pipeline exploits or real cloud misconfiguration templates.
- FR-18.4 `GET /api/v1/threats?suit=BOT` shall apply rate limiting (60 req/min per IP).
- FR-18.5 `GET /api/v1/threats?suit=CLD` shall return all Cloud suit cards with their `owaspRefs` populated (`A05:2021`, `A01:2021` as applicable).

### FR-19 — Cornucopia: Digital-by-Default Harms (US-19)
- FR-19.1 A dedicated page (`/frameworks/digital-harms`) shall display all Cornucopia `dbd-cards-1.0-en.yaml` cards, grouped by suit (SCO, ARC, AGE, TRU, POR).
- FR-19.2 Each card shall render with a `DesignHarmBadge`, never the `SeverityBadge` used for technical threats — this deck has no CRITICAL/HIGH/MEDIUM/LOW severity, only a design-harm category.
- FR-19.3 Each card shall display a `CrossReference` chip linking to OWASP A04:2021 Insecure Design, and, where the card concerns transparency of algorithms/criteria, to the CompTIA SecAI+ GRC/AI-Act topic list (DR-01.5).
- FR-19.4 The page shall display a disclaimer banner stating that this deck models *service-design harms in public-sector digital services* (source: `digitalbenefits.uk`), not exploitable technical vulnerabilities, and must not be read as a CVE-style severity ranking.
- FR-19.5 Cards shall be filterable by suit and searchable by description keyword, consistent with FR-12–FR-18.
- FR-19.6 Polish translations of all SCO/ARC/AGE/TRU/POR card descriptions shall be reviewed by a native Polish speaker before merge, following the same i18n gate as FR-11.

---

## 3. Security Requirements

### SR-01 — Authentication & Authorisation
- SR-01.1 JWT authentication shall be implemented as a ZIO HTTP `HandlerAspect` (`JwtMiddleware`).
- SR-01.2 Admin CRUD endpoints (`/api/v1/admin/*`) shall require the `ADMIN` role in the JWT `roles` claim.
- SR-01.3 The `/stride-heatmap` endpoint shall require `ADMIN` or `TRAINER` role.
- SR-01.4 Tokens shall be stateless (no server-side sessions); tokens shall expire after a configurable TTL (default: 1 hour for access tokens).
- SR-01.5 Login credentials shall be validated against bcrypt hashes (cost ≥ 12).

### SR-02 — SQL Injection Prevention
- SR-02.1 All database queries shall use ZIO Quill compile-time macro expansion.
- SR-02.2 No SQL string concatenation shall be permitted anywhere in the codebase (enforced by Scalafix rule).
- SR-02.3 The Wartremover `StringOps` rule shall flag any `+` string concatenation that touches query parameters.

### SR-03 — XSS Prevention
- SR-03.1 All Cornucopia card descriptions (`descriptionPl`, `descriptionEn`) rendered in the React UI shall be passed through `DOMPurify.sanitize()`.
- SR-03.2 `dangerouslySetInnerHTML` shall never be used without DOMPurify wrapping (enforced by custom ESLint rule `no-raw-html`).
- SR-03.3 Admin update endpoints (`PUT /api/v1/admin/threats/:id`) shall sanitize input via `SafeHtml.sanitize()` — a custom pure-Scala allow-list sanitizer (PLAN.md D-14) — before persisting. No Java-branded sanitization library shall be used.
- SR-03.4 `Content-Security-Policy` header shall set `default-src 'self'`; no `unsafe-inline` or `unsafe-eval`.

### SR-04 — Security Headers
- SR-04.1 `SecurityHeadersMiddleware` shall inject on every response: `Content-Security-Policy`, `Strict-Transport-Security` (max-age≥31536000; includeSubDomains), `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy`.
- SR-04.2 OWASP ZAP active scan shall report 0 findings with severity HIGH or CRITICAL.

### SR-05 — Rate Limiting
- SR-05.1 `RateLimitMiddleware` (ZIO STM token bucket) shall enforce a maximum of 60 requests/minute per source IP on all `/api/v1/*` routes.
- SR-05.2 When the bucket is exhausted the server shall return HTTP 429 with `Retry-After` header set to the number of seconds until refill.
- SR-05.3 The `/api/v1/search` endpoint shall additionally enforce a query-length hard cap of 200 characters, returning HTTP 422 for longer inputs.

### SR-06 — Content Integrity
- SR-06.1 `ContentIntegrityVerifier` shall run as a ZIO `ZLayer` at application startup.
- SR-06.2 If any YAML card file's SHA-256 hash does not match the value in `data/hashes.json`, the layer shall call `ZIO.die(ContentIntegrityException(...))`, preventing the HTTP server from starting.
- SR-06.3 `data/hashes.json` shall be regenerated by a CI automation job after every merge to main.
- SR-06.4 `GET /api/v1/metrics/content-integrity` shall expose verification status (authenticated endpoint).

### SR-07 — Reference ID Allowlists (Opaque Type Validators)
- SR-07.1 `OwaspRefValidator` shall accept only identifiers present in the pre-loaded `Set[OwaspRef]` (sourced from `data/ref-allowlists.json`).
- SR-07.2 `MitreAtlasRefValidator` shall accept only T-codes in `data/mitre-atlas-allowlist.json`.
- SR-07.3 `MavsRefValidator`, `CicdSecRefValidator`, `OatRefValidator` shall apply equivalent allowlists.
- SR-07.4 Any admin CRUD request supplying an unknown reference ID shall be rejected with HTTP 422 (`InvalidRefError`).

### SR-08 — Opaque Types for Security-Sensitive Identifiers
- SR-08.1 The following opaque types shall be declared in `OpaqueTypes.scala`: `ThreatCode`, `CardId`, `SuitCode`, `OwaspRef`, `MitreRef`.
- SR-08.2 Route handlers shall never accept a raw `String` where an opaque type is required.
- SR-08.3 Smart constructors shall perform format validation; invalid input returns `ZIO.fail(ValidationError(...))`.

### SR-09 — SAST / SCA
- SR-09.1 Wartremover rules active in CI: `Null`, `AsInstanceOf`, `Return`, `OptionPartial`, `EitherProjectionPartial`.
- SR-09.2 Scapegoat shall fail the build on any critical code smell (empty catch, null literal, unsafe `asInstanceOf`).
- SR-09.3 Scalafix rules: `DisableSyntax.noFinalVal`, banned import list, enforce `ZIO.fail` over `throw`.
- SR-09.4 `sbt dependencyCheck` shall fail the build on any dependency with CVSS score ≥ 7.0.
- SR-09.5 `npm audit --audit-level=high` shall fail the frontend build on any HIGH or CRITICAL npm advisory.
- SR-09.6 Trivy container scan shall fail on any HIGH or CRITICAL vulnerability in the Docker images.

### SR-10 — CSRF / CORS
- SR-10.1 There are no server-side sessions, so classical CSRF does not apply. The CORS `CorsMiddleware` shall allowlist only the configured frontend origin.
- SR-10.2 Preflight OPTIONS requests shall be handled by `CorsMiddleware` and never leak sensitive headers.

### SR-11 — Code Sample Safety
- SR-11.1 Attack Demo code snippets shall be stored in the database and served as plain text; they shall never be executed server-side.
- SR-11.2 DVO (DevOps/CI-CD) code examples shall contain pseudocode only — no working pipeline exploits that could be copied and deployed.
- SR-11.3 `BotWarningModal` shall appear before any BOT card attack demo is shown; `bot_warning_ack` stored in localStorage.

### SR-12 — i18n Security
- SR-12.1 The `Accept-Language` header is allowlisted to `pl` and `en`; any other value falls back to `en`.
- SR-12.2 Locale values from `localStorage` shall be validated against the allowlist before use.
- SR-12.3 i18n translation values shall contain only plain text — no HTML, no interpolated variables from user input.

### SR-13 — SVG Injection Prevention
- SR-13.1 AAI agent architecture diagrams shall be generated server-side and returned as `<img src="data:image/svg+xml;base64,...">`.
- SR-13.2 Any SVG rendered inline in the React UI shall be passed through DOMPurify configured to strip `<script>` and `on*` attributes.

---

## 4. Non-Functional Requirements

### NFR-01 — Performance
- NFR-01.1 API endpoints shall return responses in ≤ 200 ms (p95) under a load of 50 concurrent users.
- NFR-01.2 PostgreSQL full-text search (`tsvector` indexed) shall return results in ≤ 300 ms (p95).
- NFR-01.3 The production frontend bundle initial chunk shall be ≤ 600 KB (gzip compressed).
- NFR-01.4 Shiki language packs shall be lazy-loaded (one per language, loaded on first use).
- NFR-01.5 Lighthouse mobile Performance score shall be ≥ 85 in production build.

### NFR-02 — Accessibility
- NFR-02.1 The application shall achieve WCAG 2.1 Level AA compliance.
- NFR-02.2 `axe-playwright` accessibility checks shall report 0 Critical violations in the E2E suite.
- NFR-02.3 Lighthouse Accessibility score shall be ≥ 90.

### NFR-03 — Scalability
- NFR-03.1 The ZIO fiber-based HTTP server shall handle ≥ 200 concurrent connections without degradation.
- NFR-03.2 Database connection pool (HikariCP) shall be configurable via environment variables.

### NFR-04 — Maintainability
- NFR-04.1 Backend code coverage shall be ≥ 80% (ZIO Test line coverage).
- NFR-04.2 Frontend code coverage shall be ≥ 80% (Vitest).
- NFR-04.3 Scalafix and ESLint shall be run on every pull request; violations block merge.

### NFR-05 — Portability / Deployment
- NFR-05.1 The application shall run in Docker Compose with a single `docker compose up` command (PostgreSQL 16, Redis 7, backend, frontend, Nginx).
- NFR-05.2 A multi-stage Dockerfile shall produce a JRE 21-slim runtime image ≤ 250 MB.
- NFR-05.3 All secrets (DB password, JWT secret, Redis password) shall be passed via Docker Secrets or environment variables; no secrets in source code or Docker layers.

### NFR-06 — Monitoring & Observability
- NFR-06.1 Prometheus metrics shall be exposed at `/metrics` (or via a separate port).
- NFR-06.2 Grafana + Loki alert rules shall be configured: SEC-007 (rate limit burst), SEC-008 (content-integrity failure), SEC-009 (admin CRUD from unexpected IP).
- NFR-06.3 ZIO HTTP access logs shall be structured JSON (for Loki ingestion).

### NFR-07 — Internationalization
- NFR-07.1 The CI pipeline shall run an `i18n-parity.spec.ts` Vitest test that fails if any key present in `pl/translation.json` is missing from `en/translation.json` or vice versa.
- NFR-07.2 No hardcoded Polish or English strings shall appear in React component source files; all UI text shall reference `t('key')`.

---

## 5. Design Constraints & Technology Mandates

| Constraint | Detail |
|---|---|
| Backend language | Scala 3.3 LTS (no Scala 2 cross-build required) |
| HTTP framework | ZIO HTTP 3.x (no Play Framework, no Akka HTTP) |
| Effect system | ZIO 2 throughout; no Cats Effect |
| Database ORM | ZIO Quill (compile-time SQL); no plain JDBC strings |
| Database | PostgreSQL 16 |
| Cache / rate limit store | Redis 7 via ZIO Redis |
| Build tool | sbt 1.9.x |
| Frontend framework | React 18 with hooks; no class components |
| Frontend language | TypeScript 5.x |
| Frontend build | Vite 5.x |
| State management | Zustand (no Redux) |
| Routing | React Router v6 |
| UI library | Shadcn/UI + Tailwind CSS |
| Syntax highlight | Shiki (lazy-loaded) |
| DOM sanitization | DOMPurify 3.x |
| i18n | react-i18next |
| Charts | Recharts + D3.js |
| Validation (frontend) | Zod |
| HTTP client | fetch + TanStack Query v5 |

---

## 6. Data Requirements

### DR-01 — Minimum Seeded Data
- DR-01.1 All 10 OWASP Web Top 10 (2021) entries with mitigations and 5-language code samples.
- DR-01.2 All 10 OWASP LLM Top 10 (2025) entries with mitigations and 5-language code samples.
- DR-01.3 Minimum 15 MITRE ATLAS techniques including: AML.T0010, AML.T0011, AML.T0014, AML.T0020, AML.T0024, AML.T0029, AML.T0043, AML.T0044, AML.T0051.
- DR-01.4 All 10 OWASP Agentic AI Top 10 (2026) entries.
- DR-01.5 Minimum 20 CompTIA SecAI+ / Security+ SY0-701 topics (including: Prompt Injection, Data Poisoning, Model Theft, Adversarial ML, Deepfakes, AI Red Teaming, Zero Trust, NIST AI RMF).
- DR-01.6 Full Cornucopia Website App Edition v3.0 cards (VE, AT, SM, AZ, CR, C suits).
- DR-01.7 Full Cornucopia Companion Edition v1.0 cards (LLM, FRE, DVO, BOT, CLD, AAI suits).
- DR-01.8 Full Cornucopia Mobile App Edition v1.1 cards (PC, AA, NS, RS, CRM, CM suits).
- DR-01.9 Full Cornucopia STRIDE EoP v5.0 cards (78 cards: SP, TA, RE, ID, DS, EP suits).
- DR-01.10 Full Cornucopia MLSec v1.0 cards (52 cards: EMR, EIR, EOR, EDR suits).
- DR-01.11 Full Digital-by-Default Harms v1.0 cards (SCO, ARC, AGE, TRU, POR, COR, WC suits), each with a reviewed Polish translation and a `CrossReference` row to OWASP A04:2021 Insecure Design.

### DR-02 — YAML Source-of-Truth
- DR-02.1 Cornucopia cards shall be maintained as YAML files in `data/cornucopia/`.
- DR-02.2 Each YAML file shall conform to the JSON Schema defined in `data/cornucopia-schema.json`.
- DR-02.3 `YamlCardLoader` (ZIO service) shall load YAML files at application startup; no live-reload.

### DR-03 — Database Migrations
- DR-03.1 All schema changes shall be managed via Flyway migrations (`V1__*.sql` through `V10__*.sql`).
- DR-03.2 Migrations shall be idempotent and repeatable. No destructive `DROP` statements in non-test migrations.

---

## 7. Abuse Case Requirements

| ID | Threat | Requirement |
|---|---|---|
| AC-01 | SQL injection via `?q=` | ZIO Quill parameterised query; Scalafix no-concat rule |
| AC-02 | XSS via admin card update | `SafeHtml` pure-Scala sanitizer (server) + DOMPurify (client) |
| AC-03 | CSRF | Stateless JWT; `SameSite=Strict` cookie; no session |
| AC-04 | JWT forgery | RS256 key pair; Wartremover prevents `null` signing key |
| AC-05 | Bot scraping all card suits | ZIO STM rate limit 60 req/min; 429 + Retry-After |
| AC-06 | YAML card tampering | SHA-256 ContentIntegrityVerifier; app refuses to start |
| AC-07 | Fake OWASP reference injection via admin | OwaspRefValidator opaque type + Set allowlist |
| AC-08 | Fake MITRE T-code injection | MitreAtlasRefValidator opaque type + allowlist |
| AC-09 | Privilege escalation to /stride-heatmap | authAspect JWT role check; 401 on missing/invalid token |
| AC-10 | XSS via LLM card description | DOMPurify.sanitize() on all descriptionPl/descriptionEn |
| AC-11 | i18n locale injection (`Accept-Language: ../../etc/passwd`) | Locale allowlist (pl / en only); reject with 422 |
| AC-12 | Clickjacking /stride-heatmap | X-Frame-Options: DENY + CSP frame-ancestors 'none' |
| AC-13 | Supply-chain attack via npm/sbt dependency | sbt-dependency-check + npm audit + Trivy; fail on CVSS ≥ 7 |
| AC-14 | SVG script injection in AAI diagrams | Server-side SVG generation; DOMPurify strips `<script>` |
| AC-15 | Prompt injection via BotWarningModal content | BotWarningModal text is hardcoded i18n key; not from API |
| AC-16 | Digital-by-Default Harms deck misread as a CVE-style severity list | `DesignHarmBadge` component is a distinct React component from `SeverityBadge` — no shared props allow a `dbd` card to render a CRITICAL/HIGH color; enforced by a component-level Vitest test |

---

## 8. Traceability Matrix (abbreviated)

| Requirement | User Story | Security Design Decision | Test Coverage |
|---|---|---|---|
| FR-01, FR-02 | US-01, US-02 | D-02 (Quill SQL) | US-01 Playwright, US-02 Playwright |
| FR-11 | US-11 | D-10 (i18n security) | i18n-parity.spec.ts, US-11 Playwright |
| FR-12 | US-12 | D-04, D-07 | US-12 Playwright |
| FR-13 | US-13 | D-06, D-07 | US-13 Playwright |
| FR-14 | US-14 | D-04, D-07 | US-14 Playwright |
| FR-15 | US-15 | D-03 (JWT), D-08 | US-15 Playwright |
| FR-16 | US-16 | D-07, D-12 | US-16 Playwright |
| FR-17 | US-17 | D-07 | US-17 Playwright |
| FR-18 | US-18 | D-08 (rate limit), D-11 | US-18 Playwright |
| FR-19 | US-19 | D-10 (i18n review gate), D-06 | US-19 Playwright, AC-16 component test |
| SR-02 | — | D-02 | AC-01 integration test |
| SR-03 | — | D-05 | AC-02, AC-10 integration test |
| SR-05 | — | D-08 | AC-05 integration test |
| SR-06 | — | D-04 | AC-06 integration test |
| SR-07 | — | D-07, D-12 | AC-07, AC-08 integration test |
| SR-08 | — | D-12 | Scalafix compile-time |
| SR-09 | — | D-13 | CI SAST gates |
