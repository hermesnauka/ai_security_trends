# ThreatCompass 2026

Interactive reference mapping security threats, vulnerabilities, and mitigations across OWASP, MITRE ATLAS, and CompTIA SecAI+. Sibling project to `app01_react` (Java/Spring Boot + React) and `app02_angular` (Java/Spring Boot + Angular) - same domain model, but written **entirely in Python/Django, end to end**, deliberately with no second backend language and no separate SPA build. See `PLAN.md` §0 for why.

**Status:** Phase 1 — Foundation skeleton only. See `PLAN.md` for the full 7-phase roadmap (Cornucopia card catalogue, i18n, full-text search, CSV/PDF export via Celery, code samples in 5 languages, etc.) — none of that is implemented yet.

## Why there's no `backend/`/`frontend/` split

Unlike its sibling apps, this project is a single Django project (`backend_django/`) - Django serves its own frontend via server-rendered templates + HTMX (Phase 2+) + Alpine.js, with no separate SPA build (`PLAN.md` §0, §12). Creating empty `backend/`/`frontend/` folders here would contradict the entire point of this sibling app existing.

## What's here (Phase 1 / milestone M1)

- **Django project** (`backend_django/`): Django 5.2 / Python 3.13, apps `frameworks`, `threats`, `cards`, `matrix`, `search`, `export`, `integrity`, `accounts` (per `PLAN.md` §12). `Framework` and `Threat` (+ `ThreatTranslation`, `Mitigation`, `CodeSample`, `CornucopiaCard`, `CrossReference`, `ContentHash` schemas - migrated now, not yet wired to views) models, seeded via `manage.py seed_frameworks` from `data/*.json` with OWASP Web Top 10, OWASP LLM Top 10, a representative slice of MITRE ATLAS, and CompTIA SecAI+ (34 threats across 4 frameworks). DRF API with pagination and filtering (`framework`, `severity`, `stride`, `category`, `tag`, `q`) at `/api/v1/threats/`, `/api/v1/frameworks/`. `drf-spectacular` Swagger UI at `/api/v1/schema/swagger-ui/`. JWT token endpoints (`djangorestframework-simplejwt`) at `/api/v1/auth/token/` - full `django-allauth` deferred until there's an actual admin CRUD endpoint to protect.
- **Server-rendered home page**: `base.html` (navbar, dark-mode toggle, PL/EN language toggle - both Alpine.js stubs that persist to `localStorage` but don't translate/restyle anything beyond the toggle itself yet) + `home.html` (stat cards, plain GET `?q=` search, framework tile grid). Styled with a **real compiled Tailwind CSS v3 build** (standalone CLI, no CDN, no Node needed) and a **locally-hosted Alpine.js** (no CDN), matching `PLAN.md`'s explicit "no CDN at runtime" constraint.
- **Infra**: `docker-compose.yml` (Postgres 16, Redis 7 password-protected and not published on the host per the plan's own risk register, Django/Gunicorn, Celery worker + beat on the same image with different entrypoints, nginx), `.env`/`.env.example`.

## What's deliberately NOT here yet

Everything in `PLAN.md` Phases 2–7: nested mitigations/code samples on threat detail, HTMX-driven filter panel, the cross-reference matrix, PostgreSQL full-text search, Celery-backed CSV/PDF export, real i18n (`.po`/`.mo` compilation - the toggle above is a persistence stub only), the six-deck Cornucopia card catalogue + `HashVerificationService` integrity checks, `django-allauth`, and the test suite (`pytest-django`, Playwright E2E, Bandit). The Celery worker/beat containers exist (per Phase 1's own checklist) but don't run any real tasks yet - they'll sit idle.

## Quick start

```bash
docker compose up --build
```

- Home: http://localhost:8081/
- API: http://localhost:8000/api/v1/frameworks/ (direct to Django; nginx also proxies it on :8081)
- Swagger UI: http://localhost:8000/api/v1/schema/swagger-ui/

**M1 acceptance check (per `PLAN.md` §14):** `docker compose up` → Django home renders, `/api/v1/frameworks` returns JSON.

### Local dev (without Docker)

```bash
cd backend_django
python -m venv .venv
.venv/Scripts/pip install -e .  # or the explicit package list in Dockerfile - see note below
.venv/Scripts/python manage.py migrate
.venv/Scripts/python manage.py seed_frameworks
.venv/Scripts/python manage.py runserver
```

**Note:** `pip install -e .` fails here with a setuptools flat-layout package-discovery error (Django's one-app-per-directory layout looks like "multiple top-level packages" to setuptools, since Django apps aren't meant to be pip-installed). Install the dependency list directly instead - see `Dockerfile` or `scripts/local-dev-up.sh` for the exact command.

**This machine specifically** has no Docker installed. `scripts/local-dev-up.sh` / `scripts/local-dev-down.sh` start/stop Postgres (shared instance across sibling apps on this machine) and the Django dev server from a local venv - Celery worker/beat are skipped since they don't run real tasks yet. Machine-specific — use `docker compose` elsewhere.

### Rebuilding Tailwind CSS after template changes

```bash
# standalone CLI, no Node needed - see scripts or download from
# https://github.com/tailwindlabs/tailwindcss/releases (v3.4.17 used here, pinned per PLAN.md)
tailwindcss -i backend_django/static/css/input.css -o backend_django/static/css/output.css --minify
```
