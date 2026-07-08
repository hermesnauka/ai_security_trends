# Backend (Haskell/servant/hasql)

Scope and API contract: see `../CLAUDE.md` first. This file is command/layout
reference for working in `backend/` specifically.

## Toolchain

GHCup-managed GHC 9.8.4 + Cabal 3.16.1.0, installed under `C:\ghcup\`. Add
`C:\ghcup\bin` to `PATH` (already done by `scripts/local-dev-up.sh`).

```
cabal build all        # compile library + api executable + test suite
cabal run api           # start the server (reads DB_*/JWT_*/ADMIN_* from env)
cabal test              # ServiceSpec (pure, no DB needed) + ApiSpec (needs a
                         # running, reachable Postgres -- see below)
```

`cabal run api` must be run with CWD = `backend/` (it looks for `./migrations`
relative to the current directory and applies any not yet recorded in the
`schema_migrations` table on every startup — idempotent, safe to run repeatedly).

`cabal test`'s `ApiSpec` opens its own connection and applies migrations
itself, so it just needs `DB_HOST`/`DB_PORT`/`DB_NAME`/`DB_USER`/`DB_PASSWORD`
(and `JWT_SECRET`/`ADMIN_USERNAME`/`ADMIN_PASSWORD_HASH`, since it exercises
the login endpoint) pointed at a real Postgres — start one with
`../scripts/local-dev-up.sh` first, or export the same vars manually.

## Layout

```
app/Main.hs              -- Warp entrypoint: load Config, run Migrate, serve Api
src/Domain/Types.hs       -- wire types + their ToJSON/FromJSON (Framework, Threat*, Page, ...)
src/Config.hs             -- env var loading
src/Migrate.hs            -- custom migration runner (see "Known deliberate deviations" below)
src/Store/*.hs            -- hasql Statements (Encoders/Decoders), one module per table
src/Service/*.hs          -- business logic that's actually worth unit-testing
                             (pagination math lives here, not in Api.Handler)
src/Auth/Jwt.hs           -- hand-rolled HS256 sign/verify
src/Api.hs                -- the servant API type (single source of truth for routes)
src/Api/Handler/*.hs      -- one handler module per route group
src/Api/Error.hs          -- JSON error body helpers (404/401/500)
migrations/*.sql          -- applied in filename order, tracked in schema_migrations
test/ServiceSpec.hs       -- hspec + QuickCheck, pure, no DB
test/ApiSpec.hs           -- hspec-wai, hits a real Postgres
```

## Known deliberate deviations from PLAN.md (not from app01 — see ../CLAUDE.md for those)

- **No `hasql-th`.** It type-checks queries against a *live* database at
  compile time, which is a chicken-and-egg problem for a fresh checkout with
  no CI step to migrate a throwaway DB first. `Store/*.hs` use plain `hasql`
  with hand-written `Encoders`/`Decoders` instead — still no string-concatenated
  SQL, still parameter/result types checked by the compiler, just not against
  a live schema. Revisit if a migrate-then-build CI step gets added.
- **No `jose`.** Its `signClaims`/`verifyClaims` API is polymorphic over
  `MonadRandom`/`MonadError`/`MonadTime`, which is a lot of surface for "sign
  one HS256 token." `Auth/Jwt.hs` is ~90 lines of hand-rolled HS256
  (HMAC-SHA256 via `crypton`, base64url via `base64-bytestring`, JSON via
  `aeson`) — deliberately boring and easy to verify by reading it.
- **`crypton` depends on `ram`, not `memory`, for `ByteArrayAccess`/`convert`.**
  Both packages export a module literally named `Data.ByteArray` with a
  same-named `ByteArrayAccess` class, but they're distinct types — `crypton`'s
  `Digest`/`HMAC` instances are for `ram`'s class. Depending on `memory` and
  importing `Data.ByteArray (convert)` compiles fine but fails at the call
  site with a confusing "no instance" error naming both packages by version.
  `Auth/Jwt.hs` depends on `ram`, not `memory`, for exactly this reason.
- **hasql/hasql-pool APIs are the current (2026) redesigned ones** —
  `Hasql.Connection.Settings` as a `Monoid` (`hostAndPort <> user <> password
  <> dbname`), `Statement.preparable`/`unpreparable` instead of a `Statement`
  constructor, `Hasql.Pool.Config.settings [...]`. These are *not* what most
  hasql tutorials online show (they show an older, different API) — if you're
  reading unfamiliar hasql code and it doesn't match what you remember, check
  the version in `hasshield.cabal`'s resolved build plan before assuming it's
  wrong.
