# LuaGuard 2026 — Lua/Unity implementation (app14_LUA_UNITY)

See `../CLAUDE.md` for the sibling list and shared local-dev notes. SecureVision is a
threat-modeling reference app (browse security frameworks + threats, one hardcoded admin
login). This app digitizes it as **"Security Architects: Digital"** — the real, open-source
OWASP Cornucopia card game (`../docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`)
that every sibling since app09 already draws its Cornucopia seed content from, but that no
other sibling also implements as playable gameplay.

## This directory's docs were wrong before 2026-07-11 — don't trust old context about it

All five files here (`PLAN.md`, `requirements.md`, `SDLC_analysis.md`,
`user_stories+tests.md`, and this file) were, until 2026-07-11, an accidental byte-for-byte
duplicate of `app12_kotlin_android`'s KotlinGuard content — wrong stack (Kotlin/Android),
wrong directory reference, wrong everything (the same class of mistake `app13_ruby_FastApi`
had and fixed on the same date). All five were rewritten from scratch for this app's actual
stack. If you have older context (a summary, a memory, a cached read) describing this
directory as Kotlin/Android, it is stale — re-read the current files.

## Architecture: a real client-server model, Lua on both sides for different reasons

Unlike `app09_php_WORDPRESS`/`app11_swift_ios`/`app12_kotlin_android`, this app **does**
follow the shared Phase-1 API contract (`../CLAUDE.md`) — same category as `app01_react`/
`app02_angular`/`app03_python_django`/`app05_go_react`/`app07_rust_react`/`app08_cpp_react`/
`app10_csharp_react`/`app13_ruby_FastApi`. But its client is a Unity game, not a browser SPA:

- **Backend:** Lua (LuaJIT via OpenResty) + Lapis web framework + PostgreSQL — a real,
  production Lua web stack, not a novelty pick. Matches app01's HS256 JWT contract exactly
  (D-01), same as every sibling except `app05_go_react`'s stated RS256 exception.
- **Frontend:** Unity 2022 LTS (C# host only for scene/UI plumbing) with **MoonSharp**
  (pure-C# Lua interpreter) running all gameplay/domain logic as `.lua` files under
  `Assets/StreamingAssets/lua/`. UI Toolkit (UXML/USS), not uGUI. No third-party networking
  package — plain `UnityWebRequest`.
- **The two Lua runtimes are not the same Lua** — LuaJIT/OpenResty backend vs. MoonSharp's
  Lua 5.2-superset client. No `.lua` file is shared between `backend/` and `frontend/`; see
  `PLAN.md` §0 before assuming otherwise.
- **The one genuinely novel risk class in this repo:** embedding a general-purpose script
  interpreter inside a game client is itself an attack surface no other sibling's stack has.
  `PLAN.md` §4 D-07 and `requirements.md` SR-10/SR-11/SR-13 are the load-bearing decisions —
  MoonSharp's `Script` is always constructed with an explicit module whitelist (never
  `CoreModules.Full`), and this app never loads Lua from anything but its own repo paths (no
  "custom card deck" upload feature). Don't add one without a dedicated threat-model review
  first.

## Current state (verify against the filesystem before trusting this)

Check `backend/` and `frontend/` directly — this note will go stale the moment either grows.
As of this rewrite: the five planning docs above are real and stack-accurate; `backend/` and
`frontend/` scaffolding is described in `PLAN.md` §6/§9 but should be verified against what
actually exists on disk, not assumed from this file. Nothing has been executed in this
environment — no Lua/OpenResty/LuaRocks/Postgres/Unity runtime is available here (`../CLAUDE.md`);
treat all backend/frontend source the same as every other sibling's "unverified but
structurally correct" code until it runs somewhere that has these toolchains. Unity itself has
no CLI-only path usable without the Editor/a license activation — the same class of "real
source, never opened in the IDE" constraint as `app11_swift_ios` (no Xcode) and
`app12_kotlin_android` (no Android Studio).

**Phase-1 scope only, not the full vision:** the browsing half (frameworks/threats/cards/
mitigations/login, matching every client-server sibling) is what Phase 1 covers. The three
playable game modes (Regular, Shift Left, Threat Modeling Workshop) described in
`../docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md` are explicitly Phase 2+/3
(`PLAN.md` §6, `requirements.md` §2) — don't assume a working game loop exists just because
`game_modes.lua`/`game_sessions` are named in the schema/file layout.

## Key decisions before writing code (full detail: `PLAN.md` §2–§5)

- **Storage:** PostgreSQL via Lapis's `db.query`/model layer — same nine-table shape as
  `app13_ruby_FastApi` §5 (`frameworks`, `threats`, `cards`, `mitigations`, `code_samples`,
  `cross_references`, `content_hashes`, `users`, `threat_translations`), plus a
  `game_sessions` table that exists from Phase 1 onward but isn't written to until Phase 3.
- **Auth:** JWT HS256 (`lua-resty-jwt`), one hardcoded admin user, matching app01's contract
  exactly. No OAuth, no RS256.
- **SQL safety is runtime-only** (D-02), same tier as `app03_python_django`/
  `app09_php_WORDPRESS`/`app13_ruby_FastApi` — Lapis's parameterized query API is the actual
  guarantee, `luacheck` the closest static-analysis substitute.
- **`card_kind` has no compiler-enforced sum type** — Lua has neither algebraic data types nor
  interfaces at all, the weakest static-safety tier of any sibling (tied with Ruby/PHP on "no
  compile-time help," but without even their minimal structural typing). Enforced entirely by
  a Postgres `CHECK` constraint (D-03) — state this precisely, don't claim parity with
  Rust/Haskell/Swift/Kotlin/Scala's compiler-enforced sum types.
- **i18n:** a hand-written `i18n.lua` string table, loaded independently by both tiers (client
  Lua for UI strings, backend Lua for API error messages) — PL default, instant client-side
  switch, no scene reload. Every string SHALL exist in both languages (`requirements.md`
  NFR-06) — this is a hard requirement here, not just a stated goal, per the user's explicit
  bilingual instruction this app was commissioned under.
- **Code samples:** five languages, same set and order as `app09`/`app13`: Python, Java, Go,
  Scala, Lua — the Lua sample is the one case in this whole repo where the sample language and
  the backend's own implementation language are the same; `user_stories+tests.md` US-11 has a
  test specifically checking the sample isn't an accidental copy-paste of real route code.
- **Versions:** Lua 5.4 semantics targeted where possible, but MoonSharp only implements a
  5.2-superset — don't assume 5.4 stdlib additions work client-side. Unity 2022 LTS, MoonSharp
  2.0, OpenResty 1.25 (LuaJIT 2.1), Lapis, PostgreSQL 16.

## Where to look for more

`PLAN.md` is the primary source: §0 (why Lua on both tiers, what doesn't carry over), §0.1
(source-material provenance — `../docs/OWASP_stories/*.yaml` and the game-manual markdown),
architecture §3, decisions §4 (D-01–D-09, with D-07's MoonSharp sandbox the standout), schema
§5, phased build plan §6, API contract §7, frontend scenes §8, file layout §9, risk register
§13. `requirements.md` has the full FR/SR/NFR/DR list plus an abuse-case table (§4) unique in
this repo for including a Lua-code-execution abuse case. `user_stories+tests.md` has all 18
user stories with real Cornucopia card examples translated to Polish and their OWASP/MITRE
ATLAS coverage, plus the three game-mode user stories (US-15–17) and the MoonSharp
sandbox-escape test (US-14). `SDLC_analysis.md` covers the SSDLC/SDLC analysis, with a
dedicated section (§8) on why this project runs Scrum + Kanban (Scrumban) rather than
Waterfall or pure Scrum alone.
