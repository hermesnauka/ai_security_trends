# HaskShield 2026 — Haskell/servant implementation (app06_HASKELL_react)

The Haskell implementation: `servant` + `hasql` backend, React/TS frontend. See
`backend/CLAUDE.md` and `frontend/CLAUDE.md` for stack-specific detail, and
`../CLAUDE.md` for the sibling list, canonical API contract, and shared
local-dev setup.

## Scope: this is Phase-1 parity, not the full vision

What exists today deliberately mirrors `../app01_react`'s backend, which is
itself only a Phase-1 skeleton: frameworks + threats (read-only), one
hardcoded admin login, 4 seeded frameworks, ~33 threats. `frontend/types/index.ts`
is written against the canonical contract's shape — don't change either side
without checking the other.

## Known deliberate deviations from app01 (don't "fix" these back)

- **`stride`/`tags`/`cve_references` are native Postgres `TEXT[]`**, not app01's
  comma-joined `TEXT` column — same JSON shape (`["S","T"]`), just a better-typed
  column on this side. app01's own code comments flag the comma-join as a shortcut.
  `cve_references`/`tags` serialize as `[]` when empty, never `null` (app01 sometimes
  emits `null` here since its DTO has no null-guard for that field).
- **Auth is JWT HS256 with a shared `JWT_SECRET`**, matching what app01's `JwtService`
  *actually* does (`Keys.hmacShaKeyFor`) — not the RS256 described in `PLAN.md`'s
  aspirational D-04, which assumes a key pair app01 never had.
- **Migrations run via a small custom runner**, not `hasql-th`/Flyway. `hasql-th`
  requires a live, already-migrated database to even type-check at compile time — a
  chicken-and-egg problem for a fresh checkout — so Phase-1 uses plain `hasql` with
  hand-written `Encoders`/`Decoders` instead. Revisit `hasql-th` once there's a CI step
  that can migrate a throwaway DB before `cabal build` runs.
- **No Redis, rate limiting, `odd-jobs`, or `servant-swagger`** — none of these exist in
  app01 either. Explicitly deferred to keep the first Haskell build low-risk, not
  silently dropped from the vision.

## Running the stack locally

No Docker on this machine (see `../CLAUDE.md`). Use `scripts/local-dev-up.sh` /
`scripts/local-dev-down.sh` (portable installs under `C:\Users\krish\tools\` +
`C:\ghcup\`, not containers — see comments in those scripts).

## Environment-specific gotchas (worth knowing before you fight them again)

This machine runs one shared, Docker-less Postgres instance (started by
`scripts/local-dev-up.sh`) for every `app0N_*` course project, not one per
project. `app01_react`'s Java/Flyway backend already owns a database named
`securevision` on that shared instance, with its own schema (comma-joined
`stride`/`tags` TEXT columns, `flyway_schema_history`). This backend uses a
**separate database named `haskshield`** (same `securevision` role/password)
to avoid colliding with it — created once via `createdb -O securevision
haskshield`. `scripts/local-dev-up.sh` already points `DB_NAME` at
`haskshield` for this reason; don't "fix" it back to `securevision`. This is
purely a shared-local-Postgres artifact — a real Docker Compose deployment
gives each app its own container + volume, so `docker-compose.yml` can (and
does) still say `securevision` without any conflict.

This machine's Norton Antivirus does TLS interception (root cert:
`C:\Users\krish\tools\norton-root.cer` / `.pem`). MSYS2's `pacman`/`curl` (bundled with
GHCup) ships its own CA bundle and doesn't trust it by default, so any `pacman`-driven
install fails with `SSL certificate problem: unable to get local issuer certificate`
until that root is appended to `C:\ghcup\msys64\usr\ssl\certs\ca-bundle*.crt` (already
done as of this writing). `cabal`/GHC itself uses the Windows certificate store and
isn't affected. If MSYS2 is ever reinstalled, redo the cert append.
