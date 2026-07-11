# RustBastion 2026 — Rust/axum implementation (app07_rust_react)

The Rust implementation of SecureVision: `axum` + `sqlx` + PostgreSQL backend,
React/TS frontend. See `../CLAUDE.md` for the sibling list, canonical Phase-1
API contract, and shared local-dev-tooling notes.

## Current state: backend is built (Phase-1 parity), frontend is built

Both `backend/` and `frontend/` exist and are implemented, not just scaffolded.
The root `../CLAUDE.md` status table calling this "frontend only, backend not
started" is **stale** — verify against this file, not that table.

- `backend/` — Cargo workspace (`securevision-backend`, edition 2024) with a
  binary (`src/main.rs`) plus lib (`src/lib.rs`). Implements all five
  canonical endpoints: `POST /api/v1/auth/login`, `GET /api/v1/frameworks`,
  `GET /api/v1/frameworks/{code}`, `GET /api/v1/threats` (filter/sort/page),
  `GET /api/v1/threats/{id}`, `GET /health`. See `src/routes.rs`.
- `backend/migrations/` — two `sqlx` migrations (`0001_init_schema.sql`,
  `0002_seed_data.sql`) creating `framework`/`threat` tables and seed data.
  Migrations run automatically at startup (`run_migrations` in `main.rs`).
- `backend/tests/api.rs` — integration tests via `axum-test` + `#[sqlx::test]`
  (spins up a real Postgres per test via `sqlx`'s test harness).
- `frontend/` — built React 18 + TypeScript + Vite app (`node_modules/`,
  `dist/` present). Pages: `Dashboard`, `Frameworks`, `FrameworkDetail`.
  `frontend/src/types/index.ts` and `frontend/src/api/client.ts` already
  target the canonical contract shape.
- `docker-compose.yml` wires all three services (`postgres`, `backend`,
  `frontend` via `nginx/nginx.conf`) — this is real, not aspirational.

**Not built:** anything beyond Phase-1 — no i18n, no card decks, no admin
CRUD, no `apalis` background jobs, no `utoipa`/Swagger, no roles beyond
ADMIN. `PLAN.md`/`requirements.md`/`SDLC_analysis.md`/`user_stories+tests.md`
describe that larger aspirational end state; treat them as background, not a
build checklist for what's "left."

## Design decisions already made and implemented — don't re-litigate

The old version of this file described these as open decisions to make
"before writing the first route." They are already decided and coded:

- **Auth is HS256, matching app01 — not RS256.** `backend/src/auth.rs` calls
  `jsonwebtoken::encode` with the default `Header` (HS256) and
  `EncodingKey::from_secret(config.jwt_secret...)`, a shared secret from
  `JWT_SECRET` — same scheme as app01, despite `PLAN.md` committing to RS256.
  Password hashing is Argon2id (not app01's BCrypt) — that's a deliberate,
  intentional divergence since the hash format is a storage-only detail, not
  part of the wire contract; the plaintext admin password/credentials still
  match app01's.
- **DB columns are comma-joined `TEXT`, matching app01 — not native
  `TEXT[]`.** `stride`, `tags`, `cve_references` are `TEXT` columns split at
  the application layer (`models.rs::split_csv`), same as app01's schema.
  Unlike app01's own DTOs, this backend always normalizes `NULL`/empty to
  `[]` rather than emitting JSON `null`, to match what the already-built
  frontend types expect.
- Error body shape (`{timestamp, status, error, message}`) matches the
  canonical contract — see `backend/src/error.rs`.
- SQL is built with `sqlx::QueryBuilder` + `.push_bind(...)` (parameterized)
  even for dynamic filter/sort clauses; the `sort` column name is checked
  against a fixed whitelist (`SORTABLE_COLUMNS`) before being concatenated as
  a raw identifier — see `backend/src/handlers/threats.rs`.

If you're extending this backend, cross-check `frontend/src/types/index.ts`
and `frontend/src/api/client.ts` before changing any response shape — the
frontend is already built against the current shape.

## Gotcha: `scripts/local-dev-up.sh` / `local-dev-down.sh` are stale, copied from app01

They currently drive **`mvn spring-boot:run`** and reference a Spring Boot
backend, `Swagger UI at /swagger-ui.html`, etc. — leftover from copying
app01's script. **They do not start this Rust backend.** To run this app
locally without Docker, adapt them (or just run directly):

```
cd backend && cargo run          # backend on BIND_ADDR (see .env / .env.example)
cd frontend && npm run dev       # frontend dev server (Vite)
```

or use `docker compose up --build` with `docker-compose.yml`, which is
correct and Rust-aware. Required env vars are listed in `.env.example`
(`POSTGRES_DB/USER/PASSWORD`, `JWT_SECRET`, `JWT_EXPIRATION_MINUTES`,
`ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH`) — `backend/src/bin/hash_password.rs`
generates the Argon2id hash for `ADMIN_PASSWORD_HASH`.

## Versions in use (from `backend/Cargo.toml`)

`axum` 0.8.x, `sqlx` 0.9.x (postgres, macros, migrate features),
`jsonwebtoken` 10.x, `argon2` 0.5.x, PostgreSQL 16 (per `docker-compose.yml`),
Rust 2024 edition. Lint/SCA tooling from `PLAN.md` (`clippy -D warnings`,
`cargo audit`, `cargo-deny`, `cargo-geiger`) is aspirational — check CI config
or run manually before assuming it's enforced anywhere.

## Where to look for more

`PLAN.md`, `requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md`
describe the full 19-user-story aspirational end state — useful for context
on where this could go, not for what currently exists. For the actual
Phase-1 contract this app implements, `app01_react/backend/src/main/java/com/securevision/`
remains the source of truth per `../CLAUDE.md`; this app's implementation
already matches it (HS256, comma-joined TEXT) rather than PLAN.md's original
RS256/`TEXT[]` assumptions.
