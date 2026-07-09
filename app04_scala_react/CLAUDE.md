# app04_scala_react — ScalaShield 2026

Scala 3.3 LTS + ZIO 2 + ZIO HTTP 3.x backend with React 18 + TypeScript + Vite frontend.
Part of the `ai_security_trends` course mono-repo — read the **root `CLAUDE.md` first**, then this file.

## Key architectural decisions (see PLAN.md §4 for full rationale)

| Decision | What it means |
|---|---|
| D-02 ZIO Quill | All SQL is macro-expanded at compile time. String-concatenated SQL is a compile error. |
| D-03 JWT HS256 | `jwt-scala` (`pdi.jwt`), NOT `jjwt`/`java-jwt`. Secret comes from `JWT_SECRET` env var (shared with sibling apps). **NOT RS256** — that assumption in early PLAN.md notes is wrong; app01 (the contract) uses HS256. |
| D-15 jwt-scala | `pdi.jwt` API: `JwtClaim`, `Jwt.encode/decode`, `JwtAlgorithm.HS256`. Scala-idiomatic `Try`/`Either` — no Java exception types cross into app code. |

## Phase 1 API contract (implemented)

```
POST /api/v1/auth/login        {username, password} -> {token, tokenType:"Bearer", role:"ADMIN"} | 401
GET  /api/v1/frameworks        -> Framework[]
GET  /api/v1/frameworks/:code  -> Framework | 404
GET  /api/v1/threats           ?frameworkCode&severity&stride&tag&q&page&size -> Page<ThreatSummary>
GET  /api/v1/threats/:id       -> ThreatDetail | 404
GET  /health                   -> {"status":"UP"}
```

## Directory layout (backend)

```
backend/
├── build.sbt                   ← ZIO + Quill + jwt-scala + jbcrypt + Flyway
├── project/
│   ├── build.properties        ← sbt 1.9.9
│   └── plugins.sbt             ← sbt-assembly
└── src/main/scala/com/scalashield/
    ├── Main.scala              ← ZIOApp: routes ++ CORS ++ SecurityHeaders
    ├── config/AppConfig.scala  ← env-var config (DB, JWT, admin creds)
    ├── db/
    │   ├── DataSourceLive.scala  ← HikariCP ZLayer
    │   ├── FlywayMigrator.scala  ← Flyway migrate on startup
    │   └── QuillContext.scala    ← PostgresZioJdbcContext(SnakeCase)
    ├── routes/
    │   ├── AuthRoutes.scala      ← POST /api/v1/auth/login (jwt-scala HS256)
    │   ├── FrameworkRoutes.scala ← GET /api/v1/frameworks[/:code]
    │   └── ThreatRoutes.scala    ← GET /api/v1/threats[/:id]
    ├── repository/
    │   ├── FrameworkRepository.scala ← Quill queries
    │   └── ThreatRepository.scala    ← Quill dynamic filter query
    ├── model/
    │   ├── Framework.scala       ← case class + JsonCodec
    │   ├── Threat.scala          ← ThreatSummary, ThreatDetail, Severity enum
    │   └── Page.scala            ← Spring Data-style pagination envelope
    └── middleware/
        ├── CorsMiddleware.scala        ← dev permissive CORS (nginx handles prod)
        └── SecurityHeadersMiddleware.scala ← CSP, HSTS, X-Frame-Options
```

## DB

- Database: `scalashield`
- User: `scalashield` (or set via `DB_USER` env var)
- Shared Postgres instance on `:5432` — see root `CLAUDE.md` for collision notes
- Flyway migrations: `src/main/resources/db/migration/`
  - `V1__init_schema.sql` — all 9 tables (framework, threat, mitigation, code_sample, …)
  - `V2__seed_frameworks_and_threats.sql` — OWASP Web/LLM, MITRE ATLAS, CompTIA SecAI+

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
# 1. Ensure Postgres is running and the scalashield DB/role exists
psql -U postgres -c "CREATE ROLE scalashield LOGIN PASSWORD 'scalashield';" 2>/dev/null || true
psql -U postgres -c "CREATE DATABASE scalashield OWNER scalashield;" 2>/dev/null || true

# 2. Start backend (Flyway runs automatically on startup)
cd backend
source ../.env   # set env vars
sbt run

# 3. Start frontend (separate terminal)
cd frontend
npm install && npm run dev
```

Or use `scripts/local-dev-up.sh` / `scripts/local-dev-down.sh`.

## Build fat JAR

```bash
cd backend && sbt assembly
# → target/scala-3.3.8/scalashield-backend-assembly-0.1.0-phase1.jar
```

## Docker (when Docker is available)

```bash
docker compose up --build
```

## What's NOT in Phase 1

- Admin CRUD endpoints (`/api/v1/admin/*`)
- JWT middleware protecting routes (only the login endpoint is wired; admin routes come Phase 2+)
- ZIO STM rate limiting (Phase 2+)
- Cornucopia cards (Phase 6+)
- i18n / ThreatTranslation (Phase 5+)
- Full-text search (Phase 4+)
