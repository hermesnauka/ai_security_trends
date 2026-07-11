# SecureVision 2026

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


**Status:** Phase 1 — Foundation skeleton only. See `PLAN.md` for the full 9-phase roadmap (Cornucopia card catalogue, i18n, search, code samples in 5 languages, etc.) — none of that is implemented yet.

## What's here (Phase 1 / milestone M1)

- **Backend** (`backend/`): Spring Boot 3.3 / Java 21. `Framework` and `Threat` entities, seeded via Flyway with OWASP Web Top 10, OWASP LLM Top 10, a representative slice of MITRE ATLAS, and CompTIA SecAI+. REST API with pagination and filtering (`frameworkCode`, `severity`, `stride`, `tag`, `q`). JWT auth skeleton (`/api/v1/auth/login`) securing a not-yet-built `/api/v1/admin/**`. OpenAPI docs at `/swagger-ui.html`.
- **Frontend** (`frontend/`): React 18 / TypeScript / Vite / Tailwind. Dashboard with stats and quick search, `/frameworks` tile browser, basic framework-detail threat list.
- **Infra**: `docker-compose.yml` (Postgres 16, Redis 7, backend, frontend behind nginx).

## What's deliberately NOT here yet

Everything in PLAN.md Phases 2–9: nested mitigations/code-samples on threat detail, cross-reference matrix, full-text search, CSV/PDF export, i18n (PL/EN toggle), the Cornucopia card catalogue (FRE/LLM/AAI/STRIDE/MLSec/Mobile/DevOps suits), rate limiting, admin CRUD endpoints, and the full test suite (E2E, ZAP scan, ≥80% coverage). Tables for the later-phase entities (`Mitigation`, `CodeSample`, `CrossReference`, `ThreatTranslation`, `CornucopiaCard`, `ContentHash`) exist in the schema (V1 migration) but are not yet JPA-mapped or exposed via the API.

## Quick start

```bash
docker compose up --build
```

- Frontend: http://localhost:8081
- Backend API: http://localhost:8080/api/v1/frameworks
- Swagger UI: http://localhost:8080/swagger-ui.html

**M1 acceptance check:** `docker compose up` → frontend loads the dashboard and `/api/v1/frameworks` returns JSON.

### Local dev (without Docker)

```bash
# backend - needs Maven 3.9+ and a local Postgres on 5432 (see docker-compose.yml for creds)
# no Maven wrapper is checked in yet; run `mvn -N wrapper:wrapper` once to add ./mvnw
cd backend && mvn spring-boot:run

# frontend
cd frontend && npm install && npm run dev
```

**This machine specifically** has no Docker installed. `scripts/local-dev-up.sh` /
`scripts/local-dev-down.sh` are a one-shot alternative that starts **all three**
pieces together: the shared local Postgres (if not already running), then
backend (`mvn spring-boot:run`, waits for `:8080`), then frontend
(`npm run dev`, waits for `:5173`) — logs land in `.local-dev/{postgres,backend,frontend}.log`.
Machine-specific (hardcoded tool paths under `C:\Users\krish\tools\`) — not
portable to other setups; use `docker compose` there instead.

**Known issue if you use `local-dev-up.sh`:** its Postgres-provisioning step
hardcodes `CREATE DATABASE threatview ...`, not `$POSTGRES_DB` — if your
`POSTGRES_DB` isn't literally `threatview`, the backend will fail to connect
because the database it actually needs doesn't exist yet. Create it manually
(`createdb -U securevision -h 127.0.0.1 $POSTGRES_DB`) as a workaround, or fix
the script.

### Admin login (dev-only credentials)

```
POST /api/v1/auth/login
{ "username": "admin", "password": "changeme-dev-only" }
```

Change `ADMIN_PASSWORD_HASH` and `JWT_SECRET` before running this anywhere other than a local machine — the defaults in `docker-compose.yml` are not secrets, they're checked into a public-looking repo.
