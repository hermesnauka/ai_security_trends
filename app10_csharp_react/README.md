# SharpGuard 2026 — running backend + frontend together

Only for self-educational purpose and "open" standard community and values:
this is an interactive reference mapping security threats, vulnerabilities, and mitigations across OWASP (with Cornucopia cards and game concepts), MITRE ATLAS, and CompTIA SecAI+, ml-ops.org CRISP-ML(Q), SSDLC, Security Architects game concept with cards (by Sroka), etc. (information gathered from all these sources like: OWASP, MITRE ATLAS etc.).
This is only a kind of "snapshot" of knowledge gathered together in 2026, in july (and not being updated continuously).


## Quick start: ./$PROJECT/scripts/local-dev-up.sh script (recommended)

ATTENTION!!! Remember about hiding secrets and passwords in Vaults, secured .env file (not commited) or environment variables (like "${POSTGRES_PASSWORD}") to keep them in secret.
In this manual secrets and passwords are not secured in such proper way: only for educational purpose and better understanding what is going on. Learn how to hide and keep in secret in Vaults... You can run this open-source code at your own risk. Caveat emptor. 

### Quick start:

```bash
./scripts/local-dev-up.sh
```

See `CLAUDE.md` for architecture/design notes and `../CLAUDE.md` for the sibling-repo
conventions this project follows. This file only covers how to actually run it.

There is no `docker-compose.yml` in this directory yet, so Docker Compose is not an
option here (unlike several sibling apps) — use one of the two paths below instead.

## Option A — this machine's Docker-less local-dev scripts

Requires: a portable Postgres install, the .NET 9 SDK, and Node.js — see
`scripts/local-dev-up.sh` for the exact tool paths this machine uses; adjust `PGBIN`/`PGDATA` in that script if running
elsewhere.

1. `cp backend/.env.example backend/.env` and fill in every value — `DB_PASSWORD`,
   `JWT_SECRET`, `ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH` are all required with no
   hardcoded fallback; the backend refuses to start if any are blank. Generate a bcrypt
   hash for `ADMIN_PASSWORD_HASH` (e.g. via `dotnet` or any bcrypt CLI) — it is a hash,
   not the plaintext password.
2. From the app root, run:
   ```bash
   scripts/local-dev-up.sh
   ```
   This starts, in order: Postgres (if not already running), the backend
   (`dotnet run --project backend/src/SharpGuard.Api`) on **:8080**, and the frontend
   (`npm run dev`, Vite) on **:5173** — waiting for each to respond before starting the
   next, and logging to `.local-dev/{postgres,backend,frontend}.log`.
3. Open **http://localhost:5173** for the frontend. The backend API is directly
   reachable at **http://localhost:8080/api/v1/...**; Vite's dev server also proxies
   `/api/v1/*` to it (see `frontend/vite.config.ts`), so the frontend can call relative
   paths either way.
4. Verify the backend is up: `curl http://localhost:8080/health` → `{"status":"UP"}`.
5. Stop everything with:
   ```bash
   scripts/local-dev-down.sh
   ```

Note: this app directory also has a root-level `.env`/`.env.example` — neither is read
by any script here; only `backend/.env` matters. Don't confuse the two.

## Option B — manual, without the local-dev scripts

Requires: PostgreSQL reachable at the host/port you configure, the .NET 9 SDK, Node.js.

```bash
# Terminal 1 — backend (:8080)
cd backend
cp .env.example .env   # fill in DB_PASSWORD, JWT_SECRET, ADMIN_USERNAME, ADMIN_PASSWORD_HASH
set -a; source .env; set +a
dotnet run --project src/SharpGuard.Api

# Terminal 2 — frontend (:5173)
cd frontend
npm install
npm run dev
```

The backend applies its EF Core migration and seeds reference data (frameworks +
threats) automatically on startup — no separate migrate/seed step needed.

Open **http://localhost:5173**. Log in with the admin username/password you set (the
password itself, not the hash, from step above) — `POST /api/v1/auth/login` returns a
bearer token used for any authenticated call.

## Production-ish local setup (nginx reverse proxy)

`nginx/nginx.conf` proxies `/api/v1/*` and `/swagger-ui/*` to the backend and serves the
frontend's built static files — but nothing in this directory currently builds a Docker
image or Compose stack around it, and it is **not** part of the `local-dev-up.sh` path
above. To use it manually: `npm run build` in `frontend/` (outputs `frontend/dist/`),
point nginx's `root` at that directory, and run nginx yourself with `nginx/nginx.conf`
loaded — there is no automated script wiring this together yet.
