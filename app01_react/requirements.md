# SecureVision 2026 — Requirements Document

**Version:** 1.1  
**Date:** 2026-07-06  
**Project:** app01_react  
**Source:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`

---

## 1. Functional Requirements

### FR-01 Framework Catalog
- **FR-01.1** The system SHALL display all supported security frameworks on a landing page:
  - OWASP Web Application Security Top 10 (2021, current 2026)
  - OWASP LLM Top 10 (2025/2026)
  - OWASP API Security Top 10
  - MITRE ATLAS (Adversarial Threat Landscape for AI Systems)
  - CompTIA Security+ SY0-701
  - CompTIA SecAI+
- **FR-01.2** Each framework entry SHALL display: name, version, short description, official reference URL, and the number of threats it contains.
- **FR-01.3** The user SHALL be able to navigate from a framework tile directly to the list of threats belonging to that framework.

### FR-02 Threat Browser
- **FR-02.1** The system SHALL present a searchable and filterable list of all threats across all frameworks.
- **FR-02.2** Each threat entry in the list SHALL display: framework badge, threat code (e.g. LLM01, A03, AML.T0051), title, severity badge (CRITICAL / HIGH / MEDIUM / LOW / INFO), and STRIDE letters where applicable.
- **FR-02.3** The list SHALL support the following filters simultaneously:
  - Framework (multi-select checkboxes)
  - Severity level (multi-select)
  - STRIDE category: S, T, R, I, D, E (multi-select)
  - Threat category (free-text or pre-defined: Injection, Access Control, AI/ML, Cryptography, etc.)
  - Tag (e.g. "LLM", "supply-chain", "deepfake")
- **FR-02.4** The list SHALL support sorting by: severity (highest first), framework code, alphabetical title.
- **FR-02.5** The list SHALL support full-text search over threat title and description with instant results (debounce 300 ms).

### FR-03 Threat Detail Page
- **FR-03.1** Each threat SHALL have a dedicated detail page accessible via its unique URL.
- **FR-03.2** The detail page SHALL display:
  - Full title and framework badge
  - Severity, category, STRIDE letters (as colored badges)
  - Full description (markdown rendered)
  - Attack vectors section (how the attack is performed)
  - Attack surface section (where the attack hits)
  - Related CVE references (if any)
  - Tags
- **FR-03.3** The detail page SHALL have tabs: **Overview | Mitigations | Code Samples | Cross-References**.

### FR-04 Mitigations
- **FR-04.1** Every threat SHALL have at least one mitigation entry.
- **FR-04.2** Each mitigation SHALL display: title, description, mitigation type (Preventive / Detective / Corrective / Compensating), implementation effort (Low / Medium / High), effectiveness (Partial / Significant / Full).
- **FR-04.3** Mitigations SHALL link directly to code samples.

### FR-05 Code Samples
- **FR-05.1** Every mitigation SHALL provide code samples in all five languages:
  | # | Language | Primary Framework/Library |
  |---|---|---|
  | 1 | Python | FastAPI, SQLAlchemy, Pydantic |
  | 2 | Java (Spring Boot) | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
  | 3 | Go (Golang) | Gin framework, pgx v5, net/http |
  | 4 | Scala | Akka HTTP, Slick ORM, ZIO |
  | 5 | Lua | OpenResty / NGINX Lua, LuaSQL |
- **FR-05.2** Each code sample SHALL consist of two parts displayed in separate sub-tabs:
  - **Attack Example** — minimal runnable code that demonstrates the vulnerability
  - **Defense Example** — secure version of the same code with the vulnerability fixed
- **FR-05.3** Code SHALL be displayed with syntax highlighting appropriate to the language.
- **FR-05.4** A "Copy to Clipboard" button SHALL be present on each code block.
- **FR-05.5** Each code sample SHALL show: language name and version, framework/library name and version, a one-sentence description of what the snippet demonstrates.

### FR-06 Cross-Framework Mapping
- **FR-06.1** The system SHALL provide a dedicated "Matrix" page that presents a table mapping threats across frameworks.
- **FR-06.2** The matrix SHALL at minimum map: OWASP LLM Top 10 ↔ MITRE ATLAS ↔ CompTIA SecAI+.
- **FR-06.3** Each cell in the matrix SHALL be clickable, navigating to the corresponding threat detail page.
- **FR-06.4** A threat detail page SHALL list all cross-references in a "Cross-References" tab showing: source code, target code, relationship type (EQUIVALENT / RELATED / MAPS_TO / PARENT_CHILD), and description.

### FR-07 STRIDE Coverage Heatmap
- **FR-07.1** The system SHALL provide a "Coverage" page displaying a heatmap showing how many threats in each framework cover each STRIDE category.
- **FR-07.2** The heatmap cells SHALL be color-coded: none (grey) → low (yellow) → medium (orange) → high (red/green scale).
- **FR-07.3** Clicking a cell SHALL navigate to the filtered threat list for that framework + STRIDE combination.

### FR-08 MITRE ATLAS Kill-Chain Timeline
- **FR-08.1** The system SHALL display a visual Kill-Chain timeline for MITRE ATLAS threats showing the 7 Cyber Kill Chain phases (Reconnaissance → Weaponization → Delivery → Exploitation → Installation → Command & Control → Actions on Objectives).
- **FR-08.2** Each MITRE ATLAS technique SHALL be placed on the timeline at its corresponding phase.
- **FR-08.3** Hovering over a technique on the timeline SHALL show its ID, name, and a short description.

### FR-09 Global Search
- **FR-09.1** A global search box SHALL be present in the navigation bar on all pages.
- **FR-09.2** Search SHALL cover: threat titles, descriptions, mitigation titles, mitigation descriptions, code sample descriptions, tags.
- **FR-09.3** Search results SHALL be grouped by type (Threats, Mitigations, Code Samples) and show the matching framework.
- **FR-09.4** Matching terms SHALL be highlighted in the result excerpts.

### FR-10 Export
- **FR-10.1** The user SHALL be able to export the currently filtered threat list as CSV.
- **FR-10.2** The user SHALL be able to export a single threat detail page as PDF.

### FR-11 User Bookmarks
- **FR-11.1** The user SHALL be able to bookmark any threat or mitigation.
- **FR-11.2** Bookmarks SHALL be persisted in `localStorage` (no login required for basic bookmarks).
- **FR-11.3** A "Bookmarks" page SHALL list all saved items with quick-links to their detail pages.

### FR-12 Admin Data Management (optional, post-MVP)
- **FR-12.1** An authenticated admin role SHALL be able to add, edit, and delete threats, mitigations, and code samples via a protected admin UI or the Swagger UI.
- **FR-12.2** Admin login SHALL use JWT tokens issued by Spring Security.

### FR-13 Internationalization (Polish / English)
- **FR-13.1** The application SHALL support two UI languages: **Polish (pl)** and **English (en)**.
- **FR-13.2** A language toggle control SHALL be visible in the navigation bar on every page, allowing the user to switch between Polish and English with a single click. The toggle SHALL display the current language as a two-letter code (`PL` / `EN`) with a flag icon.
- **FR-13.3** The selected language SHALL persist across page reloads and navigation using `localStorage` key `sv_locale`.
- **FR-13.4** The default language on first visit SHALL be **Polish** (`pl`). If the browser's `Accept-Language` header contains `en` as the first preference and does not contain `pl`, the default SHALL switch to English.
- **FR-13.5** All **static UI strings** SHALL be translated into both languages. This includes:
  - Navigation labels (Frameworks, Threats, Matrix, Coverage, Search, Bookmarks, About)
  - Page titles and headings
  - Filter labels (Severity, Framework, STRIDE, Language, Tags)
  - Tab labels (Overview, Mitigations, Code Samples, Cross-References)
  - Button labels (Export CSV, Copy, Bookmark, Attack Example, Defense Example)
  - Empty state messages, loading indicators, error messages
  - Disclaimer text displayed on every page
- **FR-13.6** All **security content** (threat titles, descriptions, attack vectors, mitigation titles and descriptions) SHALL have bilingual versions stored in the database. The API SHALL accept an `Accept-Language: pl` or `Accept-Language: en` header and return the appropriate language content. If a translation is missing, the system SHALL fall back to English without error.
- **FR-13.7** Threat and mitigation **code samples** are language-agnostic (they are code, not prose). Code blocks SHALL NOT be translated. In-code comments SHALL be in English only.
- **FR-13.8** STRIDE letters (S, T, R, I, D, E) and security framework codes (LLM01, A03, AML.T0051) SHALL remain in their original form in both languages — they are internationally recognized identifiers, not prose.
- **FR-13.9** The URL structure SHALL remain in English regardless of the selected UI language (e.g., `/threats`, `/frameworks` — never `/zagrozenia`, `/frameworki`). Only the displayed content changes.
- **FR-13.10** The `/api/search` endpoint SHALL search across both the Polish and English versions of threat/mitigation text simultaneously, returning results in the currently requested language.

---

## 2. Non-Functional Requirements

### NFR-01 Performance
- **NFR-01.1** The threat list page SHALL load all data within 2 seconds on a standard broadband connection.
- **NFR-01.2** REST API list endpoints SHALL respond within 200 ms (p95) under normal load.
- **NFR-01.3** Full-text search SHALL return results within 500 ms.
- **NFR-01.4** React code-splitting SHALL be used so the initial JS bundle is < 300 KB gzipped.

### NFR-02 Security (the app itself must model what it teaches)
- **NFR-02.1** All API inputs SHALL be validated with Bean Validation (Jakarta Validation API) on the backend.
- **NFR-02.2** All SQL queries SHALL use parameterized statements via Spring Data JPA — no string concatenation in queries.
- **NFR-02.3** HTTP security headers SHALL be set: `Content-Security-Policy`, `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Strict-Transport-Security`.
- **NFR-02.4** API endpoints that write data SHALL require JWT authentication.
- **NFR-02.5** All code sample "attack demo" snippets SHALL be clearly labeled as unsafe and isolated visually (red border, warning label) so they cannot be confused with production-safe code.
- **NFR-02.6** No secrets, API keys, or passwords SHALL be committed to the repository. Use `.env` files or environment variables.

### NFR-03 Usability & Accessibility
- **NFR-03.1** The UI SHALL be fully responsive and usable on screens from 375 px (mobile) to 2560 px (4K).
- **NFR-03.2** The UI SHALL support both light mode and dark mode, toggled by a button in the navigation bar.
- **NFR-03.3** All interactive elements SHALL meet WCAG 2.1 AA contrast ratios.
- **NFR-03.4** All images and icons SHALL have meaningful `alt` text or `aria-label`.
- **NFR-03.5** Keyboard navigation SHALL work for all core flows (browsing threats, reading code samples).

### NFR-04 Maintainability
- **NFR-04.1** All seed data (threats, mitigations, code samples) SHALL be stored as JSON files under `data/` and loaded via a Spring Boot `CommandLineRunner` on first start, making it easy to add new content without code changes.
- **NFR-04.2** Code samples SHALL reference the language version and framework version so they can be reviewed and updated when libraries change.
- **NFR-04.3** Backend Java code SHALL follow standard Spring Boot project structure with clear separation: controller / service / repository / entity / dto.
- **NFR-04.4** React components SHALL follow the single-responsibility principle; each component file SHALL not exceed 250 lines.
- **NFR-04.5** All environment-specific config SHALL be in `application.yml` profiles (dev, test, prod).

### NFR-05 Testability
- **NFR-05.1** Backend unit test coverage SHALL be ≥ 80% for `service` and `repository` packages.
- **NFR-05.2** All REST controllers SHALL have integration tests using `@SpringBootTest` and Testcontainers (real PostgreSQL).
- **NFR-05.3** React components with conditional rendering or user interactions SHALL have unit tests written with Vitest and React Testing Library.
- **NFR-05.4** At least 3 Playwright end-to-end smoke tests SHALL cover: home page loads, threat detail page loads with code samples, global search returns results.

### NFR-06 Portability
- **NFR-06.1** The entire application (backend + frontend + database) SHALL run with a single `docker compose up` command on any machine with Docker installed.
- **NFR-06.2** The production Docker image for the backend SHALL be based on `eclipse-temurin:21-jre-alpine` to minimize size.
- **NFR-06.3** The frontend production build SHALL be served by Nginx Alpine.

### NFR-07 Internationalization (i18n) Quality
- **NFR-07.1** Language switching SHALL complete without a full page reload; React SHALL re-render in-place within 100 ms of the toggle being clicked.
- **NFR-07.2** The initial JS bundle size increase caused by adding i18n support SHALL NOT exceed 30 KB gzipped (translation JSON files are lazy-loaded per locale, not bundled).
- **NFR-07.3** Polish translation strings SHALL be reviewed for technical accuracy by at least one native Polish-speaking security professional before production release.
- **NFR-07.4** No hardcoded user-visible strings SHALL exist in React component files. All UI text SHALL be referenced via translation keys (e.g., `t('nav.threats')`).
- **NFR-07.5** The backend SHALL return `Content-Language: pl` or `Content-Language: en` response headers on all endpoints that serve translated content.
- **NFR-07.6** If the `Accept-Language` request header is absent or contains an unsupported locale, the API SHALL default to `en` and respond with `Content-Language: en`.

---

## 3. Security Content Requirements (Data)

### SCR-01 OWASP Web Top 10 Coverage
All 10 entries from OWASP Top 10 (2021) SHALL be present with:
- Full description
- Attack vector + attack surface
- Mitigation with code samples in all 5 languages
- STRIDE mapping (where applicable)

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

### SCR-02 OWASP LLM Top 10 Coverage
All 10 entries from OWASP LLM Top 10 (2025/2026) SHALL be present:

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

### SCR-03 MITRE ATLAS Techniques Coverage
At minimum 15 MITRE ATLAS techniques SHALL be present, spread across at least 5 tactics:

| Tactic | Technique ID | Technique Name |
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

### SCR-04 CompTIA Security+ SY0-701 / SecAI+ Coverage
At minimum 20 CompTIA topics SHALL be present covering:

**AI as Attack Target:**
- Prompt Injection
- Data & Model Poisoning
- Membership Inference Attack
- Model Inversion Attack
- Model Theft / Model Extraction
- Adversarial Machine Learning
- Jailbreaking (direct + indirect)
- Excessive Agency / Agentic AI risks
- System Prompt Leakage
- RAG / Vector database weaknesses

**AI as Attacker's Weapon:**
- AI-generated Spear Phishing
- Deepfake Audio/Video (Vishing)
- Polymorphic AI Malware
- AI-assisted Zero-Day Discovery
- AI-powered CAPTCHA bypass
- Biometric spoofing with GAN

**Defensive AI:**
- AI TRiSM (Trust, Risk, and Security Management)
- XDR / EDR behavioral detection
- Phishing-resistant MFA (FIDO2 / WebAuthn)
- Zero Trust Architecture
- AI-BOM (AI Bill of Materials)
- Rate limiting / Guardrails for LLM APIs
- Human-in-the-loop for critical actions
- NIST AI RMF

**GRC:**
- NIS2 / UKSC (Poland / EU 2024–2026)
- NIST AI Risk Management Framework
- AUP (Acceptable Use Policy) for AI tools

### SCR-05 STRIDE Mapping Requirements
The following minimum STRIDE coverage must be achieved across all threats:

| STRIDE Category | Minimum Threats Mapped |
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
- Use Python 3.12+
- Primary library for web: FastAPI 0.110+
- ORM: SQLAlchemy 2.x (async)
- Input validation: Pydantic v2
- Each sample SHALL be runnable with minimal setup
- Attack demo SHALL include a comment: `# VULNERABLE — do not use in production`
- Defense demo SHALL include a comment explaining WHY this approach is secure

### CSR-02 Java (Spring Boot)
- Java 21 (LTS)
- Spring Boot 3.3.x
- Spring Security 6 for auth/authz examples
- Spring Data JPA + Hibernate 6 for ORM examples
- No Lombok in code samples (keep samples dependency-minimal and readable)
- Use records for DTOs in Java 21 samples

### CSR-03 Go (Golang)
- Go 1.22+
- Gin 1.9+ for HTTP routing
- pgx v5 for PostgreSQL
- Use standard library `crypto` package for cryptographic examples
- Attack demo and defense demo SHALL be in the same file with clear section comments

### CSR-04 Scala
- Scala 3.x (LTS)
- Akka HTTP or http4s for web layer
- Slick 3.x or Doobie for database
- Prefer functional style (ZIO / cats-effect for async examples)
- Include `build.sbt` dependency snippet in the sample comments

### CSR-05 Lua
- Lua 5.4 / LuaJIT 2.1
- OpenResty (NGINX + Lua) for web/API examples
- LuaSQL for database access
- `lua-resty-*` libraries where applicable (e.g., `lua-resty-jwt` for auth)
- Comment at the top of each file: `-- Requires: OpenResty >= 1.21 / Lua 5.4`

---

## 5. User Stories

| ID | As a... | I want to... | So that... |
|---|---|---|---|
| US-01 | security architect | browse all OWASP LLM threats | I can quickly review what AI-related risks exist |
| US-02 | Java developer | see a Java Spring Boot code example for each SQL injection defense | I can copy-paste a secure implementation pattern |
| US-03 | Go developer | filter threats by language = Go and see code samples | I can find Go-specific security patterns immediately |
| US-04 | CompTIA SecAI+ student | see how LLM01 Prompt Injection maps to MITRE ATLAS AML.T0051 | I understand the cross-framework relationship for the exam |
| US-05 | security trainer | display the STRIDE heatmap on a projector | I can visually explain STRIDE coverage to a workshop audience |
| US-06 | pentester | search for "deepfake" and find all related threats with defenses | I can quickly assemble a test checklist for a client engagement |
| US-07 | team lead | export the filtered threat list to CSV | I can include it in a risk register document |
| US-08 | developer | see the MITRE Kill Chain timeline | I understand at which attack phase each ATLAS technique is used |
| US-09 | Scala developer | find code samples for supply chain attacks written in Scala | I can implement SCA checks in our Scala build pipeline |
| US-10 | Lua/OpenResty developer | see Lua examples for rate limiting to prevent LLM DoS | I can configure NGINX guardrails for our LLM API proxy |
| US-11 | Polish-speaking security student | switch the entire application from English to Polish with one click | I can study all threat descriptions, mitigations, and UI labels in my native language |
| US-12 | React/frontend developer | browse OWASP Cornucopia FRE cards (DOM XSS, clickjacking, CORS, JWT forgery) with Polish descriptions and OWASP Client-Side Top 10 references | I can map client-side attack scenarios to mitigations in my React application |
| US-13 | ML engineer / AI architect | explore all 10 OWASP LLM Top 10 2025 threats via Cornucopia LLM cards with Polish translations and an interactive LLM × cards matrix | I can understand prompt injection, data poisoning, excessive agency and supply chain risks in LLM systems |
| US-14 | agentic AI developer | study OWASP Agentic AI Top 10 2026 threats via Cornucopia AAI cards (excessive autonomy, unvalidated trust chains, orchestration manipulation) | I can design human-in-the-loop safeguards for autonomous agent pipelines |
| US-15 | security architect / threat modeler | use the STRIDE EoP card catalogue (Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege) with an interactive heatmap per system component | I can run a structured threat modeling session and map findings to OWASP Web Top 10 |
| US-16 | data scientist / ML security engineer | browse ML security risks (Model Risk, Input Risk, Output Risk, Dataset Risk) from Elevation of MLSec cards with MITRE ATLAS technique references | I can identify adversarial ML attacks, model theft, data poisoning and output manipulation in ML pipelines |
| US-17 | Android/iOS developer | view OWASP MAS (MASVS) threats via Cornucopia Mobile App cards (TLS verification, jailbreak detection, hardcoded keys, IPC security) | I can understand how mobile security controls differ from web and apply MASVS requirements |
| US-18 | DevSecOps engineer / team lead | browse DevOps supply chain risks (DVO cards) and automated threat patterns (BOT cards) with OWASP CI/CD Security Risk references and rate limiting mitigations | I can protect CI/CD pipelines, validate artifact integrity and defend against scraping and credential stuffing bots |

---

## 6. Constraints

- **C-01** The application code SHALL be written entirely in Java 21 (backend) and React 18 / TypeScript (frontend). No other backend languages.
- **C-02** Code SAMPLES displayed to the user cover Python, Java, Go, Scala, and Lua — these are sample content, not the application's runtime language.
- **C-03** The application SHALL NOT make outbound HTTP requests to external threat intelligence feeds at runtime (data is seeded locally from JSON files). External URLs are stored as reference links only.
- **C-04** All security framework data (OWASP, MITRE, CompTIA) displayed is for educational purposes. The application SHALL display a disclaimer on every page that information is for learning and must be verified against official sources.
- **C-05** The application SHALL be entirely self-hosted; no third-party analytics, tracking scripts, or external fonts are permitted (inline CSS fonts only).
- **C-06** The code samples SHALL cover threats and defenses as of 2026. Each sample SHALL include a version annotation so future maintainers know when to update it.
- **C-07** The application SHALL support Polish and English as the only two UI languages. No additional locales will be added in the initial release. All translation keys SHALL be defined in both `pl.json` and `en.json` before any key is used in production code — missing keys are a build-time error, not a runtime fallback.

---

## 7. Glossary

| Term | Definition |
|---|---|
| OWASP | Open Worldwide Application Security Project — non-profit producing free security standards and tools |
| OWASP LLM Top 10 | OWASP's list of the 10 most critical risks in Large Language Model applications |
| MITRE ATLAS | Adversarial Threat Landscape for AI Systems — MITRE's matrix of adversarial ML attack tactics and techniques |
| CompTIA Security+ | Vendor-neutral IT security certification exam (current version SY0-701) |
| CompTIA SecAI+ | CompTIA's dedicated AI security certification track |
| STRIDE | Microsoft threat modeling framework: Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege |
| Prompt Injection | Attack that manipulates an LLM by embedding malicious instructions in user input or retrieved content |
| Model Poisoning | Attack that corrupts an ML model's training data to manipulate its future behavior |
| AI TRiSM | Gartner's framework: AI Trust, Risk, and Security Management |
| AI-BOM | AI Bill of Materials — manifest of a model's origin, training data, dependencies, and versions |
| Kill Chain | Lockheed Martin's 7-phase model of a cyberattack: Reconnaissance → Actions on Objectives |
| Zero Trust | Security architecture that assumes no implicit trust, verifying every request regardless of network location |
| NIS2 / UKSC | EU Network and Information Security Directive 2, implemented in Poland via the Act on National Cybersecurity System |
| RAG | Retrieval-Augmented Generation — LLM architecture that queries external knowledge bases at inference time |
| Guardrails | Input/output filters applied around an LLM to prevent misuse or data leakage |
| LLM | Large Language Model — a neural network trained on massive text corpora (e.g. GPT-4, Claude, Gemini) |
| FIDO2 / WebAuthn | Phishing-resistant authentication standard using hardware security keys or biometrics |
| XDR / EDR | Extended / Endpoint Detection and Response — security tools that monitor behavior rather than signatures |
| i18n | Internationalization — the engineering practice of designing software to support multiple languages without code changes |
| l10n | Localization — the translation and cultural adaptation of i18n-enabled software for a specific locale |
| Locale | A combination of language and optional region code (e.g., `pl` for Polish, `en` for English) that determines displayed language |
| Translation key | A dot-separated identifier (e.g., `nav.threats`, `severity.critical`) used in React components instead of hardcoded strings |
| `pl.json` | The Polish translation file under `frontend/src/i18n/pl.json` containing all Polish UI strings keyed by translation keys |
| `en.json` | The English translation file under `frontend/src/i18n/en.json` containing all English UI strings keyed by translation keys |
| `Accept-Language` | HTTP request header sent by browsers and API clients to indicate the preferred response language |
| `Content-Language` | HTTP response header set by the backend to declare the language of the returned content |
| `sv_locale` | The `localStorage` key used to persist the user's chosen language across browser sessions |


## 8. Use tables...


### Totalne Monitorowanie i Logowanie (Comprehensive Auditing)

Jeśli dojdzie do incydentu (np. agent zostanie oszukany i podejmie złą decyzję), musisz mieć możliwość odtworzenia jego procesu myślowego.

- **Logowanie "Śladu Myślowego" (Chain-of-Thought Logging):** Zapisuj w bezpiecznych, niezmiennych logach (np. w systemie SIEM) nie tylko ostateczną odpowiedź agenta, ale cały jego proces wnioskowania: jakie kroki planował, jakie narzędzia wywołał i jakie dane od nich otrzymał.

- **Detekcja anomalii (Rate Limiting dla AI):** Monitoruj częstotliwość wywoływania narzędzi przez agenta. Jeśli w ułamku sekundy agent zaczyna masowo odpytywać funkcje API (np. w pętli wywołanej błędem lub atakiem), system powinien automatycznie zamrozić jego działanie i podnieść alert bezpieczeństwa.

### Złota zasada dla Architekta Systemu:

**Traktuj każdą informację zwrotną i każdą decyzję wygenerowaną przez agenta AI jako "dane wejściowe od nieznanego użytkownika z internetu".** Zastosowanie klasycznej zasady *Zero Trust* (Nigdy nie ufaj, zawsze weryfikuj) w stosunku do samego agenta to najskuteczniejsza metoda na utrzymanie wysokiego poziomu bezpieczeństwa całej aplikacji.

### Przejście ze „Starego” do „Nowego” Security (SecAI+)

Zasada analogii polega na tym, że fundamentalne koncepcje bezpieczeństwa pozostają niezmienne, ale zmienia się sposób ich technicznej realizacji.

| Klasyczne Security | Nowe Security (SecAI+) | Jak to działa w praktyce? |
| :-: | :-: | :-: |
| **Zasada Najmniejszych Uprawnień (Least Privilege)** | **Nadmierna sprawczość (Excessive Agency Control)** | Kiedyś ograniczałeś dostęp użytkownika do bazy danych. Dziś musisz drastycznie ograniczyć dostęp *agenta AI (wtyczek) do systemów. AI nie może mieć prawa usuwania danych ani wykonywania przelewów bez ostatecznej autoryzacji człowieka (*Human-in-the-Loop). |
| **Uwierzytelnianie i autoryzacja (MFA, RBAC)** | **Izolacja kontekstu i RAG (Context Isolation)** | Kiedyś pilnowałeś, by użytkownik A nie widział plików użytkownika B. W systemach AI (np. z bazą RAG), jeśli wrzucisz dokumenty obu użytkowników do jednej bazy wektorowej, LLM może w odpowiedzi dla użytkownika A wykorzystać wiedzę z dokumentu użytkownika B. Musisz izolować dane na poziomie wektorów. |
| **Firewall / WAF (Zapora sieciowa)** | **LLM Firewalls & Gateway** | Klasyczny WAF blokuje podejrzane pakiety sieciowe IP. WAF dla AI (np. LLM Gateway) analizuje zapytania tekstowe i blokuje te, które próbują wymusić złośliwe zachowanie modeli chmurowych, optymalizując też zużycie tokenów (*Denial of Wallet). |
| **Sanityzacja kodu i SQL i XSS** | **Bezpieczne renderowanie odpowiedzi (Output Handling)** | Jeśli LLM pod wpływem manipulacji wygeneruje złośliwy skrypt JavaScript, a Twoja strona internetowa bezrefleksyjnie go wyświetli, dojdzie do klasycznego ataku XSS na przeglądarkę użytkownika. AI traktujemy jako całkowicie niezaufane źródło danych. |

### SDLC, DRP i ARP w świecie Sztucznej Inteligencji

#### SDLC (Software Development Life Cycle) -\> Przejście w Secure MLOps

Klasyczny cykl rozwoju oprogramowania (SDLC) zakłada mitygację ryzyk od fazy projektowania (*Shift Left). W SecAI+ proces ten rozszerza się do **Secure MLOps**, gdzie zabezpiecza się nie tylko kod aplikacji, ale cały cykl życia modelu:

- **Faza zbierania danych:** Weryfikacja pod kątem *Data Poisoning (zatruwania danych).

- **Faza wyboru modelu:** Generowanie dokumentacji **AI-BOM** (AI Bill of Materials), czyli cyfrowego paszportu modelu potwierdzającego jego pochodzenie i brak podatności w łańcuchu dostaw.

- **Faza testów:** Przeprowadzanie dedykowanego **AI Red Teaming** (prób złamania modelu przed wdrożeniem).

### Tabela mapowania podatności i zagrożeń AI

| Zagrożenie / Podatność | OWASP (LLM Top 10) | MITRE ATLAS (Taktyka) | CompTIA SecAI+ (Rola) | Szkolenie S.. (Pokrycie) |
| :-: | :-: | :-: | :-: | :-: |
| **Wstrzykiwanie promptów (Prompt Injection)** | LLM01: Prompt Injection | TA0001: Initial Access / ML Model Input Manipulation | **AI jako cel:** Wektor bezpośredni (czaty) i pośredni (RAG, złośliwe strony www). | Blok: Testowanie odporności modeli LLM, audytowanie danych wejściowych i walidacja promptów. |
| **Zatruwanie danych treningowych (Data Poisoning)** | LLM03: Training Data Poisoning | TA0006: Adversarial ML / Poison Data Supply Chain | **AI jako cel:** Wektor podaży (zanieczyszczenie potoków MLOps i hurtowni danych). | Blok: Bezpieczeństwo potoków danych (Data pipelines), weryfikacja integralności zbiorów treningowych. |
| **Kradzież / Ekstrakcja modelu (Model Theft)** | LLM10: Model Theft | TA0010: Exfiltration / Model Inversion & Extraction | **AI jako cel:** Wektor odpytywania API w celu sklonowania wag i IP firmy. | Blok: Ochrona produkcyjna modeli, wykrywanie anomalii w zapytaniach API i rate limiting. |
| **Nadmierna sprawczość agentów (Excessive Agency)** | LLM02: Insecure Output Handling / LLM07: Excessive Agency | TA0002: Execution / Execution via LLM Plugins | **AI jako cel:** Podatność aplikacji integrującej wtyczki AI z systemami operacyjnymi/bazami. | Blok: Projektowanie bezpiecznej architektury wokół AI, zasada minimalnych uprawnień dla wtyczek. |
| **Wnioskowanie o prywatności (Membership Inference / Inversion)** | LLM06: Sensitive Information Disclosure | TA0009: Discovery / ML Model Inference Attacks | **AI jako cel:** Atak na poufność danych poprzez masową analizę odpowiedzi (Confidence scores). | Blok: Zgodność wdrożeń z wymaganiami prawnymi (RODO/AI Act) oraz techniki prywatności różnicowej. |
| **Polimorficzne złośliwe oprogramowanie (AI-Mutating Malware)** | *Nie dotyczy (błąd infrastruktury, nie aplikacji LLM) | TA0003: Defense Evasion (generowanie kodu omijającego EDR) | **AI jako broń:** Użycie LLM przez hakera do dynamicznej zmiany sygnatur wirusów. | Blok: Reagowanie na incydenty i wykrywanie zaawansowanych zagrożeń nowej generacji. |
| **Zautomatyzowany Phishing i Deepfake** | *Nie dotyczy (atak socjotechniczny zewnętrzny) | TA0001: Initial Access / Reconnaissance (profilowanie ofiar) | **AI jako broń:** Generowanie masowych, bezbłędnych wiadomości i synteza głosu (Vishing). | Blok: Analiza zagrożeń z użyciem AI, modelowanie ryzyk organizacyjnych i procedury bezpieczeństwa. |
| **Uczenie adwersaryjne (Adversarial Examples / Evasion)** | LLM01: Prompt Injection (szerokie ujęcie manipulacji wejściem) | TA0003: Defense Evasion / Evasion via Adversarial Input | **AI jako cel:** Modyfikowanie danych wejściowych (szum w obrazie/audio) w celu oszukania klasyfikatora. | Blok: Metody obrony modeli ML przed złośliwymi modyfikacjami, audytowanie stabilności sieci neuronowych. |
