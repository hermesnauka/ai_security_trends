# ThreatView 2026

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

Sibling project to `app01_react`'s SecureVision 2026 - same domain model, different frontend stack (Angular + Material here, vs React + Tailwind there).

**Status:** Phase 1 — Foundation skeleton only. See `PLAN.md` for the full 9-phase roadmap (Cornucopia card catalogue, i18n, search, code samples in 5 languages, etc.) — none of that is implemented yet.

## What's here (Phase 1 / milestone M1)

- **Backend** (`backend/`): Spring Boot 3.3 / Java 21, package `com.threatview`. `Framework` and `Threat` entities, seeded via Flyway with OWASP Web Top 10, OWASP LLM Top 10, a representative slice of MITRE ATLAS, and CompTIA SecAI+. REST API with pagination and filtering (`frameworkCode`, `severity`, `stride`, `tag`, `q`). Stateless JWT auth skeleton (`/api/v1/auth/login`) securing a not-yet-built `/api/v1/admin/**`. OpenAPI docs at `/swagger-ui.html`.
- **Frontend** (`frontend/`): **Angular 18 standalone components + Angular Material 18** (custom indigo/amber M2 theme), TypeScript `strict`/`strictTemplates`. `AppComponent` shell (`mat-sidenav-container` + `mat-toolbar` + language toggle), `DashboardComponent` (stat cards, client-side quick search, inline framework list), all `ChangeDetectionStrategy.OnPush` + Signals per the plan's D-09. Per this app's own Phase 1 checklist (narrower than app01's), there is deliberately no separate `/frameworks` route yet — `FrameworkListComponent`/`FrameworkDetailComponent` are Phase 2.
- **Infra**: `docker-compose.yml` (Postgres 16, Redis 7, backend, frontend behind nginx), `.env`/`.env.example` for compose variable substitution.

## What's deliberately NOT here yet

Everything in PLAN.md Phases 2–9: nested mitigations/code-samples on threat detail, cross-reference matrix, full-text search, CSV/PDF export, i18n (ngx-translate wiring - the PL/EN toggle persists to `localStorage` under `tv_locale` but doesn't translate anything yet), the Cornucopia card catalogue (FRE/LLM/AAI/STRIDE/MLSec/Mobile/DevOps suits), rate limiting, admin CRUD endpoints, and the full test suite (Jest, Cypress E2E, ZAP scan). Tables for the later-phase entities (`Mitigation`, `CodeSample`, `CrossReference`, `ThreatTranslation`, `CornucopiaCard`, `ContentHash`) exist in the schema (V1 migration) but are not yet JPA-mapped or exposed via the API.

## Quick start

```bash
docker compose up --build
```

- Frontend: http://localhost:8081
- Backend API: http://localhost:8080/api/v1/frameworks
- Swagger UI: http://localhost:8080/swagger-ui.html

**M1 acceptance check (per PLAN.md §17):** `docker compose up` → Angular home + `/api/v1/frameworks` returns 200 JSON; `ng serve` also works standalone.

### Local dev (without Docker)

```bash
# backend - needs Maven 3.9+ and a local Postgres on 5432 (see .env for creds)
cd backend && mvn spring-boot:run

# frontend - proxies /api/v1 to localhost:8080 via proxy.conf.json
cd frontend && npm install && npm start
```

**This machine specifically** has no Docker installed. `scripts/local-dev-up.sh` /
`scripts/local-dev-down.sh` start/stop the same three pieces (Postgres, backend,
frontend) as standalone portable installs under `./tools/` instead
of containers. Machine-specific (hardcoded tool paths) — not portable to other
setups; use `docker compose` there instead.

### Admin login (dev-only credentials)

```
POST /api/v1/auth/login
{ "username": "admin", "password": "changeme-dev-only" }
```

`.env` ships with dev-only defaults for local use. Change `ADMIN_PASSWORD_HASH` and `JWT_SECRET` (and never commit real values) before running this anywhere other than a local machine.
