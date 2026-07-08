# GoSentry 2026 — Application Development Plan

**Version:** 1.0
**Date:** 2026-07-07
**Status:** Living document — updated after each sprint planning session
**Directory:** `app05_go_react`
**Sibling projects:** `app01_react` (Java/Spring Boot + React), `app02_angular` (Java/Spring Boot + Angular), `app03_python_django` (Python/Django), `app04_scala_react` (Scala/ZIO + React)

---

## 0. Note on the Stack

This application is written **entirely in Go**, using the standard library wherever practical, for the backend — no second backend language. The frontend is **React 18 + TypeScript**, matching `app01_react`/`app04_scala_react` so the course's Java-background audience can compare the same product across four different backend ecosystems (Java/Spring Boot, Python/Django, Scala/ZIO, and now Go) against the same React frontend patterns.

**Why this matters for the course:** Go is deliberately the most different of the four backends from a "Java developer's mental model" — no classes, no exceptions (errors are values), no runtime reflection-based DI container, no garbage-collector tuning debates at the level Java requires, and the deployable artifact is a single statically-linked binary rather than a JAR/WAR or an interpreter + source tree. Several security properties fall out of these choices "for free," and this plan calls them out explicitly wherever relevant (see §4 Architecture Design Decisions, D-01, D-06, D-09).

**Note on code samples:** the application still *teaches* countermeasures in five languages — Python, Java, Go, Scala, and Lua (see §10) — because that is separate, deliberately polyglot **content**, not the application's own runtime. Java and Scala appear only as sample-code tabs; the application itself never links a JVM library.

---

## 1. Project Overview

**Name:** GoSentry 2026
**Purpose:** A bilingual (Polish/English) reference and learning platform mapping security threats, vulnerabilities and mitigations across **OWASP** (Web Top 10, LLM Top 10, Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, Automated Threats/OAT, MASVS), **MITRE ATLAS** (adversarial ML tactics/techniques), and **CompTIA Security+ SY0-701 / SecAI+ 2026**, plus the full catalogue of **OWASP Cornucopia-family card decks** found in `docs/OWASP_stories/*.yaml`. Each threat is presented with working countermeasure code in **five languages**: Python, Java, Go, Scala, and Lua.

**Source material:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md` and all six card decks under `docs/OWASP_stories/`:

| File | Edition | Suits |
|---|---|---|
| `webapp-cards-3.0-en.yaml` | OWASP Cornucopia — Website App v3.0 | VE, AT, SM, AZ, CR, C, WC |
| `mobileapp-cards-1.1-en.yaml` | OWASP Cornucopia — Mobile App v1.1 | PC, AA, NS, RS, CRM, CM, WC |
| `__LLM_AI___companion-cards-1.0-en.yaml` | OWASP Cornucopia — Companion (AI/Cloud/DevOps) v1.0 | LLM, CLD, FRE, DVO, BOT, AAI, Common |
| `STRIDE__eop-cards-5.0-en.yaml` | Microsoft "Elevation of Privilege" (STRIDE) v5.0 | SP, TA, RE, ID, DS, EP |
| `RISKS__elevation-of-mlsec-cards-1.0-en.yaml` | "Elevation of MLSec" v1.0 | EMR, EIR, EOR, EDR |
| `dbd-cards-1.0-en.yaml` | Digital-by-Default Harms Deck v1.0 | SCO, ARC, AGE, TRU, POR, COR, WC |

All six decks are in scope from day one of this plan (see §11, §15) — a gap the sibling `app04_scala_react` plan initially had and had to be corrected for.

**UI languages:** Polish (default) and English, switched instantly with no page reload; toggle persisted in `localStorage` under key `gs_locale`, and mirrored server-side via the `Accept-Language` header.

---

## 2. Technology Stack

### Backend (100% Go, standard library first)
| Layer | Technology | Version (2026) |
|---|---|---|
| Language | Go | 1.23 |
| HTTP router | `chi` v5 | — |
| Database driver | `pgx` v5 | — |
| Query layer | `sqlc` — compile-time generated, type-checked Go from `.sql` files | — |
| Database | PostgreSQL 16 | — |
| Migrations | `goose` | — |
| Cache / rate-limit store | Redis 7 via `go-redis` v9 | — |
| Background jobs | `river` — Postgres-backed job queue (export, YAML re-ingestion, periodic integrity re-check) | — |
| Auth | `golang-jwt/jwt` v5 (RS256) + `golang.org/x/crypto/bcrypt` | — |
| Validation | `go-playground/validator` v10 | — |
| HTML sanitization | `microcosm-cc/bluemonday` — pure-Go allow-list sanitizer | — |
| YAML parsing | `gopkg.in/yaml.v3`, unmarshalled into fixed Go structs only (see D-09) | — |
| Structured logging | stdlib `log/slog` | — |
| API docs | `swaggo/swag` → OpenAPI 3 / Swagger UI | — |
| Testing | stdlib `testing` + `testify` (`assert`/`require`) + `httptest` | TDD — see `user_stories+tests.md` |
| SAST | `gosec`, `staticcheck`, `go vet`, aggregated via `golangci-lint` | — |
| SCA | `govulncheck` (official Go vulnerability scanner) + Trivy (containers) | — |

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
| Container | Docker + Docker Compose — Go backend ships as a `FROM scratch` / `distroless` static binary image |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Loki + Prometheus (`prometheus/client_golang`) |
| Secrets | Docker Secrets / GitHub Secrets / `.env` (never committed) |
| SAST | `golangci-lint` (gosec + staticcheck bundled) + `eslint-plugin-security` (frontend) |
| DAST | OWASP ZAP |
| SCA | `govulncheck` + `npm audit` + Trivy |

---

## 3. High-Level Architecture

```
Browser (React 18 SPA, PL/EN)
        │
        │  HTTPS
        ▼
  Nginx (port 443)
   ├── /api/v1/*   ─────► Go binary (net/http + chi, port 8080)
   │                         ├── cmd/api/main.go        — HTTP server entrypoint
   │                         ├── internal/http/         — chi routes + middleware
   │                         ├── internal/service/      — business logic, framework-agnostic
   │                         ├── internal/store/        — sqlc-generated queries + pgx pool
   │                         └── internal/integrity/     — YAML hash verification (called by
   │                                                        cmd/api at boot AND by the River
   │                                                        worker on a schedule — never by
   │                                                        an HTTP handler, see D-05)
   │
   └── /*          ─────► React SPA static build (served by Nginx directly)

cmd/worker/main.go (same Go module, separate binary + container)
   ├── River job queue consumer (export.GenerateCSV, export.GeneratePDF,
   │                             cards.ReingestDeck, integrity.PeriodicReverify)
   └── shares internal/service, internal/store, internal/integrity with cmd/api

PostgreSQL 16   ◄── pgx pool, sqlc-generated queries (threats, cards, mitigations, users, River's own job tables)
Redis 7         ◄── rate-limit token buckets, response cache
```

**Where the trust boundaries are:** `cmd/api` (the HTTP-facing binary) and `cmd/worker` (the job-queue consumer) are **two separate compiled binaries** sharing one Go module — a real process boundary, not just a code-organization convention. `internal/integrity`'s hash-verification function is only ever called from `cmd/api`'s boot sequence and from `cmd/worker`'s scheduled job — never from an HTTP handler — enforced by Go's own `internal/` package visibility rule (a handler in `internal/http` cannot reach into `internal/integrity` unless it imports the package directly, which is caught in code review and by an import-boundary lint rule, D-05). This is the same design discipline `app03_python_django`/`app04_scala_react` applied, expressed with Go's package-privacy tools instead of Python import-graph tests or Scala's opaque types.

---

## 4. Architecture Design Decisions

### D-01 — Errors as values, no hidden control flow
Go has no exceptions. Every fallible function returns `(T, error)`; the codebase never uses `panic`/`recover` for expected error paths — only chi's top-level `Recoverer` middleware catches genuine programming bugs and turns them into a generic HTTP 500, logged with a stack trace server-side only. This removes an entire class of "forgot to catch it" bugs that show up in Java/Scala stack traces leaking to clients.

### D-02 — `sqlc`: compile-time-checked SQL, not an ORM
Every query lives in a `.sql` file under `internal/store/queries/`; `sqlc generate` produces a fully-typed Go function for it at build time, checked against the real schema. There is no runtime query builder and no string concatenation path to inject into — the SQL injection class of bug is structurally unavailable, the same guarantee `app04_scala_react` gets from ZIO Quill and `app03_python_django` gets from the Django ORM, achieved here via code generation instead of macros or a runtime ORM.

### D-03 — JWT auth via `golang-jwt/jwt` v5, stateless
RS256-signed JWTs, no server-side sessions. Middleware (`internal/http/middleware/auth.go`) validates the token and injects the parsed claims into the request context via `context.Context` — Go's standard mechanism for request-scoped values, deliberately never a global/mutable singleton.

### D-04 — `bluemonday` allow-list HTML sanitization (pure Go, no Java library)
Admin-edited threat/mitigation text is sanitized server-side with `bluemonday.UGCPolicy()` restricted to a small allow-list (`b`, `i`, `code`, `pre`, `a[href]` with scheme allow-listing) before persisting. The frontend additionally runs `DOMPurify.sanitize()` at render time — defense in depth, with **no JVM library anywhere in the chain** (unlike the OWASP Java HTML Sanitizer `app01_react`/`app02_angular` use, and unlike the mistake corrected in `app04_scala_react`).

### D-05 — `internal/` package boundary as the least-privilege enforcement mechanism
Go's `internal/` directory convention is a compiler-enforced visibility rule, not just a naming convention: code outside the module cannot import `internal/integrity` at all, and a `golangci-lint` custom rule (`depguard`) additionally forbids `internal/http/**` from importing `internal/integrity` directly. Only `cmd/api/main.go` and `cmd/worker/main.go` wire the two together. This gives the same "who is allowed to call the security-sensitive function" guarantee `app03_python_django` builds with an import-graph test and `app04_scala_react` builds with opaque types — here it is closer to being enforced by the compiler itself.

### D-06 — Static binary deployment (no interpreter, no JVM, minimal attack surface)
`cmd/api` and `cmd/worker` are compiled with `CGO_ENABLED=0` into fully static binaries and shipped in `FROM scratch` (or `gcr.io/distroless/static`) container images — no shell, no package manager, no JVM, no Python interpreter inside the running container. There is no `RCE-via-eval`, no vulnerable interpreter version, and no transitively-vulnerable base-image shell to patch. This is a concrete, teachable contrast with the JVM-based (`app01_react`, `app02_angular`, `app04_scala_react`) and Python-based (`app03_python_django`) siblings, which all need a runtime inside their container.

### D-07 — Opaque string types via Go 1.18+ generics-friendly wrapper types
Security-sensitive identifiers are modeled as distinct named types (`type ThreatCode string`, `type CardID string`, `type SuitCode string`, `type OwaspRef string`, `type MitreRef string`) with smart constructors (`func NewOwaspRef(s string) (OwaspRef, error)`) that validate against an allow-list before returning a value. A raw `string` cannot be silently used where an `OwaspRef` is expected — Go's structural typing still requires an explicit conversion, which is the point: the conversion is the code-review-visible moment where validation must have already happened.

### D-08 — Rate limiting via Redis + a Lua-scripted sliding window (no external dependency beyond Redis)
`internal/http/middleware/ratelimit.go` runs a small Lua script inside Redis (`EVAL`) implementing a sliding-window counter — atomic by construction because Redis executes the whole script single-threaded. Returns HTTP 429 with `Retry-After` when the 60 req/min/IP budget is exhausted. (This is also, deliberately, where a Lua code sample in the app's own infrastructure and a Lua code *sample* shown to end users as OpenResty content meet — see §10.)

### D-09 — `yaml.v3` unmarshals into fixed structs only — no arbitrary-type gadget risk
Go's `encoding` packages (including `yaml.v3`) decode into a statically-declared target type; there is no equivalent of Python's `yaml.load` "construct arbitrary Python object" behavior or a SnakeYAML unsafe-constructor gadget chain, because Go has no runtime reflection-based universal object constructor reachable from decoded data by default. `internal/cards/loader.go` still unmarshals defensively into a narrow `CardFile` struct (rejecting unknown fields via `yaml.UnmarshalStrict` semantics) and the loaded content is still SHA-256-verified (D-05), but the *class* of vulnerability that motivated `yaml.safe_load` in Python and `SafeConstructor` in SnakeYAML does not exist in the same form here — a fact this plan calls out explicitly rather than silently relying on, so students don't conclude "Go is inherently secure" instead of "Go's type system removes one specific bug class."

### D-10 — River: Postgres-backed job queue instead of a separate broker
Background work (CSV/PDF export, YAML deck re-ingestion, periodic integrity re-verification) is enqueued as `river.Job` rows in the same PostgreSQL database — no Redis/RabbitMQ broker to secure separately for job dispatch (Redis is still used for rate limiting and caching, D-08). `cmd/worker` polls via `LISTEN/NOTIFY` and processes jobs with typed `Args` structs, so a job payload is validated Go data, never a free-form JSON blob interpreted at execution time.

### D-11 — react-i18next with plain-text-only translation values (shared pattern)
Same as `app01_react`/`app04_scala_react`: `pl.json`/`en.json` values are plain text only, no HTML interpolation. `gs_locale` in `localStorage`; `Accept-Language` header set by a fetch interceptor, allowlisted to `pl`/`en` server-side.

---

## 5. Data Model

### 5.1 Enumerations (Go — `internal/domain/enums.go`)
```go
type Severity string
const (
	SeverityCritical Severity = "CRITICAL"
	SeverityHigh     Severity = "HIGH"
	SeverityMedium   Severity = "MEDIUM"
	SeverityLow      Severity = "LOW"
	SeverityInfo     Severity = "INFO"
)

type StrideCategory string // S, T, R, I, D, E

type SampleType string // ATTACK_DEMO, DEFENSE

type CodeLanguage string // PYTHON, JAVA, GO, SCALA, LUA

type MitigationType string // PREVENTIVE, DETECTIVE, CORRECTIVE, COMPENSATING

type Effort string // LOW, MEDIUM, HIGH

type Effectiveness string // PARTIAL, SIGNIFICANT, FULL

type RelationshipType string // EQUIVALENT, RELATED, PARENT_CHILD, MAPS_TO

type CardKind string // TECHNICAL_THREAT, DESIGN_HARM  (see 5.5 — dbd deck)
```

### 5.2 Framework
```go
type Framework struct {
	ID           uuid.UUID
	Code         string // "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS", "COMPTIA_SECAI", ...
	Name         string
	Version      string
	Description  string
	ReferenceURL string
}
```

### 5.3 Threat
```go
type Threat struct {
	ID            uuid.UUID
	FrameworkID   uuid.UUID
	Code          string // "LLM01:2025", "A03:2021", "AML.T0051"
	Title         string
	Severity      Severity
	Category      string
	Description   string
	AttackVector  string
	AttackSurface string
	Stride        []StrideCategory
	Tags          []string
}
```

### 5.4 ThreatTranslation *(i18n)*
```go
type ThreatTranslation struct {
	ID           uuid.UUID
	ThreatID     uuid.UUID
	Locale       string // "pl", "en"
	Title        string
	Description  string
	AttackVector string
}
```

### 5.5 CornucopiaCard *(all six YAML decks)*
```go
type CornucopiaCard struct {
	ID             uuid.UUID
	CardID         string // "VE3", "LLM4", "SPX", "EMR2", "SCO2"
	SuitCode       string // "VE","AT","SM","AZ","CR","C",
	                        // "PC","AA","NS","RS","CRM","CM",
	                        // "LLM","CLD","FRE","DVO","BOT","AAI",
	                        // "SP","TA","RE","ID","DS","EP",
	                        // "EMR","EIR","EOR","EDR",
	                        // "SCO","ARC","AGE","TRU","POR","COR","WC"
	SuitName       string
	Edition        string // webapp, mobileapp, companion, eop, mlsec, dbd
	Value          string // "2"-"10","J","Q","K","A"
	IsCritical     bool
	CardKind       CardKind // TECHNICAL_THREAT for 5 decks; DESIGN_HARM for dbd (US-19)
	DescriptionEn  string
	DescriptionPl  string
	MiscNote       string
	SourceURL      string
	OwaspRefs      []string
	MitreRefs      []string
	ContentSHA256  string
}
```
`Severity` is `*Severity` (nullable) at the storage/serialization layer: every `TECHNICAL_THREAT` card has one, every `DESIGN_HARM` card (dbd deck) has `nil` — enforced by a constructor function, not just convention (see US-19 in `requirements.md` FR-19 and `user_stories+tests.md`).

### 5.6 Mitigation
```go
type Mitigation struct {
	ID           uuid.UUID
	ThreatID     *uuid.UUID
	CardID       *uuid.UUID
	Title        string
	Description  string
	Type         MitigationType
	Effort       Effort
	Effectiveness Effectiveness
}
```

### 5.7 CodeSample
```go
type CodeSample struct {
	ID            uuid.UUID
	MitigationID  uuid.UUID
	Language      CodeLanguage
	SampleType    SampleType
	Title         string
	Description   string
	Code          string
	FrameworkHint string // "chi + sqlc", "Spring Boot 3.3", "Django ORM", "Akka HTTP"...
	VersionNote   string
}
```

### 5.8 CrossReference
```go
type CrossReference struct {
	ID               uuid.UUID
	SourceThreatID   uuid.UUID
	TargetThreatID   uuid.UUID
	RelationshipType RelationshipType
	Description      string
}
```

### 5.9 ContentHash
```go
type ContentHash struct {
	ID         uuid.UUID
	FileName   string
	SHA256Hash string
	VerifiedAt time.Time
	IsValid    bool
	VerifiedBy string // "go-integrity-service"
}
```

---

## 6. Development Phases

*(Numbering aligned with the Agile/Scrum sprint plan detailed in `SDLC_analysis.md`, §4.)*

### Phase 1 — Foundation (Sprints 1–2)
Covers: US-01, US-02
- [ ] `go mod init gosentry`; `cmd/api`, `cmd/worker`, `internal/{http,service,store,domain,integrity,cards}`
- [ ] `chi` router skeleton; `SecurityHeaders` middleware (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)
- [ ] Docker Compose: PostgreSQL 16 + Redis 7 + `api` + `worker` + Nginx
- [ ] `goose` migrations for models in §5.1–5.9
- [ ] `sqlc generate` wired into `make generate`; CI fails if generated code is stale vs. `.sql` sources
- [ ] Seed command (`cmd/seed`) loading OWASP Web/LLM/Agentic/API, MITRE ATLAS, CompTIA SecAI+ from JSON
- [ ] `GET /api/v1/frameworks`, `GET /api/v1/threats` (paginated)
- [ ] `golang-jwt` middleware — editor/admin roles in claims
- [ ] `swaggo/swag` → `/api/v1/docs/swagger-ui/`
- [ ] React scaffold: `npm create vite@latest frontend -- --template react-ts`, Shadcn/UI, Tailwind, Zustand

**Security checkpoint:** `golangci-lint` (gosec + staticcheck) passes with zero findings; `SecurityHeaders` active on every response; no `panic` in request-handling code paths.

### Phase 2 — Core Threat Browser (Sprints 3–4)
Covers: US-02, US-03, US-04
- [ ] `sqlc` queries: filter threats by framework, severity, stride, category, tag, q
- [ ] `GET /api/v1/threats/:id` with nested mitigations + code samples
- [ ] React `ThreatBrowserPage`, `ThreatDetailPage` (tabs: Overview | Attack Vectors | Mitigations | Code | Cross-References)
- [ ] `GET /api/v1/cross-references` — cross-framework mapping table
- [ ] React `MatrixPage` — OWASP ↔ MITRE ATLAS ↔ CompTIA mapping

**Security checkpoint:** `sqlc`-generated queries confirmed parameterized (D-02); no raw `fmt.Sprintf` building SQL anywhere (`golangci-lint` custom rule).

### Phase 3 — Card Decks & Content Integrity (Sprints 5–7)
Covers: US-05–US-12, US-19
- [ ] `internal/cards/loader.go` — `yaml.UnmarshalStrict` into `CardFile` struct for **all six** `docs/OWASP_stories/*.yaml` files
- [ ] `internal/integrity` — SHA-256 verification against `data/hashes.json`; called only from `cmd/api` boot and `cmd/worker`'s scheduled job (D-05)
- [ ] Card suit browsers: FRE, LLM, AAI, CLD (Companion), SP/TA/RE/ID/DS/EP (STRIDE), EMR/EIR/EOR/EDR (MLSec), PC/AA/NS/RS/CRM/CM (Mobile), VE/AT/SM/AZ/CR/C (Website App), **SCO/ARC/AGE/TRU/POR (Digital-by-Default Harms, US-19 — in scope from Phase 3, not bolted on later)**
- [ ] `CardKind` distinction enforced at the constructor level: `DESIGN_HARM` cards physically cannot carry a `Severity` value (Go's type system: the constructor for a `DESIGN_HARM` card takes no `Severity` parameter at all)
- [ ] `AttackDemoWarning` confirmation modal before rendering `ATTACK_DEMO` code samples

**Security checkpoint:** D-09 (strict YAML unmarshalling, no unknown fields); content hash mismatch aborts ingestion (`cmd/seed`/`cmd/worker` exit non-zero, no partial writes via a DB transaction); `DesignHarmBadge` component never shares styling with `SeverityBadge` (AC — see `user_stories+tests.md`).

### Phase 4 — Code Samples: 5 Languages (Sprints 7–9)
Covers: US-13–US-16
- [ ] Code sample seed data for every mitigation × 5 languages (Python, Java, Go, Scala, Lua)
- [ ] Attack-demo / defense sub-tabs, red-bordered warning label
- [ ] MITRE ATLAS Kill-Chain timeline (Recharts)

### Phase 5 — i18n Polish ↔ English (Sprint 9–10)
Covers: US-11
- [ ] `Accept-Language` middleware — allowlist `pl`/`en`, default `pl`
- [ ] `ThreatTranslation` served per-locale; `CornucopiaCard.DescriptionPl` fallback to English with an "EN" badge if missing
- [ ] React `react-i18next`; `LanguageToggle`; `gs_locale` in `localStorage`
- [ ] Code samples **never** translated
- [ ] CI check: i18n key-parity test fails the build on any missing `pl.json`/`en.json` key

### Phase 6 — Search, Export, Matrix Completion (Sprints 10–12)
Covers: US-06, US-07, US-08
- [ ] PostgreSQL full-text search (`tsvector` + GIN index) across threats, mitigations, cards
- [ ] `river.Job`-based export (`export.GenerateCSV`, `export.GeneratePDF` via `gofpdf` or `chromedp`-free HTML→PDF)
- [ ] `/matrix/llm`, `/matrix/agentic`, `/matrix/mobile-vs-web`, `/stride-heatmap`, `/matrix/digital-harms` (US-19)
- [ ] Redis sliding-window rate limit (D-08): 60 req/min/IP on all public list endpoints

### Phase 7 — Hardening, Testing & Release (Sprints 12–14)
Covers: full regression across US-01–US-19
- [ ] `go test ./...` with `testify`, coverage ≥ 85% on `internal/service`
- [ ] `httptest`-based integration tests for every handler
- [ ] Playwright (TypeScript) E2E — one scenario per user story
- [ ] `golangci-lint` + `govulncheck` in CI, zero HIGH findings
- [ ] OWASP ZAP full active scan against staging
- [ ] Production images: `cmd/api`/`cmd/worker` as `FROM scratch` static binaries; Nginx serving the Vite build

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
GET  /api/v1/export?format=csv&framework=OWASP_LLM     (enqueues river.Job, returns 202 + poll URL)
GET  /api/v1/export/status/:jobId
```

### Admin CRUD (JWT — ADMIN role)
```
POST   /api/v1/admin/threats
PUT    /api/v1/admin/threats/:id           — bluemonday.Sanitize applied (D-04)
DELETE /api/v1/admin/threats/:id
POST   /api/v1/admin/code-samples
PUT    /api/v1/admin/code-samples/:id
```
Note: `CornucopiaCard` rows (all six decks) have **no** admin write endpoint at all — not even a JWT-gated one. They are read-only application data, written only by `cmd/seed`/`cmd/worker`'s deck-ingestion path.

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
  /matrix                          → MatrixPage
  /matrix/llm, /matrix/agentic, /matrix/mobile-vs-web
  /stride-heatmap                  → StrideHeatmapPage (ProtectedRoute)
  /search                          → SearchResultsPage
  /about                           → AboutPage

Components:
  ThreatCard, CornucopiaCard, CodeSamplePanel, SeverityBadge,
  DesignHarmBadge (US-19 — never shares styling with SeverityBadge),
  BotWarningModal (US-11), StrideHeatmap, MatrixTable, LanguageToggle
```

---

## 9. Go Backend Package Layout

```
backend/
├── go.mod / go.sum
├── Makefile                          ← make generate / test / lint / run
├── cmd/
│   ├── api/main.go                   ← HTTP server entrypoint
│   ├── worker/main.go                ← River job consumer entrypoint
│   └── seed/main.go                  ← one-shot seeding + initial card ingestion
├── internal/
│   ├── domain/                       ← plain structs + enums (Section 5), zero dependencies
│   ├── http/
│   │   ├── router.go                 ← chi mount points
│   │   ├── middleware/
│   │   │   ├── auth.go               ← JWT verification, context injection
│   │   │   ├── ratelimit.go          ← Redis Lua sliding window (D-08)
│   │   │   ├── security_headers.go
│   │   │   └── recover.go            ← panic → generic 500, full detail logged server-side
│   │   └── handler/
│   │       ├── framework_handler.go
│   │       ├── threat_handler.go
│   │       ├── card_handler.go
│   │       ├── matrix_handler.go
│   │       ├── search_handler.go
│   │       ├── export_handler.go
│   │       └── admin_handler.go
│   ├── service/                      ← business logic, calls store + integrity, no HTTP types
│   ├── store/
│   │   ├── queries/*.sql             ← sqlc source
│   │   ├── sqlc-generated/           ← `sqlc generate` output, committed
│   │   └── pool.go                   ← pgx pool setup
│   ├── cards/
│   │   └── loader.go                 ← YAML → CornucopiaCard, calls integrity.Verify
│   ├── integrity/
│   │   └── verify.go                 ← the ONLY function allowed to mark content verified (D-05)
│   ├── jobs/
│   │   ├── export_csv.go
│   │   ├── export_pdf.go
│   │   ├── reingest_deck.go
│   │   └── periodic_reverify.go
│   └── config/
│       └── config.go                 ← env-based config struct
└── migrations/                       ← goose *.sql

frontend/                              ← React 18 + TS + Vite (structure mirrors app04_scala_react §8)

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

Every `Mitigation` ships exactly **five** `CodeSample` rows (one per language). Every `CornucopiaCard` mitigation has at least one sample demonstrating the secure pattern. Since the *application itself* is Go, the Go-language samples double as a second, simpler worked example of the same idioms used in the app's own `internal/` packages (parameterized `sqlc` queries, `bluemonday` sanitization, context-based auth) — students can compare the teaching sample against the app's real source.

| Language | Primary framework/library used in samples |
|---|---|
| Python | Django ORM / FastAPI + Pydantic |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | `chi` + `sqlc` + `pgx`, standard library `crypto` |
| Scala | Akka HTTP / http4s, Slick 3.x, ZIO 2 |
| Lua | OpenResty / NGINX Lua, `lua-resty-jwt`, LuaSQL |

```
sample_type: ATTACK_DEMO   # VULNERABLE — do not use in production
sample_type: DEFENSE       # SECURE pattern, with a one-line WHY comment
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
| OWASP A04:2021 Insecure Design — Digital-by-Default Harms | Scope/Architecture/Agency/Trust/Porosity | `SCO/ARC/AGE/TRU/POR` suits (US-19) — **not** a technical-vulnerability deck, see §15 note |

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
2. CI job `yaml-content-integrity`: schema validation (a Go `jsonschema` check reused from `internal/cards`) + injection-pattern grep + ref-allowlist validation.
3. Post-merge: a `hash-generator` CI step updates `data/hashes.json`.
4. `cmd/seed` and `cmd/worker`'s `ReingestDeck` job both call `internal/integrity.Verify` — on mismatch, ingestion aborts inside a single DB transaction (no partial writes) and a `SEC-CARD-HASH-MISMATCH` structured log line fires (`slog.Error`), which Loki alerts on.

---

## 13. Risk Register

| Risk | Mitigation |
|---|---|
| `sqlc` codegen drifts from `.sql` sources | `make generate` run in CI; build fails if `git diff` shows uncommitted generated code |
| YAML card files tampered in a PR | CODEOWNERS review + `internal/integrity.Verify` SHA-256 check, fail-secure |
| Digital-by-Default Harms deck misread as CVE severity | `CardKind` type + constructor-level enforcement (D-07-style); `DesignHarmBadge` never shares a component with `SeverityBadge` |
| Polish translations drift from English source | `ContentSHA256` stored per card; translation table flags staleness on English-text change |
| `internal/integrity.Verify` called from an unintended path | `depguard` lint rule forbids `internal/http/**` importing `internal/integrity`; enforced in CI, not just review |
| River job payload injection | `river.Job.Args` are typed Go structs, validated by `go-playground/validator` before enqueue — never a raw `map[string]any` |
| Redis rate-limit bypass via missing auth on Redis itself | `requirepass` set; Redis port not published in `docker-compose.yml` |
| Static binary still vulnerable at the Go-runtime/stdlib level | `govulncheck` in CI against the Go toolchain + module graph, not just third-party deps |
| Attack-demo code confused with production-safe code | Red border + `ATTACK_DEMO` badge + confirmation modal before code is shown/copied |
| Bot scraping the full catalogue | Redis sliding-window rate limit 60 req/min/IP (D-08) |

---

## 14. Directory Layout

```
app05_go_react/
├── PLAN.md
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
├── backend/            ← see §9 for full internal layout
├── frontend/            ← React 18 + TS + Vite (mirrors app04_scala_react structure)
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
| US-12 | Go/backend developer | browse Website App Cornucopia cards (VE/AT/SM/AZ/CR/C) | map classic OWASP Web Top 10 attack scenarios to mitigations |
| US-13 | Python developer | see a Python code sample for each mitigation | copy a secure implementation pattern |
| US-14 | Java developer | see a Java code sample for each mitigation | compare against the Go application's own idioms |
| US-15 | Scala developer | find Scala code samples for supply-chain attacks | implement SCA in a Scala pipeline |
| US-16 | Lua/OpenResty developer | see Lua examples for rate limiting preventing LLM DoS | configure NGINX guardrails for an LLM API proxy |
| US-17 | pentester | search a term and find related threats with defenses | assemble a client test checklist |
| US-18 | team lead | export the filtered threat list to CSV/PDF | include it in a risk register |
| US-19 | public-sector product owner / GRC reviewer | browse the "Digital-by-Default Harms" deck (SCO/ARC/AGE/TRU/POR), clearly separated from technical decks | assess digital-exclusion and opaque-design risk, map to A04:2021 |

*(US-11, the Polish↔English language switch, is folded into every story's acceptance criteria per FR-11 in `requirements.md` rather than numbered separately here — see requirements.md §2 FR-11 for the dedicated i18n requirement block.)*

---

## 16. Milestones & Acceptance Criteria

| Milestone | Deliverable | Done when |
|---|---|---|
| M1 | Working skeleton | `docker compose up` → `cmd/api` health check 200; React SPA loads |
| M2 | Full data seed | All frameworks + threats + mitigations in DB; API returns correct counts |
| M3 | All six card decks ingested | `internal/integrity` reports `isValid=true` for all six YAML files, including `dbd-cards-1.0-en.yaml` |
| M4 | Code samples complete | Every mitigation has 5 language samples visible on Threat Detail |
| M5 | Matrix + heatmap | Cross-reference table renders; STRIDE heatmap shows coverage % |
| M6 | i18n complete | PL/EN toggle everywhere; i18n key-parity CI check passes |
| M7 | Search + export work | Full-text search returns highlighted results; CSV/PDF export completes via River job |
| M8 | Digital-by-Default Harms | `DigitalHarmsPage` renders all 5 suits with `DesignHarmBadge`; A04:2021 cross-reference visible; no `Severity` field ever returned for `dbd` cards |
| M9 | Security hardening | `golangci-lint` + `govulncheck` zero HIGH; ZAP full scan zero HIGH |
| M10 | Tests green | ≥ 90% of TDD test list in `user_stories+tests.md` passing in CI |
