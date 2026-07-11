# SecurePress 2026 — running the application

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

Unlike most siblings in this repo, this app is **one self-contained WordPress plugin**, not a
separate backend service + SPA frontend — see `CLAUDE.md` for why. There is nothing to run
"backend and frontend together": one Docker Compose stack serves both the plugin's REST API
(`wp-json/securepress/v1/*`) and its server-rendered template pages (with progressively
enhanced vanilla JS) from the same WordPress/PHP-FPM process.

## Prerequisites

- Docker and Docker Compose
- A `.env` file (or exported shell variable) setting `SECUREPRESS_DB_PASSWORD` — `docker-compose.yml`
  refuses to start without it (`${SECUREPRESS_DB_PASSWORD:?set in .env, never committed}`)

This stack has **not been run in the environment these docs were written in** (no Docker
available there — see `CLAUDE.md`/`../CLAUDE.md`). Everything below is derived directly from
the real `docker-compose.yml`/`nginx/default.conf` in this directory, not verified end-to-end.

## Bring up the whole stack

```bash
cd app09_php_WORDPRESS
echo "SECUREPRESS_DB_PASSWORD=changeme-a-real-secret" > .env
docker compose up --build
```

This starts four containers:

| Service | Image | Role |
|---|---|---|
| `wordpress` | `wordpress:6.8-php8.3-fpm` | Runs the plugin (mounted read-write from `./wp-content/plugins/securepress-2026`) |
| `nginx` | `nginx:1.27-alpine` | Reverse proxy, listens on host port **8009** |
| `mysql` | `mysql:8.4` | Database — MySQL 8.4 satisfies the 8.0.16+ floor the `CHECK` constraints require |
| `redis` | `redis:7.4-alpine` | Object cache |

## First-time setup (no automation exists for this — do it manually)

There is no `wp-cli` step in `docker-compose.yml`, so WordPress itself and the plugin must be
set up by hand on first run:

1. Open `http://localhost:8009/` and complete the standard WordPress installation wizard
   (site title, admin username/password, etc.).
2. Log in to `/wp-admin/`, go to **Plugins**, and activate **SecurePress 2026**. This runs the
   plugin's activation hook (`Schema::create_tables()` — creates all `sp_*` tables via
   `dbDelta()`, then adds `FOREIGN KEY`/`FULLTEXT` constraints via `ALTER TABLE`) and seeds
   content (frameworks, the 20 OWASP Web/LLM Top 10 threats, 5 mitigations with 50 code
   samples across 5 languages, 6 Cornucopia decks).

## Verify it's working

- **Frontend (template pages):** `http://localhost:8009/` should show the plugin's home
  template listing security frameworks; the PL/EN language toggle should be visible.
- **REST API:** `curl http://localhost:8009/wp-json/securepress/v1/frameworks` should return a
  JSON array of frameworks (every route has an explicit `permission_callback`, so this
  particular one is public).
- **Threat detail:** browse to any seeded threat (e.g. via the frameworks list) and confirm
  mitigations + code-sample tabs render, with the attack-demo tab gated behind a confirmation
  click.

## Running the test suite (also unexecuted in this environment — no PHP/Composer/MySQL here)

```bash
cd wp-content/plugins/securepress-2026
composer install
composer exec phpunit          # tests/unit + tests/property
composer exec codecept run acceptance   # tests/acceptance (Codeception, needs a running site)
```

## Running the Playwright E2E suite

The 20 spec files under `e2e/` are TypeScript and only need Node (available separately from
the PHP/WordPress stack):

```bash
cd app09_php_WORDPRESS
npm install
npx playwright install   # first time only, downloads browsers
npx playwright test      # requires the docker-compose stack above already running
```
