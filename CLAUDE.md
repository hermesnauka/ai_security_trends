# Hermes_crewai_01 — course mono-repo (14 parallel SecureVision implementations)

This repo is a comparative exercise for the "AI in Programming" course: the same
product, **SecureVision** (a threat-modeling reference app — browse security
frameworks + threats, one hardcoded admin login), rebuilt from scratch in a
different stack per subdirectory, to compare AI-assisted development across
ecosystems. Each `appNN_*` directory has its own `CLAUDE.md` with stack-specific
detail — read this file first, then that one.

## The 14 implementations

| Dir | Stack | Status (2026-07-11) |
|---|---|---|
| `app01_react` | Java/Spring Boot + React | **contract of record** — backend+frontend built; no frontend login UI yet, health check is `/actuator/health` not `/health` (see below) |
| `app02_angular` | Java/Spring Boot + Angular | backend+frontend built (independent Spring app, not shared code); same `/actuator/health` divergence as app01 |
| `app03_python_django` | Python/Django | hybrid server-rendered + DRF API built; own contract shape, not app01's; JWT wired (simplejwt) but not enforced anywhere (`AllowAny` global default) |
| `app04_scala_react` | Scala/ZIO + React | backend+frontend built; HS256, matches app01; frontend has no login/threats-list/detail pages yet (threats only reachable filtered-by-framework); zero tests despite zio-test being a declared dependency |
| `app05_go_react` | Go (chi/pgx/sqlc) + React | backend+frontend built; **auth is RS256, a real standing deviation from app01's HS256 contract** — not a mistake to silently "fix," see below |
| `app06_HASKELL_react` | Haskell (servant/hasql) + React | backend+frontend built; HS256, matches app01; no frontend login UI yet (same gap as app01/app02); no `docker-compose.yml` (standalone Dockerfiles only) |
| `app07_rust_react` | Rust (axum) + React | backend+frontend built; HS256, matches app01; local-dev scripts are stale leftover copies of app01's (run Maven, not Cargo) — use `docker-compose.yml` or `cargo run` directly |
| `app08_cpp_react` | C++ (Drogon) + React | backend+frontend built; HS256, matches app01; Drogon's own async ORM used instead of the `libpqxx`/`sqlpp11` PLAN.md once proposed |
| `app09_php_WORDPRESS` | PHP/WordPress plugin | extensive WordPress plugin scaffold built (ingestion, mitigations/code samples, i18n, search/export/matrix, full-but-unexecuted test suite) — see its own `CLAUDE.md` for the representative-slice scope of each piece |
| `app10_csharp_react` | C#/.NET 9 + React | backend+frontend built; HS256, matches app01 |
| `app11_swift_ios` | native iOS (SwiftUI/SwiftData) | real Swift source built (SwiftData models, ContentSeeder, Views) plus a real package-level test suite (XCTest+SwiftCheck, runnable via `swift test`) but **no `.xcodeproj` and never compiled** — no API, offline-only |
| `app12_kotlin_android` | native Android (Compose/Room) | real Kotlin source built (Room entities/DAOs, ContentSeeder, repositories, Compose screens, `:data`/`:ui`/`:app` Gradle modules) plus a real test suite (JUnit4+Robolectric for `:data`, fakes for `:ui`, 2 instrumented Compose UI tests) but **never assembled/compiled** — no API, offline-only, structural twin of app11 |
| `app13_ruby_FastApi` | Ruby (Grape/Sequel) + framework-free vanilla JS | backend+frontend built (matches app01's HS256 contract); its four planning docs were originally an accidental duplicate of app12's KotlinGuard content and were fully rewritten 2026-07-11; "FastApi" in the dir name is a style reference (Grape's `params`+`grape-swagger` chosen as the closest Ruby analogue to FastAPI's validation+auto-docs), not a literal Python dependency — see its own `CLAUDE.md`; backend RSpec suite still unexecuted (no Ruby/Postgres runtime), but its frontend vitest suite (23 tests) has actually been run and passes — Node/npm turned out to be available in this environment after all |
| `app14_LUA_UNITY` | Lua (OpenResty/Lapis) + Unity/MoonSharp | backend+frontend built (matches app01's HS256 contract) — digitizes the real OWASP Cornucopia "Security Architects" card game (`docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`) as Phase 2+/3 gameplay on top of the standard Phase-1 browsing API; its five planning docs were originally an accidental duplicate of app12's KotlinGuard content and were fully rewritten 2026-07-11 — see its own `CLAUDE.md`; the one sibling embedding a general-purpose script interpreter (MoonSharp) inside its own client, sandboxed per D-07; nothing executed (no Lua/OpenResty/LuaRocks/Postgres/Unity runtime in this environment) |

This table was last verified against every app's actual filesystem/source on 2026-07-11.

## app01_react is the contract of record

Every sibling with its own backend (`app02`, `app03`, `app05`, `app06`, `app07`,
`app08`, `app10`, `app13`, `app14`) is supposed to mirror the API app01 *actually implements* —
**not** the aspirational design in any app's own `PLAN.md`. If a sibling's
behavior disagrees with app01's Java source, the sibling is wrong, not app01.
`app09` (WordPress) and `app11`/`app12` (native mobile, offline-only) are
deliberate exceptions to this rule — see their own `CLAUDE.md` for why they
don't follow the shared contract at all.

One confirmed, standing exception as of 2026-07-11: **app05's auth is RS256**,
not app01's HS256 — its own `PLAN.md` documents this and the Go code
implements it consistently, so this is a real, intentional-looking deviation,
not a bug to silently patch over. Every other sibling with a backend (app02,
app03, app07, app08, app10, app13, app14) now correctly matches app01's HS256. Also note:
app01 and app02's actual health-check route is Spring Actuator's
`/actuator/health`, not the literal `/health` shown in the contract block
below — the contract block describes the intended shape, app01's real route
differs from it slightly, and no sibling should copy the literal `/health`
path without checking.

## Canonical Phase-1 API contract

```
POST /api/v1/auth/login        {username, password} -> {token, tokenType:"Bearer", role:"ADMIN"} | 401
GET  /api/v1/frameworks        -> Framework[]
GET  /api/v1/frameworks/:code  -> Framework | 404
GET  /api/v1/threats           ?frameworkCode&severity&stride&tag&q&page&size&sort -> Page<ThreatSummary>
GET  /api/v1/threats/:id       -> ThreatDetail | 404
GET  /health                   -> {"status":"UP"}   # aspirational shape; app01's real route is
                                                      # Spring Actuator's /actuator/health (see above)
```
`Page<T> = {content, totalElements, totalPages, number, size}` (Spring Data's
envelope). Error body on 4xx: `{timestamp, status, error, message}`. Source of
truth: `app01_react/backend/src/main/java/com/securevision/`.

Auth is JWT **HS256** with a shared `JWT_SECRET` (`JwtService`,
`Keys.hmacShaKeyFor`) — app01 never had a key pair. Several sibling `PLAN.md`
files independently assumed RS256; see "app01_react is the contract of
record" above for exactly which siblings have since corrected that in code
(app02, app03, app07, app08, app10, app13, app14) versus the one standing, intentional
exception (app05). Check app01's actual code, not any `PLAN.md`, before
implementing auth in a new backend.

## Scope: every app is Phase-1 parity, not the full vision

Every app directory has its own copies of `PLAN.md`, `requirements.md`,
`SDLC_analysis.md`, `user_stories+tests.md` describing a much larger
19-user-story aspirational end state (six-plus Cornucopia card decks, i18n,
JWT roles beyond ADMIN, async export jobs, admin CRUD, cross-framework matrix,
code samples in 5 languages). Actual code is typically far behind that vision
in every app — verify against the filesystem before assuming a feature exists.

## Local dev environment (this machine)

No Docker installed. Each app that needs one uses `scripts/local-dev-up.sh` /
`local-dev-down.sh` — portable language toolchains under
`C:\Users\krish\tools\` instead of containers. **Postgres is one shared,
Docker-less instance across every app on this machine** (`:5432`) — each app's
script only ensures its own role/DB exists (e.g. app01 owns `securevision`,
app06 uses a separate `haskshield` DB to avoid colliding with it, app13 owns
`rubyguard`, app14 owns `luaguard`); stopping Postgres via any one app's
`local-dev-down.sh` affects every other app currently using it. A real Docker
Compose deployment (`docker compose up --build`, per each app's own
`docker-compose.yml`) gives each app its own container + volume with no such
collision — app13's own `docker-compose.yml` maps its containerized Postgres
to host port `5433`, and app14's to `5434`, specifically to avoid colliding
with the shared `:5432` instance (or each other) if run at once.

## Operating mode

Default to acting without asking for confirmation on routine build/doc work in this repo
(scaffolding new app directories, editing per-app `CLAUDE.md` files, adding source files,
running local builds/tests). Still ask before anything destructive or hard-to-reverse
(force-push, deleting branches/files, `git reset --hard`, overwriting uncommitted work) —
this default doesn't extend to those regardless of how it was phrased.
