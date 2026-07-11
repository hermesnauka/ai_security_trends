# GoSentry 2026 — Go/chi implementation (app05_go_react)

Standard-library-first backend (`chi` v5 routing, `pgx` v5 driver, `sqlc` for
compile-time-checked SQL) + React/TS frontend. See `../CLAUDE.md` for the
sibling list, canonical API contract, and shared local-dev notes — app01
remains the contract of record.

## Current state: Phase 1 only (frameworks + threats, read-only, one admin login)

`PLAN.md` describes a 19-user-story end state (six Cornucopia decks, i18n,
Redis rate limiting, `river` job queue, `bluemonday` sanitization, `swaggo`
docs). None of that is built. What exists: `GET /frameworks`,
`GET /frameworks/:code`, `GET /threats` (filterable), `GET /threats/:id`,
`POST /auth/login` (single hardcoded admin, no user table). **No automated
tests exist anywhere** (no `*_test.go`, no frontend test files) — this is a
real gap, not just an omission from this doc.

## Package layout

One Go module (`gosentry`), three binaries: `cmd/api` (HTTP server),
`cmd/seed` (loads `backend/data/*.json` into Postgres), `cmd/worker`
(literally `select{}` — process boundary exists, no jobs registered, no
`river` dependency in `go.mod` yet). Shared code: `internal/domain` (plain
structs), `internal/service` (business logic + row-to-DTO conversion —
`convert.go`'s `splitCSV`/`splitStride` turn comma-separated TEXT columns
into `[]string`), `internal/store` (sqlc-generated queries + pgx pool),
`internal/http/{handler,middleware}` (chi routes, JWT auth, security headers,
panic recovery).

## The sqlc pattern — read this before touching a query

Hand-written SQL lives in `backend/internal/store/queries/*.sql` (currently
`frameworks.sql`, `threats.sql`). `sqlc generate` (config: `backend/sqlc.yaml`)
reads those plus `backend/migrations/*.sql` and emits typed Go into
`internal/store/sqlcgen/` — **that generated output is committed**, don't
gitignore it. The threats filter (`frameworkCode`/`severity`/`stride`/
`category`/`tag`/`q`) is one static query using `sqlc.narg()` for optional
params — no runtime query builder, no string concatenation. After editing any
`.sql` file: `cd backend && sqlc generate`, then check the diff in
`sqlcgen/`.

**Pagination is application-level, not SQL-level:** `SearchThreats` has no
`LIMIT`/`OFFSET` — it fetches every matching row, and
`internal/service/threat_service.go` calls `domain.NewPage(summaries, page,
size)` to slice the page in Go. Fine at current seed-data volume; would need
a real `LIMIT`/`OFFSET` (or keyset pagination) before this scales. The
resulting `Page<T>` shape (`content`/`totalElements`/`totalPages`/`number`/
`size`) does match app01's Spring Data envelope.

## Where this deviates from the app01 contract (intentional, don't "fix" back)

- **`/health` only exists as `/api/v1/health`**, nested inside the `/api/v1`
  chi route group in `internal/http/router.go` — there is no bare `/health`.
- **Auth is RS256, not app01's HS256**, despite the root `../CLAUDE.md`
  flagging RS256 as a wrong assumption in sibling `PLAN.md`s — this app's own
  `PLAN.md` §D-03 still documents RS256 and the code matches it exactly.
  `internal/http/middleware/auth.go` generates a fresh in-memory RSA keypair
  on every `cmd/api` start — **not persisted or shared** with `cmd/worker`;
  restarting the API invalidates every outstanding token. There is no
  `JWT_SECRET` env var; don't add one expecting it to do anything without
  also wiring key persistence.
- `stride`/`cve_references`/`tags` are comma-separated `TEXT` columns (same
  as app01's real approach, not native Postgres arrays); always serialized
  as `[]` not `null` when empty.
- `RequireRole` middleware (`internal/http/middleware/auth.go`) exists but is
  wired to no route — no admin CRUD endpoints exist yet to protect. It's a
  Phase 2+ primitive, not dead code.
- Migrations run via the `goose` CLI as a one-shot Docker step, not embedded
  in the binary — embedding via `goose`-as-a-library was tried and reverted
  because its transitive deps forced a Go toolchain bump past the
  `go.mod`-pinned `go 1.23.0`. If adding a dependency suddenly demands a newer
  Go, suspect the same cascade before blaming your own code.

## Frontend

React 18 + TypeScript + Vite + Tailwind, `frontend/src/`: `pages/Dashboard`,
`pages/Frameworks`, `pages/FrameworkDetail` (lists that framework's threats
inline), `api/client.ts` (typed `fetch` wrapper), `types/index.ts` (hand-kept
in sync with backend DTOs — no shared schema/codegen yet). **There is no
`/threats` search page and no login UI** — `POST /auth/login` and standalone
threat browsing exist on the backend with no frontend route consuming them
yet. UI copy is in Polish (`Wczytywanie…`, `Zagrożenia`, error strings) —
no i18n toggle wired despite `PLAN.md` describing one.

## Running locally

No Docker on this machine (see `../CLAUDE.md`) — `scripts/local-dev-up.sh` /
`scripts/local-dev-down.sh` drive a portable Postgres/Go/goose install and
the Vite dev server directly. The scripts assume a Windows host under
`C:\Users\krish\tools\` (`.exe` binaries, `pg_ctl.exe`, `taskkill //F //T`
tree-kill in `local-dev-down.sh` to catch `go run`'s child-process binary,
which a plain PID kill misses) — check `../CLAUDE.md` before assuming that's
still this machine's setup. DB role/database created by the script:
`gosentry`/`gosentry` (connects to the shared cross-app Postgres instance on
`:5432`, distinct from app01's `securevision` role).

Where Docker *is* available: `docker compose up --build` runs
`migrate` → `seed` → `api`/`worker` via
`depends_on: condition: service_completed_successfully`; `cmd/api`/
`cmd/worker` ship as `FROM scratch` static binaries (`CGO_ENABLED=0`); the
one-shot `migrate`/`seed` services use a non-scratch build stage that still
has the Go toolchain + `goose` CLI.

## Where to look for more

`PLAN.md` (design decisions D-01..D-09, full schema, phased roadmap),
`README.md` (narrative build log — useful for *why* things went the way they
did, e.g. the Go-toolchain-cascade story and the Windows `taskkill` fix;
this file is the current-state reference, README is the history).
`requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md` hold the
larger aspirational scope, same caveat as every sibling: verify against the
filesystem before assuming a feature exists.
