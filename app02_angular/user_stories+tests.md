# ThreatView 2026 — User Stories & TDD Test Plan

**Project:** ThreatView 2026  
**Version:** 1.0  
**Frontend:** Angular 18 + Angular Material  
**Backend:** Java 21 + Spring Boot 3.3  
**TDD Stack:**
- Backend: JUnit 5 + Mockito + Testcontainers (PostgreSQL 16) + RestAssured
- Frontend: Jest 29 + Angular Testing Library + Mock Service Worker (MSW 2)
- E2E: Cypress 13

---

## Summary

| ID | Role | User Story | Tests |
|---|---|---|---|
| US-01 | security engineer | browse framework catalogue | 3 test classes |
| US-02 | security engineer | filter threats by framework/severity/STRIDE/tag | 4 test classes |
| US-03 | security engineer | threat detail with mitigations and code samples | 4 test classes |
| US-04 | CompTIA SecAI+ student | cross-framework threat mapping | 4 test classes |
| US-05 | security trainer | STRIDE heatmap visual | 4 test classes |
| US-06 | pentester | global full-text search | 4 test classes |
| US-07 | team lead | export threats to CSV/PDF | 4 test classes |
| US-08 | developer | MITRE ATLAS kill-chain timeline | 4 test classes |
| US-09 | Scala developer | Scala code samples for supply-chain attacks | 3 test classes |
| US-10 | Lua/OpenResty developer | Lua rate limiting code samples | 3 test classes |
| US-11 | Polish-speaking student | PL ↔ EN language switch | 5 test classes |
| US-12 | frontend developer | OWASP Cornucopia FRE cards (client-side threats) | 4 test classes |
| US-13 | ML engineer | OWASP LLM Top 10 2025 via LLM cards + matrix | 4 test classes |
| US-14 | agentic AI developer | OWASP Agentic AI Top 10 2026 via AAI cards | 3 test classes |
| US-15 | security architect | STRIDE EoP catalogue + interactive heatmap | 5 test classes |
| US-16 | data scientist | ML security risks via MLSec cards + ATLAS refs | 3 test classes |
| US-17 | Android/iOS developer | OWASP MASVS via Mobile App cards + comparison | 4 test classes |
| US-18 | DevSecOps engineer | DevOps (DVO) + Automated Threats (BOT) cards | 5 test classes |

**Total test target:** ≥ 195 tests  
**Coverage target:** ≥ 80% backend line coverage, ≥ 75% frontend statement coverage

---

## US-01: Framework Catalogue

**Role:** Security engineer  
**Need:** Browse the security framework catalogue  
**Goal:** Have a single access point to all security standards

### Acceptance Criteria

- `GET /api/v1/frameworks` returns a list with `code`, `name`, `version`, `description` fields
- `FrameworkListComponent` renders a `mat-card` grid for each framework
- Clicking a framework card navigates to `/frameworks/:code`
- Each card shows framework version and number of covered threats
- Response is cached in Redis for 10 minutes (`@Cacheable("frameworks")`)
- Loading state shows Angular Material `mat-spinner`

### TDD Test Plan

**Backend: `FrameworkServiceTest.java`**
- `getAllFrameworks_returnsAllSeededFrameworks()`
- `getFrameworkByCode_returnsCorrectFramework()`
- `getFrameworkByCode_throwsNotFoundException_whenCodeDoesNotExist()`

**Backend: `FrameworkControllerIT.java`** (Testcontainers + RestAssured)
- `GET /api/v1/frameworks` → HTTP 200, body contains `OWASP_WEB`, `OWASP_LLM`, `MITRE_ATLAS`
- `GET /api/v1/frameworks/OWASP_WEB` → HTTP 200, `name` = "OWASP Top 10 Web Application Security Risks"
- `GET /api/v1/frameworks/UNKNOWN` → HTTP 404

**Frontend: `FrameworkList.spec.ts`** (Jest + ATL)
- renders `mat-card` for each framework in mocked API response
- shows `mat-spinner` while loading
- navigates to `/frameworks/OWASP_WEB` when OWASP Web card clicked
- displays framework version number on card

**E2E: `us01-framework-list.cy.ts`**
- visits `/frameworks`, asserts grid has at least 10 cards
- clicks "OWASP LLM Top 10 2025" card, asserts URL changes to `/frameworks/OWASP_LLM`

---

## US-02: Threat Browser with Filters

**Role:** Security engineer  
**Need:** Filter threats by framework, severity, STRIDE category, tag, and keyword  
**Goal:** Quickly find threats relevant to my project

### Acceptance Criteria

- `GET /api/v1/threats?frameworkCode=OWASP_WEB&severity=HIGH` returns filtered list
- `GET /api/v1/threats?stride=S` returns only threats with STRIDE Spoofing flag
- `GET /api/v1/threats?q=injection` returns full-text search results
- `ThreatBrowserComponent` renders `mat-sidenav` filter panel on the left
- Active filters shown as `mat-chip` set; each chip has an × to remove
- Results update reactively without page reload (RxJS `debounceTime(300)`)
- Pagination: `mat-paginator` with page sizes [10, 25, 50]

### TDD Test Plan

**Backend: `ThreatServiceTest.java`**
- `getThreats_withFrameworkFilter_returnsOnlyMatchingThreats()`
- `getThreats_withSeverityHIGH_returnsOnlyCriticalAndHighThreats()`
- `getThreats_withStrideS_returnsOnlySpoofingThreats()`
- `getThreats_withKeywordInjection_returnsRelevantThreats()`
- `getThreats_withNoFilters_returnsPaginatedList()`

**Backend: `ThreatControllerIT.java`**
- `GET /api/v1/threats` → HTTP 200, `page`, `totalElements` present
- `GET /api/v1/threats?frameworkCode=OWASP_LLM` → all returned threats have `frameworkCode = OWASP_LLM`
- `GET /api/v1/threats?severity=CRITICAL` → all returned threats have `severity = CRITICAL`
- `GET /api/v1/threats?q=sql+injection` → results contain SQL-related threats

**Frontend: `ThreatBrowser.spec.ts`**
- renders `mat-sidenav` with framework filter `mat-select`
- renders severity filter as `mat-button-toggle-group`
- emits filter change when user selects severity HIGH
- shows `mat-chip` for each active filter
- removes filter when chip × clicked
- calls API with debounce after keyword input
- shows `mat-paginator` at bottom of results

**E2E: `us02-threat-browser.cy.ts`**
- opens filter panel, selects "OWASP LLM Top 10 2025", verifies results show only LLM threats
- types "prompt injection" in search box, verifies LLM01 card appears in results
- removes framework filter chip, verifies all frameworks shown again

---

## US-03: Threat Detail with Mitigations and Code Samples

**Role:** Security engineer  
**Need:** See threat details with mitigations and code samples  
**Goal:** Understand how to implement the correct protection

### Acceptance Criteria

- `GET /api/v1/threats/:id` returns threat with nested `mitigations[]` and `codeSamples[]`
- `ThreatDetailComponent` shows `mat-tab-group` with tabs: Przegląd | Wektory ataku | Mitigacje | Kod | Powiązania
- Code samples tab has language selector (Python | Java | Go | Scala | Lua)
- Attack demo code has `PODATNY` red badge in top-right corner of code block
- Defense code has `BEZPIECZNY` green badge
- Syntax highlighting via Prism.js with lazy-loaded language packs
- Breadcrumb shows framework → threat title

### TDD Test Plan

**Backend: `ThreatDetailServiceTest.java`**
- `getThreatById_returnsFullThreatWithMitigationsAndCodeSamples()`
- `getThreatById_throwsNotFoundException_whenIdDoesNotExist()`
- `getCodeSamplesByThreatId_returnsAllFiveLanguages()`

**Backend: `ThreatDetailControllerIT.java`**
- `GET /api/v1/threats/{validId}` → HTTP 200, `mitigations` array not empty, `codeSamples` array has 5 elements
- `GET /api/v1/threats/{invalidId}` → HTTP 404
- `GET /api/v1/threats/{id}/code-samples?language=JAVA` → only Java samples returned

**Frontend: `ThreatDetail.spec.ts`**
- renders `mat-tab-group` with 5 tabs
- shows `PODATNY` badge on `sampleType=ATTACK_DEMO` code blocks
- shows `BEZPIECZNY` badge on `sampleType=DEFENSE` code blocks
- switches language when Scala tab clicked
- renders breadcrumb with correct framework name

**E2E: `us03-threat-detail.cy.ts`**
- navigates to `/threats/{id}`, verifies all 5 tab labels visible
- clicks Go tab, verifies Go code sample loads
- verifies `PODATNY` badge visible on attack demo code block

---

## US-04: Cross-Framework Mapping

**Role:** CompTIA SecAI+ student  
**Need:** See how LLM01 Prompt Injection maps to MITRE ATLAS AML.T0051  
**Goal:** Understand dependencies and overlaps between frameworks

### Acceptance Criteria

- `GET /api/v1/cross-references?sourceCode=LLM01` returns related threats in other frameworks
- Matrix page `/matrix` renders a scrollable `mat-table` with framework columns
- Cells show equivalent threat codes (e.g. `LLM01 ↔ AML.T0051 ↔ A03:2021`)
- `MatrixTableComponent` is exportable to CSV
- Relationship type shown as a `mat-tooltip` on hover (EQUIVALENT / RELATED / MAPS_TO)

### TDD Test Plan

**Backend: `CrossReferenceServiceTest.java`**
- `getCrossReferences_bySourceCode_returnsAllRelatedThreats()`
- `getCrossReferences_LLM01_mapsToMitreAtlasT0051()`
- `buildMatrix_returnsCompleteFrameworkCrossTable()`

**Backend: `CrossReferenceControllerIT.java`**
- `GET /api/v1/cross-references?sourceCode=LLM01` → HTTP 200, result includes `MITRE_ATLAS` entry with code `AML.T0051`
- `GET /api/v1/cross-references` → HTTP 200, matrix data structure returned

**Frontend: `MatrixTable.spec.ts`**
- renders `mat-table` with one row per source threat
- shows framework code columns as `mat-header-cell`
- shows relationship type in `mat-tooltip` on cell hover
- calls export API when export button clicked

**E2E: `us04-cross-reference.cy.ts`**
- navigates to `/matrix`, verifies LLM01 row exists
- hovers MITRE ATLAS cell for LLM01, verifies tooltip shows "MAPS_TO: AML.T0051"

---

## US-05: STRIDE Heatmap

**Role:** Security trainer  
**Need:** Display STRIDE coverage heatmap on a projector  
**Goal:** Visually explain STRIDE threat coverage during workshops

### Acceptance Criteria

- `GET /api/v1/stats/coverage` returns coverage percentages per framework per STRIDE category
- `StrideHeatmapComponent` renders Apache ECharts heatmap (6 STRIDE × N frameworks)
- Color scale: green (≥80%) → yellow (40–79%) → red (<40%)
- Heatmap is responsive, fits 1280×720 projector resolution
- `/stride-heatmap` route is guarded by `AuthGuard` (JWT required)
- Unauthenticated users are redirected to `/login`

### TDD Test Plan

**Backend: `StrideCoverageServiceTest.java`**
- `getCoverageStats_returnsCorrectPercentages_forEachFrameworkAndStrideCategory()`
- `calculateStrideCoverage_returnsZero_whenNoThreatsSeeded()`

**Backend: `CoverageControllerIT.java`**
- `GET /api/v1/stats/coverage` (no auth) → HTTP 401
- `GET /api/v1/stats/coverage` (with valid JWT) → HTTP 200, contains STRIDE keys S, T, R, I, D, E

**Frontend: `StrideHeatmapComponent.spec.ts`**
- renders ECharts container div when data loaded
- shows error message when API returns 401
- applies red background for coverage < 40%
- applies green background for coverage ≥ 80%

**Frontend: `AuthGuard.spec.ts`**
- returns `true` when valid JWT present in localStorage
- redirects to `/login` when no JWT present
- redirects to `/login` when JWT is expired

**E2E: `us05-stride-heatmap.cy.ts`**
- visits `/stride-heatmap` without token → asserts redirect to `/login`
- logs in, visits `/stride-heatmap` → asserts ECharts canvas rendered

---

## US-06: Global Full-Text Search

**Role:** Pentester  
**Need:** Search "deepfake" and find all related threats with defenses  
**Goal:** Build a test checklist for a client quickly

### Acceptance Criteria

- `GET /api/v1/search?q=deepfake` returns threats + mitigations + code samples with matching text
- Each result shows a highlighted snippet with search terms in `<mark>` tags
- `SearchResultsComponent` groups results by type (Threats | Mitigations | Code Samples)
- Keyboard shortcut Ctrl+K opens global search overlay `mat-dialog`
- Results debounced: API called 300ms after last keystroke
- Empty state shows "Brak wyników dla: X" with suggestion to broaden query

### TDD Test Plan

**Backend: `SearchServiceTest.java`**
- `search_deepfake_returnsRelevantThreats()`
- `search_withEmptyQuery_returnsEmptyList()`
- `search_withSpecialCharacters_doesNotCrash()`
- `search_returnsHighlightedSnippets()`

**Backend: `SearchControllerIT.java`**
- `GET /api/v1/search?q=prompt+injection` → HTTP 200, at least 1 threat with `code=LLM01` in results
- `GET /api/v1/search?q=` → HTTP 400 bad request
- `GET /api/v1/search?q=xyzabc123notexisting` → HTTP 200, `totalResults=0`

**Frontend: `SearchResults.spec.ts`**
- renders grouped result sections for Threats, Mitigations, Code Samples
- shows `<mark>` wrapped text in result snippets
- shows empty-state message when results array is empty
- opens search dialog on Ctrl+K keyboard event

**E2E: `us06-global-search.cy.ts`**
- presses Ctrl+K, types "sql injection", verifies result list loads
- clicks first result, verifies navigation to threat detail page

---

## US-07: Export to CSV / PDF

**Role:** Team lead  
**Need:** Export the currently filtered list of threats to CSV  
**Goal:** Include threats in the project risk register

### Acceptance Criteria

- `GET /api/v1/export?format=csv&frameworkCode=OWASP_LLM` returns downloadable CSV file
- `GET /api/v1/export?format=pdf&frameworkCode=OWASP_LLM` returns downloadable PDF
- CSV includes columns: ID, Framework, Code, Title, Severity, STRIDE, Tags
- PDF includes framework name as header, threats as table rows
- Export button in `ThreatBrowserComponent` uses currently active filters
- Browser download triggered via `<a href> download` attribute (no new tab)

### TDD Test Plan

**Backend: `ExportServiceTest.java`**
- `exportCsv_withFrameworkFilter_returnsCorrectlySeparatedRows()`
- `exportCsv_headerRowContainsAllExpectedColumns()`
- `exportPdf_returnsNonEmptyByteArray()`

**Backend: `ExportControllerIT.java`**
- `GET /api/v1/export?format=csv` → HTTP 200, `Content-Type: text/csv`, body starts with expected headers
- `GET /api/v1/export?format=pdf` → HTTP 200, `Content-Type: application/pdf`
- `GET /api/v1/export?format=xls` → HTTP 400 unsupported format

**Frontend: `ExportButton.spec.ts`**
- renders `mat-button` with download icon
- calls export API with correct current filter params when clicked
- triggers browser download on successful response

**E2E: `us07-export.cy.ts`**
- applies OWASP LLM filter, clicks Export CSV → verifies download triggered

---

## US-08: MITRE ATLAS Kill-Chain Timeline

**Role:** Developer  
**Need:** MITRE ATLAS kill-chain attack phase timeline  
**Goal:** Understand at which attack phase each ATLAS technique is used

### Acceptance Criteria

- `GET /api/v1/atlas/timeline` returns techniques grouped by kill-chain phase (Reconnaissance → Impact)
- `AtlasTimelineComponent` renders horizontal timeline using Angular Material Stepper or custom SVG
- Each technique node links to `/threats/:id`
- Timeline is filterable by tactic phase via `mat-select`
- Hovering a node shows technique details in `mat-tooltip`

### TDD Test Plan

**Backend: `AtlasTimelineServiceTest.java`**
- `getAtlasTechniquesGroupedByPhase_returnsCorrectPhaseOrder()`
- `getAtlasTimelineData_mapsT0051_toReconnaissancePhase()`
- `getAtlasTimelineData_returnsEmptyPhases_whenNoDataSeeded()`

**Backend: `AtlasControllerIT.java`**
- `GET /api/v1/atlas/timeline` → HTTP 200, phases array not empty, `phases[0].name = "Reconnaissance"`
- `GET /api/v1/atlas/timeline?phase=Impact` → only Impact phase techniques returned

**Frontend: `AtlasTimeline.spec.ts`**
- renders one node per technique in mocked data
- applies active style to selected phase filter
- shows technique title in mat-tooltip on mouseover
- navigates to `/threats/:id` on technique node click

**E2E: `us08-atlas-timeline.cy.ts`**
- navigates to `/matrix/atlas-timeline`, verifies phase nodes visible
- clicks Reconnaissance phase filter, verifies timeline filtered

---

## US-09: Scala Code Samples for Supply-Chain Attacks

**Role:** Scala developer  
**Need:** Code samples for supply-chain attacks in Scala  
**Goal:** Implement Software Composition Analysis in a Scala build pipeline

### Acceptance Criteria

- `GET /api/v1/code-samples?language=SCALA` returns all Scala samples
- `GET /api/v1/threats/{supplyChainThreatId}/code-samples?language=SCALA` returns Scala sample
- `CodeSamplePanelComponent` shows Scala tab in language selector
- Scala sample includes both attack demo and defense pattern
- `frameworkHint` field shows "sbt 1.9 / Scala 3.4"

### TDD Test Plan

**Backend: `CodeSampleServiceTest.java`** (language filter section)
- `getCodeSamples_withScalaFilter_returnsOnlyScalaSamples()`
- `getCodeSamples_forSupplyChainThreat_returnsScalaDefensePattern()`

**Backend: `CodeSampleControllerIT.java`**
- `GET /api/v1/code-samples?language=SCALA` → HTTP 200, all results have `language=SCALA`
- `GET /api/v1/code-samples?language=SCALA&sampleType=DEFENSE` → only defense Scala samples

**Frontend: `CodeSamplePanel.spec.ts`** (Scala tab section)
- shows Scala as one of five language tabs
- displays Scala code when Scala tab selected
- shows `PODATNY` badge on attack demo Scala code
- preserves Scala code without translating when locale switches to `pl`

---

## US-10: Lua Code Samples for LLM Rate Limiting

**Role:** Lua/OpenResty developer  
**Need:** Lua examples for rate limiting to prevent LLM DoS attacks  
**Goal:** Configure NGINX guardrails for an LLM API proxy

### Acceptance Criteria

- `GET /api/v1/code-samples?language=LUA` returns all Lua samples
- Lua samples for LLM DoS threats include OpenResty `ngx.shared.DICT` rate limiting pattern
- `frameworkHint` shows "OpenResty 1.25 / NGINX Lua"
- Code samples are never translated regardless of active locale

### TDD Test Plan

**Backend: `CodeSampleServiceTest.java`** (Lua section)
- `getCodeSamples_withLuaFilter_returnsOnlyLuaSamples()`
- `getLuaSampleForLlmDosThreat_containsOpenRestyRateLimitingCode()`

**Backend: `CodeSampleControllerIT.java`**
- `GET /api/v1/code-samples?language=LUA` → HTTP 200, all `language=LUA`
- `GET /api/v1/code-samples?language=LUA&frameworkCode=OWASP_LLM` → returns relevant LLM Lua samples

**Frontend: `CodeSamplePanel.spec.ts`** (Lua tab section)
- shows Lua as one of five language tabs
- Lua code content unchanged when locale = `pl`
- shows `OpenResty 1.25` in framework hint badge

---

## US-11: Polish ↔ English Language Switch

**Role:** Polish-speaking student  
**Need:** Switch the entire application from English to Polish with a single click  
**Goal:** Learn all threat and mitigation descriptions in their native language

### Acceptance Criteria

- `LanguageToggleComponent` visible in `mat-toolbar` as `mat-button-toggle-group`
- Clicking **PL** switches `ngx-translate` language to `pl` — all UI text changes immediately (no page reload)
- Clicking **EN** switches to `en`
- Code samples are **never** translated — only UI labels and threat descriptions
- Language preference persisted in `localStorage` key `tv_locale`
- `LocaleInterceptor` appends `Accept-Language: pl` or `Accept-Language: en` header to every API request
- `Content-Language` response header returned by backend
- API returns `descriptionPl` or `descriptionEn` based on `Accept-Language` header

### TDD Test Plan

```typescript
// LanguageToggle.spec.ts (Jest + Angular Testing Library)
describe('LanguageToggleComponent', () => {
  let translateService: TranslateService;

  beforeEach(() => {
    TestBed.configureTestingModule({
      imports: [TranslateModule.forRoot(), MatButtonToggleModule],
      declarations: [LanguageToggleComponent]
    });
    translateService = TestBed.inject(TranslateService);
  });

  it('should emit "pl" when PL button clicked', () => {
    const { getByText } = render(LanguageToggleComponent);
    fireEvent.click(getByText('PL'));
    expect(translateService.currentLang).toBe('pl');
  });

  it('should emit "en" when EN button clicked', () => {
    const { getByText } = render(LanguageToggleComponent);
    fireEvent.click(getByText('EN'));
    expect(translateService.currentLang).toBe('en');
  });

  it('should persist locale to localStorage key tv_locale', () => {
    const { getByText } = render(LanguageToggleComponent);
    fireEvent.click(getByText('PL'));
    expect(localStorage.getItem('tv_locale')).toBe('pl');
  });

  it('should initialize from localStorage on startup', () => {
    localStorage.setItem('tv_locale', 'pl');
    render(LanguageToggleComponent);
    expect(translateService.currentLang).toBe('pl');
  });
});
```

```typescript
// LocaleInterceptor.spec.ts (Jest)
describe('LocaleInterceptor', () => {
  let httpTestingController: HttpTestingController;
  let http: HttpClient;

  beforeEach(() => {
    localStorage.setItem('tv_locale', 'pl');
    TestBed.configureTestingModule({
      imports: [HttpClientTestingModule],
      providers: [{ provide: HTTP_INTERCEPTORS, useClass: LocaleInterceptor, multi: true }]
    });
    httpTestingController = TestBed.inject(HttpTestingController);
    http = TestBed.inject(HttpClient);
  });

  it('should add Accept-Language: pl header when locale is pl', () => {
    http.get('/api/v1/frameworks').subscribe();
    const req = httpTestingController.expectOne('/api/v1/frameworks');
    expect(req.request.headers.get('Accept-Language')).toBe('pl');
  });

  it('should add Accept-Language: en header when locale is en', () => {
    localStorage.setItem('tv_locale', 'en');
    http.get('/api/v1/frameworks').subscribe();
    const req = httpTestingController.expectOne('/api/v1/frameworks');
    expect(req.request.headers.get('Accept-Language')).toBe('en');
  });

  it('should default to en when tv_locale is not in localStorage', () => {
    localStorage.removeItem('tv_locale');
    http.get('/api/v1/frameworks').subscribe();
    const req = httpTestingController.expectOne('/api/v1/frameworks');
    expect(req.request.headers.get('Accept-Language')).toBe('en');
  });
});
```

```typescript
// I18nParity.spec.ts (Jest — build-time check)
import * as pl from '../assets/i18n/pl.json';
import * as en from '../assets/i18n/en.json';

describe('i18n key parity', () => {
  it('pl.json and en.json must have identical top-level keys', () => {
    const plKeys = Object.keys(pl).sort();
    const enKeys = Object.keys(en).sort();
    expect(plKeys).toEqual(enKeys);
  });

  it('pl.json must have at least 50 translation keys', () => {
    expect(Object.keys(pl).length).toBeGreaterThanOrEqual(50);
  });

  it('code sample fields must not exist in translation files', () => {
    // code samples are never in i18n files — they live in API responses only
    expect(Object.keys(pl)).not.toContain('codeSample');
    expect(Object.keys(pl)).not.toContain('codeSnippet');
  });
});
```

**Backend: `LocalizationIT.java`** (Testcontainers)
- `GET /api/v1/threats/{id}` with `Accept-Language: pl` → response body `description` is Polish
- `GET /api/v1/threats/{id}` with `Accept-Language: en` → response body `description` is English
- `GET /api/v1/threats/{id}` with no `Accept-Language` → defaults to English
- `Content-Language` header present in all threat API responses

**E2E: `us11-language-switch.cy.ts`**
```javascript
describe('Language Switch US-11', () => {
  it('switches UI to Polish when PL button clicked', () => {
    cy.visit('/');
    cy.get('[data-cy=lang-toggle-pl]').click();
    cy.get('[data-cy=nav-frameworks]').should('contain.text', 'Frameworki');
    cy.get('[data-cy=nav-search]').should('contain.text', 'Szukaj');
  });

  it('persists Polish locale after page reload', () => {
    cy.visit('/');
    cy.get('[data-cy=lang-toggle-pl]').click();
    cy.reload();
    cy.get('[data-cy=nav-frameworks]').should('contain.text', 'Frameworki');
  });

  it('sends Accept-Language: pl header to API when Polish selected', () => {
    cy.intercept('GET', '/api/v1/threats*').as('threatsRequest');
    cy.visit('/threats');
    cy.get('[data-cy=lang-toggle-pl]').click();
    cy.wait('@threatsRequest').its('request.headers')
      .should('have.property', 'accept-language', 'pl');
  });

  it('does not translate code sample content', () => {
    cy.visit('/threats');
    cy.get('[data-cy=lang-toggle-pl]').click();
    cy.get('[data-cy=threat-card]').first().click();
    cy.get('[data-cy=code-tab]').click();
    cy.get('[data-cy=code-snippet]').should('not.contain', 'Podatny');
  });
});
```

---

## US-12: Frontend / Client-Side Security — Cornucopia FRE Cards

**Role:** Frontend / React developer  
**Need:** Browse OWASP Cornucopia FRE (Frontend) cards with Polish descriptions and OWASP Client-Side Top 10 references  
**Goal:** Map client-side attack scenarios to mitigations in their Angular/React application

### OWASP Cornucopia FRE Cards — Polish Translations

| Card ID | Value | Polish Description | OWASP References |
|---|---|---|---|
| FRE2 | 2 | Brian może zebrać informacje o konfiguracji klienta z powodu nadmiernie gadatliwych komunikatów o błędach JavaScript | Client-Side C01 |
| FRE3 | 3 | Robert może wstrzyknąć złośliwe dane przez niewalidowane parametry URL lub formularze klienta | A03:2021, Client-Side C03 |
| FRE4 | 4 | Ana może sfałszować token JWT lub sesję OAuth, wstrzykując złośliwe claimy z powodu braku weryfikacji sygnatury po stronie klienta | A02:2021 Cryptographic Failures, Client-Side C04 |
| FRE5 | 5 | Jee może wykraść dane z localStorage/sessionStorage z powodu braku szyfrowania wrażliwych danych po stronie klienta | A02:2021, Client-Side C02 |
| FRE6 | 6 | Jason może przeprowadzić atak CSRF przez nakłonienie użytkownika do wykonania niepożądanej akcji | A01:2021, Client-Side C06 |
| FRE7 | 7 | Jan może zidentyfikować używane biblioteki frontend przez analizę bundle.js i wykorzystać znane podatności | A06:2021, Client-Side C08 |
| FRE8 | 8 | Oana może przeprowadzić atak Reverse Tabnapping przez złośliwy link otwierany w nowej karcie bez `rel=noopener` | Client-Side C09 |
| FRE9 | 9 | Sam może zmienić prawa dostępu po stronie klienta (ukryte pola, parametry URL) z powodu braku walidacji server-side | A01:2021 Broken Access Control |
| FREX | 10 | Carlos może przeprowadzić atak clickjacking na wrażliwe akcje (przelewy) z powodu braku nagłówka X-Frame-Options lub dyrektywy CSP frame-ancestors | OWASP Client-Side C05 |
| FREJ | J | Priya może wykonać atak DOM-based XSS przez manipulację `document.location` lub `innerHTML` bez sanityzacji | A03:2021 Injection, Client-Side C03 |
| FREQ | Q | Marco może obejść zabezpieczenia CORS przez błędną konfigurację `Access-Control-Allow-Origin: *` na API | A05:2021 Security Misconfiguration |
| FREK | K | Nikita może wstrzyknąć złośliwy skrypt przez Content-Type sniffing z powodu braku nagłówka `X-Content-Type-Options: nosniff` | Client-Side C07 |

### Acceptance Criteria

- `GET /api/v1/threats?suit=FRE` returns 13 FRE cards
- `FrontendSecurityComponent` renders `mat-grid-list` with one `mat-card` per card
- Cards with value J, Q, K show a `CRITICAL` red `mat-chip` badge
- `DomSanitizer.bypassSecurityTrustHtml` is NOT used — Angular's default sanitization applied
- Polish descriptions rendered when locale = `pl`; English when locale = `en`
- Each card shows `mat-chip-set` with OWASP reference IDs

### TDD Test Plan

```typescript
// FrontendThreatService.spec.ts (Jest + MSW)
describe('FrontendThreatService', () => {
  let service: FrontendThreatService;
  let server: SetupServer;

  beforeAll(() => {
    server = setupServer(
      rest.get('/api/v1/threats', (req, res, ctx) => {
        if (req.url.searchParams.get('suit') === 'FRE') {
          return res(ctx.json(mockFreCards));
        }
      })
    );
    server.listen();
  });

  it('should load all 13 FRE cards with suit=FRE filter', async () => {
    const cards = await firstValueFrom(service.getFreCards());
    expect(cards).toHaveLength(13);
  });

  it('should return Polish description when locale is pl', async () => {
    const card = await firstValueFrom(service.getCard('FREK', 'pl'));
    expect(card.description).toContain('Content-Type sniffing');
    expect(card.description).toMatch(/^Nikita może/);
  });

  it('should return English description when locale is en', async () => {
    const card = await firstValueFrom(service.getCard('FREK', 'en'));
    expect(card.description).toMatch(/^Nikita can/);
  });

  it('should mark cards FREJ, FREQ, FREK as isCritical=true', async () => {
    const cards = await firstValueFrom(service.getFreCards());
    const criticalIds = cards.filter(c => c.isCritical).map(c => c.cardId);
    expect(criticalIds).toContain('FREJ');
    expect(criticalIds).toContain('FREQ');
    expect(criticalIds).toContain('FREK');
  });

  it('should include owaspRefs array for each card', async () => {
    const cards = await firstValueFrom(service.getFreCards());
    cards.forEach(card => {
      expect(card.owaspRefs).toBeDefined();
      expect(Array.isArray(card.owaspRefs)).toBe(true);
    });
  });
});
```

```typescript
// FrontendSecurityComponent.spec.ts (Jest + ATL)
describe('FrontendSecurityComponent', () => {
  it('should render mat-card for each FRE card in mocked API response')
  it('should show CRITICAL mat-chip on FREK card')
  it('should display Polish description when locale=pl')
  it('should NOT use bypassSecurityTrustHtml — Angular sanitization only')
  it('should show owaspRefs as mat-chip-set on each card')
  it('should navigate to /threats/FREK on FREK card click')
  it('should show mat-spinner while cards are loading')
  it('should show error snackbar on API 500 error')
});
```

**Backend: `FrontendThreatControllerIT.java`** (Testcontainers + RestAssured)
```java
@Test void getFreCards_returns13Cards() {
    given().when().get("/api/v1/threats?suit=FRE")
        .then().statusCode(200).body("content.size()", equalTo(13));
}
@Test void getFreCards_withLangPl_returnPolishDescriptions() {
    given().header("Accept-Language", "pl")
        .when().get("/api/v1/threats?suit=FRE")
        .then().statusCode(200)
        .body("content[11].description", startsWith("Nikita może"));
}
@Test void getFreKCard_isCritical_andContainsOwaspRef() {
    given().when().get("/api/v1/threats/FREK")
        .then().statusCode(200)
        .body("isCritical", equalTo(true))
        .body("owaspRefs", hasItem("Client-Side C07"));
}
```

**E2E: `us12-frontend-security.cy.ts`**
```javascript
describe('FRE Cards — US-12', () => {
  it('shows 13 FRE cards in grid', () => {
    cy.visit('/frameworks/frontend-security');
    cy.get('[data-cy=cornucopia-card]').should('have.length', 13);
  });
  it('shows CRITICAL badge on FREK card', () => {
    cy.visit('/frameworks/frontend-security');
    cy.get('[data-cy=card-FREK] [data-cy=critical-badge]').should('be.visible');
  });
  it('displays Polish descriptions when locale=pl', () => {
    cy.get('[data-cy=lang-toggle-pl]').click();
    cy.get('[data-cy=card-FREK] [data-cy=card-description]')
      .should('contain', 'Nikita może');
  });
});
```

---

## US-13: LLM Security — Cornucopia LLM Cards + Matrix

**Role:** ML engineer / AI architect  
**Need:** Explore all 10 OWASP LLM Top 10 2025 threats via Cornucopia LLM cards with an interactive matrix  
**Goal:** Understand prompt injection, data poisoning, excessive agency, and supply-chain risks in LLM systems

### OWASP Cornucopia LLM Cards — Polish Translations

| Card ID | Value | Polish Description | OWASP LLM 2025 | MITRE ATLAS |
|---|---|---|---|---|
| LLM2 | 2 | Samantha może wyczerpać zasoby obliczeniowe przez rekurencyjne lub intensywne zapytania LLM, prowadząc do DoS modelu i wzrostu kosztów | LLM10 Unbounded Consumption | T0029 |
| LLM3 | 3 | Dave może wykorzystać nadmierne poleganie na wynikach LLM bez nadzoru człowieka, prowadząc do błędnych decyzji na podstawie halucynacji | LLM09 Misinformation | — |
| LLM4 | 4 | David może skłonić model do ujawnienia wrażliwych danych z treningu, promptów systemowych lub sesji innych użytkowników przez niewystarczające filtrowanie wyjść | LLM06 Sensitive Information Disclosure | T0036 |
| LLM5 | 5 | Roy może eskalować uprawnienia lub uzyskać dostęp do danych innych użytkowników przez słabą autentykację lub błędną izolację sesji w systemach multi-tenant | LLM05 Improper Output Handling | — |
| LLM6 | 6 | Andersen może manipulować bazami wiedzy RAG lub źródłami MCP, aby model prezentował fałszywe informacje jako fakty | LLM08 Vector and Embedding Weaknesses | T0020 |
| LLM7 | 7 | Tyrell może zatruć dane treningowe lub zbiory fine-tuningu, wprowadzając backdoor aktywowany przez specjalny trigger | LLM04 Data and Model Poisoning | T0020 |
| LLM8 | 8 | Rossum może nadużyć niezabezpieczonych pluginów, serwerów MCP lub integracji do dostępu do wrażliwych danych lub obejścia autentykacji przez interfejs LLM | LLM07 System Prompt Leakage | — |
| LLM9 | 9 | Deckard może osadzić złośliwe instrukcje w dokumentach, e-mailach lub stronach internetowych przetwarzanych przez model, prowadząc do niezamierzonego zachowania lub eksfiltracji danych | LLM02 Sensitive Information Disclosure (indirect) | T0051 |
| LLMX | 10 | Sarah może nadpisać lub zmanipulować prompt systemowy przez spreparowane wejście, powodując pominięcie ograniczeń modelu lub nieautoryzowane działania | LLM01 Prompt Injection | T0051 |
| LLMJ | J | Ripley może wprowadzić skompromitowane modele firm trzecich, osadzenia lub złośliwe komponenty ML do łańcucha dostaw, prowadząc do ukrytych podatności | LLM03 Supply Chain Vulnerabilities | T0010 |
| LLMQ | Q | Kyle może wykorzystać niezabezpieczoną obsługę wyjść modelu używanych bezpośrednio w systemach downstream, umożliwiając ataki injection lub nieautoryzowane działania | LLM02 Insecure Output Handling | — |
| LLMK | K | Ava może wykorzystać nadmierną autonomię pluginów lub agentów AI do nieautoryzowanych, wysokoryzykownych działań z powodu braku human-in-the-loop | LLM06 Excessive Agency | T0047 |

### Acceptance Criteria

- `GET /api/v1/threats?suit=LLM` returns 13 LLM cards
- `GET /api/v1/matrix/llm` returns 10-row matrix (LLM01–LLM10) × Cornucopia cards
- `LlmMatrixComponent` renders `mat-table` with 10 LLM threat rows
- Each row shows mapped Cornucopia card IDs as `mat-chip` elements
- Cards with `isCritical=true` (K, Q, J) highlighted in `warn` color palette

### TDD Test Plan

```typescript
// LlmThreatService.spec.ts (Jest + MSW)
describe('LlmThreatService', () => {
  it('should return 13 LLM cards from GET /api/v1/threats?suit=LLM')
  it('should map LLMX card to LLM01:2025 identifier in owaspRefs')
  it('should map LLMK card to LLM06:2025 Excessive Agency')
  it('should load LLM×cards matrix object from /api/v1/matrix/llm')
  it('should translate LLMK description to Polish when locale=pl')
  it('should return English description for LLMK when locale=en')
});

// LlmMatrixComponent.spec.ts (Jest + ATL)
describe('LlmMatrixComponent', () => {
  it('should render mat-table with 10 rows (LLM01–LLM10)')
  it('should show Cornucopia card IDs in matrix cells as mat-chips')
  it('should apply warn color class to critical card chips')
  it('should navigate to /threats/:cardId when card chip clicked')
  it('should show empty cell when no card maps to an LLM threat')
});
```

**Backend: `LlmThreatControllerIT.java`**
- `GET /api/v1/threats?suit=LLM` → HTTP 200, 13 cards
- `GET /api/v1/threats/LLMX?lang=pl` → `description` starts with "Sarah może"
- `GET /api/v1/matrix/llm` → HTTP 200, object with key `LLM01` containing `LLMX`

**E2E: `us13-llm-security.cy.ts`**

---

## US-14: Agentic AI — Cornucopia AAI Cards

**Role:** Agentic AI developer  
**Need:** Study OWASP Agentic AI Top 10 2026 threats via Cornucopia AAI cards  
**Goal:** Design human-in-the-loop safeguards for autonomous agent pipelines

### OWASP Cornucopia AAI Cards — Polish Translations (key cards)

| Card ID | Value | Polish Description | AgentAI Ref |
|---|---|---|---|
| AAIK | K | Agent może wykonać nieautoryzowane, wysokoryzykowne działania z powodu nadmiernej autonomii i braku mechanizmu zatwierdzenia przez człowieka (human-in-the-loop) | AgentAI07 Uncontrolled Recursion / Excessive Autonomy |
| AAIJ | J | Attacker może skłonić agenta do ujawnienia lub zmodyfikowania wrażliwych danych przez niewalidowany łańcuch zaufania między agentami | AgentAI10 Inadequate Identity Verification |
| AAIQ | Q | Agent może zostać skłoniony do pominięcia bezpiecznych domyślnych konfiguracji przez zmanipulowany cel wstrzyknięty w orkiestrację | AgentAI09 Orchestration Manipulation |
| AAIX | 10 | Attacker może wstrzyknąć złośliwe instrukcje do systemu multi-agent przez niebezpieczne przesyłanie kontekstu między agentami | AgentAI05 Multi-Agent Trust Exploitation |
| AAIJ | 9 | Agent może przeprowadzić ataki na zasoby zewnętrzne z powodu nieograniczonego dostępu do API bez sandboxingu | AgentAI03 Insufficient Sandboxing |

### Acceptance Criteria

- `GET /api/v1/threats?suit=AAI` returns 13 AAI cards
- `AgenticAiComponent` shows `AUTONOMY RISK` orange badge on AAIK and AAIQ cards
- Navigation button opens `/matrix/agentic` — AgentAI × LLM comparison matrix
- Polish descriptions shown when locale = `pl`

### TDD Test Plan

```typescript
// AgenticAiComponent.spec.ts (Jest + ATL)
describe('AgenticAiComponent', () => {
  it('should render 13 AAI cards in mat-grid-list')
  it('should show AUTONOMY RISK badge on AAIK card')
  it('should show AUTONOMY RISK badge on AAIQ card')
  it('should NOT show AUTONOMY RISK badge on non-critical cards')
  it('should show AgentAI reference chips on each card')
  it('should navigate to /matrix/agentic when matrix button clicked')
  it('should display Polish descriptions for AAI cards when locale=pl')
});
```

**Backend: `AgenticThreatControllerIT.java`**
- `GET /api/v1/threats?suit=AAI` → HTTP 200, 13 cards
- `GET /api/v1/threats/AAIK` → `agentAiRefs` contains `AgentAI07`
- `GET /api/v1/matrix/agentic` → HTTP 200, matrix with AgentAI01–AgentAI10 rows

**E2E: `us14-agentic-ai.cy.ts`**

---

## US-15: STRIDE EoP — Catalogue + Interactive Heatmap

**Role:** Security architect / threat modeler  
**Need:** STRIDE EoP card catalogue and interactive heatmap per system component  
**Goal:** Run a structured threat-modeling session and map findings to OWASP Web Top 10

### STRIDE EoP King Cards — Polish Translations

| Card ID | Suit | Polish Description | STRIDE | OWASP Mapping |
|---|---|---|---|---|
| SPK | Spoofing | System dostarcza domyślne hasło admina i nie wymusza jego zmiany przy pierwszym logowaniu | S | A07:2021 Authentication Failures |
| TAK | Tampering | Kod podejmuje decyzje kontroli dostępu wszędzie, zamiast w centralnym jądrze bezpieczeństwa | T | A01:2021 Broken Access Control |
| REK | Repudiation | Logi systemowe nie są niemodyfikowalne i mogą zostać usunięte przez atakującego z dostępem do systemu plików | R | A09:2021 Logging Failures |
| IDK | Information Disclosure | Attacker może odczytać wrażliwe dane z pamięci procesu (klucze, hasła) po uzyskaniu dostępu | I | A02:2021 Cryptographic Failures |
| DSK | Denial of Service | Attacker może przeprowadzić atak amplifikacji DoS — małe zapytanie wywołuje dużą odpowiedź serwera | D | — |
| EPK | Elevation of Privilege | Attacker może uzyskać uprawnienia administratora przez SQL injection w zapytaniu bez parametryzacji | E | A01:2021 + A03:2021 |

### Acceptance Criteria

- `GET /api/v1/threats/stride/categories` returns 6 STRIDE categories with card counts
- `StrideCatalogueComponent` shows 6 `mat-expansion-panel` sections (S, T, R, I, D, E)
- Each panel contains 13 `mat-card` items for that suit
- King cards highlighted with `warn` color border
- `StrideHeatmapComponent` at `/stride-heatmap` requires JWT (`AuthGuard`)
- Heatmap built with Apache ECharts showing coverage percentages

### TDD Test Plan

```typescript
// StrideCatalogueComponent.spec.ts (Jest + ATL)
describe('StrideCatalogueComponent', () => {
  it('should render 6 mat-expansion-panel sections')
  it('should label panels S, T, R, I, D, E with STRIDE full names')
  it('should show 13 cards per expansion panel')
  it('should highlight King card (SPK) with warn border')
  it('should display Polish descriptions when locale=pl')
  it('should show OWASP reference chips for each card that has mappings')
});

// StrideHeatmapComponent.spec.ts (Jest + ATL)
describe('StrideHeatmapComponent', () => {
  it('should render ECharts heatmap container div when authenticated')
  it('should show 6 STRIDE categories on Y axis of heatmap')
  it('should apply red color class for coverage < 40%')
  it('should apply green color class for coverage >= 80%')
  it('should show loading spinner while data is being fetched')
});

// AuthGuard.spec.ts (Jest)
describe('AuthGuard', () => {
  it('should return true for /stride-heatmap when valid JWT in localStorage')
  it('should redirect to /login for /stride-heatmap when no JWT')
  it('should redirect to /login for /stride-heatmap when JWT expired')
  it('should return true for public routes without JWT')
});
```

**Backend: `StrideThreatServiceTest.java`**
- `getStrideCategories_returns6Categories_withCorrectCardCounts()`
- `getStrideHeatmapData_requiresAuthentication_returns401WhenNoToken()`
- `getStrideHeatmapData_returnsPercentageMatrix_whenAuthenticated()`

**Backend: `StrideThreatControllerIT.java`**
- `GET /api/v1/threats/stride/categories` → HTTP 200, array of 6 items
- `GET /api/v1/stride-heatmap` (no JWT) → HTTP 401
- `GET /api/v1/stride-heatmap` (with JWT) → HTTP 200, all 6 STRIDE keys present

**E2E: `us15-stride.cy.ts`**
```javascript
describe('STRIDE EoP — US-15', () => {
  it('shows 6 expansion panels in STRIDE catalogue', () => {
    cy.visit('/frameworks/stride');
    cy.get('mat-expansion-panel').should('have.length', 6);
  });
  it('shows 13 cards when Spoofing panel expanded', () => {
    cy.visit('/frameworks/stride');
    cy.get('mat-expansion-panel').first().click();
    cy.get('[data-cy=stride-card]').should('have.length', 13);
  });
  it('redirects to /login when visiting /stride-heatmap unauthenticated', () => {
    cy.visit('/stride-heatmap');
    cy.url().should('include', '/login');
  });
  it('shows ECharts heatmap after login', () => {
    cy.login('admin', 'password');
    cy.visit('/stride-heatmap');
    cy.get('div.echarts-container').should('be.visible');
  });
});
```

---

## US-16: ML Security — Elevation of MLSec Cards

**Role:** Data scientist / ML security engineer  
**Need:** Browse ML security risks (Model Risk, Input Risk, Output Risk, Dataset Risk) with MITRE ATLAS references  
**Goal:** Identify adversarial ML attacks, model theft, data poisoning, and output manipulation in ML pipelines

### MLSec Cards — Polish Translations (key cards)

| Card ID | Suit | Value | Polish Description | MITRE ATLAS | LLM 2025 |
|---|---|---|---|---|---|
| EMRX | EMR (Model Risk) | 10 | Attacker może wykraść model przez wielokrotne zapytania do API modelu, odtwarzając jego parametry (model extraction) | T0010 Model Theft | — |
| EMRK | EMR | K | Attacker może odwrócić model ML i odtworzyć prywatne dane treningowe przez ataki model inversion | T0011 Model Inversion | LLM06:2025 |
| EIRK | EIR (Input Risk) | K | Attacker może przeprowadzić atak adversarial, podając spreparowane dane wejściowe powodujące błędną klasyfikację | T0044 Craft Adversarial Data | LLM01:2025 |
| EIRQ | EIR | Q | Attacker może przeprowadzić atak prompt injection przez osadzenie złośliwych instrukcji w danych wejściowych modelu | T0051 LLM Prompt Injection | LLM01:2025 |
| EDRK | EDR (Dataset Risk) | K | Attacker może zaindukować backdoor w modelu przez zatrucie danych treningowych — aktywowany przez specjalny trigger | T0014 Data Poisoning | LLM04:2025 |
| EORK | EOR (Output Risk) | K | Attacker może uzyskać wrażliwe dane PII przez atak membership inference lub model inversion na wyjściach modelu | T0011 Model Inversion | LLM06:2025 |
| EOR4 | EOR | 4 | Attacker może manipulować wynikami klasyfikacji modelu przez evasion attacks na granicy decyzji | T0015 Evade ML Model | — |
| EIR4 | EIR | 4 | Attacker może zaindukować katastrofalne zapominanie modelu przez ciągłe ataki na dane fine-tuningu | T0020 | LLM10:2025 |

### Acceptance Criteria

- `GET /api/v1/threats?suit=EMR` (and EIR, EOR, EDR) returns corresponding cards
- `MlSecurityComponent` renders 4 `mat-tab` sections: EMR | EIR | EOR | EDR
- All MLSec cards show `ML-SPECIFIC` blue badge
- MITRE ATLAS technique references shown as `mat-chip` with technique code
- Navigation to `/matrix` shows cross-reference with LLM Top 10

### TDD Test Plan

```typescript
// MlSecurityComponent.spec.ts (Jest + ATL)
describe('MlSecurityComponent', () => {
  it('should render 4 mat-tab sections: EMR, EIR, EOR, EDR')
  it('should display ML-SPECIFIC badge on all MLSec cards')
  it('should show MITRE ATLAS technique chip (T0010) on EMRX card')
  it('should show LLM Top 10 cross-reference chip on EIRK card (LLM01:2025)')
  it('should link to /matrix when cross-reference button clicked')
  it('should display Polish descriptions when locale=pl')
});
```

**Backend: `MlSecThreatControllerIT.java`**
- `GET /api/v1/threats?suit=EMR` → HTTP 200, all cards have `edition=mlsec`
- `GET /api/v1/threats/EMRK` → `mitreRefs` contains `T0011`, `llmRefs` contains `LLM06:2025`
- `GET /api/v1/threats/mlsec/categories` → HTTP 200, array `["EMR","EIR","EOR","EDR"]`

**E2E: `us16-ml-security.cy.ts`**

---

## US-17: Mobile Security — Cornucopia Mobile App Cards

**Role:** Android/iOS developer  
**Need:** View OWASP MASVS threats via Cornucopia Mobile App cards  
**Goal:** Understand how mobile security controls differ from web and apply MASVS requirements

### Mobile App Cards — Polish Translations (key cards)

| Card ID | Suit | Value | Polish Description | MASVS | OWASP Web |
|---|---|---|---|---|---|
| NSX | NS (Network & Storage) | 10 | Attacker może przechwycić ruch TLS z powodu braku certificate pinning lub błędnej weryfikacji certyfikatu serwera | MASVS-NETWORK-2 | A02:2021 |
| NSK | NS | K | Attacker może przechwycić komunikację przez MitM w niezaufanej sieci Wi-Fi z powodu braku wymuszenia TLS 1.2+ | MASVS-NETWORK-1 | A02:2021 |
| RSX | RS (Resilience) | 10 | Attacker może ominąć zabezpieczenia aplikacji przez jailbreak/root detection bypass, jeśli brak jest obrony przed ingerencją | MASVS-RESILIENCE-4 | — |
| CRM6 | CRM (Cryptography) | 6 | Developer może przypadkowo osadzić klucze kryptograficzne w kodzie aplikacji (hardcoded keys), dostępne przez dekompilację APK | MASVS-CRYPTO-1 | A02:2021 Cryptographic Failures |
| CRM9 | CRM | 9 | Developer może użyć przestarzałych algorytmów kryptograficznych (MD5, DES, RC4) w aplikacji mobilnej | MASVS-CRYPTO-2 | A02:2021 |
| AAK | AA (Authentication & Auth) | K | Attacker może ominąć autentykację mobilną jeśli brak jest biometrycznego uwierzytelnienia lub implementacja jest błędna | MASVS-AUTH-2 | A07:2021 |
| PCK | PC (Platform Comms) | K | Attacker może przechwycić dane przez niezabezpieczone deep linki lub niezadbane intenty IPC systemu Android/iOS | MASVS-PLATFORM-2 | A01:2021 |
| CMK | CM (Code & Build) | K | Attacker może zdekompilować aplikację i wydobyć algorytmy biznesowe lub klucze API z kodu bez obfuskacji | MASVS-CODE-4 | A06:2021 |

### Acceptance Criteria

- `GET /api/v1/threats/mobile/suits` returns 6 mobile suit codes: PC, AA, NS, RS, CRM, CM
- `MobileSecurityComponent` shows 6 `mat-expansion-panel` sections
- MASVS reference shown as `mat-chip` on each card
- `GET /api/v1/matrix/mobile-vs-web` returns comparison matrix
- `MobileVsWebMatrixComponent` shows `mat-table` with MASVS control → OWASP Web Top 10 equivalence

### TDD Test Plan

```typescript
// MobileSecurityComponent.spec.ts (Jest + ATL)
describe('MobileSecurityComponent', () => {
  it('should show 6 suit sections: PC, AA, NS, RS, CRM, CM')
  it('should render MASVS reference chip on NSX card (MASVS-NETWORK-2)')
  it('should render mobile-vs-web comparison mat-table')
  it('should show OWASP Web Top 10 equivalent in comparison table')
  it('should display Polish descriptions when locale=pl')
  it('should navigate to /threats/NSX when NSX card clicked')
});
```

**Backend: `MobileSecThreatControllerIT.java`**
- `GET /api/v1/threats/mobile/suits` → HTTP 200, array `["PC","AA","NS","RS","CRM","CM"]`
- `GET /api/v1/threats?suit=NS` → HTTP 200, all `edition=mobileapp`
- `GET /api/v1/threats/NSX` → `mavsRefs` contains `MASVS-NETWORK-2`
- `GET /api/v1/matrix/mobile-vs-web` → HTTP 200, table with `masvs` and `owaspWeb` columns

**E2E: `us17-mobile-security.cy.ts`**
```javascript
describe('Mobile Security — US-17', () => {
  it('shows 6 suit expansion panels', () => {
    cy.visit('/frameworks/mobile-security');
    cy.get('mat-expansion-panel').should('have.length', 6);
  });
  it('shows MASVS-NETWORK-2 chip on NSX card', () => {
    cy.visit('/frameworks/mobile-security');
    cy.get('mat-expansion-panel').contains('Network').click();
    cy.get('[data-cy=card-NSX] mat-chip')
      .should('contain.text', 'MASVS-NETWORK-2');
  });
  it('shows MASVS vs OWASP Web comparison table at /matrix/mobile-vs-web', () => {
    cy.visit('/matrix/mobile-vs-web');
    cy.get('mat-table').should('be.visible');
    cy.get('mat-row').should('have.length.greaterThan', 5);
  });
});
```

---

## US-18: DevOps Security — DVO + BOT Cards

**Role:** DevSecOps engineer / team lead  
**Need:** Browse DevOps supply-chain risks (DVO cards) and automated threat patterns (BOT cards) with OWASP CI/CD Security Risk references and rate-limiting mitigations  
**Goal:** Protect CI/CD pipelines, validate artifact integrity, and defend against scraping and credential-stuffing bots

### DVO and BOT Cards — Polish Translations (key cards)

| Card ID | Suit | Value | Polish Description | Reference |
|---|---|---|---|---|
| DVOK | DVO | K | Attacker może wstrzyknąć złośliwy kod do procesu CI/CD przez skompromitowaną zależność pakietu (supply chain attack) | CICD-SEC-03 Dependency Chain Abuse, A06:2021 |
| DVO8 | DVO | 8 | Attacker może zmodyfikować artefakt budowania (build artifact) między etapem budowania a wdrożenia (pipeline poisoning) | CICD-SEC-09 Improper Artifact Integrity Validation, A08:2021 |
| DVOQ | DVO | Q | Attacker może uzyskać dostęp do sekretów CI/CD przez błędną konfigurację zmiennych środowiskowych lub niezaszyfrowane logi pipeline | CICD-SEC-04 Poisoned Pipeline Execution |
| DVOJ | DVO | J | Attacker może przeprowadzić atak Privilege Escalation w systemie CI/CD przez niezabezpieczone komponenty runner lub nadmiernie uprzywilejowane tokeny | CICD-SEC-06 Insufficient Credential Hygiene |
| DVO9 | DVO | 9 | Attacker może wstrzyknąć code do pipeline przez Pull Request od zewnętrznego współpracownika bez wymaganego code review | CICD-SEC-08 Ungoverned Usage of 3rd Party Services |
| BOTK | BOT | K | Attacker może skrapować całą bazę wiedzy przez zautomatyzowane zapytania (content scraping) z powodu braku rate limiting | OWASP OAT-011 Scraping |
| BOTX | BOT | 10 | Attacker może przeprowadzić atak credential stuffing — testując wykradzione pary login/hasło w dużej skali | OWASP OAT-008 Credential Cracking |
| BOTQ | BOT | Q | Attacker może przeprowadzić atak carding — automatycznie testując numery kart płatniczych przez API | OWASP OAT-001 Carding |
| BOTJ | BOT | J | Attacker może zautomatyzować tworzenie fałszywych kont przez ominięcie CAPTCHA przy rejestracji | OWASP OAT-019 Account Creation |

### Acceptance Criteria

- `GET /api/v1/threats?suit=DVO` returns 13 DVO cards with `cicdSecRefs`
- `GET /api/v1/threats?suit=BOT` returns 13 BOT cards with `oatRefs`
- `DevOpsThreatListComponent` shows DVO and BOT sections with `mat-tab-group`
- Clicking BOTK or BOTX card opens `BotWarningDialogComponent` (MatDialog)
- Dialog has "Rozumiem ryzyko" confirm and "Anuluj" cancel buttons
- Rate limit: `GET /api/v1/threats?suit=BOT` returns HTTP 429 after 60 requests/minute per IP (Bucket4j)
- `X-Frame-Options: DENY` header on `/stride-heatmap` response

### TDD Test Plan

```typescript
// DevOpsThreatListComponent.spec.ts (Jest + ATL)
describe('DevOpsThreatListComponent', () => {
  it('should show DVO tab with CI/CD cards')
  it('should show BOT tab with Automated Threat cards')
  it('should open BotWarningDialogComponent when BOTK card clicked')
  it('should open BotWarningDialogComponent when BOTX card clicked')
  it('should NOT open dialog when DVO card (non-BOT) clicked')
  it('should show CICD-SEC reference chips on DVO cards')
  it('should show OAT reference chips on BOT cards')
  it('should display Polish descriptions when locale=pl')
});
```

```typescript
// BotWarningDialogComponent.spec.ts (Jest + ATL)
describe('BotWarningDialogComponent', () => {
  let matDialogRef: MatDialogRef<BotWarningDialogComponent>;
  let router: Router;

  it('should render MatDialog with warning text about bot attack content', () => {
    const { getByText } = render(BotWarningDialogComponent, {
      imports: [MatDialogModule, MatButtonModule],
      providers: [
        { provide: MAT_DIALOG_DATA, useValue: { cardId: 'BOTK' } },
        { provide: MatDialogRef, useValue: { close: jest.fn() } }
      ]
    });
    expect(getByText('Rozumiem ryzyko')).toBeInTheDocument();
    expect(getByText('Anuluj')).toBeInTheDocument();
  });

  it('should close dialog and navigate to threat detail on "Rozumiem ryzyko" click', () => {
    const { getByText } = render(BotWarningDialogComponent, /* ... */);
    fireEvent.click(getByText('Rozumiem ryzyko'));
    expect(matDialogRef.close).toHaveBeenCalledWith(true);
  });

  it('should close dialog with false on "Anuluj" click without navigation', () => {
    const { getByText } = render(BotWarningDialogComponent, /* ... */);
    fireEvent.click(getByText('Anuluj'));
    expect(matDialogRef.close).toHaveBeenCalledWith(false);
  });
});
```

```java
// RateLimitIT.java (Testcontainers + RestAssured)
@Test
void botEndpoint_returns429_afterExceedingRateLimit() {
    // Send 60 requests — all should succeed
    for (int i = 0; i < 60; i++) {
        given().when().get("/api/v1/threats?suit=BOT")
            .then().statusCode(200);
    }
    // 61st request within same minute window should be rejected
    given().when().get("/api/v1/threats?suit=BOT")
        .then().statusCode(429)
        .header("X-RateLimit-Retry-After", notNullValue());
}

@Test
void strideHeatmap_hasXFrameOptionsDeny() {
    given().auth().oauth2(adminToken)
        .when().get("/api/v1/stride-heatmap")
        .then().statusCode(200)
        .header("X-Frame-Options", equalTo("DENY"));
}
```

**Backend: `DevOpsThreatControllerIT.java`**
- `GET /api/v1/threats?suit=DVO` → HTTP 200, 13 cards, all have `cicdSecRefs` not empty
- `GET /api/v1/threats?suit=BOT` → HTTP 200, 13 cards, all have `oatRefs` not empty
- `GET /api/v1/threats/DVOK` → `cicdSecRefs` contains `CICD-SEC-03`, `owaspRefs` contains `A06:2021`
- `GET /api/v1/threats/BOTK` → `oatRefs` contains `OAT-011`

**E2E: `us18-devops-security.cy.ts`**
```javascript
describe('DevOps Security — US-18', () => {
  it('shows DVO and BOT tabs in DevOps page', () => {
    cy.visit('/frameworks/devops-security');
    cy.get('mat-tab').should('contain.text', 'DevOps / CI-CD');
    cy.get('mat-tab').should('contain.text', 'Automated Threats');
  });

  it('opens warning dialog when BOTK card clicked', () => {
    cy.visit('/frameworks/devops-security');
    cy.get('mat-tab').contains('Automated Threats').click();
    cy.get('[data-cy=card-BOTK]').click();
    cy.get('mat-dialog-container').should('be.visible');
    cy.get('mat-dialog-container').should('contain.text', 'Rozumiem ryzyko');
  });

  it('navigates to BOTK threat detail after confirming dialog', () => {
    cy.get('[data-cy=dialog-confirm]').click();
    cy.url().should('include', '/threats/BOTK');
  });

  it('shows CICD-SEC-03 chip on DVOK card', () => {
    cy.visit('/frameworks/devops-security');
    cy.get('[data-cy=card-DVOK] mat-chip')
      .should('contain.text', 'CICD-SEC-03');
  });
});
```

---

## Test Summary

### Test Files Overview

| File | Type | Tests |
|---|---|---|
| `FrameworkServiceTest.java` | Unit | 3 |
| `FrameworkControllerIT.java` | Integration | 3 |
| `FrameworkList.spec.ts` | Component | 4 |
| `us01-framework-list.cy.ts` | E2E | 2 |
| `ThreatServiceTest.java` | Unit | 5 |
| `ThreatControllerIT.java` | Integration | 4 |
| `ThreatBrowser.spec.ts` | Component | 7 |
| `us02-threat-browser.cy.ts` | E2E | 3 |
| `ThreatDetailServiceTest.java` | Unit | 3 |
| `ThreatDetailControllerIT.java` | Integration | 3 |
| `ThreatDetail.spec.ts` | Component | 5 |
| `us03-threat-detail.cy.ts` | E2E | 3 |
| `CrossReferenceServiceTest.java` | Unit | 3 |
| `CrossReferenceControllerIT.java` | Integration | 2 |
| `MatrixTable.spec.ts` | Component | 4 |
| `us04-cross-reference.cy.ts` | E2E | 2 |
| `StrideCoverageServiceTest.java` | Unit | 2 |
| `CoverageControllerIT.java` | Integration | 2 |
| `StrideHeatmapComponent.spec.ts` | Component | 4 |
| `AuthGuard.spec.ts` | Unit | 4 |
| `us05-stride-heatmap.cy.ts` | E2E | 2 |
| `SearchServiceTest.java` | Unit | 4 |
| `SearchControllerIT.java` | Integration | 3 |
| `SearchResults.spec.ts` | Component | 4 |
| `us06-global-search.cy.ts` | E2E | 2 |
| `ExportServiceTest.java` | Unit | 3 |
| `ExportControllerIT.java` | Integration | 3 |
| `ExportButton.spec.ts` | Component | 3 |
| `us07-export.cy.ts` | E2E | 1 |
| `AtlasTimelineServiceTest.java` | Unit | 3 |
| `AtlasControllerIT.java` | Integration | 2 |
| `AtlasTimeline.spec.ts` | Component | 4 |
| `us08-atlas-timeline.cy.ts` | E2E | 2 |
| `CodeSampleServiceTest.java` (Scala) | Unit | 2 |
| `CodeSampleControllerIT.java` (Scala) | Integration | 2 |
| `CodeSamplePanel.spec.ts` (Scala tabs) | Component | 4 |
| `CodeSampleServiceTest.java` (Lua) | Unit | 2 |
| `CodeSampleControllerIT.java` (Lua) | Integration | 2 |
| `CodeSamplePanel.spec.ts` (Lua tabs) | Component | 3 |
| `LanguageToggle.spec.ts` | Component | 4 |
| `LocaleInterceptor.spec.ts` | Unit | 3 |
| `I18nParity.spec.ts` | Build-time | 3 |
| `LocalizationIT.java` | Integration | 4 |
| `us11-language-switch.cy.ts` | E2E | 4 |
| `FrontendThreatService.spec.ts` | Unit | 5 |
| `FrontendSecurityComponent.spec.ts` | Component | 8 |
| `FrontendThreatControllerIT.java` | Integration | 3 |
| `us12-frontend-security.cy.ts` | E2E | 3 |
| `LlmThreatService.spec.ts` | Unit | 6 |
| `LlmMatrixComponent.spec.ts` | Component | 5 |
| `LlmThreatControllerIT.java` | Integration | 3 |
| `us13-llm-security.cy.ts` | E2E | 2 |
| `AgenticAiComponent.spec.ts` | Component | 7 |
| `AgenticThreatControllerIT.java` | Integration | 3 |
| `us14-agentic-ai.cy.ts` | E2E | 2 |
| `StrideCatalogueComponent.spec.ts` | Component | 6 |
| `StrideHeatmapComponent.spec.ts` | Component | 5 |
| `StrideThreatServiceTest.java` | Unit | 3 |
| `StrideThreatControllerIT.java` | Integration | 3 |
| `us15-stride.cy.ts` | E2E | 4 |
| `MlSecurityComponent.spec.ts` | Component | 6 |
| `MlSecThreatControllerIT.java` | Integration | 3 |
| `us16-ml-security.cy.ts` | E2E | 2 |
| `MobileSecurityComponent.spec.ts` | Component | 6 |
| `MobileSecThreatControllerIT.java` | Integration | 4 |
| `us17-mobile-security.cy.ts` | E2E | 3 |
| `DevOpsThreatListComponent.spec.ts` | Component | 8 |
| `BotWarningDialogComponent.spec.ts` | Component | 3 |
| `RateLimitIT.java` | Integration | 2 |
| `DevOpsThreatControllerIT.java` | Integration | 4 |
| `us18-devops-security.cy.ts` | E2E | 4 |

### Totals by Category

| Category | Count |
|---|---|
| Backend unit tests (JUnit 5 + Mockito) | **77** |
| Backend integration tests (Testcontainers + RestAssured) | **42** |
| Frontend Angular component / unit tests (Jest + ATL) | **56** |
| E2E tests (Cypress 13) | **25** |
| **TOTAL** | **≥ 200** |

### Coverage Targets

| Scope | Tool | Target |
|---|---|---|
| Backend line coverage | JaCoCo | ≥ 80% |
| Frontend statement coverage | Jest `--coverage` | ≥ 75% |
| E2E golden-path scenarios | Cypress | 18/18 US (1+ per story) |
| Abuse case scenarios (AC-01–AC-13) | Testcontainers + Cypress | 100% GREEN in CI |

### CI Execution Order

```
1. mvn test                    → backend unit tests (JUnit 5 + Mockito)
2. mvn verify -P integration   → backend integration tests (Testcontainers, PostgreSQL 16)
3. ng build --configuration production
4. npx jest --coverage         → frontend component/unit tests
5. npx cypress run             → E2E tests (Cypress headless)
6. mvn jacoco:report           → generate coverage report
7. ng run coverage-check       → fail build if < 75% frontend coverage
```

### TDD Workflow per Feature

```
1. Write failing test (RED)
   ↓
2. Write minimal implementation to pass (GREEN)
   ↓
3. Refactor implementation (REFACTOR)
   ↓
4. Add more edge-case tests → repeat
   ↓
5. Integration test confirms contract with PostgreSQL
   ↓
6. E2E test confirms user-visible behavior
```
