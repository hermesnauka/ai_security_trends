# ThreatView 2026 — Application Development Plan

**Wersja:** 2.0  
**Data:** 2026-07-07  
**Status:** Living document — updated after each sprint planning session

---

## 1. Project Overview

**Name:** ThreatView 2026  
**Purpose:** An interactive security reference and learning platform that maps threats, vulnerabilities, and mitigations across six major frameworks — OWASP Web Top 10 (2021), OWASP LLM Top 10 (2025), OWASP API Security Top 10, OWASP Agentic AI Top 10 (2026), MITRE ATLAS (adversarial AI/ML techniques), and CompTIA Security+ SY0-701 / SecAI+ 2026. Each threat is presented with countermeasure sample code in five languages: Python, Java (Spring Boot), Go, Scala, and Lua.

**Cornucopia extension:** The platform covers the full OWASP Cornucopia card catalogue — Website App Edition v3.0, Companion Edition v1.0 (LLM, AAI, FRE, DVO, BOT, CLD suits), Mobile App Edition v1.1, Microsoft STRIDE Elevation of Privilege v5.0, and Elevation of MLSec v1.0 — giving practitioners an interactive card-based threat-modeling reference aligned with the core framework content.

**UI languages:** Polish (default) and English — switch persisted in `localStorage` under key `tv_locale`.

**Key differentiator from SecureVision (app01_react):** ThreatView uses **Angular 18 standalone components** + **Angular Material 18 (MDC-based)** for the frontend, offering Material Design, Angular-native reactivity via Signals and NgRx, Angular's built-in security primitives (`DomSanitizer`, strict mode, `strictTemplates`), and `ngx-translate` for runtime i18n without a build step.

---

## 2. Technology Stack

### Backend
| Layer | Technology | Version |
|---|---|---|
| Runtime | Java | 21 LTS |
| Framework | Spring Boot | 3.3.x |
| Security | Spring Security 6 | JWT / OAuth2 |
| Persistence | PostgreSQL 16 | Spring Data JPA |
| Cache | Redis 7 | Spring Cache |
| Build | Maven 3.9 | — |
| Docs | SpringDoc OpenAPI 3 | Swagger UI |
| DB migrations | Flyway | — |
| Testing | JUnit 5, Mockito, Testcontainers, RestAssured | — |
| Rate limiting | Bucket4j | — |
| Input sanitization | OWASP Java HTML Sanitizer | — |
| Integrity checks | Java MessageDigest (SHA-256) | — |

### Frontend
| Layer | Technology | Version |
|---|---|---|
| Framework | Angular | 18.x (standalone components) |
| UI Library | Angular Material | 18.x (MDC-based) |
| Language | TypeScript | 5.x (`strict: true`) |
| Build | Angular CLI | 18.x |
| State | Angular Signals + NgRx Signals | — |
| Router | Angular Router | 17+ (typed routes) |
| i18n | ngx-translate | 15.x |
| Charts | ngx-echarts (Apache ECharts) | — |
| SVG / Diagrams | D3.js v7 | — |
| Syntax highlight | Prism.js | lazy-loaded per language |
| HTTP | Angular HttpClient | — |
| Forms | Angular Reactive Forms | — |
| Testing unit | Jest 29 + Angular Testing Library | — |
| Testing E2E | Cypress 13 | — |
| Validation | class-validator + class-transformer | — |
| MSW | Mock Service Worker 2 | — |

### Infrastructure
| Component | Technology |
|---|---|
| Reverse proxy | Nginx |
| Container | Docker + Docker Compose |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Loki + Prometheus |
| Secrets | Docker Secrets / GitHub Secrets |
| SAST | SpotBugs + FindSecBugs + eslint-plugin-security |
| DAST | OWASP ZAP |
| SCA | OWASP Dependency Check + npm audit + Trivy |

---

## 3. High-Level Architecture

```
Browser (Angular SPA)
        │
        │  HTTPS
        ▼
  Nginx (port 443)
   ├── /api/v1/*  ─────► Spring Boot (port 8080)
   │                       ├── FrameworkController
   │                       ├── ThreatController          ← threats + Cornucopia cards
   │                       ├── CardSuitController        ← suit browsers (FRE/LLM/AAI…)
   │                       ├── MitigationController
   │                       ├── CodeSampleController
   │                       ├── MatrixController          ← cross-framework matrices
   │                       ├── SearchController
   │                       ├── ExportController          ← CSV/PDF
   │                       └── AdminController           ← JWT-gated CRUD
   │
   └── /*         ─────► Angular SPA bundle (ng build)
                           ├── AppShellComponent (mat-sidenav)
                           ├── Feature modules (lazy-loaded via loadComponent)
                           └── Shared: ThreatCardComponent, CornucopiaCardComponent,
                                       CodeSamplePanelComponent, BotWarningDialogComponent,
                                       LanguageToggleComponent, StrideHeatmapComponent

PostgreSQL 16  ◄── Spring Data JPA
Redis 7        ◄── Spring Cache (heatmap SVG, matrix JSON — TTL 5 min)
```

---

## 4. Architecture Design Decisions

### D-01 — Angular strict mode + strictTemplates
`strict: true` and `strictTemplates: true` in `tsconfig.json`. Eliminates entire classes of XSS-prone patterns (unchecked `any` casts, `[innerHTML]` without sanitizer call) at compile time. Enforced by `ng build` in CI.

### D-02 — Angular DomSanitizer as the only HTML rendering path
All card descriptions (`descriptionPl`, `descriptionEn`) rendered via `DomSanitizer.sanitize(SecurityContext.HTML, value)`. `bypassSecurityTrustHtml` is **forbidden** on user-sourced content — enforced by ESLint rule `no-bypass-security`.

### D-03 — Spring Security 6 stateless (SESSIONLESS)
JWT-only, no server-side sessions → no CSRF token needed on REST endpoints. Stateless simplifies horizontal scaling and removes session-fixation attack surface.

### D-04 — Parameterized queries only (no string concatenation)
All JPA queries use named parameters (`:param`) or `Specification<T>` predicate builder. String concatenation in `@Query` is a compile-time lint error (SpotBugs rule SPRING_JDBC).

### D-05 — ContentIntegrityVerifier: fail-secure startup
`@PostConstruct` bean reads `data/hashes.json` and verifies SHA-256 of every YAML card file. On any mismatch the application **refuses to start** (`ContentIntegrityException`). Prevents tampered card content from entering production.

### D-06 — YAML card files immutable at runtime
Loaded once at startup by `YamlCardLoader`, stored in `CornucopiaCard` entities. No runtime re-read. File-system access after startup is blocked by Spring profile (`card.file.readonly=true`).

### D-07 — All OWASP/MASVS/MITRE reference IDs validated via server-side allowlists
`OwaspRefValidator`, `MitreAtlasRefValidator`, `MavsRefValidator`, `CicdSecRefValidator`, `OatRefValidator` — each loads its allowlist from JSON at startup. Any unknown ID rejected with HTTP 422. Prevents content-poisoning via admin CRUD.

### D-08 — Rate limiting: Bucket4j 60 req/min per IP on card suit endpoints
Applied on all `/api/v1/threats?suit=*` endpoints. Returns HTTP 429 with `Retry-After` header. Loki alert `SEC-007` fires on > 5 rejections/min from single IP. Reflects D-11 dogfooding.

### D-09 — Angular OnPush change detection throughout
All feature and shared components use `ChangeDetectionStrategy.OnPush`. Reduces re-render attack surface (XSS via unexpected re-render), improves performance (< 200 ms p95 for list views), enables signal-based reactive patterns.

### D-10 — ngx-translate with plain-text keys only (no HTML in i18n values)
All `pl.json` / `en.json` values are plain text. HTML interpolation in translations is disabled. i18n key parity verified by `i18n-keys-parity.spec.ts` in CI — build fails on missing keys.

### D-11 — Dogfooding: app teaching BOT attacks implements its own BOT defenses
The platform that teaches OAT-011 scraping must itself be protected by rate limiting (D-08) and `BotWarningDialogComponent`. Demonstrated to users as a live example.

### D-12 — AAI agent chain diagrams rendered server-side as SVG
Agentic AI flow diagrams generated by backend (D3.js/Batik) and returned as static SVG. No client-side JS evaluation of diagram data. SVG `<script>` tags are stripped by `DomSanitizer` anyway, but server-side generation is the primary defense.

### D-13 — DVO code examples use pseudocode only — never real working CI/CD exploits
DevOps card (DVO) examples showing pipeline injection techniques use annotated pseudocode. Real pipeline credentials never appear in content. `CI_EXPLOIT_PATTERN` grep check in `yaml-content-integrity` CI job.

---

## 5. Data Model

### 5.1 Framework
```
Framework {
  id:           UUID
  code:         String   // "OWASP_WEB", "OWASP_LLM", "OWASP_API", "OWASP_AGENTIC",
                         //  "MITRE_ATLAS", "COMPTIA_SY0701", "COMPTIA_SECAI",
                         //  "CORNUCOPIA_WEBAPP", "CORNUCOPIA_COMPANION",
                         //  "CORNUCOPIA_MOBILE", "STRIDE_EOP", "MLSEC"
  name:         String
  version:      String   // "2025", "v3.0", "5.0"
  description:  String
  referenceUrl: String
}
```

### 5.2 Threat
```
Threat {
  id:            UUID
  frameworkId:   UUID     // FK → Framework
  code:          String   // "LLM01:2025", "A01:2021", "AML.T0051"
  title:         String
  severity:      Enum     // CRITICAL, HIGH, MEDIUM, LOW, INFO
  category:      String
  description:   String
  attackVector:  String
  attackSurface: String
  stride:        Set<Enum> // S, T, R, I, D, E  (null for non-STRIDE items)
  cveReferences: List<String>
  tags:          List<String>
}
```

### 5.3 ThreatTranslation  *(i18n — US-11)*
```
ThreatTranslation {
  id:           UUID
  threatId:     UUID     // FK → Threat
  locale:       String   // "pl", "en"
  title:        String
  description:  String
  attackVector: String
  category:     String
}
```

### 5.4 CornucopiaCard  *(Cornucopia card catalogue — US-12–US-18)*
```
CornucopiaCard {
  id:            UUID
  cardId:        String   // "FRE4", "LLMX", "EPK", "EDRK", "NSX"
  suitCode:      String   // "FRE", "LLM", "AAI", "DVO", "BOT", "CLD",
                          //  "VE", "AT", "SM", "AZ", "CR",
                          //  "PC", "AA", "NS", "RS", "CRM", "CM",
                          //  "SP", "TA", "RE", "ID", "DS", "EP",
                          //  "EMR", "EIR", "EOR", "EDR"
  suitName:      String   // "Frontend", "Large Language Models", "Agentic AI"…
  edition:       String   // "companion", "webapp", "mobileapp", "eop", "mlsec"
  value:         String   // "2"–"10", "J", "Q", "K", "A"
  isCritical:    Boolean  // true for J, Q, K
  descriptionEn: String   // original English from YAML
  descriptionPl: String   // Polish translation
  owaspRefs:     List<String>  // ["A03:2021", "Client-Side C01"]
  mitreRefs:     List<String>  // ["MITRE ATLAS T0014"]
  mavsRefs:      List<String>  // ["MASVS-NETWORK-2"]
  cicdSecRefs:   List<String>  // ["CICD-SEC-03"]
  oatRefs:       List<String>  // ["OAT-011"]
  agentAiRefs:   List<String>  // ["AgentAI07"]
  contentHash:   String   // SHA-256 of descriptionEn — integrity field
}
```

### 5.5 Mitigation
```
Mitigation {
  id:                   UUID
  threatId:             UUID    // FK → Threat (or CornucopiaCard via cardId)
  title:                String
  description:          String
  mitigationType:       Enum    // PREVENTIVE, DETECTIVE, CORRECTIVE, COMPENSATING
  implementationEffort: Enum    // LOW, MEDIUM, HIGH
  effectiveness:        Enum    // PARTIAL, SIGNIFICANT, FULL
}
```

### 5.6 CodeSample
```
CodeSample {
  id:            UUID
  mitigationId:  UUID    // FK → Mitigation
  language:      Enum    // PYTHON, JAVA, GO, SCALA, LUA
  sampleType:    Enum    // ATTACK_DEMO, DEFENSE
  title:         String
  description:   String
  codeSnippet:   String  // full educational snippet
  frameworkHint: String  // "Spring Boot 3.3", "FastAPI 0.110", "Gin 1.9", "Akka HTTP", "OpenResty"
  version:       String  // language/framework version annotation
}
```

### 5.7 CrossReference
```
CrossReference {
  id:               UUID
  sourceThreatId:   UUID
  targetThreatId:   UUID
  relationshipType: Enum  // EQUIVALENT, RELATED, PARENT_CHILD, MAPS_TO
  description:      String
}
```

### 5.8 ContentHash  *(YAML integrity — SSDLC Phase 6)*
```
ContentHash {
  id:         UUID
  fileName:   String   // "companion-llm-cards-1.0-en.yaml"
  sha256Hash: String
  verifiedAt: Instant
  isValid:    Boolean
}
```

---

## 6. Development Phases

### Phase 1 — Foundation (Sprints 1–2, Weeks 1–4)
Pokrycie: US-01

- [ ] `ng new threatview --standalone --routing --style=scss`
- [ ] `ng add @angular/material` — theme: indigo-amber, typography, animations
- [ ] Spring Boot 3.3 skeleton: Web, Security, Data JPA, Actuator, SpringDoc
- [ ] Docker Compose: PostgreSQL 16 + Redis 7 + backend + frontend + Nginx
- [ ] Flyway migracje V1–V8 (entities Framework, Threat, Mitigation, CodeSample, CrossReference, ThreatTranslation, CornucopiaCard, ContentHash)
- [ ] Seedowanie danych: OWASP Web Top 10, LLM Top 10 2025, MITRE ATLAS, CompTIA SecAI+
- [ ] `GET /api/v1/frameworks`, `GET /api/v1/threats` z paginacją
- [ ] Spring Security 6: stateless JWT (SESSIONLESS), rola ADMIN do CRUD
- [ ] `AppShellComponent` — `mat-sidenav-container` + `mat-toolbar` + `LanguageToggleComponent`
- [ ] `DashboardComponent` — mat-card statystyki, ShortSearchBarComponent

**Security checkpoint:** D-03 (stateless JWT) skonfigurowane; brak stack trace w odpowiedziach 5xx.

### Phase 2 — Core API + Angular Threat Browser (Sprints 3–4, Weeks 5–8)
Pokrycie: US-02, US-03, US-04

- [ ] `GET /api/v1/threats` — filtry: frameworkCode, severity, stride, category, tag, q, suit, owaspRef, mitreRef
- [ ] `GET /api/v1/threats/{id}` ze zagnieżdżonymi mitigacjami i próbkami kodu
- [ ] `GET /api/v1/cross-references` — tabela mapowania między frameworkami
- [ ] `ThreatBrowserComponent` — `mat-table` + `mat-paginator` + panel filtrów (`mat-select`, `mat-chip-listbox`)
- [ ] `ThreatDetailComponent` — `mat-tab-group`: Przegląd | Mitigacje | Kod | Powiązania
- [ ] `ThreatCardComponent` — mat-card, `SeverityBadgeComponent` (mat-chip), STRIDE chips, OnPush
- [ ] `MatrixComponent` — tabela mapowania OWASP ↔ MITRE ATLAS ↔ CompTIA
- [ ] `FrameworkListComponent` + `FrameworkDetailComponent` (mat-expansion-panel)
- [ ] Wszystkie komponenty: `ChangeDetectionStrategy.OnPush`, typed Angular Signals

**Security checkpoint:** D-04 (parameterized queries); bean validation na filtrach; globalna obsługa wyjątków bez stack trace.

### Phase 3 — Code Samples + MITRE ATLAS Timeline (Sprints 5–6, Weeks 9–12)
Pokrycie: US-08, US-09, US-10

- [ ] `CodeSamplePanelComponent` — `mat-tab-group` × 5 języków, `LazyPrismDirective`
- [ ] Attack Demo tab: mat-card z `border-left: 4px solid #b71c1c`, badge `PODATNY`
- [ ] `BotWarningDialogComponent` — MatDialog "Rozumiem ryzyko" przed skopiowaniem kodu ataku
- [ ] MITRE ATLAS Kill-Chain timeline — ngx-echarts horizontal gantt-bar (fazy: Reconnaissance → Impact)
- [ ] `CoverageComponent` — ECharts heatmap pokrycia STRIDE per framework
- [ ] Tag cloud — `mat-chip-set` do przeglądania po kategorii

**Security checkpoint:** D-02 (DomSanitizer w ThreatCardComponent); próbki kodu ATTACK_DEMO nigdy nie wykonywane server-side.

### Phase 4 — Advanced Features (Sprints 6–7, Weeks 11–14)
Pokrycie: US-05, US-06, US-07

- [ ] Full-text search: `tsvector` PostgreSQL na polach title+description+attackVector
- [ ] `GET /api/v1/search?q=` — paginacja, podświetlone fragmenty
- [ ] `SearchResultsComponent` — `HighlightPipe` do renderowania `<mark>` tagów (sanitized)
- [ ] `SearchBarComponent` w mat-toolbar z `mat-autocomplete`
- [ ] Export CSV / PDF: `GET /api/v1/export?format=csv&frameworkCode=LLM`
- [ ] Dark mode toggle — Angular Material theme switch (ui.store Signal)
- [ ] Ulubione / zakładki — `localStorage` service, persist per session

**Security checkpoint:** Limit długości query `?q=` do 200 znaków; CSV injection prevention (Apache Commons CSV quote-all); rate limit na /api/v1/search.

### Phase 5 — i18n Polish ↔ English (Sprint 8, Weeks 15–16)
Pokrycie: US-11

- [ ] `ThreatTranslation` entity — Flyway V9
- [ ] `LocaleService` — `ngx-translate`, zapis w `localStorage` (`tv_locale`), emit ngx-translate language change
- [ ] `LocaleInterceptor` — wstrzykuje `Accept-Language: pl|en` do każdego HttpClient request
- [ ] `LanguageToggleComponent` — `mat-button-toggle-group` w mat-toolbar
- [ ] `assets/i18n/pl.json` + `assets/i18n/en.json` — klucze bez HTML; ≥ 50 kluczy
- [ ] Próbki kodu NIGDY nie tłumaczone — `sampleType: ATTACK_DEMO|DEFENSE` wyłączone z i18n
- [ ] CI test: `i18n-keys-parity.spec.ts` — niezgodność kluczy = fail build

**Security checkpoint:** D-10 (plain text w plikach i18n); `LocaleInterceptor` waliduje wartość do 'pl' lub 'en' — nie przekazuje raw navigator.language.

### Phase 6 — Cornucopia: FRE + LLM + AAI (Sprint 9, Weeks 17–18)
Pokrycie: US-12, US-13, US-14

- [ ] `CornucopiaCard` entity — Flyway V10
- [ ] `YamlCardLoader` @PostConstruct — ładuje z `data/cornucopia/*.yaml`
- [ ] `ContentIntegrityVerifier` @PostConstruct — SHA-256 vs `data/hashes.json` (D-05)
- [ ] `OwaspRefValidator` — allowlist z `data/ref-allowlists.json`
- [ ] `CardSuitController` — `GET /api/v1/threats?suit=FRE|LLM|AAI`
- [ ] `FrontendSecurityComponent` — przeglądarka kart FRE z polskimi opisami (US-12)
- [ ] `LlmSecurityComponent` + `LlmMatrixComponent` — macierz LLM Top 10 × karty (US-13)
- [ ] `AgenticAiComponent` + `AgenticMatrixComponent` — macierz Agentic AI (US-14)
- [ ] `CornucopiaCardComponent` — mat-card: suit badge, value circle, OWASP ref chips, OnPush
- [ ] `AUTONOMY RISK` mat-chip na kartach AAIK, AAIQ (isCritical + suitCode=AAI)
- [ ] Bucket4j rate limit 60 req/min per IP na `/api/v1/threats?suit=*` (D-08)

**Security checkpoint:** D-05 (ContentIntegrityVerifier GREEN); D-07 (OwaspRefValidator); DomSanitizer wywołany w CornucopiaCardComponent przed `[innerHTML]`.

### Phase 7 — Cornucopia: STRIDE EoP + MLSec (Sprints 10–11, Weeks 19–22)
Pokrycie: US-15, US-16

- [ ] `MitreAtlasRefValidator` — allowlist z `data/mitre-atlas-allowlist.json`
- [ ] `GET /api/v1/threats/stride/categories`, `GET /api/v1/stride-heatmap` (JWT required)
- [ ] `GET /api/v1/threats/mlsec/categories`, filtry po mitreRef
- [ ] `StrideCatalogueComponent` — `mat-accordion` × 6 suit, 13 kart per suit
- [ ] `StrideHeatmapComponent` — ngx-echarts heatmap, `AuthGuard` (D-11 wizualizacja)
- [ ] Diagramy agentów: SVG generowane server-side (D-12) — Angular renderuje jako `<img>`
- [ ] `MlSecurityComponent` — 4 mat-tab (EMR/EIR/EOR/EDR), MITRE ATLAS ref chips
- [ ] `ML-SPECIFIC` mat-chip na kartach MLSec
- [ ] Spring Security header: `X-Frame-Options: DENY` na `/stride-heatmap`

**Security checkpoint:** AuthGuard rediryguje na /login bez JWT; `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'`; MitreAtlasRefValidator blokuje nieznane T-kody.

### Phase 8 — Cornucopia: Mobile + DevOps (Sprints 12–13, Weeks 23–26)
Pokrycie: US-17, US-18

- [ ] `MavsRefValidator`, `CicdSecRefValidator`, `OatRefValidator` (D-07)
- [ ] `GET /api/v1/threats/mobile/suits` + `/api/v1/matrix/mobile-vs-web`
- [ ] `MobileSecurityComponent` — 6 suit Mobile (PC/AA/NS/RS/CRM/CM), MASVS ref chips
- [ ] `MobileVsWebMatrixComponent` — mat-table MASVS vs OWASP Web Top 10
- [ ] `GET /api/v1/threats?suit=DVO|BOT`
- [ ] `DevOpsSecurityComponent` — sekcje DVO i BOT, CICD-SEC chips, OAT chips
- [ ] `BotWarningDialogComponent` v2 — dialog `MatDialog` z flagą `bot_warning_ack` w localStorage
- [ ] CI job `yaml-content-integrity`: ajv schema + `CI_EXPLOIT_PATTERN` grep + hash-generator
- [ ] Przykłady kodu DVO: TYLKO pseudokod (D-13)

**Security checkpoint:** BotWarningDialog wyświetlany przed kartami BOT (BOTX, BOTJ, BOTK); OatRefValidator blokuje niezdefiniowane OAT-xxx; DVO code review — brak działających exploitów pipeline.

### Phase 9 — Integration, Testing & Hardening (Sprints 14–16, Weeks 27–31)
Pokrycie: US-01–US-18 pełna integracja

- [ ] Testy jednostkowe: JUnit 5 + Mockito ≥ 80% (JaCoCo); Jest 29 + ATL ≥ 75% (lcov)
- [ ] Testy integracyjne: Testcontainers PostgreSQL 16 dla wszystkich endpointów REST
- [ ] Testy E2E: Cypress 13 — 18 plików `*.cy.ts` (≥ 25 scenariuszy łącznie)
- [ ] Abuse cases AC-01–AC-18 — wszystkie GREEN w CI
- [ ] DAST: OWASP ZAP full active scan — 0 High/Critical
- [ ] SCA: OWASP Dependency Check + npm audit — 0 Critical CVEs
- [ ] Trivy Docker image scan — 0 CRITICAL
- [ ] `axe-core` (cypress-axe) — 0 Critical/Serious WCAG 2.1 AA violations
- [ ] Lighthouse mobile ≥ 85 (Performance), ≥ 90 (Accessibility)
- [ ] `ng build --configuration production` bundle audit (zob. Section 11)
- [ ] Monitoring: Loki alerts SEC-007/SEC-008/SEC-009; Prometheus metryki

---

## 7. API Endpoint Map

### Framework & Threat (bazowe)
```
GET  /api/v1/frameworks                         — lista wszystkich frameworków
GET  /api/v1/frameworks/{code}                  — szczegóły frameworku + lista zagrożeń

GET  /api/v1/threats                            — lista zagrożeń
                                                  filtry: frameworkCode, severity, stride,
                                                          tag, q, suit, owaspRef, mitreRef
GET  /api/v1/threats/{id}                       — zagrożenie z mitigacjami
GET  /api/v1/threats/{id}/mitigations
GET  /api/v1/threats/{id}/code-samples
```

### Cornucopia Card Suits (US-12–US-18)
```
GET  /api/v1/threats?suit=FRE                   — karty Frontend (US-12)
GET  /api/v1/threats?suit=LLM                   — karty LLM (US-13)
GET  /api/v1/threats?suit=AAI                   — karty Agentic AI (US-14)
GET  /api/v1/threats/stride/categories          — 6 kategorii STRIDE (US-15)
GET  /api/v1/threats?suit=SP|TA|RE|ID|DS|EP     — poszczególne talie STRIDE (US-15)
GET  /api/v1/threats/mlsec/categories           — 4 kategorie MLSec (US-16)
GET  /api/v1/threats?suit=EMR|EIR|EOR|EDR       — poszczególne talie MLSec (US-16)
GET  /api/v1/threats/mobile/suits               — 6 talii Mobile (US-17)
GET  /api/v1/threats?suit=PC|AA|NS|RS|CRM|CM    — poszczególne talie Mobile (US-17)
GET  /api/v1/threats?suit=DVO                   — karty DevOps (US-18)
GET  /api/v1/threats?suit=BOT                   — karty Automated Threats (US-18)
```

### Matrix & Visualization
```
GET  /api/v1/matrix/llm                         — macierz LLM Top 10 × karty Cornucopia
GET  /api/v1/matrix/agentic                     — macierz Agentic AI × LLM porównanie
GET  /api/v1/matrix/mobile-vs-web               — porównanie MASVS vs OWASP Web Top 10
GET  /api/v1/stride-heatmap                     — heatmapa STRIDE per komponent [JWT]
GET  /api/v1/cross-references                   — tabela mapowania między frameworkami
GET  /api/v1/cross-references?sourceCode=LLM01
GET  /api/v1/stats/coverage                     — dane JSON dla heatmapy pokrycia
```

### Search & Export
```
GET  /api/v1/search?q=prompt+injection
GET  /api/v1/export?format=csv&frameworkCode=LLM
GET  /api/v1/export?format=pdf&frameworkCode=LLM
```

### Mitigations & Code Samples
```
GET  /api/v1/mitigations/{id}
GET  /api/v1/mitigations/{id}/code-samples
GET  /api/v1/code-samples?language=JAVA
```

### Admin CRUD (JWT — rola ADMIN)
```
POST   /api/v1/admin/threats                    — sanityzacja OwaspJavaHtmlSanitizer
PUT    /api/v1/admin/threats/{id}
DELETE /api/v1/admin/threats/{id}
POST   /api/v1/admin/code-samples
PUT    /api/v1/admin/code-samples/{id}
```

### Health & Ops
```
GET  /api/v1/actuator/health
GET  /api/v1/actuator/metrics/content.integrity
```

---

## 8. Angular Component & Route Structure

```
AppShellComponent  (mat-sidenav-container + AppShell i18n)
│
├── mat-sidenav  (navigation)
│   ├── mat-nav-list: Dashboard, Frameworks, Threats, Matrix, Search, About
│   └── LanguageToggleComponent (mat-button-toggle-group  PL | EN)
│
├── mat-toolbar  (top bar)
│   ├── SearchBarComponent  (mat-form-field + mat-autocomplete)
│   ├── DarkModeToggleComponent  (mat-slide-toggle → uiStore.darkMode Signal)
│   └── LanguageToggleComponent
│
└── <router-outlet>   (lazy-loaded via loadComponent / loadChildren)

Routes:
  /                               → DashboardComponent
  /frameworks                     → FrameworkListComponent       (mat-grid-list)
  /frameworks/:code               → FrameworkDetailComponent     (mat-expansion-panel)
  /frameworks/frontend-security   → FrontendSecurityComponent    (US-12)
  /frameworks/llm-security        → LlmSecurityComponent         (US-13)
  /frameworks/agentic-ai          → AgenticAiComponent           (US-14)
  /frameworks/stride              → StrideCatalogueComponent     (US-15, mat-accordion)
  /frameworks/ml-security         → MlSecurityComponent          (US-16)
  /frameworks/mobile-security     → MobileSecurityComponent      (US-17)
  /frameworks/devops-security     → DevOpsSecurityComponent      (US-18)
  /threats                        → ThreatBrowserComponent       (mat-table + mat-paginator)
  /threats/:id                    → ThreatDetailComponent        (mat-tab-group 4 zakładek)
  /matrix                         → MatrixComponent
  /matrix/llm                     → LlmMatrixComponent           (US-13)
  /matrix/agentic                 → AgenticMatrixComponent       (US-14)
  /matrix/mobile-vs-web           → MobileVsWebMatrixComponent   (US-17)
  /stride-heatmap                 → StrideHeatmapComponent       (AuthGuard, US-15)
  /coverage                       → CoverageComponent            (ECharts)
  /search                         → SearchResultsComponent       (US-06)
  /about                          → AboutComponent

Shared Components (src/app/shared/components/):
  ThreatCardComponent             — mat-card, severity color bar, STRIDE mat-chips, OnPush
  CornucopiaCardComponent         — mat-card, suit badge, value circle, OWASP ref chips, OnPush
  CodeSamplePanelComponent        — mat-tab-group × 5 languages, LazyPrismDirective
  BotWarningDialogComponent       — MatDialog "Rozumiem ryzyko" (US-18, localStorage flag)
  StrideHeatmapComponent          — ngx-echarts heatmap (US-05, US-15)
  MatrixTableComponent            — mat-table sticky columns
  LlmMatrixComponent              — macierz LLM Top 10 × Cornucopia (US-13)
  LanguageToggleComponent         — mat-button-toggle-group PL | EN (US-11)
  SeverityBadgeComponent          — mat-chip colored by severity enum
  OwaspRefChipListComponent       — mat-chip-set z linkami OWASP

Angular Services (src/app/core/services/):
  FrameworkService                — /api/v1/frameworks
  ThreatService                   — /api/v1/threats
  CardSuitService                 — /api/v1/threats?suit=*
  MatrixService                   — /api/v1/matrix/*
  SearchService                   — /api/v1/search
  ExportService                   — /api/v1/export
  LocaleService                   — ngx-translate + localStorage tv_locale
  AuthService                     — JWT, login, token refresh

Guards (src/app/core/guards/):
  AuthGuard                       — chroni /stride-heatmap i /admin/**
  AdminGuard                      — chroni /admin/**

Interceptors (src/app/core/interceptors/):
  AuthInterceptor                 — Authorization: Bearer <token>
  LocaleInterceptor               — Accept-Language: pl|en (walidowany)

NgRx Signals Store (src/app/store/):
  frameworksStore                 — frameworks signal slice
  threatsStore                    — threats, filters, pagination
  cardSuitsStore                  — cornucopia card suits
  searchStore                     — query + results
  uiStore                         — darkMode, locale
```

---

## 9. Code Sample Strategy

Każde zagrożenie ma co najmniej jedną mitigację z 5 próbkami kodu (jedna na język). Karty Cornucopia mają co najmniej jedną próbkę pokazującą bezpieczny wzorzec.

```
CodeSamplePanelComponent — mat-tab-group:
  [Python]  [Java]  [Go]  [Scala]  [Lua]

Każda zakładka — wewnętrzny mat-tab-group:
  [Attack Demo]  — mat-card border-left red + badge PODATNY  (nigdy nie uruchamiany server-side)
  [Defense]      — mat-card border-left green + badge BEZPIECZNY
```

| Język | Główny framework |
|---|---|
| Python | FastAPI 0.110, SQLAlchemy 2.0, Pydantic v2 |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | Gin 1.9, pgx v5, net/http |
| Scala | Akka HTTP 10.5, Slick 3.5, ZIO 2 |
| Lua | OpenResty / NGINX Lua, LuaSQL |

---

## 10. Security Data Coverage Plan

### OWASP Web Top 10 (2021)
A01–A10 — wszystkie 10 zagrożeń  
Pokrycie przez karty Cornucopia: `VE` (Validation), `AT` (Authentication), `SM` (Session Management), `AZ` (Authorization), `CR` (Cryptography), `C` (Cornucopia)

### OWASP LLM Top 10 (2025)
LLM01–LLM10 — wszystkie 10 zagrożeń  
Pokrycie przez karty: talia `LLM` (Cornucopia Companion v1.0)  
Macierz: `/matrix/llm`

### OWASP Agentic AI Top 10 (2026)
AgentAI01–AgentAI10 — wszystkie 10 zagrożeń  
Pokrycie przez karty: talia `AAI` (Cornucopia Companion v1.0)  
Macierz: `/matrix/agentic`

### OWASP API Security Top 10
API1–API10 — wszystkie 10 zagrożeń (framework `OWASP_API` w DB)

### OWASP Top 10 Client-Side Security Risks
C01–C10 — wszystkie 10  
Pokrycie przez karty: talia `FRE` (Cornucopia Companion v1.0)

### OWASP Top 10 CI/CD Security Risks
CICD-SEC-01–10 — wszystkie 10  
Pokrycie przez karty: talia `DVO`

### OWASP Automated Threats (OAT)
OAT-001–OAT-021 — minimum 13  
Pokrycie przez karty: talia `BOT`

### OWASP MASVS 2.0
MASVS-STORAGE, MASVS-CRYPTO, MASVS-AUTH, MASVS-NETWORK, MASVS-PLATFORM, MASVS-CODE, MASVS-RESILIENCE  
Pokrycie przez karty: talie `PC, AA, NS, RS, CRM, CM` (Cornucopia Mobile App v1.1)  
Macierz: `/matrix/mobile-vs-web`

### STRIDE
6 kategorii: S, T, R, I, D, E  
Pokrycie przez karty: talie `SP, TA, RE, ID, DS, EP` (STRIDE EoP v5.0)  
Heatmapa: `/stride-heatmap`

### MITRE ATLAS
Minimum 15 technik: T0010, T0011, T0014, T0020, T0024, T0029, T0043, T0044, T0051, T0046  
Pokrycie przez karty: talie `EMR, EIR, EOR, EDR` (Elevation of MLSec v1.0)

### CompTIA Security+ SY0-701 / SecAI+ 2026
Minimum 20 tematów: Prompt Injection, Data Poisoning, Model Theft, Adversarial ML, Deepfakes, AI Red Teaming, Zero Trust, NIST AI RMF, NIS2/UKSC, AI-BOM, BYOD risks, Supply Chain AI

---

## 11. Cornucopia Content Pipeline

Pliki YAML kart (`data/cornucopia/*.yaml`) traktowane jako **aktywa bezpieczeństwa** — niemutowalne po załadowaniu, z weryfikacją SHA-256 przy każdym starcie.

```
data/cornucopia/
├── webapp-cards-3.0-en.yaml          → VE, AT, SM, AZ, CR, C  (OWASP Web)
├── companion-llm-cards-1.0-en.yaml   → LLM, FRE, DVO, BOT, CLD, AAI
├── mobileapp-cards-1.1-en.yaml       → PC, AA, NS, RS, CRM, CM
├── stride-eop-cards-5.0-en.yaml      → SP, TA, RE, ID, DS, EP
├── mlsec-cards-1.0-en.yaml           → EMR, EIR, EOR, EDR
└── translations/
    ├── pl.cards.json                  → polskie tłumaczenia (klucz: cardId)
    └── en.cards.json                  → angielskie wersje (źródło: YAML desc)

data/hashes.json                       → SHA-256 każdego pliku YAML
data/mitre-atlas-allowlist.json        → dozwolone kody technik T0xxx
data/ref-allowlists.json               → allowlisty: OWASP, MASVS, CICD-SEC, OAT
```

**Workflow zmian kart:**
1. PR do `data/cornucopia/*.yaml` → CODEOWNERS: @security-team (min. 2 zatwierdzenia)
2. CI job `yaml-content-integrity`: ajv schema validation + `CI_EXPLOIT_PATTERN` grep + `*RefValidator`
3. Po merge: `hash-generator` bot aktualizuje `data/hashes.json`
4. Startup Spring Boot: `ContentIntegrityVerifier` @PostConstruct → SHA-256 → `ContentIntegrityException` jeśli mismatch → aplikacja nie startuje

---

## 12. Angular Bundle Performance Strategy

| Bundle | Cel | Strategia |
|---|---|---|
| Initial chunk | < 600 KB gzip | Lazy load każdego feature (loadComponent) |
| Per-language Prism.js | < 30 KB per język | `LazyPrismDirective`: ładowany dopiero gdy zakładka aktywna |
| ECharts | ~200 KB | Importowany tylko w CoverageComponent + StrideHeatmapComponent |
| D3.js | ~60 KB | Importowany tylko w StrideCatalogueComponent server-side SVG |
| i18n JSON | ~15 KB per język | Ładowany przy starcie i cachowany przez ngx-translate |

**Angular budget config (angular.json):**
```json
"budgets": [
  { "type": "initial", "maximumWarning": "500kb", "maximumError": "600kb" },
  { "type": "anyComponentStyle", "maximumWarning": "4kb", "maximumError": "8kb" }
]
```

**OnPush across all components** — zero `Default` change detection in production code. CI lint rule enforces this.

---

## 13. Abuse Cases Summary

| ID | Scenariusz | Wektor | Kontrola | Test |
|---|---|---|---|---|
| AC-01 | SQL Injection w filtrze `?q=` | VEK (webapp) → A03:2021 | JPA named params | `ThreatFilterSQLInjectionTest` |
| AC-02 | JWT tampering — modyfikacja payload | SPK (STRIDE) → A07:2021 | RS256 podpis | `JwtValidationTest` |
| AC-03 | Mass enumeration bez auth | BOT suit → OAT-011 | Bucket4j 60/min | `RateLimitIT` |
| AC-04 | XSS w Angular template | FRE suit → A03:2021 | Angular DomSanitizer, strict | `CornucopiaCardXSSTest` |
| AC-05 | IDOR — dostęp do cudzych zakładek | AZK (webapp) → A01:2021 | User-scoped queries | `BookmarkAuthorizationIT` |
| AC-06 | ReDoS via malicious search regex | VE suit → A03:2021 | Query length limit 200 chars | `SearchReDoSTest` |
| AC-07 | CSV injection w eksporcie | FRE4 → A03:2021 | Apache Commons CSV quote-all | `CsvInjectionIT` |
| AC-08 | Clickjacking `/stride-heatmap` | FREX → Client-Side C05 | X-Frame-Options DENY | ZAP headerscan |
| AC-09 | Bot scraping kart | BOTK → OAT-011 | Bucket4j 429 | `BotScrapingRateLimitIT` |
| AC-10 | XSS przez admin update opisu karty | FRE4 → A03:2021 | OWASP Java HTML Sanitizer | `CardDescriptionXSSIT` |
| AC-11 | YAML file tampering w CI/CD | DVO8 → A08:2021 | ContentIntegrityVerifier | `YamlIntegrityVerifierTest` |
| AC-12 | Fałszywy MITRE ATLAS ID w karcie | EMRX → allowlist bypass | MitreAtlasRefValidator | `MitreAtlasRefValidatorTest` |
| AC-13 | Credential stuffing via BOT endpoint | BOTX → OAT-008 | Bucket4j + alert SEC-007 | `CredentialStuffingRateLimitIT` |
| AC-14 | SVG injection w diagramie AAI | AAI suit → A03:2021 | Server-side SVG + CSP | `SvgInjectionTest` |
| AC-15 | BotWarningDialog bypass (direct URL) | BOTK → OAT-011 | AuthGuard + localStorage flag | `BotWarningBypassTest.cy.ts` |

---

## 14. Risk Register

| Ryzyko | Mitigacja |
|---|---|
| Angular bundle zbyt duży | Lazy loading per feature, Prism.js lazy, budgets w angular.json |
| Cross-references niespójne | Encja `CrossReference` z enum `relationshipType` |
| Próbki kodu nieaktualne | Pole `version` na `CodeSample`; admin UI do aktualizacji |
| Wyszukiwanie wolne | `tsvector` indeks PostgreSQL na title+description |
| YAML zmodyfikowany złośliwie | `ContentIntegrityVerifier` SHA-256 + CODEOWNERS 2 zatwierdzenia |
| Fałszywe OWASP/MITRE ID | `*RefValidator` server-side allowlisty |
| XSS przez admin update karty | OWASP Java HTML Sanitizer + Angular DomSanitizer |
| Bot scraping całej bazy kart | Bucket4j 60 req/min per IP + Loki alert SEC-007 |
| Clickjacking heatmapy STRIDE | `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` |
| SVG injection diagramy AAI | Server-side SVG rendering, DomSanitizer, CSP blok `<script>` |
| Angular strict mode naruszenia | `strict: true` w tsconfig.json, `ng build` fail w CI |
| Nieaktualne zależności npm/Maven | OWASP Dependency Check + npm audit + Trivy w każdym PR |

---

## 15. Directory Layout

```
app02_angular/
├── PLAN.md
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
├── backend/
│   ├── pom.xml
│   └── src/
│       ├── main/java/com/threatview/
│       │   ├── ThreatViewApplication.java
│       │   ├── config/
│       │   │   ├── SecurityConfig.java
│       │   │   └── RateLimitConfig.java            ← Bucket4j
│       │   ├── controller/
│       │   │   ├── FrameworkController.java
│       │   │   ├── ThreatController.java
│       │   │   ├── CardSuitController.java          ← Cornucopia suits
│       │   │   ├── MatrixController.java
│       │   │   ├── SearchController.java
│       │   │   ├── ExportController.java
│       │   │   └── AdminController.java
│       │   ├── service/
│       │   │   ├── ThreatService.java
│       │   │   ├── FrontendThreatService.java       ← FRE
│       │   │   ├── LlmThreatService.java            ← LLM
│       │   │   ├── AgenticThreatService.java        ← AAI
│       │   │   ├── StrideThreatService.java         ← STRIDE EoP
│       │   │   ├── MlSecThreatService.java          ← MLSec
│       │   │   ├── MobileSecThreatService.java      ← Mobile MAS
│       │   │   ├── DevOpsThreatService.java         ← DVO + BOT
│       │   │   └── LocalizationService.java         ← i18n
│       │   ├── integrity/
│       │   │   ├── ContentIntegrityVerifier.java    ← @PostConstruct SHA-256
│       │   │   ├── YamlCardLoader.java
│       │   │   └── validator/
│       │   │       ├── OwaspRefValidator.java
│       │   │       ├── MitreAtlasRefValidator.java
│       │   │       ├── MavsRefValidator.java
│       │   │       ├── CicdSecRefValidator.java
│       │   │       └── OatRefValidator.java
│       │   ├── repository/
│       │   ├── entity/
│       │   │   ├── Framework.java
│       │   │   ├── Threat.java
│       │   │   ├── ThreatTranslation.java
│       │   │   ├── CornucopiaCard.java
│       │   │   ├── Mitigation.java
│       │   │   ├── CodeSample.java
│       │   │   ├── CrossReference.java
│       │   │   └── ContentHash.java
│       │   ├── dto/
│       │   └── security/
│       ├── main/resources/
│       │   ├── application.yml
│       │   └── db/migration/                        ← Flyway V1..V20
│       └── test/
│
├── frontend/
│   ├── angular.json                                 ← budgets, lazy routes
│   ├── package.json
│   ├── tsconfig.json                                ← strict: true, strictTemplates: true
│   ├── jest.config.ts
│   └── src/
│       ├── main.ts
│       ├── app/
│       │   ├── app.config.ts                        ← provideRouter, provideHttpClient,
│       │   │                                          provideAnimations, provideTranslateService
│       │   ├── app.routes.ts                        ← lazy loadComponent definitions
│       │   ├── core/
│       │   │   ├── guards/
│       │   │   │   ├── auth.guard.ts
│       │   │   │   └── admin.guard.ts
│       │   │   ├── interceptors/
│       │   │   │   ├── auth.interceptor.ts
│       │   │   │   └── locale.interceptor.ts
│       │   │   └── services/
│       │   │       ├── framework.service.ts
│       │   │       ├── threat.service.ts
│       │   │       ├── card-suit.service.ts
│       │   │       ├── matrix.service.ts
│       │   │       ├── search.service.ts
│       │   │       ├── export.service.ts
│       │   │       ├── locale.service.ts
│       │   │       └── auth.service.ts
│       │   ├── shared/
│       │   │   ├── components/
│       │   │   │   ├── threat-card/
│       │   │   │   ├── cornucopia-card/
│       │   │   │   ├── code-sample-panel/
│       │   │   │   ├── bot-warning-dialog/
│       │   │   │   ├── stride-heatmap/
│       │   │   │   ├── matrix-table/
│       │   │   │   ├── llm-matrix/
│       │   │   │   ├── language-toggle/
│       │   │   │   ├── severity-badge/
│       │   │   │   └── owasp-ref-chip-list/
│       │   │   ├── models/
│       │   │   │   ├── framework.model.ts
│       │   │   │   ├── threat.model.ts
│       │   │   │   ├── cornucopia-card.model.ts
│       │   │   │   ├── mitigation.model.ts
│       │   │   │   └── code-sample.model.ts
│       │   │   ├── pipes/
│       │   │   │   ├── truncate.pipe.ts
│       │   │   │   ├── severity-color.pipe.ts
│       │   │   │   └── oat-label.pipe.ts
│       │   │   └── directives/
│       │   │       ├── highlight.directive.ts
│       │   │       └── lazy-prism.directive.ts
│       │   ├── features/
│       │   │   ├── dashboard/
│       │   │   ├── frameworks/
│       │   │   ├── threats/
│       │   │   ├── suits/
│       │   │   │   ├── frontend-security/           ← US-12
│       │   │   │   ├── llm-security/                ← US-13
│       │   │   │   ├── agentic-ai/                  ← US-14
│       │   │   │   ├── stride-catalogue/            ← US-15
│       │   │   │   ├── ml-security/                 ← US-16
│       │   │   │   ├── mobile-security/             ← US-17
│       │   │   │   └── devops-security/             ← US-18
│       │   │   ├── matrix/
│       │   │   ├── stride-heatmap/
│       │   │   ├── coverage/
│       │   │   └── search/
│       │   └── store/
│       │       ├── frameworks.store.ts
│       │       ├── threats.store.ts
│       │       ├── card-suits.store.ts
│       │       ├── search.store.ts
│       │       └── ui.store.ts
│       ├── assets/
│       │   └── i18n/
│       │       ├── pl.json                          ← UI strings PL (plain text only)
│       │       └── en.json                          ← UI strings EN (plain text only)
│       └── styles/
│           ├── theme.scss                           ← Angular Material custom theme (indigo-amber)
│           └── styles.scss
│
├── data/
│   ├── owasp_web_top10.json
│   ├── owasp_llm_top10.json
│   ├── owasp_agentic_top10.json
│   ├── mitre_atlas.json
│   ├── comptia_secai.json
│   ├── cornucopia/
│   │   ├── webapp-cards-3.0-en.yaml
│   │   ├── companion-llm-cards-1.0-en.yaml
│   │   ├── mobileapp-cards-1.1-en.yaml
│   │   ├── stride-eop-cards-5.0-en.yaml
│   │   ├── mlsec-cards-1.0-en.yaml
│   │   └── translations/
│   │       ├── pl.cards.json
│   │       └── en.cards.json
│   ├── hashes.json
│   ├── mitre-atlas-allowlist.json
│   ├── ref-allowlists.json
│   └── code_samples/
│       ├── python/
│       ├── java/
│       ├── go/
│       ├── scala/
│       └── lua/
│
├── e2e/
│   ├── cypress.config.ts
│   └── cypress/e2e/
│       ├── us01-framework-browser.cy.ts
│       ├── us02-threat-filter.cy.ts
│       ├── us03-threat-detail.cy.ts
│       ├── us04-cross-reference.cy.ts
│       ├── us05-stride-heatmap.cy.ts
│       ├── us06-global-search.cy.ts
│       ├── us07-export.cy.ts
│       ├── us08-atlas-timeline.cy.ts
│       ├── us09-scala-code.cy.ts
│       ├── us10-lua-code.cy.ts
│       ├── us11-language-switch.cy.ts
│       ├── us12-frontend-security.cy.ts
│       ├── us13-llm-security.cy.ts
│       ├── us14-agentic-ai.cy.ts
│       ├── us15-stride.cy.ts
│       ├── us16-ml-security.cy.ts
│       ├── us17-mobile-security.cy.ts
│       └── us18-devops-security.cy.ts
│
└── docker-compose.yml
```

---

## 16. User Stories — Kompletna Lista

| ID | Rola | Potrzeba | Cel |
|---|---|---|---|
| US-01 | security engineer | przeglądać katalog frameworków bezpieczeństwa | mieć jeden punkt dostępu do wszystkich standardów |
| US-02 | security engineer | filtrować zagrożenia wg frameworku, severity, STRIDE, tagu, q | szybko znaleźć zagrożenia istotne dla projektu |
| US-03 | security engineer | widzieć szczegóły zagrożenia z mitigacjami i próbkami kodu | rozumieć jak wdrożyć ochronę |
| US-04 | CompTIA SecAI+ student | zobaczyć jak LLM01 Prompt Injection mapuje do MITRE ATLAS AML.T0051 | rozumieć zależności między frameworkami |
| US-05 | security trainer | wyświetlić heatmapę STRIDE na projektorze | wizualnie wyjaśnić pokrycie STRIDE na warsztatach |
| US-06 | pentester | wyszukać "deepfake" i znaleźć wszystkie powiązane zagrożenia | złożyć checklistę testów dla klienta |
| US-07 | team lead | wyeksportować przefiltrowaną listę zagrożeń do CSV | włączyć ją do rejestru ryzyk |
| US-08 | developer | zobaczyć timeline Kill Chain MITRE | rozumieć na jakiej fazie ataku działa każda technika ATLAS |
| US-09 | Scala developer | znaleźć próbki kodu dla ataków na łańcuch dostaw w Scala | zaimplementować SCA w potoku Scala |
| US-10 | Lua/OpenResty developer | zobaczyć przykłady Lua dla rate limiting zapobiegającego LLM DoS | skonfigurować guardrails NGINX dla proxy LLM API |
| US-11 | Polish-speaking student | przełączyć całą aplikację z angielskiego na polski jednym kliknięciem | uczyć się opisów zagrożeń w ojczystym języku |
| US-12 | React/frontend developer | przeglądać karty Cornucopia FRE (DOM XSS, clickjacking, CORS, JWT forgery) z polskimi opisami i ref Client-Side Top 10 | mapować scenariusze ataków client-side na mitigacje w React |
| US-13 | ML engineer / AI architect | eksplorować OWASP LLM Top 10 2025 przez karty Cornucopia LLM z macierzą interaktywną | rozumieć prompt injection, data poisoning, excessive agency |
| US-14 | agentic AI developer | studiować OWASP Agentic AI Top 10 2026 przez karty AAI (excessive autonomy, unvalidated trust chains) | projektować human-in-the-loop safeguards dla agentów |
| US-15 | security architect / threat modeler | używać katalogu kart STRIDE EoP (6 suit) z interaktywną heatmapą per komponent systemu | prowadzić ustrukturyzowaną sesję threat modelingu |
| US-16 | data scientist / ML security engineer | przeglądać ryzyka ML (EMR/EIR/EOR/EDR) z referencjami MITRE ATLAS | identyfikować adversarial ML, model theft, data poisoning |
| US-17 | Android/iOS developer | zobaczyć zagrożenia OWASP MASVS przez karty Cornucopia Mobile App + tabelę MASVS vs Web | rozumieć jak kontrolki mobile różnią się od web |
| US-18 | DevSecOps engineer | przeglądać ryzyka supply chain (DVO) i wzorce botów (BOT) z ref OWASP CI/CD + rate limiting | chronić CI/CD i bronić się przed automatycznymi atakami |

---

## 17. Milestones & Acceptance Criteria

| Kamień | Deliverable | Ukończone gdy |
|---|---|---|
| M1 | Działający szkielet | `docker compose up` → Angular home + `/api/v1/frameworks` 200 JSON; `ng serve` działa |
| M2 | Pełne seedowanie danych | Wszystkie frameworki, zagrożenia, mitigacje w DB; API zwraca poprawne liczby |
| M3 | Próbki kodu kompletne | Każde zagrożenie ma 5 próbek w `CodeSamplePanelComponent` (Python/Java/Go/Scala/Lua) |
| M4 | Macierz + heatmapa | MatrixComponent renderuje się; ECharts heatmapa STRIDE pokazuje procenty pokrycia |
| M5 | Wyszukiwanie działa | Full-text search zwraca wyniki z podświetlonymi fragmentami w `HighlightPipe` |
| M6 | i18n działa | mat-button-toggle PL/EN działa; cały UI w obu językach; próbki kodu nie tłumaczone |
| M7 | Produkcyjny build | `ng build --configuration production` bundle initial < 600 KB gzip; Nginx 200; actuator/health 200 |
| M8 | Karty FRE + LLM + AAI | FrontendSecurityComponent, LlmSecurityComponent, AgenticAiComponent działają; macierze dostępne |
| M9 | STRIDE + MLSec | 78 kart STRIDE (6 × 13); ECharts heatmapa STRIDE; 52 karty MLSec (4 × 13) |
| M10 | Mobile + DevOps | MobileSecurityComponent, DevOpsSecurityComponent; tabela MASVS vs Web; BotWarningDialog |
| M11 | Integralność treści | ContentIntegrityVerifier GREEN; CI job yaml-content-integrity GREEN |
| M12 | Testy przechodzą | ≥ 195 testów; abuse cases AC-01–AC-15 GREEN; ZAP 0 High; Lighthouse ≥ 85; axe-core 0 Critical |
