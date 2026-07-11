# CppCitadel 2026 — C++/Drogon implementation (app08_cpp_react)

The C++ implementation — included deliberately as the **counter-example**: no
borrow checker, no macro-checked SQL, no derive-based schema validation. See
`PLAN.md` §0 for the full "what C++ doesn't give you for free" framing, and
`../CLAUDE.md` for the sibling list, canonical API contract, and shared
local-dev setup.

## Current state: backend exists and implements Phase-1 endpoints

`backend/` is a real Drogon C++ app (not a stub): `main.cpp`, three controllers
(`AuthController`, `FrameworkController`, `ThreatController`), `config/Config.h`,
`models/Models.h`, `utils/Headers.h`. It implements the canonical contract's
`POST /api/v1/auth/login`, `GET /api/v1/frameworks[/:code]`, `GET
/api/v1/threats[/:id]`, and `GET /health`, all wired against a real Postgres
connection via Drogon's own async ORM (`drogon::orm::DbClient`). The root
repo's sibling status table may still say "frontend only, backend not
started" for app08 — that line is stale; verify against this file and the
filesystem, not the root table.

Not present: no test suite (GoogleTest/GoogleMock/RapidCheck from PLAN.md
§5.7 isn't scaffolded — `find . -iname '*test*'` turns up nothing but
`user_stories+tests.md`), no sanitizer flags in `CMakeLists.txt`, no
`docker-compose.yml` anywhere in this app, no OpenAPI YAML, no `worker`
subdirectory or background jobs. Treat PLAN.md's fuller vision (card decks,
i18n, fuzzing pipeline, async export) as unbuilt aspiration — only Phase-1
CRUD-read + login exists.

## Actual stack (superseding PLAN.md §2 where they disagree)

- **Language/build**: C++23, CMake (`backend/CMakeLists.txt`), single flat
  target `cppcitadel` (no `core`/`api`/`worker` split PLAN.md described).
- **Dependency manager**: **Conan** (`backend/conanfile.txt`), not vcpkg —
  already decided, don't re-litigate. Pins `drogon/1.9.6`, `jwt-cpp/0.7.0`,
  `spdlog/1.13.0`; Drogon built with Postgres support on, MySQL/SQLite/Redis/
  Brotli off.
- **DB access**: Drogon's own built-in async ORM (`drogon::orm::DbClient`,
  `execSqlAsync`, `$1`/`$2`-style bound placeholders) talking to Postgres —
  **not** `libpqxx` + `sqlpp11` as PLAN.md's appendix proposed. There is no
  compile-time query-shape checking layer; parameterization is the only SQL
  safety net (mirrors WordPress/app09's "runtime-only" situation more than
  the sqlc/hasql-th siblings).
- **Auth**: `jwt-cpp` signing **HS256** (`jwt::algorithm::hs256{cfg.jwtSecret}`,
  see `AuthController.cpp`) — this **matches** app01's actual auth. PLAN.md
  D-04's RS256 assumption was never implemented and can be treated as
  superseded; don't "fix" this back to RS256.
- **Password check**: glibc `crypt_r` (bcrypt hash format `$2a$...` /
  `$2b$...`) via `<crypt.h>`, not `libsodium` Argon2id as PLAN.md said. The
  admin password hash comes from `ADMIN_PASSWORD_HASH` (env var / `.env`),
  default only for local dev — real deployments must override it.
- **JSON/logging**: `jsoncpp` (`Json::Value`, Drogon's native JSON type) and
  `spdlog`. `jwt-cpp` needs an explicit JSON-traits type since 0.6+; this app
  uses `jwt::traits::boost_json` (Boost is already pulled in transitively by
  Drogon, so no new dependency).
- **CORS/OPTIONS**: handled via `registerPreRoutingAdvice` in `main.cpp`, not
  per-route `METHOD_ADD` registration — a per-path `registerHandler(...,
  {Options})` was tried first and silently broke GET/POST with 405 on every
  real endpoint (Drogon doesn't merge method sets for an identical path
  registered twice); see the comment block in `main.cpp` before changing this.

## Frontend

`frontend/` is React 18 + TS + Vite, already built (`node_modules`/`dist`
present). `frontend/src/types/index.ts` is written against the canonical
contract's shape — don't change it without checking the backend DTOs still
match. Structure: `src/{api,components,pages,types}`.

## Local dev tooling — scripts/local-dev-up.sh is still stale

`scripts/local-dev-up.sh` still `cd`s into `backend/` and runs `mvn
spring-boot:run` — it was copied from `app01_react` and never adapted to the
Drogon binary that now exists. `.local-dev/backend.log` is a leftover Spring
Boot log from that copy, not evidence of the C++ backend having run. Fix the
script (point it at the real Conan/CMake build + the `cppcitadel` binary,
port from `HTTP_PORT`/`Config.h` — default 8080) before relying on it; don't
trust its current output. `.env` / `.env.example` already define the real env
vars the C++ app reads (`DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`,
`DB_PASSWORD`, `HTTP_PORT`, `JWT_SECRET`, `JWT_EXPIRATION_HOURS`,
`ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH`) — use those names, not the Spring
ones the stale script assumes.

No Docker on this machine (see `../CLAUDE.md`); no `docker-compose.yml`
exists in this app yet either, so there's nothing to fall back to besides the
script above.

## Before extending the backend further

1. Cross-check any new endpoint against `../app01_react/backend/src/main/java/com/securevision/`
   for actual Phase-1 field/behavior — not PLAN.md's aspirational sections.
2. `resolveOrderBy()` in `ThreatController.cpp` is the pattern for any
   user-supplied sort/column input: allowlist to a fixed map, never interpolate
   a column name into SQL text (bound placeholders only work for values).
3. If adding compile-time-checked queries, PLAN.md's `sqlpp11` idea is still
   open — nothing currently blocks it, but nothing requires it either; decide
   and document here if you add it, don't leave it implicit.
4. If adding tests, GoogleTest/GoogleMock/RapidCheck per PLAN.md §5.7 is the
   intended stack; none exists yet, so this would be new infrastructure, not
   an extension of an existing suite.
