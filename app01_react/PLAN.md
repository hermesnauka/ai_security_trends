# SecureVision 2026 — Application Development Plan

**Version:** 2.0  
**Date:** 2026-07-07  
**Status:** Living document — updated after each sprint planning session

---

## 1. Project Overview

**Name:** SecureVision 2026  
**Purpose:** An interactive reference and learning platform that maps security threats, vulnerabilities, and mitigations across six major frameworks — OWASP Web Top 10 (2021), OWASP LLM Top 10 (2025), OWASP API Security Top 10, OWASP Agentic AI Top 10 (2026), MITRE ATLAS (AI/ML adversarial techniques), and CompTIA Security+ SY0-701 / SecAI+ — and presents each threat with working sample code countermeasures in five languages: Python, Java (Spring Boot), Go, Scala, and Lua.

**Version 2.0 extension:** The platform additionally covers the full OWASP Cornucopia card catalogue — Website App Edition v3.0, Companion Edition v1.0 (LLM, AAI, FRE, DVO, BOT, CLD suits), Mobile App Edition v1.1, Microsoft STRIDE Elevation of Privilege v5.0, and Elevation of MLSec v1.0 — giving practitioners an interactive, card-based threat modeling reference aligned with SecureVision's existing framework content.

**UI languages:** Polish (default) and English — switch is persisted in `localStorage`.

---

## 2. Technology Stack

### Backend
| Layer | Technology | Version (2026) |
|---|---|---|
| Runtime | Java | 21 LTS |
| Framework | Spring Boot | 3.3.x |
| API style | REST (JSON) | — |
| Security | Spring Security 6 | JWT / OAuth2 |
| Persistence | PostgreSQL 16 | via Spring Data JPA |
| Cache | Redis 7 | Spring Cache |
| Build | Maven 3.9 | — |
| Docs | SpringDoc OpenAPI 3 | Swagger UI |
| DB migrations | Flyway | — |
| Testing | JUnit 5, Mockito, Testcontainers, RestAssured | — |
| Rate limiting | Bucket4j | — |
| Input sanitization | OWASP Java HTML Sanitizer | — |
| Integrity checks | Java MessageDigest (SHA-256) | — |

### Frontend
| Layer | Technology | Version (2026) |
|---|---|---|
| Runtime | Node 20 LTS | — |
| Framework | React | 18.x |
| Language | TypeScript | 5.x |
| Build | Vite | 5.x |
| State | Zustand | — |
| Router | React Router v6 | — |
| UI library | Shadcn/UI + Tailwind CSS | — |
| Syntax highlight | Shiki | — |
| Charts / diagrams | Recharts + D3.js (SVG) | — |
| i18n | react-i18next + i18next | — |
| Input sanitization | DOMPurify | 3.x |
| Testing | Vitest + React Testing Library + Playwright | — |
| Validation | Zod | — |
| MSW | Mock Service Worker | — |

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
Browser (React SPA)
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
   └── /*         ─────► React SPA bundle (Vite)
                           ├── pages/
                           │   ├── Dashboard
                           │   ├── FrameworkBrowser
                           │   ├── ThreatBrowser + Detail
                           │   ├── CardSuitBrowser (per suit)
                           │   ├── Matrix pages
                           │   ├── StrideHeatmap
                           │   └── GlobalSearch
                           └── components/
                               ├── ThreatCard / CornucopiaCard
                               ├── CodeSamplePanel
                               ├── StrideHeatmap
                               ├── MatrixTable
                               ├── LanguageToggle (i18n)
                               └── BotCardWarning

PostgreSQL 16  ◄── Spring Data JPA
Redis 7        ◄── Spring Cache
```

---

## 4. Data Model

### 4.1 Framework
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

### 4.2 Threat
```
Threat {
  id:            UUID
  frameworkId:   UUID     // FK → Framework
  code:          String   // "LLM01:2025", "A01:2021", "AML.T0051"
  title:         String
  severity:      Enum     // CRITICAL, HIGH, MEDIUM, LOW, INFO
  category:      String   // "Injection", "Access Control", "AI/ML", etc.
  description:   String
  attackVector:  String
  attackSurface: String
  stride:        Set<Enum> // S, T, R, I, D, E  (nullable for non-STRIDE items)
  cveReferences: List<String>
  tags:          List<String>
}
```

### 4.3 ThreatTranslation  *(i18n — US-11)*
```
ThreatTranslation {
  id:          UUID
  threatId:    UUID     // FK → Threat
  locale:      String   // "pl", "en"
  title:       String
  description: String
  attackVector: String
  category:    String
}
```

### 4.4 CornucopiaCard  *(Cornucopia card catalogue — US-12–US-18)*
```
CornucopiaCard {
  id:               UUID
  cardId:           String   // "FRE4", "LLMX", "EPK", "EDRK", "NSX"
  suitCode:         String   // "FRE", "LLM", "AAI", "DVO", "BOT", "CLD",
                             //  "VE", "AT", "SM", "AZ", "CR",
                             //  "PC", "AA", "NS", "RS", "CRM",
                             //  "SP", "TA", "RE", "ID", "DS", "EP",
                             //  "EMR", "EIR", "EOR", "EDR"
  suitName:         String   // "Frontend", "Large Language Models", "Agentic AI"…
  edition:          String   // "companion", "webapp", "mobileapp", "eop", "mlsec"
  value:            String   // "2"–"10", "J", "Q", "K", "A"
  isCritical:       Boolean  // true for J, Q, K
  descriptionEn:    String   // original English description from YAML
  descriptionPl:    String   // Polish translation
  owaspRefs:        List<String>  // ["A03:2021", "Client-Side C01"]
  mitreRefs:        List<String>  // ["MITRE ATLAS T0014"]
  mavsRefs:         List<String>  // ["MASVS-NETWORK-2"]
  cicdSecRefs:      List<String>  // ["CICD-SEC-03"]
  oatRefs:          List<String>  // ["OAT-011"]
  agentAiRefs:      List<String>  // ["AgentAI07"]
  contentHash:      String   // SHA-256 of descriptionEn — integrity check
}
```

### 4.5 Mitigation
```
Mitigation {
  id:                   UUID
  threatId:             UUID    // FK → Threat  (or FK → CornucopiaCard via cardId)
  title:                String
  description:          String
  mitigationType:       Enum    // PREVENTIVE, DETECTIVE, CORRECTIVE, COMPENSATING
  implementationEffort: Enum    // LOW, MEDIUM, HIGH
  effectiveness:        Enum    // PARTIAL, SIGNIFICANT, FULL
}
```

### 4.6 CodeSample
```
CodeSample {
  id:            UUID
  mitigationId:  UUID    // FK → Mitigation
  language:      Enum    // PYTHON, JAVA, GO, SCALA, LUA
  sampleType:    Enum    // ATTACK_DEMO, DEFENSE
  title:         String
  description:   String
  codeSnippet:   String  // full runnable / educational snippet
  frameworkHint: String  // "Spring Boot 3.3", "FastAPI 0.110", "Gin 1.9", "Akka HTTP", "OpenResty"
  version:       String  // language/framework version annotation
}
```

### 4.7 CrossReference
```
CrossReference {
  id:               UUID
  sourceThreatId:   UUID    // FK → Threat (or cardId → CornucopiaCard)
  targetThreatId:   UUID
  relationshipType: Enum    // EQUIVALENT, RELATED, PARENT_CHILD, MAPS_TO
  description:      String
}
```

### 4.8 ContentHash  *(YAML integrity — Phase 8 SSDLC)*
```
ContentHash {
  id:          UUID
  fileName:    String   // "llm-cards.yaml"
  sha256Hash:  String
  verifiedAt:  Instant
  isValid:     Boolean
}
```

---

## 5. Development Phases

### Phase 1 — Foundation (Sprints 1–2, Weeks 1–4)
Pokrycie: US-01, US-02, US-03

- [ ] Szkielet projektu: Spring Boot 3.3 + React 18 / TypeScript + Vite
- [ ] Docker Compose: PostgreSQL 16 + Redis 7 + backend + frontend + Nginx
- [ ] Schematy bazy danych + migracje Flyway (entities 4.1–4.7)
- [ ] Seedowanie danych: OWASP Web Top 10, OWASP LLM Top 10, MITRE ATLAS, CompTIA SecAI+
- [ ] REST API: `GET /api/v1/frameworks`, `GET /api/v1/threats` z paginacją
- [ ] Spring Security: JWT auth (rola admin do CRUD)
- [ ] SpringDoc OpenAPI 3 pod `/swagger-ui.html`
- [ ] React: strona główna Dashboard (statystyki, szybkie wyszukiwanie)
- [ ] React: strona `/frameworks` — kafelki frameworków

### Phase 2 — Core Features (Sprints 3–4, Weeks 5–8)
Pokrycie: US-02, US-03, US-04, US-05

- [ ] `GET /api/v1/threats` z filtrami: framework, severity, STRIDE, category, tag, q
- [ ] `GET /api/v1/threats/{id}` ze zagnieżdżonymi mitigacjami i próbkami kodu
- [ ] `GET /api/v1/cross-references` — tabela mapowania między frameworkami
- [ ] React: strona `/threats` — przeglądarka zagrożeń z panelem filtrów
- [ ] React: strona `/threats/:id` — zakładki: Przegląd | Wektory ataku | Mitigacje | Kod | Powiązania
- [ ] React: `MitigationPanel` + `CodeSamplePanel` (zakładki językowe)
- [ ] Podświetlanie składni (Shiki, leniwe ładowanie paczek językowych)
- [ ] Strona `/matrix` — tabela mapowania OWASP ↔ MITRE ATLAS ↔ CompTIA
- [ ] STRIDE badge + legenda wizualna

### Phase 3 — Content & Code Samples (Sprints 5–6, Weeks 9–12)
Pokrycie: US-04, US-08, US-09, US-10

- [ ] Próbki kodu dla każdego zagrożenia × 5 języków (Python, Java, Go, Scala, Lua)
- [ ] Każda próbka: zakładka Attack Demo (bordowy obramowanie + etykieta `PODATNY`) + zakładka Defense
- [ ] `BotCardWarning` — dialog ostrzeżenia przy kopiowaniu kodu ataku
- [ ] MITRE ATLAS Kill-Chain timeline (Recharts)
- [ ] Strona `/coverage` — heatmapa pokrycia STRIDE per framework
- [ ] Tag cloud do przeglądania po kategorii

### Phase 4 — Advanced Features (Sprints 6–7, Weeks 11–14)
Pokrycie: US-05, US-06, US-07, US-08

- [ ] Wyszukiwanie pełnotekstowe przez zagrożenia + mitigacje + próbki kodu (`tsvector` PostgreSQL)
- [ ] Strona `/search` — wyniki z podświetlonymi fragmentami
- [ ] Export do CSV / PDF (US-07)
- [ ] Zakładki / ulubione na użytkownika (localStorage fallback)
- [ ] Dark mode toggle
- [ ] React: `GlobalSearch` — globalny pasek wyszukiwania w Navbar

### Phase 5 — i18n Polish ↔ English (Sprint 8, Weeks 15–16)
Pokrycie: US-11

- [ ] Encja `ThreatTranslation` — treść PL/EN w bazie danych
- [ ] `Accept-Language` header na wszystkich endpointach API (pl/en, fallback en)
- [ ] `Content-Language` nagłówek odpowiedzi
- [ ] `react-i18next` — pliki `pl.json` / `en.json`, klucze dla całego UI
- [ ] `LanguageToggle` w Navbar — zapis w `localStorage` (klucz `sv_locale`)
- [ ] Próbki kodu NIGDY nie tłumaczone — tylko treść interfejsu
- [ ] Build-time walidacja parzystości kluczy i18n (`I18nKeysValidatorTest`)

### Phase 6 — Cornucopia: FRE + LLM + AAI (Sprint 9, Weeks 17–18)
Pokrycie: US-12, US-13, US-14

- [ ] Encja `CornucopiaCard` + migracja Flyway
- [ ] YAML loader: ładowanie kart z `data/cornucopia/*.yaml` przy starcie aplikacji
- [ ] `ContentIntegrityVerifier` (@PostConstruct) — weryfikacja SHA-256 plików YAML
- [ ] `OwaspRefValidator` — allowlist identyfikatorów OWASP
- [ ] API: `GET /api/v1/threats?suit=FRE` itp., `GET /api/v1/threats/{cardId}`
- [ ] React: `/frameworks/frontend-security` — przeglądarka kart FRE (US-12)
- [ ] React: `/frameworks/llm-security` + `/matrix/llm` — karty LLM + macierz LLM Top 10 (US-13)
- [ ] React: `/frameworks/agentic-ai` + `/matrix/agentic` — karty AAI + macierz Agentic (US-14)
- [ ] `DOMPurify` zintegrowany w każdym komponencie renderującym opisy kart
- [ ] `AUTONOMY RISK` badge na kartach AAIK, AAIQ
- [ ] Rate limit Bucket4j: 60 req/min per IP na wszystkich `/api/v1/threats?suit=*`

### Phase 7 — Cornucopia: STRIDE EoP + MLSec (Sprint 10–11, Weeks 19–22)
Pokrycie: US-15, US-16

- [ ] `MitreAtlasRefValidator` — allowlist technik ATLAS z `data/mitre-atlas-allowlist.json`
- [ ] API: `GET /api/v1/threats/stride/categories`, `GET /api/v1/stride-heatmap` (JWT required)
- [ ] API: `GET /api/v1/threats/mlsec/categories`, filtry po `MITRE ATLAS`
- [ ] React: `/frameworks/stride` — 6 suit STRIDE × 13 kart każda (US-15)
- [ ] React: `/stride-heatmap` — interaktywna heatmapa STRIDE per komponent systemu
- [ ] Diagramy STRIDE renderowane server-side jako SVG (`D-12`)
- [ ] React: `/frameworks/ml-security` — 4 kategorie MLSec (US-16)
- [ ] `ML-SPECIFIC` badge na kartach EMR/EIR/EOR/EDR — odróżniony od OWASP Web
- [ ] X-Frame-Options: DENY na `/stride-heatmap` (ochrona przed clickjacking)

### Phase 8 — Cornucopia: Mobile + DevOps (Sprint 12–13, Weeks 23–26)
Pokrycie: US-17, US-18

- [ ] `MavsRefValidator` — allowlist OWASP MASVS 2.0
- [ ] `CicdSecRefValidator` — allowlist CICD-SEC-01–10
- [ ] `OatRefValidator` — allowlist OAT-001–021
- [ ] API: mobile suits (PC, AA, NS, RS, CRM, CM) + tabela porównania MASVS vs OWASP Web
- [ ] React: `/frameworks/mobile-security` + `/matrix/mobile-vs-web` (US-17)
- [ ] API: DVO (DevOps) + BOT (Automated Threats) suits
- [ ] React: `/frameworks/devops-security` — sekcje DVO i BOT (US-18)
- [ ] `BotCardWarning` — dialog "Rozumiem ryzyko" dla kart credential enumeration (BOTX, BOTJ)
- [ ] CI job `yaml-content-integrity`: schema validation + injection scan + hash update

### Phase 9 — Integration, Testing & Hardening (Sprints 14–16, Weeks 27–31)
Pokrycie: integracja US-01–US-18

- [ ] Testy jednostkowe: wszystkie klasy serwisów (JUnit 5 + Mockito) — ≥ 80% pokrycia
- [ ] Testy integracyjne: wszystkie endpointy REST (Testcontainers + PostgreSQL)
- [ ] Testy komponentów React (Vitest + RTL)
- [ ] Testy E2E (Playwright) — 18 user stories × 1+ scenariusz
- [ ] Abuse cases AC-01–AC-13 — wszystkie GREEN w CI
- [ ] DAST: OWASP ZAP full active scan wszystkich routów
- [ ] Audit dostępności (axe-core) — WCAG 2.1 AA
- [ ] Pomiar wydajności: < 200 ms dla zapytań listowych
- [ ] Produkcyjny Docker build + konfiguracja Nginx
- [ ] README z instrukcją szybkiego startu
- [ ] Loki alert SEC-007 + SEC-008, metryka `content_integrity_check_ok`

---

## 6. API Endpoint Map

### Framework & Threat (bazowe)
```
GET  /api/v1/frameworks                         — lista wszystkich frameworków
GET  /api/v1/frameworks/{code}                  — szczegóły frameworku + lista zagrożeń

GET  /api/v1/threats                            — lista zagrożeń
                                                  filtry: frameworkCode, severity, stride,
                                                          tag, q, suit, owaspRef, mitreRef
GET  /api/v1/threats/{id}                       — pojedyncze zagrożenie z mitigacjami
GET  /api/v1/threats/{id}/mitigations           — mitigacje dla zagrożenia
GET  /api/v1/threats/{id}/code-samples          — próbki kodu (wszystkie języki)
```

### Cornucopia Card Suits (US-12–US-18)
```
GET  /api/v1/threats?suit=FRE                   — karty Frontend (US-12)
GET  /api/v1/threats?suit=LLM                   — karty LLM (US-13)
GET  /api/v1/threats?suit=AAI                   — karty Agentic AI (US-14)
GET  /api/v1/threats/stride/categories          — 6 kategorii STRIDE (US-15)
GET  /api/v1/threats?suit=TA                    — karty Tampering (US-15, przykład)
GET  /api/v1/threats?suit=EMR                   — karty Model Risk (US-16)
GET  /api/v1/threats/mlsec/categories           — 4 kategorie MLSec (US-16)
GET  /api/v1/threats?suit=NS                    — karty Network & Storage (US-17)
GET  /api/v1/threats/mobile/suits               — 6 talii Mobile (US-17)
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
GET  /api/v1/cross-references?sourceCode=LLM01  — co mapuje do LLM01
GET  /api/v1/stats/coverage                     — dane JSON dla heatmapy pokrycia
```

### Search & Export
```
GET  /api/v1/search?q=prompt+injection          — globalny full-text search
GET  /api/v1/export?format=csv&frameworkCode=LLM — export zagrożeń do CSV
GET  /api/v1/export?format=pdf&frameworkCode=LLM — export zagrożeń do PDF
```

### Mitigations & Code Samples
```
GET  /api/v1/mitigations/{id}                   — szczegóły mitigacji
GET  /api/v1/mitigations/{id}/code-samples      — próbki kodu dla mitigacji
GET  /api/v1/code-samples?language=JAVA         — wszystkie próbki w języku Java
```

### Admin CRUD (JWT — rola ADMIN)
```
POST   /api/v1/admin/threats                    — dodaj zagrożenie / kartę
PUT    /api/v1/admin/threats/{id}               — aktualizuj (sanityzacja OwaspJavaHtmlSanitizer)
DELETE /api/v1/admin/threats/{id}               — usuń
POST   /api/v1/admin/code-samples               — dodaj próbkę kodu
PUT    /api/v1/admin/code-samples/{id}
```

### Health & Ops
```
GET  /api/v1/actuator/health                    — status aplikacji
GET  /api/v1/actuator/metrics/content.integrity — metryka integralności YAML
```

---

## 7. React Page Structure

```
/                               — Dashboard (statystyki, szybkie wyszukiwanie, news)
/frameworks                     — Kafelki wszystkich frameworków
/frameworks/:code               — Szczegóły frameworku + lista zagrożeń
/frameworks/frontend-security   — Przeglądarka kart FRE (US-12)
/frameworks/llm-security        — Przeglądarka kart LLM (US-13)
/frameworks/agentic-ai          — Przeglądarka kart AAI (US-14)
/frameworks/stride              — Katalog kart STRIDE EoP — 6 suit (US-15)
/frameworks/ml-security         — Przeglądarka kart MLSec (US-16)
/frameworks/mobile-security     — Przeglądarka kart Mobile MAS (US-17)
/frameworks/devops-security     — Przeglądarka kart DVO + BOT (US-18)

/threats                        — Przeglądarka zagrożeń (filtry, sortowanie)
/threats/:id                    — Szczegóły zagrożenia / karty
                                    zakładki: Przegląd | Mitigacje | Kod | Powiązania

/matrix                         — Główna tabela mapowania (OWASP ↔ MITRE ↔ CompTIA)
/matrix/llm                     — Macierz LLM Top 10 × karty Cornucopia (US-13)
/matrix/agentic                 — Macierz Agentic AI × LLM (US-14)
/matrix/mobile-vs-web           — Porównanie MASVS vs OWASP Web Top 10 (US-17)

/stride-heatmap                 — Interaktywna heatmapa STRIDE per komponent (US-15)
/coverage                       — Heatmapa pokrycia STRIDE per framework

/search?q=...                   — Wyniki globalnego wyszukiwania (US-06)
/about                          — Dokumentacja, źródła, licencje
```

---

## 8. Code Sample Strategy

Każde zagrożenie (Threat) ma co najmniej jedną mitigację. Każda mitigacja ma dokładnie 5 próbek kodu (jedna na język). Karty Cornucopia mają co najmniej jedną próbkę pokazującą bezpieczny wzorzec.

```
title: "Parameterized Queries — SQL Injection Defense"
sampleType: ATTACK_DEMO  |  DEFENSE
codeSnippet: |
  # PODATNY — nie używać w produkcji
  ...
  # BEZPIECZNY — właściwy wzorzec
  ...
frameworkHint: "Spring Data JPA 3.x"
version: "Java 21 / Spring Boot 3.3"
```

| Język | Główny framework / biblioteka |
|---|---|
| Python | FastAPI 0.110, SQLAlchemy 2.0, Pydantic v2 |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | Gin 1.9, pgx v5, net/http |
| Scala | Akka HTTP 10.5, Slick 3.5, ZIO 2 |
| Lua | OpenResty / NGINX Lua, LuaSQL |

---

## 9. Security Data Coverage Plan

### OWASP Web Top 10 (2021)
A01 Broken Access Control → A10 SSRF — wszystkie 10 zagrożeń  
Pokrycie przez karty: `AZ` (Authorization), `AT` (Authentication), `VE` (Validation), `CR` (Cryptography), `SM` (Session Management), `C` (Cornucopia)

### OWASP LLM Top 10 (2025)
LLM01 Prompt Injection → LLM10 Unbounded Consumption — wszystkie 10 zagrożeń  
Pokrycie przez karty: talia `LLM` (Cornucopia Companion)  
Macierz: `/matrix/llm` — 10 wierszy × karty

### OWASP Agentic AI Top 10 (2026)
AgentAI01–AgentAI10 — wszystkie 10 zagrożeń  
Pokrycie przez karty: talia `AAI` (Cornucopia Companion)  
Macierz: `/matrix/agentic` — porównanie z LLM Top 10

### OWASP API Security Top 10
API1 BOLA → API10 Unsafe Consumption — wszystkie 10 zagrożeń  
Pokrycie przez: dedykowany `OWASP_API` framework w bazie danych

### OWASP Top 10 Client-Side Security Risks
C01–C10 — wszystkie 10 zagrożeń  
Pokrycie przez karty: talia `FRE` (Frontend, Cornucopia Companion)

### OWASP Top 10 CI/CD Security Risks
CICD-SEC-01–CICD-SEC-10 — wszystkie 10  
Pokrycie przez karty: talia `DVO` (DevOps, Cornucopia Companion)

### OWASP Automated Threats (OAT)
OAT-001–OAT-021 — minimum 13 zagrożeń (pokrytych przez talie `BOT`)  
Pokrycie przez karty: talia `BOT` (Automated Threats, Cornucopia Companion)

### OWASP MASVS 2.0 (Mobile Application Security)
MASVS-STORAGE, MASVS-CRYPTO, MASVS-AUTH, MASVS-NETWORK, MASVS-PLATFORM, MASVS-CODE, MASVS-RESILIENCE  
Pokrycie przez karty: talie `PC, AA, NS, RS, CRM, CM` (Cornucopia Mobile App)

### STRIDE (Threat Modeling)
6 kategorii: Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege  
Pokrycie przez karty: talie `SP, TA, RE, ID, DS, EP` (STRIDE EoP v5.0)  
Heatmapa: `/stride-heatmap` — per komponent SecureVision

### MITRE ATLAS (AI/ML adversarial)
Minimum 15 technik:
- T0010 Model Theft, T0011 Model Inversion, T0014 Data Poisoning
- T0020 Backdoor ML Model, T0018 Backdoor ML Model
- T0024 Model Extraction, T0029 Denial of ML Service
- T0043 Adversarial Perturbation, T0044 Craft Adversarial Data
- T0051 Prompt Injection, T0046 Spamming ML System  
Pokrycie przez karty: talie `EMR, EIR, EOR, EDR` (Elevation of MLSec)

### CompTIA Security+ SY0-701 / SecAI+
Minimum 20 tematów z zakresu: Prompt Injection, Data Poisoning, Model Theft, Adversarial ML, Deepfakes, AI Red Teaming, Zero Trust, NIST AI RMF, NIS2/UKSC, AI-BOM

---

## 10. Cornucopia Card Content Pipeline

Sześć plików YAML kart Cornucopia (`data/cornucopia/*.yaml`) jest traktowanych jako **aktywa bezpieczeństwa** — niemutowalne po załadowaniu, z weryfikacją SHA-256 przy każdym starcie aplikacji.

```
data/cornucopia/
├── webapp-cards-3.0-en.yaml          → karty VE, AT, SM, AZ, CR, C (OWASP Web)
├── companion-llm-cards-1.0-en.yaml   → karty LLM, FRE, DVO, BOT, CLD, AAI
├── mobileapp-cards-1.1-en.yaml       → karty PC, AA, NS, RS, CRM, CM
├── stride-eop-cards-5.0-en.yaml      → karty SP, TA, RE, ID, DS, EP
├── mlsec-cards-1.0-en.yaml           → karty EMR, EIR, EOR, EDR
└── translations/
    ├── pl.cards.json                  → polskie tłumaczenia kart (klucz: cardId)
    └── en.cards.json                  → angielskie wersje (źródło: YAML desc)

data/hashes.json                       → SHA-256 każdego pliku YAML (aktualizowany przez CI)
data/mitre-atlas-allowlist.json        → dozwolone kody technik MITRE ATLAS
data/ref-allowlists.json               → allowlisty: OWASP, MASVS, CICD-SEC, OAT
```

**Workflow zmiany treści kart:**
1. PR z modyfikacją YAML → CODEOWNERS: @security-team (wymagane 2 zatwierdzenia)
2. CI job `yaml-content-integrity`: schema validation + grep injection patterns + *RefValidator
3. Po merge: `hash-generator` bot aktualizuje `data/hashes.json`
4. Przy starcie aplikacji: `ContentIntegrityVerifier` weryfikuje SHA-256 — niezgodność → fail-secure

---

## 11. Risk Register for the Build

| Ryzyko | Mitigacja |
|---|---|
| Duży zbiór próbek kodu jest pracochłonny | Seedowanie przez JSON/YAML, nie hardkodowane Java |
| Cross-references stają się niespójne | Encja `CrossReference` z enum typem relacji |
| Próbki kodu stają się nieaktualne | Pole `version` na `CodeSample`; admin UI do aktualizacji |
| Bundle React zbyt duży | Lazy-load paczek językowych Shiki; ≤ 30 KB gzip na i18n |
| Wyszukiwanie wolne przy dużej skali | Indeksy PostgreSQL `tsvector` na polach tekstowych |
| Treść kart YAML zmodyfikowana złośliwie | `ContentIntegrityVerifier` + SHA-256 + CODEOWNERS |
| Fałszywe identyfikatory OWASP/MITRE | `*RefValidator` klasy z server-side allowlistami |
| XSS przez admin update opisu karty | `OwaspJavaHtmlSanitizer` (backend) + `DOMPurify` (frontend) |
| Scraping całej bazy kart przez boty | Bucket4j rate limit: 60 req/min per IP; alert SEC-007 |
| Clickjacking heatmapy STRIDE | `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` |
| SVG injection w diagramach agentów | Diagramy AAI renderowane server-side + blokada `<script>` w CSP |

---

## 12. Directory Layout

```
app01_react/
├── PLAN.md                           ← ten plik
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
├── backend/
│   ├── pom.xml
│   └── src/
│       ├── main/java/com/securevision/
│       │   ├── SecureVisionApplication.java
│       │   ├── config/
│       │   │   ├── SecurityConfig.java
│       │   │   └── RateLimitConfig.java          ← Bucket4j
│       │   ├── controller/
│       │   │   ├── FrameworkController.java
│       │   │   ├── ThreatController.java
│       │   │   ├── CardSuitController.java        ← Cornucopia suits
│       │   │   ├── MatrixController.java
│       │   │   ├── SearchController.java
│       │   │   ├── ExportController.java
│       │   │   └── AdminController.java
│       │   ├── service/
│       │   │   ├── ThreatService.java
│       │   │   ├── FrontendThreatService.java     ← FRE cards
│       │   │   ├── LlmThreatService.java          ← LLM cards
│       │   │   ├── AgenticThreatService.java      ← AAI cards
│       │   │   ├── StrideThreatService.java       ← STRIDE EoP
│       │   │   ├── MlSecThreatService.java        ← MLSec cards
│       │   │   ├── MobileSecThreatService.java    ← Mobile MAS
│       │   │   ├── DevOpsThreatService.java       ← DVO + BOT
│       │   │   └── LocalizationService.java       ← i18n
│       │   ├── integrity/
│       │   │   ├── ContentIntegrityVerifier.java  ← SHA-256 YAML check
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
│       │   └── db/migration/                      ← Flyway V1..V20
│       └── test/
│
├── frontend/
│   ├── package.json
│   ├── vite.config.ts
│   ├── index.html
│   └── src/
│       ├── main.tsx
│       ├── App.tsx
│       ├── i18n/
│       │   ├── pl.json                            ← UI strings PL
│       │   └── en.json                            ← UI strings EN
│       ├── pages/
│       │   ├── Dashboard.tsx
│       │   ├── Frameworks.tsx
│       │   ├── FrameworkDetail.tsx
│       │   ├── ThreatBrowser.tsx
│       │   ├── ThreatDetail.tsx
│       │   ├── suits/
│       │   │   ├── FrontendSecurity.tsx           ← US-12
│       │   │   ├── LlmSecurity.tsx                ← US-13
│       │   │   ├── AgenticAi.tsx                  ← US-14
│       │   │   ├── StrideCatalogue.tsx             ← US-15
│       │   │   ├── MlSecurity.tsx                 ← US-16
│       │   │   ├── MobileSecurity.tsx             ← US-17
│       │   │   └── DevOpsSecurity.tsx             ← US-18
│       │   ├── matrix/
│       │   │   ├── MainMatrix.tsx
│       │   │   ├── LlmMatrix.tsx
│       │   │   ├── AgenticMatrix.tsx
│       │   │   └── MobileVsWebMatrix.tsx
│       │   ├── StrideHeatmap.tsx
│       │   ├── Coverage.tsx
│       │   ├── GlobalSearch.tsx
│       │   └── About.tsx
│       ├── components/
│       │   ├── ThreatCard.tsx
│       │   ├── CornucopiaCard.tsx
│       │   ├── CodeSamplePanel.tsx
│       │   ├── BotCardWarning.tsx                 ← US-18
│       │   ├── StrideHeatmap.tsx
│       │   ├── MatrixTable.tsx
│       │   ├── LlmThreatMatrix.tsx
│       │   ├── DevOpsThreatList.tsx
│       │   ├── LanguageToggle.tsx                 ← US-11
│       │   └── NavBar.tsx
│       ├── store/
│       ├── api/
│       └── types/
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
│   ├── hashes.json                                ← SHA-256 kart YAML
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
│   ├── playwright.config.ts
│   └── *.spec.ts                                  ← 18 plików E2E (US-01–US-18)
│
└── docker-compose.yml
```

---

## 13. User Stories — Kompletna Lista

| ID | Rola | Potrzeba | Cel |
|---|---|---|---|
| US-01 | security engineer | przeglądać katalog frameworków bezpieczeństwa | mieć jeden punkt dostępu do wszystkich standardów |
| US-02 | security engineer | filtrować zagrożenia według frameworku, severity, STRIDE, tagu | szybko znaleźć zagrożenia istotne dla mojego projektu |
| US-03 | security engineer | widzieć szczegóły zagrożenia z mitigacjami i próbkami kodu | rozumieć jak wdrożyć ochronę |
| US-04 | CompTIA SecAI+ student | zobaczyć jak LLM01 Prompt Injection mapuje do MITRE ATLAS AML.T0051 | rozumieć zależności między frameworkami |
| US-05 | security trainer | wyświetlić heatmapę STRIDE na projektorze | wizualnie wyjaśnić pokrycie STRIDE na warsztatach |
| US-06 | pentester | wyszukać "deepfake" i znaleźć wszystkie powiązane zagrożenia z obroną | szybko złożyć checklistę testów dla klienta |
| US-07 | team lead | wyeksportować przefiltrowaną listę zagrożeń do CSV | włączyć ją do rejestru ryzyk |
| US-08 | developer | zobaczyć timeline Kill Chain MITRE | rozumieć na jakiej fazie ataku działa każda technika ATLAS |
| US-09 | Scala developer | znaleźć próbki kodu dla ataków na łańcuch dostaw w Scala | zaimplementować SCA w potoku Scala |
| US-10 | Lua/OpenResty developer | zobaczyć przykłady Lua dla rate limiting zapobiegającego LLM DoS | skonfigurować guardrails NGINX dla proxy LLM API |
| US-11 | Polish-speaking student | przełączyć całą aplikację z angielskiego na polski jednym kliknięciem | uczyć się wszystkich opisów zagrożeń w ojczystym języku |
| US-12 | React/frontend developer | przeglądać karty OWASP Cornucopia FRE (DOM XSS, clickjacking, CORS, JWT forgery) z polskimi opisami | mapować scenariusze ataków po stronie klienta na mitigacje |
| US-13 | ML engineer / AI architect | eksplorować wszystkie 10 zagrożeń OWASP LLM Top 10 2025 przez karty Cornucopia LLM z macierzą interaktywną | rozumieć prompt injection, data poisoning, excessive agency w systemach LLM |
| US-14 | agentic AI developer | studiować zagrożenia OWASP Agentic AI Top 10 2026 przez karty AAI | projektować zabezpieczenia human-in-the-loop dla agentów |
| US-15 | security architect / threat modeler | używać katalogu kart STRIDE EoP z interaktywną heatmapą per komponent systemu | prowadzić ustrukturyzowaną sesję threat modelingu |
| US-16 | data scientist / ML security engineer | przeglądać ryzyka bezpieczeństwa ML (Model, Input, Output, Dataset Risk) z referencjami MITRE ATLAS | identyfikować adversarial ML, model theft, data poisoning w potokach ML |
| US-17 | Android/iOS developer | zobaczyć zagrożenia OWASP MASVS przez karty Cornucopia Mobile App | zrozumieć jak kontrolki bezpieczeństwa mobile różnią się od web |
| US-18 | DevSecOps engineer | przeglądać ryzyka supply chain (DVO) i wzorce ataków automatycznych (BOT) z odwołaniami OWASP CI/CD Security | chronić potoki CI/CD i bronić się przed botami |

---

## 14. Milestones & Acceptance Criteria

| Kamień | Deliverable | Ukończone gdy |
|---|---|---|
| M1 | Działający szkielet | `docker compose up` → React home + `/api/v1/frameworks` zwraca JSON |
| M2 | Pełne seedowanie danych | Wszystkie frameworki, zagrożenia, mitigacje w DB; API zwraca poprawne liczby |
| M3 | Próbki kodu kompletne | Każde zagrożenie ma 5 próbek w językach widocznych na stronie ThreatDetail |
| M4 | Macierz + heatmapa | Tabela cross-reference renderuje się; heatmapa STRIDE pokazuje procenty pokrycia |
| M5 | Wyszukiwanie działa | Full-text search zwraca wyniki z podświetlonymi fragmentami |
| M6 | i18n działa | Przełącznik PL/EN w navbar; cały UI w obu językach; próbki kodu NIEPRZETŁUMACZONE |
| M7 | Produkcyjny build | Obraz Docker < 500 MB; Nginx serwuje SPA; `/api/v1/actuator/health` zwraca 200 |
| M8 | Karty FRE + LLM + AAI | Przeglądarki kart FRE, LLM, AAI działają; macierze LLM i Agentic dostępne |
| M9 | STRIDE + MLSec | Katalog 78 kart STRIDE (6 suit); heatmapa STRIDE; 52 karty MLSec (4 suit) |
| M10 | Mobile + DevOps | Przeglądarki kart Mobile MAS i DevOps/BOT działają; tabela MASVS vs Web |
| M11 | Integralność treści | `ContentIntegrityVerifier` działa; CI job `yaml-content-integrity` GREEN |
| M12 | Testy przechodzą | ≥ 195 testów; wszystkie abuse cases AC-01–AC-13 GREEN; ZAP full scan 0 HIGH |
