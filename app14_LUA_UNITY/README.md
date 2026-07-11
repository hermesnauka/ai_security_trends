# LuaGuard 2026 — Running Backend + Frontend Together

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

This app splits unusually compared to most siblings in this repo: the **backend** (Lua/
OpenResty/Lapis + PostgreSQL) is a normal server you can run headlessly, but the **frontend**
is a Unity project with no CLI-only run path — there is no single command that starts both.
See `CLAUDE.md`/`PLAN.md` for the full architecture; this file is only about running what
exists today.

## What actually exists right now

- `backend/`: a complete Lapis app (routes, models, services, migrations, seed data, `busted`
  specs) — runnable and testable without Unity.
- `frontend/`: a C# host layer (`Bootstrap.cs`, `LuaSandbox.cs`, `ApiBridge.cs`, `MiniJson.cs`)
  and real Lua gameplay logic (`Assets/StreamingAssets/lua/*.lua`), plus tests — but **no
  Unity scenes or UI exist yet**. There is nothing to visually run/click through yet; the
  frontend today is source you'd open in the Unity Editor to continue building the six scenes
  `PLAN.md` §8 describes.
- Nothing here has been executed in this repo's own dev environment — no Lua/OpenResty/
  LuaRocks/Postgres/Unity runtime is installed where this was written. Everything below is
  unverified but structurally correct, same as every other sibling's freshly-scaffolded code.

## Option A — Backend only, via Docker Compose (recommended first step)

```bash
cd app14_LUA_UNITY
JWT_SECRET=some-long-random-secret ADMIN_PASSWORD=changeme docker compose up --build postgres backend
```

This starts:
- `postgres` on host port **5434** (avoids colliding with the shared local Postgres on `:5432`
  and `app13_ruby_FastApi`'s own `:5433`).
- `backend` on host port **9292** — runs migrations, seeds content, seeds the admin user, then
  starts OpenResty, per `backend/Dockerfile`'s `CMD`.

Don't start the `nginx` service yet — it mounts `./frontend/WebGLBuild`, which doesn't exist
(no Unity WebGL build has been produced in this environment). `docker compose up` with no
service names starts all three and will fail/serve an empty directory for `nginx`; start only
`postgres backend` as shown above until a real WebGL build exists.

**Verify it's working:**
```bash
curl http://localhost:9292/health
# {"status":"UP"}

curl -X POST http://localhost:9292/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"changeme"}'
# {"token":"...","tokenType":"Bearer","role":"ADMIN"}

curl http://localhost:9292/api/v1/frameworks
```

## Option B — Backend only, local dev (no Docker)

Follows the shared Docker-less local-Postgres convention (`../CLAUDE.md`):

```bash
cd app14_LUA_UNITY
./scripts/local-dev-up.sh   # creates the `luaguard` role/DB on the shared local Postgres instance

cd backend
luarocks install --tree lua_modules lapis pgmoon lua-resty-jwt lyaml bcrypt lua-resty-limit-traffic
export JWT_SECRET=some-long-random-secret
export DB_HOST=127.0.0.1 DB_USER=luaguard DB_PASSWORD=luaguard DB_NAME=luaguard_development
lua scripts/db_migrate.lua
lua scripts/db_seed.lua
ADMIN_PASSWORD=changeme lua scripts/db_seed_admin.lua
openresty -p "$(pwd)" -c nginx.conf -g 'daemon off;'
```

Backend listens on **9292**, same as the Docker path.

## Running the backend test suite (no live Postgres needed for some specs)

```bash
cd backend
luarocks install busted
busted
```

`spec/services/reference_validator_spec.lua` and `spec/services/card_deck_loader_spec.lua`
only touch `db/seeds/` files on disk — no database connection required. `spec/models/
card_spec.lua` and everything under `spec/routes/` (via `spec/support/http_client.lua` →
`lapis.spec.request`) need a real, migrated, seeded Postgres test database (`config.lua`'s
`test` environment) to pass.

## Frontend: requires the Unity Editor — no CLI path

There is no `unity -batchmode` build target set up in this repo, and no `.unity` scene files
exist yet to run. To continue on the frontend:

1. Install **Unity 2022.3 LTS** (pinned in `frontend/ProjectSettings/ProjectVersion.txt`,
   currently `2022.3.50f1`).
2. Add the **MoonSharp** interpreter to the project (not a Unity Package Manager package —
   vendor its DLL/source under `Assets/Plugins/MoonSharp/`, since `frontend/Packages/
   manifest.json` only lists first-party Unity packages).
3. Open `frontend/` as a project in Unity Hub/the Editor.
4. Build the six scenes described in `PLAN.md` §8 (none exist yet), wiring each to
   `Bootstrap.cs`/`ApiBridge.cs` and the `Assets/StreamingAssets/lua/*.lua` gameplay modules
   that already exist.
5. Point `ApiBridge`'s `baseUrl` field at the backend from Option A or B above (default in
   code is `https://localhost:9292` — change the scheme to `http://` for a local dev backend
   unless you've also set up TLS termination in front of it).

### Frontend Lua logic can be tested without Unity

```bash
cd frontend/Tests/Lua
luarocks install busted
busted
```

This runs `card_engine_spec.lua`, `game_modes_spec.lua`, and `i18n_spec.lua` directly against
the real `.lua` files under `Assets/StreamingAssets/lua/` using standalone Lua — no Unity
Editor, no MoonSharp, no backend connection needed.

### Frontend sandbox tests (require Unity)

`Tests/EditMode/LuaSandboxTests.cs` runs via Unity's Test Runner (`Window > General > Test
Runner > EditMode` in the Editor, or `game-ci/unity-test-runner` in CI) — these need MoonSharp
and the Unity Editor, unlike the standalone Lua specs above.

## Summary

| Component | Command | Needs |
|---|---|---|
| Backend (Docker) | `docker compose up --build postgres backend` | Docker |
| Backend (local) | `scripts/local-dev-up.sh` + `lua scripts/db_migrate.lua` + `lua scripts/db_seed.lua` + `lua scripts/db_seed_admin.lua` + `openresty -c nginx.conf` | Lua/LuaRocks/OpenResty, local Postgres |
| Backend tests | `busted` in `backend/` | `busted`; some specs need Postgres, some don't |
| Frontend logic tests | `busted` in `frontend/Tests/Lua/` | `busted` only, no Unity |
| Frontend (full) | Open `frontend/` in Unity Editor | Unity 2022.3 LTS + MoonSharp (manual add) — no CLI path exists |
