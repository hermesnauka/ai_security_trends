# SecureVision 2026 — Java/Spring Boot + React (app01_react)

**This app is the contract of record.** See `../CLAUDE.md` for the sibling
list and shared local-dev setup. This file covers what's specific to app01 —
and since every backend-having sibling mirrors this app's *actual* behavior
(not its `PLAN.md`), treat factual claims here as load-bearing for the whole
repo.

## Current state: Phase-1 / milestone M1 only

Read-only frameworks + threats, one hardcoded (config-driven) admin login, 4
seeded frameworks, ~33 threats. Later-phase tables (`mitigation`,
`code_sample`, `cross_reference`, `threat_translation`, `cornucopia_card`,
`content_hash`) exist in the `V1` Flyway migration
(`backend/src/main/resources/db/migration/V1__init_schema.sql`) but have no
JPA entities and are not exposed via the API. No `AdminController`, no CRUD,
no rate limiting. `docker-compose.yml` provisions a `redis` service that
nothing in the code currently talks to.

## Layout

```
backend/src/main/java/com/securevision/
  controller/   AuthController, FrameworkController, ThreatController
  service/      FrameworkService, ThreatService
  repository/   FrameworkRepository, ThreatRepository, ThreatSpecifications
  entity/       Framework, Threat, Severity, StrideCategory,
                StringListConverter, StrideSetConverter
  dto/          LoginRequest/Response, FrameworkResponse,
                ThreatResponse, ThreatSummaryResponse
  security/     JwtService, JwtAuthFilter
  config/       SecurityConfig, OpenApiConfig
  exception/    ApiExceptionHandler, ResourceNotFoundException
backend/src/main/resources/
  application.yml
  db/migration/V1__init_schema.sql, V2__seed_frameworks_and_threats.sql
backend/src/test/  single Testcontainers context-load smoke test only —
                    no controller/endpoint tests exist yet
frontend/src/
  api/client.ts   fetch wrapper, no auth header ever attached
  pages/          Dashboard, Frameworks, FrameworkDetail — that's all
  components/     NavBar
```

There is **no login page in the frontend** — `App.tsx` only routes `/`,
`/frameworks`, `/frameworks/:code`. The backend's `/api/v1/auth/login` exists
and is fully wired, but nothing in the UI calls it or stores a token; the SPA
only ever hits the public read endpoints. Don't assume an auth flow exists
end-to-end just because the backend half is built.

## API contract as actually implemented

```
POST /api/v1/auth/login        {username, password} -> {token, tokenType:"Bearer", role:"ADMIN"} | 401
GET  /api/v1/frameworks        -> FrameworkResponse[]
GET  /api/v1/frameworks/:code  -> FrameworkResponse | 404
GET  /api/v1/threats           ?frameworkCode&severity&stride&tag&q + Pageable(page,size,sort) -> Page<ThreatSummaryResponse>
GET  /api/v1/threats/:id       -> ThreatResponse | 404
GET  /actuator/health          -> Spring Boot Actuator's default body (also /actuator/info, /actuator/metrics)
```
`ThreatSummaryResponse`: `id, frameworkCode, code, title, severity, category,
stride, tags`. `ThreatResponse` (detail) adds `frameworkName, description,
attackVector, attackSurface, cveReferences` and intentionally omits nested
mitigations/code-samples (see doc comment on the DTO) rather than fake empty
arrays. `Page<T>` is Spring Data's native envelope: `{content, totalElements,
totalPages, number, size, ...}`. 4xx error body (`ApiExceptionHandler`):
`{timestamp, status, error, message}`.

**Gotcha for the root contract table:** the root `../CLAUDE.md` lists the
health check as `GET /health`. That endpoint does not exist in this codebase
— there's no custom mapping for it anywhere in `controller/`. The real one is
`/actuator/health`, from `spring-boot-starter-actuator` with
`management.endpoints.web.exposure.include: health,info,metrics` in
`application.yml`, and it's the path allow-listed in `SecurityConfig`
(`/actuator/health/**`). Any sibling copying the root file's `/health` literal
is copying a typo, not app01's behavior.

Auth is JWT **HS256** via `JwtService` (`Keys.hmacShaKeyFor`, single shared
`JWT_SECRET` from `securevision.jwt.secret`), enforced by `JwtAuthFilter`
ahead of `UsernamePasswordAuthenticationFilter`. `SecurityConfig` permits
`/api/v1/auth/**`, `/api/v1/frameworks/**`, `/api/v1/threats/**`,
`/actuator/health/**`, and the Swagger/OpenAPI paths; everything else
(including the not-yet-built `/api/v1/admin/**`) requires `ROLE_ADMIN`. There
is no user table — `AuthController` checks the single configured
`admin.username` / bcrypt `admin.password-hash` pair and mints a token; this
is deliberate dev-only single-admin auth, not a stub for something more that
already exists. The RS256 key-pair design some sibling `PLAN.md`s assumed was
never built here — HS256 is the real contract.

Swagger UI: `/swagger-ui.html` (`OpenApiConfig`), OpenAPI JSON at
`/v3/api-docs`.

## Data model notes

Entities: `Framework`, `Threat` only (`entity/`). `stride`, `cveReferences`,
`tags` are stored as **comma-joined `TEXT`** via `StringListConverter` /
`StrideSetConverter`, not native arrays or a join table — a deliberate
Phase-1 shortcut documented in the converters' own doc comments. Both
converters return `List.of()`/`Set.of()` (never `null`) on empty/blank input,
so `ThreatResponse`/`ThreatSummaryResponse` can pass `cveReferences`/`tags`
straight through from the entity without a null-guard even though only
`stride` has an explicit one — that asymmetry is intentional, not a bug, but
don't assume the guard exists if you touch these DTOs further.

## Known bugs / gaps — fix, don't "mirror"

- **`docker-compose.yml`, the `backend` service's `ADMIN_PASSWORD_HASH` line
  is still broken**: it reads `ADMIN_PASSWORD_HASH: ${}` instead of
  `ADMIN_PASSWORD_HASH: ${ADMIN_PASSWORD_HASH}`. `docker compose up` as
  checked in will not pass the admin hash through to the backend container —
  fix this before treating `docker compose up` as a working smoke test.
- No `./mvnw` wrapper is checked in (`README.md` calls this out); run
  `mvn -N wrapper:wrapper` once before scripting backend builds that assume
  a wrapper exists.
- Backend test suite is exactly one test (`SecureVisionApplicationTests`,
  a Testcontainers Postgres context-load check) — no controller/service unit
  tests, no endpoint integration tests exist yet.
- Frontend has no auth UI, no token storage, no protected routes — the JWT
  login endpoint is effectively backend-only right now.

## Running locally

```bash
docker compose up --build   # frontend :8081, backend :8080, swagger-ui.html
```
This machine has no Docker installed (see `../CLAUDE.md`), so day-to-day dev
uses `scripts/local-dev-up.sh` / `local-dev-down.sh` instead — that script
only ensures the `securevision` role/DB exist on the shared local Postgres
instance, it doesn't run the app itself. Copy `.env.example` to `.env` and
set real values first (`POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`,
`JWT_SECRET`, `ADMIN_USERNAME`, `ADMIN_PASSWORD_HASH`); dev-only admin
credentials (`admin` / `changeme-dev-only`, see `application.yml`'s comment
for the hash provenance) belong in your local `.env`, not in source control
as real secrets. `frontend/dist` is a committed Vite build output — treat it
as generated, not hand-edited.

## Where to look for more

`PLAN.md`, `requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md` in
this directory describe the full 9-phase aspirational vision (Cornucopia card
catalogue, i18n, code samples in 5 languages, admin CRUD, cross-reference
matrix, async export). None of that beyond what's listed above is built —
verify against `backend/src/main/java/com/securevision/` before assuming a
feature exists, that package is the actual source of truth over any planning
doc, including this file if it ever drifts.
