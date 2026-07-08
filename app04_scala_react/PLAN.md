# ScalaShield 2026 — Application Development Plan

**Version:** 1.0  
**Date:** 2026-07-07  
**Status:** Living document — updated after each sprint planning session

---

## 1. Project Overview

**Name:** ScalaShield 2026  
**Purpose:** An interactive security reference and learning platform that maps threats, vulnerabilities, and mitigations across six major frameworks — OWASP Web Top 10 (2021), OWASP LLM Top 10 (2025), OWASP API Security Top 10, OWASP Agentic AI Top 10 (2026), MITRE ATLAS (AI/ML adversarial techniques), and CompTIA Security+ SY0-701 / SecAI+ 2026. Each threat is presented with countermeasure sample code in five languages: Python, Java (Spring Boot), Go, Scala, and Lua.

**Cornucopia extension:** The platform covers the full OWASP Cornucopia card catalogue — Website App Edition v3.0, Companion Edition v1.0 (LLM, AAI, FRE, DVO, BOT, CLD suits), Mobile App Edition v1.1, Microsoft STRIDE Elevation of Privilege v5.0, and Elevation of MLSec v1.0.

**UI languages:** Polish (default) and English — switch persisted in `localStorage` under key `ss_locale`.

**Key differentiator:** ScalaShield uses **Scala 3.3 LTS + ZIO 2 + ZIO HTTP** for the backend — a purely functional, effect-typed stack with compile-time SQL safety (ZIO Quill), ZIO STM-based rate limiting, and opaque types for security-sensitive identifiers. The frontend is **React 18 + TypeScript + Vite** (same patterns as SecureVision/app01_react).

---

## 2. Technology Stack

### Backend
| Layer | Technology | Version |
|---|---|---|
| Language | Scala | 3.3 LTS |
| HTTP framework | ZIO HTTP | 3.x |
| Effect system | ZIO 2 | 2.x |
| Database ORM | ZIO Quill | (compile-time SQL macros) |
| Database | PostgreSQL 16 | via HikariCP |
| Cache | Redis 7 | via ZIO Redis |
| Auth | ZIO HTTP JWT middleware (`jwt-scala`, RS256) | — |
| Build | sbt | 1.9.x |
| API docs | Tapir + Swagger UI | — |
| DB migrations | Flyway | — |
| Testing | ZIO Test + sttp | — |
| Rate limiting | Custom ZIO STM token bucket middleware | — |
| Input sanitization | `SafeHtml` — custom pure-Scala allow-list sanitizer (D-14) | — |
| Integrity checks | SHA-256 via the JVM `MessageDigest` API, wrapped in a small Scala `Hashing` helper | — |
| SAST | Scalafix + Wartremover + Scapegoat | — |
| SCA | sbt-dependency-check | — |

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
| Charts / Diagrams | Recharts + D3.js | — |
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
| Container | Docker + Docker Compose |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Loki + Prometheus |
| Secrets | Docker Secrets / GitHub Secrets |
| SAST backend | Scalafix + Wartremover + Scapegoat |
| SAST frontend | eslint-plugin-security |
| DAST | OWASP ZAP |
| SCA | sbt-dependency-check + npm audit + Trivy |

---

## 3. High-Level Architecture

```
Browser (React SPA)
        │
        │  HTTPS
        ▼
  Nginx (port 443)
   ├── /api/v1/*  ─────► ZIO HTTP Server (port 8080)
   │                       ├── FrameworkRoutes
   │                       ├── ThreatRoutes          ← threats + Cornucopia cards
   │                       ├── CardSuitRoutes        ← suit browsers (FRE/LLM/AAI…)
   │                       ├── MatrixRoutes          ← cross-framework matrices
   │                       ├── SearchRoutes
   │                       ├── ExportRoutes          ← CSV/PDF
   │                       └── AdminRoutes           ← JWT-gated CRUD
   │                       Middleware stack:
   │                         CorsMiddleware → SecurityHeadersMiddleware
   │                         → RateLimitMiddleware (ZIO STM)
   │                         → JwtMiddleware (HandlerAspect)
   │                         → ErrorHandler
   │
   └── /*         ─────► React SPA bundle (Vite)
                           ├── pages/
                           │   ├── Dashboard
                           │   ├── FrameworkBrowser / FrameworkDetail
                           │   ├── ThreatBrowser / ThreatDetail
                           │   ├── Card suit pages (7 pages, US-12–US-18)
                           │   ├── Matrix pages (4 pages)
                           │   ├── StrideHeatmap (auth required)
                           │   ├── GlobalSearch
                           │   └── About
                           └── components/
                               ├── ThreatCard / CornucopiaCard
                               ├── CodeSamplePanel (Shiki, 5 languages)
                               ├── BotWarningModal
                               ├── StrideHeatmap (Recharts)
                               ├── MatrixTable
                               └── LanguageToggle (react-i18next)

PostgreSQL 16  ◄── ZIO Quill (compile-time SQL)
Redis 7        ◄── ZIO Redis (cache + rate limit counters)
```

---

## 4. Architecture Design Decisions

### D-01 — ZIO Effect System throughout the backend
All backend effects wrapped in `ZIO[R, E, A]`. Side effects banned outside the ZIO boundary. No bare `try/catch` blocks except at the top-level `ZIOApp` bootstrap. Failures are typed (`AppError` sealed trait), enabling exhaustive pattern matching and preventing silent swallowing.

### D-02 — Type-safe SQL via ZIO Quill
ZIO Quill uses compile-time macro expansion to verify SQL queries against the database schema. No string concatenation in queries — the compiler rejects them. Type inference prevents the entire SQL Injection class of bugs at compile time. This replaces Spring Data JPA's runtime query parsing.

### D-03 — ZIO HTTP JWT Middleware (stateless)
JWT auth implemented as a ZIO HTTP `HandlerAspect`. Stateless — no server-side sessions → no CSRF surface. Token validation and role extraction happen in the middleware layer before route handlers execute. Admin routes protected by `adminAspect`, authenticated routes by `authAspect`.

### D-04 — ContentIntegrityVerifier as ZIO Layer (fail-secure)
YAML card file integrity checking implemented as a ZIO `ZLayer` that is composed into the application graph at startup. If any SHA-256 hash mismatches `data/hashes.json`, the layer calls `ZIO.die(ContentIntegrityException(...))`. Since the HTTP server depends on this layer, it cannot start — fail-secure by construction, not by convention.

### D-05 — DOMPurify client-side sanitization
Same as app01_react: all card descriptions (`descriptionPl`, `descriptionEn`) passed through `DOMPurify.sanitize()` before React renders them. Backend stores plain text; frontend sanitizes at render time.

### D-06 — YAML cards loaded via ZIO Scope (immutable after startup)
`YamlCardLoader` implemented as a `ZIO.acquireRelease` scoped resource. Cards loaded once at startup, stored in a `ZIO Ref[Map[CardId, CornucopiaCard]]`. After startup, `Ref` is read-only (no `Ref.update` in request handlers). File-system reads are blocked after initialization.

### D-07 — Opaque types for OWASP/MITRE reference IDs + Set[T] allowlists
Reference IDs modeled as opaque types (`opaque type OwaspRef = String`, `opaque type MitreRef = String`). Construction goes through smart constructors that check membership in a pre-loaded `Set[OwaspRef]`. Illegal IDs return `ZIO.fail(InvalidRefError(...))` — rejected with HTTP 422. Prevents content poisoning via admin CRUD.

### D-08 — Rate limiting via ZIO STM token bucket
Rate limiting implemented as a `ZIO HTTP` middleware using ZIO STM (Software Transactional Memory). Each IP gets a `TRef[TokenBucket]`. STM transactions are atomic and composable — no race conditions possible. Returns HTTP 429 with `Retry-After` when bucket exhausted. Replaces Java's Bucket4j with a pure Scala equivalent.

### D-09 — Zustand for frontend state (same as app01_react)
Same frontend state architecture: Zustand slices for `frameworks`, `threats`, `cardSuits`, `search`, `ui` (darkMode, locale). No Redux boilerplate.

### D-10 — react-i18next with plain-text-only i18n values
`pl.json` / `en.json` values contain only plain text. HTML interpolation in translations disabled. `ss_locale` key in `localStorage`. `Accept-Language` header injected by Axios/fetch interceptor (allowlisted to `pl` or `en` only).

### D-11 — Dogfooding: app teaching BOT attacks deploys its own BOT defenses
The platform that teaches OAT-011 scraping must itself be protected by rate limiting (D-08) and `BotWarningModal`. Demonstrated to users as a live example of the principle.

### D-12 — Scala 3 opaque types for security-sensitive strings
Typed aliases prevent accidental mixing of user input with validated domain identifiers:
```scala
opaque type ThreatCode  = String
opaque type CardId      = String
opaque type SuitCode    = String
opaque type OwaspRef    = String
opaque type MitreRef    = String
```
Raw `String` from user input cannot be used where a `ThreatCode` is expected without going through a smart constructor that validates the format.

### D-13 — Scalafix + Wartremover + Scapegoat (compile-time SAST)
- **Wartremover**: enforces null-safety (`wartremover.wart.Null`), bans `Any.asInstanceOf`, `return` statements, `Option.get` (partial function)
- **Scapegoat**: static analysis for 120+ code smells including unsafe `toString` calls, empty `catch` blocks, string concatenation in loops
- **Scalafix**: custom rules for banned imports, enforced error handling patterns
All rules fail the build — CI enforces zero violations.

### D-14 — `SafeHtml`: a custom pure-Scala allow-list HTML sanitizer
The backend never depends on a Java-branded sanitizer library. `SafeHtml.sanitize(raw: String): String` is a small, dependency-free Scala module: it parses the input with `scala.xml.pull.XMLEventReader`, keeps only an explicit allow-list of tags (`b`, `i`, `code`, `pre`, `a`) and attributes (`href`, restricted to `http(s)://` schemes), and drops everything else — including all `on*` event attributes and `javascript:`/`data:` URLs. `PUT /api/v1/admin/threats/:id` runs every free-text field through `SafeHtml.sanitize` before persisting; the React frontend additionally runs `DOMPurify.sanitize()` at render time (D-05), giving defense in depth without ever pulling in a Java library. The unit test suite includes property-based tests (ZIO Test + a small allow-list fuzzer) asserting that no `<script>`, `on\w+=`, or `javascript:` substring ever survives sanitization.

### D-15 — `jwt-scala` instead of a Java JWT library
JWT signing/verification uses `jwt-scala` (the `pdi.jwt` package) rather than `jjwt` or `java-jwt` — both JVM libraries with a "Java" identity in the ecosystem. `jwt-scala` exposes a Scala-idiomatic `Try`/`Either`-based API that composes directly with `ZIO.fromTry`, keeping the entire auth path in native Scala types (`JwtClaim`, `Either[JwtException, ...]`) with no Java-flavored exception types crossing into application code.

---

## 5. Data Model

### 5.1 Enumerations (Scala 3 enums)

```scala
enum Severity derives Codec.AsObject:
  case CRITICAL, HIGH, MEDIUM, LOW, INFO

enum StrideCategory: case S, T, R, I, D, E

enum SampleType: case ATTACK_DEMO, DEFENSE

enum CodeLanguage: case PYTHON, JAVA, GO, SCALA, LUA

enum MitigationType: case PREVENTIVE, DETECTIVE, CORRECTIVE, COMPENSATING

enum Effort: case LOW, MEDIUM, HIGH

enum Effectiveness: case PARTIAL, SIGNIFICANT, FULL

enum RelationshipType: case EQUIVALENT, RELATED, PARENT_CHILD, MAPS_TO
```

### 5.2 Framework
```scala
case class Framework(
  id:           UUID,
  code:         String,  // "OWASP_WEB", "OWASP_LLM", "STRIDE_EOP", "MLSEC"
  name:         String,
  version:      String,
  description:  String,
  referenceUrl: String
)
```

### 5.3 Threat
```scala
case class Threat(
  id:            UUID,
  frameworkId:   UUID,
  code:          String,             // "LLM01:2025", "A01:2021", "AML.T0051"
  title:         String,
  severity:      Severity,
  category:      String,
  description:   String,
  attackVector:  String,
  attackSurface: String,
  stride:        Set[StrideCategory],
  cveReferences: List[String],
  tags:          List[String]
)
```

### 5.4 ThreatTranslation  *(i18n — US-11)*
```scala
case class ThreatTranslation(
  id:           UUID,
  threatId:     UUID,
  locale:       String,  // "pl", "en"
  title:        String,
  description:  String,
  attackVector: String,
  category:     String
)
```

### 5.5 CornucopiaCard  *(US-12–US-18)*
```scala
case class CornucopiaCard(
  id:            UUID,
  cardId:        String,       // "FRE4", "LLMX", "EPK", "EDRK", "NSX"
  suitCode:      String,       // "FRE", "LLM", "AAI", "DVO", "BOT", "CLD",
                               //  "VE", "AT", "SM", "AZ", "CR",
                               //  "PC", "AA", "NS", "RS", "CRM", "CM",
                               //  "SP", "TA", "RE", "ID", "DS", "EP",
                               //  "EMR", "EIR", "EOR", "EDR",
                               //  "SCO", "ARC", "AGE", "TRU", "POR", "COR", "WC"
  suitName:      String,
  edition:       String,       // "companion", "webapp", "mobileapp", "eop", "mlsec", "dbd"
  value:         String,       // "2"–"10", "J", "Q", "K", "A"
  isCritical:    Boolean,      // true for J, Q, K
  descriptionEn: String,
  descriptionPl: String,
  owaspRefs:     List[String],
  mitreRefs:     List[String],
  mavsRefs:      List[String],
  cicdSecRefs:   List[String],
  oatRefs:       List[String],
  agentAiRefs:   List[String],
  contentHash:   String        // SHA-256 of descriptionEn
)
```

### 5.6 Mitigation
```scala
case class Mitigation(
  id:                   UUID,
  threatId:             UUID,
  title:                String,
  description:          String,
  mitigationType:       MitigationType,
  implementationEffort: Effort,
  effectiveness:        Effectiveness
)
```

### 5.7 CodeSample
```scala
case class CodeSample(
  id:            UUID,
  mitigationId:  UUID,
  language:      CodeLanguage,
  sampleType:    SampleType,
  title:         String,
  description:   String,
  codeSnippet:   String,   // educational snippet only, never executed server-side
  frameworkHint: String,   // "ZIO HTTP 3.x", "FastAPI 0.110", "Gin 1.9"
  version:       String
)
```

### 5.8 CrossReference
```scala
case class CrossReference(
  id:               UUID,
  sourceThreatId:   UUID,
  targetThreatId:   UUID,
  relationshipType: RelationshipType,
  description:      String
)
```

### 5.9 ContentHash  *(YAML integrity)*
```scala
case class ContentHash(
  id:         UUID,
  fileName:   String,
  sha256Hash: String,
  verifiedAt: Instant,
  isValid:    Boolean
)
```

### 5.10 AppError (sealed trait hierarchy)
```scala
sealed trait AppError
case class NotFoundError(resource: String, id: String)  extends AppError
case class InvalidRefError(refType: String, value: String) extends AppError
case class AuthenticationError(message: String)           extends AppError
case class AuthorizationError(role: String)               extends AppError
case class ContentIntegrityException(fileName: String)    extends AppError
case class DatabaseError(cause: Throwable)                extends AppError
case class ValidationError(field: String, message: String) extends AppError
```

---

## 6. Development Phases

### Phase 1 — Foundation (Sprints 1–2, Weeks 1–4)
Pokrycie: US-01

- [ ] `sbt new scala/scala3.g8` + ZIO HTTP dependency setup
- [ ] `build.sbt`: ZIO 2, ZIO HTTP, ZIO Quill, ZIO Redis, Flyway, Tapir, sbt-assembly
- [ ] `plugins.sbt`: sbt-dependency-check, scalafix, wartremover, sbt-scapegoat
- [ ] `Main.scala`: `ZIOApp` bootstrap — compose all ZLayers
- [ ] Docker Compose: PostgreSQL 16 + Redis 7 + backend (8080) + frontend + Nginx (443)
- [ ] Flyway migrations V1–V8 (all 8 entities)
- [ ] Seed data: OWASP Web Top 10, LLM Top 10, MITRE ATLAS, CompTIA SecAI+
- [ ] `GET /api/v1/frameworks` (ZIO HTTP + ZIO Quill), `GET /api/v1/threats` (paginated)
- [ ] `SecurityHeadersMiddleware` — CSP, HSTS, X-Frame-Options, X-Content-Type-Options
- [ ] React 18 frontend scaffold: `npm create vite@latest frontend -- --template react-ts`
- [ ] Shadcn/UI setup, Tailwind CSS, React Router v6, Zustand stores

**Security checkpoint:** D-13 (Scalafix + Wartremover) passes; no `null` literals in codebase; `SecurityHeadersMiddleware` active.

### Phase 2 — Core API + React Threat Browser (Sprints 3–4, Weeks 5–8)
Pokrycie: US-02, US-03, US-04

- [ ] `GET /api/v1/threats` — filters: frameworkCode, severity, stride, category, tag, q, suit, owaspRef, mitreRef (all via ZIO Quill dynamic queries)
- [ ] `GET /api/v1/threats/:id` — nested mitigations + code samples
- [ ] `GET /api/v1/cross-references` — cross-framework mapping table
- [ ] React `ThreatBrowserPage` — filter panel (Shadcn Select, CheckboxGroup), table/card view
- [ ] React `ThreatDetailPage` — tabs: Przegląd | Mitigacje | Kod | Powiązania
- [ ] React `ThreatCard` component — severity color band, STRIDE badges
- [ ] React `MatrixPage` — OWASP ↔ MITRE ATLAS ↔ CompTIA mapping table

**Security checkpoint:** D-02 (ZIO Quill compile-time SQL verified); ZIO Quill rejects string-concat queries at compile time; `AppError` sealed hierarchy exhaustively handled.

### Phase 3 — Code Samples + MITRE ATLAS Timeline (Sprints 5–6, Weeks 9–12)
Pokrycie: US-08, US-09, US-10

- [ ] `CodeSamplePanel` — Shiki syntax highlight, lazy-loaded per language
- [ ] Attack Demo tab: red border + `PODATNY` badge; `BotWarningModal` before clipboard copy
- [ ] MITRE ATLAS Kill-Chain timeline (Recharts horizontal bar)
- [ ] `CoverageHeatmap` — Recharts heatmap, STRIDE coverage per framework
- [ ] Tag-based navigation (tag cloud)

**Security checkpoint:** D-05 (DOMPurify on all card descriptions); ATTACK_DEMO code never executed server-side; `BotWarningModal` blocks clipboard without confirmation.

### Phase 4 — Advanced Features (Sprints 6–7, Weeks 11–14)
Pokrycie: US-05, US-06, US-07

- [ ] PostgreSQL full-text search: `tsvector` index on title + description + attackVector
- [ ] `GET /api/v1/search?q=` — paginated, highlighted fragments via `ts_headline`
- [ ] `GlobalSearchBar` in top nav (React Query debounced)
- [ ] Export CSV / PDF: `GET /api/v1/export?format=csv&frameworkCode=LLM`
- [ ] Dark mode toggle (Tailwind `dark:` classes, Zustand `uiStore`)
- [ ] Bookmarks / favourites (localStorage service)

**Security checkpoint:** Query length limit 200 chars in ZIO HTTP route validation; CSV injection prevention (quoted fields); rate limit on `/api/v1/search`.

### Phase 5 — i18n Polish ↔ English (Sprint 8, Weeks 15–16)
Pokrycie: US-11

- [ ] `ThreatTranslation` entity — Flyway V9
- [ ] `LocalizationService` — ZIO service, `Accept-Language` header → locale selection
- [ ] React: `react-i18next` with `public/locales/pl/translation.json` and `en/translation.json`
- [ ] `LanguageToggle` component (Shadcn ToggleGroup) in navbar
- [ ] `ss_locale` persisted in `localStorage`
- [ ] Axios/fetch interceptor: `Accept-Language: pl|en` (allowlisted)
- [ ] Code samples NEVER translated
- [ ] CI test: `i18n-parity.spec.ts` — fail on missing keys

**Security checkpoint:** D-10 (plain text in i18n files); locale interceptor rejects non-allowlisted values; `i18n-parity.spec.ts` GREEN in CI.

### Phase 6 — Cornucopia: FRE + LLM + AAI (Sprint 9, Weeks 17–18)
Pokrycie: US-12, US-13, US-14

- [ ] `CornucopiaCard` entity — Flyway V10, ZIO Quill mapping
- [ ] `YamlCardLoader` — ZIO `acquireRelease` scoped resource
- [ ] `ContentIntegrityVerifier` ZIO Layer — SHA-256 vs `data/hashes.json`, `ZIO.die` on mismatch (D-04)
- [ ] `OwaspRefValidator` — opaque type smart constructor + `Set[OwaspRef]` allowlist (D-07)
- [ ] `CardSuitRoutes` — `GET /api/v1/threats?suit=FRE|LLM|AAI`
- [ ] React `FrontendSecurityPage` — FRE card browser (US-12)
- [ ] React `LlmSecurityPage` + `LlmMatrixPage` — LLM cards + matrix (US-13)
- [ ] React `AgenticAiPage` + `AgenticMatrixPage` — AAI cards (US-14)
- [ ] `CornucopiaCard` React component — suit badge, value circle, OWASP ref chips
- [ ] `AUTONOMY RISK` badge on AAIK, AAIQ cards
- [ ] `RateLimitMiddleware` active on `/api/v1/threats?suit=*` (D-08)

**Security checkpoint:** D-04 (ContentIntegrityVerifier layer); D-07 (OwaspRefValidator opaque type); D-12 (CardId, SuitCode opaque types in routes); rate limit STM bucket active.

### Phase 7 — Cornucopia: STRIDE EoP + MLSec (Sprints 10–11, Weeks 19–22)
Pokrycie: US-15, US-16

- [ ] `MitreAtlasRefValidator` — opaque type + allowlist from `data/mitre-atlas-allowlist.json`
- [ ] `GET /api/v1/threats/stride/categories`, `GET /api/v1/stride-heatmap` (authAspect JWT)
- [ ] `GET /api/v1/threats/mlsec/categories`, filter by mitreRef
- [ ] React `StrideCataloguePage` — accordion per suit (6 suits × 13 cards)
- [ ] React `StrideHeatmapPage` — Recharts heatmap (auth-protected route)
- [ ] AAI agent diagrams: server-side SVG generation, React renders as `<img>`
- [ ] React `MlSecurityPage` — 4 category tabs (EMR/EIR/EOR/EDR), MITRE ATLAS chips
- [ ] `ML-SPECIFIC` badge on MLSec cards
- [ ] Security header: `X-Frame-Options: DENY` on `/stride-heatmap` route

**Security checkpoint:** `authAspect` JWT middleware guards `/stride-heatmap`; `MitreAtlasRefValidator` blocks unknown T-codes; SVG injection prevented by server-side generation.

### Phase 8 — Cornucopia: Mobile + DevOps (Sprints 12–13, Weeks 23–26)
Pokrycie: US-17, US-18

- [ ] `MavsRefValidator`, `CicdSecRefValidator`, `OatRefValidator` (opaque types + allowlists)
- [ ] `GET /api/v1/threats/mobile/suits` + `/api/v1/matrix/mobile-vs-web`
- [ ] React `MobileSecurityPage` + `MobileVsWebMatrixPage` (US-17)
- [ ] `GET /api/v1/threats?suit=DVO|CLD|BOT`
- [ ] React `DevOpsSecurityPage` — DVO section (CICD-SEC chips) + CLD section (A05:2021/A01:2021 chips) + BOT section (OAT chips)
- [ ] `BotWarningModal` v2 — `localStorage` flag `bot_warning_ack` (US-18)
- [ ] CI job `yaml-content-integrity`: ajv schema + injection grep + hash-generator
- [ ] DVO code examples: pseudocode only (D-13 pattern — no real CI/CD exploits)

**Security checkpoint:** `OatRefValidator` blocks undefined OAT-xxx; `BotWarningModal` flag stored securely in localStorage; DVO content reviewed — no working pipeline exploits.

### Phase 8.5 — Cornucopia: Digital-by-Default Harms (Sprint 13, Week 26)
Pokrycie: US-19

- [ ] `YamlCardLoader` extended to load `dbd-cards-1.0-en.yaml` (suits SCO, ARC, AGE, TRU, POR, COR, WC)
- [ ] `DigitalHarmsService` — read-only, no OWASP/MITRE ref validator applied (this deck has no CVE-style refs; it cross-links to A04:2021 by hand-curated `CrossReference` rows instead)
- [ ] `GET /api/v1/threats/digital-harms/suits`, `GET /api/v1/threats?suit=SCO|ARC|AGE|TRU|POR`
- [ ] React `DigitalHarmsPage` (US-19) — 5 suit sections, each card rendered with `DesignHarmBadge` instead of `SeverityBadge`
- [ ] Polish translations for all `SCO`/`ARC`/`AGE`/`TRU`/`POR` cards reviewed by a native speaker before merge (same i18n gate as D-10)
- [ ] Disclaimer banner on `/frameworks/digital-harms` explicitly stating this deck models *service-design harms*, not exploitable technical vulnerabilities

**Security checkpoint:** `DesignHarmBadge` never reuses `CRITICAL`/`HIGH` styling (prevents this non-technical deck from being read as a CVE severity); Polish translation review gate enforced before merge, same as D-10.

### Phase 9 — Integration, Testing & Hardening (Sprints 14–16, Weeks 27–31)
Pokrycie: US-01–US-19 full integration

- [ ] ZIO Test suites: all service layers (mocked dependencies)
- [ ] Integration tests: ZIO Test + sttp against real PostgreSQL 16 (Testcontainers Scala)
- [ ] React: Vitest + RTL — all components, hooks, stores
- [ ] E2E: Playwright — 19 spec files (us01 through us19)
- [ ] Abuse cases AC-01–AC-16 GREEN in CI
- [ ] DAST: OWASP ZAP full active scan — 0 High/Critical
- [ ] `axe-playwright` accessibility — WCAG 2.1 AA
- [ ] Lighthouse mobile ≥ 85 (Performance), ≥ 90 (Accessibility)
- [ ] `sbt assembly` Docker production build, Nginx config
- [ ] Frontend bundle: `npm run build` initial chunk < 600 KB gzip
- [ ] Monitoring: Loki alerts SEC-007/SEC-008/SEC-009; Prometheus metrics

---

## 7. API Endpoint Map

### Framework & Threat (base)
```
GET  /api/v1/frameworks                         — list all frameworks
GET  /api/v1/frameworks/:code                   — framework detail + threats

GET  /api/v1/threats                            — threat list
                                                  filters: frameworkCode, severity, stride,
                                                           tag, q (max 200 chars), suit,
                                                           owaspRef, mitreRef
GET  /api/v1/threats/:id                        — threat with mitigations
GET  /api/v1/threats/:id/mitigations
GET  /api/v1/threats/:id/code-samples
```

### Cornucopia Card Suits (US-12–US-19)
```
GET  /api/v1/threats?suit=FRE                   — Frontend cards (US-12)
GET  /api/v1/threats?suit=LLM                   — LLM cards (US-13)
GET  /api/v1/threats?suit=AAI                   — Agentic AI cards (US-14)
GET  /api/v1/threats/stride/categories          — 6 STRIDE categories (US-15)
GET  /api/v1/threats?suit=SP|TA|RE|ID|DS|EP     — individual STRIDE suits
GET  /api/v1/threats/mlsec/categories           — 4 MLSec categories (US-16)
GET  /api/v1/threats?suit=EMR|EIR|EOR|EDR       — individual MLSec suits
GET  /api/v1/threats/mobile/suits               — 6 Mobile suits (US-17)
GET  /api/v1/threats?suit=PC|AA|NS|RS|CRM|CM    — individual Mobile suits
GET  /api/v1/threats?suit=DVO                   — DevOps cards (US-18)
GET  /api/v1/threats?suit=CLD                   — Cloud cards (US-18) — maps to A05:2021/A01:2021
GET  /api/v1/threats?suit=BOT                   — Automated Threat cards (US-18)
GET  /api/v1/threats/digital-harms/suits        — 5 Digital-by-Default suits (US-19)
GET  /api/v1/threats?suit=SCO|ARC|AGE|TRU|POR   — individual Digital-by-Default suits (US-19)
```

### Matrix & Visualization
```
GET  /api/v1/matrix/llm                         — LLM Top 10 × Cornucopia matrix
GET  /api/v1/matrix/agentic                     — Agentic AI × LLM comparison
GET  /api/v1/matrix/mobile-vs-web               — MASVS vs OWASP Web Top 10
GET  /api/v1/stride-heatmap                     — STRIDE heatmap per component [JWT]
GET  /api/v1/cross-references
GET  /api/v1/cross-references?sourceCode=LLM01
GET  /api/v1/stats/coverage
```

### Search & Export
```
GET  /api/v1/search?q=prompt+injection
GET  /api/v1/export?format=csv&frameworkCode=LLM
GET  /api/v1/export?format=pdf&frameworkCode=LLM
```

### Mitigations & Code Samples
```
GET  /api/v1/mitigations/:id
GET  /api/v1/mitigations/:id/code-samples
GET  /api/v1/code-samples?language=SCALA
```

### Admin CRUD (JWT — ADMIN role)
```
POST   /api/v1/admin/threats
PUT    /api/v1/admin/threats/:id           — SafeHtml.sanitize applied (D-14)
DELETE /api/v1/admin/threats/:id
POST   /api/v1/admin/code-samples
PUT    /api/v1/admin/code-samples/:id
```

### Health & Ops
```
GET  /api/v1/health                        — ZIO HTTP health endpoint
GET  /api/v1/metrics/content-integrity     — ContentHash verification status
```

---

## 8. React Page & Component Structure

```
App (React Router v6)
│
├── Layout (Navbar + Sidebar + LanguageToggle)
│   ├── GlobalSearchBar (debounced React Query)
│   ├── DarkModeToggle (Zustand uiStore)
│   └── LanguageToggle (react-i18next, ss_locale)
│
└── <Outlet> (lazy-loaded via React.lazy + Suspense)

Routes:
  /                               → DashboardPage
  /frameworks                     → FrameworkBrowserPage
  /frameworks/:code               → FrameworkDetailPage
  /frameworks/frontend-security   → FrontendSecurityPage    (US-12)
  /frameworks/llm-security        → LlmSecurityPage         (US-13)
  /frameworks/agentic-ai          → AgenticAiPage           (US-14)
  /frameworks/stride              → StrideCataloguePage     (US-15)
  /frameworks/ml-security         → MlSecurityPage          (US-16)
  /frameworks/mobile-security     → MobileSecurityPage      (US-17)
  /frameworks/devops-security     → DevOpsSecurityPage      (US-18)
  /frameworks/digital-harms       → DigitalHarmsPage         (US-19)
  /threats                        → ThreatBrowserPage
  /threats/:id                    → ThreatDetailPage        (4 tabs)
  /matrix                         → MatrixPage
  /matrix/llm                     → LlmMatrixPage           (US-13)
  /matrix/agentic                 → AgenticMatrixPage       (US-14)
  /matrix/mobile-vs-web           → MobileVsWebMatrixPage   (US-17)
  /stride-heatmap                 → StrideHeatmapPage       (ProtectedRoute)
  /coverage                       → CoveragePage
  /search                         → SearchResultsPage       (US-06)
  /about                          → AboutPage

Components (src/components/):
  ThreatCard                  — severity color band, STRIDE badge chips
  CornucopiaCard              — suit badge, value circle, OWASP ref chips, DOMPurify
  CodeSamplePanel             — Shiki per language, Attack Demo / Defense tabs
  BotWarningModal             — confirm dialog before showing BOT cards (US-18)
  DesignHarmBadge              — distinct badge for the `dbd` deck (US-19) — never CRITICAL/HIGH styling
  StrideHeatmap               — Recharts heatmap
  MatrixTable                 — cross-reference table with sticky columns
  LlmMatrix                   — LLM Top 10 × Cornucopia interactive matrix
  LanguageToggle              — react-i18next PL | EN toggle
  SeverityBadge               — colored chip per severity
  OwaspRefChipList            — clickable OWASP reference chips

Hooks (src/hooks/):
  useThreats(filter)          — React Query, GET /api/v1/threats
  useThreatDetail(id)         — React Query, GET /api/v1/threats/:id
  useCardSuit(suit)           — React Query, GET /api/v1/threats?suit=*
  useSearch(q)                — React Query debounced, GET /api/v1/search
  useLocale()                 — react-i18next + ss_locale localStorage
  useAuth()                   — JWT context

Zustand stores (src/store/):
  frameworksStore             — frameworks list + selected
  threatsStore                — threats, filters, pagination
  cardSuitsStore              — cornucopia card suits
  searchStore                 — query + results
  uiStore                     — darkMode, locale
```

---

## 9. Scala ZIO Backend Architecture

```
backend/
├── build.sbt                              ← ZIO HTTP, ZIO Quill, Tapir, Flyway, ZIO Redis
├── project/
│   ├── build.properties                   ← sbt.version=1.9.x
│   └── plugins.sbt                        ← sbt-assembly, sbt-dependency-check,
│                                            scalafix, sbt-wartremover, sbt-scapegoat
├── .scalafix.conf                         ← custom rules: banned imports, error handling
├── .wartremover.conf
└── src/
    ├── main/scala/com/scalashield/
    │   ├── Main.scala                     ← ZIOApp: provideLayer(AppLayer.live)
    │   ├── AppLayer.scala                 ← ZLayer graph: DB → Repos → Services → Routes
    │   ├── config/
    │   │   └── AppConfig.scala            ← ZIO Config (typesafe-config backend)
    │   ├── routes/
    │   │   ├── FrameworkRoutes.scala
    │   │   ├── ThreatRoutes.scala
    │   │   ├── CardSuitRoutes.scala       ← Cornucopia suit endpoints
    │   │   ├── MatrixRoutes.scala
    │   │   ├── SearchRoutes.scala
    │   │   ├── ExportRoutes.scala
    │   │   └── AdminRoutes.scala          ← adminAspect JWT required
    │   ├── services/
    │   │   ├── ThreatService.scala        ← trait + ThreatServiceLive (ZLayer)
    │   │   ├── CardSuitService.scala
    │   │   ├── FrontendThreatService.scala
    │   │   ├── LlmThreatService.scala
    │   │   ├── AgenticThreatService.scala
    │   │   ├── StrideThreatService.scala
    │   │   ├── MlSecThreatService.scala
    │   │   ├── MobileSecThreatService.scala
    │   │   ├── DevOpsThreatService.scala
    │   │   ├── DigitalHarmsService.scala        ← dbd deck (US-19), read-only, DESIGN HARM labelling
    │   │   └── LocalizationService.scala
    │   ├── integrity/
    │   │   ├── ContentIntegrityVerifier.scala  ← ZLayer, ZIO.die on hash mismatch
    │   │   ├── YamlCardLoader.scala            ← ZIO acquireRelease scoped
    │   │   └── validator/
    │   │       ├── OwaspRefValidator.scala      ← opaque OwaspRef + Set allowlist
    │   │       ├── MitreAtlasRefValidator.scala
    │   │       ├── MavsRefValidator.scala
    │   │       ├── CicdSecRefValidator.scala
    │   │       └── OatRefValidator.scala
    │   ├── repository/
    │   │   ├── ThreatRepository.scala           ← ZIO Quill ctx
    │   │   ├── CardRepository.scala
    │   │   ├── MitigationRepository.scala
    │   │   ├── CodeSampleRepository.scala
    │   │   └── ContentHashRepository.scala
    │   ├── model/                               ← case classes + enums (Section 5)
    │   ├── middleware/
    │   │   ├── JwtMiddleware.scala              ← ZIO HTTP HandlerAspect
    │   │   ├── RateLimitMiddleware.scala        ← ZIO STM TRef[TokenBucket]
    │   │   ├── SecurityHeadersMiddleware.scala  ← CSP, HSTS, X-Frame-Options
    │   │   └── CorsMiddleware.scala
    │   └── error/
    │       ├── AppError.scala                   ← sealed trait hierarchy
    │       └── ErrorHandler.scala               ← ZIO HTTP error mapping
    └── test/scala/com/scalashield/
        ├── services/                            ← ZIO Test suites
        ├── integrity/
        ├── repository/                          ← Testcontainers PostgreSQL
        └── routes/                              ← sttp integration tests
```

---

## 10. Code Sample Strategy

Each threat has at least one mitigation with 5 code samples (one per language). Cornucopia cards have at least one sample showing the secure pattern.

```
CodeSamplePanel — tabs: [Python] [Java] [Go] [Scala] [Lua]

Each tab — inner tabs:
  [Attack Demo]  — red left border + PODATNY badge (never executed server-side)
  [Defense]      — green left border + BEZPIECZNY badge
```

| Language | Framework |
|---|---|
| Python | FastAPI 0.110, SQLAlchemy 2.0, Pydantic v2 |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | Gin 1.9, pgx v5, net/http |
| Scala | ZIO HTTP 3.x, ZIO Quill, ZIO 2 |
| Lua | OpenResty / NGINX Lua, LuaSQL |

---

## 11. Security Data Coverage Plan

### OWASP Web Top 10 (2021) — A01–A10
Cornucopia: VE (Validation), AT (Authentication), SM (Session), AZ (Authorization), CR (Cryptography), C

### OWASP LLM Top 10 (2025) — LLM01–LLM10
Cornucopia: LLM suit (Companion v1.0) | Matrix: /matrix/llm

### OWASP Agentic AI Top 10 (2026) — AgentAI01–AgentAI10
Cornucopia: AAI suit | Matrix: /matrix/agentic

### OWASP API Security Top 10 — API1–API10

### OWASP Top 10 Client-Side Security Risks — C01–C10
Cornucopia: FRE suit

### OWASP Top 10 CI/CD Security Risks — CICD-SEC-01–10
Cornucopia: DVO suit

### OWASP Automated Threats (OAT) — OAT-001–021 (min 13)
Cornucopia: BOT suit

### OWASP MASVS 2.0 — MASVS-STORAGE/CRYPTO/AUTH/NETWORK/PLATFORM/CODE/RESILIENCE
Cornucopia: PC, AA, NS, RS, CRM, CM suits | Matrix: /matrix/mobile-vs-web

### STRIDE — S, T, R, I, D, E (6 categories × 13 cards each)
Cornucopia: SP, TA, RE, ID, DS, EP suits (EoP v5.0) | Heatmap: /stride-heatmap

### MITRE ATLAS — min 15 techniques: T0010, T0011, T0014, T0020, T0024, T0029, T0043, T0044, T0051
Cornucopia: EMR, EIR, EOR, EDR suits (MLSec v1.0)

### CompTIA Security+ SY0-701 / SecAI+ 2026 — min 20 topics
Prompt Injection, Data Poisoning, Model Theft, Adversarial ML, Deepfakes, AI Red Teaming, Zero Trust, NIST AI RMF

### OWASP A04:2021 Insecure Design — Digital-by-Default Harms (US-19)
Cornucopia: SCO (Scope), ARC (Architecture), AGE (Agency), TRU (Trust), POR (Porosity) suits (`dbd-cards-1.0-en.yaml` v1.0) | Page: `/frameworks/digital-harms`

This deck (source: `digitalbenefits.uk`) is explicitly **not** a technical-vulnerability deck like the other five — it models *service-design harms* in public-sector digital services (digital exclusion, forced re-entry of already-held data, opaque algorithms). It is included because it maps cleanly onto **OWASP A04:2021 Insecure Design** and onto the GRC/AI-Act transparency topics already required under CompTIA SecAI+ (§ above), and gives Polish-speaking learners a non-technical entry point into "secure by design" thinking before they meet STRIDE/Cornucopia's more code-level decks. It is labelled with a distinct `DESIGN HARM` badge in the UI (never the `CRITICAL`/`HIGH` severity badges used for technical threats) so it cannot be mistaken for a CVE-style vulnerability.

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
data/mitre-atlas-allowlist.json        ← allowed T-codes
data/ref-allowlists.json               ← OWASP, MASVS, CICD-SEC, OAT allowlists
```

**Workflow:**
1. PR to `data/cornucopia/*.yaml` → CODEOWNERS: @security-team (min 2 approvals)
2. CI job `yaml-content-integrity`: ajv schema + injection grep + ref validator
3. Post-merge: `hash-generator` bot updates `data/hashes.json`
4. Startup: `ContentIntegrityVerifier` ZLayer → `ZIO.die` on any mismatch → app fails to start

---

## 13. Risk Register

| Risk | Mitigation |
|---|---|
| ZIO Quill compile-time macros slow compilation | Incremental compilation via sbt; separate subproject for model |
| sbt assembly fat-JAR > 200 MB | Multi-stage Docker: sbt image for build, JRE 21-slim for runtime |
| React bundle too large | Lazy route loading via React.lazy; Shiki language packs lazy |
| Cross-references inconsistent | `CrossReference` case class with `RelationshipType` enum |
| YAML tampered maliciously | `ContentIntegrityVerifier` ZLayer + CODEOWNERS |
| False OWASP/MITRE IDs | Opaque type validators + Set[T] allowlists (D-07, D-12) |
| XSS via admin card update | `SafeHtml` pure-Scala sanitizer (D-14) + DOMPurify |
| Bot scraping card API | ZIO STM rate limit 60 req/min per IP (D-08) |
| Clickjacking /stride-heatmap | X-Frame-Options: DENY + CSP frame-ancestors 'none' |
| SVG injection in AAI diagrams | Server-side SVG generation; DOMPurify strips `<script>` |
| Wartremover blocks valid patterns | Suppression annotation `@SuppressWarnings` with required justification comment |
| Opaque type ergonomics friction | Extension methods defined in companion objects; transparent at call sites |

---

## 14. Directory Layout

```
app04_scala_react/
├── PLAN.md
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
├── backend/                               ← Scala 3 + ZIO 2 + ZIO HTTP
│   ├── build.sbt
│   ├── project/
│   │   ├── build.properties
│   │   └── plugins.sbt
│   ├── .scalafix.conf
│   └── src/
│       ├── main/scala/com/scalashield/
│       │   ├── Main.scala
│       │   ├── AppLayer.scala
│       │   ├── config/AppConfig.scala
│       │   ├── routes/
│       │   │   ├── FrameworkRoutes.scala
│       │   │   ├── ThreatRoutes.scala
│       │   │   ├── CardSuitRoutes.scala
│       │   │   ├── MatrixRoutes.scala
│       │   │   ├── SearchRoutes.scala
│       │   │   ├── ExportRoutes.scala
│       │   │   └── AdminRoutes.scala
│       │   ├── services/
│       │   │   ├── ThreatService.scala
│       │   │   ├── CardSuitService.scala
│       │   │   ├── FrontendThreatService.scala
│       │   │   ├── LlmThreatService.scala
│       │   │   ├── AgenticThreatService.scala
│       │   │   ├── StrideThreatService.scala
│       │   │   ├── MlSecThreatService.scala
│       │   │   ├── MobileSecThreatService.scala
│       │   │   ├── DevOpsThreatService.scala
│       │   │   └── LocalizationService.scala
│       │   ├── integrity/
│       │   │   ├── ContentIntegrityVerifier.scala
│       │   │   ├── YamlCardLoader.scala
│       │   │   └── validator/
│       │   │       ├── OwaspRefValidator.scala
│       │   │       ├── MitreAtlasRefValidator.scala
│       │   │       ├── MavsRefValidator.scala
│       │   │       ├── CicdSecRefValidator.scala
│       │   │       └── OatRefValidator.scala
│       │   ├── repository/
│       │   │   ├── ThreatRepository.scala
│       │   │   ├── CardRepository.scala
│       │   │   ├── MitigationRepository.scala
│       │   │   ├── CodeSampleRepository.scala
│       │   │   └── ContentHashRepository.scala
│       │   ├── model/
│       │   │   ├── Framework.scala
│       │   │   ├── Threat.scala
│       │   │   ├── ThreatTranslation.scala
│       │   │   ├── CornucopiaCard.scala
│       │   │   ├── Mitigation.scala
│       │   │   ├── CodeSample.scala
│       │   │   ├── CrossReference.scala
│       │   │   ├── ContentHash.scala
│       │   │   └── OpaqueTypes.scala    ← ThreatCode, CardId, OwaspRef etc.
│       │   ├── middleware/
│       │   │   ├── JwtMiddleware.scala
│       │   │   ├── RateLimitMiddleware.scala
│       │   │   ├── SecurityHeadersMiddleware.scala
│       │   │   └── CorsMiddleware.scala
│       │   └── error/
│       │       ├── AppError.scala
│       │       └── ErrorHandler.scala
│       └── test/scala/com/scalashield/
│           ├── services/
│           ├── integrity/
│           ├── repository/
│           └── routes/
│
├── frontend/                              ← React 18 + TypeScript + Vite
│   ├── package.json
│   ├── vite.config.ts
│   ├── tsconfig.json
│   └── src/
│       ├── main.tsx
│       ├── App.tsx
│       ├── pages/
│       │   ├── Dashboard.tsx
│       │   ├── FrameworkBrowser.tsx
│       │   ├── FrameworkDetail.tsx
│       │   ├── ThreatBrowser.tsx
│       │   ├── ThreatDetail.tsx
│       │   ├── suits/
│       │   │   ├── FrontendSecurity.tsx    ← US-12
│       │   │   ├── LlmSecurity.tsx         ← US-13
│       │   │   ├── AgenticAi.tsx           ← US-14
│       │   │   ├── StrideCatalogue.tsx     ← US-15
│       │   │   ├── MlSecurity.tsx          ← US-16
│       │   │   ├── MobileSecurity.tsx      ← US-17
│       │   │   └── DevOpsSecurity.tsx      ← US-18
│       │   ├── matrix/
│       │   │   ├── MainMatrix.tsx
│       │   │   ├── LlmMatrix.tsx
│       │   │   ├── AgenticMatrix.tsx
│       │   │   └── MobileVsWebMatrix.tsx
│       │   ├── StrideHeatmap.tsx
│       │   ├── Coverage.tsx
│       │   ├── SearchResults.tsx
│       │   └── About.tsx
│       ├── components/
│       │   ├── ThreatCard.tsx
│       │   ├── CornucopiaCard.tsx
│       │   ├── CodeSamplePanel.tsx
│       │   ├── BotWarningModal.tsx
│       │   ├── StrideHeatmap.tsx
│       │   ├── MatrixTable.tsx
│       │   ├── LlmMatrix.tsx
│       │   ├── LanguageToggle.tsx
│       │   └── SeverityBadge.tsx
│       ├── hooks/
│       ├── store/
│       │   ├── frameworksStore.ts
│       │   ├── threatsStore.ts
│       │   ├── cardSuitsStore.ts
│       │   ├── searchStore.ts
│       │   └── uiStore.ts
│       ├── api/
│       │   └── client.ts              ← fetch wrapper with Accept-Language interceptor
│       ├── i18n/
│       │   └── index.ts               ← react-i18next setup
│       └── types/
│
├── public/
│   └── locales/
│       ├── pl/translation.json
│       └── en/translation.json
│
├── data/
│   ├── owasp_web_top10.json
│   ├── owasp_llm_top10.json
│   ├── owasp_agentic_top10.json
│   ├── mitre_atlas.json
│   ├── comptia_secai.json
│   ├── cornucopia/
│   │   ├── webapp-cards-3.0-en.yaml
│   │   ├── companion-llm-cards-1.0-en.yaml
│   │   ├── mobileapp-cards-1.1-en.yaml
│   │   ├── stride-eop-cards-5.0-en.yaml
│   │   ├── mlsec-cards-1.0-en.yaml
│   │   ├── dbd-cards-1.0-en.yaml       ← Digital-by-Default Harms (US-19)
│   │   └── translations/
│   │       ├── pl.cards.json
│   │       └── en.cards.json
│   ├── hashes.json
│   ├── mitre-atlas-allowlist.json
│   ├── ref-allowlists.json
│   └── code_samples/
│       ├── python/
│       ├── java/
│       ├── go/
│       ├── scala/
│       └── lua/
│
├── e2e/
│   ├── playwright.config.ts
│   └── tests/
│       ├── us01-framework-browser.spec.ts
│       ├── us02-threat-filter.spec.ts
│       ├── ...
│       ├── us18-devops-security.spec.ts
│       └── us19-digital-harms.spec.ts
│
└── docker-compose.yml
```

---

## 15. User Stories — Complete List

| ID | Role | Need | Goal |
|---|---|---|---|
| US-01 | security engineer | browse security framework catalogue | single access point to all standards |
| US-02 | security engineer | filter threats by framework, severity, STRIDE, tag, q | quickly find threats relevant to my project |
| US-03 | security engineer | see threat details with mitigations and code samples | understand how to implement protection |
| US-04 | CompTIA SecAI+ student | see how LLM01 Prompt Injection maps to MITRE ATLAS AML.T0051 | understand cross-framework dependencies |
| US-05 | security trainer | display STRIDE heatmap on projector | visually explain STRIDE coverage in workshops |
| US-06 | pentester | search "deepfake" and find all related threats with defenses | assemble test checklist for client |
| US-07 | team lead | export filtered threat list to CSV | include in risk register |
| US-08 | developer | see MITRE ATLAS Kill-Chain timeline | understand which attack phase each technique belongs to |
| US-09 | Scala developer | find code samples for supply-chain attacks in Scala | implement SCA in Scala pipeline |
| US-10 | Lua/OpenResty developer | see Lua examples for rate limiting preventing LLM DoS | configure NGINX guardrails for LLM API proxy |
| US-11 | Polish-speaking student | switch entire app from English to Polish with one click | learn all threat descriptions in native language |
| US-12 | React/frontend developer | browse Cornucopia FRE cards (DOM XSS, clickjacking, CORS, JWT forgery) with Polish descriptions | map client-side attack scenarios to mitigations |
| US-13 | ML engineer / AI architect | explore OWASP LLM Top 10 2025 via Cornucopia LLM cards with interactive matrix | understand prompt injection, data poisoning, excessive agency |
| US-14 | agentic AI developer | study OWASP Agentic AI Top 10 2026 via AAI cards | design human-in-the-loop safeguards for agent pipelines |
| US-15 | security architect | use STRIDE EoP catalogue with interactive heatmap per system component | run structured threat modeling session |
| US-16 | data scientist | browse ML security risks (EMR/EIR/EOR/EDR) with MITRE ATLAS references | identify adversarial ML, model theft, data poisoning |
| US-17 | Android/iOS developer | see OWASP MASVS threats via Cornucopia Mobile App cards + MASVS vs Web table | understand how mobile security differs from web |
| US-18 | DevSecOps engineer | browse DevOps supply chain risks (DVO) and automated threat patterns (BOT) | protect CI/CD pipelines and defend against bots |
| US-19 | public-sector product owner / GRC reviewer | browse the "Digital-by-Default Harms" deck (SCO/ARC/AGE/TRU/POR) with Polish translations, clearly separated from technical-vulnerability decks | assess digital-exclusion and opaque-design risk in a public digital service and map it to OWASP A04:2021 Insecure Design |

---

## 16. Milestones & Acceptance Criteria

| Milestone | Deliverable | Done when |
|---|---|---|
| M1 | Working skeleton | `sbt run` → ZIO HTTP starts; `GET /api/v1/frameworks` returns JSON; `npm run dev` → React SPA loads |
| M2 | Full data seed | All frameworks, threats, mitigations in DB; API returns correct counts |
| M3 | Code samples complete | Each threat has 5 code samples (Scala/Python/Java/Go/Lua) visible in ThreatDetailPage |
| M4 | Matrix + heatmap | MatrixPage renders; CoverageHeatmap shows STRIDE percentages |
| M5 | Search works | Full-text search returns results with highlighted fragments |
| M6 | i18n works | PL/EN toggle in navbar; entire UI in both languages; code samples not translated |
| M7 | Production build | `sbt assembly` → Docker image; `npm run build` → initial bundle < 600 KB gzip; health endpoint 200 |
| M8 | FRE + LLM + AAI cards | FrontendSecurityPage, LlmSecurityPage, AgenticAiPage; matrices available |
| M9 | STRIDE + MLSec | 78 STRIDE cards (6 × 13); Recharts heatmap; 52 MLSec cards (4 × 13) |
| M10 | Mobile + DevOps | MobileSecurityPage, DevOpsSecurityPage; MASVS vs Web table; BotWarningModal |
| M11 | Content integrity | ContentIntegrityVerifier ZLayer GREEN; CI yaml-content-integrity GREEN |
| M12 | Digital-by-Default Harms | DigitalHarmsPage renders all 5 suits with `DESIGN HARM` badge; A04:2021 cross-reference visible |
| M13 | Tests pass | ≥ 200 tests; abuse cases AC-01–AC-16 GREEN; ZAP 0 HIGH; Lighthouse ≥ 85; axe-playwright 0 Critical |
