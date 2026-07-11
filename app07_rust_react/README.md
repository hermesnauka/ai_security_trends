# RustBastion 2026 — Running backend + frontend together

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

See `CLAUDE.md` for the full architecture/design-decision notes. This file only covers how to
actually start the app.

## Option A — Docker Compose (recommended, works anywhere Docker is installed)

```bash
cp .env.example .env
# edit .env: set POSTGRES_DB/USER/PASSWORD, JWT_SECRET, JWT_EXPIRATION_MINUTES, ADMIN_USERNAME

# generate ADMIN_PASSWORD_HASH (Argon2id) before first run:
cd backend && cargo run --bin hash_password -- 'your-admin-password' && cd ..
# paste the printed hash into .env as ADMIN_PASSWORD_HASH

docker compose up --build
```

This starts all three services together:

| Service | Container port | Host port |
|---|---|---|
| `postgres` | 5432 | 5432 |
| `backend` (axum) | 8080 | 8080 |
| `frontend` (nginx serving the built Vite app) | 80 | **8081** |

Verify it's up:

```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/v1/frameworks
open http://localhost:8081        # frontend
```

Migrations run automatically at backend startup (`run_migrations` in `main.rs`) — no separate
migrate step needed.

## Option B — run backend and frontend directly (no Docker)

**Do not use `scripts/local-dev-up.sh`/`local-dev-down.sh`** — they are stale leftover copies
of `app01_react`'s scripts and drive `mvn spring-boot:run` against a Spring Boot backend that
doesn't exist here; running them will not start this Rust backend (see `CLAUDE.md`'s "Gotcha"
section). Start each piece directly instead:

```bash
# 1. Postgres must be running and reachable — either the shared local instance
#    described in ../CLAUDE.md, or your own.

# 2. Backend (terminal 1)
cd backend
export DATABASE_URL=postgres://<user>:<password>@localhost:5432/<db>
export JWT_SECRET=... JWT_EXPIRATION_MINUTES=60 ADMIN_USERNAME=... ADMIN_PASSWORD_HASH=...
export BIND_ADDR=0.0.0.0:8080          # optional, this is the default
cargo run

# 3. Frontend (terminal 2)
cd frontend
npm install
npm run dev                             # Vite dev server, defaults to http://localhost:5173
```

With this option: backend is `http://localhost:8080`, frontend dev server is
`http://localhost:5173` (not 8081 — that port only exists in the Docker Compose topology,
where nginx serves the production build). The Vite dev server proxies API calls to the
backend automatically in dev mode — check `frontend/vite.config.ts` if you need to change the
target.

## Verifying everything works end to end

1. `curl http://localhost:8080/health` → `{"status":"UP"}` (or equivalent).
2. Open the frontend in a browser, log in with `ADMIN_USERNAME`/the plaintext password you
   hashed in step 1 of Option A (or whatever you set `ADMIN_PASSWORD_HASH` to represent).
3. Confirm the Frameworks/Dashboard pages load real seeded data from `backend/migrations/0002_seed_data.sql`.
