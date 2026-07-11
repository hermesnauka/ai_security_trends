# RubyGuard 2026 — Running backend + frontend together

See `CLAUDE.md`/`PLAN.md` for the full architecture. This file only covers how to get both
halves running at once. Two ways to do it — Docker Compose (recommended, fewest manual
steps) or the local-dev scripts (this machine's Docker-less convention, `../CLAUDE.md`).

## Option A: Docker Compose (backend + Postgres + Nginx-served frontend, one command)

Prerequisites: Docker and Docker Compose.

```bash
cd app13_ruby_FastApi
JWT_SECRET="$(openssl rand -hex 32)" ADMIN_PASSWORD=changeme docker compose up --build
```

This starts three containers (`docker-compose.yml`):

| Service | What it runs | Port |
|---|---|---|
| `postgres` | Postgres 16, DB `rubyguard_development` | `5433` → container's `5432` (avoids colliding with this machine's shared local Postgres on `5432`) |
| `backend` | `bundle exec rake db:migrate db:seed db:seed_admin`, then Puma serving the Grape API | `9292` |
| `nginx` | Serves `frontend/` static files directly, proxies `/api/*` and `/health` to the backend | `8080` → container's `80` |

Open **http://localhost:8080** for the frontend. It calls the backend through Nginx's `/api/*`
proxy, so no CORS configuration is needed in this mode.

Verify it's up:
```bash
curl http://localhost:8080/health          # -> {"status":"UP"}
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"changeme"}'   # -> 200 with a JWT
```

## Option B: Local-dev scripts (no Docker, this machine's shared Postgres)

Prerequisites: Ruby 3.4 + Bundler, Node.js (for the frontend dev server/tests), and access to
the shared local Postgres instance this machine's other apps also use (`../CLAUDE.md`).

```bash
cd app13_ruby_FastApi
./scripts/local-dev-up.sh          # creates the `rubyguard` role/DB on the shared Postgres instance
```

**Backend** (terminal 1):
```bash
cd backend
bundle install
cp .env.example .env               # then edit JWT_SECRET/ADMIN_PASSWORD to real values
bundle exec rake db:migrate
bundle exec rake db:seed
ADMIN_PASSWORD=changeme bundle exec rake db:seed_admin
bundle exec puma -C config/puma.rb # listens on :9292
```

**Frontend** (terminal 2):
```bash
cd frontend
npm install
npm run dev                        # esbuild --watch --servedir=., listens on :8000 by default
```

`index.html` runs `src/main.js` directly as native browser ES modules — `npm run dev` is a
convenience static file server + watch-rebuild for `dist/bundle.js`, not a required build step;
opening `frontend/index.html` in a browser via any static file server works too, as long as
`fetch()` calls to `/api/*` can reach the backend on `:9292` (set `CORS_ORIGIN` in the
backend's `.env` to match whatever origin you serve the frontend from).

Verify: `curl http://localhost:9292/health` should return `{"status":"UP"}`; then open the
frontend and log in with the admin username/password you set above.

## Tests (not part of "running the app", but useful to confirm things work)

```bash
cd backend && bundle exec rspec              # full RSpec suite (unit + request specs)
cd frontend && npx vitest run                # 23 unit tests — confirmed passing in this environment
cd frontend && npx playwright test           # E2E specs (needs `npx playwright install` first, and a running stack)
```
