# SharpGuard 2026 — C#/.NET implementation (app10_csharp_react)

The C#/.NET 9 backend + React/TS frontend implementation of SecureVision. See
`../CLAUDE.md` for the sibling list, canonical Phase-1 API contract, and shared
local-dev-tooling notes.

## Current state: backend and frontend both exist and are wired together

Both halves are built — this is further along than the root `CLAUDE.md`'s sibling
status table says (it still lists app10 as "frontend only, backend not started";
that line is stale, verify against the filesystem, not that table).

- **`backend/`** — ASP.NET Core 9 Minimal API, single project
  `backend/src/SharpGuard.Api/SharpGuard.Api.csproj` (`SharpGuard.sln` at
  `backend/`). Implements the full canonical Phase-1 contract from `../CLAUDE.md`:
  `POST /api/v1/auth/login`, `GET /api/v1/frameworks[/:code]`,
  `GET /api/v1/threats[/:id]`, `GET /health`. EF Core 9 + Npgsql against Postgres,
  with a real migration (`Migrations/20260710223710_InitialCreate.cs`) and
  `SeedData.cs`. Routes live in `Endpoints/` (`AuthEndpoints.cs`,
  `FrameworkEndpoints.cs`, `ThreatEndpoints.cs`), DTOs in `Dtos/`, entities in
  `Entities/` (`Framework`, `Threat`, `Severity`), JWT issuance in
  `Auth/JwtTokenService.cs`.
- **`frontend/`** — Vite + React 18 + TS, `src/pages/` (Dashboard, Frameworks,
  FrameworkDetail, Threats, ThreatDetail), `src/api/client.ts`, `src/types/index.ts`.
  Types and API client already match the backend's actual DTO shapes (checked
  against `Dtos/*.cs` directly) — not just an aspirational/mocked shape anymore.
- **Not built:** any of the larger 19-user-story aspirational scope in `PLAN.md` /
  `requirements.md` / `SDLC_analysis.md` / `user_stories+tests.md` — Cornucopia card
  decks, YAML ingestion, Hangfire background jobs, admin CRUD, i18n. No user table
  either (`AuthEndpoints.cs` is a single hardcoded-admin login sourced from env
  config, not a DB-backed user store — see below). Treat those docs as describing a
  future phase, not current behavior; verify any specific claim against
  `backend/src/SharpGuard.Api/` before relying on it.

## Auth: HS256, already correct — do not "fix" this to RS256

`Auth/JwtTokenService.cs` signs with `SecurityAlgorithms.HmacSha256` and a shared
secret from `JWT_SECRET`, matching app01's actual `JwtService`
(`Keys.hmacShaKeyFor`). `PLAN.md` may still describe RS256 (an earlier, wrong
assumption shared by several sibling PLAN.md files, per `../CLAUDE.md`) — the code
itself already carries a comment explaining why HS256 is correct. If `PLAN.md` still
says RS256 elsewhere, the code is right and the doc is stale; don't switch the
implementation back to RS256 to match it.

Login (`Endpoints/AuthEndpoints.cs`) checks a single admin identity from
`Admin:Username` / `Admin:PasswordHash` config (populated from `ADMIN_USERNAME` /
`ADMIN_PASSWORD_HASH` env vars in `Program.cs`), verified with `BCrypt.Net`. No
hardcoded fallback for `DB_PASSWORD`, `JWT_SECRET`, or the admin credentials — startup
throws if any are unset/blank (`Program.cs`), specifically to avoid a silently-active
dev default. Copy `backend/.env.example` to `backend/.env` and fill in every value
before running.

## Design decisions worth knowing before touching backend code

- **EF Core + Npgsql, not Dapper** — chosen for compile-time C#-expression
  type-checking, but EF Core does **not** verify query shape against the live DB
  schema at compile time the way Go's `sqlc`, Haskell's `hasql-th`, or Rust's
  `sqlx::query!` do. Don't oversell this guarantee in docs/comments.
- **Unknown filter values degrade gracefully, not with an error** —
  `ThreatEndpoints.cs`: an unparseable `severity` query param matches zero rows
  rather than throwing (app01's Java `Severity.valueOf` throws on bad input; that's
  treated as an accident of the reference impl, not a contract requirement). `sort`
  is resolved through a fixed allowlist of column names (`id`, `code`, `title`,
  `severity`, `category`) since a column choice can't be parameterized like a value;
  unknown sort field/direction falls back to the default (`severity asc`).
- **CORS is wildcard, no credentials** — this is a bearer-token API with no cookies,
  so `AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()` in `Program.cs` is
  considered safe; don't add cookie-based auth without revisiting this.
- **Flat env var names** (`DB_HOST`, `JWT_SECRET`, etc.), not ASP.NET Core's
  `Section__Key` convention — `Program.cs` reads them directly so
  `scripts/local-dev-up.sh` can export the same flat names every sibling app uses.
- Still just planned, not yet implemented anywhere in the tree: `YamlDotNet`
  Cornucopia-deck ingestion, `Microsoft.AspNetCore.RateLimiting`, Native AOT publish,
  Roslyn/SecurityCodeScan/SonarAnalyzer SAST wiring, exhaustive-switch
  `CS8509`-as-error enforcement. If you implement any of these, also update this
  file — right now the `.csproj` only references `BCrypt.Net-Next`,
  `Microsoft.AspNetCore.Authentication.JwtBearer`, `Microsoft.EntityFrameworkCore.Design`,
  `Npgsql.EntityFrameworkCore.PostgreSQL`, and `System.IdentityModel.Tokens.Jwt`.

## Local dev

No Docker on this machine (see `../CLAUDE.md`) and no `docker-compose.yml` exists in
this directory yet. `scripts/local-dev-up.sh` / `local-dev-down.sh` start Postgres
(portable install), `dotnet run --project backend/src/SharpGuard.Api` on `:8080`, and
`npm run dev` (Vite) on `:5173`, logging to `.local-dev/*.log`. Requires
`backend/.env` (copy from `backend/.env.example`) with `DB_PASSWORD`, `JWT_SECRET`,
`ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH` set — the script fails fast if `.env` is
missing, and the app itself fails fast at startup if any of those four are blank.
`nginx/nginx.conf` proxies `/api/v1/*` for a prod-like local setup but isn't part of
the `local-dev-up.sh` path.

## Where to look for more

`PLAN.md`, `requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md` describe
the full aspirational 19-user-story end state — treat them as a roadmap, not a
description of current behavior. For actual current behavior, read
`backend/src/SharpGuard.Api/` directly (it's small enough to read in full) rather
than trusting either this file or the planning docs in isolation.
