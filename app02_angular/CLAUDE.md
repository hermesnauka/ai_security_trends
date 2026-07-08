# ThreatView 2026 — Angular implementation (app02_angular)

Pairs the same backend stack as app01 (Spring Boot) with **Angular 18** instead
of React. Product is renamed here (`ThreatView`, package `com.threatview`,
artifact `threatview-backend`) — this is a genuinely separate Spring Boot app,
not a shared/forked copy of app01's code, though it mirrors app01's structure
closely (same controller/service/repository/entity layering, same
`StringListConverter`-style comma-joined `TEXT` columns, same Flyway approach).
See `../CLAUDE.md` for the sibling list, canonical API contract, and shared
local-dev setup — app01 remains the contract of record.

## What's actually built vs. what PLAN.md/README imply

- Backend: `FrameworkController`, `ThreatController` only (no `CardSuitController`,
  `MitigationController`, `MatrixController`, `SearchController`, `ExportController`,
  `AdminController` from the PLAN.md architecture diagram — those are all aspirational).
  Later-phase tables (`Mitigation`, `CodeSample`, `CrossReference`, `ThreatTranslation`,
  `CornucopiaCard`, `ContentHash`) exist in the `V1__init_schema.sql` migration but are
  **not** JPA-mapped or exposed.
- Frontend: no login component, no auth interceptor, no `/frameworks` or `/threats`
  route yet — just `AppComponent` shell + `DashboardComponent` (stat cards, client-side
  quick search over frameworks). `LanguageToggleComponent` persists a locale to
  `localStorage` (`tv_locale`) but doesn't translate anything — `ngx-translate` isn't
  wired up despite being in PLAN.md's stack table.

## Contract-shape note

`threat.model.ts` / `framework.model.ts` under
`frontend/src/app/shared/models/` are written against the canonical contract's
exact shape (see `../CLAUDE.md`) — check app01's Java DTOs before changing
either side.

## Angular-specific things worth knowing before you touch this

- **Standalone components throughout**, no `NgModule` anywhere — bootstrapped via
  `app.config.ts` (`provideRouter`, `provideHttpClient`, `provideAnimations`,
  `provideZoneChangeDetection`). If you scaffold a new component, use
  `ng generate --standalone` (the CLI default in Angular 18) and wire it into
  `app.routes.ts`, not into a module.
- **`frontend/proxy.conf.json`** proxies `/api/v1` to `localhost:8080` for `ng serve`
  (`npm start`). This is dev-only — nginx (`nginx/nginx.conf`) does the equivalent
  reverse-proxying in the Docker Compose setup. If API calls 404 during local dev, check
  this file before suspecting the backend.
- Services (`ThreatService`, `FrameworkService` in `core/services/`) are
  `providedIn: 'root'`, inject `HttpClient` via `inject()` (not constructor injection),
  and return `Observable<T>` — don't reach for `async/await` + `firstValueFrom` unless
  there's a specific reason; keep it idiomatic RxJS/`| async` pipe in templates.
- `tsconfig.json` has `strict` + Angular's `strictTemplates` on. Expect template
  type-checking errors that React/JSX wouldn't catch — read the actual compiler error,
  it's usually a real type mismatch against the model in `shared/models/`, not noise.
- All components declared with `ChangeDetectionStrategy.OnPush` per PLAN.md's D-09 —
  if a template isn't updating after a state change, check whether a signal/input was
  mutated in place instead of reassigned before assuming OnPush is the culprit.

## Running the stack locally

No Docker on this machine (see `../CLAUDE.md`) — use `scripts/local-dev-up.sh` /
`scripts/local-dev-down.sh` (portable Postgres/Maven/Node under
`C:\Users\krish\tools\`). Elsewhere, `docker compose up --build` brings up
Postgres 16, backend, frontend+nginx per `docker-compose.yml`. Dev admin login
is `admin` / `changeme-dev-only` (see `.env`) — never commit real
`ADMIN_PASSWORD_HASH`/`JWT_SECRET` values.
