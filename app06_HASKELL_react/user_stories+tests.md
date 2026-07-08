# HaskShield 2026 — User Stories & TDD Test Plan

**Version:** 1.0
**Date:** 2026-07-07
**Stack:** Haskell (GHC 9.8) + servant + hasql-th (backend) · React 18 + TypeScript + Vite (frontend)
**Test frameworks:** `hspec` + `QuickCheck` + `hspec-wai` · Vitest + React Testing Library · Playwright

---

## Konwencje testowe

### Backend (Haskell — `hspec` + `QuickCheck`)
```haskell
spec :: Spec
spec = describe "ThreatService" $ do
  it "filters by severity" $ do
    result <- runService testEnv $ ThreatService.list (ThreatFilter { severity = Just Critical })
    result `shouldSatisfy` all ((== Critical) . threatSeverity)

  prop "never returns a threat outside the requested framework" $
    \fw -> monadicIO $ do
      result <- run $ runService testEnv $ ThreatService.list (ThreatFilter { frameworkCode = Just fw })
      assert (all ((== fw) . threatFrameworkCode) result)
```

### Backend HTTP (`hspec-wai`)
```haskell
spec :: Spec
spec = with (pure app) $
  describe "GET /api/v1/threats" $
    it "responds 200 for a valid framework filter" $
      get "/api/v1/threats?framework=OWASP_LLM" `shouldRespondWith` 200
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
RED       — napisz test (hspec example lub QuickCheck property) opisujący oczekiwane zachowanie
GREEN     — napisz minimalny kod, który sprawia, że test przechodzi
REFACTOR  — poprawiaj kod bez łamania testów; GHC -Wall -Werror pilnuje wyczerpującego dopasowania wzorców
```

Dla funkcji czystych (bez `IO` w typie, patrz `PLAN.md` D-03) preferowany jest test właściwości (QuickCheck) nad przykładem — losowe dane wejściowe łapią przypadki brzegowe, których autor testu by nie wymyślił. Dla efektów (`IO`, dostęp do bazy) używamy `hspec`/`hspec-wai` z przykładami.

---

## US-01 — Katalog frameworków bezpieczeństwa

**Rola:** security engineer
**Potrzeba:** przeglądać katalog wszystkich frameworków bezpieczeństwa
**Cel:** mieć jeden punkt dostępu do wszystkich standardów

### Kryteria akceptacji
- `GET /api/v1/frameworks` zwraca wszystkie frameworki z liczbą zagrożeń
- Strona główna wyświetla kafelek per framework
- Kliknięcie kafelka nawiguje do `/frameworks/:code`

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "FrameworkService.list" $
  it "returns at least 10 seeded frameworks" $ do
    frameworks <- runService testEnv FrameworkService.list
    length frameworks `shouldSatisfy` (>= 10)

wai :: Spec
wai = with (pure app) $
  it "404s for an unknown framework code" $
    get "/api/v1/frameworks/NOT_REAL" `shouldRespondWith` 404
```

**Frontend:** `FrameworkBrowserPage.spec.tsx` — renders ≥ 10 tiles.

**E2E:** `us01-frameworks.spec.ts`.

---

## US-02 — Przeglądarka zagrożeń z filtrami

**Rola:** security engineer
**Potrzeba:** filtrować zagrożenia po frameworku, severity, STRIDE, tagu, `q`
**Cel:** szybko znaleźć zagrożenia istotne dla mojego projektu

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "ThreatService.list" $ do
  it "combines framework and severity filters" $ do
    result <- runService testEnv $ ThreatService.list ThreatFilter
      { frameworkCode = Just "OWASP_LLM", severity = Just Critical, .. }
    result `shouldSatisfy` all (\t -> threatFrameworkCode t == "OWASP_LLM" && threatSeverity t == Critical)

wai :: Spec
wai = with (pure app) $
  it "rejects a query longer than 200 characters with 422" $
    get ("/api/v1/threats?q=" <> BS.replicate 201 'a') `shouldRespondWith` 422
```

**E2E:** `us02-threat-filter.spec.ts` — combine filters, assert result count changes without navigation.

---

## US-03 — Szczegóły zagrożenia z mitigacjami i kodem

**Rola:** security engineer
**Potrzeba:** widzieć szczegóły zagrożenia z mitigacjami i próbkami kodu w 5 językach
**Cel:** wiedzieć jak wdrożyć ochronę

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "Mitigation.codeSamples" $
  prop "every seeded mitigation has all five languages" $
    forAll seededMitigations $ \m ->
      let langs = sampleLanguage <$> NE.toList (mitigationCodeSamples m)
      in sort (nub langs) === [Python, Java, Go, Scala, Lua]
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

**E2E:** `us03-threat-detail.spec.ts`.

---

## US-04 — Mapowanie cross-framework (LLM01 → MITRE ATLAS)

**Rola:** CompTIA SecAI+ student
**Potrzeba:** zobaczyć jak LLM01 Prompt Injection mapuje do MITRE ATLAS AML.T0051
**Cel:** zrozumieć zależności między frameworkami

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "CrossReferenceService.bySourceCode" $
  it "includes AML.T0051 for LLM01" $ do
    refs <- runService testEnv $ CrossReferenceService.bySourceCode "LLM01"
    map crossRefTargetCode refs `shouldContain` ["AML.T0051"]
```

**E2E:** `us04-cross-reference.spec.ts`.

---

## US-05 — Bezpieczeństwo frontend/client-side (karty FRE)

**Rola:** React/frontend developer
**Potrzeba:** przeglądać karty Cornucopia FRE (Companion Edition v1.0) z polskimi opisami
**Cel:** mapować scenariusze ataków po stronie klienta na mitigacje

### Polskie tłumaczenia kart FRE (z `__LLM_AI___companion-cards-1.0-en.yaml`)

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie OWASP |
|---|---|---|---|
| FRE2 | "Marcus bypasses client-side validation and sends malformed or malicious input directly to backend APIs, triggering logic flaws, human errors, and usability issues" | *"Marcus omija walidację po stronie klienta i wysyła zniekształcone lub złośliwe dane bezpośrednio do API backendu, wywołując błędy logiki, błędy ludzkie i problemy użytkowe"* | **A03:2021 Injection / A04:2021 Insecure Design** |
| FRE3 | "Lena can access sensitive or confidential information because it's not removed after logout or when the client session ends" | *"Lena może uzyskać dostęp do danych wrażliwych, ponieważ nie są one usuwane po wylogowaniu lub zakończeniu sesji klienta"* | **A01:2021 Broken Access Control** |
| FRE4 | "James injects JavaScript through user-controlled data that is written into the DOM, executing arbitrary code in the victim's browser" | *"James wstrzykuje JavaScript poprzez dane kontrolowane przez użytkownika, które są zapisywane do DOM, wykonując dowolny kod w przeglądarce ofiary"* | **A03:2021 Injection (DOM XSS)** |
| FRE5 | "Victor compromises or replaces a third-party script loaded from a CDN and runs malicious code in every user's browser" | *"Victor kompromituje lub zamienia skrypt zewnętrzny wczytywany z CDN i wykonuje złośliwy kod w przeglądarce każdego użytkownika"* | **A06:2021 Vulnerable and Outdated Components** |

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "CardService.bySuit \"FRE\"" $ do
  it "returns cards each carrying at least one OwaspRef" $ do
    cards <- runService testEnv $ CardService.bySuit "FRE"
    cards `shouldSatisfy` all (not . null . cardOwaspRefs)

  it "FRE4's Polish translation is reviewed, not identical to English" $ do
    card <- runService testEnv $ CardService.byCardId "FRE4" Pl
    cardDescriptionPl card `shouldNotBe` cardDescriptionEn card
    cardDescriptionPl card `shouldSatisfy` T.isInfixOf "James wstrzykuje"
```

**E2E:** `us05-frontend-security.spec.ts`.

---

## US-06 — Bezpieczeństwo LLM (karty LLM + macierz)

**Rola:** ML engineer / AI architect
**Potrzeba:** eksplorować OWASP LLM Top 10 2025 przez karty Cornucopia LLM z interaktywną macierzą
**Cel:** zrozumieć prompt injection, data poisoning, excessive agency

### Polskie tłumaczenia kart LLM

| Karta | Angielski oryginał | Polskie tłumaczenie | OWASP LLM ref |
|---|---|---|---|
| LLM2 | "Samantha can exhaust computational resources or increase operational costs by submitting resource-intensive or recursive LLM queries, leading to model DoS" | *"Samantha może wyczerpać zasoby obliczeniowe lub zwiększyć koszty operacyjne, wysyłając zasobożerne lub rekurencyjne zapytania do LLM"* | **LLM10:2025 Unbounded Consumption**, MITRE ATLAS AML.T0029 |
| LLM3 | "Dave can exploit overreliance on LLM outputs where critical human oversight is missing" | *"Dave może wykorzystać nadmierne poleganie na wynikach LLM przy braku krytycznego nadzoru człowieka"* | **LLM09:2025 Misinformation / Overreliance** |
| LLM4 | "David can cause the model to disclose sensitive information from its training data, system prompts, configuration... due to insufficient output filtering or prompt leakage" | *"David może spowodować, że model ujawni informacje wrażliwe z danych treningowych, system promptów lub konfiguracji z powodu niewystarczającego filtrowania wyjścia"* | **LLM02:2025 Sensitive Information Disclosure + LLM07:2025 System Prompt Leakage** |

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "MatrixService.llm" $
  it "maps LLM10 to a row containing card LLM2" $ do
    matrix <- runService testEnv MatrixService.llm
    rowsFor matrix "LLM10" `shouldSatisfy` any ((== "LLM2") . cardId)
```

**Frontend:** `LlmMatrix.spec.tsx` — empty cells render a dashed placeholder.

**E2E:** `us06-llm-security.spec.ts`.

---

## US-07 — Agentic AI + Cloud (karty AAI + CLD)

**Rola:** agentic AI developer / cloud engineer
**Potrzeba:** studiować karty AAI (nadmierna autonomia) i CLD (błędna konfiguracja cloud)
**Cel:** projektować zabezpieczenia human-in-the-loop i unikać nadmiarowych uprawnień IAM

### Polskie tłumaczenia kart AAI

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|
| AAI2 | "Tay can misinterpret user intent due to insufficient context isolation or prompt enforcement and execute actions outside the expected task scope" | *"Tay może błędnie zinterpretować intencję użytkownika z powodu niewystarczającej izolacji kontekstu i wykonać działania wykraczające poza oczekiwany zakres zadania"* | **OWASP Agentic AI Top 10 2026 — Excessive Agency; STRIDE: Elevation of Privilege** |
| AAI4 | "MissTrial can autonomously loop or chain external tool calls without enforcing rate limits or budget controls" | *"MissTrial może autonomicznie zapętlać lub łączyć wywołania zewnętrznych narzędzi bez wymuszania limitów szybkości lub kontroli budżetu"* | Pokrewne **LLM10:2025 Unbounded Consumption**; "Denial of Wallet" |
| AAI5 | "Watson can reveal sensitive internal instructions, policies, or reasoning artifacts when exposed to adversarial prompting patterns" | *"Watson może ujawnić wrażliwe wewnętrzne instrukcje lub artefakty rozumowania pod wpływem adwersarialnego prompt engineeringu"* | **LLM07:2025 System Prompt Leakage** |

### Polskie tłumaczenia kart CLD (Cloud)

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|
| CLD2 | "Dan can abuse overly permissive roles assigned to an application to gain full access to cloud services beyond its intended scope" | *"Dan może wykorzystać nadmiernie permisywne role przypisane aplikacji, aby uzyskać pełny dostęp do usług cloud poza zamierzonym zakresem"* | **A01:2021 Broken Access Control** |
| CLD3 | "Roupe can discover a publicly accessible cloud storage and download sensitive customer data directly from the internet" | *"Roupe może odnaleźć publicznie dostępny magazyn danych w chmurze i pobrać wrażliwe dane klientów bezpośrednio z internetu"* | **A05:2021 Security Misconfiguration** |
| CLD4 | "Ryan can operate within critical cloud services without triggering alerts by exploiting the absence of audit logs and security monitoring" | *"Ryan może działać w krytycznych usługach cloud bez wywoływania alertów, wykorzystując brak logów audytowych"* | **A09:2021 Security Logging and Monitoring Failures** |

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "CardService card kinds" $ do
  it "AAIK is flagged critical" $ do
    card <- runService testEnv $ CardService.byCardId "AAIK" En
    cardIsCritical card `shouldBe` True

  it "CLD3 cross-references A05:2021" $ do
    card <- runService testEnv $ CardService.byCardId "CLD3" En
    cardOwaspRefs card `shouldContain` [OwaspRef "A05:2021"]
```

**E2E:** `us07-agentic-ai.spec.ts` — AAIK/AAIQ show `AUTONOMY RISK` badge; CLD cards visible on the DevOps page.

---

## US-08 — STRIDE EoP — katalog i heatmapa

**Rola:** security architect / threat modeler
**Potrzeba:** używać katalogu kart STRIDE EoP z interaktywną heatmapą
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
```haskell
spec :: Spec
spec = describe "StrideHeatmapService.compute" $
  it "returns exactly the 6 STRIDE categories" $ do
    heatmap <- runService testEnv StrideHeatmapService.compute
    Set.fromList (heatmapCategories heatmap) `shouldBe` Set.fromList [minBound .. maxBound]

wai :: Spec
wai = with (pure app) $
  it "requires auth on /api/v1/stride-heatmap" $
    get "/api/v1/stride-heatmap" `shouldRespondWith` 401
```

**E2E:** `us08-stride.spec.ts` — 78 cards across 6 suits; heatmap requires login; `X-Frame-Options: DENY` present.

---

## US-09 — Bezpieczeństwo ML (karty MLSec)

**Rola:** data scientist / ML security engineer
**Potrzeba:** przeglądać ryzyka ML (Model/Input/Output/Dataset Risk) z referencjami MITRE ATLAS
**Cel:** identyfikować adversarial ML, model theft, data poisoning

### Polskie tłumaczenia kart MLSec

| Karta | Suit | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|---|
| EMR2 | Model Risk | "When a model is filled with too much overlapping information, collisions in the representation space may lead to the model 'forgetting' information" (misc: Catastrophic forgetting) | *"Gdy model jest przeładowany zbyt dużą liczbą nakładających się informacji, kolizje w przestrzeni reprezentacji mogą prowadzić do 'zapominania' informacji przez model"* | Brak wprost kodu OWASP LLM Top 10 — pokrewne **LLM04:2025 Data and Model Poisoning**; CompTIA SecAI+ "AI Model Reliability" |
| EMR3 | Model Risk | "An ML system may end up oscillating and not properly converging if using gradient descent in a space with a misleading gradient" (misc: Oscillation) | *"System ML może zacząć oscylować i nie zbiegać prawidłowo, jeśli używa gradientu prostego w przestrzeni z wprowadzającym w błąd gradientem"* | MITRE ATLAS ML Attack Staging |
| EMR4 | Model Risk | "Setting weights and thresholds with a bad RNG can damage system behavior and lead to subtle security issues" (misc: Randomness) | *"Ustawianie wag i progów przy użyciu słabego generatora liczb pseudolosowych może uszkodzić zachowanie systemu"* | **A02:2021 Cryptographic Failures** (analogicznie, rozszerzone na warstwę ML) |

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "CardService.byCardId \"EMR2\"" $
  it "has no OWASP ref but does have a misc note (no false mapping)" $ do
    card <- runService testEnv $ CardService.byCardId "EMR2" En
    cardOwaspRefs card `shouldBe` []
    cardMiscNote card `shouldSatisfy` isJust
```

**E2E:** `us09-ml-security.spec.ts` — `ML-SPECIFIC` badge shown; no fabricated OWASP badge for EMR2.

---

## US-10 — Bezpieczeństwo mobile (karty Mobile MAS)

**Rola:** Android/iOS developer
**Potrzeba:** zobaczyć zagrożenia OWASP MASVS przez karty Cornucopia Mobile App
**Cel:** zrozumieć jak kontrolki bezpieczeństwa mobile różnią się od web

### Polskie tłumaczenia kart Mobile

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|
| PC2 | "Andrew can expose sensitive data through the app's auto-generated screenshots when the app moves to the background" | *"Andrew może ujawnić dane wrażliwe poprzez automatycznie generowane zrzuty ekranu, gdy aplikacja przechodzi w tło"* | **MASVS-STORAGE** |
| PC3 | "Harold can spy sensitive data being entered through the user interface because the data is excessive, not properly masked or cleaned up after use" | *"Harold może przechwycić dane wrażliwe wprowadzane w interfejsie, ponieważ są nadmiarowe, niewłaściwie maskowane"* | **MASVS-STORAGE** |
| PC4 | "Kelly can expose sensitive data by taking advantage of the app's excessive permissions" | *"Kelly może ujawnić dane wrażliwe, wykorzystując nadmiarowe uprawnienia aplikacji"* | **MASVS-PLATFORM** |

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "MatrixService.mobileVsWeb" $
  it "maps MASVS-STORAGE to a web-equivalent row" $ do
    matrix <- runService testEnv MatrixService.mobileVsWeb
    rowsFor matrix "MASVS-STORAGE" `shouldSatisfy` (not . null)
```

**E2E:** `us10-mobile-security.spec.ts`.

---

## US-11 — Bezpieczeństwo DevOps + Cloud (karty DVO + CLD + BOT)

**Rola:** DevSecOps engineer / team lead
**Potrzeba:** przeglądać ryzyka supply chain (DVO), błędną konfigurację cloud (CLD) i wzorce automatycznych ataków (BOT)
**Cel:** chronić potoki CI/CD, ograniczać ryzyko cloud i bronić się przed botami

### Polskie tłumaczenia kart DVO + BOT

| Karta | Suit | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|---|
| DVOK | DVO | "Timo can compromise software, development environments, or DevOps tooling by injecting malicious code via external dependencies or exploited developer credentials" | *"Timo może skompromitować oprogramowanie, środowiska developerskie lub narzędzia DevOps, wstrzykując złośliwy kod przez zewnętrzne zależności"* | **CICD-SEC-3 Dependency Chain Abuse**, A06:2021 |
| DVOQ | DVO | "Seba can access the code repository, log files, command line history, pipelines, or other places, to gain access to secrets or other sensitive information" | *"Seba może uzyskać dostęp do repozytorium kodu, logów, historii linii komend lub pipeline'ów, aby zdobyć sekrety"* | **CICD-SEC-6 Insufficient Credential Hygiene** |
| BOTK | BOT | "EDVAC can collect application content and/or other data for use elsewhere" | *"EDVAC może zbierać treść aplikacji i/lub inne dane do wykorzystania gdzie indziej"* | **OAT-011 Scraping** |
| BOTX | BOT | "Ferranti Pegasus can enumerate individual authentication credentials, or payment card data... by trying different values" | *"Ferranti Pegasus może enumerować dane uwierzytelniające lub dane karty płatniczej, próbując różnych wartości"* | **OAT-021 Card Cracking / OAT-008 Credential Stuffing** |

### Kryteria akceptacji
- `/frameworks/devops-security` zawiera sekcje DVO, CLD, BOT
- Kliknięcie krytycznej karty BOT otwiera modal ostrzeżenia
- `GET /api/v1/threats?suit=BOT` jest rate-limited (429 po > 60 req/min per IP)

### Plan testów TDD

**Backend:**
```haskell
wai :: Spec
wai = with (pure app) $
  it "returns 429 with Retry-After after 60 requests to the BOT suit" $ do
    replicateM_ 60 (get "/api/v1/threats?suit=BOT")
    response <- get "/api/v1/threats?suit=BOT"
    liftIO $ simpleStatus response `shouldBe` status429
    liftIO $ lookup "Retry-After" (simpleHeaders response) `shouldSatisfy` isJust

spec :: Spec
spec = describe "CardService.byCardId \"DVOK\"" $
  it "cross-references A06:2021" $ do
    card <- runService testEnv $ CardService.byCardId "DVOK" En
    cardOwaspRefs card `shouldContain` [OwaspRef "A06:2021"]
```

**E2E:** `us11-devops-security.spec.ts`.

---

## US-12 — Bezpieczeństwo Website App (karty VE/AT/SM/AZ/CR/C)

**Rola:** backend developer
**Potrzeba:** przeglądać karty Cornucopia Website App Edition v3.0
**Cel:** mapować klasyczne scenariusze ataków OWASP Web Top 10 na mitigacje

### Polskie tłumaczenia kart VE (z `webapp-cards-3.0-en.yaml`)

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|
| VE2 | "Brian can gather information about the underlying configurations, schemas, logic, code... due to the content of error messages, or poor configuration, or the presence of default installation files" | *"Brian może zebrać informacje o konfiguracji, schematach, logice, kodzie poprzez treść komunikatów błędów lub słabą konfigurację"* | **A05:2021 Security Misconfiguration + A09:2021 Logging Failures** |
| VE3 | "Robert can input malicious data because the allowed protocol format is not being checked, or duplicates are accepted, or the structure is not being verified" | *"Robert może wprowadzić złośliwe dane, ponieważ nie jest sprawdzany dozwolony format lub nie weryfikuje się struktury"* | **A03:2021 Injection** |
| VE4 | "Dave can input malicious field names or data because it is not being checked within the context of the current user and process" | *"Dave może wprowadzić złośliwe nazwy pól lub dane, ponieważ nie są sprawdzane w kontekście aktualnego użytkownika i procesu"* | **A01:2021 Broken Access Control** (mass assignment) |

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "CardService.suitsByEdition \"webapp\"" $
  it "returns exactly the 6 Website App suits" $ do
    suits <- runService testEnv $ CardService.suitsByEdition Webapp
    sort suits `shouldBe` sort ["VE", "AT", "SM", "AZ", "CR", "C"]

  it "VE3 cross-references A03:2021" $ do
    card <- runService testEnv $ CardService.byCardId "VE3" En
    cardOwaspRefs card `shouldContain` [OwaspRef "A03:2021"]
```

**E2E:** `us12-website-app.spec.ts`.

---

## US-13 — Próbki kodu Python

**Rola:** Python developer
**Potrzeba:** zobaczyć próbkę kodu Python dla każdej mitigacji
**Cel:** skopiować bezpieczny wzorzec

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "CodeSampleService" $
  prop "every seeded mitigation has a Python sample" $
    forAll seededMitigationIds $ \mid -> monadicIO $ do
      samples <- run $ runService testEnv $ CodeSampleService.byMitigationId mid
      assert (Python `elem` map sampleLanguage samples)
```

**E2E:** `us13-python-code.spec.ts`.

---

## US-14 — Próbki kodu Java

**Rola:** Java developer
**Potrzeba:** zobaczyć próbkę kodu Java dla każdej mitigacji
**Cel:** porównać z alternatywą o silniejszym systemie typów

### Plan testów TDD

**Backend:** analogicznie do US-13, `prop` sprawdza obecność `Java` w liście języków dla każdej mitigacji.

**E2E:** `us14-java-code.spec.ts` — zakładka Java pokazuje idiom Spring Boot/Spring Security; próbka jest jednoznacznie oznaczona jako treść, niezwiązana z żadnym artefaktem budowania backendu.

---

## US-15 — Próbki kodu Scala (ataki supply-chain)

**Rola:** Scala developer
**Potrzeba:** znaleźć próbki kodu Scala dla ataków na łańcuch dostaw
**Cel:** zaimplementować SCA w pipeline Scali

### Plan testów TDD

**E2E:** `us15-scala-code.spec.ts` — filtruj próbki po `language=SCALA` i `tag=supply-chain`.

---

## US-16 — Próbki kodu Lua (rate limiting / LLM DoS)

**Rola:** Lua/OpenResty developer
**Potrzeba:** zobaczyć przykłady Lua dla rate limiting zapobiegającego LLM DoS
**Cel:** skonfigurować guardrails NGINX dla proxy LLM API

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "CodeSampleService for LLM2's mitigation" $
  it "includes a Lua sample using lua-resty-limit-req" $ do
    samples <- runService testEnv $ CodeSampleService.byMitigationId llm2MitigationId
    let lua = find ((== Lua) . sampleLanguage) samples
    fmap sampleCode lua `shouldSatisfy` maybe False (T.isInfixOf "lua-resty-limit-req")
```

**E2E:** `us16-lua-code.spec.ts`.

---

## US-17 — Globalne wyszukiwanie

**Rola:** pentester
**Potrzeba:** wyszukać frazę i znaleźć wszystkie powiązane zagrożenia z obroną
**Cel:** złożyć checklistę testów dla klienta

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "SearchService.query" $
  it "returns highlighted excerpts" $ do
    results <- runService testEnv $ SearchService.query "deepfake" En
    results `shouldSatisfy` not . null
    resultExcerpt (head results) `shouldSatisfy` T.isInfixOf "<mark>"

wai :: Spec
wai = with (pure app) $
  it "rejects a query over 200 characters" $
    get ("/api/v1/search?q=" <> BS.replicate 201 'a') `shouldRespondWith` 422
```

**E2E:** `us17-global-search.spec.ts`.

---

## US-18 — Eksport do CSV/PDF

**Rola:** team lead
**Potrzeba:** wyeksportować przefiltrowaną listę zagrożeń do CSV/PDF
**Cel:** dodać ją do rejestru ryzyk

### Plan testów TDD

**Backend:**
```haskell
wai :: Spec
wai = with (pure app) $
  it "enqueues a job and returns 202 with a jobId" $ do
    response <- get "/api/v1/export?format=csv&framework=OWASP_LLM"
    liftIO $ simpleStatus response `shouldBe` status202
    let Just body = decode (simpleBody response) :: Maybe ExportJobResponse
    liftIO $ exportJobId body `shouldSatisfy` (not . T.null)

spec :: Spec
spec = describe "Jobs.ExportCsv.validateArgs" $
  it "rejects args missing the required framework field" $
    Jobs.ExportCsv.validateArgs (ExportCsvArgs { format = "csv", framework = "" })
      `shouldSatisfy` isLeft -- AC-14: malformed job payload rejected before execution
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
| ARC2 | ARC — Architecture | "Theo formulates identity verification resulting in limited ways to verify new accounts" | *"Theo formułuje weryfikację identyfikacji w sposób ograniczający metody weryfikacji nowych kont"* | **A04:2021 Insecure Design**, pokrewne STRIDE: Spoofing |
| ARC3 | ARC | "Oakley pulls the service into a shape which largely or completely excludes the use of paper for any input and output by claimants" | *"Oakley nadaje usłudze formę, która w dużej mierze lub całkowicie wyklucza możliwość użycia papieru do wejścia lub wyjścia danych"* | Harm projektowy — wykluczenie cyfrowe; **A04:2021** ("secure AND accessible by design") |

**Ważna uwaga metodologiczna:** ta talia — w przeciwieństwie do FRE/LLM/AAI/CLD/STRIDE/MLSec/Mobile/DVO/BOT/Website App — **nie opisuje podatności technicznych z określonym poziomem severity**. W modelu danych Haskell karta `dbd` ma `cardKind = DesignHarm`, a `DesignHarm` jest konstruktorem typu sumy `CardKind` **bez pola severity** — nie istnieje żadna wartość Haskella `DesignHarm` niosąca `Severity`, bo taki typ nie ma odpowiadającego pola (patrz `PLAN.md` D-01). To najsilniejsza wersja tej gwarancji spośród wszystkich sześciu aplikacji w tej serii kursu.

### Kryteria akceptacji
- `/frameworks/digital-harms` wyświetla wszystkie karty pogrupowane po 5 suitach
- Każda karta renderowana jest z `DesignHarmBadge`, nigdy z `SeverityBadge`
- Banner disclaimera wyjaśnia harm projektowy vs. podatność techniczna
- Odpowiedź JSON dla kart `SCO|ARC|AGE|TRU|POR` **nie zawiera klucza** `severity` (nie `null` — nieobecność klucza)

### Plan testów TDD

**Backend:**
```haskell
spec :: Spec
spec = describe "CardKind" $ do
  it "DesignHarm cannot carry a severity — this is a type-level fact, tested via serialization" $ do
    let card = mkDesignHarmCard "SCO2" "SCO" enDesc plDesc
    -- Nie istnieje getter `cardSeverity :: CornucopiaCard -> Severity` dla tego przypadku;
    -- ten test dokumentuje kształt encoding JSON, który jest jedyną obserwowalną konsekwencją.
    let encoded = Aeson.toJSON card
    HashMap.member "severity" (encoded ^?! _Object) `shouldBe` False
    cardKind card `shouldBe` DesignHarm

  it "SCO2 cross-references A04:2021" $ do
    card <- runService testEnv $ CardService.byCardId "SCO2" En
    cardOwaspRefs card `shouldContain` [OwaspRef "A04:2021"]

wai :: Spec
wai = with (pure app) $
  it "GET /api/v1/threats?suit=SCO never returns a severity key" $ do
    response <- get "/api/v1/threats?suit=SCO"
    let Just (Aeson.Object items) = decode (simpleBody response)
    liftIO $ forM_ (items ^.. members) $ \item ->
      HashMap.member "severity" (item ^?! _Object) `shouldBe` False
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

  it('never renders a SeverityBadge on a dbd card — the TS type has no severity field', async () => {
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

  test('API response for dbd cards has no severity key at all', async ({ request }) => {
    const response = await request.get('/api/v1/threats?suit=SCO')
    const body = await response.json()
    for (const card of body.items) {
      expect(Object.keys(card)).not.toContain('severity')
      expect(card.cardKind).toBe('DesignHarm')
    }
  })
})
```

---

## Podsumowanie planu testów

### Cel: ≥ 200 testów łącznie

| Warstwa | Framework | Liczba | Typ |
|---|---|---|---|
| Backend — unit (hspec) | `hspec` | ≥ 45 | Serwisy, konstruktory typów, encoding JSON |
| Backend — właściwości | `QuickCheck` | ≥ 15 | Niezmienniki (np. każda mitigacja ma 5 języków, YAML z nieznanymi polami jest odrzucany) |
| Backend — integracja | `hspec-wai` + testowa PostgreSQL (Docker) | ≥ 26 | Handlery, statementy hasql-th, rate-limit |
| Frontend — komponenty | Vitest + React Testing Library | ≥ 43 | Komponenty UI, hooki, store'y |
| Frontend — serwisy | Vitest + MSW 2 | ≥ 15 | fetch/React Query, interceptory, i18n |
| E2E | Playwright | ≥ 27 | 19 plików spec × ~1.4 scenariuszy |
| **RAZEM** | | **≥ 200** | |

### Cele pokrycia kodu

| Warstwa | Narzędzie | Cel |
|---|---|---|
| Backend Haskell | `hpc` (via `cabal test --enable-coverage`) | ≥ 85% dla `src/Service` |
| Frontend React | Vitest v8 coverage | ≥ 75% |

### Kolejność wykonania testów w CI

```
[1] hlint . && stan check                  — SAST, szybkie
[2] cabal build -Wall -Werror              — kompilacja z ostrzeżeniami jako błędami
[3] cabal test hasshield-core:unit         — hspec + QuickCheck (bez bazy danych)
[4] cabal test hasshield-core:integration  — hspec-wai + testowa PostgreSQL (Docker)
[5] osv-scanner --lockfile=cabal.project.freeze   — SCA
[6] npm run test                           — Vitest + RTL (coverage report)
[7] npm run build                          — Vite production build (< 600 KB gzip initial)
[8] npm run e2e                            — Playwright headless Chromium + Firefox
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
| AC-01: SQL Injection `?q=` | Nie istnieje ścieżka kodu budująca SQL inaczej niż przez `hasql-th` — test dokumentuje ten fakt | Sprint 3–4 |
| AC-02: XSS w opisie karty | `xss-sanitize`/DOMPurify integration test | Sprint 5–7 |
| AC-05: Bot scraping | `hspec-wai` — 429 po 60 req | Sprint 10–12 |
| AC-06: YAML file tampering | `Integrity.Verify` — abort na hash mismatch | Sprint 5–7 |
| AC-09: Privilege escalation `/stride-heatmap` | JWT middleware — 401 bez roli | Sprint 5–7 |
| AC-11: i18n locale injection | `Locale` sum type — parsowanie nieznanej wartości zwraca `En`, nigdy nie propaguje surowego tekstu | Sprint 9–10 |
| AC-14: Malicious odd-jobs payload | `Jobs.ExportCsv.validateArgs` odrzuca niekompletne dane | Sprint 10–12 |
| AC-15: BotWarningModal bypass | `us11-devops-security.spec.ts` — bezpośrednie wywołanie API wciąż zablokowane | Sprint 5–7 |
| AC-16: Harms deck misread as CVE severity | Test serializacji JSON — brak klucza `severity`, nie tylko `null` | Sprint 5–7 |
