# ThreatView 2026 — Angular implementation (app02_angular)

Pairs a separate Spring Boot backend with **Angular 18** instead of React. Renamed here
(`ThreatView`, package `com.threatview`, artifact `threatview-backend`) — this is a
genuinely independent Spring Boot app, not a shared/forked copy of app01's code, though
it mirrors app01's layering closely (same controller/service/repository/entity split,
same `StringListConverter`-style comma-joined `TEXT` columns, same Flyway approach). See
`../CLAUDE.md` for the sibling list, canonical API contract, and shared local-dev notes
— app01 remains the contract of record.

## Current state

**Backend** (`backend/src/main/java/com/threatview/`): `FrameworkController`,
`ThreatController`, and **`AuthController`** (JWT login) are implemented, backed by
`FrameworkService`/`ThreatService`, `FrameworkRepository`/`ThreatRepository` (+
`ThreatSpecifications` for dynamic filtering). Auth is fully wired: `JwtService` (HS256
via `Keys.hmacShaKeyFor`, matching app01), `JwtAuthFilter`, `SecurityConfig` (stateless,
CSRF disabled, `/api/v1/auth/**` + `/api/v1/frameworks/**` + `/api/v1/threats/**` +
actuator/swagger public, `/api/v1/admin/**` reserved for `ROLE_ADMIN`, everything else
authenticated). Dev-only single-admin login — credentials from config
(`threatview.admin.username` / `.password-hash`), no user table. `CardSuitController`,
`MitigationController`, `MatrixController`, `SearchController`, `ExportController`,
`AdminController` from PLAN.md's architecture diagram do **not** exist — Phase 1 only.
Later-phase tables (`mitigation`, `code_sample`, `cross_reference`, `cornucopia_card`,
`content_hash`, `threat_translation`) exist in `V1__init_schema.sql` but are **not**
JPA-mapped or exposed. Only test: `ThreatViewApplicationTests` — a Testcontainers
context-load smoke test (proves migrations + JPA mappings + security wiring boot
cleanly), no controller/service unit tests.

**Frontend** (`frontend/src/app/`): no login component, no auth interceptor, no
`/frameworks` or `/threats` route yet — just `AppComponent` shell + `DashboardComponent`
(stat cards, client-side quick search over frameworks, Polish-language UI strings).
`LanguageToggleComponent` persists a locale to `localStorage` (`tv_locale`) but doesn't
translate anything — `ngx-translate` isn't wired up despite being in PLAN.md's stack
table. No `.spec.ts` files anywhere — no frontend test coverage yet. `app.routes.ts`
only registers `''` -> `DashboardComponent` (lazy `loadComponent`) + wildcard redirect.

So: **backend auth is ahead of frontend** — the JWT login endpoint works and is
contract-shaped like app01's, but nothing in the Angular app calls it yet.

## Gotchas vs. the canonical contract (`../CLAUDE.md`)

- `POST /api/v1/auth/login` matches the canonical shape: `{token, tokenType:"Bearer",
  role:"ADMIN"}` (`LoginResponse.bearer(...)`), HS256 JWT — correctly did **not** assume
  RS256.
- Health check is **`/actuator/health`** (Spring Boot Actuator, exposed via
  `management.endpoints.web.exposure.include: health,info,metrics` in
  `application.yml`), **not** a custom `/health` route like app01's. If you add a
  bespoke `/health` for parity, decide deliberately — don't assume it already matches.
- `threat.model.ts` / `framework.model.ts` under `frontend/src/app/shared/models/` are
  written against the canonical contract's shape (paginated `Page<T>`, filter params) —
  cross-check against app01's actual Java DTOs before changing either side, not against
  any PLAN.md.

## Angular-specific things worth knowing before you touch this

- **Standalone components throughout**, no `NgModule` anywhere — bootstrapped via
  `app.config.ts` (`provideRouter`, `provideHttpClient`, `provideAnimations`,
  `provideZoneChangeDetection`). Use `ng generate --standalone` and wire new components
  into `app.routes.ts`, not into a module.
- **`frontend/proxy.conf.json`** proxies `/api/v1` to `localhost:8080` for `ng serve`
  (`npm start`). Dev-only — `nginx/nginx.conf` does the equivalent reverse-proxying in
  Docker Compose. If API calls 404 during local dev, check this file before suspecting
  the backend.
- Services (`ThreatService`, `FrameworkService` in `core/services/`) are
  `providedIn: 'root'`, inject `HttpClient` via `inject()` (not constructor injection),
  return `Observable<T>` — keep it idiomatic RxJS/`| async`, don't reach for
  `async/await` + `firstValueFrom` without a specific reason.
- `tsconfig.json` has `strict` + Angular's `strictTemplates` on. Template type-checking
  errors are usually real mismatches against `shared/models/`, not noise.
- All components use `ChangeDetectionStrategy.OnPush` per PLAN.md's D-09 — if a
  template isn't updating after a state change, check for in-place mutation of a
  signal/input before assuming OnPush is the culprit.

## Running the stack locally

No Docker on this machine (see `../CLAUDE.md`) — use `scripts/local-dev-up.sh` /
`scripts/local-dev-down.sh` (portable Postgres/Maven/Node under `C:\Users\krish\tools\`;
logs land in `.local-dev/{backend,frontend,postgres}.log`). Elsewhere, `docker compose
up --build` brings up Postgres 16, Redis 7, backend, frontend+nginx per
`docker-compose.yml` (Redis is provisioned but not yet used by any backend code — no
caching wired up). Dev admin login is `admin` / `changeme-dev-only` (bcrypt hash in
`.env`) — never commit real `ADMIN_PASSWORD_HASH`/`JWT_SECRET` values.

## Where to look for more

`PLAN.md`, `requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md` in this
directory describe the full 19-user-story aspirational end state (per `../CLAUDE.md`,
every sibling is far behind this vision) — treat them as background, not as a
description of current code.
