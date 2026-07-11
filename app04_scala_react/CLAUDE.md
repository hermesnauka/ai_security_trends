# app04_scala_react — ScalaShield 2026

Scala 3.3 LTS + ZIO 2 + ZIO HTTP 3.x backend with React 18 + TypeScript + Vite
frontend. Part of the `ai_security_trends` course mono-repo — read the **root
`CLAUDE.md` first**, then this file. Backend + frontend are both built and
runnable; this is Phase-1-only, not the full aspirational vision in `PLAN.md`.

## Key architectural decisions (full rationale: `PLAN.md` §4)

| Decision | What it means |
|---|---|
| D-02 ZIO Quill | All SQL is macro-expanded at compile time via `quill-jdbc-zio`; string-concatenated SQL is a compile error. |
| D-03/D-15 JWT HS256 | `jwt-scala` (`pdi.jwt`), not `jjwt`/`java-jwt`. Confirmed in code (`AuthRoutes.scala`): `Jwt.encode(claim, cfg.jwtSecret, JwtAlgorithm.HS256)`. Secret from `JWT_SECRET` env var, shared scheme with app01 — **this correctly matches app01's HS256 contract** (some early `PLAN.md` notes assumed RS256; that assumption was not carried into the actual code). |
| Flyway | Schema + seed data via versioned SQL migrations, run automatically on startup (`FlywayMigrator.migrate` before `Server.serve`). |

## What's actually implemented

Backend (`backend/src/main/scala/com/scalashield/`, ~500 lines total):
```
Main.scala                         ZIOApp: wires routes ++ CORS ++ security headers,
                                    runs Flyway migration before Server.serve
config/AppConfig.scala             env-var config (DB, JWT, admin creds)
db/DataSourceLive.scala            HikariCP ZLayer
db/FlywayMigrator.scala            Flyway migrate on startup
db/QuillContext.scala              PostgresZioJdbcContext(SnakeCase)
routes/AuthRoutes.scala            POST /api/v1/auth/login (HS256, bcrypt password check)
routes/FrameworkRoutes.scala       GET /api/v1/frameworks[/:code]
routes/ThreatRoutes.scala          GET /api/v1/threats[/:id] with frameworkCode/severity/
                                    stride/category/tag/q filters + page/size
repository/FrameworkRepository.scala   Quill queries
repository/ThreatRepository.scala      Quill dynamic filter query
model/                              Framework, ThreatSummary/ThreatDetail, Severity/
                                     StrideCategory enums, Page envelope
middleware/CorsMiddleware.scala             dev permissive CORS (nginx handles prod)
middleware/SecurityHeadersMiddleware.scala  CSP, HSTS, X-Frame-Options
```

Frontend (`frontend/src/`): React Router with only three routes — `/`
(Dashboard, shows a live threat count via `getThreats({size:1})`),
`/frameworks` (list), `/frameworks/:code` (detail, which *is* where threats
are actually browsed — `FrameworkDetail.tsx` fetches threats filtered by
`frameworkCode`). **There is no dedicated `/threats` list page, no
single-threat detail page, and no login UI** — the backend's login endpoint
and per-threat-by-id endpoint exist but nothing in the frontend calls or
exercises them. `src/api/client.ts` is a thin `fetch` wrapper matching the
contract shape.

No test suite exists yet on either side (no `backend/src/test/`, no frontend
test files) despite `zio-test`/`zio-test-sbt` being declared as dependencies
in `build.sbt`.

## Phase 1 API contract (implemented)

```
POST /api/v1/auth/login        {username, password} -> {token, tokenType:"Bearer", role:"ADMIN"} | 401
GET  /api/v1/frameworks        -> Framework[]
GET  /api/v1/frameworks/:code  -> Framework | 404
GET  /api/v1/threats           ?frameworkCode&severity&stride&category&tag&q&page&size -> Page<ThreatSummary>
GET  /api/v1/threats/:id       -> ThreatDetail | 404
GET  /health                   -> {"status":"UP"}
```
This matches app01's canonical contract closely, with two notes: `/health` is
the literal path here (confirmed in `Main.scala`) — unlike app01/app02, which
actually serve Spring Actuator's `/actuator/health` instead of the literal
path shown in the root contract block. Also, the contract's `sort` query
param is not parsed by `ThreatRoutes.scala` (only `page`/`size` are); no
route requires JWT auth yet — the login endpoint issues tokens but nothing
checks them (see "Not yet built" below).

## Directory layout

```
backend/
├── build.sbt                   ZIO + Quill + jwt-scala + jbcrypt + Flyway
├── project/                    build.properties (sbt 1.9.9), plugins.sbt (sbt-assembly)
├── Dockerfile
└── src/main/
    ├── scala/com/scalashield/  (layout above)
    └── resources/db/migration/
        ├── V1__init_schema.sql              all 9 tables (framework, threat, mitigation,
        │                                     code_sample, …)
        └── V2__seed_frameworks_and_threats.sql   OWASP Web/LLM, MITRE ATLAS, CompTIA SecAI+
frontend/                       React 18 + TS + Vite + Tailwind + react-router-dom
nginx/nginx.conf
docker-compose.yml
scripts/local-dev-up.sh, local-dev-down.sh
.env / .env.example
```

## DB

- Database `scalashield`, user `scalashield` (override via `DB_USER`).
- Shared Postgres instance on `:5432` across every app on this machine — see
  root `CLAUDE.md` for collision notes; this app's role/DB is distinct from
  app01's `securevision` and app06's `haskshield`.
- Flyway migrations in `src/main/resources/db/migration/` (see layout above).

## Environment variables

| Var | Default (dev) | Notes |
|---|---|---|
| `DB_HOST` | `localhost` | |
| `DB_PORT` | `5432` | |
| `DB_NAME` | `scalashield` | |
| `DB_USER` | `scalashield` | |
| `DB_PASSWORD` | `scalashield` | |
| `HTTP_PORT` | `8080` | |
| `JWT_SECRET` | dev default (weak) | **Must be ≥ 32 chars in production** |
| `JWT_EXPIRATION_HOURS` | `8` | |
| `ADMIN_USERNAME` | `admin` | |
| `ADMIN_PASSWORD_HASH` | bcrypt of `changeme-dev-only__` | Override in every deployment |

Copy `.env.example` to `.env` and fill in real values before running.

## Local dev (no Docker)

```bash
# 1. Ensure Postgres role/DB exist
psql -U postgres -c "CREATE ROLE scalashield LOGIN PASSWORD 'scalashield';" 2>/dev/null || true
psql -U postgres -c "CREATE DATABASE scalashield OWNER scalashield;" 2>/dev/null || true

# 2. Backend (Flyway runs automatically on startup)
cd backend && source ../.env && sbt run

# 3. Frontend (separate terminal)
cd frontend && npm install && npm run dev
```

Or `scripts/local-dev-up.sh` / `scripts/local-dev-down.sh` (both present).
`.local-dev/*.log` files (backend/frontend/postgres) are runtime logs from
prior runs, not part of the source layout.

## Build fat JAR / Docker

```bash
cd backend && sbt assembly   # -> target/scala-3.3.8/scalashield-backend-assembly-0.1.0-phase1.jar
docker compose up --build    # when Docker is available
```

## Not yet built (do not assume these exist)

- No test suite (backend or frontend), despite `zio-test` deps in `build.sbt`.
- No frontend login UI, no `/threats` list page, no single-threat detail page
  — threats are only visible filtered-by-framework on `FrameworkDetail.tsx`.
- No JWT verification middleware — only the login endpoint is wired; nothing
  protects any route yet (Phase 2+).
- Admin CRUD endpoints (`/api/v1/admin/*`) — Phase 2+.
- ZIO STM rate limiting (D-08) — Phase 2+.
- Cornucopia cards (D-06, D-07) — Phase 6+.
- i18n / `ThreatTranslation`, react-i18next (D-10) — Phase 5+.
- Full-text search — Phase 4+.
- Scalafix/Wartremover/Scapegoat compile-time SAST (D-13), `SafeHtml` sanitizer
  (D-14), opaque types (D-07/D-12) — all described in `PLAN.md` but not
  present in the actual `backend/src` tree today.

For the full aspirational 19-user-story design (not yet built), see
`PLAN.md`, `requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md` in
this directory — verify against the filesystem before assuming any of it
exists, per the root `CLAUDE.md`'s scope note.
