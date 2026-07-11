# RubyGuard 2026 — SSDLC / SDLC Analysis

**Version:** 1.0
**Date:** 2026-07-11
**Companion documents:** `PLAN.md`, `requirements.md`, `user_stories+tests.md`

This document walks `PLAN.md`/`requirements.md`'s content through both the general
**SDLC** (Planning, Design, Implementation, Testing, Deployment, Maintenance) and the
security-integrated **SSDLC** view of those same stages, then focuses in detail on how
this project is actually run day-to-day: **Agile/Scrum with a Kanban board**, not
Waterfall. Every phase below is stated concretely against this app's real design (Ruby/
Grape/Sequel/PostgreSQL backend, framework-free JS frontend), not in the abstract.

---

## 1. Why SSDLC, Not "Security as a Final Checklist"

Security here is integrated into every phase below, not bolted on before release. Three
concrete examples this plan is built around:

- The `card_kind`/`severity` `CHECK` constraint (D-03) is a **design-time** decision (§3
  below), not a testing-time bug caught later — it makes an entire class of "design-harm
  card wrongly shows a severity" bug structurally impossible at the database level, the
  earliest point in the pipeline it can be enforced.
- JWT secret handling (D-01, SR-02) is a **requirements-time** decision: "never committed,
  env-var only" is written into `requirements.md` before a single line of auth code exists,
  not discovered as a finding during a later security review.
- SQL injection prevention (D-04, SR-01) is a **coding-standard** decision enforced by
  Brakeman in CI (§4 below) on every single commit, not a manual code-review checklist
  item applied inconsistently.

---

## 2. Requirements & Threat Modeling

**General SDLC — Planning and Analysis:** goals (bilingual OWASP/MITRE/CompTIA reference
app), budget (a course project — Phase-1 parity, not the full 19-user-story vision,
`requirements.md` §2), and requirements (`requirements.md` FR/SR/NFR/DR) are defined before
any backend code exists.

**SSDLC — Requirements & Threat Modeling:** `PLAN.md` §11's threat model summary is written
during this phase, not after implementation: public read-heavy API + one authenticated
write surface (login), SQL injection (D-04), brute-force login (D-01/SR-05), JWT secret
leakage (SR-02), dependency vulnerabilities (SR-10) are all identified here, before design.
Compliance framing: this app's own subject matter (OWASP/MITRE/CompTIA) doubles as its
threat-modeling reference material — a genuinely unusual, reflexive property this course
series' apps share (the security-education content and the security-engineering practice
applied to build it reinforce each other).

---

## 3. Secure Design

**General SDLC — Design:** system architecture (`PLAN.md` §3 — Nginx → Puma → Grape →
Sequel → Postgres, no queue/cache layer, justified by data volume) and the frontend/backend
API contract (§7) are designed before implementation begins.

**SSDLC — Secure Design, "least privilege" applied concretely:**
- The database role this app's backend connects as SHALL have privileges scoped only to
  the `rubyguard` database/schema — no superuser, no cross-database access, matching the
  shared-Postgres-instance convention `../CLAUDE.md` documents (every sibling owns only
  its own role/DB on that shared instance).
- The one seeded admin account has exactly one role (`ADMIN`) with no finer-grained
  permission model in Phase-1 — least privilege here means "the smallest role model that
  satisfies Phase-1 scope," not "build unused fine-grained roles speculatively."
- `card_kind`/`severity`'s `CHECK` constraint (D-03) is itself a least-privilege-adjacent
  design principle applied to data integrity: the database is given the least freedom
  necessary to represent a valid row, not trusted to be told the truth by application code
  alone.
- No CSRF token scheme (D-07) is a *design* decision made because the JWT-bearer,
  no-cookie-session architecture removes the attack surface CSRF protections exist to
  close — a case of designing the surface away rather than adding a mitigation on top of it.

---

## 4. Development (Secure Coding Standards)

**General SDLC — Implementation:** the actual writing of `backend/app/api/`,
`backend/app/models/`, `frontend/src/views/`, etc.

**SSDLC — Secure coding standards preventing common pitfalls:**
- **Injection (SQL):** Sequel's parameterized dataset API only — RuboCop code review and
  Brakeman CI scanning both exist specifically to catch a raw-string-interpolation regression
  (D-04, SR-01).
- **Injection (YAML/deserialization):** `CardFileLoader`'s explicit allow-listed-keys check
  (D-06, SR-06) — Ruby's `Psych`/`JSON.parse` leniency is a known pitfall this coding
  standard exists to close, stated explicitly rather than assumed safe by default.
- **Broken access control:** every route's required auth level is declared explicitly in
  its Grape class (`app01_react`'s own JWT-filter-chain equivalent) — no route relies on
  "probably fine because nothing links to it."
- **Secrets management:** `JWT_SECRET`/DB credentials are environment variables only,
  `.gitignore`d, never interpolated into a log line (SR-02, SR-03).

---

## 5. Security Testing — SAST and DAST in the Pipeline

**General SDLC — Testing:** RSpec unit + request specs, `rantly` property tests, Playwright
E2E — see `user_stories+tests.md` for the concrete TDD examples per user story.

**SSDLC — continuous SAST/DAST:**
- **SAST:** Brakeman (Ruby/Rack-aware — SQL injection, mass assignment, command injection,
  unsafe redirect checks) and `bundler-audit` (dependency CVE checks against the Ruby
  Advisory Database) both run on every CI push, not periodically — a finding fails the
  build (SR-10, SR-11), the same "fail the build, don't just report" posture every
  sibling's CI pipeline takes.
- **DAST-adjacent:** Playwright's E2E suite exercises the running application over real
  HTTP the way a DAST tool would traverse it, though it is not a dedicated DAST scanner
  (e.g. OWASP ZAP) — `PLAN.md` doesn't claim DAST coverage this project doesn't actually
  have; a genuine ZAP baseline scan against the docker-compose-launched stack is a
  documented, not-yet-implemented Phase-2 addition (mirrors every sibling's own honest
  "DAST scanning not yet wired up" scope statement where applicable).
- **Property-based testing** (`rantly`) exists specifically to probe cases a fixed set of
  example-based unit tests would miss — e.g., the "every mitigation has all 5 languages"
  property (§10 `PLAN.md`) checks the actual seeded dataset's shape rather than one
  hand-picked example.

---

## 6. Deployment & Monitoring

**General SDLC — Deployment:** `docker-compose up --build` (dev/CI) or the staged CI/CD
pipeline (`PLAN.md` §12) for anything closer to production: RSpec → Brakeman →
`bundler-audit` → RuboCop → Playwright → build frontend → manual approval gate → staging →
production.

**SSDLC — securing infrastructure configuration + runtime monitoring:**
- Nginx is configured to serve only the built `frontend/dist/` static assets and proxy
  `/api/*` — no directory listing, no exposed backend port directly to the internet in the
  containerized topology.
- Puma's worker/thread counts are configured explicitly (not left at library defaults) to
  bound resource consumption per container.
- **Monitoring** in Phase-1 scope is basic (`GET /health`, matching the shared contract) —
  a full metrics/log-aggregation stack (Grafana/Loki/Prometheus, as some siblings run) is
  documented as aspirational, not falsely claimed as built.

---

## 7. Maintenance

Ongoing: dependency updates (`bundler-audit` catching new CVEs in already-deployed gem
versions), adding curated cards/mitigations to existing decks without needing a schema
migration (the data model already supports partial-deck curation, per `PLAN.md` §0.1's
"representative sample" scope), and Cornucopia deck version bumps (a new
`webapp-cards-3.1-en.yaml` would need `DeckManifestEntry`-equivalent config update plus
re-running the ingestion pipeline — an intentionally low-ceremony operation).

---

## 8. Process: Agile, Scrum, and Kanban — How This Project Is Actually Run

The six-phase SDLC breakdown above describes *what* happens; it does not imply this project
runs Waterfall (a single linear pass through each phase once). In practice:

### 8.1 Why Agile, not Waterfall
A single-team, course-timeline project with evolving scope (Phase-1 parity now, a
documented 19-user-story aspirational vision later, `requirements.md` §2) is exactly the
situation Waterfall handles poorly: Waterfall assumes requirements are fully known and
stable before design begins, which is false here — the Cornucopia deck content itself was
still being curated (severity/refs) while early API endpoints were already being built.
Agile's iterative delivery lets "Foundation" (Phase 1, `PLAN.md` §6) ship and get used
before "Card ingestion" (Phase 2) is even fully designed.

### 8.2 Scrum structure applied to this project
- **Sprints:** each of `PLAN.md` §6's six phases (Foundation, Card ingestion, Mitigations +
  code samples, i18n, Search/export/matrix, Hardening/testing) is sized to fit roughly one
  sprint — a natural, pre-existing decomposition into sprint-sized increments, not an
  afterthought applied to a plan written without sprints in mind.
- **Product Backlog:** the 19 user stories in `user_stories+tests.md`, each already broken
  into acceptance criteria and a concrete TDD test — directly liftable into backlog items
  with a Definition of Ready (an RSpec/Playwright test sketch exists) built in from the
  start.
- **Sprint Planning:** at the start of each phase, the relevant FR/SR/NFR/DR IDs
  (`requirements.md`) and user stories (`user_stories+tests.md`) for that phase are pulled
  into the sprint backlog — e.g. Phase 2's sprint pulls in FR-05 through FR-12 and US-05
  through US-12 together, since they share the same card-ingestion dependency.
- **Daily Stand-up:** blockers specific to this stack surface quickly here — e.g. "the
  `bundler-audit` CI step is failing on a transitive dependency" is a concrete, nameable
  blocker this stack's tooling produces, not a generic placeholder.
- **Sprint Review:** each phase ends with a demo against the ACTUAL running
  `docker-compose` stack — "does `GET /api/v1/matrix/llm` return LLM2 mapped to
  LLM10:2025" is a literal, testable demo criterion pulled straight from US-04/US-06's
  acceptance criteria, not a vague "looks done" judgment call.
- **Sprint Retrospective:** the "Correction note" at the top of `PLAN.md` (this directory's
  planning docs were an accidental duplicate of `app12_kotlin_android`'s content) is exactly
  the kind of process failure a retrospective exists to catch and prevent recurring —
  documented here as a real example, not a hypothetical one.

### 8.3 Kanban board applied to this project
Alongside Scrum's sprint cadence, day-to-day flow is tracked on a Kanban board with these
columns, mapped directly to this project's real states:

```
Backlog → Ready (test sketch exists) → In Progress → Code Review (Brakeman/RuboCop pass)
       → QA (RSpec/Playwright green) → Done (merged, deployed to staging)
```

- **WIP limits** matter specifically for the "Card ingestion" phase (Phase 2): curating
  severity/refs for even a representative sample across six decks is exactly the kind of
  work that invites too many decks being "in progress" simultaneously with none finished —
  a WIP limit of 2 concurrent decks-in-curation keeps focus and surfaces the
  `ReferenceValidator` allowlist-mismatch class of bug (D-06/SR-07) sooner, against fewer
  decks at once.
- **Blocked items** are visibly tagged — e.g., a `code_samples` row blocked on a
  not-yet-authored Scala sample is visible on the board as blocked, not silently absent
  from a sprint burndown.
- Kanban's continuous-flow model complements Scrum's sprint boundaries well for this
  project specifically because content curation (which decks/cards get curated when) does
  not naturally chunk into fixed-length sprints the way the six architectural phases do —
  a hybrid **Scrumban** approach (sprint cadence for architecture/features, continuous
  Kanban flow for ongoing content curation and dependency/CVE triage) is what this project
  actually uses in practice.

### 8.4 Why this combination, not one or the other alone
Pure Scrum's fixed sprint boundary is a poor fit for "triage a new CVE `bundler-audit`
just flagged" — that class of work needs to start the moment it's discovered, not wait for
the next sprint planning session. Pure Kanban has no natural forcing function for the
"demo the running stack to stakeholders" checkpoint Scrum's Sprint Review provides. Running
both — Scrum for the six-phase architectural roadmap, Kanban for the continuous
flow of content curation, bug fixes, and dependency triage within and across those phases
— is the practical answer this project uses, not a theoretical ideal quoted from a textbook.
