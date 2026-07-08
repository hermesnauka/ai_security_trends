# ThreatCompass 2026 — Django implementation (app03_python_django)

The Python implementation: **entirely Django, end to end** — no second backend
language, and deliberately **no separate SPA**. Django serves its own frontend
via server-rendered templates (+ HTMX/Alpine.js planned for later phases). See
`PLAN.md` §0 and `README.md` ("Why there's no `backend/`/`frontend/` split") —
confirmed by reading both; this is a documented deliberate choice, not an
oversight. See `../CLAUDE.md` for the sibling list and shared local-dev setup.

## Known deliberate deviations from sibling convention (don't "fix" these back)

- **Backend lives in `backend_django/`, not `backend/`.** Every other sibling with a
  backend (`app01_react`, `app02_angular`, `app05_go_react`, `app06_HASKELL_react`) uses
  `backend/`. This one doesn't — it's a real naming deviation, not a typo. Don't rename
  it to match; nothing else in the course tooling assumes `backend/` here, but if you
  write scripts that assume the sibling convention, special-case this app.
- **No `frontend/` directory at all.** Django's `templates/` (`base.html`, `home.html`)
  + `static/` (compiled Tailwind CSS, local Alpine.js — no CDN at runtime) *is* the
  frontend. Creating an empty `frontend/` here to match siblings would contradict the
  entire point of this app existing (see README §"Why there's no split").
- **Hybrid, not pure server-rendered:** this app exposes *both* a server-rendered home
  page (`GET /`) *and* a real JSON DRF API under `/api/v1/*`, plus a Swagger UI
  (`drf-spectacular`) at `/api/v1/schema/swagger-ui/`. It is not purely HTML-only like a
  classic Django app.

## Scope: this is Phase-1 (M1) only, not the full vision

`PLAN.md`, `requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md` describe a
7-phase, 19-user-story end state (six OWASP Cornucopia card decks, full i18n PL/EN,
Celery-backed CSV/PDF export, cross-framework matrix, code samples in 5 languages,
`django-allauth`). **Almost none of that is built.** What exists: `frameworks` and
`threats` apps with working models/views/serializers; `cards`, `matrix`, `export`,
`integrity`, `search`, `accounts` apps exist as Django app scaffolding (mostly just
`apps.py` + migrations, no real views yet — `search` has no models or views at all).
Read `PLAN.md` for the destination, but don't assume anything past what's below is
wired up.

## Actual API contract as implemented (NOT app01's canonical shape — see `../CLAUDE.md`)

This app's DRF endpoints exist but use **different param/path conventions** than
app01's canonical contract (`app01_react/backend/.../com/securevision/`):

```
GET  /                          -> server-rendered home.html (framework tiles, ?q= plain search)
POST /api/v1/auth/token/        {username, password} -> {access, refresh}   (simplejwt, NOT /auth/login)
POST /api/v1/auth/token/refresh/ {refresh} -> {access}
GET  /api/v1/frameworks/        -> Framework[]                (unpaginated, trailing slash required)
GET  /api/v1/frameworks/:code/  -> Framework | 404
GET  /api/v1/threats/           ?framework&severity&stride&category&tag&q -> Threat[] (DRF default, no page/size/sort yet)
GET  /api/v1/threats/:pk/       -> ThreatDetail | 404
GET  /api/v1/schema/swagger-ui/ -> Swagger UI (drf-spectacular)
```

Note the differences from app01: query param is `framework` not `frameworkCode`; no
`Page<T>` envelope (DRF's default list, not Spring Data's); auth path is
`/auth/token/` returning simplejwt's `{access, refresh}`, not `/auth/login` returning
`{token, tokenType, role}`; detail lookup is `:pk`/`:code` not `:id`. If you're asked to
bring this into parity with app01's contract, that's a deliberate follow-up task, not a
bug fix — check with the plan before changing DRF serializers to match Spring's shape.

## Data seeded so far

`manage.py seed_frameworks` loads `backend_django/data/*.json` (OWASP Web Top 10, OWASP
LLM Top 10, a MITRE ATLAS slice, CompTIA SecAI+) — 4 frameworks, 34 threats. The six
Cornucopia YAML decks referenced throughout `PLAN.md` are **not** ingested; `cards`
app's models exist but are empty.

## Running the stack locally

`docker compose up --build` (Postgres 16, Redis 7, Django/Gunicorn, Celery worker+beat
idle, nginx) — home at `:8081`, API direct at `:8000`. This machine has no Docker (see
`../CLAUDE.md`); use `scripts/local-dev-up.sh` / `scripts/local-dev-down.sh` instead
(shared Postgres across sibling apps, Celery skipped since no real tasks run yet).
`pip install -e .` fails here with a setuptools flat-layout discovery error — install
deps directly per `Dockerfile` instead, don't "fix" the `pyproject.toml` layout to force
editable installs.

Rebuild Tailwind after template edits: standalone CLI (no Node), see README's exact
command — `tailwindcss -i backend_django/static/css/input.css -o .../output.css --minify`.
