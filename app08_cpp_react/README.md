# CppCitadel 2026 — running backend + frontend together

See `CLAUDE.md` for the full current-state notes and `../CLAUDE.md` for the shared repo
conventions. There is **no `docker-compose.yml` in this app** — the only automated path on
this machine is `scripts/local-dev-up.sh`. Both are documented below.

## Prerequisites

- PostgreSQL running and reachable (see `../CLAUDE.md` "Local dev environment" for the
  shared, Docker-less local instance this repo uses on this machine).
- A C++23 toolchain, [Conan](https://conan.io/) (2.x), and CMake ≥ 3.15.
- Node.js/npm for the frontend (Vite dev server).

## Option A — the fixed local-dev script (recommended on this machine)

```bash
./scripts/local-dev-up.sh
```

This script (fixed 2026-07-11 — it used to be a stale copy of `app01_react`'s script that ran
`mvn spring-boot:run` and never actually started this app's C++ backend, see `CLAUDE.md`)
now does all of the following, each step skipped if already satisfied:

1. Starts the shared local Postgres instance if it isn't running.
2. Creates the `cppcitadel` role/database and applies `backend/db/migrations/V1__init_schema.sql`
   + `V2__seed.sql` via `psql`, but **only the first time the database is created** — there is
   no migration-tracking table, so re-running the script does not re-apply migrations against
   an existing database.
3. Builds the backend if `backend/build/cppcitadel` doesn't exist yet (`conan install` →
   `cmake --preset conan-release` → `cmake --build --preset conan-release`).
4. Starts the `cppcitadel` binary on port `8080` (override with `HTTP_PORT`).
5. Starts the Vite frontend dev server on port `5173` (`npm run dev` inside `frontend/`).

When it finishes you'll see:

```
Frontend:    http://localhost:5173
Backend API: http://localhost:8080/api/v1/frameworks
```

Open `http://localhost:5173` in a browser for the frontend; `curl
http://localhost:8080/api/v1/frameworks` should return a JSON array once the backend is up.

Stop everything with:

```bash
./scripts/local-dev-down.sh
```

(This kills whatever is listening on ports `8080`/`5173` and stops the shared Postgres
instance — see `../CLAUDE.md`, stopping Postgres this way affects every other app on this
machine currently using it.)

## Option B — manual steps (portable, no script)

```bash
# 1. Postgres: create role/database once
psql -U postgres -c "CREATE ROLE cppcitadel WITH LOGIN PASSWORD 'cppcitadel';"
psql -U postgres -c "CREATE DATABASE cppcitadel OWNER cppcitadel;"
psql -U cppcitadel -d cppcitadel -f backend/db/migrations/V1__init_schema.sql
psql -U cppcitadel -d cppcitadel -f backend/db/migrations/V2__seed.sql

# 2. Backend: build once with Conan + CMake
cd backend
conan install . -of=build --build=missing -s build_type=Release
cmake --preset conan-release
cmake --build --preset conan-release

# 3. Backend: run (reads DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASSWORD/HTTP_PORT/JWT_SECRET/
#    JWT_EXPIRATION_HOURS/ADMIN_USERNAME/ADMIN_PASSWORD_HASH from the environment or .env —
#    see .env.example; every one of these has a dev-only default in Config.h if unset)
export DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME=cppcitadel DB_USER=cppcitadel DB_PASSWORD=cppcitadel
./build/cppcitadel
# -> listens on :8080 (HTTP_PORT)

# 4. Frontend, in a second terminal
cd frontend
npm install   # first time only
npm run dev
# -> listens on :5173, proxies API calls per frontend/src/api
```

Default admin login (dev only — `Config.h`'s fallback `ADMIN_PASSWORD_HASH`,
override in production): username `admin`. The matching plaintext password is whatever was
used to generate that bcrypt hash in your `.env` — set your own `ADMIN_USERNAME`/
`ADMIN_PASSWORD_HASH` rather than relying on the checked-in dev default for anything beyond a
quick local smoke test.

## Verifying it's working

```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/frameworks
```

Then open `http://localhost:5173` and confirm the frameworks list loads.

## What's NOT built yet

No test suite exists (`GoogleTest`/`GoogleMock`/`RapidCheck` from `PLAN.md` §5.7 are planned,
not scaffolded), no sanitizer flags are wired into `CMakeLists.txt`, and no `docker-compose.yml`
exists — see `CLAUDE.md` for the full current-state list before assuming a `PLAN.md` feature
exists.
