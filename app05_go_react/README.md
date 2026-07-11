# GoSentry 2026

Interactive reference mapping security threats, vulnerabilities, and mitigations across OWASP, MITRE ATLAS, and CompTIA SecAI+. Sibling project to `app01_react`/`app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django), and `app04_scala_react` (Scala/ZIO) - same domain model, backend written **entirely in Go, standard library first**, contrasted directly against the JVM/Python siblings (see `PLAN.md` §0: no classes, no exceptions, no GC-tuning debates, a single static binary instead of a JAR/interpreter tree).

**Status:** Phase 1 — Foundation skeleton only. See `PLAN.md` for the full 7-phase roadmap (all six Cornucopia decks including Digital-by-Default Harms, i18n, full-text search, River-based export, code samples in 5 languages, etc.) — none of that is implemented yet.

## What's here (Phase 1 / milestone M1)

- **Backend** (`backend/`): Go 1.23, `chi` v5 router, **`sqlc`** for compile-time-checked SQL (D-02 — `internal/store/queries/*.sql` → `sqlc generate` → typed, schema-verified Go, committed per `PLAN.md` §9). `Framework`/`Threat` domain types, `goose` migrations for all 9 data-model entities (schema now, only Framework/Threat actually wired to queries - the rest wait for their own phase, same pattern as the other sibling apps). `GET /api/v1/frameworks`, `GET /api/v1/frameworks/:code`, paginated+filterable `GET /api/v1/threats` (`frameworkCode`, `severity`, `stride`, `category`, `tag`, `q` - all as ONE static query using `sqlc.narg()`, not a runtime query builder), `GET /api/v1/threats/:id`. `SecurityHeaders` middleware (CSP, HSTS, X-Frame-Options, X-Content-Type-Options), a `Recover` middleware that turns panics into a generic 500 with full detail `slog`-logged server-side only (D-01). RS256 JWT login (`golang-jwt/jwt` v5) matching the JWT-skeleton pattern the other sibling apps use — no admin CRUD endpoint exists yet for it to actually gate. `cmd/api`, `cmd/worker` (skeleton only, no River jobs registered yet), and `cmd/seed` are three separate compiled binaries sharing one Go module, matching D-05's stated process-boundary claim.
- **Frontend** (`frontend/`): React 18 / TypeScript / Vite / Tailwind — same Dashboard/Frameworks/FrameworkDetail pages as the other React-frontend sibling apps' Phase 1 scope.
- **Infra**: `docker-compose.yml` — `cmd/api`/`cmd/worker` ship as genuinely `FROM scratch` static-binary images (D-06); a separate one-shot `migrate`/`seed` pair (using the non-scratch build stage, which has the `goose` CLI) runs before `api`/`worker` start, via `depends_on: condition: service_completed_successfully`.

## What's deliberately NOT here yet

Everything in `PLAN.md` Phases 2–7: nested mitigations/code samples on threat detail, the cross-reference matrix, full-text search, River-based CSV/PDF export (the `cmd/worker` binary exists but registers no jobs), real i18n (`gs_locale` toggle not wired), the entire six-deck Cornucopia card catalogue including Digital-by-Default Harms, the opaque-type ref validators (D-07), `bluemonday` sanitization (D-04 - no admin CRUD to sanitize input for yet), Redis-based rate limiting (D-08), `golangci-lint`/`govulncheck` CI gates, and the test suite. `swaggo/swag` (tech-stack table) also didn't make it into Phase 1 - plain chi routes only, no `/api/v1/docs/swagger-ui/` yet.

## What was already sitting here before this build

Like two of its siblings, this directory had a `frontend/`, `nginx/`, `.env`, and `scripts/` before any of the above was written - a mechanical copy-paste of `app01_react`'s output (package.json said `"securevision-frontend"`, `docker-compose.yml`'s content had been pasted into `.env` instead of its own file, `nginx.conf` proxied `/swagger-ui/`+`/v3/api-docs/` paths that don't exist here). All rebranded/rewritten; `backend/` didn't exist at all.

## Real things worth knowing if you touch the build

- **Go module toolchain auto-upgrade fought the `PLAN.md`-pinned Go 1.23 repeatedly.** `go get <pkg>@latest` for `pgx/v5`, then again for `goose/v3`, each pulled a version whose own `go.mod` required Go 1.24/1.25+, which cascades: Go's `go` directive is derived from the *maximum* requirement across the whole resolved graph, so one greedy transitive bump silently drags the whole module's minimum Go version up. Fixed by explicitly pinning to the newest version of each *direct* dependency that still declares a Go 1.23-or-earlier requirement (checked directly against `proxy.golang.org`'s per-version `.mod` files, not guessed): `pgx/v5@v5.7.6`, `golang.org/x/crypto@v0.37.0`. Ended up **not** adding `goose` as a library dependency at all (see next point) specifically because chasing this kept re-triggering the same cascade for comparatively little benefit.
- **Embedding migrations into the binary via `goose`-as-a-library was attempted and reverted.** The idea - use Go's `embed.FS` to bake `migrations/*.sql` directly into the `cmd/api` binary, matching D-06's "single static binary" story even more literally - kept re-triggering the toolchain cascade above (goose's own transitive deps wanted newer everything). Backed out in favor of the already-proven-working approach: `goose` as a separate CLI, invoked as a one-shot `migrate` step in `docker-compose.yml` (using the non-scratch build stage, which has the toolchain) before the genuinely-`FROM scratch` `api`/`worker` images start. Phase 1's own checklist only requires migrations to exist and run, not to be embedded - this was a nice-to-have that wasn't worth the fight.
- **`go run`'s child-process model breaks naive port-based `taskkill` on Windows.** `go run ./cmd/api` compiles to a temp binary (named `api.exe` here) and execs it as a *child* of the `go` process. `netstat`'s LISTENING-socket-to-PID mapping was observed pointing at the parent `go.exe` PID; killing just that PID left `api.exe` running and still serving on :8080 - confirmed by actually re-checking the port after "stopping" it, not just trusting the script's own success message. Fixed `scripts/local-dev-down.sh` to use `taskkill //F //T` (tree-kill) plus a fallback `taskkill //IM api.exe` in case the parent had already exited and the child had been reparented past the tree-kill's reach.
- Everything else - the `sqlc` compile-time query generation, the chi router, RS256 JWT signing/verification, the pagination shape, the security headers - worked on the **first real run**, no bugs found. Notably cleaner than the other four sibling apps' first attempts; consistent with `PLAN.md` §0's own thesis about Go's simpler type system and lack of macro/reflection-based footguns.

## Quick start

```bash
docker compose up --build
```

- Frontend: http://localhost:8081
- Backend API: http://localhost:8080/api/v1/frameworks
- Health: http://localhost:8080/api/v1/health

**M1 acceptance check (per `PLAN.md` §16):** `docker compose up` → `cmd/api` health check 200; React SPA loads. (The Docker build itself is untested on this machine - no Docker installed here - but the `migrate`/`seed`/`api` steps it orchestrates were each run directly and verified working, including a real `goose up` against Postgres and a real `sqlc generate` run.)

### Local dev (without Docker)

```bash
# backend - needs Go 1.23+, a local Postgres on 5432, and goose/sqlc on PATH
# (go install github.com/pressly/goose/v3/cmd/goose@v3.24.0 and
#  go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest)
cd backend
goose -dir migrations postgres "postgres://gosentry:gosentry@localhost:5432/gosentry?sslmode=disable" up
go run ./cmd/seed
go run ./cmd/api

# frontend - proxies /api/v1 to localhost:8080 via vite.config.ts
cd frontend && npm install && npm run dev
# → http://localhost:5173 (Vite's default dev-server port)
```

**This machine specifically** has no Docker installed. `scripts/local-dev-up.sh` /
`scripts/local-dev-down.sh` start/stop the same pieces (Postgres, backend, frontend)
as standalone portable installs under `C:\Users\krish\tools\` instead of containers
(including a portable Go toolchain under `tools/go/` and `goose`/`sqlc` under
`tools/gopath/bin/`). Machine-specific (hardcoded tool paths) — not portable to
other setups; use `docker compose` there instead.

### Regenerating sqlc code after changing a query

```bash
cd backend && sqlc generate   # writes internal/store/sqlcgen/ - commit the output
```
