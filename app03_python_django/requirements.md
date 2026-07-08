# ThreatCompass 2026 — Requirements Document

**Version:** 1.0
**Date:** 2026-07-07
**Project:** `app03_python_django`
**Sources:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`, `docs/OWASP_stories/*.yaml` (6 card decks), `PLAN.md`

---

## 1. Functional Requirements

### FR-01 Framework Catalog
- **FR-01.1** The system SHALL display all supported security frameworks on the home page:
  OWASP Web Top 10, OWASP LLM Top 10, OWASP Agentic AI Top 10, OWASP API Security Top 10,
  OWASP Client-Side Top 10, OWASP CI/CD Security Top 10, OWASP Automated Threats (OAT),
  OWASP MASVS 2.0, MITRE ATLAS, CompTIA Security+ SY0-701 / SecAI+, plus the six Cornucopia-family
  card decks (Web App, Mobile App, Companion, STRIDE EoP, Elevation of MLSec, Digital-by-Default Harms).
- **FR-01.2** Each framework tile SHALL show: name, version, short description, reference URL, and threat count.
- **FR-01.3** Clicking a tile SHALL navigate to `/frameworks/<code>/` listing all its threats/cards.

### FR-02 Threat & Card Browser
- **FR-02.1** The system SHALL present one unified, searchable, filterable list across all threats and all Cornucopia cards.
- **FR-02.2** Each entry SHALL show: framework/edition badge, code (e.g. `LLM01`, `A03`, `AML.T0051`, `VE3`, `SCO2`), title/description excerpt, severity or card value, and STRIDE letters where applicable.
- **FR-02.3** Filters, combinable: framework/edition, suit (VE/AT/.../SCO/ARC...), severity, STRIDE category, category, tag, `q` free text.
- **FR-02.4** Sorting: severity (highest first), framework code, alphabetical.
- **FR-02.5** Filtering SHALL be implemented as an HTMX partial swap — no full page reload, results update within 300 ms of the last keystroke (debounced).

### FR-03 Threat / Card Detail Page
- **FR-03.1** Each threat and each Cornucopia card SHALL have a dedicated detail page at a stable URL.
- **FR-03.2** The page SHALL display: full title, framework/edition badge, severity or value, STRIDE badges, full description, attack vector, attack surface, related CVEs (if any), tags, and — for Cornucopia cards — the card's `misc` note and source URL.
- **FR-03.3** Tabs: **Overview | Attack Vectors | Mitigations | Code Samples | Cross-References**, implemented as HTMX-loaded partials.

### FR-04 Mitigations
- **FR-04.1** Every threat and every Cornucopia card SHALL have at least one `Mitigation`.
- **FR-04.2** Each mitigation SHALL show: title, description, type (Preventive/Detective/Corrective/Compensating), effort (Low/Medium/High), effectiveness (Partial/Significant/Full).

### FR-05 Code Samples (5 languages)
- **FR-05.1** Every mitigation SHALL provide code samples in Python, Java, Go, Scala, and Lua.
- **FR-05.2** Each sample SHALL have two sub-tabs: **Attack Example** (`ATTACK_DEMO`) and **Defense Example** (`DEFENSE`).
- **FR-05.3** Code SHALL be rendered with server-side Pygments syntax highlighting (no client-side highlighter bundle).
- **FR-05.4** A "Copy to Clipboard" button (Alpine.js) SHALL be present on every code block.
- **FR-05.5** Attack-demo code SHALL require the user to dismiss an "I understand this is vulnerable code, for education only" confirmation before the code is revealed or copyable.

### FR-06 Cross-Framework Mapping
- **FR-06.1** A `/matrix/` page SHALL present a table mapping threats/cards across frameworks.
- **FR-06.2** At minimum: OWASP LLM Top 10 ↔ MITRE ATLAS ↔ CompTIA SecAI+ ↔ Companion `LLM`/`AAI` cards.
- **FR-06.3** Matrix cells SHALL link to the corresponding detail page.
- **FR-06.4** The "Cross-References" tab on a detail page SHALL list all related items with relationship type.

### FR-07 STRIDE Coverage Heatmap
- **FR-07.1** `/stride-heatmap/` SHALL show a heatmap of STRIDE coverage per framework and per the STRIDE EoP deck's own 6 suits.
- **FR-07.2** Cells SHALL be color-coded none→low→medium→high.
- **FR-07.3** Clicking a cell SHALL navigate to the filtered threat/card list for that combination.

### FR-08 MITRE ATLAS Kill-Chain Timeline
- **FR-08.1** `/matrix/mitre-atlas/` SHALL render the 7-phase Cyber Kill Chain with ATLAS techniques placed on their phase.
- **FR-08.2** Hovering/tapping a technique SHALL show ID, name, short description, and any Companion `LLM`/`AAI`/mlsec cards that map to it.

### FR-09 Global Search
- **FR-09.1** A search box SHALL be present on every page (base template).
- **FR-09.2** Search SHALL cover threat titles/descriptions, mitigation text, code sample descriptions, card descriptions (`description_en` and `description_pl`), and tags, using PostgreSQL full-text search.
- **FR-09.3** Results SHALL be grouped by type and show matching excerpts with the query term highlighted.

### FR-10 Export
- **FR-10.1** Users SHALL be able to export the current filtered list as CSV or PDF.
- **FR-10.2** Export SHALL run as an async Celery task (`export.tasks.generate_csv` / `generate_pdf`, using the stdlib `csv` module and WeasyPrint respectively); the UI SHALL poll `/export/status/<job_id>/` and show a progress state, never blocking the request thread.

### FR-11 Bookmarks
- **FR-11.1** Users SHALL be able to bookmark any threat, card, or mitigation.
- **FR-11.2** Anonymous bookmarks persist in `localStorage`; authenticated users' bookmarks persist server-side against their account.

### FR-12 Admin / Editor Content Management
- **FR-12.1** Authenticated users with role `editor` or `admin` SHALL manage threats/mitigations/code samples via Django admin or protected views.
- **FR-12.2** Cornucopia card records (`CornucopiaCard`) SHALL be **read-only** even for editors — they are ingested exclusively from the reviewed YAML source files, never edited in the UI (this preserves the integrity guarantee in FR-16).
- **FR-12.3** Auth SHALL use `django-allauth` sessions for the web UI and JWT (`simplejwt`) for the API.

### FR-13 Card Deck Coverage (all six `docs/OWASP_stories/*.yaml` decks)
- **FR-13.1** `webapp-cards-3.0-en.yaml` (suits VE, AT, SM, AZ, CR, C, WC) SHALL be fully ingested and browsable at `/cards/webapp/`.
- **FR-13.2** `mobileapp-cards-1.1-en.yaml` (suits PC, AA, NS, RS, CRM, CM, WC) SHALL be browsable at `/cards/mobile/`.
- **FR-13.3** `__LLM_AI___companion-cards-1.0-en.yaml` (suits LLM, CLD, FRE, DVO, BOT, AAI, Common) SHALL be browsable at `/cards/companion/llm/`, `/cards/companion/agentic/`, `/cards/companion/frontend/`, `/cards/companion/devops/`.
- **FR-13.4** `STRIDE__eop-cards-5.0-en.yaml` (suits SP, TA, RE, ID, DO, EP) SHALL be browsable at `/cards/stride/` with the interactive heatmap.
- **FR-13.5** `RISKS__elevation-of-mlsec-cards-1.0-en.yaml` (suits EMR, EIR, EOR, EDR) SHALL be browsable at `/cards/mlsec/`.
- **FR-13.6** `dbd-cards-1.0-en.yaml` (suits SCO, ARC, AGE, TRU, POR, COR, WC) SHALL be browsable at `/cards/dbd-harms/`, explicitly labelled as a **service-design / digital-ethics harms deck** (not a pure technical-vulnerability deck) and cross-referenced to OWASP A04:2021 Insecure Design and CompTIA SecAI+ GRC content.
- **FR-13.7** Every card's `desc` field from the YAML SHALL be stored verbatim as `description_en`; a human-reviewed Polish translation SHALL be stored as `description_pl` (see FR-19.6 for translation-quality rules).

### FR-14 Content Integrity Verification Service
- **FR-14.1** On every YAML re-ingestion, the `integrity.services.HashVerificationService` SHALL verify the SHA-256 hash of the source file against `data/hashes.json` using the Python standard library `hashlib`.
- **FR-14.2** If verification fails, the ingestion command SHALL abort with no partial writes (`transaction.atomic()`), and log a `SEC-CARD-HASH-MISMATCH` event.
- **FR-14.3** `HashVerificationService.verify()` SHALL be callable **only** from the `load_cornucopia_cards` management command and the `integrity.tasks.periodic_hash_reverify` Celery task — never from a request-handling view or serializer — so that no public-facing code path can mark content as verified.
- **FR-14.4** `/matrix/` computations SHALL be performed by `matrix.services.MatrixComputationService` using the Django ORM's aggregation API (`annotate`/`aggregate`); computations expected to take longer than the request/response cycle SHALL be moved to a Celery task rather than a separate service.

### FR-15 MITRE ATLAS & CompTIA SecAI+ Content
- **FR-15.1** At least 15 MITRE ATLAS techniques across at least 5 tactics SHALL be seeded (see SCR-03 below) and cross-linked from relevant `LLM`, `AAI`, and `EMR/EIR/EOR/EDR` cards.
- **FR-15.2** At least 20 CompTIA Security+/SecAI+ topics SHALL be seeded, reusing the mapping table already present in `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`.

### FR-16 Content Integrity & Provenance
- **FR-16.1** Every `CornucopiaCard` SHALL store `content_sha256` computed over `description_en`; the admin UI SHALL display this hash and the verification timestamp.
- **FR-16.2** Any change to a YAML source file SHALL require a pull request reviewed by CODEOWNERS `@security-team` before the hash allowlist (`data/hashes.json`) is updated.

### FR-17 Internationalization (Polish / English)
- **FR-17.1** The application SHALL support exactly two UI languages: **Polish (`pl`, default)** and **English (`en`)**.
- **FR-17.2** A language toggle (Alpine.js component in the navbar) SHALL let the user switch instantly, showing the current language as `PL`/`EN` with a flag icon, with no full page reload.
- **FR-17.3** Selected language SHALL persist via the `django_language` cookie (Django's standard `LocaleMiddleware` mechanism) and be mirrored to `localStorage` for the Alpine.js toggle state.
- **FR-17.4** Default language on first visit SHALL be **Polish**. If `Accept-Language` prefers `en` and does not include `pl`, default to English.
- **FR-17.5** All static UI strings (navigation, headings, filter/tab/button labels, empty states, error messages, the disclaimer) SHALL be wrapped in `{% trans %}` / `{% blocktrans %}` (templates) or `gettext_lazy` (Python) and translated in both `locale/pl/LC_MESSAGES/django.po` and `locale/en/LC_MESSAGES/django.po`.
- **FR-17.6** Security content (`ThreatTranslation`, `CornucopiaCard.description_pl`) SHALL be stored per-locale in the database, not machine-translated on the fly. Missing Polish translations SHALL fall back to English content with a small "EN" badge — never a blank field.
- **FR-17.7** Code samples SHALL NOT be translated. In-code comments remain in English in both locales — including the `# VULNERABLE` / `# BEZPIECZNY` labels, which are the **one** exception: the safety label on the code block itself SHALL be translated (see FR-05.5), while the code body stays English.
- **FR-17.8** URL paths SHALL remain in English in both locales (`/threats/`, `/cards/stride/` — never `/zagrozenia/`).
- **FR-17.9** `/api/v1/search` SHALL query both `description_en` and `description_pl` (and `title`/`ThreatTranslation`) simultaneously and return results in the locale requested via `Accept-Language` or `?lang=`.
- **FR-17.10** CI SHALL run `manage.py compilemessages --check` (or equivalent key-parity check) and fail the build if any translation key used in a template is missing from either `.po` file.

---

## 2. Non-Functional Requirements

### NFR-01 Performance
- **NFR-01.1** Threat/card list pages SHALL render within 2 s on a standard broadband connection.
- **NFR-01.2** DRF list endpoints SHALL respond within 250 ms (p95) under normal load.
- **NFR-01.3** Full-text search SHALL return results within 500 ms.
- **NFR-01.4** HTMX partial swaps SHALL transfer < 20 KB of HTML per filter interaction.

### NFR-02 Security (the app must model what it teaches)
- **NFR-02.1** All DRF input SHALL be validated via serializers; all Django forms SHALL use Django's built-in validation — no hand-rolled parsing of request bodies.
- **NFR-02.2** All database access SHALL go through the Django ORM/QuerySet API — no raw SQL string concatenation. Any unavoidable raw SQL SHALL use parameterized queries (`params=`) exclusively.
- **NFR-02.3** HTTP security headers SHALL be set via `django-csp`/`SecurityMiddleware`: `Content-Security-Policy`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Strict-Transport-Security`, `Referrer-Policy: same-origin`.
- **NFR-02.4** All write endpoints (Django views and DRF) SHALL require authentication; `editor`/`admin` roles enforced via Django permissions/groups.
- **NFR-02.5** Attack-demo code samples SHALL always render inside a visually distinct red-bordered `ATTACK_DEMO` block with a warning label — never styled identically to `DEFENSE` samples.
- **NFR-02.6** No secrets, API keys, Redis/Celery broker passwords, or DB credentials SHALL be committed to the repository; `.env` / Docker secrets only, `.env.example` provided with placeholder values.
- **NFR-02.7** YAML files SHALL only ever be parsed with `yaml.safe_load` — `yaml.load`/`yaml.unsafe_load` are forbidden and enforced by a Bandit `B506` rule in CI.
- **NFR-02.8** The Celery/Redis broker port SHALL NOT be published in `docker-compose.yml`; only the Docker-internal network SHALL reach it, and the broker SHALL require a password (`requirepass`) even on the internal network.

### NFR-03 Usability & Accessibility
- **NFR-03.1** Fully responsive from 375 px to 2560 px.
- **NFR-03.2** Light and dark mode via Alpine.js toggle, no page reload.
- **NFR-03.3** WCAG 2.1 AA contrast ratios on all interactive elements.
- **NFR-03.4** All icons/images have meaningful `alt`/`aria-label`.
- **NFR-03.5** All core flows (browsing, filtering, reading code) SHALL be fully keyboard-navigable, including HTMX-swapped content (focus management on swap).

### NFR-04 Maintainability
- **NFR-04.1** All seed data SHALL live under `backend_django/data/` as JSON/YAML, loaded via Django management commands — never hand-written as Python object literals in migrations.
- **NFR-04.2** Each `CodeSample` SHALL carry `version_note` so maintainers know when a sample needs a refresh as languages/frameworks evolve.
- **NFR-04.3** Django apps SHALL follow a `models.py` / `services.py` / `selectors.py` / `views.py` / `serializers.py` / `urls.py` separation per app (Django's recommended "fat models, thin views," with business logic in `services`/`selectors`, not in views).
- **NFR-04.4** Celery tasks SHALL be thin wrappers that call into the same `services.py` functions used by views — task functions themselves SHALL NOT contain business logic, so the logic is testable without Celery running.
- **NFR-04.5** Environment-specific config SHALL live in `threatcompass/settings/{base,dev,prod}.py`.

### NFR-05 Testability (TDD — see `user_stories+tests.md` for the full plan)
- **NFR-05.1** Backend unit test coverage SHALL be ≥ 85% for `services`/`selectors` packages (`pytest-django` + `coverage.py`).
- **NFR-05.2** Every DRF endpoint SHALL have an `APITestCase` integration test.
- **NFR-05.3** `HashVerificationService` and `MatrixComputationService` SHALL have pure `pytest` unit tests with no Django test-DB dependency where possible (they operate on files/querysets, not raw SQL).
- **NFR-05.4** At least one Playwright (Python) end-to-end test per user story (US-01–US-19).
- **NFR-05.5** Tests SHALL be written **before** the implementation for every new feature (Red → Green → Refactor); a PR that adds production code without a preceding failing test committed in the same PR SHALL fail review.

### NFR-06 Portability
- **NFR-06.1** The full stack (Django + Celery worker/beat + PostgreSQL + Redis + Nginx) SHALL run via a single `docker compose up`.
- **NFR-06.2** A single production image based on `python:3.13-slim` SHALL serve both the Django web process and the Celery worker/beat processes (different container entrypoints, same image).
- **NFR-06.3** Static files served by WhiteNoise or Nginx directly — no dependency on an external CDN.

### NFR-07 Internationalization Quality
- **NFR-07.1** Language switching SHALL complete in under 150 ms perceived latency (cookie set + HTMX/Alpine re-render, no full navigation for the toggle itself where feasible).
- **NFR-07.2** Compiled `.mo` files SHALL add no more than ~50 KB to the deployed image; they are server-side only, not shipped to the browser.
- **NFR-07.3** Polish strings SHALL be reviewed by at least one native Polish-speaking security professional before production release.
- **NFR-07.4** No hardcoded user-visible strings SHALL exist in templates or Python view code; all go through `{% trans %}`/`gettext_lazy`.
- **NFR-07.5** DRF responses serving translated content SHALL set `Content-Language: pl` or `Content-Language: en`.
- **NFR-07.6** Absent or unsupported `Accept-Language` SHALL default to `pl` per FR-17.4, with `Content-Language: pl` in the response.

---

## 3. Security Content Requirements (Data)

### SCR-01 OWASP Web Top 10 (2021) — all 10
| Code | Title |
|---|---|
| A01:2021 | Broken Access Control |
| A02:2021 | Cryptographic Failures |
| A03:2021 | Injection |
| A04:2021 | Insecure Design |
| A05:2021 | Security Misconfiguration |
| A06:2021 | Vulnerable and Outdated Components |
| A07:2021 | Identification and Authentication Failures |
| A08:2021 | Software and Data Integrity Failures |
| A09:2021 | Security Logging and Monitoring Failures |
| A10:2021 | Server-Side Request Forgery (SSRF) |

### SCR-02 OWASP LLM Top 10 (2025) — all 10
| Code | Title |
|---|---|
| LLM01 | Prompt Injection |
| LLM02 | Sensitive Information Disclosure |
| LLM03 | Supply Chain Vulnerabilities |
| LLM04 | Data and Model Poisoning |
| LLM05 | Improper Output Handling |
| LLM06 | Excessive Agency |
| LLM07 | System Prompt Leakage |
| LLM08 | Vector and Embedding Weaknesses |
| LLM09 | Misinformation / Overreliance |
| LLM10 | Unbounded Consumption / Model DoS |

### SCR-03 MITRE ATLAS — minimum 15 techniques, ≥ 5 tactics
| Tactic | Technique | Name |
|---|---|---|
| Reconnaissance | AML.T0000 | Active Scanning |
| Reconnaissance | AML.T0002 | Acquire Public ML Artifacts |
| Initial Access | AML.T0010 | ML Supply Chain Compromise |
| Initial Access | AML.T0051 | LLM Prompt Injection |
| ML Attack Staging | AML.T0018 | Backdoor ML Model |
| ML Attack Staging | AML.T0020 | Poison Training Data |
| ML Attack Staging | AML.T0019 | Publish Poisoned Datasets |
| Execution | AML.T0041 | Craft Adversarial Data |
| Defense Evasion | AML.T0043 | Adversarial Perturbation |
| Defense Evasion | AML.T0015 | Evade ML Model |
| Credential Access | AML.T0012 | Valid Accounts |
| Exfiltration | AML.T0024 | Exfiltrate via ML Inference API |
| Exfiltration | AML.T0025 | Infer Training Data Membership |
| Impact | AML.T0029 | Denial of ML Service |
| Impact | AML.T0046 | Spamming ML System with Chaff Data |

### SCR-04 CompTIA Security+ SY0-701 / SecAI+ — minimum 20 topics
Prompt Injection · Data & Model Poisoning · Membership Inference · Model Inversion ·
Model Theft/Extraction · Adversarial ML · Jailbreaking (direct + indirect) · Excessive Agency ·
System Prompt Leakage · RAG/Vector DB weaknesses · AI-generated Spear Phishing ·
Deepfake Audio/Video (Vishing) · Polymorphic AI Malware · AI-assisted Zero-Day Discovery ·
AI TRiSM · Phishing-resistant MFA (FIDO2/WebAuthn) · Zero Trust Architecture · AI-BOM ·
NIST AI RMF · NIS2/UKSC (PL/EU).

### SCR-05 Cornucopia-family Card Decks (`docs/OWASP_stories/*.yaml`) — full ingestion
| Deck | File | Minimum coverage |
|---|---|---|
| Website App v3.0 | `webapp-cards-3.0-en.yaml` | all 7 suits (VE, AT, SM, AZ, CR, C, WC), all cards |
| Mobile App v1.1 | `mobileapp-cards-1.1-en.yaml` | all 7 suits (PC, AA, NS, RS, CRM, CM, WC), all cards |
| Companion v1.0 | `__LLM_AI___companion-cards-1.0-en.yaml` | all 7 suits (LLM, CLD, FRE, DVO, BOT, AAI, Common), all cards |
| STRIDE EoP v5.0 | `STRIDE__eop-cards-5.0-en.yaml` | all 6 STRIDE suits (SP, TA, RE, ID, DO, EP), all cards |
| Elevation of MLSec v1.0 | `RISKS__elevation-of-mlsec-cards-1.0-en.yaml` | all 4 suits (EMR, EIR, EOR, EDR), all cards |
| Digital-by-Default Harms v1.0 | `dbd-cards-1.0-en.yaml` | all suits (SCO, ARC, AGE, TRU, POR, COR, WC), all cards |

### SCR-06 STRIDE Mapping — minimum coverage
| STRIDE | Minimum threats/cards mapped |
|---|---|
| S — Spoofing | 5 |
| T — Tampering | 5 |
| R — Repudiation | 3 |
| I — Information Disclosure | 6 |
| D — Denial of Service | 4 |
| E — Elevation of Privilege | 4 |

---

## 4. Code Sample Requirements (per language)

### CSR-01 Python
- Python 3.13; Django 5.2 ORM / DRF for web examples.
- Attack demo comment: `# VULNERABLE — do not use in production`.
- Defense demo comment explains **why** the pattern is secure.

### CSR-02 Java
- Java 21 (LTS); Spring Boot 3.3, Spring Security 6, Spring Data JPA.
- No Lombok in samples (readability for learners over brevity).
- Use records for sample DTOs.

### CSR-03 Go
- Go 1.22+; Gin 1.9+; `pgx` v5; standard library `crypto`.
- Attack and defense demo in the same file with clear `// --- ATTACK ---` / `// --- DEFENSE ---` section comments.

### CSR-04 Scala
- Scala 3.x; Akka HTTP or http4s; Slick 3.x or Doobie.
- Functional style preferred (ZIO/cats-effect for async samples).
- Include a `build.sbt` dependency snippet in comments.

### CSR-05 Lua
- Lua 5.4 / LuaJIT 2.1; OpenResty (NGINX + Lua); LuaSQL; `lua-resty-*` where applicable.
- Header comment: `-- Requires: OpenResty >= 1.21 / Lua 5.4`.

---

## 5. Constraints

- **C-01** The application SHALL be written entirely in Python 3.13 / Django 5.2 — web process and Celery worker/beat processes alike. No other backend runtime language is used anywhere in the application itself.
- **C-02** Code **samples** shown to users (Python, Java, Go, Scala, Lua) are educational content, not part of the application's own runtime — Java appears only as one of the five sample languages, never as application code.
- **C-03** The application SHALL NOT make outbound calls to external threat-intel feeds at runtime; all framework/threat/card data is seeded locally from files under `data/`. External URLs are stored as reference links only.
- **C-04** Every page SHALL display a disclaimer that content is for educational purposes and must be verified against official sources.
- **C-05** No third-party analytics, tracking scripts, or externally-hosted fonts/CDNs; Tailwind is compiled at build time, fonts are self-hosted.
- **C-06** Every code sample SHALL carry a version annotation for future maintenance.
- **C-07** Only Polish and English are supported; both `.po` files SHALL be complete before any new translation key reaches production — missing keys fail the CI build, not silently fall back at runtime for *UI strings* (security *content* falls back per FR-17.6).
- **C-08** `CornucopiaCard` records are never editable through the UI or admin — content changes only through a reviewed PR to the source YAML files plus a hash-allowlist update (FR-16).
- **C-09** The Celery/Redis broker SHALL never be exposed on a public port; it exists solely to run asynchronous tasks for the Django application over the Docker-internal network.

---

## 6. Glossary

| Term | Definition |
|---|---|
| OWASP | Open Worldwide Application Security Project |
| Cornucopia | OWASP's card-game family for threat modeling (Website App, Mobile App, Companion editions) |
| STRIDE | Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege |
| MITRE ATLAS | Adversarial Threat Landscape for AI Systems |
| CompTIA SecAI+ | CompTIA's AI-security certification track |
| MASVS | OWASP Mobile Application Security Verification Standard |
| OAT | OWASP Automated Threats to Web Applications |
| Digital-by-Default Harms deck | A card deck (`dbd-cards-1.0-en.yaml`) modeling societal/service-design harms — exclusion, surveillance, repeated data requests — in public-sector digital services; mapped here to OWASP A04:2021 Insecure Design and GRC/AI-Act content, not to a technical CVE-style vulnerability |
| Celery | Python distributed task queue, used here for async export jobs, YAML re-ingestion, and periodic integrity re-verification — runs as a separate OS process but the same Python/Django codebase |
| Celery beat | Celery's scheduler process, used to trigger `periodic_hash_reverify` on a fixed schedule (e.g. weekly) |
| HTMX | Library for driving partial page updates from server-rendered HTML, without a client SPA framework |
| i18n / l10n | Internationalization / localization |
| Locale | Language+region code (`pl`, `en`) determining displayed content |
| `django_language` | Django's standard cookie for the active locale |
| `Accept-Language` / `Content-Language` | HTTP request/response headers for language negotiation |
| Fail-secure | On integrity-check failure, the system SHALL refuse to load the data rather than load it in a possibly-tampered state |
