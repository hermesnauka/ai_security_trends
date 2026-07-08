# SecureVision 2026 — User Stories & TDD Test Plan

**Version:** 1.0  
**Date:** 2026-07-06  
**Methodology:** Test-Driven Development (TDD) — Red → Green → Refactor  
**Frameworks:** JUnit 5 + Mockito + Testcontainers (backend) · Vitest + React Testing Library (frontend) · Playwright (E2E)

---

## TDD Principles Applied in This Project

```
RED   — Write a failing test that describes the desired behaviour BEFORE writing any code.
GREEN — Write the minimal production code that makes the test pass.
REFACTOR — Improve the code without breaking tests.
```

Every user story follows this structure:
1. **Acceptance Criteria** (Gherkin Given/When/Then — drives E2E and integration tests)
2. **Unit Tests** (service layer, pure logic — `@ExtendWith(MockitoExtension.class)`)
3. **Integration Tests** (full Spring context + real PostgreSQL via Testcontainers)
4. **Frontend Component Tests** (Vitest + React Testing Library)
5. **E2E Tests** (Playwright — browser-level acceptance)

Test files are written BEFORE the implementation class. The test file path is listed so it can be created immediately.

---

## Test Stack & Configuration

### Backend (`backend/src/test/java/com/securevision/`)

```java
// pom.xml test dependencies (add these before writing any test)
<dependency>
  <groupId>org.junit.jupiter</groupId>
  <artifactId>junit-jupiter</artifactId>
  <scope>test</scope>
</dependency>
<dependency>
  <groupId>org.mockito</groupId>
  <artifactId>mockito-core</artifactId>
  <scope>test</scope>
</dependency>
<dependency>
  <groupId>org.testcontainers</groupId>
  <artifactId>postgresql</artifactId>
  <scope>test</scope>
</dependency>
<dependency>
  <groupId>org.springframework.boot</groupId>
  <artifactId>spring-boot-starter-test</artifactId>
  <scope>test</scope>
</dependency>
<dependency>
  <groupId>io.rest-assured</groupId>
  <artifactId>rest-assured</artifactId>
  <scope>test</scope>
</dependency>
```

### Frontend (`frontend/src/__tests__/`)

```json
// package.json devDependencies (add before writing any test)
"vitest": "^1.x",
"@testing-library/react": "^14.x",
"@testing-library/user-event": "^14.x",
"@testing-library/jest-dom": "^6.x",
"msw": "^2.x"
```

### E2E (`e2e/`)

```json
"@playwright/test": "^1.44.x"
```

---

## Test Pyramid Overview

```
         ┌─────────────┐
         │   E2E (10)  │  Playwright — slow, high value
         │  Playwright │  One per user story
         ├─────────────┤
         │  Component  │  Vitest + RTL — medium
         │  Tests (25) │  Per React page/component
         ├─────────────┤
      Integration Tests │  Spring Boot + Testcontainers
         (20 tests)     │  Per REST endpoint group
         ├─────────────┤
         │ Unit Tests  │  JUnit 5 + Mockito — fast
         │  (50+ tests)│  Per service method
         └─────────────┘
```

---

## US-01 — Browse OWASP LLM Threats

**Story:** As a security architect, I want to browse all OWASP LLM threats so that I can quickly review what AI-related risks exist.

### Acceptance Criteria

```gherkin
Feature: OWASP LLM Threat Browsing

  Scenario: View all OWASP LLM threats on the threat list page
    Given the database contains all 10 OWASP LLM Top 10 threats
    When I navigate to /threats?framework=OWASP_LLM
    Then I see exactly 10 threat cards
    And each card shows: threat code (LLM01–LLM10), title, severity badge
    And the framework filter shows "OWASP LLM" as active

  Scenario: Navigate to a framework directly from the home page
    Given I am on the home page
    When I click the "OWASP LLM Top 10" framework tile
    Then I am redirected to /frameworks/OWASP_LLM
    And the page title reads "OWASP LLM Top 10 (2025/2026)"
    And I see the threat count = 10

  Scenario: OWASP LLM framework tile shows correct metadata
    Given I am on /frameworks
    When the page loads
    Then the OWASP LLM tile shows: name, version "2025/2026", description, and a link to the official OWASP reference URL
```

### Unit Tests

**File:** `ThreatServiceTest.java`

```java
// TDD Step 1: Write these tests FIRST — they will all fail (RED)
// TDD Step 2: Implement ThreatService to make them pass (GREEN)
// TDD Step 3: Refactor ThreatService without breaking tests

@ExtendWith(MockitoExtension.class)
class ThreatServiceTest {

    @Mock
    ThreatRepository threatRepository;

    @InjectMocks
    ThreatService threatService;

    @Test
    @DisplayName("findByFrameworkCode returns only threats for given framework")
    void findByFrameworkCode_returnsOnlyMatchingThreats() {
        // ARRANGE
        var llmThreat = ThreatFixtures.owaspLlm01();
        var webThreat = ThreatFixtures.owaspA01();
        when(threatRepository.findByFramework_Code("OWASP_LLM"))
            .thenReturn(List.of(llmThreat));

        // ACT
        var result = threatService.findByFrameworkCode("OWASP_LLM");

        // ASSERT
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getCode()).isEqualTo("LLM01");
        verify(threatRepository).findByFramework_Code("OWASP_LLM");
    }

    @Test
    @DisplayName("findByFrameworkCode with unknown code returns empty list, not exception")
    void findByFrameworkCode_unknownCode_returnsEmptyList() {
        when(threatRepository.findByFramework_Code("UNKNOWN")).thenReturn(List.of());
        assertThat(threatService.findByFrameworkCode("UNKNOWN")).isEmpty();
    }

    @Test
    @DisplayName("findByFrameworkCode result is sorted by threat code ascending")
    void findByFrameworkCode_resultIsSortedByCode() {
        var threats = List.of(
            ThreatFixtures.withCode("LLM10"),
            ThreatFixtures.withCode("LLM01"),
            ThreatFixtures.withCode("LLM05")
        );
        when(threatRepository.findByFramework_Code("OWASP_LLM")).thenReturn(threats);

        var result = threatService.findByFrameworkCode("OWASP_LLM");

        assertThat(result).extracting(ThreatDto::code)
            .containsExactly("LLM01", "LLM05", "LLM10");
    }
}
```

**File:** `FrameworkServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class FrameworkServiceTest {

    @Mock FrameworkRepository frameworkRepository;
    @InjectMocks FrameworkService frameworkService;

    @Test
    @DisplayName("findByCode returns framework with correct threat count")
    void findByCode_returnsFrameworkWithThreatCount() {
        var framework = FrameworkFixtures.owaspLlm();
        when(frameworkRepository.findByCode("OWASP_LLM"))
            .thenReturn(Optional.of(framework));

        var result = frameworkService.findByCode("OWASP_LLM");

        assertThat(result).isPresent();
        assertThat(result.get().threatCount()).isEqualTo(10);
    }

    @Test
    @DisplayName("findByCode with unknown code returns empty Optional")
    void findByCode_unknownCode_returnsEmpty() {
        when(frameworkRepository.findByCode("NOPE")).thenReturn(Optional.empty());
        assertThat(frameworkService.findByCode("NOPE")).isEmpty();
    }
}
```

### Integration Tests

**File:** `ThreatControllerIT.java`

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@Sql("/test-data/owasp_llm_threats.sql")
class ThreatControllerIT {

    @Container
    static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16-alpine");

    @LocalServerPort int port;

    @Test
    @DisplayName("GET /api/threats?framework=OWASP_LLM returns 10 threats")
    void getThreats_filterByOwaspLlm_returns10() {
        given().port(port)
            .when().get("/api/threats?framework=OWASP_LLM")
            .then().statusCode(200)
            .body("content.size()", equalTo(10))
            .body("content[0].frameworkCode", equalTo("OWASP_LLM"))
            .body("content.code", hasItems("LLM01", "LLM02", "LLM10"));
    }

    @Test
    @DisplayName("GET /api/frameworks/OWASP_LLM returns framework with threatCount=10")
    void getFramework_owaspLlm_returnsThreatCount() {
        given().port(port)
            .when().get("/api/frameworks/OWASP_LLM")
            .then().statusCode(200)
            .body("code", equalTo("OWASP_LLM"))
            .body("version", equalTo("2025/2026"))
            .body("threatCount", equalTo(10));
    }

    @Test
    @DisplayName("GET /api/threats?framework=UNKNOWN returns empty page, not 404")
    void getThreats_unknownFramework_returnsEmptyPage() {
        given().port(port)
            .when().get("/api/threats?framework=UNKNOWN")
            .then().statusCode(200)
            .body("content.size()", equalTo(0))
            .body("totalElements", equalTo(0));
    }
}
```

### Frontend Component Tests

**File:** `FrameworkTile.test.tsx`

```typescript
// TDD: write test before creating the FrameworkTile component
describe('FrameworkTile', () => {
  it('renders framework name, version and threat count', () => {
    render(<FrameworkTile framework={mockOwaspLlm} />)
    expect(screen.getByText('OWASP LLM Top 10')).toBeInTheDocument()
    expect(screen.getByText('2025/2026')).toBeInTheDocument()
    expect(screen.getByText('10 threats')).toBeInTheDocument()
  })

  it('navigates to /frameworks/OWASP_LLM on click', async () => {
    render(<MemoryRouter><FrameworkTile framework={mockOwaspLlm} /></MemoryRouter>)
    await userEvent.click(screen.getByRole('link'))
    // React Router navigate assertion via history
    expect(mockNavigate).toHaveBeenCalledWith('/frameworks/OWASP_LLM')
  })
})
```

**File:** `ThreatList.test.tsx`

```typescript
describe('ThreatList with OWASP_LLM filter', () => {
  beforeEach(() => {
    server.use(
      http.get('/api/threats', ({ request }) => {
        const url = new URL(request.url)
        if (url.searchParams.get('framework') === 'OWASP_LLM') {
          return HttpResponse.json(mockOwaspLlmPage)
        }
        return HttpResponse.json(emptyPage)
      })
    )
  })

  it('renders 10 threat cards for OWASP_LLM filter', async () => {
    render(<ThreatList />, { wrapper: RouterWrapper })
    await waitFor(() =>
      expect(screen.getAllByTestId('threat-card')).toHaveLength(10)
    )
  })

  it('each card shows threat code, title and severity badge', async () => {
    render(<ThreatList />, { wrapper: RouterWrapper })
    await screen.findByText('LLM01')
    expect(screen.getByText('Prompt Injection')).toBeInTheDocument()
    expect(screen.getByTestId('severity-badge-LLM01')).toHaveTextContent('CRITICAL')
  })
})
```

### E2E Test

**File:** `e2e/us01-browse-owasp-llm.spec.ts`

```typescript
test('US-01: security architect browses all OWASP LLM threats', async ({ page }) => {
  await page.goto('/')
  await page.click('[data-testid="framework-tile-OWASP_LLM"]')
  await expect(page).toHaveURL('/frameworks/OWASP_LLM')
  await expect(page.locator('[data-testid="threat-card"]')).toHaveCount(10)
  await expect(page.locator('text=LLM01')).toBeVisible()
  await expect(page.locator('text=LLM10')).toBeVisible()
})
```

---

## US-02 — Java Spring Boot Code Sample for SQL Injection Defense

**Story:** As a Java developer, I want to see a Java Spring Boot code example for each SQL injection defense so that I can copy-paste a secure implementation pattern.

### Acceptance Criteria

```gherkin
  Scenario: Java code sample is visible on the A03 threat detail page
    Given I navigate to the threat detail page for "A03:2021 Injection"
    When I click the "Code Samples" tab
    Then I see a tab labeled "Java"
    When I click the "Java" tab
    Then I see an "Attack Example" sub-tab and a "Defense Example" sub-tab
    And the Defense Example contains Spring Data JPA parameterized query code
    And a "Copy" button is present

  Scenario: Attack example is visually distinguished as unsafe
    Given I am viewing the Java code sample for A03 Injection
    When I view the "Attack Example" sub-tab
    Then the code block has a red border and a warning label "VULNERABLE — do not use in production"

  Scenario: Code sample shows version metadata
    Given I am viewing any Java code sample
    Then I can see "Java 21" and "Spring Boot 3.3" version labels above the code block
```

### Unit Tests

**File:** `CodeSampleServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class CodeSampleServiceTest {

    @Mock CodeSampleRepository codeSampleRepository;
    @InjectMocks CodeSampleService codeSampleService;

    @Test
    @DisplayName("findByMitigationAndLanguage returns correct sample")
    void findByMitigationAndLanguage_returnsCorrectSample() {
        var mitigationId = UUID.randomUUID();
        var sample = CodeSampleFixtures.javaInjectionDefense(mitigationId);
        when(codeSampleRepository.findByMitigation_IdAndLanguage(mitigationId, Language.JAVA))
            .thenReturn(Optional.of(sample));

        var result = codeSampleService.findByMitigationAndLanguage(mitigationId, Language.JAVA);

        assertThat(result).isPresent();
        assertThat(result.get().language()).isEqualTo(Language.JAVA);
        assertThat(result.get().frameworkHint()).contains("Spring Boot");
    }

    @Test
    @DisplayName("findAllForThreat returns samples for all 5 languages")
    void findAllForThreat_returns5Languages() {
        var threatId = UUID.randomUUID();
        when(codeSampleRepository.findByThreat_Id(threatId))
            .thenReturn(CodeSampleFixtures.allLanguagesFor(threatId));

        var result = codeSampleService.findAllForThreat(threatId);

        assertThat(result).hasSize(5);
        assertThat(result).extracting(CodeSampleDto::language)
            .containsExactlyInAnyOrder(
                Language.JAVA, Language.PYTHON, Language.GO,
                Language.SCALA, Language.LUA
            );
    }

    @Test
    @DisplayName("code sample contains both attack and defense snippets")
    void codeSample_containsBothAttackAndDefenseSnippets() {
        var threatId = UUID.randomUUID();
        var sample = codeSampleService.findByThreatAndLanguage(threatId, Language.JAVA);

        assertThat(sample.attackSnippet()).isNotBlank();
        assertThat(sample.defenseSnippet()).isNotBlank();
        assertThat(sample.attackSnippet())
            .contains("VULNERABLE"); // required warning comment
    }
}
```

### Integration Tests

**File:** `CodeSampleControllerIT.java`

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@Sql("/test-data/injection_threat_with_samples.sql")
class CodeSampleControllerIT {

    @Test
    @DisplayName("GET /api/threats/{id}/code-samples returns samples for all 5 languages")
    void getThreatCodeSamples_returns5Languages() {
        String threatId = fetchA03ThreatId();

        given().port(port)
            .when().get("/api/threats/{id}/code-samples", threatId)
            .then().statusCode(200)
            .body("size()", equalTo(5))
            .body("language", hasItems("JAVA", "PYTHON", "GO", "SCALA", "LUA"));
    }

    @Test
    @DisplayName("Java code sample contains Spring Boot version metadata")
    void getJavaCodeSample_containsVersionMetadata() {
        String threatId = fetchA03ThreatId();

        given().port(port)
            .when().get("/api/threats/{id}/code-samples", threatId)
            .then().body("find { it.language == 'JAVA' }.frameworkHint",
                containsString("Spring Boot"))
            .body("find { it.language == 'JAVA' }.version",
                containsString("21"));
    }

    @Test
    @DisplayName("Code sample attackSnippet contains VULNERABLE marker")
    void codeSample_attackSnippet_containsVulnerableMarker() {
        String threatId = fetchA03ThreatId();

        given().port(port)
            .when().get("/api/threats/{id}/code-samples", threatId)
            .then().body("find { it.language == 'JAVA' }.attackSnippet",
                containsString("VULNERABLE"));
    }
}
```

### Frontend Component Tests

**File:** `CodeSamplePanel.test.tsx`

```typescript
describe('CodeSamplePanel', () => {
  it('renders language tabs for all 5 languages', async () => {
    render(<CodeSamplePanel threatId="a03-id" />, { wrapper })
    await screen.findByRole('tab', { name: 'Java' })
    expect(screen.getByRole('tab', { name: 'Python' })).toBeInTheDocument()
    expect(screen.getByRole('tab', { name: 'Go' })).toBeInTheDocument()
    expect(screen.getByRole('tab', { name: 'Scala' })).toBeInTheDocument()
    expect(screen.getByRole('tab', { name: 'Lua' })).toBeInTheDocument()
  })

  it('shows Attack/Defense sub-tabs when a language tab is selected', async () => {
    render(<CodeSamplePanel threatId="a03-id" />, { wrapper })
    await userEvent.click(await screen.findByRole('tab', { name: 'Java' }))
    expect(screen.getByRole('tab', { name: 'Attack Example' })).toBeInTheDocument()
    expect(screen.getByRole('tab', { name: 'Defense Example' })).toBeInTheDocument()
  })

  it('attack example code block has red-border class and warning label', async () => {
    render(<CodeSamplePanel threatId="a03-id" />, { wrapper })
    await userEvent.click(await screen.findByRole('tab', { name: 'Java' }))
    await userEvent.click(screen.getByRole('tab', { name: 'Attack Example' }))
    const codeBlock = screen.getByTestId('code-block-attack')
    expect(codeBlock).toHaveClass('border-red-500')
    expect(screen.getByText(/VULNERABLE/i)).toBeInTheDocument()
  })

  it('copy button copies defense code to clipboard', async () => {
    render(<CodeSamplePanel threatId="a03-id" />, { wrapper })
    await userEvent.click(await screen.findByRole('tab', { name: 'Java' }))
    await userEvent.click(screen.getByRole('tab', { name: 'Defense Example' }))
    const copyBtn = screen.getByRole('button', { name: /copy/i })
    await userEvent.click(copyBtn)
    expect(navigator.clipboard.writeText).toHaveBeenCalledWith(
      expect.stringContaining('JpaRepository')
    )
  })
})
```

### E2E Test

**File:** `e2e/us02-java-code-sample.spec.ts`

```typescript
test('US-02: Java developer sees Spring Boot SQL injection defense', async ({ page }) => {
  await page.goto('/threats/a03-injection')
  await page.click('[role="tab"][name="Code Samples"]')
  await page.click('[role="tab"][name="Java"]')
  await page.click('[role="tab"][name="Defense Example"]')
  await expect(page.locator('[data-testid="code-block-defense"]'))
    .toContainText('JpaRepository')
  await expect(page.locator('[data-testid="version-label"]'))
    .toContainText('Spring Boot 3.3')
  await page.click('[aria-label="Copy code"]')
  // clipboard assertion via evaluate
  const clipboardText = await page.evaluate(() => navigator.clipboard.readText())
  expect(clipboardText).toContain('JpaRepository')
})
```

---

## US-03 — Filter Threats by Language (Go)

**Story:** As a Go developer, I want to filter threats by language = Go and see code samples so that I can find Go-specific security patterns immediately.

### Acceptance Criteria

```gherkin
  Scenario: Filter code samples to show only Go examples
    Given I am on the /threats page
    When I select "Go" in the language filter
    Then the threat list refreshes
    And each visible threat card shows a "Go" language badge
    And the URL updates to /threats?language=GO

  Scenario: Threat detail shows Go code sample first when Go filter is active
    Given the active language filter is "Go"
    When I open a threat detail page
    Then the "Code Samples" tab is pre-selected to the "Go" language sub-tab
```

### Unit Tests

**File:** `CodeSampleFilterServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class CodeSampleFilterServiceTest {

    @Mock CodeSampleRepository codeSampleRepository;
    @InjectMocks CodeSampleFilterService filterService;

    @Test
    @DisplayName("findThreatsWithSamplesForLanguage returns only threats that have Go samples")
    void findThreatsWithLanguage_Go_returnsOnlyThreatsWithGoSamples() {
        var goSample = CodeSampleFixtures.goSample();
        when(codeSampleRepository.findDistinctThreatsByLanguage(Language.GO))
            .thenReturn(List.of(goSample.getThreat()));

        var result = filterService.findThreatsWithSamplesForLanguage(Language.GO);

        assertThat(result).isNotEmpty();
        assertThat(result).allSatisfy(threat ->
            assertThat(threat.hasLanguage(Language.GO)).isTrue()
        );
    }

    @Test
    @DisplayName("language filter is case-insensitive: 'go' == 'GO'")
    void languageFilter_isCaseInsensitive() {
        when(codeSampleRepository.findDistinctThreatsByLanguage(Language.GO))
            .thenReturn(List.of());

        assertThatCode(() -> filterService.findThreatsWithSamplesForLanguage(Language.GO))
            .doesNotThrowAnyException();
    }
}
```

### Integration Tests

**File:** `ThreatFilterIT.java`

```java
@Test
@DisplayName("GET /api/threats?language=GO returns only threats with Go samples")
void filterByLanguageGo_returnsThreatsWithGoSamples() {
    given().port(port)
        .when().get("/api/threats?language=GO")
        .then().statusCode(200)
        .body("content.size()", greaterThan(0))
        .body("content.languages.flatten()", everyItem(hasItem("GO")));
}

@Test
@DisplayName("GET /api/code-samples?language=GO returns only Go samples")
void getCodeSamples_filterByGo_returnsOnlyGoSamples() {
    given().port(port)
        .when().get("/api/code-samples?language=GO")
        .then().statusCode(200)
        .body("language", everyItem(equalTo("GO")));
}
```

### Frontend Component Tests

**File:** `LanguageFilter.test.tsx`

```typescript
describe('LanguageFilter', () => {
  it('renders checkboxes for all 5 languages', () => {
    render(<LanguageFilter onChange={vi.fn()} />)
    ;['Python', 'Java', 'Go', 'Scala', 'Lua'].forEach(lang =>
      expect(screen.getByLabelText(lang)).toBeInTheDocument()
    )
  })

  it('calls onChange with GO when Go checkbox is checked', async () => {
    const onChange = vi.fn()
    render(<LanguageFilter onChange={onChange} />)
    await userEvent.click(screen.getByLabelText('Go'))
    expect(onChange).toHaveBeenCalledWith(expect.arrayContaining(['GO']))
  })

  it('updates URL params to ?language=GO when Go is selected', async () => {
    render(<ThreatListPage />, { wrapper: RouterWrapper })
    await userEvent.click(screen.getByLabelText('Go'))
    expect(mockLocation.search).toContain('language=GO')
  })
})
```

### E2E Test

**File:** `e2e/us03-go-language-filter.spec.ts`

```typescript
test('US-03: Go developer filters threats to see only Go code samples', async ({ page }) => {
  await page.goto('/threats')
  await page.check('[aria-label="Filter by language Go"]')
  await expect(page).toHaveURL(/language=GO/)
  const cards = page.locator('[data-testid="threat-card"]')
  await expect(cards.first()).toBeVisible()
  // each visible threat has a Go badge
  for (const card of await cards.all()) {
    await expect(card.locator('[data-testid="lang-badge-GO"]')).toBeVisible()
  }
})
```

---

## US-04 — Cross-Framework Mapping (LLM01 ↔ AML.T0051)

**Story:** As a CompTIA SecAI+ student, I want to see how LLM01 Prompt Injection maps to MITRE ATLAS AML.T0051 so that I understand the cross-framework relationship.

### Acceptance Criteria

```gherkin
  Scenario: Cross-reference between LLM01 and AML.T0051 is visible on threat detail
    Given I navigate to the LLM01 threat detail page
    When I click the "Cross-References" tab
    Then I see a row linking LLM01 to AML.T0051
    And the relationship type is "MAPS_TO"
    And the row contains a clickable link to the AML.T0051 detail page

  Scenario: Matrix page shows the LLM01-AML.T0051 mapping
    Given I am on the /matrix page
    When the table loads
    Then the cell at row LLM01 and column MITRE ATLAS shows "AML.T0051"
    And the cell is a clickable link to AML.T0051

  Scenario: Navigating from LLM01 cross-reference to AML.T0051 detail page
    Given I am on the LLM01 Cross-References tab
    When I click the AML.T0051 link
    Then I navigate to /threats/aml-t0051
    And the page title shows "Prompt Injection (AML.T0051)"
```

### Unit Tests

**File:** `CrossReferenceServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class CrossReferenceServiceTest {

    @Mock CrossReferenceRepository crossRefRepository;
    @InjectMocks CrossReferenceService crossRefService;

    @Test
    @DisplayName("findBySourceCode returns cross-references for LLM01")
    void findBySourceCode_LLM01_returnsAtlasMapping() {
        var ref = CrossRefFixtures.llm01ToAtlasT0051();
        when(crossRefRepository.findBySourceThreat_Code("LLM01"))
            .thenReturn(List.of(ref));

        var result = crossRefService.findBySourceCode("LLM01");

        assertThat(result).hasSize(1);
        assertThat(result.get(0).targetCode()).isEqualTo("AML.T0051");
        assertThat(result.get(0).relationshipType())
            .isEqualTo(RelationshipType.MAPS_TO);
    }

    @Test
    @DisplayName("buildMatrix returns non-empty matrix with LLM row")
    void buildMatrix_containsLlmRow() {
        var refs = CrossRefFixtures.allLlmToAtlasMappings();
        when(crossRefRepository.findAll()).thenReturn(refs);

        var matrix = crossRefService.buildMatrix();

        assertThat(matrix.rows()).anyMatch(row ->
            row.sourceCode().startsWith("LLM")
        );
    }
}
```

### Integration Tests

**File:** `CrossReferenceControllerIT.java`

```java
@Test
@DisplayName("GET /api/cross-references?sourceCode=LLM01 returns AML.T0051 mapping")
void getCrossReferences_LLM01_returnsAtlasMapping() {
    given().port(port)
        .when().get("/api/cross-references?sourceCode=LLM01")
        .then().statusCode(200)
        .body("targetCode", hasItem("AML.T0051"))
        .body("find { it.targetCode == 'AML.T0051' }.relationshipType",
            equalTo("MAPS_TO"));
}

@Test
@DisplayName("GET /api/matrix returns complete cross-framework table")
void getMatrix_returnsNonEmptyTable() {
    given().port(port)
        .when().get("/api/matrix")
        .then().statusCode(200)
        .body("rows.size()", greaterThanOrEqualTo(10))
        .body("rows.sourceCode.flatten()", hasItem("LLM01"));
}
```

### Frontend Component Tests

**File:** `CrossReferenceTab.test.tsx`

```typescript
describe('CrossReferenceTab', () => {
  it('renders cross-reference row for AML.T0051 on LLM01 page', async () => {
    render(<CrossReferenceTab threatCode="LLM01" />, { wrapper })
    await screen.findByText('AML.T0051')
    expect(screen.getByText('MAPS_TO')).toBeInTheDocument()
  })

  it('AML.T0051 reference is a link to the threat detail', async () => {
    render(<CrossReferenceTab threatCode="LLM01" />, { wrapper })
    const link = await screen.findByRole('link', { name: /AML\.T0051/ })
    expect(link).toHaveAttribute('href', '/threats/aml-t0051')
  })
})
```

**File:** `MatrixPage.test.tsx`

```typescript
describe('MatrixPage', () => {
  it('renders a table with LLM01 row containing AML.T0051 cell', async () => {
    render(<MatrixPage />, { wrapper })
    await screen.findByRole('row', { name: /LLM01/ })
    expect(screen.getByRole('cell', { name: /AML\.T0051/ })).toBeInTheDocument()
  })

  it('AML.T0051 matrix cell is a clickable link', async () => {
    render(<MatrixPage />, { wrapper })
    const cell = await screen.findByRole('link', { name: /AML\.T0051/ })
    expect(cell).toHaveAttribute('href', '/threats/aml-t0051')
  })
})
```

### E2E Test

**File:** `e2e/us04-cross-framework-mapping.spec.ts`

```typescript
test('US-04: student sees LLM01 mapped to AML.T0051', async ({ page }) => {
  await page.goto('/threats/llm01')
  await page.click('[role="tab"][name="Cross-References"]')
  const row = page.locator('[data-testid="cross-ref-row"]').filter({ hasText: 'AML.T0051' })
  await expect(row).toBeVisible()
  await expect(row.locator('text=MAPS_TO')).toBeVisible()
  await row.locator('a').click()
  await expect(page).toHaveURL('/threats/aml-t0051')
  await expect(page.locator('h1')).toContainText('AML.T0051')
})
```

---

## US-05 — STRIDE Coverage Heatmap

**Story:** As a security trainer, I want to display the STRIDE heatmap on a projector so that I can visually explain STRIDE coverage to a workshop audience.

### Acceptance Criteria

```gherkin
  Scenario: STRIDE heatmap renders all 6 STRIDE categories as columns
    Given I navigate to /coverage
    Then I see 6 column headers: S, T, R, I, D, E
    And each cell has a color based on the threat count (grey/yellow/orange/red)
    And each cell shows the count of threats as a number

  Scenario: Clicking a heatmap cell navigates to filtered threat list
    Given I am on the /coverage page
    When I click the cell for framework "OWASP LLM" and STRIDE "I"
    Then I am navigated to /threats?framework=OWASP_LLM&stride=I
    And the threat list shows only Information Disclosure threats for OWASP LLM

  Scenario: STRIDE minimum coverage is met
    Given the database is fully seeded
    Then the heatmap cell for STRIDE "I" has count >= 6 (per SCR-05 in requirements)
    And no STRIDE category cell for any framework shows count = 0
```

### Unit Tests

**File:** `CoverageServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class CoverageServiceTest {

    @Mock ThreatRepository threatRepository;
    @InjectMocks CoverageService coverageService;

    @Test
    @DisplayName("buildStrideMatrix returns matrix with 6 STRIDE columns per framework")
    void buildStrideMatrix_returns6StrideColumnsPerFramework() {
        when(threatRepository.countByFrameworkAndStride())
            .thenReturn(CoverageFixtures.allFrameworkStrideCounts());

        var matrix = coverageService.buildStrideMatrix();

        assertThat(matrix.frameworks()).isNotEmpty();
        matrix.frameworks().forEach(fw ->
            assertThat(fw.strideCounts()).containsKeys("S", "T", "R", "I", "D", "E")
        );
    }

    @Test
    @DisplayName("coverage cell for I category has count >= 6")
    void coverageCell_I_meetsMinimumRequirement() {
        when(threatRepository.countByFrameworkAndStride())
            .thenReturn(CoverageFixtures.allFrameworkStrideCounts());

        var matrix = coverageService.buildStrideMatrix();
        int totalI = matrix.frameworks().stream()
            .mapToInt(fw -> fw.strideCounts().getOrDefault("I", 0))
            .sum();

        assertThat(totalI).isGreaterThanOrEqualTo(6);
    }

    @Test
    @DisplayName("color tier is correct for different count values")
    void colorTier_isCorrectForCountValues() {
        assertThat(coverageService.colorTier(0)).isEqualTo("grey");
        assertThat(coverageService.colorTier(1)).isEqualTo("yellow");
        assertThat(coverageService.colorTier(4)).isEqualTo("orange");
        assertThat(coverageService.colorTier(8)).isEqualTo("red");
    }
}
```

### Integration Tests

**File:** `CoverageControllerIT.java`

```java
@Test
@DisplayName("GET /api/stats/coverage returns matrix with 6 STRIDE columns per framework")
void getCoverage_returnsStrideMatrix() {
    given().port(port)
        .when().get("/api/stats/coverage")
        .then().statusCode(200)
        .body("frameworks.size()", greaterThanOrEqualTo(3))
        .body("frameworks[0].strideCounts.keySet()",
            hasItems("S", "T", "R", "I", "D", "E"));
}
```

### Frontend Component Tests

**File:** `StrideHeatmap.test.tsx`

```typescript
describe('StrideHeatmap', () => {
  it('renders 6 STRIDE column headers', async () => {
    render(<StrideHeatmap />, { wrapper })
    await screen.findByRole('columnheader', { name: 'S' })
    ;['T', 'R', 'I', 'D', 'E'].forEach(letter =>
      expect(screen.getByRole('columnheader', { name: letter })).toBeInTheDocument()
    )
  })

  it('cell with count 0 has grey class', async () => {
    render(<StrideHeatmap />, { wrapper })
    const greyCell = await screen.findByTestId('heatmap-cell-grey')
    expect(greyCell).toHaveClass('bg-gray-200')
  })

  it('clicking a cell navigates to filtered threat list', async () => {
    render(<StrideHeatmap />, { wrapper: RouterWrapper })
    const cell = await screen.findByTestId('heatmap-cell-OWASP_LLM-I')
    await userEvent.click(cell)
    expect(mockNavigate).toHaveBeenCalledWith(
      '/threats?framework=OWASP_LLM&stride=I'
    )
  })
})
```

### E2E Test

**File:** `e2e/us05-stride-heatmap.spec.ts`

```typescript
test('US-05: trainer views STRIDE heatmap and clicks to filtered list', async ({ page }) => {
  await page.goto('/coverage')
  await expect(page.getByRole('columnheader', { name: 'I' })).toBeVisible()
  // all 6 STRIDE headers visible
  for (const letter of ['S', 'T', 'R', 'I', 'D', 'E']) {
    await expect(page.getByRole('columnheader', { name: letter })).toBeVisible()
  }
  // click a cell and verify navigation
  await page.click('[data-testid="heatmap-cell-OWASP_LLM-I"]')
  await expect(page).toHaveURL(/framework=OWASP_LLM.*stride=I|stride=I.*framework=OWASP_LLM/)
  await expect(page.locator('[data-testid="threat-card"]').first()).toBeVisible()
})
```

---

## US-06 — Global Search for "Deepfake"

**Story:** As a pentester, I want to search for "deepfake" and find all related threats with defenses so that I can quickly assemble a test checklist.

### Acceptance Criteria

```gherkin
  Scenario: Search for "deepfake" returns relevant threats
    Given the system is fully seeded
    When I type "deepfake" in the global search box and submit
    Then I am taken to /search?q=deepfake
    And the results include at least one threat from CompTIA SecAI+
    And the results include the mitigation entries related to deepfakes
    And the word "deepfake" is highlighted in each result excerpt

  Scenario: Search results are grouped by type
    Given I search for "deepfake"
    Then the results page shows three groups: "Threats", "Mitigations", "Code Samples"
    And each result shows the framework badge it belongs to

  Scenario: Empty search returns guidance, not an error
    Given I submit an empty search
    Then the page shows "Please enter a search term" and does not crash
```

### Unit Tests

**File:** `SearchServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class SearchServiceTest {

    @Mock SearchRepository searchRepository;
    @InjectMocks SearchService searchService;

    @Test
    @DisplayName("search('deepfake') returns results from multiple entity types")
    void search_deepfake_returnsMultipleEntityTypes() {
        when(searchRepository.fullTextSearch("deepfake"))
            .thenReturn(SearchResultFixtures.deepfakeResults());

        var results = searchService.search("deepfake");

        assertThat(results.threats()).isNotEmpty();
        assertThat(results.mitigations()).isNotEmpty();
    }

    @Test
    @DisplayName("search result excerpts contain highlighted terms")
    void search_results_containHighlightedTerms() {
        when(searchRepository.fullTextSearch("deepfake"))
            .thenReturn(SearchResultFixtures.deepfakeResults());

        var results = searchService.search("deepfake");

        results.threats().forEach(threat ->
            assertThat(threat.excerpt()).contains("<mark>deepfake</mark>")
        );
    }

    @Test
    @DisplayName("search with blank query throws IllegalArgumentException")
    void search_blankQuery_throwsIllegalArgument() {
        assertThatThrownBy(() -> searchService.search("  "))
            .isInstanceOf(IllegalArgumentException.class)
            .hasMessageContaining("query must not be blank");
    }

    @Test
    @DisplayName("search is case-insensitive: 'Deepfake' == 'deepfake'")
    void search_isCaseInsensitive() {
        when(searchRepository.fullTextSearch(anyString()))
            .thenReturn(SearchResultFixtures.deepfakeResults());

        var lower = searchService.search("deepfake");
        var upper = searchService.search("DEEPFAKE");

        assertThat(lower.threats().size()).isEqualTo(upper.threats().size());
    }
}
```

### Integration Tests

**File:** `SearchControllerIT.java`

```java
@Test
@DisplayName("GET /api/search?q=deepfake returns grouped results with highlights")
void search_deepfake_returnsGroupedResults() {
    given().port(port)
        .queryParam("q", "deepfake")
        .when().get("/api/search")
        .then().statusCode(200)
        .body("threats.size()", greaterThan(0))
        .body("threats[0].excerpt", containsString("<mark>"))
        .body("threats[0].frameworkCode", notNullValue());
}

@Test
@DisplayName("GET /api/search without q param returns 400")
void search_missingQuery_returns400() {
    given().port(port)
        .when().get("/api/search")
        .then().statusCode(400);
}
```

### Frontend Component Tests

**File:** `SearchResultsPage.test.tsx`

```typescript
describe('SearchResultsPage', () => {
  it('renders three result groups: Threats, Mitigations, Code Samples', async () => {
    render(<SearchResultsPage />, { wrapper: routerWithQuery('deepfake') })
    await screen.findByRole('heading', { name: 'Threats' })
    expect(screen.getByRole('heading', { name: 'Mitigations' })).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Code Samples' })).toBeInTheDocument()
  })

  it('result excerpts show <mark> highlighted terms', async () => {
    render(<SearchResultsPage />, { wrapper: routerWithQuery('deepfake') })
    const marks = await screen.findAllByRole('mark')
    expect(marks.length).toBeGreaterThan(0)
    marks.forEach(m => expect(m.textContent?.toLowerCase()).toContain('deepfake'))
  })

  it('shows guidance message when query is empty', () => {
    render(<SearchResultsPage />, { wrapper: routerWithQuery('') })
    expect(screen.getByText(/please enter a search term/i)).toBeInTheDocument()
  })
})
```

### E2E Test

**File:** `e2e/us06-search-deepfake.spec.ts`

```typescript
test('US-06: pentester searches for deepfake and finds threats', async ({ page }) => {
  await page.goto('/')
  await page.fill('[data-testid="global-search-input"]', 'deepfake')
  await page.press('[data-testid="global-search-input"]', 'Enter')
  await expect(page).toHaveURL('/search?q=deepfake')
  await expect(page.locator('text=Threats')).toBeVisible()
  await expect(page.locator('mark').first()).toContainText('deepfake')
  // at least one result
  await expect(page.locator('[data-testid="search-result-item"]').first()).toBeVisible()
})
```

---

## US-07 — Export Filtered Threat List to CSV

**Story:** As a team lead, I want to export the currently filtered threat list as CSV so that I can include it in a risk register document.

### Acceptance Criteria

```gherkin
  Scenario: Export button is present on the threat list page
    Given I am on /threats with any filter applied
    Then I see an "Export CSV" button in the toolbar

  Scenario: Exported CSV contains all currently visible threats
    Given I have filtered threats to framework=OWASP_LLM (10 threats)
    When I click "Export CSV"
    Then a file "threats-OWASP_LLM-2026-07-06.csv" is downloaded
    And the CSV contains a header row: code,title,severity,framework,category,tags
    And the CSV contains exactly 10 data rows

  Scenario: CSV special characters are properly escaped
    Given a threat title contains a comma
    When exported to CSV
    Then the value is quoted in the CSV file
```

### Unit Tests

**File:** `CsvExportServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class CsvExportServiceTest {

    @InjectMocks CsvExportService csvExportService;

    @Test
    @DisplayName("export generates CSV with correct header")
    void export_generatesCsvWithCorrectHeader() throws IOException {
        var threats = ThreatFixtures.owaspLlmAll();
        var csv = csvExportService.exportThreatsToCsv(threats);

        var reader = new BufferedReader(new StringReader(csv));
        assertThat(reader.readLine())
            .isEqualTo("code,title,severity,framework,category,tags");
    }

    @Test
    @DisplayName("export generates one row per threat")
    void export_generatesOneRowPerThreat() throws IOException {
        var threats = ThreatFixtures.owaspLlmAll(); // 10 items
        var csv = csvExportService.exportThreatsToCsv(threats);

        long dataRows = csv.lines().count() - 1; // subtract header
        assertThat(dataRows).isEqualTo(10);
    }

    @Test
    @DisplayName("title with comma is quoted in CSV")
    void export_commaInTitle_isQuoted() throws IOException {
        var threat = ThreatFixtures.withTitle("Injection, SQL and NoSQL");
        var csv = csvExportService.exportThreatsToCsv(List.of(threat));

        assertThat(csv).contains("\"Injection, SQL and NoSQL\"");
    }

    @Test
    @DisplayName("export with empty list returns only header row")
    void export_emptyList_returnsOnlyHeader() throws IOException {
        var csv = csvExportService.exportThreatsToCsv(List.of());
        assertThat(csv.lines().count()).isEqualTo(1);
    }
}
```

### Integration Tests

**File:** `ExportControllerIT.java`

```java
@Test
@DisplayName("GET /api/threats/export?framework=OWASP_LLM returns CSV with 10 rows")
void exportCsv_owaspLlm_returns10DataRows() {
    var csvBody = given().port(port)
        .when().get("/api/threats/export?framework=OWASP_LLM&format=csv")
        .then().statusCode(200)
        .contentType("text/csv")
        .header("Content-Disposition",
            containsString("filename=\"threats-OWASP_LLM-"))
        .extract().body().asString();

    long rows = csvBody.lines().count();
    assertThat(rows).isEqualTo(11); // 1 header + 10 data
}
```

### Frontend Component Tests

**File:** `ExportButton.test.tsx`

```typescript
describe('ExportButton', () => {
  it('renders Export CSV button in threat list toolbar', () => {
    render(<ThreatListToolbar currentFilter={{ framework: 'OWASP_LLM' }} />, { wrapper })
    expect(screen.getByRole('button', { name: /export csv/i })).toBeInTheDocument()
  })

  it('triggers download with correct filename when clicked', async () => {
    const downloadSpy = vi.spyOn(exportService, 'downloadCsv')
    render(<ThreatListToolbar currentFilter={{ framework: 'OWASP_LLM' }} />, { wrapper })
    await userEvent.click(screen.getByRole('button', { name: /export csv/i }))
    expect(downloadSpy).toHaveBeenCalledWith(
      expect.objectContaining({ framework: 'OWASP_LLM' })
    )
  })
})
```

### E2E Test

**File:** `e2e/us07-export-csv.spec.ts`

```typescript
test('US-07: team lead exports filtered threat list to CSV', async ({ page }) => {
  await page.goto('/threats?framework=OWASP_LLM')
  const [download] = await Promise.all([
    page.waitForEvent('download'),
    page.click('[data-testid="export-csv-button"]')
  ])
  expect(download.suggestedFilename()).toMatch(/^threats-OWASP_LLM-.+\.csv$/)
  const path = await download.path()
  const content = await fs.readFile(path!, 'utf-8')
  const lines = content.trim().split('\n')
  expect(lines[0]).toBe('code,title,severity,framework,category,tags')
  expect(lines.length).toBe(11) // header + 10 LLM threats
})
```

---

## US-08 — MITRE Kill-Chain Timeline

**Story:** As a developer, I want to see the MITRE Kill Chain timeline so that I understand at which attack phase each ATLAS technique is used.

### Acceptance Criteria

```gherkin
  Scenario: Kill-Chain timeline shows 7 phases
    Given I navigate to /frameworks/MITRE_ATLAS
    Then I see a horizontal timeline with 7 labelled phases:
      Reconnaissance, Weaponization, Delivery, Exploitation,
      Installation, Command & Control, Actions on Objectives

  Scenario: MITRE techniques appear on the correct timeline phase
    Given the timeline is rendered
    Then AML.T0051 (Prompt Injection) appears in the "Initial Access" phase area
    And AML.T0020 (Poison Training Data) appears in the "ML Attack Staging" phase area

  Scenario: Hovering over a technique shows a tooltip with details
    Given the timeline is rendered
    When I hover over the AML.T0051 node
    Then a tooltip shows: ID "AML.T0051", name "LLM Prompt Injection", short description
```

### Unit Tests

**File:** `KillChainMapperTest.java`

```java
@ExtendWith(MockitoExtension.class)
class KillChainMapperTest {

    @InjectMocks KillChainMapper mapper;

    @Test
    @DisplayName("mapToKillChainPhase maps AML.T0051 to INITIAL_ACCESS phase")
    void map_AML_T0051_toInitialAccessPhase() {
        var technique = ThreatFixtures.atlasT0051();
        assertThat(mapper.mapToPhase(technique))
            .isEqualTo(KillChainPhase.INITIAL_ACCESS);
    }

    @Test
    @DisplayName("mapToKillChainPhase maps AML.T0020 to ML_ATTACK_STAGING phase")
    void map_AML_T0020_toMlAttackStagingPhase() {
        var technique = ThreatFixtures.atlasT0020();
        assertThat(mapper.mapToPhase(technique))
            .isEqualTo(KillChainPhase.ML_ATTACK_STAGING);
    }

    @Test
    @DisplayName("buildTimeline returns all 7 phases (including empty ones)")
    void buildTimeline_returnsAll7Phases() {
        var techniques = ThreatFixtures.allAtlasTechniques();
        var timeline = mapper.buildTimeline(techniques);

        assertThat(timeline.phases()).hasSize(7);
        assertThat(timeline.phases())
            .extracting(TimelinePhase::name)
            .containsExactly(
                "Reconnaissance", "Weaponization", "Delivery",
                "Exploitation", "Installation",
                "Command & Control", "Actions on Objectives"
            );
    }
}
```

### Integration Tests

**File:** `TimelineControllerIT.java`

```java
@Test
@DisplayName("GET /api/frameworks/MITRE_ATLAS/timeline returns 7-phase timeline")
void getTimeline_mitre_returns7Phases() {
    given().port(port)
        .when().get("/api/frameworks/MITRE_ATLAS/timeline")
        .then().statusCode(200)
        .body("phases.size()", equalTo(7))
        .body("phases.name", hasItem("Reconnaissance"))
        .body("phases.name", hasItem("Actions on Objectives"))
        .body("phases.find { it.name == 'Initial Access' }.techniques.id",
            hasItem("AML.T0051"));
}
```

### Frontend Component Tests

**File:** `KillChainTimeline.test.tsx`

```typescript
describe('KillChainTimeline', () => {
  it('renders 7 phase labels on the timeline', async () => {
    render(<KillChainTimeline frameworkCode="MITRE_ATLAS" />, { wrapper })
    await screen.findByText('Reconnaissance')
    ;['Weaponization', 'Delivery', 'Exploitation', 'Installation',
      'Command & Control', 'Actions on Objectives']
      .forEach(phase => expect(screen.getByText(phase)).toBeInTheDocument())
  })

  it('AML.T0051 node appears in the correct phase', async () => {
    render(<KillChainTimeline frameworkCode="MITRE_ATLAS" />, { wrapper })
    const node = await screen.findByTestId('timeline-node-AML.T0051')
    const phase = node.closest('[data-phase]')
    expect(phase).toHaveAttribute('data-phase', 'Initial Access')
  })

  it('hovering over a node shows tooltip with technique details', async () => {
    render(<KillChainTimeline frameworkCode="MITRE_ATLAS" />, { wrapper })
    const node = await screen.findByTestId('timeline-node-AML.T0051')
    await userEvent.hover(node)
    await screen.findByRole('tooltip')
    expect(screen.getByRole('tooltip')).toHaveTextContent('AML.T0051')
    expect(screen.getByRole('tooltip')).toHaveTextContent('LLM Prompt Injection')
  })
})
```

### E2E Test

**File:** `e2e/us08-kill-chain-timeline.spec.ts`

```typescript
test('US-08: developer views MITRE Kill Chain timeline', async ({ page }) => {
  await page.goto('/frameworks/MITRE_ATLAS')
  const timeline = page.locator('[data-testid="kill-chain-timeline"]')
  await expect(timeline).toBeVisible()
  await expect(timeline.locator('text=Reconnaissance')).toBeVisible()
  await expect(timeline.locator('text=Actions on Objectives')).toBeVisible()
  // hover tooltip
  const node = timeline.locator('[data-testid="timeline-node-AML\\.T0051"]')
  await node.hover()
  await expect(page.locator('[role="tooltip"]')).toContainText('AML.T0051')
})
```

---

## US-09 — Scala Code Samples for Supply Chain Attacks

**Story:** As a Scala developer, I want to find code samples for supply chain attacks written in Scala so that I can implement SCA checks in our Scala build pipeline.

### Acceptance Criteria

```gherkin
  Scenario: Scala code sample exists for LLM03 Supply Chain Vulnerabilities
    Given I navigate to the LLM03 threat detail page
    When I click "Code Samples" tab and select "Scala"
    Then I see a Scala code sample with both Attack and Defense sub-tabs
    And the sample references Scala build tool (sbt or Mill) or a Scala library
    And the framework hint shows "Scala 3.x" or "Akka HTTP" or "Slick"

  Scenario: Scala code sample also exists for A06 Vulnerable Components
    Given I search for framework = OWASP_WEB, code = A06
    When I open the Code Samples tab and select Scala
    Then I see a Scala defense example showing how to check for vulnerable dependencies
```

### Unit Tests

**File:** `CodeSampleValidatorTest.java`

```java
@ExtendWith(MockitoExtension.class)
class CodeSampleValidatorTest {

    @InjectMocks CodeSampleValidator validator;

    @Test
    @DisplayName("Scala sample must reference Scala 3.x in version field")
    void scalaCodeSample_versionMentionsScala3() {
        var sample = CodeSampleFixtures.scalaSupplyChain();
        var violations = validator.validate(sample);
        assertThat(violations).isEmpty();
        assertThat(sample.version()).containsIgnoringCase("Scala 3");
    }

    @Test
    @DisplayName("code sample without defenseSnippet fails validation")
    void codeSample_missingDefenseSnippet_failsValidation() {
        var sample = CodeSampleFixtures.scalaWithoutDefense();
        var violations = validator.validate(sample);
        assertThat(violations).anyMatch(v ->
            v.field().equals("defenseSnippet")
        );
    }

    @Test
    @DisplayName("every threat has a Scala code sample (coverage check)")
    void allThreats_haveScalaSample() {
        var threatIds = threatRepository.findAllIds();
        threatIds.forEach(id ->
            assertThat(codeSampleRepository
                .findByThreat_IdAndLanguage(id, Language.SCALA))
                .isPresent()
        );
    }
}
```

### Integration Tests

**File:** `ScalaSampleIT.java`

```java
@Test
@DisplayName("LLM03 threat has Scala code sample")
void llm03_hasScalaCodeSample() {
    given().port(port)
        .when().get("/api/threats/llm03/code-samples")
        .then().statusCode(200)
        .body("find { it.language == 'SCALA' }", notNullValue())
        .body("find { it.language == 'SCALA' }.version",
            containsStringIgnoringCase("scala"))
        .body("find { it.language == 'SCALA' }.defenseSnippet",
            not(emptyString()));
}

@Test
@DisplayName("GET /api/code-samples?language=SCALA returns at least 10 samples")
void getCodeSamples_scala_returnsAtLeast10() {
    given().port(port)
        .when().get("/api/code-samples?language=SCALA")
        .then().statusCode(200)
        .body("size()", greaterThanOrEqualTo(10));
}
```

### Frontend Component Tests

**File:** `CodeTab.test.tsx`

```typescript
describe('CodeTab — Scala', () => {
  it('renders Scala tab with version label "Scala 3.x"', async () => {
    render(<CodeSamplePanel threatId="llm03-id" />, { wrapper })
    await userEvent.click(await screen.findByRole('tab', { name: 'Scala' }))
    expect(screen.getByTestId('version-label')).toHaveTextContent('Scala 3')
  })

  it('Scala defense code block is not empty', async () => {
    render(<CodeSamplePanel threatId="llm03-id" />, { wrapper })
    await userEvent.click(await screen.findByRole('tab', { name: 'Scala' }))
    await userEvent.click(screen.getByRole('tab', { name: 'Defense Example' }))
    const codeBlock = screen.getByTestId('code-block-defense')
    expect(codeBlock.textContent?.trim().length).toBeGreaterThan(0)
  })
})
```

### E2E Test

**File:** `e2e/us09-scala-supply-chain.spec.ts`

```typescript
test('US-09: Scala developer finds supply chain attack code sample', async ({ page }) => {
  await page.goto('/threats/llm03')
  await page.click('[role="tab"][name="Code Samples"]')
  await page.click('[role="tab"][name="Scala"]')
  await expect(page.locator('[data-testid="version-label"]')).toContainText('Scala 3')
  await page.click('[role="tab"][name="Defense Example"]')
  const code = page.locator('[data-testid="code-block-defense"]')
  await expect(code).not.toBeEmpty()
})
```

---

## US-10 — Lua/OpenResty Rate Limiting for LLM DoS

**Story:** As a Lua/OpenResty developer, I want to see Lua examples for rate limiting to prevent LLM DoS so that I can configure NGINX guardrails for my LLM API proxy.

### Acceptance Criteria

```gherkin
  Scenario: Lua code sample exists for LLM10 Unbounded Consumption
    Given I navigate to the LLM10 threat detail page
    When I open the "Code Samples" tab and select "Lua"
    Then I see a Lua defense example implementing rate limiting
    And the sample includes a comment: "-- Requires: OpenResty >= 1.21 / Lua 5.4"
    And the code uses the "lua-resty-limit-traffic" or equivalent library

  Scenario: Lua defense example is correct and complete
    Given I am viewing the Lua defense example for LLM10
    Then the code block is not empty
    And the version label shows "Lua 5.4 / OpenResty"
    And a Copy button is present
```

### Unit Tests

**File:** `LuaSampleValidatorTest.java`

```java
@ExtendWith(MockitoExtension.class)
class LuaSampleValidatorTest {

    @InjectMocks CodeSampleValidator validator;

    @Test
    @DisplayName("Lua sample must contain OpenResty version comment")
    void luaSample_mustContainOpenRestyComment() {
        var sample = CodeSampleFixtures.luaRateLimiting();
        assertThat(sample.defenseSnippet())
            .contains("-- Requires: OpenResty");
    }

    @Test
    @DisplayName("LLM10 has a Lua code sample")
    void llm10_hasLuaCodeSample() {
        when(codeSampleRepository
            .findByThreat_CodeAndLanguage("LLM10", Language.LUA))
            .thenReturn(Optional.of(CodeSampleFixtures.luaRateLimiting()));

        var result = codeSampleService
            .findByThreatCodeAndLanguage("LLM10", Language.LUA);

        assertThat(result).isPresent();
        assertThat(result.get().defenseSnippet()).isNotBlank();
    }

    @Test
    @DisplayName("Lua sample version field mentions Lua 5.4 or LuaJIT")
    void luaSample_versionMentionsLua54OrLuaJit() {
        var sample = CodeSampleFixtures.luaRateLimiting();
        assertThat(sample.version())
            .matches("(?i).*(lua 5\\.4|luajit|openresty).*");
    }
}
```

### Integration Tests

**File:** `LuaSampleIT.java`

```java
@Test
@DisplayName("LLM10 has Lua code sample with OpenResty rate-limiting")
void llm10_hasLuaCodeSampleWithRateLimiting() {
    given().port(port)
        .when().get("/api/threats/llm10/code-samples")
        .then().statusCode(200)
        .body("find { it.language == 'LUA' }", notNullValue())
        .body("find { it.language == 'LUA' }.defenseSnippet",
            containsString("OpenResty"))
        .body("find { it.language == 'LUA' }.version",
            containsStringIgnoringCase("lua"));
}

@Test
@DisplayName("GET /api/code-samples?language=LUA&threat=LLM10 returns exactly 1 sample")
void getLuaSamples_llm10_returns1() {
    given().port(port)
        .when().get("/api/code-samples?language=LUA&threatCode=LLM10")
        .then().statusCode(200)
        .body("size()", equalTo(1))
        .body("[0].language", equalTo("LUA"));
}
```

### Frontend Component Tests

**File:** `LuaCodeBlock.test.tsx`

```typescript
describe('Lua code sample for LLM10', () => {
  it('shows OpenResty version label', async () => {
    render(<CodeSamplePanel threatId="llm10-id" />, { wrapper })
    await userEvent.click(await screen.findByRole('tab', { name: 'Lua' }))
    expect(screen.getByTestId('version-label'))
      .toHaveTextContent(/Lua 5\.4|OpenResty/i)
  })

  it('defense code block contains rate limiting code', async () => {
    render(<CodeSamplePanel threatId="llm10-id" />, { wrapper })
    await userEvent.click(await screen.findByRole('tab', { name: 'Lua' }))
    await userEvent.click(screen.getByRole('tab', { name: 'Defense Example' }))
    expect(screen.getByTestId('code-block-defense').textContent)
      .toMatch(/resty\.limit|rate.limit/i)
  })
})
```

### E2E Test

**File:** `e2e/us10-lua-rate-limiting.spec.ts`

```typescript
test('US-10: Lua developer sees OpenResty rate limiting example for LLM DoS', async ({ page }) => {
  await page.goto('/threats/llm10')
  await page.click('[role="tab"][name="Code Samples"]')
  await page.click('[role="tab"][name="Lua"]')
  await expect(page.locator('[data-testid="version-label"]'))
    .toContainText(/Lua 5\.4|OpenResty/)
  await page.click('[role="tab"][name="Defense Example"]')
  const code = page.locator('[data-testid="code-block-defense"]')
  await expect(code).toContainText('OpenResty')
  // copy button works
  await page.click('[aria-label="Copy code"]')
  const clipboardText = await page.evaluate(() => navigator.clipboard.readText())
  expect(clipboardText).toMatch(/resty\.limit|rate.limit/i)
})
```

---

## US-11 — Polish / English Language Switch

**Story:** As a Polish-speaking security student, I want to switch the entire application from English to Polish with one click so that I can study all threat descriptions, mitigations, and UI labels in my native language.

**Tech stack for i18n:**
- Frontend: `react-i18next` + `i18next` (lazy-loads `pl.json` / `en.json` per locale)
- Backend: `Accept-Language` header parsed in a `LocaleResolver` bean; bilingual fields stored as `title_pl` / `title_en` (or a separate `ThreatTranslation` join table)
- Persistence of choice: `localStorage` key `sv_locale`

### Acceptance Criteria

```gherkin
Feature: Polish / English language switching

  Scenario: Default language on first visit is Polish
    Given a user opens the application for the first time
    And their browser Accept-Language header is "pl-PL"
    Then all navigation labels, headings, and button labels are displayed in Polish
    And the language toggle shows "PL" as the active selection

  Scenario: User switches to English
    Given the current language is Polish
    When the user clicks the "EN" toggle in the navigation bar
    Then all UI strings immediately switch to English without a page reload
    And the toggle shows "EN" as active
    And the selection is saved to localStorage key "sv_locale"

  Scenario: Language preference persists across page reload
    Given the user previously selected English
    When the user reloads the page
    Then the UI is displayed in English, not Polish

  Scenario: Threat descriptions are returned in the active language
    Given the current language is Polish
    When the user opens the LLM01 threat detail page
    Then the threat title is in Polish (e.g., "Wstrzykiwanie promptów")
    And the description is in Polish
    And the attack vector text is in Polish

  Scenario: Switching language on a threat detail page re-fetches content in new language
    Given the user is on the LLM01 detail page showing Polish content
    When the user switches to English
    Then the threat title changes to "Prompt Injection"
    And the description changes to the English version
    And the URL does not change

  Scenario: Code blocks are never translated
    Given the language is set to Polish
    When the user views the Java defense code sample for LLM01
    Then the code block contains the same English code and comments as in English mode

  Scenario: API returns Polish content when Accept-Language is pl
    Given a client sends GET /api/threats/llm01 with header Accept-Language: pl
    Then the response body contains "title": "Wstrzykiwanie promptów"
    And the response header Content-Language is "pl"

  Scenario: API falls back to English for unsupported locale
    Given a client sends GET /api/threats/llm01 with header Accept-Language: de
    Then the response contains the English title
    And the response header Content-Language is "en"

  Scenario: Search returns results in the active language
    Given the current language is Polish
    When the user searches for "wstrzykiwanie"
    Then the results contain the Polish versions of matching threat titles
    When the user switches to English and searches for "injection"
    Then the results contain the English versions of the same threats
```

### Unit Tests

**File:** `LocalizationServiceTest.java`

```java
// TDD: write ALL these tests before creating LocalizationService
@ExtendWith(MockitoExtension.class)
class LocalizationServiceTest {

    @Mock ThreatTranslationRepository translationRepository;
    @InjectMocks LocalizationService localizationService;

    @Test
    @DisplayName("resolveLocale returns PL for Accept-Language: pl-PL")
    void resolveLocale_plPL_returnsPolish() {
        assertThat(localizationService.resolveLocale("pl-PL"))
            .isEqualTo(Locale.forLanguageTag("pl"));
    }

    @Test
    @DisplayName("resolveLocale returns EN for Accept-Language: de (unsupported)")
    void resolveLocale_unsupportedLocale_fallsBackToEnglish() {
        assertThat(localizationService.resolveLocale("de"))
            .isEqualTo(Locale.ENGLISH);
    }

    @Test
    @DisplayName("resolveLocale returns EN when header is absent (null)")
    void resolveLocale_nullHeader_returnsEnglish() {
        assertThat(localizationService.resolveLocale(null))
            .isEqualTo(Locale.ENGLISH);
    }

    @Test
    @DisplayName("resolveLocale returns EN for Accept-Language: en-US")
    void resolveLocale_enUS_returnsEnglish() {
        assertThat(localizationService.resolveLocale("en-US"))
            .isEqualTo(Locale.ENGLISH);
    }
}
```

**File:** `ThreatLocalizationServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class ThreatLocalizationServiceTest {

    @Mock ThreatRepository threatRepository;
    @Mock ThreatTranslationRepository translationRepository;
    @InjectMocks ThreatService threatService;

    @Test
    @DisplayName("findById in Polish returns Polish title and description")
    void findById_polish_returnsPolishContent() {
        var threat = ThreatFixtures.llm01WithTranslations();
        when(threatRepository.findById(threat.getId()))
            .thenReturn(Optional.of(threat));

        var result = threatService.findById(threat.getId(), Locale.forLanguageTag("pl"));

        assertThat(result.title()).isEqualTo("Wstrzykiwanie promptów");
        assertThat(result.description()).startsWith("Najpopularniejsza");
    }

    @Test
    @DisplayName("findById in English returns English title and description")
    void findById_english_returnsEnglishContent() {
        var threat = ThreatFixtures.llm01WithTranslations();
        when(threatRepository.findById(threat.getId()))
            .thenReturn(Optional.of(threat));

        var result = threatService.findById(threat.getId(), Locale.ENGLISH);

        assertThat(result.title()).isEqualTo("Prompt Injection");
    }

    @Test
    @DisplayName("findById with missing Polish translation falls back to English")
    void findById_missingPolishTranslation_fallsBackToEnglish() {
        var threat = ThreatFixtures.llm01EnglishOnly();
        when(threatRepository.findById(threat.getId()))
            .thenReturn(Optional.of(threat));

        var result = threatService.findById(threat.getId(), Locale.forLanguageTag("pl"));

        // Falls back to English — no exception, no null
        assertThat(result.title()).isEqualTo("Prompt Injection");
        assertThat(result.title()).isNotNull();
    }

    @Test
    @DisplayName("search in Polish searches both pl and en fields, returns pl content")
    void search_polish_returnsPolishResults() {
        when(translationRepository.fullTextSearchLocalized("wstrzykiwanie", "pl"))
            .thenReturn(SearchResultFixtures.polishInjectionResults());

        var results = threatService.search("wstrzykiwanie", Locale.forLanguageTag("pl"));

        assertThat(results.threats()).isNotEmpty();
        assertThat(results.threats().get(0).title())
            .isEqualTo("Wstrzykiwanie promptów");
    }
}
```

**File:** `I18nKeysValidatorTest.java`

```java
// Compile-time safety check: every key in en.json must exist in pl.json
class I18nKeysValidatorTest {

    private static final ObjectMapper mapper = new ObjectMapper();

    @Test
    @DisplayName("pl.json contains all keys that exist in en.json")
    void polishTranslations_containAllEnglishKeys() throws Exception {
        var enKeys = flatKeys(loadJson("frontend/src/i18n/en.json"));
        var plKeys = flatKeys(loadJson("frontend/src/i18n/pl.json"));

        var missingInPl = enKeys.stream()
            .filter(k -> !plKeys.contains(k))
            .toList();

        assertThat(missingInPl)
            .as("These keys exist in en.json but are missing in pl.json")
            .isEmpty();
    }

    @Test
    @DisplayName("en.json contains all keys that exist in pl.json")
    void englishTranslations_containAllPolishKeys() throws Exception {
        var enKeys = flatKeys(loadJson("frontend/src/i18n/en.json"));
        var plKeys = flatKeys(loadJson("frontend/src/i18n/pl.json"));

        var missingInEn = plKeys.stream()
            .filter(k -> !enKeys.contains(k))
            .toList();

        assertThat(missingInEn)
            .as("These keys exist in pl.json but are missing in en.json")
            .isEmpty();
    }

    @Test
    @DisplayName("no translation value is blank in either locale")
    void noTranslationValue_isBlank() throws Exception {
        var enValues = flatValues(loadJson("frontend/src/i18n/en.json"));
        var plValues = flatValues(loadJson("frontend/src/i18n/pl.json"));

        assertThat(enValues).noneMatch(String::isBlank);
        assertThat(plValues).noneMatch(String::isBlank);
    }

    // helpers: flatKeys(), flatValues(), loadJson() — recursive JSON traversal
}
```

### Integration Tests

**File:** `LocalizationControllerIT.java`

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@Sql("/test-data/llm01_with_translations.sql")
class LocalizationControllerIT {

    @Test
    @DisplayName("GET /api/threats/llm01 with Accept-Language: pl returns Polish title")
    void getThreat_acceptLanguagePl_returnsPolishTitle() {
        given().port(port)
            .header("Accept-Language", "pl")
            .when().get("/api/threats/llm01")
            .then().statusCode(200)
            .header("Content-Language", equalTo("pl"))
            .body("title", equalTo("Wstrzykiwanie promptów"));
    }

    @Test
    @DisplayName("GET /api/threats/llm01 with Accept-Language: en returns English title")
    void getThreat_acceptLanguageEn_returnsEnglishTitle() {
        given().port(port)
            .header("Accept-Language", "en")
            .when().get("/api/threats/llm01")
            .then().statusCode(200)
            .header("Content-Language", equalTo("en"))
            .body("title", equalTo("Prompt Injection"));
    }

    @Test
    @DisplayName("GET /api/threats/llm01 without Accept-Language defaults to English")
    void getThreat_noAcceptLanguage_defaultsToEnglish() {
        given().port(port)
            .when().get("/api/threats/llm01")
            .then().statusCode(200)
            .header("Content-Language", equalTo("en"))
            .body("title", equalTo("Prompt Injection"));
    }

    @Test
    @DisplayName("GET /api/threats/llm01 with Accept-Language: de falls back to English")
    void getThreat_unsupportedLocale_fallsBackToEnglish() {
        given().port(port)
            .header("Accept-Language", "de")
            .when().get("/api/threats/llm01")
            .then().statusCode(200)
            .header("Content-Language", equalTo("en"))
            .body("title", equalTo("Prompt Injection"));
    }

    @Test
    @DisplayName("GET /api/threats list with Accept-Language: pl returns Polish titles for all threats")
    void getThreatList_acceptLanguagePl_allTitlesInPolish() {
        given().port(port)
            .header("Accept-Language", "pl")
            .when().get("/api/threats?framework=OWASP_LLM")
            .then().statusCode(200)
            .body("content[0].title", not(equalTo("Prompt Injection")))
            .body("content[0].title", equalTo("Wstrzykiwanie promptów"));
    }

    @Test
    @DisplayName("GET /api/search?q=wstrzykiwanie with Accept-Language: pl returns Polish results")
    void search_polishQuery_returnsPolishResults() {
        given().port(port)
            .header("Accept-Language", "pl")
            .queryParam("q", "wstrzykiwanie")
            .when().get("/api/search")
            .then().statusCode(200)
            .body("threats.size()", greaterThan(0))
            .body("threats[0].title", containsString("wstrzykiwanie").or(containsString("Wstrzykiwanie")));
    }

    @Test
    @DisplayName("Code samples are not translated — same content regardless of Accept-Language")
    void getCodeSamples_contentIsNotAffectedByLocale() {
        String enCode = given().port(port)
            .header("Accept-Language", "en")
            .when().get("/api/threats/llm01/code-samples")
            .then().extract().jsonPath().getString("[0].defenseSnippet");

        String plCode = given().port(port)
            .header("Accept-Language", "pl")
            .when().get("/api/threats/llm01/code-samples")
            .then().extract().jsonPath().getString("[0].defenseSnippet");

        assertThat(plCode).isEqualTo(enCode);
    }
}
```

### Frontend Component Tests

**File:** `LanguageToggle.test.tsx`

```typescript
// TDD: write this test BEFORE creating the LanguageToggle component
describe('LanguageToggle', () => {
  beforeEach(() => {
    localStorage.clear()
    i18n.changeLanguage('pl')
  })

  it('renders PL as active and EN as inactive when language is Polish', () => {
    render(<LanguageToggle />)
    expect(screen.getByRole('button', { name: 'PL' })).toHaveAttribute('aria-pressed', 'true')
    expect(screen.getByRole('button', { name: 'EN' })).toHaveAttribute('aria-pressed', 'false')
  })

  it('clicking EN switches UI language to English without page reload', async () => {
    render(<LanguageToggle />)
    await userEvent.click(screen.getByRole('button', { name: 'EN' }))
    expect(i18n.language).toBe('en')
    expect(screen.getByRole('button', { name: 'EN' })).toHaveAttribute('aria-pressed', 'true')
  })

  it('persists chosen language to localStorage after click', async () => {
    render(<LanguageToggle />)
    await userEvent.click(screen.getByRole('button', { name: 'EN' }))
    expect(localStorage.getItem('sv_locale')).toBe('en')
  })

  it('is keyboard accessible — pressing Enter on EN button switches language', async () => {
    render(<LanguageToggle />)
    screen.getByRole('button', { name: 'EN' }).focus()
    await userEvent.keyboard('{Enter}')
    expect(i18n.language).toBe('en')
  })
})
```

**File:** `NavBar.i18n.test.tsx`

```typescript
describe('NavBar — i18n integration', () => {
  it('shows Polish nav labels when language is pl', async () => {
    await i18n.changeLanguage('pl')
    render(<NavBar />, { wrapper: RouterWrapper })
    expect(screen.getByText('Zagrożenia')).toBeInTheDocument()
    expect(screen.getByText('Frameworki')).toBeInTheDocument()
    expect(screen.getByText('Macierz')).toBeInTheDocument()
  })

  it('shows English nav labels when language is en', async () => {
    await i18n.changeLanguage('en')
    render(<NavBar />, { wrapper: RouterWrapper })
    expect(screen.getByText('Threats')).toBeInTheDocument()
    expect(screen.getByText('Frameworks')).toBeInTheDocument()
    expect(screen.getByText('Matrix')).toBeInTheDocument()
  })
})
```

**File:** `ThreatDetail.i18n.test.tsx`

```typescript
describe('ThreatDetail — language switching', () => {
  it('re-fetches threat in Polish when language switches to pl', async () => {
    server.use(
      http.get('/api/threats/llm01', ({ request }) => {
        const lang = request.headers.get('Accept-Language')
        if (lang === 'pl') return HttpResponse.json(mockLlm01Polish)
        return HttpResponse.json(mockLlm01English)
      })
    )

    await i18n.changeLanguage('en')
    render(<ThreatDetailPage threatId="llm01" />, { wrapper })
    await screen.findByText('Prompt Injection')

    await i18n.changeLanguage('pl')
    // component should re-fetch with Accept-Language: pl
    await screen.findByText('Wstrzykiwanie promptów')
    expect(screen.queryByText('Prompt Injection')).not.toBeInTheDocument()
  })

  it('code sample blocks are identical in both languages', async () => {
    await i18n.changeLanguage('en')
    render(<ThreatDetailPage threatId="llm01" />, { wrapper })
    const enCode = (await screen.findByTestId('code-block-defense')).textContent

    await i18n.changeLanguage('pl')
    const plCode = screen.getByTestId('code-block-defense').textContent

    expect(plCode).toBe(enCode)
  })
})
```

**File:** `i18n.keys.test.ts`

```typescript
// Mirrors the Java I18nKeysValidatorTest — catches missing keys at frontend level
import enTranslations from '../i18n/en.json'
import plTranslations from '../i18n/pl.json'

function flatKeys(obj: Record<string, unknown>, prefix = ''): string[] {
  return Object.entries(obj).flatMap(([k, v]) =>
    typeof v === 'object' && v !== null
      ? flatKeys(v as Record<string, unknown>, prefix ? `${prefix}.${k}` : k)
      : [`${prefix ? prefix + '.' : ''}${k}`]
  )
}

describe('i18n key completeness', () => {
  const enKeys = flatKeys(enTranslations)
  const plKeys = flatKeys(plTranslations)

  it('pl.json has no missing keys compared to en.json', () => {
    const missing = enKeys.filter(k => !plKeys.includes(k))
    expect(missing).toEqual([])
  })

  it('en.json has no missing keys compared to pl.json', () => {
    const missing = plKeys.filter(k => !enKeys.includes(k))
    expect(missing).toEqual([])
  })

  it('no translation value is an empty string', () => {
    const allValues = [
      ...Object.values(enTranslations).flat(),
      ...Object.values(plTranslations).flat()
    ]
    allValues.forEach(v => expect(typeof v === 'string' ? v.trim() : '').not.toBe(''))
  })
})
```

### E2E Test

**File:** `e2e/us11-language-switch.spec.ts`

```typescript
test.describe('US-11: Polish/English language switching', () => {

  test('default language is Polish on first visit', async ({ page }) => {
    await page.context().clearCookies()
    await page.evaluate(() => localStorage.clear())
    await page.goto('/')
    await expect(page.locator('[data-testid="nav-threats"]')).toHaveText('Zagrożenia')
    await expect(page.locator('[data-testid="lang-toggle-PL"]'))
      .toHaveAttribute('aria-pressed', 'true')
  })

  test('clicking EN switches all UI text to English instantly', async ({ page }) => {
    await page.goto('/')
    await page.click('[data-testid="lang-toggle-EN"]')
    // no navigation occurs
    await expect(page).toHaveURL('/')
    await expect(page.locator('[data-testid="nav-threats"]')).toHaveText('Threats')
    await expect(page.locator('[data-testid="lang-toggle-EN"]'))
      .toHaveAttribute('aria-pressed', 'true')
  })

  test('language preference persists after reload', async ({ page }) => {
    await page.goto('/')
    await page.click('[data-testid="lang-toggle-EN"]')
    await page.reload()
    await expect(page.locator('[data-testid="nav-threats"]')).toHaveText('Threats')
    const stored = await page.evaluate(() => localStorage.getItem('sv_locale'))
    expect(stored).toBe('en')
  })

  test('threat detail shows Polish content when PL is active', async ({ page }) => {
    await page.goto('/threats/llm01')
    // ensure PL is active (default)
    await expect(page.locator('[data-testid="lang-toggle-PL"]'))
      .toHaveAttribute('aria-pressed', 'true')
    await expect(page.locator('h1')).toContainText('Wstrzykiwanie promptów')
  })

  test('switching to EN on threat detail re-renders title in English', async ({ page }) => {
    await page.goto('/threats/llm01')
    await page.click('[data-testid="lang-toggle-EN"]')
    await expect(page.locator('h1')).toContainText('Prompt Injection')
    // URL unchanged
    await expect(page).toHaveURL('/threats/llm01')
  })

  test('code blocks are not translated — identical in both languages', async ({ page }) => {
    await page.goto('/threats/llm01')
    await page.click('[role="tab"][name="Code Samples"]')
    await page.click('[role="tab"][name="Java"]')
    await page.click('[role="tab"][name="Defense Example"]')
    const codeEn = await page.locator('[data-testid="code-block-defense"]').textContent()

    await page.click('[data-testid="lang-toggle-PL"]')
    const codePl = await page.locator('[data-testid="code-block-defense"]').textContent()

    expect(codePl).toBe(codeEn)
  })
})
```

---

## TDD Execution Order

Follow this order when implementing — write each test file before the corresponding production code:

```
PHASE 1 — Red: Write ALL test files first (no production code yet)
  backend/src/test/java/...
    └── service/      ThreatServiceTest, FrameworkServiceTest, CodeSampleServiceTest,
                      CrossReferenceServiceTest, SearchServiceTest,
                      CoverageServiceTest, CsvExportServiceTest,
                      KillChainMapperTest, CodeSampleValidatorTest,
                      LocalizationServiceTest, ThreatLocalizationServiceTest,
                      I18nKeysValidatorTest
    └── controller/   ThreatControllerIT, CodeSampleControllerIT,
                      CrossReferenceControllerIT, CoverageControllerIT,
                      ExportControllerIT, SearchControllerIT, TimelineControllerIT,
                      LocalizationControllerIT
  frontend/src/__tests__/
    └──               FrameworkTile.test, ThreatList.test, CodeSamplePanel.test,
                      LanguageFilter.test, CrossReferenceTab.test, MatrixPage.test,
                      StrideHeatmap.test, SearchResultsPage.test, ExportButton.test,
                      KillChainTimeline.test, CodeTab.test, LuaCodeBlock.test,
                      LanguageToggle.test, NavBar.i18n.test, ThreatDetail.i18n.test,
                      i18n.keys.test
  frontend/src/i18n/
    └──               en.json (write all keys with English values — BEFORE any component)
                      pl.json (write all keys with Polish values — BEFORE any component)
  e2e/
    └──               us01 through us10 spec files, us11-language-switch.spec.ts

PHASE 2 — Green: Implement production code until all tests pass
  For each user story, implement in this order:
    1. Entity + Repository (for i18n: add ThreatTranslation entity + migration)
    2. Service (for i18n: LocalizationService + locale-aware ThreatService overloads)
    3. Controller (for i18n: Accept-Language header binding + Content-Language response header)
    4. Translation JSON files (en.json, pl.json — ALL keys, no blanks)
    5. React i18n provider (i18next init, lazy locale loading)
    6. React component (for i18n: LanguageToggle, NavBar, ThreatDetail locale-aware fetch)
    7. Verify E2E passes

PHASE 3 — Refactor: Clean up without breaking tests
  Run: mvn test (backend) + npx vitest run (frontend) + npx playwright test (e2e)
  All must pass before any commit.

  i18n-specific refactor checklist:
    [ ] No hardcoded strings remain in any .tsx file (grep for user-visible English words)
    [ ] All API calls include Accept-Language header from i18n context
    [ ] Language switch triggers only one API re-fetch, not a full remount
    [ ] pl.json and en.json key counts are equal (I18nKeysValidatorTest enforces this)
```

---

## CI Pipeline Test Execution

```yaml
# .github/workflows/test.yml (write this BEFORE the first commit)
jobs:
  backend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21' }
      - run: mvn -f backend/pom.xml test
        # Testcontainers pulls postgres:16-alpine automatically

  frontend-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: cd frontend && npm ci && npx vitest run --coverage

  i18n-key-parity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21' }
      # Java test: I18nKeysValidatorTest checks en.json vs pl.json parity
      - run: mvn -f backend/pom.xml test -Dtest=I18nKeysValidatorTest
      # Also run the frontend key-parity test in isolation so it fails fast
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: cd frontend && npm ci && npx vitest run src/__tests__/i18n.keys.test.ts

  e2e-tests:
    needs: [backend-tests, frontend-tests]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker compose up -d --wait
      - run: cd e2e && npx playwright test
      - uses: actions/upload-artifact@v4
        if: failure()
        with:
          name: playwright-report
          path: e2e/playwright-report/
```

---

## Test Coverage Targets

| Layer | Target | Tool |
|---|---|---|
| Backend service classes | ≥ 80% line coverage | JaCoCo (Maven plugin) |
| Backend controller integration | 100% endpoints tested | Rest Assured + Testcontainers |
| React components | ≥ 75% branch coverage | Vitest + c8 |
| E2E critical paths | 11 user stories × 1+ test | Playwright |
| i18n key parity | 100% — zero missing keys allowed | I18nKeysValidatorTest + i18n.keys.test.ts |
| i18n locale coverage | Both `pl` and `en` tested for every API endpoint | LocalizationControllerIT |
| Total test count (minimum) | 125 tests | — |

### i18n Test File Summary

| Test file | Layer | What it covers |
|---|---|---|
| `LocalizationServiceTest.java` | Unit | `resolveLocale()` — all edge cases (pl, en, de, null) |
| `ThreatLocalizationServiceTest.java` | Unit | Polish/English content returned from service; fallback to English |
| `I18nKeysValidatorTest.java` | Unit | `en.json` ↔ `pl.json` key parity; no blank values |
| `LocalizationControllerIT.java` | Integration | `Accept-Language` header → response body locale; `Content-Language` header; fallback; code samples not affected |
| `LanguageToggle.test.tsx` | Component | Toggle renders; click switches language; persists to localStorage; keyboard accessible |
| `NavBar.i18n.test.tsx` | Component | Nav labels in Polish and English |
| `ThreatDetail.i18n.test.tsx` | Component | Re-fetch on language switch; code blocks unchanged |
| `i18n.keys.test.ts` | Unit (TS) | `en.json` ↔ `pl.json` key parity at frontend level |
| `us11-language-switch.spec.ts` | E2E | Full 6-scenario user journey across Polish ↔ English |

---

## Rozszerzenie na podstawie kart OWASP Cornucopia (US-12 … US-18)

> **Źródło:** pliki `./docs/OWASP_stories/*.yaml` — OWASP Cornucopia Companion v1.0, Website App v3.0,
> Mobile App v1.1, STRIDE EoP v5.0, Elevation of MLSec v1.0.
> Każda historia użytkownika opisuje treści, które aplikacja SecureVision 2026 **prezentuje** użytkownikom
> (nie nowe ataki na samą aplikację). Dla każdej historii podano:
> - Mapowanie kart YAML → identyfikatory OWASP
> - Polskie tłumaczenia kluczowych kart (King/Queen/Jack/10/Ace)
> - Plan TDD: kryteria akceptacji (Gherkin), testy jednostkowe (JUnit 5), testy integracyjne
>   (Testcontainers), testy komponentów (Vitest/RTL) i testy E2E (Playwright)

### Tabela mapowania YAML → OWASP

| Plik YAML | Talia (suit) | Pokryty standard OWASP / framework |
|---|---|---|
| `__LLM_AI___companion-cards-1.0-en.yaml` | LLM | OWASP LLM Top 10 2025 (LLM01–LLM10) |
| `__LLM_AI___companion-cards-1.0-en.yaml` | AAI | OWASP Agentic AI Top 10 2026 |
| `__LLM_AI___companion-cards-1.0-en.yaml` | FRE | OWASP Top 10 Client-Side Security Risks |
| `__LLM_AI___companion-cards-1.0-en.yaml` | DVO | OWASP Top 10 CI/CD Security Risks |
| `__LLM_AI___companion-cards-1.0-en.yaml` | BOT | OWASP Automated Threats to Web Applications |
| `__LLM_AI___companion-cards-1.0-en.yaml` | CLD | MITRE ATT&CK Cloud |
| `webapp-cards-3.0-en.yaml` | VE, AT, SM, AZ, CR | OWASP Web Top 10 2021 (A01–A10) |
| `mobileapp-cards-1.1-en.yaml` | PC, AA, NS, RS, CRM, CM | OWASP MASVS / MAS |
| `STRIDE__eop-cards-5.0-en.yaml` | SP, TA, RE, ID, DS, EP | STRIDE — modelowanie zagrożeń |
| `RISKS__elevation-of-mlsec-cards-1.0-en.yaml` | EMR, EIR, EOR, EDR | MITRE ATLAS + OWASP LLM Top 10 ML-specific |
| `dbd-cards-1.0-en.yaml` | SCO, ARC, AGE, TRU, POR | Digital Benefits & Disbenefits (UK) — etyczne wzorce projektowania usług |

> **Uwaga — `dbd-cards-1.0-en.yaml`:** Jest to talia projektowania usług cyfrowych (badania Newcastle University / UKRI)
> dotycząca szkód wyrządzanych petentom przez cyfrowe systemy świadczeń socjalnych. Nie jest talią bezpieczeństwa OWASP.
> Odnosi się do WCAG 2.1 AA, zasad dostępności (NFR-03) i wzorców projektowania etycznego.
> Pełne User Story na podstawie tej talii jest poza zakresem MVP — materiał do wersji 2.0.

---

## US-12: Zagrożenia warstwy frontendu — karta FRE (OWASP Client-Side Top 10)

**Źródło YAML:** `__LLM_AI___companion-cards-1.0-en.yaml`, talia `FRE` (Frontend)

### Mapowanie kart FRE → OWASP

| ID karty | Angielski opis (skrócony) | Tłumaczenie polskie | OWASP |
|---|---|---|---|
| FRE4 | James injects JavaScript through user-controlled data written into the DOM | **James wstrzykuje JavaScript przez dane sterowane przez użytkownika zapisane do DOM, uruchamiając dowolny kod w przeglądarce ofiary.** | A03:2021 Injection (XSS), Client-Side C01 |
| FRE6 | Olga exploits malicious JS to steal authentication tokens and hijack sessions | **Olga wykorzystuje złośliwy JavaScript do kradzieży tokenów uwierzytelniania i przejęcia sesji użytkownika.** | A07:2021, Client-Side C06 |
| FRE7 | Carlos exploits misconfigured CORS or unsafe postMessage | **Carlos wykorzystuje błędnie skonfigurowane CORS lub niebezpieczną obsługę postMessage do odczytu wrażliwych danych z innego źródła.** | A05:2021 Security Misconfiguration, Client-Side C02 |
| FRE9 | Sophia reuses, predicts, or forges JWTs to take over sessions | **Sophia ponownie używa, przewiduje lub fałszuje JWTy lub tokeny dostępu, podszywając się pod użytkowników i przejmując aktywne sesje.** | A07:2021, Client-Side C03 |
| FREX | Piotr embeds the app in a hidden frame (clickjacking) | **Piotr osadza aplikację w ukrytej lub zamaskowanej ramce, aby nakłonić użytkowników do klikania elementów UI wykonujących wrażliwe akcje.** | Client-Side C05 Clickjacking |
| FREQ | Kim injects persistent malicious code into frontend assets | **Kim wstrzykuje trwały złośliwy kod do zasobów frontendu, umożliwiając długoterminową kontrolę nad przeglądarkami wszystkich użytkowników.** | A08:2021 Software and Data Integrity Failures |
| FREK | Darius utilizes a JS app to control users' systems and data | **Darius wykorzystuje aplikację JavaScript do zarządzania i kontrolowania systemów, dzierżawców i danych użytkowników bez autoryzacji.** | A01:2021 Broken Access Control |

### User Story US-12

```
JAKO:   użytkownik aplikacji SecureVision 2026 (deweloper / tester bezpieczeństwa)
CHCĘ:   przeglądać interaktywne scenariusze zagrożeń warstwy frontendu
        oparte na kartach OWASP Cornucopia FRE
PO TO:  żeby zrozumieć ataki XSS, CSRF, clickjacking, kradzież tokenów JWT
        i inne zagrożenia po stronie klienta ze wskazaniem zagrożeń
        z OWASP Top 10 Client-Side Security Risks
```

### Kryteria akceptacji (Gherkin)

```gherkin
Feature: US-12 Przeglądanie zagrożeń frontendu (OWASP Cornucopia FRE)

  Scenario: Wyświetlanie listy kart FRE z identyfikatorami OWASP Client-Side
    Given użytkownik jest na stronie "/frameworks/frontend-security"
    When strona jest załadowana
    Then widoczne są karty FRE2 do FREA posortowane według wartości
    And każda karta wyświetla identyfikator OWASP Client-Side (np. "Client-Side C01")
    And karty "face" (J, Q, K, A) są oznaczone jako scenariusze krytyczne

  Scenario: Szczegóły karty FRE4 — DOM XSS
    Given użytkownik jest na stronie "/frameworks/frontend-security"
    When użytkownik klika kartę "FRE4"
    Then wyświetla się tytuł "DOM-based XSS — James"
    And opis w aktywnym języku (pl/en) opisuje wstrzyknięcie JavaScript przez DOM
    And wyświetlone są zakładki: Opis | Atenuacje | Przykłady kodu | Powiązania
    And zakładka "Przykłady kodu" zawiera przykład podatnego i bezpiecznego kodu React
    And etykieta "A03:2021 Injection" jest widoczna i klikalnie prowadzi do szczegółów zagrożenia

  Scenario: Filtrowanie kart FRE według kategorii OWASP
    Given użytkownik jest na stronie "/frameworks/frontend-security"
    When użytkownik wybiera filtr "A07:2021"
    Then wyświetlane są tylko karty FRE6, FRE9 powiązane z A07:2021
    And pozostałe karty są ukryte

  Scenario: Polska treść kart FRE
    Given użytkownik wybrał język "pl" (domyślny)
    When użytkownik otwiera kartę "FREX — Clickjacking"
    Then opis jest wyświetlony po polsku: zawiera słowo "ramce" i "wrażliwe akcje"
    And etykieta zagrożenia brzmi "Client-Side C05: Clickjacking"
```

### Testy jednostkowe — `FrontendThreatServiceTest.java`

```java
// backend/src/test/java/com/securevision/service/FrontendThreatServiceTest.java
@ExtendWith(MockitoExtension.class)
class FrontendThreatServiceTest {

    @Mock  ThreatRepository threatRepository;
    @InjectMocks  FrontendThreatService service;

    @Test
    void returnsAllFreCardsOrderedByValue() {
        List<Threat> cards = List.of(
            threat("FRE2", 2), threat("FRE4", 4), threat("FREK", 13)
        );
        when(threatRepository.findBySuitCode("FRE")).thenReturn(cards);

        List<Threat> result = service.getCardsBySuit("FRE");

        assertThat(result).isSortedAccordingTo(Comparator.comparingInt(Threat::getValue));
        assertThat(result).hasSize(3);
    }

    @Test
    void mapsFre4ToOwaspClientSideC01() {
        Threat fre4 = threat("FRE4", 4);
        fre4.setOwaspRefs(List.of("A03:2021", "Client-Side C01"));
        when(threatRepository.findByCardId("FRE4")).thenReturn(Optional.of(fre4));

        Threat result = service.getCardById("FRE4");

        assertThat(result.getOwaspRefs()).contains("A03:2021", "Client-Side C01");
    }

    @Test
    void filterByOwaspRefReturnsOnlyMatchingCards() {
        List<Threat> allFre = List.of(
            threatWithRef("FRE6", "A07:2021"),
            threatWithRef("FRE9", "A07:2021"),
            threatWithRef("FRE4", "A03:2021")
        );
        when(threatRepository.findBySuitCode("FRE")).thenReturn(allFre);

        List<Threat> result = service.filterByOwaspRef("FRE", "A07:2021");

        assertThat(result).hasSize(2);
        assertThat(result).allMatch(t -> t.getOwaspRefs().contains("A07:2021"));
    }

    @Test
    void frexIsMappedToClickjackingClientSideC05() {
        Threat frex = threat("FREX", 10);
        frex.setOwaspRefs(List.of("Client-Side C05"));
        when(threatRepository.findByCardId("FREX")).thenReturn(Optional.of(frex));

        Threat result = service.getCardById("FREX");

        assertThat(result.getOwaspRefs()).containsExactly("Client-Side C05");
    }
}
```

### Test integracyjny — `FrontendThreatControllerIT.java`

```java
// backend/src/test/java/com/securevision/controller/FrontendThreatControllerIT.java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@Sql("/sql/frontend-threats-seed.sql")
class FrontendThreatControllerIT {

    @Container
    static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void getFreCards_returns13Cards() {
        given().when().get("/api/v1/threats?suit=FRE&lang=en")
            .then().statusCode(200)
            .body("content", hasSize(13))
            .body("content[0].cardId", equalTo("FRE2"));
    }

    @Test
    void getFreCard_fre4_hasOwaspA03Ref() {
        given().when().get("/api/v1/threats/FRE4?lang=en")
            .then().statusCode(200)
            .body("owaspRefs", hasItem("A03:2021"))
            .body("owaspRefs", hasItem("Client-Side C01"));
    }

    @Test
    void getFreCards_filterByA07_returns2Cards() {
        given().when().get("/api/v1/threats?suit=FRE&owaspRef=A07%3A2021")
            .then().statusCode(200)
            .body("content", hasSize(2))
            .body("content.cardId", hasItems("FRE6", "FRE9"));
    }

    @Test
    void getFreCard_frex_polishDescription_containsClickjackingKeyword() {
        given().header("Accept-Language", "pl")
            .when().get("/api/v1/threats/FREX")
            .then().statusCode(200)
            .body("descriptionPl", containsString("ramce"));
    }
}
```

### Test komponentu — `FrontendThreatCard.test.tsx`

```typescript
// frontend/src/components/__tests__/FrontendThreatCard.test.tsx
import { render, screen, fireEvent } from '@testing-library/react'
import { FrontendThreatCard } from '../FrontendThreatCard'

const fre4 = {
  cardId: 'FRE4', value: 4, suitName: 'Frontend',
  descriptionPl: 'James wstrzykuje JavaScript przez dane sterowane przez użytkownika zapisane do DOM.',
  descriptionEn: 'James injects JavaScript through user-controlled data written into the DOM.',
  owaspRefs: ['A03:2021', 'Client-Side C01'],
}

it('renders card ID and OWASP badge', () => {
  render(<FrontendThreatCard card={fre4} lang="pl" />)
  expect(screen.getByText('FRE4')).toBeInTheDocument()
  expect(screen.getByText('A03:2021')).toBeInTheDocument()
  expect(screen.getByText('Client-Side C01')).toBeInTheDocument()
})

it('displays Polish description when lang=pl', () => {
  render(<FrontendThreatCard card={fre4} lang="pl" />)
  expect(screen.getByText(/wstrzykuje JavaScript/)).toBeInTheDocument()
})

it('displays English description when lang=en', () => {
  render(<FrontendThreatCard card={fre4} lang="en" />)
  expect(screen.getByText(/injects JavaScript/)).toBeInTheDocument()
})

it('calls onSelect when card is clicked', () => {
  const onSelect = vi.fn()
  render(<FrontendThreatCard card={fre4} lang="pl" onSelect={onSelect} />)
  fireEvent.click(screen.getByRole('article'))
  expect(onSelect).toHaveBeenCalledWith('FRE4')
})
```

### Test E2E — `us12-frontend-threats.spec.ts`

```typescript
// e2e/us12-frontend-threats.spec.ts
import { test, expect } from '@playwright/test'

test('US-12: strona kart FRE wyświetla 13 kart posortowanych', async ({ page }) => {
  await page.goto('/frameworks/frontend-security')
  const cards = page.locator('[data-testid="threat-card"]')
  await expect(cards).toHaveCount(13)
  const firstId = await cards.first().getAttribute('data-card-id')
  expect(firstId).toBe('FRE2')
})

test('US-12: kliknięcie FRE4 otwiera szczegóły z odwołaniem do A03:2021', async ({ page }) => {
  await page.goto('/frameworks/frontend-security')
  await page.click('[data-card-id="FRE4"]')
  await expect(page.locator('h1')).toContainText('DOM-based XSS')
  await expect(page.locator('[data-owasp-ref="A03:2021"]')).toBeVisible()
})

test('US-12: filtr A07:2021 pozostawia tylko FRE6 i FRE9', async ({ page }) => {
  await page.goto('/frameworks/frontend-security')
  await page.selectOption('[data-testid="owasp-filter"]', 'A07:2021')
  const cards = page.locator('[data-testid="threat-card"]')
  await expect(cards).toHaveCount(2)
  await expect(page.locator('[data-card-id="FRE6"]')).toBeVisible()
  await expect(page.locator('[data-card-id="FRE9"]')).toBeVisible()
})
```

---

## US-13: Scenariusze zagrożeń LLM — karty OWASP Cornucopia LLM

**Źródło YAML:** `__LLM_AI___companion-cards-1.0-en.yaml`, talia `LLM`

### Mapowanie kart LLM → OWASP LLM Top 10 2025

| ID karty | Polskie tłumaczenie kluczowego zagrożenia | OWASP LLM 2025 |
|---|---|---|
| LLMX (10) | **Sarah nadpisuje promptami systemowymi lub instrukcjami bezpieczeństwa przez spreparowane dane wejściowe, powodując ignorowanie przez model zamierzonych ograniczeń lub wykonywanie nieautoryzowanych działań.** | LLM01:2025 Prompt Injection + LLM07:2025 System Prompt Leakage |
| LLM9 | **Deckard osadza złośliwe instrukcje w zewnętrznych treściach (dokumentach, e-mailach, stronach web) przetwarzanych przez model, prowadząc do niezamierzonego zachowania lub eksfiltracji danych.** | LLM01:2025 Prompt Injection (pośrednie) |
| LLMQ | **Kyle wykorzystuje niebezpieczną obsługę wyjść modelu używanych bezpośrednio w systemach downstream, umożliwiając ataki injection, zdalne wykonanie kodu lub nieautoryzowane działania.** | LLM05:2025 Improper Output Handling |
| LLM4 | **David powoduje ujawnienie przez model wrażliwych informacji z danych treningowych, promptów systemowych, konfiguracji lub kontekstu innych użytkowników z powodu niewystarczającego filtrowania wyjść.** | LLM02:2025 Sensitive Information Disclosure |
| LLMK (K) | **Ava wykorzystuje nadmierną agencję lub autonomię we wtyczkach, rozszerzeniach lub innych komponentach AI do wykonywania nieautoryzowanych lub wysokiego ryzyka działań z powodu braku zatwierdzenia przez człowieka.** | LLM06:2025 Excessive Agency |
| LLM7 | **Tyrell zatruwa zbiory danych treningowych lub sam proces fine-tuningu, wprowadzając backdoory lub złośliwe zachowania, które mogą być później aktywowane.** | LLM04:2025 Data and Model Poisoning |
| LLMJ (J) | **Ripley wprowadza skompromitowane modele innych firm, embeddingi lub złośliwe komponenty ML do łańcucha dostaw, prowadząc do ukrytych podatności lub kradzieży danych.** | LLM03:2025 Supply Chain |
| LLM3 | **Dave może wykorzystać nadmierne poleganie na wynikach LLM przy braku krytycznego nadzoru człowieka, prowadząc do błędów bezpieczeństwa lub błędnych decyzji opartych na halucynacjach.** | LLM09:2025 Misinformation |
| LLM5 | **Roy może eskalować uprawnienia lub uzyskać dostęp do danych innych użytkowników z powodu słabego uwierzytelniania lub błędnej izolacji sesji w systemach LLM multi-tenant.** | LLM08:2025 Vector and Embedding Weaknesses |
| LLM6 | **Andersen może manipulować bazami wiedzy, wektorowymi bazami danych lub źródłami RAG/MCP, powodując że model pobiera i prezentuje fałszywe lub złośliwe informacje jako fakty.** | LLM08:2025 Vector and Embedding Weaknesses |
| LLM2 | **Samantha może wyczerpać zasoby obliczeniowe lub zwiększyć koszty operacyjne przez złożone lub rekurencyjne zapytania do modelu, prowadząc do DoS modelu.** | LLM10:2025 Unbounded Consumption |

### User Story US-13

```
JAKO:   deweloper / architekt bezpieczeństwa / student AI security
CHCĘ:   przeglądać kompletny katalog zagrożeń LLM (OWASP LLM Top 10 2025)
        z przykładowymi scenariuszami ataków opartymi na kartach Cornucopia LLM
PO TO:  żeby zrozumieć każde z 10 zagrożeń OWASP LLM 2025 w kontekście
        konkretnych scenariuszy ataku i znać wzorce zabezpieczeń
```

### Kryteria akceptacji (Gherkin)

```gherkin
Feature: US-13 Przeglądanie zagrożeń LLM (OWASP LLM Top 10 2025)

  Scenario: Wyświetlanie wszystkich 10 zagrożeń OWASP LLM 2025
    Given użytkownik jest na stronie "/frameworks/llm-security"
    When strona jest załadowana
    Then widoczne są karty LLM2 do LLMA posortowane wartością
    And dla każdej karty wyświetlony jest identyfikator OWASP LLM (np. "LLM01:2025")
    And karty oznaczone jako krytyczne (K, Q, J) mają badge "KRYTYCZNE"

  Scenario: Szczegóły karty LLMX — Prompt Injection / System Prompt
    Given użytkownik otwiera kartę "LLMX"
    Then tytuł brzmi "Manipulacja promptem systemowym — Sarah"
    And opis po polsku zawiera tekst "ignorowanie przez model zamierzonych ograniczeń"
    And wyświetlone są odwołania: "LLM01:2025" i "LLM07:2025"
    And zakładka "Przykłady kodu" zawiera Python (FastAPI) pokazujący podatny i bezpieczny endpoint

  Scenario: Karta LLM7 — Data and Model Poisoning
    Given użytkownik otwiera kartę "LLM7"
    Then opis po polsku zawiera słowa "backdoory" i "fine-tuningu"
    And wyświetlone jest odwołanie "LLM04:2025 Data and Model Poisoning"
    And sekcja "Mitigacje" zawiera co najmniej 3 strategie ochrony

  Scenario: Widok matrycy LLM Top 10 — pokrycie kart
    Given użytkownik jest na stronie "/matrix/llm"
    When strona jest załadowana
    Then wyświetlona jest tabela 10 wierszy (LLM01–LLM10) × kolumny kart Cornucopia
    And każde zagrożenie LLM ma przypisaną co najmniej jedną kartę Cornucopia

  Scenario: Wyszukiwanie "prompt injection" zwraca karty LLM i AAI
    Given użytkownik wpisuje "prompt injection" w globalną wyszukiwarkę
    Then wyniki zawierają karty LLMX, LLM9 i AAI7
    And każdy wynik oznaczony jest identyfikatorem OWASP
```

### Testy jednostkowe — `LlmThreatServiceTest.java`

```java
// backend/src/test/java/com/securevision/service/LlmThreatServiceTest.java
@ExtendWith(MockitoExtension.class)
class LlmThreatServiceTest {

    @Mock  ThreatRepository threatRepository;
    @Mock  MitigationRepository mitigationRepository;
    @InjectMocks  LlmThreatService service;

    @Test
    void llmxIsMappedToBothLlm01AndLlm07() {
        Threat llmx = threat("LLMX", 10);
        llmx.setOwaspRefs(List.of("LLM01:2025", "LLM07:2025"));
        when(threatRepository.findByCardId("LLMX")).thenReturn(Optional.of(llmx));

        Threat result = service.getCardById("LLMX");

        assertThat(result.getOwaspRefs()).containsExactlyInAnyOrder("LLM01:2025", "LLM07:2025");
    }

    @Test
    void getLlmTop10Matrix_returnsTenRows() {
        when(threatRepository.findBySuitCode("LLM")).thenReturn(buildAllLlmCards());

        List<LlmMatrixRow> matrix = service.buildOwaspLlmMatrix();

        assertThat(matrix).hasSize(10);
        assertThat(matrix).allMatch(row -> !row.getMappedCards().isEmpty());
    }

    @Test
    void llm7MitigationsAreAtLeastThree() {
        Threat llm7 = threat("LLM7", 7);
        List<Mitigation> mitigations = List.of(
            mitigation("Walidacja danych treningowych"),
            mitigation("Izolacja modeli produkcyjnych"),
            mitigation("Weryfikacja checksum fine-tuned modeli")
        );
        when(threatRepository.findByCardId("LLM7")).thenReturn(Optional.of(llm7));
        when(mitigationRepository.findByThreatId(llm7.getId())).thenReturn(mitigations);

        List<Mitigation> result = service.getMitigationsForCard("LLM7");

        assertThat(result).hasSizeGreaterThanOrEqualTo(3);
    }

    @Test
    void searchPromptInjection_returnsLlmxAndLlm9() {
        List<Threat> matched = List.of(threat("LLMX", 10), threat("LLM9", 9));
        when(threatRepository.searchByKeyword("prompt injection")).thenReturn(matched);

        List<Threat> result = service.search("prompt injection");

        assertThat(result).extracting(Threat::getCardId)
            .containsExactlyInAnyOrder("LLMX", "LLM9");
    }
}
```

### Test integracyjny — `LlmThreatControllerIT.java`

```java
// backend/src/test/java/com/securevision/controller/LlmThreatControllerIT.java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@Sql("/sql/llm-threats-seed.sql")
class LlmThreatControllerIT {

    @Container
    static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void getLlmCards_returns13Cards() {
        given().when().get("/api/v1/threats?suit=LLM&lang=en")
            .then().statusCode(200)
            .body("content", hasSize(13));
    }

    @Test
    void getLlmxCard_hasTwoOwaspLlmRefs() {
        given().header("Accept-Language", "en")
            .when().get("/api/v1/threats/LLMX")
            .then().statusCode(200)
            .body("owaspRefs", hasItems("LLM01:2025", "LLM07:2025"));
    }

    @Test
    void getLlmxCard_polishDescription_containsSystemPromptKeyword() {
        given().header("Accept-Language", "pl")
            .when().get("/api/v1/threats/LLMX")
            .then().statusCode(200)
            .body("descriptionPl", containsString("prompta systemowego"));
    }

    @Test
    void getLlmMatrix_hasExactlyTenRows() {
        given().when().get("/api/v1/matrix/llm")
            .then().statusCode(200)
            .body("rows", hasSize(10));
    }

    @Test
    void searchPromptInjection_findsAtLeastLlmxAndLlm9() {
        given().queryParam("q", "prompt injection")
            .when().get("/api/v1/search")
            .then().statusCode(200)
            .body("results.cardId", hasItems("LLMX", "LLM9"));
    }
}
```

### Test komponentu — `LlmThreatMatrix.test.tsx`

```typescript
// frontend/src/components/__tests__/LlmThreatMatrix.test.tsx
import { render, screen } from '@testing-library/react'
import { LlmThreatMatrix } from '../LlmThreatMatrix'

const mockMatrix = Array.from({ length: 10 }, (_, i) => ({
  threatId: `LLM0${i + 1}:2025`,
  title: `LLM Threat ${i + 1}`,
  cards: [`LLM${i + 2}`],
}))

it('renders 10 OWASP LLM rows', () => {
  render(<LlmThreatMatrix rows={mockMatrix} />)
  expect(screen.getAllByRole('row')).toHaveLength(11) // 10 + header
})

it('displays LLM01:2025 Prompt Injection row', () => {
  render(<LlmThreatMatrix rows={mockMatrix} />)
  expect(screen.getByText(/LLM01:2025/)).toBeInTheDocument()
})

it('each row has at least one card badge', () => {
  render(<LlmThreatMatrix rows={mockMatrix} />)
  const badges = screen.getAllByTestId('card-badge')
  expect(badges.length).toBeGreaterThanOrEqualTo(10)
})
```

### Test E2E — `us13-llm-threats.spec.ts`

```typescript
// e2e/us13-llm-threats.spec.ts
import { test, expect } from '@playwright/test'

test('US-13: strona LLM wyświetla 13 kart', async ({ page }) => {
  await page.goto('/frameworks/llm-security')
  await expect(page.locator('[data-testid="threat-card"]')).toHaveCount(13)
})

test('US-13: karta LLMX ma odwołania do LLM01 i LLM07', async ({ page }) => {
  await page.goto('/frameworks/llm-security')
  await page.click('[data-card-id="LLMX"]')
  await expect(page.locator('[data-owasp-ref="LLM01:2025"]')).toBeVisible()
  await expect(page.locator('[data-owasp-ref="LLM07:2025"]')).toBeVisible()
})

test('US-13: macierz LLM Top 10 ma 10 wierszy', async ({ page }) => {
  await page.goto('/matrix/llm')
  await expect(page.locator('[data-testid="matrix-row"]')).toHaveCount(10)
})

test('US-13: wyszukanie "prompt injection" zwraca LLMX', async ({ page }) => {
  await page.goto('/')
  await page.fill('[data-testid="global-search"]', 'prompt injection')
  await page.keyboard.press('Enter')
  await expect(page.locator('[data-card-id="LLMX"]')).toBeVisible()
})
```

---

## US-14: Zagrożenia autonomicznych agentów AI — karty AAI (OWASP Agentic AI Top 10)

**Źródło YAML:** `__LLM_AI___companion-cards-1.0-en.yaml`, talia `AAI` (Agentic AI)

### Mapowanie kart AAI → OWASP Agentic AI Top 10 2026

| ID karty | Polskie tłumaczenie | OWASP Agentic 2026 |
|---|---|---|
| AAIK (K) | **GPI-3.1415 wykonuje operacje wysokiego wpływu w zintegrowanych systemach ze względu na nadmierną agencję i brak zabezpieczeń transakcyjnych.** | AgentAI07 Excessive Autonomy |
| AAIQ (Q) | **Jane wykonuje przepływy pracy zdefiniowane przez atakującego na dużą skalę po skompromitowaniu płaszczyzny orkiestracji lub sterowania.** | AgentAI09 Orchestration Manipulation |
| AAIJ (J) | **BabyAGI ufa instrukcjom od agentów równorzędnych bez weryfikacji, walidacji polityki lub zapewnienia tożsamości.** | AgentAI10 Unvalidated Trust Chains |
| AAIX (10) | **DeepGeek autonomicznie planuje i wykonuje wieloetapowe operacje w systemach bez wykrywania złośliwych pośrednich celów.** | AgentAI09 Orchestration Manipulation |
| AAI9 | **CoPirate modyfikuje konfiguracje, uprawnienia lub ustawienia systemu poza zamierzoną autoryzacją z powodu nadmiernej autonomii.** | AgentAI07 Excessive Autonomy / AgentAI04 Privilege Escalation |
| AAI8 | **PreCursor wykonuje niezamierzony kod lub działania systemowe gdy kontrole walidacji wejść narzędzi i piaskownice są słabe.** | AgentAI05 Improper Output Handling |
| AAI7 | **Auto-GPT traktuje wyjścia zewnętrznych narzędzi jako autorytatywne i wykonuje wbudowane złośliwe instrukcje bez walidacji.** | AgentAI06 Unsafe Resource Access |
| AAI6 | **Gremlini uzyskuje dostęp i przetwarza wrażliwe źródła danych poza autoryzacją użytkownika z powodu niewystarczającej walidacji dostępu.** | AgentAI04 Privilege Escalation |
| AAI5 | **Watson ujawnia wrażliwe wewnętrzne instrukcje, polityki lub artefakty rozumowania pod wpływem wzorców adversarialnych.** | AgentAI02 Compromised Agent Identity |
| AAI4 | **MissTrial autonomicznie pętla lub łączy wywołania zewnętrznych narzędzi bez egzekwowania limitów szybkości lub kontroli budżetu.** | AgentAI03 Agent Memory Poisoning (budget exhaustion) |
| AAI2 | **Tay błędnie interpretuje intencje użytkownika z powodu niewystarczającej izolacji kontekstu i wykonuje działania poza oczekiwanym zakresem zadania.** | AgentAI01 Prompt Injection via Environment |

### User Story US-14

```
JAKO:   deweloper / architekt AI / specjalista ds. bezpieczeństwa AI
CHCĘ:   przeglądać scenariusze zagrożeń dla systemów autonomicznych agentów AI
        oparte na kartach OWASP Cornucopia AAI i OWASP Agentic AI Top 10 2026
PO TO:  żeby zrozumieć ryzyka związane z nadmierną agencją, łańcuchami agentów
        i atakami na orkiestrację, oraz poznać wzorce human-in-the-loop
```

### Kryteria akceptacji (Gherkin)

```gherkin
Feature: US-14 Zagrożenia autonomicznych agentów AI (OWASP Agentic AI Top 10)

  Scenario: Strona Agentic AI wyświetla 13 kart AAI
    Given użytkownik jest na stronie "/frameworks/agentic-ai"
    When strona jest załadowana
    Then wyświetlane są karty AAI2 do AAIA posortowane wartością
    And każda karta ma przypisany identyfikator z OWASP Agentic AI Top 10 2026

  Scenario: Karta AAIK — Excessive Agency (krytyczna)
    Given użytkownik otwiera kartę "AAIK"
    Then tytuł zawiera "GPI-3.1415 — Nadmierna agencja"
    And opis po polsku zawiera "brak zabezpieczeń transakcyjnych"
    And wyświetlone jest odwołanie "AgentAI07 Excessive Autonomy"
    And sekcja "Mitigacje" zawiera wzorzec "human-in-the-loop approval"

  Scenario: Diagram łańcucha agentów (agent chain visualization)
    Given użytkownik jest na stronie "/frameworks/agentic-ai"
    When użytkownik klika kartę "AAIJ — BabyAGI — Trust Chains"
    Then wyświetlony jest diagram zaufania między agentami
    And diagram pokazuje niezweryfikowane połączenie jako czerwoną strzałkę

  Scenario: Porównanie AAI vs LLM zagrożeń
    Given użytkownik jest na stronie "/matrix/agentic"
    When strona jest załadowana
    Then wyświetlona jest kolumna LLM Top 10 i kolumna Agentic AI Top 10
    And powiązania między zagrożeniami są oznaczone liniami (np. LLM01 ↔ AgentAI01)
```

### Testy jednostkowe — `AgenticThreatServiceTest.java`

```java
// backend/src/test/java/com/securevision/service/AgenticThreatServiceTest.java
@ExtendWith(MockitoExtension.class)
class AgenticThreatServiceTest {

    @Mock  ThreatRepository threatRepository;
    @InjectMocks  AgenticThreatService service;

    @Test
    void aaikMapsToAgentAi07ExcessiveAutonomy() {
        Threat aaik = threat("AAIK", 13);
        aaik.setOwaspRefs(List.of("AgentAI07"));
        when(threatRepository.findByCardId("AAIK")).thenReturn(Optional.of(aaik));

        Threat result = service.getCardById("AAIK");

        assertThat(result.getOwaspRefs()).contains("AgentAI07");
    }

    @Test
    void aaiCardsSuite_hasExactly13Cards() {
        when(threatRepository.findBySuitCode("AAI")).thenReturn(buildAaiCards(13));

        List<Threat> result = service.getCardsBySuit("AAI");

        assertThat(result).hasSize(13);
    }

    @Test
    void aaijMapsToUnvalidatedTrustChains_AgentAi10() {
        Threat aaij = threat("AAIJ", 11);
        aaij.setOwaspRefs(List.of("AgentAI10"));
        when(threatRepository.findByCardId("AAIJ")).thenReturn(Optional.of(aaij));

        assertThat(service.getCardById("AAIJ").getOwaspRefs()).contains("AgentAI10");
    }

    @Test
    void aai4MapsToResourceExhaustionCategory() {
        Threat aai4 = threat("AAI4", 4);
        aai4.setCategories(List.of("resource-exhaustion", "autonomy"));
        when(threatRepository.findByCardId("AAI4")).thenReturn(Optional.of(aai4));

        assertThat(service.getCardById("AAI4").getCategories()).contains("resource-exhaustion");
    }
}
```

### Test integracyjny — `AgenticThreatControllerIT.java`

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@Sql("/sql/agentic-threats-seed.sql")
class AgenticThreatControllerIT {

    @Container
    static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void getAaiCards_returns13Cards() {
        given().when().get("/api/v1/threats?suit=AAI")
            .then().statusCode(200).body("content", hasSize(13));
    }

    @Test
    void aaik_hasExcessiveAutonomyRef() {
        given().when().get("/api/v1/threats/AAIK")
            .then().statusCode(200)
            .body("owaspRefs", hasItem("AgentAI07"));
    }

    @Test
    void aaik_polishDescription_containsHumanApprovalKeyword() {
        given().header("Accept-Language", "pl")
            .when().get("/api/v1/threats/AAIK")
            .then().statusCode(200)
            .body("descriptionPl", containsString("zabezpieczeń transakcyjnych"));
    }
}
```

### Test E2E — `us14-agentic-ai.spec.ts`

```typescript
// e2e/us14-agentic-ai.spec.ts
import { test, expect } from '@playwright/test'

test('US-14: strona Agentic AI wyświetla 13 kart AAI', async ({ page }) => {
  await page.goto('/frameworks/agentic-ai')
  await expect(page.locator('[data-testid="threat-card"]')).toHaveCount(13)
})

test('US-14: karta AAIK ma odwołanie AgentAI07', async ({ page }) => {
  await page.goto('/frameworks/agentic-ai')
  await page.click('[data-card-id="AAIK"]')
  await expect(page.locator('[data-owasp-ref="AgentAI07"]')).toBeVisible()
})

test('US-14: macierz porównawcza LLM vs Agentic AI jest dostępna', async ({ page }) => {
  await page.goto('/matrix/agentic')
  await expect(page.locator('[data-testid="matrix-row"]')).toHaveCount(10)
})
```

---

## US-15: Modelowanie zagrożeń metodą STRIDE — karty EoP (Microsoft Elevation of Privilege)

**Źródło YAML:** `STRIDE__eop-cards-5.0-en.yaml`, talie `SP, TA, RE, ID, DS, EP`

### Mapowanie kart EoP → OWASP i STRIDE

| Talia | Kluczowa karta | Polskie tłumaczenie | OWASP / STRIDE |
|---|---|---|---|
| SP — Spoofing | SPK (K) | **System jest dostarczany z domyślnym hasłem administratora i nie wymusza jego zmiany.** | A07:2021 Identification and Authentication Failures — STRIDE-S |
| SP | SPQ | **Atakujący może atakować sposób aktualizowania lub odzyskiwania danych uwierzytelniających (odzyskiwanie konta nie wymaga ujawnienia starego hasła).** | A07:2021 — STRIDE-S |
| TA — Tampering | TAK (K) | **Atakujący może załadować kod do twojego procesu przez punkt rozszerzeń.** | A08:2021 Software and Data Integrity Failures — STRIDE-T |
| TA | TAQ | **Atakujący może zmieniać parametry przez granicę zaufania po walidacji (np. ukryte pola HTML, wskaźniki do krytycznej pamięci).** | A03:2021 Injection — STRIDE-T |
| RE — Repudiation | REK (K) | **System nie posiada żadnych dzienników zdarzeń.** | A09:2021 Security Logging and Monitoring Failures — STRIDE-R |
| RE | REJ | **Atakujący może edytować dzienniki i nie ma sposobu na wykrycie tego (brak opcji heartbeat w systemie logowania).** | A09:2021 — STRIDE-R |
| ID — Information Disclosure | IDK (K) | **Atakujący może odczytywać informacje sieciowe, ponieważ nie stosuje się żadnej kryptografii.** | A02:2021 Cryptographic Failures — STRIDE-I |
| ID | IDQ | **Atakujący może odczytać cały kanał komunikacyjny, ponieważ nie jest zaszyfrowany (np. HTTP, SMTP).** | A02:2021 — STRIDE-I |
| DS — Denial of Service | DSK (K) | **Atakujący może wzmocnić atak DoS przez ten komponent z amplifikacją rzędu 100:1.** | Brak odpowiednika OWASP Web Top 10 (aspekt operacyjny) — STRIDE-D |
| DS | DSQ | **Atakujący może wzmocnić atak DoS z amplifikacją rzędu 10:1.** | STRIDE-D |
| EP — Elevation of Privilege | EPK (K) | **Atakujący może wstrzyknąć polecenie, które system uruchomi z wyższymi uprawnieniami.** | A01:2021 Broken Access Control + A03:2021 Injection — STRIDE-E |
| EP | EPJ | **Atakujący może odbijać dane wejściowe z powrotem do użytkownika (Cross-Site Scripting).** | A03:2021 Injection (XSS) — STRIDE-E |
| EP | EPQ | **Aplikacja zawiera treści generowane przez użytkownika na stronie, możliwie z zawartością losowych URL.** | A08:2021 / A03:2021 — STRIDE-E |

### User Story US-15

```
JAKO:   architekt systemów / team lead / uczestnik warsztatów z threat modelingu
CHCĘ:   przeglądać i używać kart STRIDE EoP (Elevation of Privilege) jako narzędzia
        do modelowania zagrożeń w trybie interaktywnym
PO TO:  żeby przeprowadzać sesje threat modelingu dla własnych systemów,
        mapować zagrożenia do OWASP Web Top 10 i dokumentować ryzyko
```

### Kryteria akceptacji (Gherkin)

```gherkin
Feature: US-15 Modelowanie zagrożeń STRIDE (karty EoP)

  Scenario: Strona STRIDE wyświetla 6 talii z kartami
    Given użytkownik jest na stronie "/frameworks/stride"
    When strona jest załadowana
    Then widocznych jest 6 sekcji: Spoofing, Tampering, Repudiation,
         Information Disclosure, Denial of Service, Elevation of Privilege
    And każda sekcja zawiera 13 kart

  Scenario: Karta EPK — wstrzykiwanie poleceń z eskalacją uprawnień
    Given użytkownik otwiera kartę "EPK"
    Then tytuł brzmi "Elevation of Privilege — Wstrzykiwanie poleceń"
    And opis po polsku zawiera "wstrzyknąć polecenie... wyższymi uprawnieniami"
    And wyświetlone są powiązania: "A01:2021" i "A03:2021"
    And zakładka "Przykłady kodu" zawiera Java Spring Boot — błędna i poprawna walidacja wejść

  Scenario: Karta REK — brak logowania — powiązanie z OWASP A09
    Given użytkownik otwiera kartę "REK"
    Then opis po polsku brzmi "System nie posiada żadnych dzienników"
    And wyświetlone jest odwołanie "A09:2021 Security Logging and Monitoring Failures"

  Scenario: Widok heatmapy STRIDE dla SecureVision
    Given użytkownik jest na stronie "/stride-heatmap"
    When strona jest załadowana
    Then wyświetlona jest heatmapa 6×N (S, T, R, I, D, E × komponenty systemu)
    And komórki z wysokim ryzykiem są oznaczone kolorem czerwonym

  Scenario: Filtrowanie kart EoP według kategorii STRIDE
    Given użytkownik jest na stronie "/frameworks/stride"
    When użytkownik klika filtr "Tampering"
    Then wyświetlane są tylko karty TA2 do TAA
    And pasek boczny pokazuje mapowanie: "Tampering → A08:2021"
```

### Testy jednostkowe — `StrideThreatServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class StrideThreatServiceTest {

    @Mock  ThreatRepository threatRepository;
    @InjectMocks  StrideThreatService service;

    @Test
    void allSixStrideCategories_haveThirteenCardsEach() {
        for (String cat : List.of("SP", "TA", "RE", "ID", "DS", "EP")) {
            when(threatRepository.findBySuitCode(cat)).thenReturn(buildCards(cat, 13));
        }
        Map<String, List<Threat>> result = service.getAllStrideCategories();
        assertThat(result).hasSize(6);
        result.values().forEach(cards -> assertThat(cards).hasSize(13));
    }

    @Test
    void epkIsMappedToA01AndA03() {
        Threat epk = threat("EPK", 13);
        epk.setOwaspRefs(List.of("A01:2021", "A03:2021"));
        when(threatRepository.findByCardId("EPK")).thenReturn(Optional.of(epk));

        assertThat(service.getCardById("EPK").getOwaspRefs())
            .containsExactlyInAnyOrder("A01:2021", "A03:2021");
    }

    @Test
    void rekIsMappedToA09() {
        Threat rek = threat("REK", 13);
        rek.setOwaspRefs(List.of("A09:2021"));
        when(threatRepository.findByCardId("REK")).thenReturn(Optional.of(rek));

        assertThat(service.getCardById("REK").getOwaspRefs()).containsOnly("A09:2021");
    }

    @Test
    void buildStrideHeatmap_returnsNonEmptyMatrix() {
        when(threatRepository.findAll()).thenReturn(buildAllStrideThreats());

        StrideHeatmap heatmap = service.buildHeatmap(List.of("Nginx", "SpringBoot", "PostgreSQL"));

        assertThat(heatmap.getRows()).hasSize(6);
        assertThat(heatmap.getRows()).allMatch(row -> !row.getCells().isEmpty());
    }
}
```

### Test integracyjny — `StrideThreatControllerIT.java`

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@Sql("/sql/stride-threats-seed.sql")
class StrideThreatControllerIT {

    @Container
    static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void getStrideCategories_returns6Categories() {
        given().when().get("/api/v1/threats/stride/categories")
            .then().statusCode(200)
            .body("$", hasSize(6))
            .body("name", hasItems("Spoofing", "Tampering", "Repudiation",
                                   "Information Disclosure", "Denial of Service",
                                   "Elevation of Privilege"));
    }

    @Test
    void getTaCards_returns13TamperingCards() {
        given().when().get("/api/v1/threats?suit=TA")
            .then().statusCode(200).body("content", hasSize(13));
    }

    @Test
    void getEpkCard_hasA01AndA03Refs() {
        given().when().get("/api/v1/threats/EPK")
            .then().statusCode(200)
            .body("owaspRefs", hasItems("A01:2021", "A03:2021"));
    }

    @Test
    void getStrideHeatmap_returnsMatrix() {
        given().when().get("/api/v1/stride-heatmap")
            .then().statusCode(200)
            .body("rows", hasSize(6));
    }
}
```

### Test komponentu — `StrideHeatmap.test.tsx`

```typescript
// frontend/src/components/__tests__/StrideHeatmap.test.tsx
import { render, screen } from '@testing-library/react'
import { StrideHeatmap } from '../StrideHeatmap'

const mockData = {
  rows: [
    { category: 'Spoofing', cells: [{ component: 'Nginx', risk: 'HIGH' }] },
    { category: 'Tampering', cells: [{ component: 'Nginx', risk: 'MEDIUM' }] },
    { category: 'Repudiation', cells: [{ component: 'Nginx', risk: 'LOW' }] },
    { category: 'Information Disclosure', cells: [{ component: 'Nginx', risk: 'HIGH' }] },
    { category: 'Denial of Service', cells: [{ component: 'Nginx', risk: 'HIGH' }] },
    { category: 'Elevation of Privilege', cells: [{ component: 'Nginx', risk: 'CRITICAL' }] },
  ]
}

it('renders 6 STRIDE category rows', () => {
  render(<StrideHeatmap data={mockData} />)
  expect(screen.getAllByRole('row')).toHaveLength(7)
})

it('marks HIGH-risk cells with red class', () => {
  render(<StrideHeatmap data={mockData} />)
  const highCells = document.querySelectorAll('.risk-high')
  expect(highCells.length).toBeGreaterThanOrEqualTo(2)
})

it('marks CRITICAL cell with critical class', () => {
  render(<StrideHeatmap data={mockData} />)
  expect(document.querySelector('.risk-critical')).not.toBeNull()
})
```

### Test E2E — `us15-stride.spec.ts`

```typescript
// e2e/us15-stride.spec.ts
import { test, expect } from '@playwright/test'

test('US-15: strona STRIDE ma 6 sekcji po 13 kart każda', async ({ page }) => {
  await page.goto('/frameworks/stride')
  for (const suit of ['SP', 'TA', 'RE', 'ID', 'DS', 'EP']) {
    await expect(page.locator(`[data-suit="${suit}"] [data-testid="threat-card"]`))
      .toHaveCount(13)
  }
})

test('US-15: karta EPK ma odwołania do A01 i A03', async ({ page }) => {
  await page.goto('/frameworks/stride')
  await page.click('[data-card-id="EPK"]')
  await expect(page.locator('[data-owasp-ref="A01:2021"]')).toBeVisible()
  await expect(page.locator('[data-owasp-ref="A03:2021"]')).toBeVisible()
})

test('US-15: heatmapa STRIDE wyświetla 6 wierszy', async ({ page }) => {
  await page.goto('/stride-heatmap')
  await expect(page.locator('[data-testid="heatmap-row"]')).toHaveCount(6)
})
```

---

## US-16: Ryzyka bezpieczeństwa systemów ML — karty Elevation of MLSec

**Źródło YAML:** `RISKS__elevation-of-mlsec-cards-1.0-en.yaml`, talie `EMR, EIR, EOR, EDR`

### Mapowanie kart MLSec → OWASP + MITRE ATLAS

| Talia | ID karty | Polskie tłumaczenie zagrożenia | OWASP LLM / MITRE ATLAS |
|---|---|---|---|
| EMR — Model Risk | EMRK (K) | **Modele ML są ponownie używane w sytuacjach transferu do przestrzeni problemowej, do której nie są przeznaczone — ryzyko błędów systemu.** | LLM03:2025 Supply Chain; MITRE ATLAS T0010 |
| EMR | EMRQ | **Transfer modelu prowadzi do możliwości, że ponownie używana wersja może być modelem z trojanem lub inaczej uszkodzonym.** | LLM04:2025 Data and Model Poisoning; MITRE ATLAS T0011 |
| EMR | EMRX | **Kradzież wiedzy systemu ML jest możliwa przez bezpośrednią obserwację wejście/wyjście, umożliwiając atakującym inżynierię wsteczną modelu.** | MITRE ATLAS T0010 Model Theft |
| EMR | EMRJ | **Większość algorytmów ML przechowuje reprezentację danych treningowych wewnętrznie. Te dane mogą być wrażliwe i potencjalnie mogą być wyodrębnione z modelu.** | LLM02:2025 Sensitive Information Disclosure |
| EIR — Input Risk | EIRK (K) | **Oszukaj system ML przez złośliwe dane wejściowe, które powodują, że system ML dokonuje fałszywej predykcji lub kategoryzacji.** | MITRE ATLAS T0044 Craft Adversarial Data |
| EIR | EIRQ | **Atakujący manipuluje dużym modelem językowym przez złośliwe dane wejściowe, aby nadpisać instrukcje z promptów systemowych.** | LLM01:2025 Prompt Injection |
| EIR | EIR4 | **Atak gąbkowy (sponge) dostarcza systemowi LLM dane wejściowe, których przetworzenie jest droższe niż normalne — jak atak DoS wyczerpujący budżet obliczeniowy.** | LLM10:2025 Unbounded Consumption |
| EOR — Output Risk | EORK (K) | **Atakujący bezpośrednio manipuluje strumieniem wyjściowym lokując się między systemem ML a jego odbiorcą. Może być trudno wykryć, bo modele są nieprzejrzyste.** | LLM05:2025 Improper Output Handling |
| EOR | EOR10 | **System oparty na LLM może podejmować działania prowadzące do niezamierzonych konsekwencji jeśli przyznano mu nadmierną funkcjonalność, uprawnienia lub autonomię.** | LLM06:2025 Excessive Agency |
| EOR | EOR4 | **Zależność od LLM bez nadzoru może prowadzić do dezinformacji i problemów prawnych. Trudno będzie też wykryć atak na system LLM.** | LLM09:2025 Misinformation |
| EDR — Dataset Risk | EDRK (K) | **Atakujący celowo manipuluje danymi, aby zakłócić, wprowadzić stronniczość, kontrolować lub wpłynąć na trening ML. W internecie wiele danych jest już "domyślnie" zatrutych.** | LLM04:2025 Data and Model Poisoning; MITRE ATLAS T0014 |
| EDR | EDRQ | **Wrażliwe i poufne dane używane do trenowania ML mogą zostać ujawnione przez ataki ekstrakcji (extraction attacks).** | LLM02:2025 Sensitive Information Disclosure |

### User Story US-16

```
JAKO:   data scientist / ML engineer / architekt AI bezpieczeństwa
CHCĘ:   przeglądać katalog ryzyk bezpieczeństwa systemów ML (Model, Input, Output,
        Dataset Risk) na podstawie kart Elevation of MLSec
PO TO:  żeby zrozumieć zagrożenia specyficzne dla ML (nie tylko LLM) — od kradzieży
        modeli, przez zatruwanie danych, po manipulację wyjściami — i znać
        odwołania do OWASP LLM Top 10 oraz MITRE ATLAS
```

### Kryteria akceptacji (Gherkin)

```gherkin
Feature: US-16 Ryzyka bezpieczeństwa ML (Elevation of MLSec)

  Scenario: Strona ML Security wyświetla 4 kategorie ryzyk
    Given użytkownik jest na stronie "/frameworks/ml-security"
    When strona jest załadowana
    Then widoczne są 4 sekcje: "Ryzyko modelu", "Ryzyko danych wejściowych",
         "Ryzyko danych wyjściowych", "Ryzyko zbiorów danych"
    And każda sekcja zawiera 13 kart

  Scenario: Karta EDRK — data poisoning (krytyczna)
    Given użytkownik otwiera kartę "EDRK"
    Then tytuł zawiera "Zatrucie danych treningowych"
    And opis po polsku zawiera "wiele danych jest już domyślnie zatrutych"
    And wyświetlone są odwołania "LLM04:2025" i "MITRE ATLAS T0014"
    And zakładka "Przykłady kodu" zawiera Python — wykrywanie anomalii w zbiorze danych

  Scenario: Karta EMRQ — Trojanized model
    Given użytkownik otwiera kartę "EMRQ"
    Then opis po polsku zawiera "modelem z trojanem"
    And wyświetlone jest odwołanie "LLM04:2025 Data and Model Poisoning"

  Scenario: Filtrowanie po MITRE ATLAS zwraca karty EMR i EIR
    Given użytkownik jest na stronie "/frameworks/ml-security"
    When użytkownik wybiera filtr "MITRE ATLAS"
    Then wyświetlane są karty EMRX, EMRQ, EIRK i EDRK
    And każda wyświetlona karta ma technikę MITRE ATLAS
```

### Testy jednostkowe — `MlSecThreatServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class MlSecThreatServiceTest {

    @Mock  ThreatRepository threatRepository;
    @InjectMocks  MlSecThreatService service;

    @Test
    void edrkMapsToLlm04AndMitreAtlasT0014() {
        Threat edrk = threat("EDRK", 13);
        edrk.setOwaspRefs(List.of("LLM04:2025"));
        edrk.setMitreRefs(List.of("MITRE ATLAS T0014"));
        when(threatRepository.findByCardId("EDRK")).thenReturn(Optional.of(edrk));

        Threat result = service.getCardById("EDRK");
        assertThat(result.getOwaspRefs()).contains("LLM04:2025");
        assertThat(result.getMitreRefs()).contains("MITRE ATLAS T0014");
    }

    @Test
    void emrxMapsToModelTheft_MitreAtlasT0010() {
        Threat emrx = threat("EMRX", 10);
        emrx.setMitreRefs(List.of("MITRE ATLAS T0010"));
        when(threatRepository.findByCardId("EMRX")).thenReturn(Optional.of(emrx));

        assertThat(service.getCardById("EMRX").getMitreRefs())
            .contains("MITRE ATLAS T0010");
    }

    @Test
    void fourMlSecCategories_haveThirteenCardsEach() {
        for (String cat : List.of("EMR", "EIR", "EOR", "EDR")) {
            when(threatRepository.findBySuitCode(cat)).thenReturn(buildCards(cat, 13));
        }
        Map<String, List<Threat>> result = service.getAllMlSecCategories();
        assertThat(result).hasSize(4);
        result.values().forEach(cards -> assertThat(cards).hasSize(13));
    }

    @Test
    void filterByMitreAtlas_returnsCardsWithMitreRefs() {
        List<Threat> withMitre = List.of(
            threatWithMitreRef("EMRX", "MITRE ATLAS T0010"),
            threatWithMitreRef("EMRQ", "MITRE ATLAS T0011"),
            threatWithMitreRef("EIRK", "MITRE ATLAS T0044"),
            threatWithMitreRef("EDRK", "MITRE ATLAS T0014")
        );
        when(threatRepository.findByMitreRefNotNull()).thenReturn(withMitre);

        List<Threat> result = service.filterByMitreAtlas();

        assertThat(result).hasSize(4);
    }
}
```

### Test integracyjny — `MlSecControllerIT.java`

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@Sql("/sql/mlsec-threats-seed.sql")
class MlSecControllerIT {

    @Container
    static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void getMlSecCategories_returnsFour() {
        given().when().get("/api/v1/threats/mlsec/categories")
            .then().statusCode(200).body("$", hasSize(4));
    }

    @Test
    void getEdrk_hasLlm04AndMitreT0014() {
        given().when().get("/api/v1/threats/EDRK")
            .then().statusCode(200)
            .body("owaspRefs", hasItem("LLM04:2025"))
            .body("mitreRefs", hasItem("MITRE ATLAS T0014"));
    }

    @Test
    void getEdrk_polishDescription_containsPoisoningKeyword() {
        given().header("Accept-Language", "pl")
            .when().get("/api/v1/threats/EDRK")
            .then().statusCode(200)
            .body("descriptionPl", containsString("zatrutych"));
    }
}
```

### Test E2E — `us16-ml-security.spec.ts`

```typescript
// e2e/us16-ml-security.spec.ts
import { test, expect } from '@playwright/test'

test('US-16: strona ML Security wyświetla 4 kategorie', async ({ page }) => {
  await page.goto('/frameworks/ml-security')
  await expect(page.locator('[data-testid="ml-category"]')).toHaveCount(4)
})

test('US-16: karta EDRK ma MITRE ATLAS T0014 i LLM04', async ({ page }) => {
  await page.goto('/frameworks/ml-security')
  await page.click('[data-card-id="EDRK"]')
  await expect(page.locator('[data-mitre-ref="MITRE ATLAS T0014"]')).toBeVisible()
  await expect(page.locator('[data-owasp-ref="LLM04:2025"]')).toBeVisible()
})
```

---

## US-17: Bezpieczeństwo aplikacji mobilnych — karty OWASP MAS (MASVS)

**Źródło YAML:** `mobileapp-cards-1.1-en.yaml`, talie `PC, AA, NS, RS, CRM, CM`

### Mapowanie kluczowych kart Mobile → OWASP MASVS

| Talia | ID karty | Polskie tłumaczenie | OWASP MASVS |
|---|---|---|---|
| NS — Network & Storage | NSK (K) | **Taher może przechwycić, wyodrębnić lub zmodyfikować wrażliwe dane w spoczynku lub w tranzycie przez wpływanie na metody przechowywania lub transmisji.** | MASVS-NETWORK-1, MASVS-STORAGE-1 |
| NS | NSQ | **Ahmed może odczytywać i modyfikować dane w tranzycie, ponieważ komunikacja jest przesyłana przez niezaszyfrowany kanał.** | MASVS-NETWORK-1; A02:2021 |
| NS | NSX | **Maarten może skompromitować komunikację między aplikacją a zewnętrznymi usługami, bo aplikacja nie weryfikuje certyfikatów TLS i łańcuchów, ufa niezaufanym źródłom lub ignoruje błędy weryfikacji TLS.** | MASVS-NETWORK-2 |
| AA — Auth & Authz | AAK (K) | **Aatif może wpływać na kontrolki uwierzytelniania lub je zmieniać i przez to je obchodzić.** | MASVS-AUTH-2; A07:2021 |
| AA | AAQ | **Riotaro może wstrzyknąć i uruchomić polecenie, które aplikacja wykona z wyższymi uprawnieniami bez uwierzytelnienia.** | MASVS-AUTH-1; A01:2021 |
| RS — Resilience | RSK (K) | **Sherif może wpływać na kontrole przed inżynierią wsteczną i ochronę środowiska uruchomieniowego i przez to je obejść.** | MASVS-RESILIENCE-3, MASVS-RESILIENCE-4 |
| RS | RSX | **Juan może ominąć wykrywanie jailbreaka/roota i wykonywać funkcje administracyjne w celu obejścia kontroli integralności i dostępu.** | MASVS-RESILIENCE-4 |
| CRM — Cryptography | CRMK (K) | **Tarik może wpływać na operacje kryptograficzne i przez to je obchodzić.** | MASVS-CRYPTO-1; A02:2021 |
| CRM | CRM6 | **Kouti może wyodrębnić wrażliwe dane, bo klucz kryptograficzny jest zakodowany na stałe lub przechowywany niepewnie.** | MASVS-CRYPTO-1; A02:2021 |
| PC — Platform & Code | PCK (K) | **Grant może zmodyfikować lub ujawnić dane przez wpływanie na mosty JavaScript, rozszerzenia lub komunikację między procesami.** | MASVS-CODE-4 |
| CM — Cornucopia Mobile | CMK (K) | **Ruben może używać aplikacji bez modyfikacji do rozprzestrzeniania złośliwego kodu, bo metody transferu i przechowywania nie wykonują właściwej sanityzacji.** | MASVS-CODE-2; A08:2021 |
| CM | CMX | **Carlos może używać usług powiadomień push aplikacji do uruchamiania kampanii phishingowych, bo powiadomienia nie są sanityzowane i walidowane.** | MASVS-PLATFORM; A03:2021 |

### User Story US-17

```
JAKO:   programista aplikacji mobilnych / tester bezpieczeństwa mobile
CHCĘ:   przeglądać zagrożenia bezpieczeństwa aplikacji mobilnych opartych
        na kartach OWASP Cornucopia Mobile App v1.1 i standardzie OWASP MASVS
PO TO:  żeby zrozumieć różnice między bezpieczeństwem web a mobile
        (ochrona klucza kryptograficznego, wykrywanie jailbreaka, bezpieczna IPC)
        i mapować zagrożenia do kontrolek MASVS
```

### Kryteria akceptacji (Gherkin)

```gherkin
Feature: US-17 Bezpieczeństwo aplikacji mobilnych (OWASP MASVS)

  Scenario: Strona Mobile Security wyświetla 6 talii
    Given użytkownik jest na stronie "/frameworks/mobile-security"
    When strona jest załadowana
    Then widoczne są talie: "Platform & Code", "Authentication & Authorization",
         "Network & Storage", "Resilience", "Cryptography", "Cornucopia Mobile"
    And każda talia zawiera 13 kart

  Scenario: Karta NSX — TLS verification
    Given użytkownik otwiera kartę "NSX"
    Then opis po polsku zawiera "weryfikuje certyfikatów TLS"
    And wyświetlone jest odwołanie "MASVS-NETWORK-2"
    And zakładka "Przykłady kodu" zawiera kod Java (Android OkHttp) — certificate pinning

  Scenario: Karta RSX — Jailbreak/root detection
    Given użytkownik otwiera kartę "RSX"
    Then opis po polsku zawiera "wykrywanie jailbreaka/roota"
    And wyświetlone jest odwołanie "MASVS-RESILIENCE-4"
    And zakładka "Przykłady kodu" zawiera kod Kotlin/Swift dla sprawdzania integralności urządzenia

  Scenario: Karta CRM6 — hardcoded cryptographic key
    Given użytkownik otwiera kartę "CRM6"
    Then opis po polsku zawiera "zakodowany na stałe" i "niepewnie"
    And wyświetlone są odwołania "MASVS-CRYPTO-1" i "A02:2021"

  Scenario: Porównanie MASVS vs OWASP Web — tabela różnic
    Given użytkownik jest na stronie "/matrix/mobile-vs-web"
    When strona jest załadowana
    Then wyświetlona jest tabela porównania kategorii MASVS i OWASP Web Top 10
```

### Testy jednostkowe — `MobileSecThreatServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class MobileSecThreatServiceTest {

    @Mock  ThreatRepository threatRepository;
    @InjectMocks  MobileSecThreatService service;

    @Test
    void nsxMapsToMasvs_NETWORK_2() {
        Threat nsx = threat("NSX", 10);
        nsx.setOwaspRefs(List.of("MASVS-NETWORK-2"));
        when(threatRepository.findByCardId("NSX")).thenReturn(Optional.of(nsx));

        assertThat(service.getCardById("NSX").getOwaspRefs())
            .containsOnly("MASVS-NETWORK-2");
    }

    @Test
    void rsxMapsToMasvs_RESILIENCE_4() {
        Threat rsx = threat("RSX", 10);
        rsx.setOwaspRefs(List.of("MASVS-RESILIENCE-4"));
        when(threatRepository.findByCardId("RSX")).thenReturn(Optional.of(rsx));

        assertThat(service.getCardById("RSX").getOwaspRefs())
            .contains("MASVS-RESILIENCE-4");
    }

    @Test
    void crm6MapsToMavsv_CRYPTO_1_andA02() {
        Threat crm6 = threat("CRM6", 6);
        crm6.setOwaspRefs(List.of("MASVS-CRYPTO-1", "A02:2021"));
        when(threatRepository.findByCardId("CRM6")).thenReturn(Optional.of(crm6));

        Threat result = service.getCardById("CRM6");
        assertThat(result.getOwaspRefs())
            .containsExactlyInAnyOrder("MASVS-CRYPTO-1", "A02:2021");
    }

    @Test
    void sixMobileSuits_haveThirteenCardsEach() {
        for (String suit : List.of("PC", "AA", "NS", "RS", "CRM", "CM")) {
            when(threatRepository.findBySuitCode(suit)).thenReturn(buildCards(suit, 13));
        }
        Map<String, List<Threat>> result = service.getAllMobileSuits();
        assertThat(result).hasSize(6);
        result.values().forEach(cards -> assertThat(cards).hasSize(13));
    }
}
```

### Test integracyjny — `MobileSecControllerIT.java`

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@Sql("/sql/mobile-threats-seed.sql")
class MobileSecControllerIT {

    @Container
    static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void getNsxCard_hasMavsNetworkRef() {
        given().when().get("/api/v1/threats/NSX")
            .then().statusCode(200)
            .body("owaspRefs", hasItem("MASVS-NETWORK-2"));
    }

    @Test
    void getMobileCards_nsCategory_returns13() {
        given().when().get("/api/v1/threats?suit=NS")
            .then().statusCode(200).body("content", hasSize(13));
    }

    @Test
    void getCrm6_polishDescription_containsHardcodedKeyword() {
        given().header("Accept-Language", "pl")
            .when().get("/api/v1/threats/CRM6")
            .then().statusCode(200)
            .body("descriptionPl", containsString("zakodowany na stałe"));
    }
}
```

### Test E2E — `us17-mobile-security.spec.ts`

```typescript
// e2e/us17-mobile-security.spec.ts
import { test, expect } from '@playwright/test'

test('US-17: strona Mobile Security ma 6 talii', async ({ page }) => {
  await page.goto('/frameworks/mobile-security')
  await expect(page.locator('[data-testid="mobile-suit"]')).toHaveCount(6)
})

test('US-17: karta NSX ma MASVS-NETWORK-2', async ({ page }) => {
  await page.goto('/frameworks/mobile-security')
  await page.click('[data-card-id="NSX"]')
  await expect(page.locator('[data-owasp-ref="MASVS-NETWORK-2"]')).toBeVisible()
})

test('US-17: karta CRM6 ma MASVS-CRYPTO-1 i A02:2021', async ({ page }) => {
  await page.goto('/frameworks/mobile-security')
  await page.click('[data-card-id="CRM6"]')
  await expect(page.locator('[data-owasp-ref="MASVS-CRYPTO-1"]')).toBeVisible()
  await expect(page.locator('[data-owasp-ref="A02:2021"]')).toBeVisible()
})
```

---

## US-18: Bezpieczeństwo DevOps i łańcucha dostaw — karty DVO + BOT

**Źródło YAML:** `__LLM_AI___companion-cards-1.0-en.yaml`, talie `DVO` (DevOps) i `BOT` (Automated Threats)

### Mapowanie kart DVO → OWASP Top 10 CI/CD Security Risks

| ID karty | Polskie tłumaczenie | OWASP CI/CD / Web Top 10 |
|---|---|---|
| DVOK (K) | **Timo może skompromitować oprogramowanie, środowiska programistyczne lub narzędzia DevOps przez wstrzyknięcie złośliwego kodu przez zewnętrzne zależności lub skompromitowane dane uwierzytelniające programistów.** | CICD-SEC-03 Dependency Chain Abuse; A06:2021 |
| DVOQ (Q) | **Seba może uzyskać dostęp do repozytorium kodu, plików dziennika, historii poleceń, pipeline'ów lub innych miejsc, by zdobyć sekrety lub inne wrażliwe informacje.** | CICD-SEC-06 Insufficient Secrets Management; A05:2021 |
| DVOJ (J) | **Pravir może wykorzystywać podatności w ekosystemie aplikacji lub deweloperskim, w tym w repozytoriach i infrastrukturze DevOps, z powodu nieaktualnych lub źle utrzymanych zależności.** | A06:2021 Vulnerable and Outdated Components; CICD-SEC-03 |
| DVOX (10) | **Patricia może wykorzystywać przestarzałe dane uwierzytelniające DevOps, tożsamości, usługi lub API, a także nadmierne uprawnienia, do obejścia kontroli dostępu.** | CICD-SEC-05 Insufficient Access Control to SCM |
| DVO9 | **Nariman może kontrolować lub wpływać na wykonanie pipeline'u przez wstrzyknięcie złośliwych poleceń przez zatrute lub typosquattowane zależności workflow.** | CICD-SEC-09 Improper Artifact Integrity Validation |
| DVO8 | **Maxim może wdrożyć złośliwy lub zmodyfikowany artefakt, bo jego integralność nie jest gwarantowana ani weryfikowana.** | CICD-SEC-09; A08:2021 Software and Data Integrity Failures |
| DVO7 | **John może wdrożyć nieautoryzowane lub złośliwe zmiany do produkcji, bo bramki zatwierdzania, kontrole walidacji lub procesy kontroli zmian są brakujące lub można je obejść.** | CICD-SEC-02 Inadequate Code Review; CICD-SEC-05 |

### Mapowanie kart BOT → OWASP Automated Threats

| ID karty | Polskie tłumaczenie | OWASP OAT (Automated Threats) |
|---|---|---|
| BOTK (K) | **EDVAC może zbierać treści aplikacji i/lub inne dane w celu wykorzystania ich gdzie indziej.** | OAT-011 Scraping |
| BOTQ (Q) | **Manchester Baby może dodawać złośliwe lub wątpliwe informacje do treści, baz danych lub wiadomości użytkowników.** | OAT-019 Account Creation |
| BOTJ (J) | **Zuse Z3 może walidować skradzione zbiorcze dane uwierzytelniające lub dane posiadacza karty (PAN, kod bezpieczeństwa, data ważności).** | OAT-007 Credential Cracking |
| BOTX (10) | **Ferranti Pegasus może wyliczać indywidualne dane uwierzytelniające lub dane karty płatniczej przez próbowanie różnych wartości.** | OAT-012 Carding / OAT-008 Credential Stuffing |

### User Story US-18

```
JAKO:   deweloper / inżynier DevSecOps / team lead
CHCĘ:   przeglądać scenariusze zagrożeń pipeline'ów CI/CD i łańcucha dostaw (DVO)
        oraz zagrożeń automatycznych (BOT) z kartami Cornucopia DVO i BOT
PO TO:  żeby zrozumieć jak chronić procesy budowania, wdrażania i dostarczania
        oprogramowania oraz jak wykrywać i blokować zautomatyzowane ataki boty
```

### Kryteria akceptacji (Gherkin)

```gherkin
Feature: US-18 Bezpieczeństwo DevOps, CI/CD i ataki zautomatyzowane (DVO + BOT)

  Scenario: Strona DevOps Security wyświetla talie DVO i BOT
    Given użytkownik jest na stronie "/frameworks/devops-security"
    When strona jest załadowana
    Then widoczne są sekcje "DevOps" i "Automated Threats"
    And sekcja DVO zawiera 13 kart, sekcja BOT zawiera 13 kart

  Scenario: Karta DVOK — supply chain compromise (krytyczna)
    Given użytkownik otwiera kartę "DVOK"
    Then tytuł zawiera "Timo — Kompromitacja łańcucha dostaw"
    And opis po polsku zawiera "zewnętrzne zależności" i "dane uwierzytelniające programistów"
    And wyświetlone jest odwołanie "CICD-SEC-03" i "A06:2021"
    And zakładka "Przykłady kodu" zawiera konfigurację GitHub Actions z hashami SHA zależności

  Scenario: Karta DVO8 — artifact integrity (A08:2021)
    Given użytkownik otwiera kartę "DVO8"
    Then opis po polsku zawiera "integralność nie jest gwarantowana"
    And wyświetlone są odwołania "CICD-SEC-09" i "A08:2021"

  Scenario: Karta BOTK — scraping (krytyczna)
    Given użytkownik otwiera kartę "BOTK"
    Then opis po polsku zawiera "zbierać treści aplikacji"
    And wyświetlone jest odwołanie "OAT-011 Scraping"
    And sekcja "Mitigacje" zawiera: rate limiting, CAPTCHA, behavioral analytics

  Scenario: Filtrowanie DVO według CICD-SEC pokazuje karty pipeline'u
    Given użytkownik jest na stronie "/frameworks/devops-security"
    When użytkownik wybiera filtr "CICD-SEC"
    Then wyświetlane są karty DVO7, DVO8, DVO9, DVOK i DVOQ
```

### Testy jednostkowe — `DevOpsThreatServiceTest.java`

```java
@ExtendWith(MockitoExtension.class)
class DevOpsThreatServiceTest {

    @Mock  ThreatRepository threatRepository;
    @InjectMocks  DevOpsThreatService service;

    @Test
    void dvokMapsToArtifactIntegrityAndCicdSec03() {
        Threat dvok = threat("DVOK", 13);
        dvok.setOwaspRefs(List.of("CICD-SEC-03", "A06:2021"));
        when(threatRepository.findByCardId("DVOK")).thenReturn(Optional.of(dvok));

        Threat result = service.getCardById("DVOK");
        assertThat(result.getOwaspRefs())
            .containsExactlyInAnyOrder("CICD-SEC-03", "A06:2021");
    }

    @Test
    void dvo8MapsToA08AndCicdSec09() {
        Threat dvo8 = threat("DVO8", 8);
        dvo8.setOwaspRefs(List.of("CICD-SEC-09", "A08:2021"));
        when(threatRepository.findByCardId("DVO8")).thenReturn(Optional.of(dvo8));

        assertThat(service.getCardById("DVO8").getOwaspRefs())
            .containsExactlyInAnyOrder("CICD-SEC-09", "A08:2021");
    }

    @Test
    void botkMapsToOatScraping() {
        Threat botk = threat("BOTK", 13);
        botk.setOwaspRefs(List.of("OAT-011"));
        when(threatRepository.findByCardId("BOTK")).thenReturn(Optional.of(botk));

        assertThat(service.getCardById("BOTK").getOwaspRefs()).containsOnly("OAT-011");
    }

    @Test
    void dvoSuite_hasThirteenCards() {
        when(threatRepository.findBySuitCode("DVO")).thenReturn(buildCards("DVO", 13));
        assertThat(service.getCardsBySuit("DVO")).hasSize(13);
    }

    @Test
    void botSuite_hasThirteenCards() {
        when(threatRepository.findBySuitCode("BOT")).thenReturn(buildCards("BOT", 13));
        assertThat(service.getCardsBySuit("BOT")).hasSize(13);
    }
}
```

### Test integracyjny — `DevOpsThreatControllerIT.java`

```java
@SpringBootTest(webEnvironment = RANDOM_PORT)
@Testcontainers
@Sql("/sql/devops-threats-seed.sql")
class DevOpsThreatControllerIT {

    @Container
    static PostgreSQLContainer<?> pg = new PostgreSQLContainer<>("postgres:16-alpine");

    @Test
    void getDvoCards_returns13() {
        given().when().get("/api/v1/threats?suit=DVO")
            .then().statusCode(200).body("content", hasSize(13));
    }

    @Test
    void getBotCards_returns13() {
        given().when().get("/api/v1/threats?suit=BOT")
            .then().statusCode(200).body("content", hasSize(13));
    }

    @Test
    void getDvok_hasCicdSec03AndA06() {
        given().when().get("/api/v1/threats/DVOK")
            .then().statusCode(200)
            .body("owaspRefs", hasItems("CICD-SEC-03", "A06:2021"));
    }

    @Test
    void getDvok_polishDescription_containsSupplyChainKeyword() {
        given().header("Accept-Language", "pl")
            .when().get("/api/v1/threats/DVOK")
            .then().statusCode(200)
            .body("descriptionPl", containsString("łańcucha dostaw"));
    }

    @Test
    void getBotk_hasOatScrapingRef() {
        given().when().get("/api/v1/threats/BOTK")
            .then().statusCode(200)
            .body("owaspRefs", hasItem("OAT-011"));
    }
}
```

### Test komponentu — `DevOpsThreatList.test.tsx`

```typescript
// frontend/src/components/__tests__/DevOpsThreatList.test.tsx
import { render, screen } from '@testing-library/react'
import { DevOpsThreatList } from '../DevOpsThreatList'

const mockDvoCards = [
  { cardId: 'DVOK', value: 13, owaspRefs: ['CICD-SEC-03', 'A06:2021'],
    descriptionPl: 'Timo kompromituje łańcuch dostaw przez zewnętrzne zależności.' },
  { cardId: 'DVO8', value: 8, owaspRefs: ['CICD-SEC-09', 'A08:2021'],
    descriptionPl: 'Maxim wdraża złośliwy artefakt.' },
]

it('renders DVO cards with OWASP badges', () => {
  render(<DevOpsThreatList cards={mockDvoCards} lang="pl" />)
  expect(screen.getByText('DVOK')).toBeInTheDocument()
  expect(screen.getByText('CICD-SEC-03')).toBeInTheDocument()
  expect(screen.getByText('DVO8')).toBeInTheDocument()
})

it('shows Polish description when lang=pl', () => {
  render(<DevOpsThreatList cards={mockDvoCards} lang="pl" />)
  expect(screen.getByText(/łańcuch dostaw/)).toBeInTheDocument()
})

it('renders critical badge for face cards (value >= 11)', () => {
  render(<DevOpsThreatList cards={mockDvoCards} lang="pl" />)
  const critical = screen.getByTestId('badge-dvok-critical')
  expect(critical).toBeInTheDocument()
})
```

### Test E2E — `us18-devops-security.spec.ts`

```typescript
// e2e/us18-devops-security.spec.ts
import { test, expect } from '@playwright/test'

test('US-18: strona DevOps Security ma sekcje DVO i BOT', async ({ page }) => {
  await page.goto('/frameworks/devops-security')
  await expect(page.locator('[data-suit="DVO"]')).toBeVisible()
  await expect(page.locator('[data-suit="BOT"]')).toBeVisible()
})

test('US-18: karta DVOK ma odwołania CICD-SEC-03 i A06:2021', async ({ page }) => {
  await page.goto('/frameworks/devops-security')
  await page.click('[data-card-id="DVOK"]')
  await expect(page.locator('[data-owasp-ref="CICD-SEC-03"]')).toBeVisible()
  await expect(page.locator('[data-owasp-ref="A06:2021"]')).toBeVisible()
})

test('US-18: karta BOTK ma OAT-011 Scraping', async ({ page }) => {
  await page.goto('/frameworks/devops-security')
  await page.click('[data-card-id="BOTK"]')
  await expect(page.locator('[data-owasp-ref="OAT-011"]')).toBeVisible()
})
```

---

## Zaktualizowane cele pokrycia testami

| Warstwa | Cel | Narzędzie |
|---|---|---|
| Backend service classes | ≥ 80% line coverage | JaCoCo (Maven plugin) |
| Backend controller integration | 100% endpoints tested | Rest Assured + Testcontainers |
| React components | ≥ 75% branch coverage | Vitest + c8 |
| E2E critical paths | 18 user stories × 1+ test | Playwright |
| i18n key parity | 100% — zero missing keys allowed | I18nKeysValidatorTest + i18n.keys.test.ts |
| i18n locale coverage | Both `pl` and `en` tested for every API endpoint | LocalizationControllerIT |
| Total test count (minimum) | **195 tests** | — |

### Podsumowanie nowych plików testowych (US-12 … US-18)

| Plik testowy | Warstwa | Co pokrywa |
|---|---|---|
| `FrontendThreatServiceTest.java` | Unit | Filtrowanie kart FRE, mapowanie OWASP Client-Side |
| `FrontendThreatControllerIT.java` | Integration | API kart FRE; `Accept-Language`; filtr A07 |
| `FrontendThreatCard.test.tsx` | Component | Renderowanie karty FRE, język pl/en, klik |
| `us12-frontend-threats.spec.ts` | E2E | 3 scenariusze: lista, szczegóły FRE4, filtr A07 |
| `LlmThreatServiceTest.java` | Unit | Mapowanie LLMX→LLM01+LLM07, macierz LLM Top 10 |
| `LlmThreatControllerIT.java` | Integration | API kart LLM, macierz, wyszukiwanie prompt injection |
| `LlmThreatMatrix.test.tsx` | Component | Renderowanie macierzy LLM Top 10 |
| `us13-llm-threats.spec.ts` | E2E | 4 scenariusze: lista, LLMX, macierz, wyszukiwanie |
| `AgenticThreatServiceTest.java` | Unit | AAIK→AgentAI07, AAIJ→AgentAI10, filtrowanie |
| `AgenticThreatControllerIT.java` | Integration | API kart AAI, opis PL |
| `us14-agentic-ai.spec.ts` | E2E | 3 scenariusze: lista, AAIK, macierz |
| `StrideThreatServiceTest.java` | Unit | 6 kategorii STRIDE, EPK→A01+A03, heatmapa |
| `StrideThreatControllerIT.java` | Integration | API 6 kategorii, EPK, REK, heatmapa |
| `StrideHeatmap.test.tsx` | Component | Renderowanie heatmapy 6×N, kolory ryzyka |
| `us15-stride.spec.ts` | E2E | 3 scenariusze: STRIDE 6 suit, EPK, heatmapa |
| `MlSecThreatServiceTest.java` | Unit | EDRK→LLM04+ATLAS T0014, EMRX→T0010, 4 kategorie |
| `MlSecControllerIT.java` | Integration | API 4 kategorii ML, EDRK, opis PL |
| `us16-ml-security.spec.ts` | E2E | 2 scenariusze: 4 kategorie, EDRK |
| `MobileSecThreatServiceTest.java` | Unit | NSX→MASVS-NETWORK-2, RSX→RESILIENCE-4, CRM6 |
| `MobileSecControllerIT.java` | Integration | API mobile suits, NSX, CRM6 |
| `us17-mobile-security.spec.ts` | E2E | 3 scenariusze: 6 talii, NSX, CRM6 |
| `DevOpsThreatServiceTest.java` | Unit | DVOK→CICD-SEC-03, DVO8→A08, BOTK→OAT-011 |
| `DevOpsThreatControllerIT.java` | Integration | API DVO+BOT, DVOK, BOTK, opis PL |
| `DevOpsThreatList.test.tsx` | Component | Lista DVO, badge krytyczne, język pl |
| `us18-devops-security.spec.ts` | E2E | 3 scenariusze: DVO+BOT, DVOK, BOTK |
