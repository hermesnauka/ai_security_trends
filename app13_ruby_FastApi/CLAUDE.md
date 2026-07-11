# RubyGuard 2026 — Ruby/Grape implementation (app13_ruby_FastApi)

Ruby backend (Grape + Sequel + PostgreSQL) + a framework-free vanilla-JS frontend. See
`../CLAUDE.md` for the sibling list. Unlike `app09_php_WORDPRESS`/`app11_swift_ios`/
`app12_kotlin_android`, this app **does** follow the shared Phase-1 API contract — it has a
real client-server model, same category as `app01_react`/`app02_angular`/`app03_python_django`/
`app05_go_react`/`app07_rust_react`/`app08_cpp_react`/`app10_csharp_react`.

## This directory's docs were wrong before 2026-07-11 — don't trust old context about it

All five planning docs here (`PLAN.md`, `requirements.md`, `SDLC_analysis.md`,
`user_stories+tests.md`, and this file) were, until 2026-07-11, an accidental byte-for-byte
duplicate of `app12_kotlin_android`'s KotlinGuard content — wrong stack (Kotlin/Android),
wrong directory reference, wrong everything. All five were rewritten from scratch for this
app's actual stack. If you have older context (a summary, a memory, a cached read)
describing this directory as Kotlin/Android/offline, it is stale — re-read the current
files.

## Naming note: "FastApi" in the directory name is a style reference, not a literal dependency

`FastApi` in `app13_ruby_FastApi` refers to Python's FastAPI framework only as a design
philosophy — this app's actual backend framework is **Grape** (a declarative Rack-based
REST DSL), chosen specifically because its `params` validation blocks + `grape-swagger`
auto-generated OpenAPI docs are the closest real Ruby analogue to FastAPI's Pydantic
validation + automatic `/docs`. See `PLAN.md` §0 for the full reasoning, including what
does **NOT** carry over (FastAPI's native async/await — this app uses Puma's ordinary
synchronous Rack worker model, stated explicitly rather than glossed over).

## Current state (verify against the filesystem before trusting this)

**Real source now exists**, built the same session the planning docs above were corrected,
with seed content (frameworks/threats/mitigations/6 Cornucopia decks/50 code samples)
copied verbatim from `app12_kotlin_android`'s already-integrity-verified assets — the same
"language-agnostic educational content, reused rather than re-authored" principle every
sibling since app09 follows:

- **`backend/`**: Grape (`app/api/`: `auth_api.rb`, `frameworks_api.rb`, `threats_api.rb`,
  `cards_api.rb`, `mitigations_api.rb`, `matrix_api.rb`, `search_api.rb`, `export_api.rb`,
  `health_api.rb`, mounted from `root_api.rb` with `grape-swagger`), Sequel models
  (`app/models/`) over 8 migrated tables (`db/migrations/001`–`008`, including the D-03
  `CHECK` constraint pair on `cards`), and services (`app/services/`: `CardFileLoader`
  D-06 allow-listed-keys YAML decoder, `ReferenceValidator`, `IntegrityChecker`,
  `ContentSeeder`, `JwtService`). `Rakefile` provides `db:migrate`/`db:seed`/`db:seed_admin`.
  The RSpec suite now covers every service and model, not just a representative slice:
  `spec/requests/` (auth, health, cards, mitigations, export, frameworks, threats, matrix,
  search), `spec/services/` (`ReferenceValidator`, `CardFileLoader` — D-06 + uncurated-skip
  behavior — `CodeSampleCompletenessSpec`'s `rantly`-based property test, `JwtService`,
  `IntegrityChecker`, `ContentSeeder`), and `spec/models/` (`Card`'s D-03 `CHECK` constraint,
  `User`'s bcrypt hashing + `users_role_check` constraint, `Threat`'s localization fallback +
  `threats_severity_check`/FK constraints). `spec/spec_helper.rb` seeds a real test admin
  user and clears Rack::Attack's in-memory cache store per-example so one example's login
  attempts never bleed into another's rate-limit assertions.
  - **The exact "uncurated card crashes ingestion" bug independently caught and fixed in
    app11_swift_ios's and app12_kotlin_android's loaders was written correctly here from
    the start** — `CardFileLoader#build_seed` skips (returns `nil`) a card with no curation
    entry at all, and only raises `MissingCuratedSeverity` for a curated-but-malformed
    entry — see the doc comment there for why conflating those two cases is the bug this
    avoids.
  - Writing this suite (even unexecuted) surfaced two real bugs, since fixed: Rack::Attack's
    cache store leaking counters across examples (fixed via the per-example clear above), and
    login returning the wrong HTTP status on bad credentials.
- **`frontend/`**: a genuinely framework-free ES2022 app (`src/main.js` composition root,
  a ~30-line History-API `router.js`, a hand-written `i18n.js` store, `api-client.js`,
  and one `render(container, params)` module per view under `src/views/`) — the D-08
  differentiator every other backend+SPA sibling doesn't have. The D-09 attack-demo gate
  is a native `<dialog>` element. `package.json` wires `esbuild` (optional production
  minification only — `index.html` runs `src/main.js` directly as native browser ES
  modules, no bundling step is required for the app to function), `vitest`
  (`src/__tests__/i18n.test.js`, `api-client.test.js`, `router.test.js` — 23 unit tests
  covering the locale store, the fetch wrapper's auth-header/param-filtering/error-body
  behavior, and the History-API router's param extraction + `data-nav` click interception),
  and `@playwright/test` (`e2e/us01-frameworks.spec.js`, `e2e/us03-threat-detail.spec.js`, 2
  representative specs mirroring app11/app12's equivalents — not all 19 user stories, same
  representative-slice pattern).
- `docker-compose.yml` (Postgres 16 + backend + Nginx) and `nginx/default.conf`
  (proxies `/api/*`+`/health` to Puma, serves the frontend directly, falls back to
  `index.html` for client-side routes) exist at the app root. `scripts/local-dev-up.sh`/
  `local-dev-down.sh` follow the shared convention (`../CLAUDE.md`) for the Docker-less
  local Postgres instance.

**The frontend unit suite has actually been run and passes** — as of 2026-07-11, Node 22 /
npm 10 turned out to be available in this environment after all (the `../CLAUDE.md` "no
Node runtime" note was true when first written, not currently): `npm install` +
`npx vitest run` in `frontend/` gives 23/23 passing. That run also caught and fixed a real
bug: `vitest.config.js` had no `exclude` for `e2e/`, so `vitest run` tried to collect the
Playwright specs directly and failed with "Playwright Test did not expect test() to be
called here" — now excluded.

**Everything else remains unexecuted.** No Ruby/Bundler/Postgres runtime exists in this
environment, so the full RSpec suite, `rake db:migrate`, and `docker compose up` are still
unverified — every backend file is real, structurally-checked-by-hand Ruby (brace/`end`
balance checked by hand, cross-referenced for dangling constant/import names since no
interpreter was available to verify) but none of it has been run through `bundle exec` or
`rspec`. The Playwright E2E specs also haven't run (no browsers installed via
`npx playwright install`, and no server for them to point at). Treat backend + E2E the same
as every other sibling's "unverified but structurally correct" source; treat the frontend
unit suite as genuinely green.

**Not built at all:** admin CRUD screens, JWT roles beyond `ADMIN`, async export-job
polling, a mobile-vs-web matrix endpoint, `Login`-gated write routes beyond login itself
(Phase-1 parity, `requirements.md` §2), and 17 of the 19 planned Playwright E2E specs.

## Key decisions to know before writing code (`PLAN.md` §2–§5 has full detail)

- **Backend:** Ruby 3.4, Grape (API framework) + Sequel (ORM, not ActiveRecord — usable
  standalone without pulling in Rails) + PostgreSQL, served by Puma.
- **Auth:** JWT HS256, one hardcoded admin user — matches `app01_react`'s actual contract
  exactly (D-01). No OAuth, no RS256 (that's `app05_go_react`'s one stated exception, not a
  pattern to copy here).
- **`card_kind` (technical-threat vs. design-harm) has no compiler-enforced sum type in
  Ruby** — modeled as a `card_kind` string column with a Postgres `CHECK` constraint
  enforcing `severity IS NULL` for `design_harm` rows (D-03) — a real, DB-enforced
  guarantee, but a weaker tier than Rust/Haskell/Swift/Kotlin's compiler-enforced sum
  types in the sibling apps that have them. State this precisely; don't claim parity with
  those.
- **SQL safety is runtime-only** (D-04), like `app03_python_django`/`app09_php_WORDPRESS`:
  Sequel's parameterized dataset API is the actual guarantee, Brakeman + RuboCop are the
  closest static-analysis substitute for what a type system would otherwise catch.
- **Frontend is deliberately framework-free** (vanilla ES2022 JS, no React/Angular/Vue,
  D-08) — a genuine differentiator for this course's comparison matrix, not a shortcut.
  Don't "upgrade" it to React without checking `PLAN.md` §2 first — it's a stated,
  load-bearing decision.
- **i18n:** a hand-written client-side `i18n.js` store (D-05), not a library — PL default,
  instant client-side switch, no page reload.
- Every raw Cornucopia YAML file is decoded with an explicit allow-listed-keys check
  (D-06) — Ruby's `Psych`/`JSON.parse` are lenient by default, the opposite end from
  Kotlin's kotlinx.serialization (`app12_kotlin_android`) or C#'s `YamlDotNet`
  (`app10_csharp_react`).

## Where to look for more depth

`PLAN.md` is the primary source (§0/§0.1 stack rationale + source-material provenance,
architecture §3, decisions §4, data model §5, phased build plan §6, API contract §7, risk
register §13). `requirements.md` has the full FR/SR/NFR/DR list. `user_stories+tests.md`
has all 19 user stories with real Polish-translated Cornucopia card examples and their
OWASP coverage. `SDLC_analysis.md` covers the SSDLC/SDLC analysis, with a dedicated section
(§8) on why this project runs Scrum + Kanban (Scrumban) rather than Waterfall or pure Scrum
alone.
