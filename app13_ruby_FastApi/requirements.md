# RubyGuard 2026 — Requirements Specification

**Version:** 1.0
**Date:** 2026-07-11
**Companion document:** `PLAN.md`

---

## 1. Functional Requirements

| ID | Requirement |
|---|---|
| FR-01 | The app SHALL display a home screen listing all security frameworks in scope (OWASP Web/LLM/Agentic/API/Client-Side/CI-CD Top 10, OAT, MITRE ATLAS, CompTIA Security+/SecAI+). |
| FR-02 | The app SHALL allow filtering the threat list by framework, severity, STRIDE category, tag, and free-text query, via `GET /api/v1/threats` query parameters. |
| FR-03 | The app SHALL display, for each threat, a detail view with sections: Overview, Attack Vectors, Mitigations, Code Samples, Cross-References. |
| FR-04 | The app SHALL display cross-framework mappings (e.g., LLM01:2025 ↔ MITRE ATLAS AML.T0051) in a dedicated Matrix view. |
| FR-05 | The app SHALL present the OWASP Cornucopia Companion deck's FRE suit (client-side threats) with Polish and English descriptions. |
| FR-06 | The app SHALL present the OWASP Cornucopia Companion deck's LLM suit with an interactive LLM-vs-OWASP-LLM-Top-10 matrix. |
| FR-07 | The app SHALL present the AAI (Agentic AI) and CLD (Cloud) suits from the Companion deck. |
| FR-08 | The app SHALL present the STRIDE/Elevation-of-Privilege deck (SP/TA/RE/ID/DS/EP) with an interactive coverage heatmap. |
| FR-09 | The app SHALL present the "Elevation of MLSec" deck (EMR/EIR/EOR/EDR — ML-specific risks). |
| FR-10 | The app SHALL present the Mobile App deck (PC/AA/NS/RS/CRM/CM), dual-billed as both browsable content and this app's own threat-model source (§11). |
| FR-11 | The app SHALL present the DevOps + Cloud suits (DVO/CLD/BOT) from the Companion deck. |
| FR-12 | The app SHALL present the Website App deck (VE/AT/SM/AZ/CR/C). |
| FR-13 | The app SHALL provide at least one real, complete Python mitigation code sample (attack-demo + defense) for at least one seeded mitigation. |
| FR-14 | The app SHALL provide at least one real, complete Java mitigation code sample (attack-demo + defense) for at least one seeded mitigation. |
| FR-15 | The app SHALL provide at least one real, complete Scala mitigation code sample (attack-demo + defense), specifically demonstrating a supply-chain-class threat. |
| FR-16 | The app SHALL provide at least one real, complete Lua mitigation code sample (attack-demo + defense), specifically demonstrating rate-limiting / LLM-DoS mitigation. |
| FR-17 | The app SHALL provide global free-text search across threats and cards (`GET /api/v1/search?q=`). |
| FR-18 | The app SHALL provide bilingual (Polish/English) UI strings and threat/card content, switchable instantly client-side with no page reload, defaulting to Polish. |
| FR-19 | The app SHALL present the Digital-by-Default Harms deck (SCO/ARC/AGE/TRU/POR/COR/WC) as design-harm cards that structurally never display a severity badge (D-03). |
| FR-20 | The app SHALL provide synchronous CSV export of the currently filtered threat list (`GET /api/v1/export.csv`). |
| FR-21 | The app SHALL require a valid JWT bearer token for the one write-capable route (login itself is the exception); every read (`GET`) route is public, matching `app01_react`'s actual contract. |

## 2. Aspirational Scope (documented for completeness, not Phase-1)

The following describe the full 19-user-story end-state this course series' planning docs
traditionally document, matching every sibling's own aspirational-vs-actual split
(`../CLAUDE.md` "Scope: every app is Phase-1 parity, not the full vision"): async export
job polling, admin CRUD screens for content management, JWT roles beyond `ADMIN`, a
cross-framework matrix beyond LLM/STRIDE, and i18n coverage for every Cornucopia deck's
curated card (Phase-1 ships a representative sample per deck, not every card).

## 3. Security Requirements

| ID | Requirement |
|---|---|
| SR-01 | Every SQL query SHALL use Sequel's parameterized dataset API — no string interpolation of user input into a raw SQL string anywhere in the codebase (D-04). |
| SR-02 | JWT tokens SHALL use HS256 with a secret sourced only from an environment variable, never committed to version control. |
| SR-03 | The one seeded admin password SHALL be stored as a bcrypt hash, never in plaintext, and never logged. |
| SR-04 | Every Grape endpoint accepting user input SHALL validate that input via a `params` block (D-02) — no endpoint reads `params[:x]` outside a declared, typed, validated parameter. |
| SR-05 | `POST /api/v1/auth/login` SHALL be rate-limited per source IP via `rack-attack` to mitigate credential brute-forcing. |
| SR-06 | Every raw Cornucopia YAML/curation JSON file SHALL be decoded through an explicit allow-listed-keys check (D-06) — an unrecognized key SHALL abort ingestion of that file with a clear error, not silently ignore the extra field. |
| SR-07 | Every curated `owasp_refs`/`mitre_refs` value SHALL be validated against a bundled allowlist file before being written to the database — an unknown reference SHALL abort ingestion, not silently pass through. |
| SR-08 | Every list/filter endpoint SHALL respond within 200ms (p95) against the seeded dataset — validated by an RSpec request-spec assertion, not just an aspiration. |
| SR-09 | A `card_kind = 'design_harm'` row's `severity` column SHALL be enforced `NULL` by a database `CHECK` constraint (D-03) — not merely an application-level convention that could be silently violated by a future direct-SQL mistake. |
| SR-10 | Dependency vulnerabilities SHALL be checked in CI via `bundler-audit` against the Ruby Advisory Database; a build with a known-vulnerable gem version SHALL fail CI. |
| SR-11 | Static analysis SHALL run in CI via Brakeman; a new SQL-injection, mass-assignment, or command-injection finding SHALL fail CI. |
| SR-12 | Every attack-demo code sample SHALL require an explicit user confirmation (reveal gate, D-09) before its source is rendered in the frontend — never displayed by default. |

## 4. Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-01 | The backend SHALL run on Ruby 3.4, targeting Puma 6.x on Rack. |
| NFR-02 | The frontend SHALL run in any evergreen browser without a framework runtime dependency, using only ES2022-supported JavaScript. |
| NFR-03 | The full stack SHALL be runnable via `docker-compose up --build` with no manual configuration beyond environment variables. |
| NFR-04 | The full stack SHALL also be runnable via the shared local-dev scripts (`../CLAUDE.md`) against the shared, Docker-less local Postgres instance. |
| NFR-05 | The codebase SHALL pass RuboCop with no disabled-by-default cop re-enabled and no inline `# rubocop:disable` comment left unexplained. |

## 5. Data Requirements

| ID | Requirement |
|---|---|
| DR-01.1 | Frameworks SHALL include, at minimum: OWASP_WEB, OWASP_LLM, OWASP_AGENTIC, OWASP_API, OWASP_CLIENT_SIDE, OWASP_CICD, OWASP_OAT, OWASP_MASVS, MITRE_ATLAS, COMPTIA_SECAI, STRIDE (matching the real seeded set every recent sibling uses). |
| DR-01.2 | Threats SHALL include the OWASP Web Top 10 (2021) and OWASP LLM Top 10 (2025), in full — 20 threats total, matching every sibling's Phase-1 content scope. |
| DR-01.3 | MITRE ATLAS reference values SHALL be drawn from a minimum technique set including `AML.T0051` (LLM prompt injection's real ATLAS mapping). |
| DR-01.4 | No OWASP Agentic AI Top 10 threats are seeded in Phase-1 — the Matrix view SHALL report this honestly (a stated note, not padded-out invented data), matching every sibling's `agenticMatrix()`-equivalent behavior. |
| DR-02 | Mitigations SHALL number exactly 5 in Phase-1, each with code samples in all 5 languages (Python/Java/Go/Scala/Lua), both an attack-demo and a defense sample per language (50 samples total) — content reused verbatim from `app09_php_WORDPRESS`/`app11_swift_ios`/`app12_kotlin_android`. |
| DR-03 | Cornucopia card curation SHALL cover a representative sample per deck, not every card — matching every sibling's stated content-scope gap. |

---

**Traceability:** every FR/SR/NFR/DR above maps to at least one acceptance criterion in
`user_stories+tests.md`; every ID prefix (FR/SR/NFR/DR) matches the convention every
sibling's own `requirements.md` uses, for cross-app comparability.
