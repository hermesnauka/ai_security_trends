# LuaGuard 2026 — Requirements Specification

**Version:** 1.0
**Date:** 2026-07-11
**Companion document:** `PLAN.md`

---

## 1. Functional Requirements

| ID | Requirement |
|---|---|
| FR-01 | The app SHALL display a home screen (Unity `FrameworksScene`) listing all security frameworks in scope (OWASP Web/LLM Top 10, MITRE ATLAS, CompTIA Security+/SecAI+, STRIDE). |
| FR-02 | The app SHALL allow filtering the threat list by framework, severity, STRIDE category, tag, and free-text query, via `GET /api/v1/threats` query parameters. |
| FR-03 | The app SHALL display, for each threat, a detail view (`ThreatDetailScene`) with sections: Overview, Attack Vectors, Attack Surface, Mitigations, Code Samples, Cross-References. |
| FR-04 | The app SHALL present the OWASP Cornucopia Companion deck's LLM suit content with real OWASP LLM Top 10 (LLM01–LLM10) mappings, sourced from `../docs/OWASP_stories/__LLM_AI___companion-cards-1.0-en.yaml`. |
| FR-05 | The app SHALL present the STRIDE/Elevation-of-Privilege deck (`../docs/OWASP_stories/STRIDE__eop-cards-5.0-en.yaml`) with an interactive STRIDE coverage heatmap. |
| FR-06 | The app SHALL present the Digital-by-Default Harms deck (`../docs/OWASP_stories/dbd-cards-1.0-en.yaml`) as design-harm cards that structurally never display a severity badge (D-03). |
| FR-07 | The app SHALL present the Website App deck (`../docs/OWASP_stories/webapp-cards-3.0-en.yaml`), the Mobile App deck (`mobileapp-cards-1.1-en.yaml`), and the ML-Security deck (`RISKS__elevation-of-mlsec-cards-1.0-en.yaml`). |
| FR-08 | The app SHALL provide at least one real, complete mitigation code sample (attack-demo + defense pair) in each of Python, Java, Go, Scala, and Lua, for at least one seeded mitigation. |
| FR-09 | The app SHALL provide global free-text search across threats and cards (`GET /api/v1/search?q=`). |
| FR-10 | The app SHALL provide a Polish/English language toggle in the Unity settings/login screen, switching all UI strings and threat/card content instantly, with no scene reload, defaulting to Polish (D-05). Every user-facing string in this app SHALL exist in both languages — there is no string shown only in one locale. |
| FR-11 | The app SHALL require a valid JWT bearer token for the one write-capable Phase-1 route (login itself is the exception); every read (`GET`) route is public, matching `app01_react`'s actual contract (D-01). |
| FR-12 | *(Phase 2+)* The app SHALL let a player start a Regular-mode game session (`POST /api/v1/game/sessions`), draw and resolve Protection/Attack/Event cards per turn, and track a reputation meter from 10 down to 0 across 6 turns, per the rules in `../docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`. |
| FR-13 | *(Phase 2+)* The app SHALL let a player start a Shift Left-mode session with separate Development/Production zones, where components in Development cannot be attacked until moved to Production at the start of the next turn. |
| FR-14 | *(Phase 2+)* The app SHALL support a Threat Modeling Workshop mode: Attack and Protection cards dealt to players, scored by proposing/countering a threat against a real system diagram — no `Component` cards used. |
| FR-15 | The app SHALL display cross-framework mappings (e.g., an LLM Cornucopia card ↔ its OWASP LLM Top 10 ID ↔ its MITRE ATLAS technique ID, per `../docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`'s own OWASP-to-ATLAS mapping table) in a dedicated Matrix view. |

## 2. Aspirational Scope (documented for completeness, not Phase 1)

Matching every sibling's own aspirational-vs-actual split (`../CLAUDE.md` "Scope: every app
is Phase-1 parity, not the full vision"): the full three-game-mode implementation (FR-12–14)
is explicitly Phase 2+, not Phase 1 — Phase 1 ships only the browsing/login half (FR-01–11,
FR-15). Also aspirational: async export-job polling, admin CRUD screens, JWT roles beyond
`ADMIN`, a community/custom-card-deck loading feature (explicitly rejected — see SR-13 and
`PLAN.md` D-07), and full i18n/curation coverage for every Cornucopia card (Phase 1 ships a
representative sample per deck, not every card — the same content-scope gap every sibling
since app09 states).

## 3. Security Requirements

| ID | Requirement |
|---|---|
| SR-01 | Every SQL query SHALL use Lapis's parameterized query API (`db.query`, `?` placeholders) — no string concatenation of user input into a raw SQL string anywhere in the codebase (D-02). |
| SR-02 | JWT tokens SHALL use HS256 (`lua-resty-jwt`) with a secret sourced only from an environment variable, never committed to version control. |
| SR-03 | The one seeded admin password SHALL be stored as a bcrypt hash (`lua-bcrypt`), never in plaintext, and never logged. |
| SR-04 | Every route accepting user input SHALL validate that input explicitly before use — no route reads a query/body parameter and passes it directly to `db.query`, a filesystem path, or a Lua `load`/`loadstring` call. |
| SR-05 | `POST /api/v1/auth/login` SHALL be rate-limited per source IP (a Lua/OpenResty `lua-resty-limit-req` shared-dict limiter) to mitigate credential brute-forcing. |
| SR-06 | Every raw Cornucopia YAML file SHALL be decoded through an explicit allow-listed-keys check (D-06) — an unrecognized key SHALL abort ingestion of that file with a clear error, not silently ignore the extra field. |
| SR-07 | Every curated `owasp_refs`/`mitre_refs` value SHALL be validated against a bundled allowlist file before being written to the database — an unknown reference SHALL abort ingestion, not silently pass through. |
| SR-08 | A `card_kind = 'design_harm'` row's `severity` column SHALL be enforced `NULL` by a database `CHECK` constraint (D-03) — not merely an application-level convention. |
| SR-09 | Every attack-demo code sample SHALL require an explicit user confirmation (a Unity UI Toolkit modal, D-09) before its source is rendered — never displayed by default. |
| SR-10 | The MoonSharp `Script` instance on the client SHALL be constructed with an explicit module whitelist (`CoreModules.Preset_SoftSandbox` minus `os`/`io`) — `CoreModules.Full` SHALL never be used anywhere in the codebase (D-07). This SHALL be enforced by a CI grep-check, not only code review. |
| SR-11 | No C# `UserData`-registered live object SHALL ever be exposed to a Lua script — every C#↔Lua boundary call SHALL pass only plain data (tables, strings, numbers, booleans) (D-07). |
| SR-12 | Dependency vulnerabilities SHALL be checked in CI: `luarocks` package pins reviewed against known-CVE Lua packages for the backend; Unity package manifest reviewed for the frontend. |
| SR-13 | The app SHALL NOT implement any feature that loads a Lua script from a source other than this repository's own `backend/app/` or `frontend/Assets/StreamingAssets/lua/` directories in Phase 1 or Phase 2 — no user-supplied "custom card deck" scripting endpoint, no server-side `eval`-style route. Any future work in this direction requires a dedicated threat-model review first (see `PLAN.md` §11). |
| SR-14 | Every list/filter endpoint SHALL respond within 200ms (p95) against the seeded dataset — validated by a `busted` request-spec assertion, not just an aspiration. |

## 4. Abuse-Case Table

| Abuse Case | STRIDE Category | Mitigation |
|---|---|---|
| Attacker forges a JWT to reach a write route without valid credentials | Spoofing | HS256 signature verification server-side on every request (D-01); `JWT_SECRET` never committed |
| Attacker submits a crafted `threats` filter query attempting SQL injection | Tampering | SR-01, Lapis parameterized queries only |
| Attacker brute-forces the admin login | Elevation of Privilege | SR-05, per-IP rate limiting |
| A future "custom card deck" upload is used to smuggle a malicious Lua payload into either Lua runtime | Tampering / Elevation of Privilege | SR-13 (feature explicitly not built), D-07 sandbox as defense-in-depth if this ever changes |
| A malicious/corrupted Cornucopia YAML deck is deployed, containing an unrecognized field silently accepted | Tampering | SR-06, allow-listed-keys ingestion check |
| A curated card references a non-existent OWASP/MITRE ID, misleading a player about a real-world mapping | Repudiation (of the mapping's accuracy) | SR-07, reference allowlist validation at ingestion |
| Player's stored JWT is read from `PlayerPrefs` by another process on a shared machine | Information Disclosure | D-08 stated caveat; Phase-1 accepted risk, not solved by encryption (course-scope limitation, documented not hidden) |
| Attacker sends an oversized/recursive game-session turn payload to exhaust backend resources | Denial of Service | Request body size limits at the OpenResty `nginx.conf` level; `game_sessions` writes are Phase 2+, not yet built |
| A player views an attack-demo code sample and copy-pastes it into production code without reading the warning | Tampering (of the player's own codebase, not this app) | SR-09, explicit confirmation modal with warning text in both languages |

## 5. Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-01 | The backend SHALL run on OpenResty (LuaJIT 2.1) with Lapis, targeting the `openresty/openresty:1.25.3-alpine` image. |
| NFR-02 | The frontend SHALL run on Unity 2022 LTS, targeting both a desktop standalone build and a WebGL build from the same C#/Lua source. |
| NFR-03 | The full stack (backend + Postgres) SHALL be runnable via `docker-compose up --build` with no manual configuration beyond environment variables; the Unity client connects to it as an external HTTP client, not itself containerized. |
| NFR-04 | The backend SHALL also be runnable via the shared local-dev scripts (`../CLAUDE.md`) against the shared, Docker-less local Postgres instance. |
| NFR-05 | The backend codebase SHALL pass `luacheck` with no globals-write warning left unexplained. |
| NFR-06 | Every UI string in both C# (Unity UI Toolkit static labels) and Lua (`i18n.lua` table) SHALL exist in both `pl` and `en` — a missing-translation check SHALL run in CI (a Lua script that diffs the two locale tables' key sets). |

## 6. Data Requirements

| ID | Requirement |
|---|---|
| DR-01.1 | Frameworks SHALL include, at minimum: OWASP_WEB, OWASP_LLM, MITRE_ATLAS, COMPTIA_SECAI, STRIDE (matching the real seeded set every recent sibling uses). |
| DR-01.2 | Threats SHALL include the OWASP Web Top 10 (2021) and OWASP LLM Top 10 (2025), in full — 20 threats total, matching every sibling's Phase-1 content scope. |
| DR-01.3 | MITRE ATLAS reference values SHALL be drawn from a minimum technique set including `AML.T0051` (LLM prompt injection's real ATLAS mapping) and `AML.T0024` (model extraction), both cited in `../docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`. |
| DR-02 | Mitigations SHALL number exactly 5 in Phase 1/2, each with code samples in all 5 languages (Python/Java/Go/Scala/Lua), both an attack-demo and a defense sample per language (50 samples total) — content reused verbatim from `app09_php_WORDPRESS`/`app11_swift_ios`/`app12_kotlin_android`/`app13_ruby_FastApi`. |
| DR-03 | Cornucopia card curation SHALL cover a representative sample per deck, not every card — matching every sibling's stated content-scope gap. |
| DR-04 | `game_sessions` rows (Phase 2+ only) SHALL NOT be linked to a `users` row — sessions are anonymous, identified only by an opaque per-device token, since gameplay is not an authenticated feature in this app's scope. |

---

**Traceability:** every FR/SR/NFR/DR above maps to at least one acceptance criterion in
`user_stories+tests.md`; every ID prefix (FR/SR/NFR/DR) matches the convention every sibling's
own `requirements.md` uses, for cross-app comparability.
