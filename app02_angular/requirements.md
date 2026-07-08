# ThreatView 2026 — Wymagania Aplikacji

**Wersja:** 1.0  
**Data:** 2026-07-07  
**Status:** Zatwierdzony — podstawa dla user stories i testów  
**Aplikacja:** ThreatView 2026 (app02_angular)

---

## 1. Cel aplikacji

**ThreatView 2026** to interaktywna platforma referencyjna i edukacyjna w zakresie bezpieczeństwa oprogramowania. Aplikacja prezentuje zagrożenia, luki bezpieczeństwa i mitigacje z sześciu głównych standardów: OWASP Web Top 10 (2021), OWASP LLM Top 10 (2025), OWASP Agentic AI Top 10 (2026), OWASP API Security Top 10, MITRE ATLAS (techniki adversarialnego ML) oraz CompTIA Security+ SY0-701 / SecAI+ 2026. Aplikacja obejmuje również pełny katalog kart OWASP Cornucopia.

Każde zagrożenie jest przedstawione z przykładowym kodem ataku i obrony w pięciu językach programowania: Python, Java/Spring Boot, Go, Scala i Lua.

Aplikacja jest dostępna w języku polskim (domyślnie) i angielskim z możliwością przełączania przez użytkownika.

---

## 2. Wymagania funkcjonalne (US-01 – US-18)

| ID | Rola | Potrzeba | Cel |
|---|---|---|---|
| US-01 | security engineer | przeglądać katalog wszystkich frameworków bezpieczeństwa (OWASP Web, LLM, API, Agentic AI, MITRE ATLAS, CompTIA SecAI+) | mieć jeden punkt dostępu do wszystkich standardów bezpieczeństwa w jednym miejscu |
| US-02 | security engineer | filtrować zagrożenia według frameworku, poziomu severity (CRITICAL/HIGH/MEDIUM/LOW/INFO), kategorii STRIDE, tagu i słowa kluczowego | szybko znaleźć zagrożenia istotne dla mojego projektu bez przeglądania całego katalogu |
| US-03 | security engineer | widzieć szczegóły każdego zagrożenia — opis ataku, wektory ataku, powiązane mitigacje, i próbki kodu w 5 językach | rozumieć jak wdrożyć ochronę techniczną dla konkretnego zagrożenia |
| US-04 | CompTIA SecAI+ student | zobaczyć jak zagrożenie LLM01 Prompt Injection mapuje do techniki MITRE ATLAS AML.T0051 i kompetencji CompTIA SecAI+ | rozumieć zależności i powiązania między różnymi frameworkami bezpieczeństwa |
| US-05 | security trainer | wyświetlić interaktywną heatmapę pokrycia STRIDE per komponent systemu na projektorze | wizualnie wyjaśnić zagrożenia STRIDE uczestnikom warsztatów threat modelingu |
| US-06 | pentester | wyszukać frazę "deepfake" lub "prompt injection" i znaleźć wszystkie powiązane zagrożenia z kompletną listą mitigacji | szybko złożyć checklistę testów penetracyjnych dla klienta |
| US-07 | team lead | wyeksportować przefiltrowaną listę zagrożeń do CSV lub PDF | włączyć ją bezpośrednio do rejestru ryzyk projektu |
| US-08 | developer | zobaczyć timeline Kill Chain MITRE ATLAS pokazujący poszczególne fazy ataku | rozumieć na którym etapie ataku działa każda technika ATLAS i gdzie wdrożyć ochronę |
| US-09 | Scala developer | znaleźć i skopiować próbki kodu obrony dla ataków na łańcuch dostaw napisane w Scala/Akka | zaimplementować kontrole SCA w istniejącym potoku budowania Scala |
| US-10 | Lua/OpenResty developer | zobaczyć przykłady kodu w Lua dla rate limiting zabezpieczającego przed LLM DoS | skonfigurować guardrails NGINX Lua dla własnego proxy LLM API |
| US-11 | Polish-speaking student | przełączyć całą aplikację z angielskiego na polski jednym kliknięciem w pasku nawigacji | uczyć się opisów zagrożeń i mitigacji w ojczystym języku bez zmiany kontekstu |
| US-12 | React/frontend developer | przeglądać karty OWASP Cornucopia Frontend (FRE) — DOM XSS, clickjacking, CORS, JWT forgery — z polskimi opisami i odwołaniami do OWASP Client-Side Top 10 | mapować scenariusze ataków po stronie klienta na konkretne mitigacje w moich aplikacjach webowych |
| US-13 | ML engineer / AI architect | eksplorować wszystkie 10 zagrożeń OWASP LLM Top 10 2025 przez karty Cornucopia LLM z polskimi tłumaczeniami i interaktywną macierzą LLM Top 10 × karty | rozumieć prompt injection, data poisoning, excessive agency i ryzyka supply chain w systemach LLM |
| US-14 | agentic AI developer | studiować zagrożenia OWASP Agentic AI Top 10 2026 przez karty AAI (nadmierna autonomia, niezweryfikowane łańcuchy zaufania, manipulacja orkiestracją) | projektować zabezpieczenia human-in-the-loop dla autonomicznych potoków agentów AI |
| US-15 | security architect / threat modeler | używać katalogu kart STRIDE EoP (Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege) z interaktywną heatmapą per komponent systemu | prowadzić ustrukturyzowaną sesję threat modelingu i mapować wyniki do OWASP Web Top 10 |
| US-16 | data scientist / ML security engineer | przeglądać ryzyka bezpieczeństwa ML (Model Risk EMR, Input Risk EIR, Output Risk EOR, Dataset Risk EDR) z odwołaniami do technik MITRE ATLAS | identyfikować adversarial ML, model theft, data poisoning i manipulację wynikami w potokach ML |
| US-17 | Android/iOS developer | zobaczyć zagrożenia OWASP MASVS przez karty Cornucopia Mobile App (weryfikacja TLS, jailbreak detection, hardcoded keys, bezpieczeństwo IPC) | rozumieć jak kontrolki bezpieczeństwa mobile różnią się od web i zastosować wymagania MASVS |
| US-18 | DevSecOps engineer / team lead | przeglądać ryzyka supply chain (karty DVO) i wzorce ataków automatycznych (karty BOT) z odwołaniami do OWASP CI/CD Security Risks i mitigacjami rate limiting | chronić potoki CI/CD, walidować integralność artefaktów i bronić się przed botami scrapingu i credential stuffing |

---

## 3. Wymagania techniczne

### 3.1 Frontend — Angular 18

| ID | Wymaganie |
|---|---|
| FR-T-01 | Aplikacja zbudowana jako Angular 18 SPA ze standalone components i Angular Material 18 (MDC-based) |
| FR-T-02 | Angular Signals + NgRx Signals — reaktywne zarządzanie stanem: frameworks, threats, cardSuits, search, ui (darkMode, locale) |
| FR-T-03 | Angular Router z lazy loading dla każdego feature — wstępny bundle < 600 KB gzip |
| FR-T-04 | ngx-translate 15.x — przełączanie PL ↔ EN bez przeładowania strony; pliki `assets/i18n/pl.json` i `en.json` |
| FR-T-05 | Angular Reactive Forms + class-validator dla wszystkich formularzy (wyszukiwanie, admin CRUD) |
| FR-T-06 | Angular HttpClient z interceptorami: `AuthInterceptor` (Bearer JWT), `LocaleInterceptor` (Accept-Language header) |
| FR-T-07 | Prism.js leniwie ładowany per język (LazyPrismDirective) — próbki kodu nigdy nie są tłumaczone |
| FR-T-08 | ngx-echarts (Apache ECharts) dla wykresów + D3.js v7 dla SVG diagramów STRIDE Kill Chain |
| FR-T-09 | Angular DomSanitizer — bezpieczne renderowanie opisów kart; `bypassSecurityTrustHtml` zabronione na opisach kart |
| FR-T-10 | Angular strict mode: `"strict": true` w `tsconfig.json`; TypeScript 5.x; CI weryfikuje `tsc --noEmit` |

### 3.2 Backend — Spring Boot 3.3

| ID | Wymaganie |
|---|---|
| FR-T-11 | REST API JSON, SpringDoc OpenAPI 3, Swagger UI pod `/swagger-ui.html`, CORS skonfigurowany dla allowed origins |
| FR-T-12 | Spring Security 6 — JWT authentication + OAuth2; rola ADMIN do CRUD endpointów; rola USER do odczytu |
| FR-T-13 | PostgreSQL 16 + Spring Data JPA + Flyway V1..V25; Redis 7 dla Spring Cache (TTL 5 min) |
| FR-T-14 | Bucket4j — rate limiting 60 req/min per IP na endpointach `/api/v1/threats?suit=*` |
| FR-T-15 | OWASP Java HTML Sanitizer — sanityzacja wszystkich pól tekstowych przez admin endpoint PUT/POST |
| FR-T-16 | `ContentIntegrityVerifier` @PostConstruct — weryfikacja SHA-256 każdego pliku YAML kart przy starcie; fail-secure przy niezgodności |
| FR-T-17 | Klasy `*RefValidator`: `OwaspRefValidator`, `MitreAtlasRefValidator`, `MavsRefValidator`, `CicdSecRefValidator`, `OatRefValidator` — server-side allowlisty identyfikatorów |

---

## 4. Wymagania niefunkcjonalne

| ID | Wymaganie | Cel pomiarowy |
|---|---|---|
| NF-01 | Czas odpowiedzi API < 200 ms dla zapytań listowych | p95, Apache Bench 100 concurrent users |
| NF-02 | Inicjalny bundle Angular < 600 KB gzip | `ng build --configuration production` + gzip |
| NF-03 | Lighthouse Performance Score ≥ 85 (mobile) | Lighthouse CI w GitHub Actions |
| NF-04 | Lighthouse Accessibility Score ≥ 90 | WCAG 2.1 AA — axe-core w Cypress |
| NF-05 | 99.5% uptime w środowisku produkcyjnym | Prometheus + Grafana alert |
| NF-06 | Obsługa min. 100 jednoczesnych użytkowników | Apache Bench bez degradacji > 200 ms |
| NF-07 | Pokrycie testami jednostkowymi ≥ 80% klas backend | JaCoCo + CI gate |
| NF-08 | Czas zimnego startu aplikacji < 10 s | Docker health check |

---

## 5. Wymagania bezpieczeństwa

| ID | Wymaganie |
|---|---|
| SR-01 | Content Security Policy: `script-src 'self'`; brak `unsafe-inline` i `unsafe-eval`; Angular CLI generuje nonce dla inline styles |
| SR-02 | HSTS: `Strict-Transport-Security: max-age=31536000; includeSubDomains; preload` |
| SR-03 | `X-Content-Type-Options: nosniff` na wszystkich odpowiedziach HTTP |
| SR-04 | `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` — ochrona przed clickjacking; szczególnie `/stride-heatmap` |
| SR-05 | `Referrer-Policy: strict-origin-when-cross-origin` |
| SR-06 | `Permissions-Policy: camera=(), microphone=(), geolocation=()` |
| SR-07 | JWT access token wygasa po 15 minutach; refresh token przechowywany w HttpOnly cookie |
| SR-08 | Wszystkie admin endpointy wymagają JWT z rolą ADMIN; brak dostępu 403 dla USER |
| SR-09 | Bean validation (@Valid) na wszystkich DTO; allowlisty identyfikatorów na polach owaspRefs, mitreRefs, mavsRefs |
| SR-10 | Zapobieganie SQL injection — wyłącznie Spring Data JPA (parameterized queries); brak raw SQL |
| SR-11 | Bucket4j rate limiting 60 req/min per IP na endpointach kart; HTTP 429 z Retry-After header |
| SR-12 | Integralność YAML kart: SHA-256 weryfikowane przez `ContentIntegrityVerifier` @PostConstruct; aplikacja nie startuje przy niezgodności |
| SR-13 | Próbki kodu ataku oznaczone etykietą **PODATNY** (VULNERABLE) — nigdy nie uruchamiane server-side; BotWarningDialog przed kopiowaniem |
| SR-14 | Angular `DomSanitizer` — wszystkie opisy kart renderowane przez `sanitize(SecurityContext.HTML, ...)`; `bypassSecurityTrustHtml` zabronione na opisach |
| SR-15 | CORS — dozwolone origins w `application.yml`; brak wildcard `*` w produkcji |
| SR-16 | SCA: OWASP Dependency Check (Java) + npm audit (Node) + Trivy (Docker image) w CI; blokada przy HIGH/CRITICAL CVE |
| SR-17 | SAST: SpotBugs + FindSecBugs (Java) + eslint-plugin-security (TypeScript) w CI |
| SR-18 | DAST: OWASP ZAP full active scan na środowisku staging przed każdym deployem na prod; blokada przy HIGH findings |

---

## 6. Wymagania dostępności

| ID | Wymaganie |
|---|---|
| A-01 | WCAG 2.1 AA — wszystkie strony; weryfikacja axe-core w Cypress E2E |
| A-02 | Kontrast kolorów ≥ 4.5:1 dla tekstu normalnego, ≥ 3:1 dla tekstu dużego (Angular Material paleta) |
| A-03 | Nawigacja klawiaturą — wszystkie interaktywne elementy focusable (Angular CDK a11y, mat-focus-trap dla dialogów) |
| A-04 | ARIA labels na wszystkich mat-icon-button, mat-fab i elementach bez widocznego tekstu |
| A-05 | Skip-to-content link na początku każdej strony |
| A-06 | Komunikaty o błędach formularzy (mat-error) powiązane z polami przez aria-describedby |
| A-07 | Tabele danych (mat-table) z nagłówkami `scope="col"` i opisami aria-label |
| A-08 | Diagramy SVG (D3.js) z alternatywnym opisem tekstowym (aria-label lub figcaption) |

---

## 7. Wymagania internacjonalizacji (i18n)

| ID | Wymaganie |
|---|---|
| i18n-01 | Język domyślny: polski (`pl`) |
| i18n-02 | Język alternatywny: angielski (`en`) — fallback gdy brak klucza PL |
| i18n-03 | `LanguageToggleComponent` widoczny w `mat-toolbar` i w `mat-sidenav` |
| i18n-04 | Wybór języka persystowany w `localStorage` pod kluczem `tv_locale` |
| i18n-05 | `LocaleInterceptor` — nagłówek `Accept-Language: pl` lub `Accept-Language: en` na każdym żądaniu HTTP |
| i18n-06 | `Content-Language` nagłówek w odpowiedziach API |
| i18n-07 | Próbki kodu NIGDY nie są tłumaczone — tylko treść UI i opisy zagrożeń |
| i18n-08 | Klucze i18n weryfikowane w CI: test `i18n-keys-parity.spec.ts` sprawdza parzystość kluczy PL vs EN |
| i18n-09 | Nazwy kart Cornucopia i opisy przechowywane jako `descriptionPl` + `descriptionEn` w encji `CornucopiaCard` |
| i18n-10 | Przełączenie języka nie przeładowuje strony — ngx-translate `TranslateService.use()` + Angular Signals reaktywna aktualizacja widoku |

---

## 8. Wymagania dotyczące danych i treści

| ID | Wymaganie |
|---|---|
| D-01 | Minimum 10 zagrożeń dla każdego z frameworków: OWASP Web Top 10, LLM Top 10, API Top 10, Agentic AI Top 10 |
| D-02 | Minimum 15 technik MITRE ATLAS z mapowaniem do OWASP LLM Top 10 |
| D-03 | Minimum 20 tematów CompTIA SecAI+ z mapowaniem do zagrożeń LLM i MITRE ATLAS |
| D-04 | Każde zagrożenie ma minimum 1 mitigację; każda mitigacja ma 5 próbek kodu (Python, Java, Go, Scala, Lua) |
| D-05 | Każda próbka kodu ma zakładkę Attack Demo (PODATNY) i zakładkę Defense (BEZPIECZNY) |
| D-06 | Karty Cornucopia: wszystkie 5 edycji YAML załadowane — webapp 3.0 (7 suit), companion 1.0 (6 suit), mobileapp 1.1 (6 suit), stride-eop 5.0 (6 suit), mlsec 1.0 (4 suit) |
| D-07 | Każda karta Cornucopia ma opis polski (`descriptionPl`) i angielski (`descriptionEn`) |
| D-08 | Karty krytyczne (J, Q, K) mają flagę `isCritical: true` — wyróżnione wizualnie w UI |
| D-09 | Pliki YAML kart nie są modyfikowane w runtime; `ContentIntegrityVerifier` weryfikuje SHA-256 przy każdym starcie |
| D-10 | Wszystkie identyfikatory OWASP, MITRE ATLAS, MASVS, CICD-SEC, OAT walidowane przez server-side allowlisty |

---

## 9. Definicja ukończenia (Definition of Done)

Każda User Story jest ukończona gdy:

1. Kod napisany zgodnie z Angular strict mode i Java coding standards
2. Testy jednostkowe przechodzą (≥ 80% pokrycia dla nowej klasy)
3. Test integracyjny (Testcontainers) dla endpointu REST — GREEN
4. Test komponentu Angular (Jest + ATL) — GREEN
5. Test E2E Cypress dla user story — GREEN
6. Brak nowych HIGH/CRITICAL wyników SpotBugs, eslint-plugin-security
7. Klucze i18n dla PL i EN dodane w plikach `pl.json` / `en.json`
8. Security peer review dla wszystkich nowych endpointów i komponentów z zewnętrznym wejściem
9. Dokumentacja OpenAPI zaktualizowana dla nowych endpointów
10. Product Owner zaakceptował funkcjonalność
