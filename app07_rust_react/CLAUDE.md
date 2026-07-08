# RustBastion 2026 — Rust/axum implementation (app07_rust_react)

The Rust implementation: intended `axum` + `sqlx` + PostgreSQL backend,
React/TS frontend. See `../CLAUDE.md` for the sibling list, canonical API
contract, and shared local-dev setup; see `app06_HASKELL_react/CLAUDE.md` for
a worked example of this same file once a backend exists here.

## Current state: backend not started

**Only `frontend/` exists.** It is a built React 18 + TypeScript + Vite app
(`node_modules/`, `dist/`, `tsconfig*.tsbuildinfo` are all present — it has been run).
There is **no `backend/` directory, no `Cargo.toml`, no Rust code, no database, no
`docker-compose.yml` wiring a backend service.** `nginx/nginx.conf` and
`scripts/local-dev-up.sh`/`local-dev-down.sh` exist but — check before trusting them —
likely only stand up the frontend/proxy, not an API, since none has been written yet.

`PLAN.md` describes a large 19-user-story end state (6 card decks, i18n, RS256 JWT
roles, `apalis` background jobs, admin CRUD, `utoipa`/Swagger). **None of it is built.**
Treat this whole app as "frontend-only, backend at zero," not as a partially-built
backend — there is nothing to extend yet, only a plan to start from.

## Frontend already expects the canonical contract

`frontend/src/types/index.ts` is already written against the canonical
contract's shape (see `../CLAUDE.md`) — read it before designing Rust response
DTOs so the two don't drift.

## What PLAN.md commits to, once backend work starts

| Layer | Choice | Version |
|---|---|---|
| Web framework | `axum` (Tokio + Tower) | 0.8.x |
| DB access | `sqlx` (`query!`/`query_as!`, compile-time-checked against a live schema) | 0.8.x |
| Database | PostgreSQL | 16 |
| Auth | `jsonwebtoken`, **RS256** per PLAN.md | — |
| Password hashing | `argon2` (Argon2id) | — |
| Testing | `#[tokio::test]` + `proptest` + `axum-test`/`reqwest` | — |
| Lint/SCA | `clippy -D warnings`, `cargo-geiger`, `cargo audit`, `cargo-deny` | — |

**Deviation already known, per `../CLAUDE.md`:** PLAN.md assumes RS256 JWT;
app01's actual auth is HS256 with a shared secret. Don't implement RS256
without deciding, and recording here, that this app deliberately diverges from
app01 — the same caution applies to `sqlx migrate` vs. app01's Flyway
migrations, and to `TEXT[]` vs. app01's comma-joined `TEXT` columns
(`stride`/`tags`/`cve_references`).

## Before writing the first route

1. Read `app01_react/backend/src/main/java/com/securevision/` end to end for the real
   contract (entities, DTOs, `JwtService`, error-handling advice) — not PLAN.md's vision.
2. Read `frontend/src/types/index.ts` and `frontend/src/api/*` in this app to see what
   shape the already-built frontend expects on the wire.
3. Decide, and record here, whether Phase-1 follows app01 exactly (HS256, comma-joined
   text columns) or deliberately diverges (RS256, native `TEXT[]`) — don't let PLAN.md's
   aspirational D-04 silently become the implementation without that decision being made
   explicitly.
