# ThreatCompass 2026 — Django implementation (app03_python_django)

The Python implementation: **entirely Django, end to end** — no second backend
language, and deliberately **no separate SPA**. Django serves its own frontend via
server-rendered templates (HTMX planned for a later phase, not present yet) plus a
locally-hosted Alpine.js. See `PLAN.md` §0 and `README.md` for the full rationale.
See `../CLAUDE.md` for the sibling list and shared local-dev notes.

## Deliberate deviations from sibling convention (don't "fix" these back)

- **Backend lives in `backend_django/`, not `backend/`.** Real naming deviation, not a
  typo — special-case this app in any cross-repo tooling that assumes `backend/`.
- **No `frontend/` directory.** `backend_django/templates/` (`base.html`, `home.html`) +
  `backend_django/static/` (compiled Tailwind CSS v3, local Alpine.js — no CDN) *is* the
  frontend.
- **Hybrid, not pure server-rendered.** `GET /` is a server-rendered home page, but the
  app also exposes a real JSON DRF API under `/api/v1/*` plus Swagger UI
  (`drf-spectacular`) at `/api/v1/schema/swagger-ui/`.
- **Contract shape does not match app01.** Per the root `CLAUDE.md`, app03 is a named
  exception to "mirror app01's API" — see contract section below. Bringing it into
  parity with app01 is a deliberate follow-up task, not a bug fix.

## Current state (what's actually implemented — verified against source, not PLAN.md)

Django 5.2 / Python 3.13. `INSTALLED_APPS`: `frameworks`, `threats`, `cards`, `matrix`,
`search`, `export`, `integrity`, `accounts` (`backend_django/threatcompass/settings/base.py`).

**Wired up and working:**
- `frameworks` and `threats` apps: real models, DRF serializers, generic views, `urls.py`,
  registered in `threatcompass/urls.py`. This is the only real functionality in the app.
- `accounts` app: no models, but a real `urls.py` delegating to
  `djangorestframework-simplejwt`'s `TokenObtainPairView`/`TokenRefreshView`.
- `HomeView` (`frameworks/views.py`): server-rendered `home.html` — framework tiles, plain
  `?q=` GET search over framework name/code, stat counts. No HTMX yet (Phase 2 scope).
- `manage.py seed_frameworks` loads `backend_django/data/*.json` (OWASP Web Top 10, OWASP
  LLM Top 10, a MITRE ATLAS slice, CompTIA SecAI+) — 4 frameworks, 34 `Threat` rows.

**Scaffolding only (app registered, migrations exist, no views/API wired):**
- `cards` (`CornucopiaCard` model), `matrix` (`CrossReference` model), `integrity`
  (`ContentHash` model) — real models + `0001_initial` migrations, `admin.py` registered,
  but nothing served via the API. Same for `ThreatTranslation`, `Mitigation`, `CodeSample`
  models living inside `threats/models.py` — migrated, not exposed anywhere yet.
- `export`, `search` — **no models, no migrations at all**, just an empty `AppConfig` each
  (`apps.py` + `__init__.py`). These are further behind than `cards`/`matrix`/`integrity`.

Read `PLAN.md` for the 7-phase, 19-user-story destination (six Cornucopia decks, full
i18n, Celery CSV/PDF export, cross-framework matrix, 5-language code samples,
`django-allauth`) — don't assume anything past what's listed above is real.

## Actual API contract as implemented (NOT app01's shape — deliberate, see `../CLAUDE.md`)

```
GET  /                           -> server-rendered home.html (framework tiles, ?q= search)
POST /api/v1/auth/token/         {username, password} -> {access, refresh}   (simplejwt, not /auth/login)
POST /api/v1/auth/token/refresh/ {refresh} -> {access}
GET  /api/v1/frameworks/         -> Framework[]                 (unpaginated — pagination_class=None)
GET  /api/v1/frameworks/:code/   -> Framework | 404
GET  /api/v1/threats/            ?framework&severity&stride&category&tag&q -> paginated (DRF PageNumberPagination, {count,next,previous,results}, PAGE_SIZE=20; no explicit `sort`/ordering param)
GET  /api/v1/threats/:pk/        -> ThreatDetail | 404
GET  /api/v1/schema/swagger-ui/  -> Swagger UI (drf-spectacular)
```

Key differences from app01's canonical contract (`app01_react/backend/.../com/securevision/`):
query param is `framework` not `frameworkCode`; list envelope is DRF's own
`{count,next,previous,results}`, not Spring Data's `Page<T>`; auth path is
`/auth/token/` returning simplejwt's `{access, refresh}`, not `/auth/login` returning
`{token, tokenType, role}`; detail lookup is `:pk`/`:code`, not `:id`.

**Gotcha:** `REST_FRAMEWORK["DEFAULT_PERMISSION_CLASSES"]` is `AllowAny` globally
(`settings/base.py`) — the JWT auth classes are configured but nothing currently requires
a token. `frameworks`/`threats` endpoints are fully open reads with no auth enforcement
yet, despite simplejwt being wired.

## Database — this app's name in the shared local Postgres

Per `../CLAUDE.md`, Postgres is one shared Docker-less instance across sibling apps on
this machine. This app's role/DB is **`threatcompass`** (see `scripts/local-dev-up.sh` and
`DATABASES["default"]` defaults in `settings/base.py` — both default to `threatcompass`/
`threatcompass`). Distinct from app01's `securevision` and app06's `haskshield`.

## Running the stack locally

- **Docker Compose** (`docker compose up --build`): Postgres 16, Redis 7 (password-set,
  no host port published, per PLAN.md's risk register), Django/Gunicorn, Celery
  worker+beat (idle — no real tasks exist yet), nginx. Home + API proxied at `:8081`;
  Django direct at `:8000`; Swagger at `:8000/api/v1/schema/swagger-ui/`.
- **This machine has no Docker** (see `../CLAUDE.md`) — use `scripts/local-dev-up.sh` /
  `scripts/local-dev-down.sh` instead. This starts Postgres + a Django dev server from a
  local venv directly on **`:8000`** (no nginx involved, so no `:8081` in this mode).
  Celery is skipped (nothing real to run). Uses the shared cross-app Postgres instance.
- `pip install -e .` fails in `backend_django/` with a setuptools flat-layout
  package-discovery error (Django's one-app-per-directory layout looks like multiple
  top-level packages to setuptools). Install the explicit dependency list from
  `Dockerfile` / `pyproject.toml` `[project.dependencies]` directly instead — don't
  "fix" this by restructuring `pyproject.toml` for editable installs.

Rebuild Tailwind after template edits (standalone CLI, no Node, v3.4.17 pinned):
```
tailwindcss -i backend_django/static/css/input.css -o backend_django/static/css/output.css --minify
```

## Where to look for more

`PLAN.md` (architecture, phased roadmap, schema detail), `requirements.md`,
`SDLC_analysis.md`, `user_stories+tests.md`, `README.md` (quick start). All describe the
full aspirational end state — cross-check any claim against `backend_django/` source
before relying on it, the same way this file was verified.
