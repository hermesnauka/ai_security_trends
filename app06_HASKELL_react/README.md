# HaskShield 2026 (app06_HASKELL_react)

SecureVision's Haskell implementation: `servant` + `hasql` backend, Vite/React/TypeScript
frontend. Phase-1 scope only — mirrors `app01_react`'s actual (not aspirational) API contract.
See `CLAUDE.md` for the full current-state summary, `backend/CLAUDE.md`/`frontend/CLAUDE.md`
for stack-specific command/layout reference, and `../CLAUDE.md` for the shared sibling
conventions.

## There is no `docker-compose.yml` in this app

Unlike most siblings, this directory only has standalone `backend/Dockerfile` and
`frontend/Dockerfile`, plus `nginx/nginx.conf` — no compose file ties them together. Run
backend and frontend as two separate processes (see below). Don't invent a `docker compose up`
command for this app; it doesn't exist here.

## Prerequisites

- **GHC 9.8.4 + Cabal 3.16.1.0** (GHCup-managed) for the backend.
- **Node.js** + npm for the frontend (Vite + React 18 + TypeScript + Tailwind).
- **PostgreSQL**, reachable at whatever `DB_HOST`/`DB_PORT` you configure.
- A `.env` file (copy `.env.example`) with `POSTGRES_DB`/`POSTGRES_USER`/`POSTGRES_PASSWORD`,
  `DB_HOST`/`DB_PORT`/`DB_NAME`/`DB_USER`/`DB_PASSWORD`, `JWT_SECRET` (HS256, ≥32 bytes),
  `JWT_EXPIRATION_MINUTES`, `ADMIN_USERNAME`/`ADMIN_PASSWORD_HASH` (a bcrypt hash — the same
  `$2b$`/`$2a$`/`$2y$` format app01_react uses is directly interoperable here), and `PORT`.

## Quick start (this machine): `scripts/local-dev-up.sh`

This machine has no Docker installed, so `scripts/local-dev-up.sh` starts all three pieces
(Postgres, backend, frontend) as standalone portable installs under `C:\Users\krish\tools\`
and `C:\ghcup\` instead of containers — **machine-specific, hardcoded tool paths, not portable
to another setup**. (Its own header comment says "docker-compose.yml is the real, portable way
to run this project — use it if Docker is installed" — that line is stale/aspirational; no
compose file actually exists in this app, see above.)

```bash
./scripts/local-dev-up.sh
```

This creates/reuses a Postgres database named **`haskshield`**, not `securevision` — this
machine runs one shared, Docker-less Postgres instance across every `app0N_*` course project,
and `app01_react`'s Java/Flyway backend already owns a `securevision` database with its own
schema. Don't "fix" the DB name back to `securevision`; it would collide.

First run compiles every Haskell dependency from scratch and can take several minutes. Once up:

- Frontend: http://localhost:5173
- Backend API: http://localhost:8080/api/v1/frameworks
- Health: http://localhost:8080/health

Stop everything with:

```bash
./scripts/local-dev-down.sh
```

## Running it manually (any machine, without the script)

```bash
# 1. Postgres: create the `haskshield` database (or whatever DB_NAME you set) first.

# 2. Backend — from backend/, with DB_*/JWT_*/ADMIN_* exported per .env.example:
cd backend
cabal build all
cabal run api
# Applies migrations/*.sql on every startup (idempotent) before serving on :8080.

# 3. Frontend — in a second terminal:
cd frontend
npm install
npm run dev
# Vite dev server on :5173, proxies /api/v1 -> localhost:8080
```

## Verifying it's working

```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/frameworks
```

Then open http://localhost:5173 — Dashboard, Frameworks, FrameworkDetail, and Threats pages
should all load. **There is no login page in the frontend** — the `POST /api/v1/auth/login`
endpoint exists and works (`curl -X POST http://localhost:8080/api/v1/auth/login -H
'Content-Type: application/json' -d '{"username":"...","password":"..."}'`), but nothing in
`frontend/src` calls it yet (same gap noted for app01/app02).

## Running the tests

```bash
cd backend
cabal test
# ServiceSpec.hs: pure, hspec + QuickCheck, no DB needed
# ApiSpec.hs: hspec-wai, needs a real reachable Postgres (start one via
#             ../scripts/local-dev-up.sh first, or export DB_*/JWT_*/ADMIN_* manually)
```

```bash
cd frontend
npm run build   # tsc -b && vite build — clean as of the last verification
npm run lint    # eslint . --ext ts,tsx — clean as of the last verification
```

## Known deviations from app01_react (deliberate, see `CLAUDE.md`)

- Auth is JWT **HS256** with a shared `JWT_SECRET` — matches what app01's `JwtService` actually
  does, not the RS256 described in this app's own `PLAN.md`'s aspirational design.
- `stride`/`tags`/`cve_references` are native Postgres `TEXT[]`, not app01's comma-joined
  `TEXT` column (same JSON shape on the wire).
- Migrations run via a small custom runner (`src/Migrate.hs`), not `hasql-th` or Flyway.
