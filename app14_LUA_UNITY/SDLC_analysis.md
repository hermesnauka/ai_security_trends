# LuaGuard 2026 — SSDLC / SDLC Analysis

**Version:** 1.0
**Date:** 2026-07-11
**Companion documents:** `PLAN.md`, `requirements.md`, `user_stories+tests.md`
**Methodology focus:** Agile Scrum with a security-gated Kanban board (this analysis centers
on Agile/Scrum/Kanban, not Waterfall)

This document walks `PLAN.md`/`requirements.md`'s content through both the general **SDLC**
(Planning, Design, Implementation, Testing, Deployment, Maintenance) and the
security-integrated **SSDLC** view of those same stages, then focuses in detail on how this
project is actually run day-to-day: **Agile/Scrum with a Kanban board**, not Waterfall. Every
phase below is stated concretely against this app's real design (Lua/OpenResty/Lapis/
PostgreSQL backend, Unity + MoonSharp/Lua frontend), not in the abstract.

---

## 1. Why SSDLC, Not "Security as a Final Checklist"

Security here is integrated into every phase below, not bolted on before release. Three
concrete examples this plan is built around:

- The MoonSharp sandbox boundary (D-07) is a **design-time** decision (§3 below), not a
  testing-time bug caught later — it makes an entire class of "a Lua gameplay script reads
  the filesystem or spawns a process" vulnerability structurally impossible before a single
  gameplay script is written, the earliest point in the pipeline it can be closed off.
- The `card_kind`/`severity` `CHECK` constraint (D-03) is a **design-time** decision at the
  database layer, identical in spirit to every sibling that has one — Lua contributes zero
  static-typing help here, so the guarantee has to live in Postgres from day one, not be
  retrofitted after a bug report.
- JWT secret handling (D-01, SR-02) is a **requirements-time** decision: "never committed,
  env-var only" is written into `requirements.md` before a single line of auth code exists.

---

## 2. Requirements & Threat Modeling

**General SDLC — Planning and Analysis:** goals (a bilingual OWASP/MITRE/CompTIA reference
app that also digitizes the real OWASP Cornucopia "Security Architects" card game), budget (a
course project — Phase-1 browsing parity now, the three game modes as a documented Phase 2+
addition, `requirements.md` §2), and requirements (`requirements.md` FR/SR/NFR/DR) are defined
before any backend or Unity code exists.

**SSDLC — Requirements & Threat Modeling:** `PLAN.md` §11's threat model summary and
`requirements.md` §4's abuse-case table are written during this phase, not after
implementation. Two things are identified here that no browsing-only sibling has to consider:

- **Embedding a general-purpose script interpreter is itself a new attack-surface category**
  (D-07) — this is identified and scoped out (SR-13: no user-supplied Lua content in Phase 1
  or 2) *before* any MoonSharp integration code is written, not discovered as a finding during
  a later pen-test.
- The **two-Lua-runtime split** (LuaJIT backend vs. MoonSharp client, `PLAN.md` §0) is
  flagged early as a maintenance/consistency risk, not just a security one — a bug fixed in
  one runtime's Lua stdlib quirk-handling does not automatically fix the other.

Compliance framing: this app's own subject matter (OWASP/MITRE/CompTIA) doubles as its
threat-modeling reference material — the same reflexive property every sibling since app09
shares, here made literal by also implementing the actual threat-modeling card game as
gameplay.

---

## 3. Secure Design

**General SDLC — Design:** system architecture (`PLAN.md` §3 — Unity/MoonSharp client →
OpenResty/Lapis → Postgres, no queue/cache layer) and the API contract (§7) are designed
before implementation begins.

**SSDLC — Secure Design, "least privilege" applied concretely:**

- **The MoonSharp sandbox is this project's flagship least-privilege example:** the client's
  `Script` instance is constructed with `CoreModules.Preset_SoftSandbox` minus `os`/`io` — Lua
  gameplay code is given the least capability that still lets it run card logic, reputation
  math, and UI string lookups, and nothing else (D-07, SR-10, SR-11). This is least privilege
  applied to a *script interpreter's own capability set*, a design axis none of the other
  twelve siblings' stacks have to reason about at all.
- The database role this app's backend connects as SHALL have privileges scoped only to the
  `luaguard` database/schema — no superuser, no cross-database access, matching the
  shared-Postgres-instance convention `../CLAUDE.md` documents.
- The one seeded admin account has exactly one role (`ADMIN`), no finer-grained permission
  model in Phase 1 — least privilege here means "the smallest role model that satisfies
  Phase-1 scope," not speculative unused roles.
- `game_sessions` (Phase 2+) are deliberately **not** linked to a `users` row (DR-04) — a
  design decision that least-privileges the gameplay feature away from the one credentialed
  account entirely, since gameplay never needs to touch anything an authenticated admin can.
- `card_kind`/`severity`'s `CHECK` constraint (D-03) gives the database the least freedom
  necessary to represent a valid row, rather than trusting application code alone to enforce
  it.

---

## 4. Development (Secure Coding Standards)

**General SDLC — Implementation:** the actual writing of `backend/app/routes/`,
`backend/app/models/`, `frontend/Assets/Scripts/` (C# glue), `frontend/Assets/StreamingAssets/
lua/` (gameplay logic).

**SSDLC — Secure coding standards preventing common pitfalls:**

- **Injection (SQL):** Lapis's parameterized `db.query` API only — `luacheck` and manual code
  review both exist specifically to catch a raw-string-concatenation regression (D-02, SR-01).
- **Injection (YAML/deserialization):** `CardDeckLoader`'s explicit allow-listed-keys check
  (D-06, SR-06) — `lyaml`/libyaml leniency is a known pitfall this coding standard exists to
  close, stated explicitly rather than assumed safe by default.
- **Injection (Lua code, this project's unique pitfall):** no route or gameplay script ever
  calls Lua's own `load`/`loadstring` on anything derived from user input, on either tier —
  this is a coding standard distinct from SQL/XSS injection, specific to embedding a script
  interpreter, and is called out by name in code review checklists (SR-04, SR-13).
- **Broken access control:** every route's required auth level is declared explicitly in its
  Lapis route block — no route relies on "probably fine because nothing links to it."
- **Secrets management:** `JWT_SECRET`/DB credentials are environment variables only,
  `.gitignore`d, never interpolated into a log line (SR-02, SR-03).

---

## 5. Security Testing — SAST and DAST in the Pipeline

**General SDLC — Testing:** `busted` unit + request specs (backend), `busted` run standalone
against `StreamingAssets/lua/*.lua` (frontend gameplay logic, no Unity needed), Unity
`EditMode`/`PlayMode` tests (C# glue + in-engine confirmation) — see `user_stories+tests.md`
for concrete examples per user story.

**SSDLC — continuous SAST/DAST:**

- **SAST:** `luacheck` (both Lua codebases — backend and the `StreamingAssets` scripts) runs
  on every CI push; a new globals-write or unused-variable warning fails the build (NFR-05).
- **The MoonSharp sandbox-escape test suite (US-14) is this project's SAST-adjacent but
  dynamic check** — it doesn't scan source text for a pattern, it actually executes
  adversarial Lua snippets (`io.open`, `os.execute`) against the real sandboxed `Script`
  instance and asserts they raise. This sits between classic SAST and DAST: it's a unit test,
  but it's testing a runtime security boundary the way a DAST tool probes a running system,
  not a static code-shape rule.
- **CI grep-check (SR-10):** `! grep -rn "CoreModules.Full" frontend/Assets/Scripts/` — a
  deliberately blunt, always-on backstop alongside the dynamic sandbox test, so a
  `CoreModules.Full` regression fails CI even if no test happens to exercise the specific API
  it would have exposed.
- **DAST-adjacent:** Unity `PlayMode` tests exercise real scenes against a real running
  backend the way a DAST tool would traverse an application, though this is not a dedicated
  DAST scanner (e.g. OWASP ZAP) — `PLAN.md` doesn't claim DAST coverage this project doesn't
  actually have; a genuine ZAP baseline scan against the docker-compose-launched backend is a
  documented, not-yet-implemented Phase-2 addition, matching every sibling's own honest
  "DAST scanning not yet wired up" scope statement.

---

## 6. Deployment & Monitoring

**General SDLC — Deployment:** `docker-compose up --build` (backend + Postgres, dev/CI) or the
staged CI/CD pipeline (`PLAN.md` §12) for anything closer to production: `busted` →
`luacheck` → the sandbox-escape suite → Unity `EditMode`/`PlayMode` (via `game-ci/
unity-test-runner`) → manual approval gate → staging → production. The Unity WebGL/desktop
builds themselves are a separate, manual release step, not a CI gate (`PLAN.md` §12).

**SSDLC — securing infrastructure configuration + runtime monitoring:**

- Nginx (in the docker-compose topology) proxies `/api/*` to OpenResty and serves the WebGL
  build's static files — no directory listing, no backend port exposed directly.
- OpenResty's worker process count and shared-dict sizes (used by SR-05's rate limiter) are
  configured explicitly, not left at library defaults, to bound resource consumption per
  container.
- **Monitoring** in Phase-1 scope is basic (`GET /health`, matching the shared contract) — a
  full metrics/log-aggregation stack is documented as aspirational, not falsely claimed as
  built.

---

## 7. Maintenance

Ongoing: dependency updates (reviewing `luarocks` package pins and the Unity package manifest
for new CVEs), adding curated cards/mitigations to existing decks without a schema migration
(the data model already supports partial-deck curation, per `PLAN.md` §0.1's "representative
sample" scope), Cornucopia deck version bumps, and — unique to this sibling — periodic review
of whether the "no user-supplied Lua content" boundary (SR-13) still holds as new features are
proposed; any feature request that would cross it requires a dedicated threat-model review
before acceptance, not a routine PR approval.

---

## 8. Process: Agile, Scrum, and Kanban — How This Project Is Actually Run

The six-phase SDLC breakdown above describes *what* happens; it does not imply this project
runs Waterfall (a single linear pass through each phase once). In practice:

### 8.1 Why Agile, not Waterfall

A single-team, course-timeline project with evolving scope (Phase-1 browsing parity now, the
three game modes as a documented Phase 2+ addition, `requirements.md` §2) is exactly the
situation Waterfall handles poorly: Waterfall assumes requirements are fully known and stable
before design begins, which is false here — the Cornucopia deck content itself was still being
curated while early API endpoints were already being built, and the game-mode rules (§0.1's
source manual) were being read and translated concurrently with backend schema design. Agile's
iterative delivery lets "Foundation + Browsing Parity" (Phase 1, `PLAN.md` §6) ship and get
used before "The Game Itself" (Phase 3) is even fully designed.

### 8.2 Scrum structure applied to this project

- **Sprints:** each of `PLAN.md` §6's four phases (Foundation + Browsing Parity, Cards/
  Mitigations/Code Samples, The Game Itself, Search/Export/Matrix + Hardening) is sized to
  fit roughly one to two sprints — a natural, pre-existing decomposition into sprint-sized
  increments.
- **Product Backlog:** the 18 user stories in `user_stories+tests.md`, each already broken
  into acceptance criteria and a concrete TDD test sketch — directly liftable into backlog
  items with a Definition of Ready (a `busted`/Unity test sketch exists) built in from the
  start.
- **Sprint Planning:** at the start of each phase, the relevant FR/SR/NFR/DR IDs
  (`requirements.md`) and user stories (`user_stories+tests.md`) for that phase are pulled
  into the sprint backlog — e.g. Phase 3's sprint pulls in FR-12 through FR-14 and US-15
  through US-17 together, since they share the same `game_sessions` schema dependency.
- **Daily Stand-up:** blockers specific to this stack surface quickly here — e.g. "the Unity
  Editor license activation secret expired in CI, `game-ci/unity-test-runner` is failing" is a
  concrete, nameable blocker this stack's tooling produces, the same class of dependency
  `app11_swift_ios`'s macOS-only runner and `app12_kotlin_android`'s Gradle/Android-SDK runner
  represent for their own stacks.
- **Sprint Review:** each phase ends with a demo against the actual running stack — "does
  `POST /api/v1/game/sessions` with `mode=regular` correctly cost exactly 1 reputation point
  when an attack matches an open STRIDE vulnerability" (US-15) is a literal, testable demo
  criterion, not a vague "looks done" judgment call.
- **Sprint Retrospective:** this directory's own history is a real, not hypothetical,
  retrospective example — `CLAUDE.md`/`PLAN.md`/`requirements.md`/`SDLC_analysis.md`/
  `user_stories+tests.md` were, until 2026-07-11, an accidental duplicate of
  `app12_kotlin_android`'s KotlinGuard content, caught and corrected in this rewrite — exactly
  the kind of process failure a retrospective exists to catch and prevent recurring.

### 8.3 Kanban board applied to this project

Alongside Scrum's sprint cadence, day-to-day flow is tracked on a Kanban board with these
columns, mapped directly to this project's real states:

```
Backlog → Ready (test sketch exists) → In Progress → Code Review (luacheck + sandbox-escape suite pass)
       → QA (busted/Unity tests green) → Done (merged, deployed to staging)
```

- **WIP limits** matter specifically for the "The Game Itself" phase (Phase 3): implementing
  three distinct game modes (Regular, Shift Left, Workshop) that share a card-resolution
  engine invites too many modes being "in progress" simultaneously with none finished — a WIP
  limit of 1 mode-in-development at a time keeps focus and surfaces `card_engine.lua` API
  design mismatches sooner, against one consumer at a time instead of three.
- **Blocked items** are visibly tagged — e.g., a Unity `PlayMode` test blocked on a
  Unity-Editor CI license issue is visible on the board as blocked, not silently absent from a
  sprint burndown, distinct from a genuine code defect.
- A hybrid **Scrumban** approach (sprint cadence for the four architectural phases, continuous
  Kanban flow for ongoing content curation, dependency/CVE triage, and — specific to this
  project — any proposed feature that touches the "no user-supplied Lua" boundary, which gets
  its own always-visible Kanban swimlane requiring a threat-model-review checkbox before it can
  move to "In Progress") is what this project actually uses in practice.

### 8.4 Why this combination, not one or the other alone

Pure Scrum's fixed sprint boundary is a poor fit for "triage a newly discovered `luarocks`
package CVE" — that class of work needs to start the moment it's discovered, not wait for the
next sprint planning session. Pure Kanban has no natural forcing function for the "demo the
running stack to stakeholders" checkpoint Scrum's Sprint Review provides — important here
specifically because Phase 3's game modes are much easier to demo live than to describe.
Running both — Scrum for the four-phase architectural roadmap, Kanban for the continuous flow
of content curation, bug fixes, dependency triage, and sandbox-boundary review — is the
practical answer this project uses, not a theoretical ideal quoted from a textbook.
