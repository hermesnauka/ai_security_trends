# ThreatView 2026 — Analiza SSDLC

**Wersja:** 1.0  
**Data:** 2026-07-07  
**Metodologia:** Agile — Scrum + Kanban z integracją SSDLC  
**Dotyczy:** US-01 – US-18 / Angular 18 + Spring Boot 3.3

---

## 1. Przegląd metodologii

### 1.1 Scrum z integracją Security

Projekt realizowany w 2-tygodniowych sprintach (Sprints 1–16, 31 tygodni łącznie). Bezpieczeństwo jest wymaganiem pierwszej klasy w każdym sprincie — nie traktowanym jako osobna faza na końcu.

**Ceremonie scrumowe z wymiarem security:**

| Ceremonia | Czas | Element security |
|---|---|---|
| Sprint Planning | 4h | Każda US ma SAC (Security Acceptance Criteria) w DoD |
| Daily Standup | 15 min | Stały punkt: "security blocker?" |
| Sprint Review | 2h | Demo funkcjonalności + wyniki skanów SAST z CI |
| Retrospective | 1.5h | Analiza incydentów bezpieczeństwa z minionego sprintu |
| Backlog Refinement | 2h mid-sprint | Weryfikacja kryteriów bezpieczeństwa dla US z kolejnego sprintu |

### 1.2 Kanban Security Board

```
Backlog → Security Review → In Progress → SAST Check → Code Review → Testing → Done
```

- **Security Review**: każda US przed rozpoczęciem pracy przechodzi przez mini-STRIDE analizę
- **SAST Check**: SpotBugs + FindSecBugs (backend) + ESLint security plugin (frontend) GREEN
- **Code Review**: min. 1 recenzja security-aware przed merge
- **Testing**: unit + integration + E2E + abuse cases GREEN

### 1.3 Definition of Done (DoD) — wymiar security

Każda US jest "Done" gdy:
- [ ] SAST (SpotBugs + ESLint) GREEN dla zmienionych plików
- [ ] Brak nowych Critical/High CVEs w OWASP Dependency Check / npm audit
- [ ] Testy bezpieczeństwa (abuse cases) dla danej US GREEN
- [ ] Angular strict mode — `ng build` kompiluje bez błędów
- [ ] Security Acceptance Criteria (sekcja 2.3) spełnione dla danej US
- [ ] Code review zatwierdzony przez osobę z uprawnieniami security

### 1.4 Mapa sprintów

| Sprint | Tygodnie | Faza | User Stories | Główne deliverables |
|---|---|---|---|---|
| 1–2 | 1–4 | Phase 1 Foundation | US-01 | Angular scaffold, Spring Boot, Docker, Flyway V1–V8, seed data |
| 3–4 | 5–8 | Phase 2 Core | US-02, US-03, US-04 | ThreatBrowser, ThreatDetail, MatrixComponent |
| 5–6 | 9–12 | Phase 3 Code Samples | US-08, US-09, US-10 | CodeSamplePanel, LazyPrism, MITRE timeline |
| 6–7 | 11–14 | Phase 4 Advanced | US-05, US-06, US-07 | Search, Export, Dark mode |
| 8 | 15–16 | Phase 5 i18n | US-11 | ngx-translate PL/EN, LocaleInterceptor |
| 9 | 17–18 | Phase 6 FRE+LLM+AAI | US-12, US-13, US-14 | CornucopiaCard, FRE/LLM/AAI browsers |
| 10–11 | 19–22 | Phase 7 STRIDE+MLSec | US-15, US-16 | STRIDE catalogue, ECharts heatmap, MLSec |
| 12–13 | 23–26 | Phase 8 Mobile+DevOps | US-17, US-18 | Mobile MAS, DVO+BOT, BotWarningDialog |
| 14–16 | 27–31 | Phase 9 Hardening | All | Tests, ZAP, axe, Lighthouse, monitoring |

---

## 2. Faza 0 — Planowanie i modelowanie zagrożeń

### 2.1 Zbieranie wymagań bezpieczeństwa

Przed pierwszym sprintem:
- Warsztat stakeholderów: identyfikacja aktywów i danych wrażliwych
- Ocena OWASP SAMM — poziom wyjściowy projektu
- Threat modeling systemu ThreatView metodą STRIDE (sekcja 2.2)
- Inicjalizacja rejestru ryzyk (Risk Register, PLAN.md sekcja 14)
- Decyzje architektoniczne D-01–D-13 zatwierdzone przez tech lead i security lead

### 2.2 Threat Modeling — STRIDE dla ThreatView 2026

| Kategoria STRIDE | Komponent | Zagrożenie | Ryzyko | Mitigacja |
|---|---|---|---|---|
| **S** — Spoofing | `/api/v1/admin` | Nieuprawniony dostęp bez ADMIN JWT | HIGH | `@PreAuthorize("hasRole('ADMIN')")` |
| **S** — Spoofing | Angular JWT | Token theft przez XSS → session hijacking | HIGH | HttpOnly refresh token; access token TTL 15 min |
| **T** — Tampering | YAML card files | Modyfikacja plików kart Cornucopia | HIGH | ContentIntegrityVerifier SHA-256 + CODEOWNERS |
| **T** — Tampering | Angular templates | XSS przez `[innerHTML]` bez sanityzacji | HIGH | Angular DomSanitizer + strict mode + CSP |
| **T** — Tampering | `/api/v1/admin/threats` | XSS payload w opisie karty przez admina | HIGH | OWASP Java HTML Sanitizer + DomSanitizer |
| **R** — Repudiation | Admin CRUD | Admin zaprzecza modyfikacji karty | MEDIUM | Strukturyzowane logi Loki z user claim z JWT |
| **I** — Information Disclosure | Error responses | Wyciek stack trace przez verbose 5xx | MEDIUM | `GlobalExceptionHandler` — generic messages |
| **I** — Information Disclosure | YAML git history | Ujawnienie nieopublikowanych kart przez historię git | LOW | gitleaks CI + opcjonalnie git-crypt |
| **D** — Denial of Service | `/api/v1/threats?suit=*` | Bot scraping całego API w pętli | HIGH | Bucket4j 60 req/min per IP; HTTP 429 + Retry-After |
| **D** — Denial of Service | ECharts heatmap | Ciężkie SVG generowane per request | MEDIUM | Cache Redis TTL 5 min (`@Cacheable`) |
| **E** — Elevation of Privilege | POST `/api/v1/admin` | User bez ADMIN role wykonuje CRUD | HIGH | Spring Security method security + JWT claim |
| **E** — Elevation of Privilege | `?q=` filter | SQL injection → admin DB access | HIGH | Spring Data JPA Specification, named params |

### 2.3 Security Acceptance Criteria (SAC)

| ID | Kryterium | Weryfikacja w CI |
|---|---|---|
| SAC-01 | Wszystkie endpointy `/admin/**` wymagają JWT z ADMIN claim | `AdminControllerSecurityIT` |
| SAC-02 | SAST SpotBugs + FindSecBugs + ESLint security GREEN przed każdym merge | CI job `lint-and-sast` |
| SAC-03 | Brak High/Critical w OWASP Dependency Check i npm audit | CI job `dependency-check` |
| SAC-04 | ContentIntegrityVerifier weryfikuje SHA-256 YAML przy starcie — niezgodność = fail-secure | `ContentIntegrityVerifierTest` |
| SAC-05 | Bucket4j zwraca HTTP 429 po > 60 req/min per IP na `/api/v1/threats?suit=*` | `RateLimitIT` |
| SAC-06 | CSP header blokuje inline scripts i eval | ZAP headerscan w CI |
| SAC-07 | Angular `DomSanitizer.sanitize(SecurityContext.HTML)` przed każdym `[innerHTML]` | `CornucopiaCardXSSTest` |
| SAC-08 | `strict: true` + `strictTemplates: true` — `ng build` bez błędów | CI job `build` |
| SAC-09 | Wszystkie próbki `ATTACK_DEMO` oznaczone badge `PODATNY` w UI | `CodeSamplePanelComponent.spec.ts` |
| SAC-10 | `BotWarningDialogComponent` wyświetla się przed kartami BOT | `us18-devops-security.cy.ts` |
| SAC-11 | `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` na `/stride-heatmap` | ZAP headerscan |
| SAC-12 | axe-core: 0 Critical/Serious WCAG 2.1 AA violations | `cypress-axe` w każdym E2E spec |
| SAC-13 | Wszystkie 18 plików `*.cy.ts` GREEN | CI job `e2e` |
| SAC-14 | Backend ≥ 80% (JaCoCo); frontend ≥ 75% (Jest lcov) | CI job `unit-tests` |
| SAC-15 | DAST ZAP full active scan — 0 High/Critical na staging | CI job `dast-zap` |

---

## 3. Faza 1 — Fundament (Sprint 1–2, Tygodnie 1–4)

### 3.1 Inicjalizacja projektu

```
ng new threatview --standalone --routing --style=scss
ng add @angular/material   (theme: indigo-amber, animations: enabled)
```

Spring Boot 3.3 pom.xml zależności: spring-boot-starter-web, spring-boot-starter-security, spring-boot-starter-data-jpa, spring-boot-starter-actuator, springdoc-openapi-starter-webmvc-ui, bucket4j-spring-boot-starter, owasp-java-html-sanitizer, flyway-core.

### 3.2 Konfiguracja środowiska deweloperskiego

```
.github/
  CODEOWNERS:           /data/cornucopia/  @security-team  (min. 2 zatwierdzenia)
  branch-protection:    main, develop — brak direct push; PR + CI GREEN wymagane

.git/hooks/ (instalowane przez npm postinstall + mvn generate-sources):
  pre-commit:    ng lint + mvn spotbugs:check -q + gitleaks detect

.editorconfig:   charset utf-8, end_of_line lf
```

### 3.3 CI Pipeline — bazowy (GitHub Actions)

```
Jobs (kolejność wykonania):
  [1] lint-and-sast         ─── ng lint, mvn spotbugs:check, gitleaks
  [2] unit-tests            ─── ng test --coverage (Jest), mvn test (JUnit 5 + JaCoCo)
  [3] dependency-check      ─── mvn dependency-check:check, npm audit --audit-level=high
  [4] build                 ─── mvn package -DskipTests, ng build --configuration production
      └─ budget-check        ── ng build verifies initial chunk < 600 KB gzip
  [5] integration-tests     ─── mvn verify (Testcontainers PostgreSQL 16)
  [6] docker-scan           ─── trivy image --exit-code 1 --severity CRITICAL
```

### 3.4 Spring Boot — bezpieczeństwo bazowe

```java
// SecurityConfig.java
http
  .sessionManagement(s -> s.sessionCreationPolicy(STATELESS))
  .csrf(AbstractHttpConfigurer::disable)   // stateless JWT REST — CSRF nie potrzebny
  .headers(headers -> headers
    .contentSecurityPolicy("default-src 'self'; frame-ancestors 'none'; object-src 'none'")
    .frameOptions(f -> f.deny())
    .httpStrictTransportSecurity(hsts -> hsts.maxAgeInSeconds(31536000).includeSubDomains(true))
    .contentTypeOptions(Customizer.withDefaults())
  )
  .authorizeHttpRequests(auth -> auth
    .requestMatchers("/api/v1/admin/**").hasRole("ADMIN")
    .requestMatchers("/api/v1/stride-heatmap").authenticated()
    .anyRequest().permitAll()
  );

// Actuator ograniczony:
management.endpoints.web.exposure.include=health,metrics
management.endpoint.env.enabled=false
```

---

## 4. Faza 2 — Rdzeń funkcjonalności (Sprint 3–4, Tygodnie 5–8)

### 4.1 Bezpieczne kodowanie — backend (US-02, US-03)

**Filtrowanie zagrożeń — zapobieganie SQL Injection:**
```java
// ThreatRepository — Specification<T> z named params (nigdy string concat)
Specification<Threat> spec = Specification.where(null);
if (q != null && !q.isBlank()) {
    String safe = q.trim().substring(0, Math.min(q.length(), 200));
    spec = spec.and((root, query, cb) ->
        cb.like(cb.lower(root.get("title")), "%" + safe.toLowerCase() + "%"));
}
```

**Walidacja DTO (bean validation):**
```java
public record ThreatFilterRequest(
    @Pattern(regexp = "^[A-Z0-9_]{2,20}$") String frameworkCode,
    @Pattern(regexp = "^(CRITICAL|HIGH|MEDIUM|LOW|INFO)$") String severity,
    @Pattern(regexp = "^[STRIDE]{1,6}$") String stride,
    @Size(max = 200) String q,
    @Min(0) @Max(100) int page
) {}
```

**GlobalExceptionHandler — bez stack trace:**
```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleAll(Exception ex) {
        log.error("Unhandled: {}", ex.getMessage()); // logujemy szczegóły wewnętrznie
        return ResponseEntity.status(500).body(new ApiError("INTERNAL_ERROR", "An error occurred"));
    }
}
```

### 4.2 Bezpieczne kodowanie — Angular (US-02, US-03)

**CornucopiaCardComponent — DomSanitizer:**
```typescript
@Component({ changeDetection: ChangeDetectionStrategy.OnPush })
export class CornucopiaCardComponent {
  card = input.required<CornucopiaCard>();

  protected safeDescription = computed(() => {
    const raw = this.localeService.currentLocale() === 'pl'
      ? this.card().descriptionPl
      : this.card().descriptionEn;
    // JEDYNA dozwolona ścieżka renderowania HTML — ESLint blokuje bypassSecurityTrustHtml
    return this.sanitizer.sanitize(SecurityContext.HTML, raw) ?? '';
  });

  constructor(
    private sanitizer: DomSanitizer,
    private localeService: LocaleService
  ) {}
}
```

### 4.3 Abuse Cases — Faza 2

**AC-01: SQL Injection**
```java
@Test
void sqlInjectionInQParam_shouldNotDropTable() {
    given().queryParam("q", "'; DROP TABLE threats; --")
        .when().get("/api/v1/threats")
        .then().statusCode(anyOf(equalTo(200), equalTo(400)));
    assertThat(threatRepository.count()).isGreaterThan(0);
}
```

**AC-02: JWT Tampering**
```java
@Test
void modifiedJwtPayload_shouldReturn401() {
    String validToken = jwtService.generateToken("user1", List.of("USER"));
    String[] parts = validToken.split("\\.");
    String fakePayload = Base64.encodeBase64String("{\"sub\":\"admin\",\"roles\":[\"ADMIN\"]}".getBytes());
    given()
        .header("Authorization", "Bearer " + parts[0] + "." + fakePayload + "." + parts[2])
        .when().get("/api/v1/admin/threats")
        .then().statusCode(401);
}
```

---

## 5. Faza 3 — Próbki kodu (Sprint 5–6, Tygodnie 9–12)

### 5.1 Wymagania bezpieczeństwa dla kodu (SR-CODE)

| ID | Wymaganie | Implementacja |
|---|---|---|
| SR-CODE-01 | ATTACK_DEMO → badge PODATNY (border czerwony) | `CodeSamplePanelComponent` — klasa CSS `vulnerable-sample` |
| SR-CODE-02 | ATTACK_DEMO nigdy nie wykonywane server-side | `codeSnippet` to plain String — brak eval() w backendzie |
| SR-CODE-03 | Próbki kodu nie tłumaczone | `LocaleInterceptor` nie dodaje Accept-Language dla `/api/v1/code-samples` |
| SR-CODE-04 | Prism.js ładowany lazy per język | `LazyPrismDirective`: `import()` dopiero gdy zakładka aktywna |
| SR-CODE-05 | Copy ATTACK_DEMO → dialog ostrzeżenia | `BotWarningDialogComponent` przed `navigator.clipboard.writeText()` |

### 5.2 Testy — próbki kodu

```typescript
// CodeSamplePanelComponent.spec.ts
it('should show PODATNY badge on ATTACK_DEMO tab', () => {
    const { getByText } = render(CodeSamplePanelComponent,
        { inputs: { codeSamples: [mockAttackDemoSample] } });
    expect(getByText('PODATNY')).toBeInTheDocument();
});

it('should open BotWarningDialog before clipboard copy on ATTACK_DEMO', async () => {
    const dialogSpy = jest.spyOn(dialog, 'open');
    await userEvent.click(screen.getByLabelText('Copy attack demo code'));
    expect(dialogSpy).toHaveBeenCalledWith(BotWarningDialogComponent);
});
```

---

## 6. Faza 4 — Zaawansowane funkcje (Sprint 6–7, Tygodnie 11–14)

### 6.1 Wyszukiwanie — zabezpieczenia

**Limit długości query (AC-06: ReDoS):**
```java
@GetMapping("/api/v1/search")
public ResponseEntity<SearchResult> search(
    @RequestParam @NotBlank @Size(min = 2, max = 200) String q) { ... }
```

```java
// SearchReDoSTest.java
@Test
void queryExceeding200Chars_shouldReturn400() {
    given().queryParam("q", "a".repeat(201))
        .when().get("/api/v1/search")
        .then().statusCode(400);
}
```

### 6.2 Eksport — CSV Injection Prevention (AC-07)

```java
// ExportService.java
CSVFormat csvFormat = CSVFormat.DEFAULT
    .withQuoteMode(QuoteMode.ALL)  // ochrona przed =FORMULA injection
    .withHeader("ID", "Code", "Title", "Severity", "Category");
```

```java
// CsvInjectionIT.java
@Test
void threatTitleWithFormulaPrefix_shouldBeQuotedInExport() {
    // Threat z tytułem "=CMD|' /C calc'!A0" jest dopuszczalny w bazie
    // ale w CSV musi być owinięty cudzysłowami
    String csv = given().queryParam("frameworkCode", "OWASP_WEB")
        .when().get("/api/v1/export?format=csv")
        .then().statusCode(200).extract().body().asString();
    assertThat(csv).contains("\"=CMD|' /C calc'!A0\""); // <=  owinięty cudzysłowami
}
```

---

## 7. Faza 5 — i18n (Sprint 8, Tygodnie 15–16)

### 7.1 LocaleInterceptor — tylko 'pl' lub 'en'

```typescript
// locale.interceptor.ts
export const localeInterceptor: HttpInterceptorFn = (req, next) => {
  const locale = inject(LocaleService).currentLocale();
  const safe = (['pl', 'en'] as const).includes(locale as 'pl' | 'en') ? locale : 'pl';
  return next(req.clone({ setHeaders: { 'Accept-Language': safe } }));
};
```

### 7.2 Test parzystości kluczy i18n

```typescript
// i18n-keys-parity.spec.ts
import plJson from '../assets/i18n/pl.json';
import enJson from '../assets/i18n/en.json';

describe('i18n key parity', () => {
  it('should have identical top-level keys', () => {
    expect(Object.keys(plJson).sort()).toEqual(Object.keys(enJson).sort());
  });

  it('should have at least 50 keys', () => {
    expect(Object.keys(plJson).length).toBeGreaterThanOrEqual(50);
  });

  it('should contain no HTML tags in i18n values', () => {
    const htmlTagRegex = /<[^>]+>/;
    Object.entries(plJson).forEach(([key, value]) => {
      expect(htmlTagRegex.test(value as string),
        `pl.json key "${key}" contains HTML`).toBeFalsy();
    });
  });
});
```

---

## 8. Faza 6 — Cornucopia: FRE + LLM + AAI (Sprint 9, Tygodnie 17–18)

### 8.1 Wymagania bezpieczeństwa — Cornucopia

| ID | Wymaganie | Implementacja |
|---|---|---|
| SR-C-01 | descriptionPl/En: plain text bez HTML | Walidacja w YamlCardLoader + grep w CI |
| SR-C-02 | DomSanitizer przed każdym renderowaniem opisu karty | `CornucopiaCardComponent.safeDescription` computed signal |
| SR-C-03 | ContentIntegrityVerifier SHA-256 — fail-secure | `@PostConstruct` → throw `ContentIntegrityException` |
| SR-C-04 | OwaspRefValidator — server-side allowlist | `data/ref-allowlists.json` sekcja owaspRefs |
| SR-C-05 | Rate limit 60 req/min per IP na `/api/v1/threats?suit=*` | Bucket4j `@RateLimited` |
| SR-C-06 | AAI diagramy renderowane server-side jako SVG | Backend Batik, Angular: `<img [src]="svgUrl">` |
| SR-C-07 | AUTONOMY RISK badge na AAIK, AAIQ | `isCritical && suitCode === 'AAI'` → mat-chip czerwony |

### 8.2 ContentIntegrityVerifier

```java
@Component
@Slf4j
public class ContentIntegrityVerifier {

    @PostConstruct
    public void verify() throws ContentIntegrityException {
        Map<String, String> expected = loadHashesJson("data/hashes.json");
        for (var entry : expected.entrySet()) {
            String actual = computeSha256(Path.of("data/cornucopia", entry.getKey()));
            if (!entry.getValue().equalsIgnoreCase(actual)) {
                log.error("INTEGRITY FAIL: {} expected={} actual={}",
                    entry.getKey(), entry.getValue(), actual);
                throw new ContentIntegrityException("Tampered YAML: " + entry.getKey());
            }
        }
        log.info("ContentIntegrityVerifier: all {} files OK", expected.size());
    }

    private String computeSha256(Path path) throws ContentIntegrityException {
        try {
            return HexFormat.of().formatHex(
                MessageDigest.getInstance("SHA-256").digest(Files.readAllBytes(path))
            );
        } catch (Exception e) {
            throw new ContentIntegrityException("Cannot verify: " + path, e);
        }
    }
}
```

### 8.3 YAML Integrity CI Pipeline

```
PR → CI yaml-content-integrity:
  1. ajv validate --schema card-schema.json --data *.yaml
  2. grep -rE "(system_prompt|<script|javascript:|eval\()" data/cornucopia/ → fail if match
  3. java -jar validators.jar data/cornucopia/*.yaml  (OwaspRefValidator CLI)
↓ merge
  hash-generator [bot] → aktualizuje data/hashes.json → commit
↓ deploy
  Spring @PostConstruct ContentIntegrityVerifier → SHA-256 vs hashes.json
  → ContentIntegrityException jeśli niezgodność → aplikacja nie startuje
```

### 8.4 Abuse Cases — Cornucopia

**AC-09: Bot scraping (Bucket4j)**
```java
@Test
void exceed60RequestsPerMinute_shouldReturn429() {
    for (int i = 0; i < 61; i++) {
        Response r = given().queryParam("suit", "FRE").get("/api/v1/threats");
        if (i == 60) {
            assertThat(r.statusCode()).isEqualTo(429);
            assertThat(r.header("Retry-After")).isNotNull();
        }
    }
}
```

**AC-10: XSS przez admin update opisu karty**
```java
@Test @WithMockUser(roles = "ADMIN")
void adminUpdate_withXssPayload_shouldSanitize() {
    given()
        .body(new UpdateCardRequest(cardId, "<script>alert('XSS')</script>Safe", null))
        .contentType(ContentType.JSON)
        .header("Authorization", "Bearer " + adminToken)
        .put("/api/v1/admin/threats/" + cardId)
        .then().statusCode(200);
    assertThat(cardRepository.findById(cardId).orElseThrow().getDescriptionPl())
        .doesNotContain("<script>")
        .contains("Safe");
}
```

**AC-11: YAML tampering**
```java
@Test
void tamperedYamlFile_shouldThrowContentIntegrityException() {
    Path tempYaml = Files.createTempFile("tampered", ".yaml");
    Files.writeString(tempYaml, "malicious: content");
    assertThatThrownBy(() -> verifier.verifyFile(tempYaml, originalHash))
        .isInstanceOf(ContentIntegrityException.class);
}
```

**AC-12: Fałszywy MITRE ATLAS ID**
```java
@Test
void unknownMitreAtlasId_shouldReturn422() {
    given()
        .body(new UpdateCardRequest(cardId, "desc", List.of("MITRE.T9999")))
        .contentType(ContentType.JSON)
        .header("Authorization", "Bearer " + adminToken)
        .put("/api/v1/admin/threats/" + cardId)
        .then().statusCode(422);
}
```

---

## 9. Faza 7 — STRIDE EoP + MLSec (Sprint 10–11, Tygodnie 19–22)

### 9.1 Wymagania bezpieczeństwa (US-15, US-16)

| ID | Wymaganie | Implementacja |
|---|---|---|
| SR-S-01 | `/stride-heatmap` wymaga JWT | `AuthGuard` Angular + `@PreAuthorize("isAuthenticated()")` |
| SR-S-02 | X-Frame-Options: DENY + CSP `frame-ancestors 'none'` dla heatmapy | Spring Security SecurityConfig |
| SR-S-03 | MitreAtlasRefValidator — allowlist T-kodów | `data/mitre-atlas-allowlist.json` |
| SR-S-04 | ML-SPECIFIC badge na kartach EMR/EIR/EOR/EDR | `edition === 'mlsec'` → mat-chip purple |
| SR-S-05 | Dane heatmapy cachowane Redis TTL 5 min | `@Cacheable("stride-heatmap")` Spring Cache |

### 9.2 AuthGuard Angular — implementacja

```typescript
// auth.guard.ts
export const authGuard: CanActivateFn = (route, state) => {
  const auth = inject(AuthService);
  const router = inject(Router);
  if (auth.isAuthenticated()) return true;
  return router.parseUrl('/login?returnUrl=' + state.url);
};
```

```typescript
// auth-guard.spec.ts
it('should redirect unauthenticated user to /login', async () => {
  jest.spyOn(authService, 'isAuthenticated').mockReturnValue(false);
  const result = await TestBed.runInInjectionContext(() =>
    authGuard(activatedRoute, routerState));
  expect((result as UrlTree).toString()).toContain('/login');
});
```

---

## 10. Faza 8 — Mobile + DevOps (Sprint 12–13, Tygodnie 23–26)

### 10.1 Wymagania bezpieczeństwa (US-17, US-18)

| ID | Wymaganie | Implementacja |
|---|---|---|
| SR-M-01 | MavsRefValidator — MASVS-*-* allowlist | `data/ref-allowlists.json` |
| SR-M-02 | CicdSecRefValidator — CICD-SEC-01–10 | `data/ref-allowlists.json` |
| SR-M-03 | OatRefValidator — OAT-001–021 | `data/ref-allowlists.json` |
| SR-M-04 | BotWarningDialog przed kartami BOT krytycznymi | `localStorage bot_warning_ack` + MatDialog |
| SR-M-05 | DVO kod: pseudokod bez działających exploitów | CI grep `CI_EXPLOIT_PATTERN` |
| SR-M-06 | Dogfooding: ThreatView sam wdraża ochronę BOT (D-11) | Bucket4j + BotWarningDialog |

### 10.2 BotWarningDialog — implementacja

```typescript
// devops-security.component.ts
openBotCard(card: CornucopiaCard): void {
  const ack = localStorage.getItem('bot_warning_ack') === 'true';
  if (ack || !card.isCritical) {
    this.router.navigate(['/threats', card.cardId]);
    return;
  }
  this.dialog.open(BotWarningDialogComponent, { width: '400px' })
    .afterClosed()
    .subscribe(confirmed => {
      if (confirmed) {
        localStorage.setItem('bot_warning_ack', 'true');
        this.router.navigate(['/threats', card.cardId]);
      }
    });
}
```

### 10.3 Abuse Cases — Mobile + DevOps

**AC-13: Credential Stuffing Rate Limit**
```java
@Test
void botSuiteEndpoint_shouldReturn429AfterRateLimit() {
    IntStream.range(0, 61).forEach(i -> {
        Response r = given()
            .header("X-Forwarded-For", "203.0.113.42")
            .queryParam("suit", "BOT")
            .get("/api/v1/threats");
        if (i == 60) assertThat(r.statusCode()).isEqualTo(429);
    });
}
```

**AC-14: SVG Injection w diagramie AAI**
```java
@Test
void agentDiagramEndpoint_shouldNotContainScriptTags() {
    String svg = given().get("/api/v1/threats/AAIK/diagram")
        .then().statusCode(200).extract().body().asString();
    assertThat(svg).doesNotContain("<script").doesNotContain("javascript:");
}
```

**AC-15: BotWarningDialog bypass via direct URL**
```typescript
// BotWarningBypassTest.cy.ts
it('should show BotWarningDialog when navigating directly to BOT card without ack', () => {
  cy.clearLocalStorage();
  cy.visit('/frameworks/devops-security');
  cy.get('[data-cy=bot-card-BOTK]').click();
  cy.get('mat-dialog-container').should('be.visible');
  cy.get('[data-cy=bot-warning-cancel]').click();
  cy.url().should('not.include', '/threats/BOTK');
});
```

---

## 11. Faza 9 — Integracja i Hardening (Sprint 14–16, Tygodnie 27–31)

### 11.1 Piramida testów

```
          /\
         /E2E\          ≥ 25 Cypress scenarios (us01–us18.cy.ts)
        /______\
       / IT     \       ≥ 40 Testcontainers (RestAssured + PostgreSQL 16)
      /__________\
     / Unit tests \     ≥ 75 JUnit 5 + Jest (components + services)
    /______________\
```

**Kolejność wykonania w CI:**
```
unit-tests → integration-tests → ng build → docker compose up (staging) → e2e-cypress → dast-zap
```

### 11.2 DAST — OWASP ZAP Full Active Scan

```yaml
# .github/workflows/dast.yml
- name: Start staging
  run: docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d

- name: ZAP Active Scan
  uses: zaproxy/action-full-scan@v0.10.0
  with:
    target: 'http://localhost:4200'
    fail_action: true       # CI fail jeśli MEDIUM+
    cmd_options: '-r zap-report.html'

- name: Upload report
  uses: actions/upload-artifact@v4
  with:
    name: zap-report
    path: zap-report.html
```

Znane false-positives do suppresji w `zap-suppressions.json`:
- `csrfcountermeasures` — wyłączone celowo (stateless JWT REST)
- `x-content-type-options` — obsługiwane przez Spring Security headers

### 11.3 Accessibility (WCAG 2.1 AA) — cypress-axe

```typescript
// Fragment każdego pliku *.cy.ts
beforeEach(() => {
  cy.visit(routeForThisSpec);
  cy.injectAxe();
});

it('should have no accessibility violations', () => {
  cy.checkA11y(null, {
    runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa'] }
  });
});
```

**Angular Material checklist:**
- `mat-table`: `aria-label` per kolumna, `aria-sort` na nagłówkach
- `mat-dialog`: `aria-modal="true"`, focus trap `CdkFocusTrap`
- `LanguageToggleComponent`: `aria-label="Zmień język / Change language"`
- Kontrast kolorów: indigo-amber theme ≥ 4.5:1 (zweryfikowany)

### 11.4 Angular Bundle Performance

```json
// angular.json — budgets
"budgets": [
  { "type": "initial", "maximumWarning": "500kb", "maximumError": "600kb" },
  { "type": "anyComponentStyle", "maximumWarning": "4kb", "maximumError": "8kb" }
]
```

| Bundle część | Cel | Strategia |
|---|---|---|
| Initial chunk | < 600 KB gzip | Lazy load via `loadComponent()` dla każdego feature |
| Prism.js per język | < 30 KB per język | `LazyPrismDirective`: `import()` gdy zakładka aktywna |
| ngx-echarts | ~200 KB | Tylko w CoverageComponent + StrideHeatmapComponent |
| i18n JSON | ~15 KB per język | Ładowany raz przy starcie, cachowany przez ngx-translate |

**OnPush w każdym komponencie** — `Default` change detection zakazany (lint rule w CI).

### 11.5 Monitoring produkcyjny

**Loki alerts:**

| ID | Trigger | Akcja |
|---|---|---|
| SEC-007 | `rate_limit_rejections_total > 5/min` od single IP | PagerDuty MEDIUM |
| SEC-008 | `content_integrity_check_ok == 0` przy starcie | PagerDuty CRITICAL → deployment blocked |
| SEC-009 | `AuthenticationFailureEvent > 10/min` | PagerDuty HIGH — potential brute-force |

**Prometheus metrics:**
```
content_integrity_check_ok{app="threatview"}    — gauge: 1=OK, 0=FAIL
rate_limit_rejections_total{endpoint="threats"} — counter
http_server_requests_seconds{uri="/api/v1/threats",le="0.2"}  — p95 < 200 ms SLO
```

---

## 12. Tabela mapowania: US → Zagrożenie → Abuse Case → Kontrola

| US | Zagrożenie główne | STRIDE / OWASP | Abuse Case | Kontrola techniczna | Test |
|---|---|---|---|---|---|
| US-01 | Nieuprawniony dostęp do frameworków | S — A07 | AC-02 | Spring Security JWT | `JwtValidationTest` |
| US-02 | SQL Injection w filtrach | E — A03 | AC-01 | JPA Specification, named params | `ThreatFilterSQLInjectionTest` |
| US-03 | Verbose error messages | I — A09 | — | GlobalExceptionHandler generic | `ErrorResponseTest` |
| US-04 | Data poisoning w cross-references | T — A03 | AC-01 | Bean validation DTOs | `CrossRefValidationIT` |
| US-05 | Clickjacking heatmapy | T — C05 | AC-08 | X-Frame-Options DENY | ZAP headerscan |
| US-06 | ReDoS via malicious query | D — A03 | AC-06 | Size(max=200) + tsvector | `SearchReDoSTest` |
| US-07 | CSV injection w eksporcie | T — A03 | AC-07 | Commons CSV QuoteMode.ALL | `CsvInjectionIT` |
| US-08 | ATLAS data tampering | T | — | Parameterized queries | `AtlasServiceTest` |
| US-09 | Injection w Scala snippet | T — A03 | — | plain String, no eval | `CodeSampleSecurityTest` |
| US-10 | Injection w Lua snippet | T — A03 | — | plain String, no eval | `CodeSampleSecurityTest` |
| US-11 | Header injection Accept-Language | T | — | LocaleInterceptor allowlist | `LocaleInterceptorTest` |
| US-12 | XSS w opisie karty FRE | XSS — A03/C03 | AC-04, AC-10 | DomSanitizer + OWASP HTML Sanitizer | `CornucopiaCardXSSTest` |
| US-13 | LLM card YAML poisoning | T — LLM04 | AC-11 | ContentIntegrityVerifier SHA-256 | `YamlIntegrityVerifierTest` |
| US-14 | AAI SVG injection | T — A03 | AC-14 | Server-side SVG rendering | `SvgInjectionTest` |
| US-15 | Clickjacking `/stride-heatmap` | T — C05 | AC-08 | X-Frame-Options DENY | ZAP headerscan |
| US-16 | Fałszywy MITRE ATLAS ID | T — A03 | AC-12 | MitreAtlasRefValidator | `MitreAtlasRefValidatorTest` |
| US-17 | Fałszywy MASVS ID | T — A03 | — | MavsRefValidator | `MavsRefValidatorTest` |
| US-18 | Bot scraping + BotDialog bypass | D — OAT-011 | AC-09, AC-13, AC-15 | Bucket4j + BotWarningDialog | `BotScrapingRateLimitIT` |

---

## 13. Checklista compliance SSDLC

### Faza 0 — Requirements & Threat Modeling
- [ ] STRIDE threat model dla ThreatView 2026 ukończony (sekcja 2.2)
- [ ] SAC-01–SAC-15 zdefiniowane i włączone do DoD (sekcja 2.3)
- [ ] CODEOWNERS skonfigurowane dla `/data/cornucopia/` — min. 2 zatwierdzenia @security-team
- [ ] Risk register zainicjowany (PLAN.md sekcja 14)
- [ ] OWASP SAMM assessment poziomu wyjściowego

### Faza 1 — Foundation
- [ ] Angular 18 strict mode (`strict: true`, `strictTemplates: true`)
- [ ] Spring Security 6 stateless JWT skonfigurowany
- [ ] Flyway migracje chronione przed ręcznym rollback
- [ ] Git pre-commit hooks: ESLint + SpotBugs + gitleaks aktywne
- [ ] CI pipeline (lint-and-sast, unit-tests, dependency-check, build, integration-tests, docker-scan) aktywny
- [ ] `.editorconfig`: charset utf-8, end_of_line lf
- [ ] Stack trace wyłączony w API responses (GlobalExceptionHandler)

### Fazy 2–4 — Development
- [ ] Wszystkie JPA queries: named params / Specification — brak string concat
- [ ] Bean validation na wszystkich DTO endpointach
- [ ] `DomSanitizer.sanitize(SecurityContext.HTML)` w CornucopiaCardComponent
- [ ] ESLint rule `no-bypass-security` aktywna i egzekwowana w CI
- [ ] `ChangeDetectionStrategy.OnPush` we wszystkich komponentach
- [ ] CSV export: `QuoteMode.ALL` (CSV injection prevention)
- [ ] Rate limit na `/api/v1/search` endpoint
- [ ] GlobalExceptionHandler: generic messages prod, stack trace tylko w logach

### Faza 5 — i18n
- [ ] Klucze i18n: tylko plain text, bez HTML
- [ ] `LocaleInterceptor`: allowlist 'pl'/'en' — nie przepuszcza raw navigator.language
- [ ] CI test `i18n-keys-parity.spec.ts` — fail build na niezgodność kluczy

### Fazy 6–8 — Cornucopia
- [ ] `ContentIntegrityVerifier` aktywny (fail-secure przy SHA-256 mismatch)
- [ ] `OwaspRefValidator` aktywny
- [ ] `MitreAtlasRefValidator` aktywny
- [ ] `MavsRefValidator`, `CicdSecRefValidator`, `OatRefValidator` aktywne
- [ ] Bucket4j rate limiting 60 req/min per IP na `/api/v1/threats?suit=*`
- [ ] `BotWarningDialogComponent` wyświetlany przed kartami BOT (BOTX, BOTJ, BOTK)
- [ ] `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` na `/stride-heatmap`
- [ ] `ML-SPECIFIC` mat-chip na kartach EMR/EIR/EOR/EDR
- [ ] `AUTONOMY RISK` mat-chip na kartach AAIK, AAIQ
- [ ] CI job `yaml-content-integrity` GREEN dla każdego PR zmieniającego YAML
- [ ] DVO kod: tylko pseudokod — `CI_EXPLOIT_PATTERN` grep GREEN

### Faza 9 — Hardening
- [ ] ZAP full active scan: 0 High/Critical alerts
- [ ] OWASP Dependency Check: 0 Critical CVEs
- [ ] npm audit: 0 High/Critical
- [ ] Trivy Docker scan: 0 CRITICAL
- [ ] axe-core (cypress-axe): 0 Critical/Serious WCAG 2.1 AA violations
- [ ] Lighthouse mobile Performance ≥ 85
- [ ] Lighthouse Accessibility ≥ 90
- [ ] `ng build --configuration production` initial chunk < 600 KB gzip
- [ ] Backend coverage ≥ 80% (JaCoCo report w CI)
- [ ] Frontend coverage ≥ 75% (Jest lcov w CI)
- [ ] Wszystkie 18 plików `*.cy.ts` GREEN
- [ ] Abuse cases AC-01–AC-15 GREEN
- [ ] Monitoring aktywny: Loki alerts SEC-007, SEC-008, SEC-009
- [ ] Prometheus metryki `content_integrity_check_ok` i `rate_limit_rejections_total`
- [ ] README: instrukcja `docker compose up` quick-start
