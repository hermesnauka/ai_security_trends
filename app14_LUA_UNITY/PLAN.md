# LuaGuard 2026 — Application Development Plan

**Version:** 1.0
**Date:** 2026-07-11
**Status:** Living document — updated after each sprint planning session
**Directory:** `app14_LUA_UNITY`
**Sibling projects:** `app01_react`/`app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django),
`app04_scala_react` (Scala/ZIO), `app05_go_react` (Go), `app06_HASKELL_react` (Haskell),
`app07_rust_react` (Rust), `app08_cpp_react` (C++), `app09_php_WORDPRESS` (PHP/WordPress),
`app10_csharp_react` (C#/.NET), `app11_swift_ios` (Swift/iOS), `app12_kotlin_android`
(Kotlin/Android), `app13_ruby_FastApi` (Ruby/Grape)

---

## 0. Note on the Stack — Lua as Gameplay Script, Unity as Host

This app is named for its two defining technologies: **Lua** (the scripting language for all
gameplay/domain logic, both client and server) and **Unity** (the game-engine client). Unlike
every prior sibling, LuaGuard frames SecureVision's content — OWASP/MITRE/CompTIA threats and
their mitigations — as a digitized version of a real, existing artifact: **OWASP Cornucopia**
("Security Architects" in its Polish-translated instruction manual, `../docs/Security
Architects+ Comptia+OWASP LLM top10__v01b.md`), the free, open-source threat-modeling card
game this whole repo's Cornucopia seed content already comes from. Every sibling since app09
ingests Cornucopia's YAML card decks as static reference data; **LuaGuard is the first sibling
to also implement the game itself** — Regular mode, Shift Left mode, and the Threat Modeling
Workshop mode described in that document — as playable Unity scenes, on top of the same
Phase-1 browsing API every client-server sibling exposes.

**Why Lua for both tiers, not just the client:** Unity's embedding story for Lua is real and
common (`MoonSharp`, a pure-C# Lua 5.2 interpreter, used by shipped Unity titles precisely to
let designers iterate on gameplay data/rules without recompiling C#) — that's the frontend
half. The backend half re-uses the same rationale server-side: **OpenResty** (nginx embedding
LuaJIT) with the **Lapis** web framework is a real, production-grade Lua web stack (originally
built for MoonMax/itch.io), giving Lua a legitimate reason to exist on both sides of the wire
instead of only inside the game client. Nothing here is a novelty stack picked only to say
"we used Lua twice" — both halves are real tools solving the problem a professional team would
reach for them to solve.

**What does NOT carry over:** Lua's dynamic typing means neither tier gets any compile-time
type safety — no sibling's weakest tier on that axis, tied with Ruby (`app13_ruby_FastApi`)
and PHP (`app09_php_WORDPRESS`), and explicitly weaker than Rust/Haskell/Swift/Kotlin/Scala's
compiler-enforced sum types for the `card_kind` distinction (§4, D-03). MoonSharp's Lua is
Lua 5.2-superset, not 5.4 — a few 5.4 stdlib additions (`utf8` library changes, integer
division `//`) are unavailable client-side; the backend, running real LuaJIT/Lua 5.1-compatible
OpenResty, has its own, different subset ceiling. The two Lua runtimes are **not the same
Lua** and code is not shared between them — treat that as a real constraint, not an oversight.

## 0.1 Source Material — What Actually Exists vs. What's Curated

Same discipline as every sibling since app09: **real Cornucopia YAML decks, not invented
data.** The seed source lives at the repo root, shared across all client-server siblings:

- `../docs/OWASP_stories/*.yaml` — six real, unmodified OWASP Cornucopia deck files (`webapp`,
  `dbd` design-harm deck, `stride-eop`, `mlsec`, `mobileapp`, and the LLM/Agentic-AI
  `companion` deck) — the same six decks `app09`–`app13` ingest.
- `../docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md` — the source narrative this
  app is unique in also implementing as gameplay: the Polish/English game manual (About the
  Game, Game Modes, STRIDE glossary, gameplay set-up, Regular/Shift Left/Workshop mode rules),
  plus the OWASP LLM Top 10, MITRE ATLAS tactic/technique mapping, CompTIA Security+ (SY0-701)
  and CompTIA SecAI+ sections this PLAN's threat catalogue and `requirements.md` draw from.
- As with every sibling: **only a representative slice of curated content** (severity, OWASP
  refs, MITRE ATLAS refs, Polish translations) ships in Phase 1 — every raw card decodes, but
  only a sample per deck carries full curation. Don't assume every one of the ~100 real cards
  has a severity/reference mapping; see `user_stories+tests.md` for exactly which ones do.

## 1. Project Overview

LuaGuard 2026 digitizes SecureVision as **"Security Architects: Digital"** — a Unity client
(desktop + WebGL target) backed by a Lua/OpenResty REST API, matching the shared Phase-1
contract (`../CLAUDE.md`) for the browsing half (frameworks, threats, login, health), and
adding the Cornucopia card game's three modes as a Phase-2+ interactive layer on top of the
same content. A player/security-architect browses OWASP Web Top 10, OWASP LLM Top 10, MITRE
ATLAS, CompTIA Security+/SecAI+, and STRIDE-categorized threats and their mitigations (with
attack-demo + defense code samples in five languages), then — optionally — plays a session of
the actual card game against those same threats, learning the STRIDE taxonomy by defending a
simulated company's reputation for six turns.

## 2. Technology Stack

### Backend

- **Language:** Lua (LuaJIT 2.1, as embedded by OpenResty — not reference Lua 5.4).
- **Web framework:** Lapis (`leafo/lapis`) — a declarative routing + ORM layer over OpenResty,
  chosen as the closest real Lua analogue to Sinatra/Grape (small, explicit route blocks,
  first-class Postgres model layer), the same rationale every sibling's `PLAN.md` §0 gives for
  its own framework pick.
- **Database:** PostgreSQL 16, accessed via `lapis.db.postgres` (parameterized queries only —
  see D-02).
- **Auth:** `lua-resty-jwt` for JWT HS256 encode/decode — matches `app01_react`'s contract
  exactly (D-01).
- **YAML decoding:** `lyaml` (a LuaRocks binding over libyaml) for the Cornucopia deck files —
  the same "lenient parser, hand-checked allow-list" caveat every YAML-ingesting sibling
  states (D-06).
- **Server:** OpenResty (nginx + LuaJIT), running under `openresty/openresty:1.25.3-alpine` in
  Docker.

### Frontend

- **Engine:** Unity 2022 LTS, C# as the host language for scene/UI bootstrapping only — no
  gameplay or domain logic is written in C# (see D-07 for exactly where the Lua/C# boundary
  sits).
- **Lua runtime:** MoonSharp 2.0 (pure C#, MIT-licensed, no native plugin — works unmodified
  on WebGL/IL2CPP, unlike NLua/KopiLua which need native interop that WebGL can't support).
  All gameplay logic — card resolution, STRIDE matching, reputation math, the three game
  modes, i18n string lookups, mitigation-sample formatting — is Lua, loaded from
  `StreamingAssets/lua/*.lua`.
- **UI:** Unity UI Toolkit (UXML/USS), not uGUI — chosen for the same reason every vanilla-JS
  sibling avoids a component framework: UI Toolkit's retained-mode tree + C# event bindings is
  close enough to a "no extra framework" baseline for this course's comparison matrix, while
  still being Unity's own current-generation, actively-maintained UI system (uGUI is in
  maintenance mode as of Unity 2022).
- **Networking:** `UnityWebRequest` for all REST calls to the Lua backend — no third-party
  networking package.

### Infrastructure (shared conventions, see `../CLAUDE.md`)

- `docker-compose.yml`: Postgres 16 + OpenResty backend + Nginx (serves the WebGL build's
  static files, proxies `/api/*` to OpenResty) — the desktop Unity build talks to the same
  backend directly over HTTPS, no Nginx hop needed.
- Local dev: `scripts/local-dev-up.sh`/`local-dev-down.sh` follow the shared Docker-less
  Postgres convention every app on this machine uses (`../CLAUDE.md`), adding a `luarocks`
  bootstrap step for `lapis`/`lua-resty-jwt`/`lyaml`.
- Unity itself has no CLI-only headless build path usable without the Unity Editor/Unity Hub
  license activation — same class of "real source, never opened in the IDE" constraint as
  `app11_swift_ios` (no Xcode) and `app12_kotlin_android` (no Android Studio) — see
  `CLAUDE.md`.

## 3. Architecture

```
┌─────────────────────────────┐        HTTPS/JSON         ┌──────────────────────────────┐
│  Unity Client (C# host)     │ ────────────────────────▶ │  OpenResty + Lapis (Lua)     │
│  ┌────────────────────────┐ │                            │  ┌─────────────────────────┐ │
│  │ MoonSharp Lua VM       │ │ ◀──────────────────────── │  │ Lapis routes (app/)     │ │
│  │  - card_engine.lua     │ │      Bearer JWT (HS256)   │  │ Sequel-equivalent models│ │
│  │  - game_modes.lua      │ │                            │  │ (lapis.db.postgres)     │ │
│  │  - i18n.lua            │ │                            │  └─────────────────────────┘ │
│  │  - api_client.lua      │ │                            │             │                │
│  └────────────────────────┘ │                            │             ▼                │
│  UI Toolkit (UXML/USS)      │                            │       PostgreSQL 16           │
│  scenes/*.unity              │                            │  (frameworks/threats/cards/   │
└─────────────────────────────┘                            │   mitigations/code_samples/    │
                                                             │   cross_references/users)     │
                                                             └──────────────────────────────┘
```

C# owns exactly three things: booting Unity, mounting the MoonSharp `Script` sandbox with its
whitelisted API surface (D-07), and marshalling `UnityWebRequest` responses into Lua tables.
Every decision about what to render, how a STRIDE match resolves, and how reputation changes
is made in Lua — mirroring how every vanilla-JS frontend sibling keeps its "framework" (here,
Unity + C#) to plumbing only.

## 4. Key Design Decisions

- **D-01 (Auth):** JWT HS256 with a shared `JWT_SECRET`, one hardcoded admin user — matches
  `app01_react`'s actual contract exactly, not `app05_go_react`'s RS256 exception. Token
  stored in Unity's `PlayerPrefs` on the client — plaintext on disk, the same class of caveat
  every browser-`localStorage`-based sibling states about its own token storage; not
  encrypted-at-rest, a stated Phase-1 limitation, not an oversight.
- **D-02 (SQL safety is runtime-only):** Lapis's `db.query`/model layer only ever accepts
  parameterized placeholders (`db.query("... where code = ?", code)`) — Lua has no
  compile-time query checking, same tier as `app03_python_django`/`app09_php_WORDPRESS`/
  `app13_ruby_FastApi`. `luacheck` is the closest static-analysis substitute, not a SQL-aware
  linter.
- **D-03 (`card_kind` — no sum type):** Lua has no algebraic data types and no interfaces at
  all — the weakest static-safety tier of any sibling, tied with Ruby/PHP on "no compile-time
  help" but with neither language's minimal structural typing either. The
  technical-threat-vs-design-harm distinction is enforced the same way as every dynamically-
  typed sibling: a `card_kind` string column plus a Postgres `CHECK` constraint requiring
  `severity IS NULL` for `design_harm` rows — a real, DB-enforced guarantee, but state
  precisely that Lua itself contributes nothing here; the guarantee is 100% Postgres's.
- **D-04 (STRIDE-as-gameplay is additive, not a replacement taxonomy):** The Cornucopia STRIDE
  letters double as this app's actual game mechanic (attack cards match component
  vulnerabilities by STRIDE letter, per the source manual, §0.1) — but the underlying
  `threats`/`cards` schema is unchanged from every sibling's; STRIDE is still just a `text[]`
  column, not a new enum requiring engine support.
- **D-05 (i18n):** A hand-written `i18n.lua` string table loaded by both tiers independently
  (client Lua for UI strings, backend Lua for API error messages) — PL default, instant
  client-side switch via a Unity settings-menu toggle, no server round-trip needed to change
  locale. Threat/card *content* translations (`description_pl`) are separate rows in Postgres,
  fetched already-localized by `?locale=pl` — the same UI-string-vs-content-string split every
  i18n-supporting sibling makes.
- **D-06 (Cornucopia YAML decode, allow-listed keys):** `lyaml`'s underlying libyaml is
  lenient by default; the backend's `CardDeckLoader` hand-checks
  `raw_keys - ALLOWED_KEYS` and raises rather than silently accepting an unrecognized YAML
  key — identical discipline to `app13_ruby_FastApi`'s `CardFileLoader`.
- **D-07 (MoonSharp sandbox boundary — this app's genuinely novel risk class):** No other
  sibling embeds a general-purpose script interpreter inside its own client. MoonSharp's
  `Script` instance is constructed with an explicit whitelist
  (`CoreModules.Preset_SoftSandbox` minus `os`/`io`), **never** `CoreModules.Full` — Lua
  gameplay scripts must never gain filesystem or process access, since a future "load a
  community-authored card deck" feature (explicitly out of Phase-1 scope, `requirements.md`
  §2) would otherwise be a straightforward arbitrary-code-execution vector. Every C#↔Lua
  boundary call is a plain data marshalling call (tables/strings/numbers only) — no
  `UserData`-registered live C# object is ever exposed to Lua.
- **D-08 (Token/network storage caveat):** Same as D-01 — `PlayerPrefs` on desktop is a
  plaintext `.plist`/registry-key/`.dat` file depending on platform; WebGL builds use
  browser `localStorage` under the hood. Stated plainly, not hidden.
- **D-09 (Attack-demo gate):** A vulnerable code sample never renders until the player
  explicitly confirms via a UI Toolkit modal ("This code deliberately demonstrates a
  vulnerability — confirm to view it") — the same confirm-gate pattern as
  `app09_php_WORDPRESS`/`app13_ruby_FastApi`, implemented here as a Unity modal instead of an
  HTML `<dialog>`.

## 5. Data Model (PostgreSQL, via Lapis migrations)

Same nine tables as `app13_ruby_FastApi` §5 (the two client-server siblings share the same
Phase-1 content shape): `frameworks`, `threats`, `threat_translations`, `cards`, `mitigations`,
`code_samples`, `cross_references`, `content_hashes`, `users`. One addition unique to this
app, gated to Phase 2+ (not built in Phase 1, see §6):

- `game_sessions` — `id`, `player_token` (opaque, not a `users` FK — sessions are anonymous),
  `mode` (`regular`/`shift_left`/`workshop`), `turn`, `reputation`, `components` (`jsonb`,
  snapshot of on-table component state), `created_at`, `completed_at`. Exists in the schema
  from Phase 1 onward (so the migration ordering is stable) but is never written to until the
  Phase 2 game-mode routes exist.

`cards.card_kind`'s `CHECK` constraint (D-03) is identical to `app13_ruby_FastApi`'s: a
`design_harm` row must have `severity IS NULL`; every other `card_kind` must have a non-NULL
severity.

## 6. Phased Build Plan

1. **Phase 1 — Foundation + Browsing Parity:** Lapis skeleton, Postgres migrations, JWT auth,
   `CardDeckLoader`/`ContentSeeder` (backend Lua), `/api/v1/{auth,frameworks,threats,health}`
   matching the shared contract exactly. Unity: bootstrap scene, MoonSharp sandbox
   construction (D-07), `api_client.lua`, threats browser + detail UI Toolkit screens, login
   screen, PL/EN toggle.
2. **Phase 2 — Cards, Mitigations, Code Samples:** `/api/v1/cards`, `/api/v1/mitigations/:code`
   endpoints; five-language code samples (Python/Java/Go/Scala/Lua) with the D-09 attack-demo
   gate; card-browser UI Toolkit screens grouped by suit.
3. **Phase 3 — The Game Itself:** `game_sessions` table goes live; Regular mode first (turn
   loop, protection/attack/event card resolution, reputation tracking), then Shift Left mode
   (Development/Production zones), then the Threat Modeling Workshop mode (attack/protection
   card dealing, scoring) as a separate, non-turn-based Unity scene.
4. **Phase 4 — Search/Export/Matrix + Hardening:** FULLTEXT-equivalent search
   (`plainto_tsquery` over `threats`/`cards`), CSV export, STRIDE heatmap, then the WPCS/
   Brakeman-equivalent hardening pass — `luacheck` + a Lapis-specific SQL-injection lint rule
   set, plus a MoonSharp-sandbox-escape test suite (D-07) unique to this sibling.

## 7. API Contract (matches `../CLAUDE.md`'s canonical Phase-1 contract)

```
POST /api/v1/auth/login        {username, password} -> {token, tokenType:"Bearer", role:"ADMIN"} | 401
GET  /api/v1/frameworks        -> Framework[]
GET  /api/v1/frameworks/:code  -> Framework | 404
GET  /api/v1/threats           ?frameworkCode&severity&stride&tag&q&page&size&sort -> Page<ThreatSummary>
GET  /api/v1/threats/:id       -> ThreatDetail | 404
GET  /api/v1/cards             ?suitCode&edition -> Card[]                      # Phase 2
GET  /api/v1/mitigations/:code -> Mitigation[] (with code_samples)              # Phase 2
POST /api/v1/game/sessions     {mode} -> GameSession                            # Phase 3
POST /api/v1/game/sessions/:id/turn  {action, cardId?} -> GameSession           # Phase 3
GET  /health                   -> {"status":"UP"}
```

`Page<T>` matches app01's Spring Data envelope shape (`{content, totalElements, totalPages,
number, size}`) even though Lapis has no built-in equivalent — hand-built in the route
handler, same as every other non-Java sibling does.

## 8. Frontend Views (Unity Scenes)

- `LoginScene` — username/password form, PL/EN toggle, JWT stored via `PlayerPrefs`.
- `FrameworksScene` — framework list, tapping one filters into `ThreatsScene`.
- `ThreatsScene` — filterable threat list (severity/STRIDE/framework/tag/search).
- `ThreatDetailScene` — overview, attack vector/surface, STRIDE badges, mitigations with the
  D-09-gated code-sample tabs (5 languages).
- `CardBrowserScene` — Cornucopia cards grouped by suit (Phase 2).
- `GameModeSelectScene` → `RegularModeScene` / `ShiftLeftModeScene` / `WorkshopModeScene`
  (Phase 3) — the turn-based board, reputation meter, and card-play UI described in
  `../docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`.

## 9. Repository/Directory Layout

```
app14_LUA_UNITY/
├── backend/
│   ├── app/
│   │   ├── models/          # frameworks.lua, threats.lua, cards.lua, mitigations.lua, ...
│   │   ├── routes/          # auth.lua, frameworks.lua, threats.lua, health.lua, ...
│   │   └── services/        # card_deck_loader.lua, content_seeder.lua, jwt_service.lua,
│   │                         # reference_validator.lua, integrity_checker.lua
│   ├── db/
│   │   ├── migrations/
│   │   └── seeds/           # symlink or copy of ../../docs/OWASP_stories + curated JSON
│   ├── spec/                 # busted test suite
│   ├── config.lua
│   └── rockspec / Procfile
├── frontend/
│   ├── Assets/
│   │   ├── Scenes/
│   │   ├── Scripts/          # C# host: Bootstrap.cs, LuaSandbox.cs, ApiBridge.cs
│   │   ├── StreamingAssets/lua/  # card_engine.lua, game_modes.lua, i18n.lua, api_client.lua
│   │   └── UI/                # .uxml/.uss
│   ├── ProjectSettings/
│   └── Tests/                 # Unity Test Framework (EditMode) + a busted suite for the
│                                # StreamingAssets Lua scripts run standalone (no Unity needed)
├── docker-compose.yml
├── nginx/default.conf
└── scripts/local-dev-up.sh / local-dev-down.sh
```

## 10. Code Sample Strategy

Same five languages, same order, as `app13_ruby_FastApi` and `app09_php_WORDPRESS`: **Python,
Java, Go, Scala, Lua** — one attack-demo + one defense sample per mitigation per language,
stored as `code_samples` rows (`sample_type` = `attack_demo`/`defense`). Lua's own sample
uses the OpenResty/Lapis idioms this backend itself uses (so the "defense" Lua sample is
literally the pattern the backend route handlers follow) — the one sibling where the sample
language and the implementation language are the same, worth calling out explicitly so a
reader doesn't assume the code-sample Lua and the backend's own Lua diverge in style.

## 11. Threat Model Summary

Everything every client-server sibling already lists (JWT forgery, SQL injection via
unparameterized queries, missing `permission_callback`-equivalent route guards, XSS via
unescaped threat/card text) **plus one entry unique to this sibling**: an untrusted Lua
payload reaching either MoonSharp (client) or the backend's own Lua runtime is a direct
code-execution primitive, not merely a data-validation bug — D-07's sandbox and the explicit
Phase-1 decision to never load Lua from anything but this repo's own `StreamingAssets`/
`app/` directories (no user-supplied "custom card deck" scripting, no server-side `eval`-style
endpoint) are the two mitigations. `requirements.md`'s abuse-case table (§4) has the full
STRIDE-per-abuse-case breakdown.

## 12. CI/CD Pipeline

GitHub Actions: `busted` (backend Lua tests) + `luacheck` lint on every push; Unity's
`EditMode` test runner via `game-ci/unity-test-runner` (needs a Unity Personal license
activation secret — same class of CI dependency `app11_swift_ios`'s macOS-only runner
requirement and `app12_kotlin_android`'s Gradle/Android-SDK runner requirement represent);
`docker compose build` smoke test for the backend image. No WebGL build step in CI (Unity
WebGL builds are slow and require the full Editor — left as a manual release step, not a PR
gate).

## 13. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| MoonSharp sandbox escape via a future community-content feature | Low (not built in Phase 1) | Critical | D-07: whitelist-only `CoreModules`, no `UserData`-registered live objects, explicitly deferred feature |
| Lua's dynamic typing lets a `nil` propagate silently into a DB write | Medium | Medium | `luacheck` + explicit `assert()`/`error()` guards at every model boundary, same discipline app13 uses for Ruby |
| Unity Editor/license unavailable in CI or this dev environment | High (confirmed — no Unity install here) | Low (blocks compiling, not design) | Treat frontend source as "real, never opened in the Editor," same as app11/app12; `Tests/` Lua-only specs run under standalone `lua`/`busted`, independent of Unity |
| Two different Lua runtimes (LuaJIT backend vs. MoonSharp client) silently diverge in stdlib behavior | Medium | Low | No shared `.lua` files between `backend/` and `frontend/`; each tier's Lua is tested against its own runtime only |
| WebGL build target can't use any native Lua binding | High if attempted with NLua/KopiLua | High | D-07's choice of MoonSharp specifically, since it's pure C# and IL2CPP/WebGL-safe |
