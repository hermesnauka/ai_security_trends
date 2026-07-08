# SecureVision 2026

Interactive reference mapping security threats, vulnerabilities, and mitigations across OWASP, MITRE ATLAS, and CompTIA SecAI+.

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
`scripts/local-dev-down.sh` start/stop the same three pieces (Postgres, backend,
frontend) as standalone portable installs under `C:\Users\krish\tools\` instead
of containers. Machine-specific (hardcoded tool paths) — not portable to other
setups; use `docker compose` there instead.

### Admin login (dev-only credentials)

```
POST /api/v1/auth/login
{ "username": "admin", "password": "changeme-dev-only" }
```

Change `ADMIN_PASSWORD_HASH` and `JWT_SECRET` before running this anywhere other than a local machine — the defaults in `docker-compose.yml` are not secrets, they're checked into a public-looking repo.
