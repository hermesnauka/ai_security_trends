# GoSentry 2026 — User Stories & TDD Test Plan

**Version:** 1.0
**Date:** 2026-07-07
**Stack:** Go 1.23 + chi + sqlc + pgx (backend) · React 18 + TypeScript + Vite (frontend)
**Test frameworks:** Go `testing` + `testify` + `httptest` · Vitest + React Testing Library · Playwright

---

## Konwencje testowe

### Backend (Go — `testing` + `testify`)
```go
func TestThreatService_FilterBySeverity(t *testing.T) {
	svc := service.NewThreatService(testStore(t))
	got, err := svc.List(context.Background(), service.ThreatFilter{Severity: ptr(domain.SeverityCritical)})
	require.NoError(t, err)
	assert.NotEmpty(t, got)
	for _, th := range got {
		assert.Equal(t, domain.SeverityCritical, th.Severity)
	}
}
```

### Backend HTTP (`httptest`)
```go
func TestThreatHandler_List_Returns200(t *testing.T) {
	srv := httptest.NewServer(router.New(testDeps(t)))
	defer srv.Close()
	resp, err := http.Get(srv.URL + "/api/v1/threats?framework=OWASP_LLM")
	require.NoError(t, err)
	assert.Equal(t, http.StatusOK, resp.StatusCode)
}
```

### Frontend (Vitest + React Testing Library)
```typescript
describe('ComponentName', () => {
  it('opis testu', async () => {
    render(<ComponentName />)
    expect(await screen.findByText('...'))
  })
})
```

### E2E (Playwright)
```typescript
test('opis testu', async ({ page }) => {
  await page.goto('/route')
  await expect(page.getByTestId('...')).toBeVisible()
})
```

---

## Zasada TDD stosowana w tym projekcie

```
RED       — napisz test opisujący oczekiwane zachowanie, PRZED napisaniem kodu produkcyjnego
GREEN     — napisz minimalny kod, który sprawia, że test przechodzi
REFACTOR  — poprawiaj kod bez łamania testów
```

Dla każdej user story test jest tworzony jako pierwszy plik w PR; kod produkcyjny w tym samym PR bez odpowiadającego, wcześniej nieprzechodzącego testu jest odrzucany w code review (patrz `requirements.md` NFR-04.4).

---

## US-01 — Katalog frameworków bezpieczeństwa

**Rola:** security engineer
**Potrzeba:** przeglądać katalog wszystkich frameworków bezpieczeństwa
**Cel:** mieć jeden punkt dostępu do wszystkich standardów

### Kryteria akceptacji
- `GET /api/v1/frameworks` zwraca wszystkie frameworki z liczbą zagrożeń
- Strona główna wyświetla kafelek per framework z nazwą, wersją, opisem, linkiem referencyjnym
- Kliknięcie kafelka nawiguje do `/frameworks/:code`

### Plan testów TDD

**Backend:**
```go
func TestFrameworkService_List_ReturnsAllSeeded(t *testing.T) {
	svc := service.NewFrameworkService(testStore(t))
	frameworks, err := svc.List(context.Background())
	require.NoError(t, err)
	assert.GreaterOrEqual(t, len(frameworks), 10) // 4 OWASP top-10s + MITRE + CompTIA + 6 Cornucopia decks
}

func TestFrameworkHandler_Detail_404ForUnknownCode(t *testing.T) {
	srv := httptest.NewServer(router.New(testDeps(t)))
	defer srv.Close()
	resp, _ := http.Get(srv.URL + "/api/v1/frameworks/NOT_REAL")
	assert.Equal(t, http.StatusNotFound, resp.StatusCode)
}
```

**Frontend:**
```typescript
it('renders one tile per framework', async () => {
  render(<FrameworkBrowserPage />)
  const tiles = await screen.findAllByTestId('framework-tile')
  expect(tiles.length).toBeGreaterThanOrEqual(10)
})
```

**E2E:** `us01-frameworks.spec.ts` — home page shows tiles; clicking one navigates to `/frameworks/OWASP_LLM`.

---

## US-02 — Przeglądarka zagrożeń z filtrami

**Rola:** security engineer
**Potrzeba:** filtrować zagrożenia po frameworku, severity, STRIDE, tagu, `q`
**Cel:** szybko znaleźć zagrożenia istotne dla mojego projektu

### Kryteria akceptacji
- Filtry kombinowalne: framework, severity, stride, category, tag, q
- Debounce 300 ms na wyszukiwanie tekstowe
- Wynik aktualizuje się bez pełnego przeładowania strony

### Plan testów TDD

**Backend:**
```go
func TestThreatService_Filter_CombinesFrameworkAndSeverity(t *testing.T) {
	svc := service.NewThreatService(testStore(t))
	got, err := svc.List(context.Background(), service.ThreatFilter{
		FrameworkCode: ptr("OWASP_LLM"),
		Severity:      ptr(domain.SeverityCritical),
	})
	require.NoError(t, err)
	for _, th := range got {
		assert.Equal(t, "OWASP_LLM", th.FrameworkCode)
		assert.Equal(t, domain.SeverityCritical, th.Severity)
	}
}

func TestThreatHandler_List_RejectsQueryLongerThan200Chars(t *testing.T) {
	srv := httptest.NewServer(router.New(testDeps(t)))
	defer srv.Close()
	longQ := strings.Repeat("a", 201)
	resp, _ := http.Get(srv.URL + "/api/v1/threats?q=" + longQ)
	assert.Equal(t, http.StatusUnprocessableEntity, resp.StatusCode)
}
```

**Frontend:** `ThreatBrowserPage.spec.tsx` — filter panel updates the list via React Query without `window.location` changing.

**E2E:** `us02-threat-filter.spec.ts` — combine framework + severity filters, assert result count changes.

---

## US-03 — Szczegóły zagrożenia z mitigacjami i kodem

**Rola:** security engineer
**Potrzeba:** widzieć szczegóły zagrożenia z mitigacjami i próbkami kodu w 5 językach
**Cel:** wiedzieć jak wdrożyć ochronę

### Kryteria akceptacji
- Zakładki: Przegląd | Wektory ataku | Mitigacje | Kod | Powiązania
- Zakładka Kod zawiera podsekcje: Python | Java | Go | Scala | Lua
- Kod `ATTACK_DEMO` wymaga potwierdzenia w modalu przed wyświetleniem/kopiowaniem

### Plan testów TDD

**Backend:**
```go
func TestMitigationService_GetByThreatID_IncludesAllFiveLanguages(t *testing.T) {
	svc := service.NewMitigationService(testStore(t))
	mitigations, err := svc.ListByThreatID(context.Background(), llm01ID)
	require.NoError(t, err)
	langs := collectLanguages(mitigations[0].CodeSamples)
	assert.ElementsMatch(t, []domain.CodeLanguage{"PYTHON", "JAVA", "GO", "SCALA", "LUA"}, langs)
}
```

**Frontend:**
```typescript
it('does not render attack-demo code before confirmation', async () => {
  render(<ThreatDetailPage id="LLM01" />)
  await userEvent.click(await screen.findByText('Kod'))
  expect(screen.queryByTestId('attack-demo-code-body')).not.toBeInTheDocument()
  await userEvent.click(screen.getByText(/Rozumiem/i))
  expect(await screen.findByTestId('attack-demo-code-body')).toBeVisible()
})
```

**E2E:** `us03-threat-detail.spec.ts` — all 5 language tabs present; attack-demo gated by confirmation.

---

## US-04 — Mapowanie cross-framework (LLM01 → MITRE ATLAS)

**Rola:** CompTIA SecAI+ student
**Potrzeba:** zobaczyć jak LLM01 Prompt Injection mapuje do MITRE ATLAS AML.T0051
**Cel:** zrozumieć zależności między frameworkami

### Plan testów TDD

**Backend:**
```go
func TestCrossReferenceService_BySourceCode_ReturnsMapsToRelationship(t *testing.T) {
	svc := service.NewCrossReferenceService(testStore(t))
	refs, err := svc.BySourceCode(context.Background(), "LLM01")
	require.NoError(t, err)
	assert.Contains(t, refIDs(refs), "AML.T0051")
}
```

**E2E:** `us04-cross-reference.spec.ts` — matrix cell for LLM01/AML.T0051 is clickable and navigates correctly.

---

## US-05 — Bezpieczeństwo frontend/client-side (karty FRE)

**Rola:** React/frontend developer
**Potrzeba:** przeglądać karty Cornucopia FRE (Companion Edition v1.0) z polskimi opisami
**Cel:** mapować scenariusze ataków po stronie klienta na mitigacje

### Polskie tłumaczenia kart FRE (z `__LLM_AI___companion-cards-1.0-en.yaml`)

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie OWASP |
|---|---|---|---|
| FRE2 | "Marcus bypasses client-side validation and sends malformed or malicious input directly to backend APIs, triggering logic flaws, human errors, and usability issues" | *"Marcus omija walidację po stronie klienta i wysyła zniekształcone lub złośliwe dane bezpośrednio do API backendu, wywołując błędy logiki, błędy ludzkie i problemy użytkowe"* | **A03:2021 Injection / A04:2021 Insecure Design** — walidacja tylko client-side nigdy nie jest kontrolą bezpieczeństwa |
| FRE3 | "Lena can access sensitive or confidential information because it's not removed after logout or when the client session ends" | *"Lena może uzyskać dostęp do danych wrażliwych, ponieważ nie są one usuwane po wylogowaniu lub zakończeniu sesji klienta"* | **A01:2021 Broken Access Control** (STRIDE: Information Disclosure) |
| FRE4 | "James injects JavaScript through user-controlled data that is written into the DOM, executing arbitrary code in the victim's browser" | *"James wstrzykuje JavaScript poprzez dane kontrolowane przez użytkownika, które są zapisywane do DOM, wykonując dowolny kod w przeglądarce ofiary"* | **A03:2021 Injection (DOM XSS)** |
| FRE5 | "Victor compromises or replaces a third-party script loaded from a CDN and runs malicious code in every user's browser" | *"Victor kompromituje lub zamienia skrypt zewnętrzny wczytywany z CDN i wykonuje złośliwy kod w przeglądarce każdego użytkownika"* | **A06:2021 Vulnerable and Outdated Components** (supply-chain XSS) |

### Kryteria akceptacji
- `/frameworks/frontend-security` wyświetla wszystkie karty FRE z chipami OWASP
- Przełącznik PL/EN zmienia opis karty bez przeładowania strony

### Plan testów TDD

**Backend:**
```go
func TestCardService_BySuit_FRE_ReturnsAllCardsWithOwaspRefs(t *testing.T) {
	svc := service.NewCardService(testStore(t))
	cards, err := svc.BySuit(context.Background(), "FRE")
	require.NoError(t, err)
	for _, c := range cards {
		assert.NotEmpty(t, c.OwaspRefs)
	}
}

func TestCardLoader_FRE4_DescriptionPl_IsReviewedNotIdenticalToEnglish(t *testing.T) {
	card := loadCard(t, "FRE4")
	assert.NotEqual(t, card.DescriptionEn, card.DescriptionPl)
	assert.Contains(t, card.DescriptionPl, "James wstrzykuje")
}
```

**E2E:** `us05-frontend-security.spec.ts` — page lists FRE cards, PL toggle updates description text.

---

## US-06 — Bezpieczeństwo LLM (karty LLM + macierz)

**Rola:** ML engineer / AI architect
**Potrzeba:** eksplorować OWASP LLM Top 10 2025 przez karty Cornucopia LLM z interaktywną macierzą
**Cel:** zrozumieć prompt injection, data poisoning, excessive agency

### Polskie tłumaczenia kart LLM (z `__LLM_AI___companion-cards-1.0-en.yaml`)

| Karta | Angielski oryginał | Polskie tłumaczenie | OWASP LLM ref |
|---|---|---|---|
| LLM2 | "Samantha can exhaust computational resources or increase operational costs by submitting resource-intensive or recursive LLM queries, leading to model DoS" | *"Samantha może wyczerpać zasoby obliczeniowe lub zwiększyć koszty operacyjne, wysyłając zasobożerne lub rekurencyjne zapytania do LLM, co prowadzi do odmowy usługi modelu"* | **LLM10:2025 Unbounded Consumption**, MITRE ATLAS AML.T0029 |
| LLM3 | "Dave can exploit overreliance on LLM outputs where critical human oversight is missing, leading to security failures or incorrect decisions" | *"Dave może wykorzystać nadmierne poleganie na wynikach LLM przy braku krytycznego nadzoru człowieka, co prowadzi do błędów bezpieczeństwa lub błędnych decyzji"* | **LLM09:2025 Misinformation / Overreliance** |
| LLM4 | "David can cause the model to disclose sensitive information from its training data, system prompts, configuration... due to insufficient output filtering or prompt leakage" | *"David może spowodować, że model ujawni informacje wrażliwe z danych treningowych, system promptów, konfiguracji z powodu niewystarczającego filtrowania wyjścia lub wycieku promptu"* | **LLM02:2025 Sensitive Information Disclosure + LLM07:2025 System Prompt Leakage** |

### Plan testów TDD

**Backend:**
```go
func TestMatrixService_LLM_MapsLLM01ToCompanionLLMCards(t *testing.T) {
	svc := service.NewMatrixService(testStore(t))
	matrix, err := svc.LLM(context.Background())
	require.NoError(t, err)
	assert.NotEmpty(t, matrix.RowsFor("LLM10")) // LLM2 maps here
}
```

**Frontend:** `LlmMatrix.spec.tsx` — empty cells render a dashed placeholder, not a blank cell.

**E2E:** `us06-llm-security.spec.ts` — matrix page shows LLM2/LLM10 linked cell.

---

## US-07 — Agentic AI + Cloud (karty AAI + CLD)

**Rola:** agentic AI developer / cloud engineer
**Potrzeba:** studiować karty AAI (nadmierna autonomia) i CLD (błędna konfiguracja cloud)
**Cel:** projektować zabezpieczenia human-in-the-loop dla agentów i unikać nadmiarowych uprawnień IAM

### Polskie tłumaczenia kart AAI

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|
| AAI2 | "Tay can misinterpret user intent due to insufficient context isolation or prompt enforcement and execute actions outside the expected task scope" | *"Tay może błędnie zinterpretować intencję użytkownika z powodu niewystarczającej izolacji kontekstu i wykonać działania wykraczające poza oczekiwany zakres zadania"* | **OWASP Agentic AI Top 10 2026 — Excessive Agency; STRIDE: Elevation of Privilege** |
| AAI4 | "MissTrial can autonomously loop or chain external tool calls without enforcing rate limits or budget controls" | *"MissTrial może autonomicznie zapętlać lub łączyć wywołania zewnętrznych narzędzi bez wymuszania limitów szybkości lub kontroli budżetu"* | Pokrewne **LLM10:2025 Unbounded Consumption**; STRIDE: Denial of Service ("Denial of Wallet") |
| AAI5 | "Watson can reveal sensitive internal instructions, policies, or reasoning artifacts when exposed to adversarial prompting patterns" | *"Watson może ujawnić wrażliwe wewnętrzne instrukcje, polityki lub artefakty rozumowania pod wpływem adwersarialnego prompt engineeringu"* | **LLM07:2025 System Prompt Leakage** |

### Polskie tłumaczenia kart CLD (Cloud)

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|
| CLD2 | "Dan can abuse overly permissive roles assigned to an application to gain full access to cloud services beyond its intended scope" | *"Dan może wykorzystać nadmiernie permisywne role przypisane aplikacji, aby uzyskać pełny dostęp do usług cloud poza zamierzonym zakresem"* | **A01:2021 Broken Access Control** (excessive IAM permissions) |
| CLD3 | "Roupe can discover a publicly accessible cloud storage and download sensitive customer data directly from the internet" | *"Roupe może odnaleźć publicznie dostępny magazyn danych w chmurze i pobrać wrażliwe dane klientów bezpośrednio z internetu"* | **A05:2021 Security Misconfiguration** |
| CLD4 | "Ryan can operate within critical cloud services without triggering alerts by exploiting the absence of audit logs and security monitoring" | *"Ryan może działać w krytycznych usługach cloud bez wywoływania alertów, wykorzystując brak logów audytowych i monitoringu bezpieczeństwa"* | **A09:2021 Security Logging and Monitoring Failures** |

### Plan testów TDD

**Backend:**
```go
func TestCardService_AAI2_HasAutonomyRiskFlagForCriticalValues(t *testing.T) {
	svc := service.NewCardService(testStore(t))
	card, err := svc.ByCardID(context.Background(), "AAIK", "en")
	require.NoError(t, err)
	assert.True(t, card.IsCritical)
}

func TestCardService_CLD3_OwaspRefsContainsA05(t *testing.T) {
	svc := service.NewCardService(testStore(t))
	card, err := svc.ByCardID(context.Background(), "CLD3", "en")
	require.NoError(t, err)
	assert.Contains(t, card.OwaspRefs, "A05:2021")
}
```

**E2E:** `us07-agentic-ai.spec.ts` — AAIK/AAIQ show `AUTONOMY RISK` badge; CLD cards visible on the DevOps page (folded per FR-07.3).

---

## US-08 — STRIDE EoP — katalog i heatmapa

**Rola:** security architect / threat modeler
**Potrzeba:** używać katalogu kart STRIDE EoP z interaktywną heatmapą per komponent
**Cel:** prowadzić ustrukturyzowaną sesję threat modelingu

### Polskie tłumaczenia kart STRIDE (z `STRIDE__eop-cards-5.0-en.yaml`)

| Karta | STRIDE | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|---|
| SP2 | Spoofing | "An attacker could take over the port or socket that the server normally uses" | *"Atakujący może przejąć port lub gniazdo, które normalnie wykorzystuje serwer"* | **A05:2021 Security Misconfiguration** |
| SP3 | Spoofing | "An attacker could try one credential after another and there's nothing to slow them down (online or offline)" | *"Atakujący może próbować kolejnych danych uwierzytelniających bez żadnego mechanizmu spowalniającego"* | **A07:2021 Identification and Authentication Failures**, OAT-007/OAT-008 |
| TA2 | Tampering | "An attacker can take advantage of your custom key exchange or integrity control which you built instead of using standard crypto" | *"Atakujący może wykorzystać własną implementację wymiany kluczy zamiast standardowej kryptografii"* | **A02:2021 Cryptographic Failures** |
| TA6 | Tampering | "An attacker can write to a data store your code relies on" | *"Atakujący może zapisywać dane w magazynie danych, na którym opiera się kod"* | **A01:2021 Broken Access Control / A08:2021 Software and Data Integrity Failures** |

### Plan testów TDD

**Backend:**
```go
func TestStrideHeatmapService_Compute_ReturnsAllSixCategories(t *testing.T) {
	svc := service.NewStrideHeatmapService(testStore(t))
	heatmap, err := svc.Compute(context.Background())
	require.NoError(t, err)
	assert.Len(t, heatmap.Categories, 6)
}

func TestStrideHeatmapHandler_RequiresAuth(t *testing.T) {
	srv := httptest.NewServer(router.New(testDeps(t)))
	defer srv.Close()
	resp, _ := http.Get(srv.URL + "/api/v1/stride-heatmap")
	assert.Equal(t, http.StatusUnauthorized, resp.StatusCode)
}
```

**E2E:** `us08-stride.spec.ts` — 78 cards across 6 suits; heatmap requires login; `X-Frame-Options: DENY` present.

---

## US-09 — Bezpieczeństwo ML (karty MLSec)

**Rola:** data scientist / ML security engineer
**Potrzeba:** przeglądać ryzyka ML (Model/Input/Output/Dataset Risk) z referencjami MITRE ATLAS
**Cel:** identyfikować adversarial ML, model theft, data poisoning

### Polskie tłumaczenia kart MLSec (z `RISKS__elevation-of-mlsec-cards-1.0-en.yaml`)

| Karta | Suit | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|---|
| EMR2 | Model Risk | "When a model is filled with too much overlapping information, collisions in the representation space may lead to the model 'forgetting' information" (misc: Catastrophic forgetting) | *"Gdy model jest przeładowany zbyt dużą liczbą nakładających się informacji, kolizje w przestrzeni reprezentacji mogą prowadzić do 'zapominania' informacji przez model"* (katastroficzne zapominanie) | Brak wprost kodu OWASP LLM Top 10 — pokrewne **LLM04:2025 Data and Model Poisoning**; CompTIA SecAI+ "AI Model Reliability" |
| EMR3 | Model Risk | "An ML system may end up oscillating and not properly converging if using gradient descent in a space with a misleading gradient" (misc: Oscillation) | *"System ML może zacząć oscylować i nie zbiegać prawidłowo, jeśli używa gradientu prostego w przestrzeni z wprowadzającym w błąd gradientem"* | MITRE ATLAS ML Attack Staging (adwersarialne manipulowanie krajobrazem strat) |
| EMR4 | Model Risk | "Setting weights and thresholds with a bad RNG can damage system behavior and lead to subtle security issues" (misc: Randomness) | *"Ustawianie wag i progów przy użyciu słabego generatora liczb pseudolosowych może uszkodzić zachowanie systemu"* | **A02:2021 Cryptographic Failures** (analogicznie — słaba entropia), rozszerzone na warstwę ML |

### Plan testów TDD

**Backend:**
```go
func TestCardService_EMR2_HasNoOwaspRefButHasComptiaNote(t *testing.T) {
	svc := service.NewCardService(testStore(t))
	card, err := svc.ByCardID(context.Background(), "EMR2", "en")
	require.NoError(t, err)
	assert.Empty(t, card.OwaspRefs) // no forced/false OWASP mapping
	assert.NotEmpty(t, card.MiscNote)
}
```

**E2E:** `us09-ml-security.spec.ts` — MLSec page shows `ML-SPECIFIC` badge and does not fabricate an OWASP badge for EMR2.

---

## US-10 — Bezpieczeństwo mobile (karty Mobile MAS)

**Rola:** Android/iOS developer
**Potrzeba:** zobaczyć zagrożenia OWASP MASVS przez karty Cornucopia Mobile App
**Cel:** zrozumieć jak kontrolki bezpieczeństwa mobile różnią się od web

### Polskie tłumaczenia kart Mobile (z `mobileapp-cards-1.1-en.yaml`)

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|
| PC2 | "Andrew can expose sensitive data through the app's auto-generated screenshots when the app moves to the background" | *"Andrew może ujawnić dane wrażliwe poprzez automatycznie generowane zrzuty ekranu, gdy aplikacja przechodzi w tło"* | **MASVS-STORAGE** |
| PC3 | "Harold can spy sensitive data being entered through the user interface because the data is excessive, not properly masked or cleaned up after use" | *"Harold może przechwycić dane wrażliwe wprowadzane w interfejsie, ponieważ są nadmiarowe, niewłaściwie maskowane lub nieusuwane po użyciu"* | **MASVS-STORAGE** |
| PC4 | "Kelly can expose sensitive data by taking advantage of the app's excessive permissions" | *"Kelly może ujawnić dane wrażliwe, wykorzystując nadmiarowe uprawnienia aplikacji"* | **MASVS-PLATFORM**, A01:2021 least privilege |

### Plan testów TDD

**Backend:**
```go
func TestMatrixService_MobileVsWeb_MapsMasvsStorageToWebEquivalent(t *testing.T) {
	svc := service.NewMatrixService(testStore(t))
	matrix, err := svc.MobileVsWeb(context.Background())
	require.NoError(t, err)
	assert.NotEmpty(t, matrix.RowsFor("MASVS-STORAGE"))
}
```

**E2E:** `us10-mobile-security.spec.ts` — 6 suits × 13 cards; MASVS-vs-Web matrix renders.

---

## US-11 — Bezpieczeństwo DevOps + Cloud (karty DVO + CLD + BOT)

**Rola:** DevSecOps engineer / team lead
**Potrzeba:** przeglądać ryzyka supply chain (DVO), błędną konfigurację cloud (CLD) i wzorce automatycznych ataków (BOT)
**Cel:** chronić potoki CI/CD, ograniczać ryzyko cloud i bronić się przed botami

### Polskie tłumaczenia kart DVO + BOT

| Karta | Suit | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|---|
| DVOK | DVO | "Timo can compromise software, development environments, or DevOps tooling by injecting malicious code via external dependencies or exploited developer credentials" | *"Timo może skompromitować oprogramowanie, środowiska developerskie lub narzędzia DevOps, wstrzykując złośliwy kod przez zewnętrzne zależności lub wykorzystane dane uwierzytelniające developera"* | **CICD-SEC-3 Dependency Chain Abuse**, A06:2021 |
| DVOQ | DVO | "Seba can access the code repository, log files, command line history, pipelines, or other places, to gain access to secrets or other sensitive information" | *"Seba może uzyskać dostęp do repozytorium kodu, plików logów, historii linii komend, pipeline'ów lub innych miejsc, aby zdobyć sekrety lub inne dane wrażliwe"* | **CICD-SEC-6 Insufficient Credential Hygiene** |
| BOTK | BOT | "EDVAC can collect application content and/or other data for use elsewhere" | *"EDVAC może zbierać treść aplikacji i/lub inne dane do wykorzystania gdzie indziej"* | **OAT-011 Scraping** |
| BOTX | BOT | "Ferranti Pegasus can enumerate individual authentication credentials, or payment card data... by trying different values" | *"Ferranti Pegasus może enumerować poszczególne dane uwierzytelniające lub dane karty płatniczej, próbując różnych wartości"* | **OAT-021 Card Cracking / OAT-008 Credential Stuffing** |

### Kryteria akceptacji
- `/frameworks/devops-security` zawiera sekcje DVO, CLD, BOT
- Kliknięcie krytycznej karty BOT (BOTK, BOTX) otwiera modal ostrzeżenia
- `GET /api/v1/threats?suit=BOT` jest rate-limited (429 po > 60 req/min per IP)
- Przykłady kodu DVO/CLD to TYLKO pseudokod

### Plan testów TDD

**Backend:**
```go
func TestRateLimitMiddleware_Returns429After60Requests(t *testing.T) {
	srv := httptest.NewServer(router.New(testDeps(t)))
	defer srv.Close()
	var last *http.Response
	for i := 0; i < 61; i++ {
		last, _ = http.Get(srv.URL + "/api/v1/threats?suit=BOT")
	}
	assert.Equal(t, http.StatusTooManyRequests, last.StatusCode)
	assert.NotEmpty(t, last.Header.Get("Retry-After"))
}

func TestCardService_DVOK_OwaspRefsContainsA06(t *testing.T) {
	svc := service.NewCardService(testStore(t))
	card, err := svc.ByCardID(context.Background(), "DVOK", "en")
	require.NoError(t, err)
	assert.Contains(t, card.OwaspRefs, "A06:2021")
}
```

**Frontend:**
```typescript
describe('BotWarningModal', () => {
  it('opens on BOTK card click and blocks navigation until confirmed', async () => {
    render(<DevOpsSecurityPage />)
    await userEvent.click(await screen.findByTestId('bot-card-BOTK'))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
  })
})
```

**E2E:** `us11-devops-security.spec.ts` — DVO/CLD/BOT sections visible; BOT rate limit returns 429; modal gates BOT cards.

---

## US-12 — Bezpieczeństwo Website App (karty VE/AT/SM/AZ/CR/C)

**Rola:** Go/backend developer
**Potrzeba:** przeglądać karty Cornucopia Website App Edition v3.0
**Cel:** mapować klasyczne scenariusze ataków OWASP Web Top 10 na mitigacje

### Polskie tłumaczenia kart VE (z `webapp-cards-3.0-en.yaml`)

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|
| VE2 | "Brian can gather information about the underlying configurations, schemas, logic, code... due to the content of error messages, or poor configuration, or the presence of default installation files" | *"Brian może zebrać informacje o konfiguracji, schematach, logice, kodzie poprzez treść komunikatów błędów, słabą konfigurację lub obecność domyślnych plików instalacyjnych"* | **A05:2021 Security Misconfiguration + A09:2021 Logging Failures** |
| VE3 | "Robert can input malicious data because the allowed protocol format is not being checked, or duplicates are accepted, or the structure is not being verified" | *"Robert może wprowadzić złośliwe dane, ponieważ nie jest sprawdzany dozwolony format, akceptowane są duplikaty lub nie weryfikuje się struktury"* | **A03:2021 Injection** |
| VE4 | "Dave can input malicious field names or data because it is not being checked within the context of the current user and process" | *"Dave może wprowadzić złośliwe nazwy pól lub dane, ponieważ nie są sprawdzane w kontekście aktualnego użytkownika i procesu"* | **A01:2021 Broken Access Control** (mass assignment) |

### Kryteria akceptacji
- `/frameworks/website-app` wyświetla karty VE, AT, SM, AZ, CR, C grupowane po suit
- Każda karta ma chip prowadzący do odpowiadającego wpisu OWASP Web Top 10

### Plan testów TDD

**Backend:**
```go
func TestCardService_VE3_CrossReferencesA03(t *testing.T) {
	svc := service.NewCardService(testStore(t))
	card, err := svc.ByCardID(context.Background(), "VE3", "en")
	require.NoError(t, err)
	assert.Contains(t, card.OwaspRefs, "A03:2021")
}

func TestWebsiteAppPage_ListsAllSixSuits(t *testing.T) {
	svc := service.NewCardService(testStore(t))
	suits, err := svc.SuitsByEdition(context.Background(), "webapp")
	require.NoError(t, err)
	assert.ElementsMatch(t, []string{"VE", "AT", "SM", "AZ", "CR", "C"}, suits)
}
```

**E2E:** `us12-website-app.spec.ts` — page renders 6 suits; VE3 links to A03:2021 matrix row.

---

## US-13 — Próbki kodu Python

**Rola:** Python developer
**Potrzeba:** zobaczyć próbkę kodu Python dla każdej mitigacji
**Cel:** skopiować bezpieczny wzorzec

### Plan testów TDD

**Backend:**
```go
func TestCodeSampleService_EveryMitigationHasPythonSample(t *testing.T) {
	svc := service.NewCodeSampleService(testStore(t))
	mitigations := allMitigations(t)
	for _, m := range mitigations {
		samples, err := svc.ByMitigationID(context.Background(), m.ID)
		require.NoError(t, err)
		assert.Contains(t, languages(samples), domain.CodeLanguage("PYTHON"))
	}
}
```

**E2E:** `us13-python-code.spec.ts` — Python tab renders Django/FastAPI idiom in the Defense sub-tab.

---

## US-14 — Próbki kodu Java

**Rola:** Java developer
**Potrzeba:** zobaczyć próbkę kodu Java dla każdej mitigacji
**Cel:** porównać z własnymi idiomami z aplikacji Go

### Plan testów TDD

**Backend:**
```go
func TestCodeSampleService_EveryMitigationHasJavaSample(t *testing.T) {
	svc := service.NewCodeSampleService(testStore(t))
	for _, m := range allMitigations(t) {
		samples, err := svc.ByMitigationID(context.Background(), m.ID)
		require.NoError(t, err)
		assert.Contains(t, languages(samples), domain.CodeLanguage("JAVA"))
	}
}
```

**E2E:** `us14-java-code.spec.ts` — Java tab shows Spring Boot/Spring Security idiom; sample is clearly labelled as content, not linked to any backend build artifact.

---

## US-15 — Próbki kodu Scala (ataki supply-chain)

**Rola:** Scala developer
**Potrzeba:** znaleźć próbki kodu Scala dla ataków na łańcuch dostaw
**Cel:** zaimplementować SCA w pipeline Scali

### Plan testów TDD

**E2E:** `us15-scala-code.spec.ts` — filter code samples by `language=SCALA` and `tag=supply-chain`; assert at least one result.

---

## US-16 — Próbki kodu Lua (rate limiting / LLM DoS)

**Rola:** Lua/OpenResty developer
**Potrzeba:** zobaczyć przykłady Lua dla rate limiting zapobiegającego LLM DoS
**Cel:** skonfigurować guardrails NGINX dla proxy LLM API

### Plan testów TDD

**Backend:**
```go
func TestCodeSampleService_LLM2Mitigation_HasLuaResyLimitReqSample(t *testing.T) {
	svc := service.NewCodeSampleService(testStore(t))
	samples, err := svc.ByMitigationID(context.Background(), llm2MitigationID)
	require.NoError(t, err)
	lua := findByLanguage(samples, "LUA")
	assert.Contains(t, lua.Code, "lua-resty-limit-req")
}
```

**E2E:** `us16-lua-code.spec.ts` — Lua tab on the LLM2 mitigation shows an OpenResty rate-limiting sample.

---

## US-17 — Globalne wyszukiwanie

**Rola:** pentester
**Potrzeba:** wyszukać frazę i znaleźć wszystkie powiązane zagrożenia z obroną
**Cel:** złożyć checklistę testów dla klienta

### Plan testów TDD

**Backend:**
```go
func TestSearchService_Query_ReturnsHighlightedExcerpts(t *testing.T) {
	svc := service.NewSearchService(testStore(t))
	results, err := svc.Query(context.Background(), "deepfake", "en")
	require.NoError(t, err)
	assert.NotEmpty(t, results)
	assert.Contains(t, results[0].Excerpt, "<mark>")
}

func TestSearchHandler_RejectsQueryOver200Chars(t *testing.T) {
	srv := httptest.NewServer(router.New(testDeps(t)))
	defer srv.Close()
	resp, _ := http.Get(srv.URL + "/api/v1/search?q=" + strings.Repeat("a", 201))
	assert.Equal(t, http.StatusUnprocessableEntity, resp.StatusCode)
}
```

**E2E:** `us17-global-search.spec.ts` — search box present on every page; results grouped by type.

---

## US-18 — Eksport do CSV/PDF

**Rola:** team lead
**Potrzeba:** wyeksportować przefiltrowaną listę zagrożeń do CSV/PDF
**Cel:** dodać ją do rejestru ryzyk

### Plan testów TDD

**Backend:**
```go
func TestExportHandler_EnqueuesRiverJobAndReturns202(t *testing.T) {
	srv := httptest.NewServer(router.New(testDeps(t)))
	defer srv.Close()
	resp, _ := http.Get(srv.URL + "/api/v1/export?format=csv&framework=OWASP_LLM")
	assert.Equal(t, http.StatusAccepted, resp.StatusCode)
	var body struct{ JobID string `json:"jobId"` }
	json.NewDecoder(resp.Body).Decode(&body)
	assert.NotEmpty(t, body.JobID)
}

func TestGenerateCSVJob_ValidatesArgsBeforeExecuting(t *testing.T) {
	args := jobs.ExportCSVArgs{Format: "csv"} // missing required Framework
	err := jobs.ValidateExportArgs(args)
	assert.Error(t, err) // AC-14: malformed job payload rejected before execution
}

func TestExportStatusHandler_ReturnsPendingThenCompleted(t *testing.T) {
	jobID := enqueueTestExport(t)
	resp1 := getExportStatus(t, jobID)
	assert.Equal(t, "pending", resp1.Status)
	completeTestJob(t, jobID)
	resp2 := getExportStatus(t, jobID)
	assert.Equal(t, "completed", resp2.Status)
	assert.NotEmpty(t, resp2.DownloadURL)
}
```

**E2E:** `us18-export.spec.ts` — export button polls status and offers a download link once ready.

---

## US-19 — Digital-by-Default Harms (karty SCO/ARC/AGE/TRU/POR)

**Rola:** product owner / GRC reviewer w sektorze publicznym
**Potrzeba:** przeglądać talię "Digital-by-Default Harms" (`dbd-cards-1.0-en.yaml`) z polskimi tłumaczeniami, jasno odróżnioną od talii technicznych podatności
**Cel:** ocenić ryzyko wykluczenia cyfrowego i nieprzejrzystego projektowania usługi publicznej, zmapować je na OWASP A04:2021 Insecure Design

### Polskie tłumaczenia kart SCO/ARC (z `dbd-cards-1.0-en.yaml`)

| Karta | Suit | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|---|
| SCO2 | SCO — Scope | "Tommy does not create, publish and maintain publicly all the service assumptions, specifications, constraints, source code, algorithms, formulas, configuration settings, operating instructions and processes" | *"Tommy nie tworzy, nie publikuje i nie utrzymuje publicznie wszystkich założeń usługi, specyfikacji, ograniczeń, kodu źródłowego, algorytmów, formuł, ustawień konfiguracyjnych, instrukcji działania i procesów"* | **OWASP A04:2021 Insecure Design** — brak transparentności projektowej; SecAI+/GRC: wyjaśnialność algorytmów (AI Act, art. 13) |
| SCO3 | SCO | "Charlotte designs the service so that claimants themselves have to generate/enter data about personal activities or obtain/enter existing data from elsewhere" | *"Charlotte projektuje usługę tak, że osoby z niej korzystające muszą samodzielnie generować/wprowadzać dane o swoich działaniach lub zdobywać/wprowadzać dane już istniejące gdzie indziej"* | **A04:2021** (odwrócona zasada data minimization) |
| SCO4 | SCO | "Sofia undertakes features which require claimants to provide information repeatedly or which is already held" | *"Sofia wdraża funkcje wymagające ponownego podawania informacji, które już są w posiadaniu systemu"* | Naruszenie zasady **"collect once"** / RODO art. 5; **A04:2021**, nie podatność techniczna |
| ARC2 | ARC — Architecture | "Theo formulates identity verification resulting in limited ways to verify new accounts" | *"Theo formułuje weryfikację identyfikacji w sposób ograniczający metody weryfikacji nowych kont"* | **A04:2021 Insecure Design**, pokrewne STRIDE: Spoofing (utrudniona, nie ułatwiona, weryfikacja tożsamości) |
| ARC3 | ARC | "Oakley pulls the service into a shape which largely or completely excludes the use of paper for any input and output by claimants" | *"Oakley nadaje usłudze formę, która w dużej mierze lub całkowicie wyklucza możliwość użycia papieru do wejścia lub wyjścia danych"* | Harm projektowy — wykluczenie cyfrowe; **A04:2021** ("secure AND accessible by design") |

**Ważna uwaga metodologiczna:** ta talia — w przeciwieństwie do FRE/LLM/AAI/CLD/STRIDE/MLSec/Mobile/DVO/BOT/Website App — **nie opisuje podatności technicznych z określonym poziomem severity**. W modelu danych Go karta `dbd` ma `CardKind = "DESIGN_HARM"` i jej konstruktor **nie przyjmuje** argumentu `Severity` — nie jest to tylko konwencja UI, lecz właściwość systemu typów (patrz `PLAN.md` D-07, `requirements.md` FR-19.2).

### Kryteria akceptacji
- `/frameworks/digital-harms` wyświetla wszystkie karty pogrupowane po 5 suitach
- Każda karta renderowana jest z `DesignHarmBadge`, nigdy z `SeverityBadge`
- Banner disclaimera wyjaśnia harm projektowy vs. podatność techniczna
- `GET /api/v1/threats?suit=SCO|ARC|AGE|TRU|POR` nigdy nie zwraca pola `severity`

### Plan testów TDD

**Backend:**
```go
func TestNewDesignHarmCard_HasNoSeverityField(t *testing.T) {
	card := domain.NewDesignHarmCard("SCO2", "SCO", "Scope", enDesc, plDesc)
	// domain.NewDesignHarmCard's signature has no Severity parameter at all —
	// this test exists to document and lock that constructor shape, not to
	// "check" a value that could otherwise silently be set.
	assert.Equal(t, domain.CardKindDesignHarm, card.CardKind)
}

func TestCardService_SCO2_OwaspRefsContainsA04(t *testing.T) {
	svc := service.NewCardService(testStore(t))
	card, err := svc.ByCardID(context.Background(), "SCO2", "en")
	require.NoError(t, err)
	assert.Contains(t, card.OwaspRefs, "A04:2021")
}

func TestCardHandler_DigitalHarmsSuits_NeverReturnsSeverityField(t *testing.T) {
	srv := httptest.NewServer(router.New(testDeps(t)))
	defer srv.Close()
	resp, _ := http.Get(srv.URL + "/api/v1/threats?suit=SCO")
	var body struct {
		Items []map[string]any `json:"items"`
	}
	json.NewDecoder(resp.Body).Decode(&body)
	for _, item := range body.Items {
		_, hasSeverity := item["severity"]
		assert.False(t, hasSeverity)
		assert.Equal(t, "DESIGN_HARM", item["cardKind"])
	}
}
```

**Frontend:**
```typescript
describe('DigitalHarmsPage', () => {
  it('renders all 5 suit sections', async () => {
    render(<DigitalHarmsPage />)
    for (const suit of ['sco', 'arc', 'age', 'tru', 'por']) {
      await screen.findByTestId(`${suit}-section`)
    }
  })

  it('never renders a SeverityBadge on a dbd card', async () => {
    render(<DigitalHarmsPage />)
    const card = await screen.findByTestId('card-SCO2')
    expect(within(card).queryByTestId('severity-badge')).not.toBeInTheDocument()
    expect(within(card).getByTestId('design-harm-badge')).toBeInTheDocument()
  })

  it('shows the disclaimer banner before any card content', async () => {
    render(<DigitalHarmsPage />)
    expect(await screen.findByTestId('harms-disclaimer-banner')).toBeVisible()
  })
})
```

**E2E:**
```typescript
test.describe('US-19 Digital-by-Default Harms', () => {
  test('shows all 5 suits and the disclaimer banner', async ({ page }) => {
    await page.goto('/frameworks/digital-harms')
    await expect(page.getByTestId('harms-disclaimer-banner')).toBeVisible()
    for (const suit of ['sco', 'arc', 'age', 'tru', 'por']) {
      await expect(page.getByTestId(`${suit}-section`)).toBeVisible()
    }
  })

  test('switching to Polish shows the reviewed SCO2 translation', async ({ page }) => {
    await page.goto('/frameworks/digital-harms')
    await page.getByTestId('language-toggle').click()
    await expect(page.getByTestId('card-SCO2')).toContainText(/Tommy nie tworzy/i)
  })

  test('API never returns a severity field for dbd cards', async ({ request }) => {
    const response = await request.get('/api/v1/threats?suit=SCO')
    const body = await response.json()
    for (const card of body.items) {
      expect(card.severity).toBeUndefined()
      expect(card.cardKind).toBe('DESIGN_HARM')
    }
  })
})
```

---

## Podsumowanie planu testów

### Cel: ≥ 200 testów łącznie

| Warstwa | Framework | Liczba | Typ |
|---|---|---|---|
| Backend — unit | Go `testing` + `testify` | ≥ 60 | Serwisy, walidatory, konstruktory typów |
| Backend — integracja | `httptest` + testowa PostgreSQL (Docker) | ≥ 26 | Handlery, zapytania sqlc, rate-limit |
| Frontend — komponenty | Vitest + React Testing Library | ≥ 43 | Komponenty UI, hooki, store'y |
| Frontend — serwisy | Vitest + MSW 2 | ≥ 15 | fetch/React Query, interceptory, i18n |
| E2E | Playwright | ≥ 27 | 19 plików spec × ~1.4 scenariuszy |
| **RAZEM** | | **≥ 200** | |

### Cele pokrycia kodu

| Warstwa | Narzędzie | Cel |
|---|---|---|
| Backend Go | `go test -cover ./...` | ≥ 85% dla `internal/service` |
| Frontend React | Vitest v8 coverage | ≥ 75% |

### Kolejność wykonania testów w CI

```
[1] go vet ./... && golangci-lint run     — SAST, szybkie
[2] go test ./...                          — unit (bez bazy danych, mockowany store)
[3] go test -tags=integration ./...        — httptest + Testcontainers-go PostgreSQL
[4] govulncheck ./...                      — SCA na module graph
[5] npm run test                           — Vitest + RTL (coverage report)
[6] npm run build                          — Vite production build (< 600 KB gzip initial)
[7] npm run e2e                            — Playwright headless Chromium + Firefox
```

### Pliki testowe E2E (Playwright)

```
e2e/
├── us01-frameworks.spec.ts
├── us02-threat-filter.spec.ts
├── us03-threat-detail.spec.ts
├── us04-cross-reference.spec.ts
├── us05-frontend-security.spec.ts
├── us06-llm-security.spec.ts
├── us07-agentic-ai.spec.ts
├── us08-stride.spec.ts
├── us09-ml-security.spec.ts
├── us10-mobile-security.spec.ts
├── us11-devops-security.spec.ts
├── us12-website-app.spec.ts
├── us13-python-code.spec.ts
├── us14-java-code.spec.ts
├── us15-scala-code.spec.ts
├── us16-lua-code.spec.ts
├── us17-global-search.spec.ts
├── us18-export.spec.ts
└── us19-digital-harms.spec.ts
```

### Kluczowe scenariusze abuse case (powiązane testy)

| Abuse Case | Test | Faza |
|---|---|---|
| AC-01: SQL Injection `?q=` | `ThreatService` test — sqlc parametryzacja | Sprint 3–4 |
| AC-02: XSS w opisie karty | `bluemonday`/DOMPurify integration test | Sprint 5–7 |
| AC-05: Bot scraping | `RateLimitMiddleware` — 429 po 60 req | Sprint 10–12 |
| AC-06: YAML file tampering | `integrity.Verify` — abort na hash mismatch | Sprint 5–7 |
| AC-09: Privilege escalation `/stride-heatmap` | JWT middleware — 401 bez roli | Sprint 5–7 |
| AC-11: i18n locale injection | `Accept-Language` allowlist test | Sprint 9–10 |
| AC-14: Malicious River job payload | `ValidateExportArgs` rejects malformed Args | Sprint 10–12 |
| AC-15: BotWarningModal bypass | `us11-devops-security.spec.ts` — direct API call still gated | Sprint 5–7 |
| AC-16: Harms deck misread as CVE severity | `DigitalHarmsPage.spec.tsx` — no `SeverityBadge` ever rendered | Sprint 5–7 |
