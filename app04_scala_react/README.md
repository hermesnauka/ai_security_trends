# ScalaShield 2026

Interactive reference mapping security threats, vulnerabilities, and mitigations across OWASP, MITRE ATLAS, and CompTIA SecAI+. Sibling project to `app01_react`/`app02_angular` (Java/Spring Boot backends) - same domain model, but backend written in **Scala 3 + ZIO 2 + ZIO HTTP** with compile-time-verified SQL (ZIO Quill), contrasted directly against the Java sibling apps.

**Status:** Phase 1 — Foundation skeleton only. See `PLAN.md` for the full 9-phase roadmap (Cornucopia card catalogue including the Digital-by-Default Harms deck, i18n, full-text search, opaque-type ref validators, code samples in 5 languages, etc.) — none of that is implemented yet.

## What's here (Phase 1 / milestone M1)

- **Backend** (`backend/`): Scala 3.3.8 LTS, ZIO 2.1.26, ZIO HTTP 3.11.3, **ZIO Quill 4.8.6** for compile-time-checked SQL (D-02 — every query in this codebase is macro-verified against the schema at compile time; `sbt compile` prints the generated SQL for each one). `Framework`/`Threat` case classes, Flyway migrations for all 8 data-model entities (schema now, only Framework/Threat actually Quill-mapped - the rest wait for their own phase, same "schema now, logic later" pattern as the sibling apps). `GET /api/v1/frameworks`, `GET /api/v1/frameworks/:code`, paginated+filterable `GET /api/v1/threats` (`frameworkCode`, `severity`, `stride`, `category`, `tag`, `q`), `GET /api/v1/threats/:id`. `SecurityHeadersMiddleware` (CSP, HSTS, X-Frame-Options, X-Content-Type-Options) active on every response. Fat-jar production build via `sbt-assembly`.
- **Frontend** (`frontend/`): React 18 / TypeScript / Vite / Tailwind — same Dashboard/Frameworks/FrameworkDetail pages as `app01_react`'s Phase 1 (this app's own Phase 1 checklist doesn't call for anything beyond that scaffold either).
- **Infra**: `docker-compose.yml` (Postgres 16, Redis 7, backend, frontend behind nginx), `.env`/`.env.example`.

## What's deliberately NOT here yet

Everything in `PLAN.md` Phases 2–9.5: nested mitigations/code samples on threat detail, the cross-reference matrix, full-text search, CSV/PDF export, i18n (`ss_locale` toggle not wired), the entire Cornucopia card catalogue (FRE/LLM/AAI/STRIDE/MLSec/Mobile/DevOps/Digital-by-Default-Harms suits), the opaque-type `OwaspRefValidator`/`MitreAtlasRefValidator`/etc., `SafeHtml` (D-14), `jwt-scala` auth (D-15 - no admin/JWT at all yet, since Phase 1's own checklist doesn't call for it), rate limiting (ZIO STM token bucket, D-08), and the test suite (ZIO Test, Testcontainers, Playwright). Tapir + Swagger UI (tech-stack table) also didn't make it into Phase 1 - plain zio-http routes only, no `/api/v1/schema/swagger-ui/` yet.

## What was already sitting here before this build

This directory already had a `frontend/`, `nginx/`, `.env`, and `scripts/` before any of the above was written - a mechanical copy-paste of `app01_react`'s output (package.json said `"securevision-frontend"`, imports referenced `com.securevision.dto`, `docker-compose.yml`'s content had been pasted into `.env` instead of its own file). All of that has been rebranded/rewritten as part of this build; there was no working Scala backend at all - `backend/` didn't exist.

## Real bugs caught building this (worth knowing if you touch the build)

- **`sbt-assembly`'s default-ish merge strategy silently breaks JDBC driver loading.** A blanket `PathList("META-INF", _*) => discard` also discards `META-INF/services/java.sql.Driver` - the fat jar builds fine and then fails at runtime with "No suitable driver" because `DriverManager` can't find the Postgres driver via SPI. Fix: `MergeStrategy.concat` for `META-INF/services/*` specifically, discard the rest. Caught by actually running the assembled jar (`java -jar ...`), not just `sbt assembly` succeeding.
- **`zio-http` 3.11.x pulls `zio-json 0.9.1`** (via `zio-schema-json`) while **`quill-jdbc-zio` wants `zio-json 0.7.1`** - a real transitive version conflict sbt treats as a hard error by default. Fixed via `evictionErrorLevel := Level.Warn` (the newer zio-json is fine for the basic `DeriveJsonCodec` usage here).
- **Quill's dynamic-query `filterOpt` extension has a confusing type signature** for optional-filter predicates - `lift(v)` inside it produced `Quoted[V]` type mismatches against plain entity fields. Sidestepped by building the dynamic query with a `var` + `.foreach`-threaded `.filter(...)` calls instead, which has an unambiguous signature.
- **`Header.StrictTransportSecurity.MaxAge` / `Header.XContentTypeOptions.NoSniff` don't exist** in zio-http 3.11.3's typed header API (as remembered from older docs) - replaced with plain `Header.Custom(name, value)`.
- **`GET /api/v1/threats` initially returned a bare JSON array**, not the paginated `{content, totalElements, totalPages, number, size}` shape `PLAN.md` explicitly requires and the frontend (copied from `app01_react`) already expected - caught by actually loading the Dashboard page and checking, not just curling the endpoint once.

## Quick start

```bash
docker compose up --build
```

- Frontend: http://localhost:8081
- Backend API: http://localhost:8080/api/v1/frameworks
- Health: http://localhost:8080/api/v1/health

**M1 acceptance check (per `PLAN.md` §16):** `docker compose up` → `GET /api/v1/frameworks` returns JSON; `npm run dev` → React SPA loads. (The Docker build itself is untested on this machine - no Docker installed here, see below - but the underlying `sbt assembly` fat jar it depends on was run directly and verified working.)

### Local dev (without Docker)

```bash
# backend - needs sbt 1.9+ and a local Postgres on 5432 (see .env for creds)
cd backend && sbt run

# frontend - proxies /api/v1 to localhost:8080 via vite.config.ts
cd frontend && npm install && npm run dev
```

**This machine specifically** has no Docker installed. `scripts/local-dev-up.sh` /
`scripts/local-dev-down.sh` start/stop the same three pieces (Postgres, backend,
frontend) as standalone portable installs under `C:\Users\krish\tools\` instead
of containers (including a portable `sbt` under `tools/sbt/`). Machine-specific
(hardcoded tool paths) — not portable to other setups; use `docker compose` there instead.
