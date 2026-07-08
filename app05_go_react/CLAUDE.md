# GoSentry 2026 — Go/chi implementation (app05_go_react)

The Go implementation: standard-library-first backend with `chi` v5 routing,
`pgx` v5 driver, and `sqlc` for compile-time-checked SQL. React/TS frontend,
same shape as app01/app06. See `../CLAUDE.md` for the sibling list, canonical
API contract, and shared local-dev setup — app01 remains the contract of
record.

## Scope: this is Phase-1 parity, not the full vision

`PLAN.md` describes a much larger 19-user-story end state (six OWASP Cornucopia
card decks, i18n, Redis-backed rate limiting, a `river` job queue for CSV/PDF
export, `bluemonday` sanitization for admin CRUD, `swaggo/swag` API docs).
**None of that is built yet.** What exists today is frameworks + threats
(read-only) and one hardcoded admin login — mirroring app01's own Phase-1
skeleton.

## Package layout

Three binaries share one module (`gosentry`): `cmd/api` (HTTP server), `cmd/seed`
(loads `backend/data/*.json` into Postgres), `cmd/worker` (skeleton only — no jobs
registered). Shared code: `internal/domain` (plain structs, no ORM annotations),
`internal/service` (business logic + DB-row-to-DTO conversion, e.g.
`convert.go`'s `splitCSV`/`splitStride`), `internal/store` (sqlc-generated queries +
`pgx` pool), `internal/http/{handler,middleware}` (chi routes, JWT auth, security
headers, panic recovery).

## The sqlc pattern — read this before touching a query

Hand-written SQL lives in `backend/internal/store/queries/*.sql` (currently
`frameworks.sql`, `threats.sql`). `sqlc generate` (config: `backend/sqlc.yaml`) reads
those files plus `backend/migrations/*.sql` as the schema, and emits fully-typed Go into
`internal/store/sqlcgen/` — **commit that generated output**, don't gitignore it. There
is no runtime query builder and no ORM: the `threats` filter endpoint
(`frameworkCode`/`severity`/`stride`/`category`/`tag`/`q`) is **one static SQL query**
using `sqlc.narg()` for optional params, not a dynamically-built string. After editing
any `.sql` file, run `cd backend && sqlc generate` and re-check in the diff.

## Known deviations from the app01 contract (don't "fix" these back)

- **`/health` only exists as `/api/v1/health`** (`internal/http/router.go` nests it
  inside the `/api/v1` chi route group) — there is no bare `/health` route, unlike the
  contract above. Check with callers/frontend before adding one at root; it may be
  intentional given how this app's Nginx/Docker health checks are wired.
- **`stride`/`cve_references`/`tags` are comma-separated `TEXT` columns**, same as
  app01's actual approach — not native Postgres arrays. `internal/service/convert.go`
  splits them into `[]string` in the service layer before JSON serialization, and always
  emits `[]` (never `null`) for empty values.
- **Auth is RS256, not app01's actual HS256.** `internal/http/middleware/auth.go`
  generates a fresh in-memory RSA keypair on every `cmd/api` process start — it is
  **not persisted or shared** with `cmd/worker`. Restarting the API invalidates every
  outstanding token. There's no `JWT_SECRET` env var here; don't add one expecting it to
  do anything without also wiring key persistence.
- **`RequireRole` middleware exists but is wired to nothing** — no admin CRUD endpoints
  exist yet for it to protect. Present for Phase 2, not dead code to delete.
- **Migrations run via the `goose` CLI as a one-shot Docker step**, not embedded in the
  binary. Embedding via `goose`-as-a-library was tried and reverted — its transitive
  deps kept forcing a Go toolchain version bump past the `go.mod`-pinned 1.23. If you add
  a dependency and CI/local builds suddenly demand a newer Go, suspect the same cascade
  (check the new package's own `go.mod` `go` directive before blaming your code).

## Running locally

No Docker on this machine (see `../CLAUDE.md`) — use `scripts/local-dev-up.sh` /
`scripts/local-dev-down.sh` (portable Go/goose/sqlc installs under
`C:\Users\krish\tools\`). Where Docker *is* available: `docker compose up --build`
runs `migrate` → `seed` → `api`/`worker` via `depends_on: condition:
service_completed_successfully`; `cmd/api`/`cmd/worker` ship as `FROM scratch`
static binaries with `CGO_ENABLED=0`.

**Windows gotcha:** `go run ./cmd/api` execs a temp binary as a *child* process; killing
the parent `go.exe` PID (e.g. via `netstat`-found PID) leaves the child still listening.
`local-dev-down.sh` uses `taskkill //F //T` (tree-kill) plus an `//IM api.exe` fallback —
verify the port is actually free after "stopping", don't trust the script's exit code alone.
