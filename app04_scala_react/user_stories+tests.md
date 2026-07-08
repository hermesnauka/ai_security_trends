# ScalaShield 2026 — User Stories & TDD Test Plan

**Wersja:** 1.0  
**Data:** 2026-07-07  
**Stack:** Scala 3 + ZIO 2 + ZIO HTTP (backend) · React 18 + TypeScript + Vite (frontend)  
**Test frameworks:** ZIO Test + Testcontainers · Vitest + React Testing Library · Playwright  

---

## Konwencje testowe

### Backend (Scala / ZIO Test)
```scala
// Każdy spec dziedziczy po ZIOSpecDefault
object MyServiceSpec extends ZIOSpecDefault:
  def spec = suite("MyService")(
    test("opis testu") {
      for
        svc    <- ZIO.service[MyService]
        result <- svc.someMethod(input)
      yield assert(result)(assertion)
    }
  ).provide(MyService.live, TestDatabase.layer)
```

### Frontend (Vitest + React Testing Library)
```typescript
// vitest.config.ts: environment: 'jsdom', setupFiles: ['./src/setupTests.ts']
describe('ComponentName', () => {
  it('opis testu', async () => {
    render(<ComponentName />)
    expect(await screen.findByText('...'))...
  })
})
```

### E2E (Playwright)
```typescript
// playwright.config.ts: baseURL http://localhost:5173
test('opis testu', async ({ page }) => {
  await page.goto('/route')
  await expect(page.getByTestId('...')).toBeVisible()
})
```

---

## US-01 — Katalog frameworków bezpieczeństwa

**Rola:** security engineer  
**Potrzeba:** przeglądać katalog frameworków bezpieczeństwa  
**Cel:** mieć jeden punkt dostępu do wszystkich standardów  

### Kryteria akceptacji
- `GET /api/v1/frameworks` zwraca listę z polami: code, name, version, description, referenceUrl
- Strona `/frameworks` wyświetla kafelki dla każdego frameworku
- Kliknięcie kafelka nawiguje do `/frameworks/:code`
- Lista zawiera minimum: OWASP_WEB, OWASP_LLM, OWASP_API, OWASP_AGENTIC, MITRE_ATLAS, COMPTIA_SECAI

### Plan testów TDD

**Backend:**
- `FrameworkServiceSpec` — ZIO Test: ładowanie listy frameworków, brak stack trace w 5xx
- `FrameworkRoutesSpec` — ZIO HTTP testkit: GET /api/v1/frameworks → 200 JSON, GET /api/v1/frameworks/OWASP_WEB → 200

**Frontend:**
- `FrameworkBrowser.spec.tsx` — renderuje kafelki, klik nawiguje do szczegółów
- `frameworkService.spec.ts` — axios mock, parsowanie DTO

**E2E:**
- `us01-frameworks.spec.ts` — strona /frameworks ładuje się, widoczne min. 6 kafelków

---

## US-02 — Przeglądarka zagrożeń z filtrami

**Rola:** security engineer  
**Potrzeba:** filtrować zagrożenia według frameworku, severity, STRIDE, tagu, q  
**Cel:** szybko znaleźć zagrożenia istotne dla projektu  

### Kryteria akceptacji
- `GET /api/v1/threats` akceptuje filtry: frameworkCode, severity, stride, tag, q, suit, owaspRef, mitreRef
- Wyniki paginowane (domyślnie 20 per strona)
- Filtr q obsługuje pełnotekstowy search (tsvector PostgreSQL)
- Filtr stride przyjmuje tylko wartości ze zbioru {S,T,R,I,D,E}
- Parametr q ograniczony do max 200 znaków

### Plan testów TDD

**Backend:**
```scala
object ThreatServiceSpec extends ZIOSpecDefault:
  def spec = suite("ThreatService")(
    test("should filter by severity=HIGH") {
      for
        service <- ZIO.service[ThreatService]
        results <- service.findThreats(ThreatFilter(severity = Some("HIGH")))
      yield assert(results.items)(forall(t => assert(t.severity)(equalTo("HIGH"))))
    },
    test("should reject stride filter with invalid characters") {
      for
        service <- ZIO.service[ThreatService]
        result  <- service.findThreats(ThreatFilter(stride = Some("XYZ"))).exit
      yield assert(result)(fails(isSubtype[ValidationError](anything)))
    },
    test("should limit q parameter to 200 chars") {
      for
        service <- ZIO.service[ThreatService]
        result  <- service.findThreats(ThreatFilter(q = Some("a" * 201))).exit
      yield assert(result)(fails(isSubtype[ValidationError](anything)))
    }
  ).provide(ThreatService.live, TestDatabase.layer)
```

**Frontend:**
- `ThreatBrowser.spec.tsx` — panel filtrów renderuje się, select severity działa, MSW mock odpowiada
- `ThreatFilter.spec.ts` — budowanie query params z obiektu filtra

**E2E:**
- `us02-threat-filter.spec.ts` — filtrowanie severity=HIGH zmniejsza listę wyników

---

## US-03 — Szczegóły zagrożenia z mitigacjami i kodem

**Rola:** security engineer  
**Potrzeba:** zobaczyć szczegóły zagrożenia z mitigacjami i próbkami kodu  
**Cel:** rozumieć jak wdrożyć ochronę  

### Kryteria akceptacji
- `GET /api/v1/threats/:id` zwraca zagrożenie z zagnieżdżonymi mitigacjami i próbkami kodu
- Strona `/threats/:id` pokazuje zakładki: Przegląd | Mitigacje | Kod | Powiązania
- Zakładka Kod zawiera podsekcje: Python | Java | Go | Scala | Lua
- Próbka ATTACK_DEMO oznaczona badge `PODATNY` z czerwonym obramowaniem
- Brak stack trace w odpowiedziach błędu API

### Plan testów TDD

**Backend:**
```scala
object ThreatDetailServiceSpec extends ZIOSpecDefault:
  def spec = suite("ThreatDetailService")(
    test("should return threat with nested mitigations") {
      for
        service <- ZIO.service[ThreatService]
        threat  <- service.getThreatById(knownThreatId)
      yield assert(threat.mitigations)(isNonEmpty)
    },
    test("should return threat with code samples in 5 languages") {
      for
        service <- ZIO.service[ThreatService]
        threat  <- service.getThreatById(knownThreatId)
        langs    = threat.mitigations.flatMap(_.codeSamples).map(_.language).toSet
      yield assert(langs)(hasSameElements(Set("PYTHON","JAVA","GO","SCALA","LUA")))
    },
    test("should return 404 for unknown threat id") {
      for
        response <- ZIO.serviceWithZIO[TestServer](_.get(s"/api/v1/threats/$unknownId"))
      yield assert(response.status)(equalTo(Status.NotFound))
    }
  ).provide(ThreatService.live, TestServer.layer, TestDatabase.layer)
```

**Frontend:**
- `ThreatDetail.spec.tsx` — zakładki renderują się, przełączanie zakładek działa
- `CodeSamplePanel.spec.tsx` — badge PODATNY widoczny dla ATTACK_DEMO, brak dla DEFENSE

**E2E:**
- `us03-threat-detail.spec.ts` — kliknięcie zagrożenia otwiera stronę szczegółów z kodem

---

## US-04 — Mapowanie cross-framework (LLM01 → MITRE ATLAS)

**Rola:** CompTIA SecAI+ student  
**Potrzeba:** zobaczyć jak LLM01 Prompt Injection mapuje do MITRE ATLAS AML.T0051  
**Cel:** rozumieć zależności między frameworkami  

### Kryteria akceptacji
- `GET /api/v1/cross-references?sourceCode=LLM01:2025` zwraca powiązania
- Strona `/matrix` wyświetla tabelę OWASP ↔ MITRE ATLAS ↔ CompTIA
- RelationshipType: EQUIVALENT, RELATED, PARENT_CHILD, MAPS_TO

### Plan testów TDD

**Backend:**
- `CrossReferenceServiceSpec` — ZIO Test: query by sourceCode, empty result for unknown code
- `CrossRefRoutesSpec` — HTTP 200 dla znanych relacji, HTTP 200 z pustą listą dla nieznanych

**Frontend:**
- `MatrixTable.spec.tsx` — tabela renderuje się, komórki zawierają kody zagrożeń

---

## US-05 — Heatmapa STRIDE

**Rola:** security trainer  
**Potrzeba:** wyświetlić heatmapę STRIDE na projektorze  
**Cel:** wizualnie wyjaśnić pokrycie STRIDE na warsztatach  

### Kryteria akceptacji
- `GET /api/v1/stats/coverage` zwraca dane JSON dla heatmapy
- Strona `/coverage` wyświetla heatmapę (Recharts HeatMapChart)
- `GET /api/v1/stride-heatmap` wymaga JWT (HTTP 401 bez tokenu)
- Dane heatmapy cachowane w Redis (TTL 5 minut)

### Plan testów TDD

**Backend:**
```scala
object StrideCoverageServiceSpec extends ZIOSpecDefault:
  def spec = suite("StrideCoverageService")(
    test("should return coverage data for 6 STRIDE categories") {
      for
        service  <- ZIO.service[StrideCoverageService]
        coverage <- service.getCoverage
      yield assert(coverage.categories)(hasSize(equalTo(6)))
    },
    test("GET /api/v1/stride-heatmap without JWT returns 401") {
      for
        response <- ZIO.serviceWithZIO[TestServer](_.get("/api/v1/stride-heatmap"))
      yield assert(response.status)(equalTo(Status.Unauthorized))
    }
  ).provide(StrideCoverageService.live, TestServer.layer, TestDatabase.layer)
```

**Frontend:**
- `StrideHeatmap.spec.tsx` — Recharts renderuje się z danymi mock, 6 kategorii widocznych

**E2E:**
- `us05-heatmap.spec.ts` — zalogowany użytkownik widzi heatmapę /stride-heatmap

---

## US-06 — Globalne wyszukiwanie

**Rola:** pentester  
**Potrzeba:** wyszukać "deepfake" i znaleźć powiązane zagrożenia z obroną  
**Cel:** szybko złożyć checklistę testów dla klienta  

### Kryteria akceptacji
- `GET /api/v1/search?q=deepfake` zwraca wyniki z podświetlonymi fragmentami
- Minimalna długość query: 2 znaki, maksymalna: 200 znaków
- Wyniki zawierają threatId, title, fragment ze snippet highlight
- Strona `/search` z paskiem wyszukiwania w navbarze

### Plan testów TDD

**Backend:**
```scala
object SearchServiceSpec extends ZIOSpecDefault:
  def spec = suite("SearchService")(
    test("should return non-empty results for 'deepfake'") {
      for
        service <- ZIO.service[SearchService]
        results <- service.search("deepfake", page = 0, size = 10)
      yield assert(results.items)(isNonEmpty)
    },
    test("should reject query shorter than 2 chars") {
      for
        service <- ZIO.service[SearchService]
        result  <- service.search("a", page = 0, size = 10).exit
      yield assert(result)(fails(isSubtype[ValidationError](anything)))
    },
    test("should reject query longer than 200 chars") {
      for
        service <- ZIO.service[SearchService]
        result  <- service.search("a" * 201, page = 0, size = 10).exit
      yield assert(result)(fails(isSubtype[ValidationError](anything)))
    }
  ).provide(SearchService.live, TestDatabase.layer)
```

**Frontend:**
- `SearchResults.spec.tsx` — lista wyników renderuje się, highlight `<mark>` widoczny w snippetach

---

## US-07 — Eksport do CSV

**Rola:** team lead  
**Potrzeba:** wyeksportować przefiltrowaną listę zagrożeń do CSV  
**Cel:** włączyć ją do rejestru ryzyk  

### Kryteria akceptacji
- `GET /api/v1/export?format=csv&frameworkCode=LLM` zwraca plik CSV
- Content-Type: text/csv; charset=utf-8
- Pola CSV: ID, Code, Title, Severity, Category, OWASP_Ref
- CSV Injection prevention: QuoteMode.ALL (Apache Commons CSV lub Scala equivalent)

### Plan testów TDD

**Backend:**
```scala
object ExportServiceSpec extends ZIOSpecDefault:
  def spec = suite("ExportService")(
    test("should return CSV with correct Content-Type") {
      for
        response <- ZIO.serviceWithZIO[TestServer](
                      _.get("/api/v1/export?format=csv&frameworkCode=OWASP_WEB"))
      yield assert(response.status)(equalTo(Status.Ok)) &&
            assert(response.headers.get("Content-Type"))(isSome(containsString("text/csv")))
    },
    test("should quote all fields to prevent CSV injection") {
      for
        service <- ZIO.service[ExportService]
        csv     <- service.exportToCsv(List(threatWithFormulaTitle))
      yield assert(csv)(containsString("\"=FORMULA\""))
    }
  ).provide(ExportService.live, TestServer.layer, TestDatabase.layer)
```

**E2E:**
- `us07-export.spec.ts` — klik "Eksportuj CSV" pobiera plik, nagłówki CSV widoczne

---

## US-08 — Kill-Chain timeline MITRE ATLAS

**Rola:** developer  
**Potrzeba:** zobaczyć timeline Kill Chain MITRE ATLAS  
**Cel:** rozumieć na jakiej fazie ataku działa każda technika ATLAS  

### Kryteria akceptacji
- `GET /api/v1/threats?frameworkCode=MITRE_ATLAS` zwraca zagrożenia z fazą killchain
- Komponent `AtlasTimeline` wyświetla oś czasu (Recharts) faz: Reconnaissance → Impact
- Techniki ATLAS przypisane do faz kill-chain

### Plan testów TDD

**Backend:**
- `AtlasTimelineServiceSpec` — ZIO Test: pobieranie technik ATLAS z polem phase, sortowanie po fazie

**Frontend:**
- `AtlasTimeline.spec.tsx` — Recharts renderuje oś czasu, fazy widoczne jako etykiety osi X

---

## US-09 — Próbki kodu Scala (supply-chain attacks)

**Rola:** Scala developer  
**Potrzeba:** znaleźć próbki kodu dla ataków na łańcuch dostaw w Scala  
**Cel:** zaimplementować SCA w potoku Scala  

### Kryteria akceptacji
- `GET /api/v1/code-samples?language=SCALA` zwraca próbki w Scala
- Każda próbka ma: sampleType (ATTACK_DEMO/DEFENSE), frameworkHint ("ZIO 2 / sbt"), codeSnippet
- Próbki Scala dotyczące supply chain zawierają słowa kluczowe: sbt, dependency, artifact

### Plan testów TDD

**Backend:**
```scala
object CodeSampleServiceSpec extends ZIOSpecDefault:
  def spec = suite("CodeSampleService — Scala filter")(
    test("should return only Scala code samples when language=SCALA") {
      for
        service <- ZIO.service[CodeSampleService]
        samples <- service.getByLanguage("SCALA")
      yield assert(samples)(forall(s => assert(s.language)(equalTo("SCALA"))))
    },
    test("Scala supply-chain samples should contain sbt or artifact keywords") {
      for
        service <- ZIO.service[CodeSampleService]
        samples <- service.getByLanguageAndCategory("SCALA", "supply-chain")
      yield assert(samples)(forall(s =>
        assert(s.codeSnippet.toLowerCase)(
          containsString("sbt") || containsString("artifact") || containsString("dependency"))))
    }
  ).provide(CodeSampleService.live, TestDatabase.layer)
```

**Frontend:**
- `CodeSamplePanel.spec.tsx` — zakładka Scala aktywna pokazuje codeSnippet z flagą `lang-scala` dla Prism.js

---

## US-10 — Próbki kodu Lua (rate limiting / LLM DoS)

**Rola:** Lua/OpenResty developer  
**Potrzeba:** zobaczyć przykłady Lua dla rate limiting zapobiegającego LLM DoS  
**Cel:** skonfigurować guardrails NGINX dla proxy LLM API  

### Kryteria akceptacji
- `GET /api/v1/code-samples?language=LUA` zwraca próbki w Lua
- Próbki Lua dotyczące rate limiting zawierają: `ngx.sleep`, `redis`, `limit_req` lub `resty`
- frameworkHint: "OpenResty / NGINX Lua"

### Plan testów TDD

**Backend:**
```scala
object CodeSampleServiceSpec extends ZIOSpecDefault:
  def spec = suite("CodeSampleService — Lua filter")(
    test("should return only Lua code samples when language=LUA") {
      for
        service <- ZIO.service[CodeSampleService]
        samples <- service.getByLanguage("LUA")
      yield assert(samples)(forall(s => assert(s.language)(equalTo("LUA"))))
    },
    test("Lua rate-limiting samples should contain ngx or resty keywords") {
      for
        service <- ZIO.service[CodeSampleService]
        samples <- service.getByLanguageAndCategory("LUA", "rate-limiting")
      yield assert(samples)(forall(s =>
        assert(s.codeSnippet)(
          containsString("ngx") || containsString("resty") || containsString("redis"))))
    }
  ).provide(CodeSampleService.live, TestDatabase.layer)
```

---

## US-11 — Przełącznik języka PL ↔ EN

**Rola:** Polish-speaking student  
**Potrzeba:** przełączyć całą aplikację z angielskiego na polski jednym kliknięciem  
**Cel:** uczyć się opisów zagrożeń w ojczystym języku  

### Kryteria akceptacji
- Komponent `LanguageToggle` widoczny w navbarze (przyciski PL i EN)
- Kliknięcie PL: react-i18next zmienia język na 'pl' bez przeładowania strony
- Kliknięcie EN: zmienia język na 'en'
- Wybór persystowany w localStorage pod kluczem `ss_locale`
- Axios interceptor `LocaleInterceptor` wstrzykuje `Accept-Language: pl|en` do każdego żądania
- Próbki kodu NIGDY nie tłumaczone
- Parzystość kluczy pl.json / en.json weryfikowana w CI

### Plan testów TDD

**Backend:**
```scala
// LocalizationServiceSpec.scala
import zio.test._
import zio.test.Assertion._

object LocalizationServiceSpec extends ZIOSpecDefault:
  def spec = suite("LocalizationService")(
    test("should return Polish translation when locale is pl") {
      for
        service <- ZIO.service[LocalizationService]
        result  <- service.getTranslation(knownThreatId, "pl")
      yield assert(result.locale)(equalTo("pl")) &&
            assert(result.title)(not(isEmpty))
    },
    test("should fallback to English when Polish translation missing") {
      for
        service <- ZIO.service[LocalizationService]
        result  <- service.getTranslation(untranslatedThreatId, "pl")
      yield assert(result.locale)(equalTo("en"))
    },
    test("GET /api/v1/threats with Accept-Language: pl returns Polish descriptions") {
      for
        response <- ZIO.serviceWithZIO[TestServer](
                      _.get("/api/v1/threats/FREK", Map("Accept-Language" -> "pl")))
      yield assert(response.status)(equalTo(Status.Ok)) &&
            assert(response.bodyAs[CornucopiaCard].descriptionPl)(not(isEmpty))
    },
    test("Accept-Language header not in pl/en should default to en") {
      for
        response <- ZIO.serviceWithZIO[TestServer](
                      _.get("/api/v1/threats/FREK", Map("Accept-Language" -> "de")))
      yield assert(response.status)(equalTo(Status.Ok))
    }
  ).provide(LocalizationService.live, TestServer.layer, TestDatabase.layer)
```

**Frontend:**
```typescript
// LanguageToggle.spec.tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { LanguageToggle } from './LanguageToggle'
import i18n from '../i18n'

describe('LanguageToggle', () => {
  beforeEach(() => localStorage.clear())

  it('should change i18n language to "pl" when PL button clicked', async () => {
    render(<LanguageToggle />)
    await userEvent.click(screen.getByText('PL'))
    expect(i18n.language).toBe('pl')
  })

  it('should change i18n language to "en" when EN button clicked', async () => {
    render(<LanguageToggle />)
    await userEvent.click(screen.getByText('EN'))
    expect(i18n.language).toBe('en')
  })

  it('should persist locale to localStorage key ss_locale', async () => {
    render(<LanguageToggle />)
    await userEvent.click(screen.getByText('PL'))
    expect(localStorage.getItem('ss_locale')).toBe('pl')
  })

  it('should initialise from localStorage on mount', () => {
    localStorage.setItem('ss_locale', 'pl')
    render(<LanguageToggle />)
    expect(screen.getByText('PL')).toHaveAttribute('aria-pressed', 'true')
  })

  it('should not translate code snippet content', () => {
    render(<CodeSamplePanel samples={[mockAttackDemoSample]} />)
    const codeBlock = screen.getByRole('code')
    expect(codeBlock.textContent).toBe(mockAttackDemoSample.codeSnippet)
  })
})

// LocaleInterceptor.spec.ts
describe('LocaleInterceptor', () => {
  it('should add Accept-Language: pl when locale is pl', async () => {
    localStorage.setItem('ss_locale', 'pl')
    const intercepted = await captureRequest(axios.get('/api/v1/threats'))
    expect(intercepted.headers['Accept-Language']).toBe('pl')
  })

  it('should only emit pl or en — not arbitrary locale strings', async () => {
    localStorage.setItem('ss_locale', 'de') // invalid value
    const intercepted = await captureRequest(axios.get('/api/v1/threats'))
    expect(['pl', 'en']).toContain(intercepted.headers['Accept-Language'])
  })
})

// i18n-keys-parity.spec.ts
import plJson from '../../public/locales/pl/translation.json'
import enJson from '../../public/locales/en/translation.json'

describe('i18n key parity', () => {
  it('pl.json and en.json must have identical top-level keys', () => {
    const plKeys = Object.keys(plJson).sort()
    const enKeys = Object.keys(enJson).sort()
    expect(plKeys).toEqual(enKeys)
  })

  it('pl.json must have at least 50 keys', () => {
    expect(Object.keys(plJson).length).toBeGreaterThanOrEqual(50)
  })

  it('no i18n value should contain HTML tags', () => {
    const htmlTag = /<[^>]+>/
    Object.entries(plJson).forEach(([key, value]) => {
      expect(htmlTag.test(value as string), `key "${key}" contains HTML`).toBe(false)
    })
  })
})
```

**E2E:**
```typescript
// us11-language-switch.spec.ts
import { test, expect } from '@playwright/test'

test.describe('US-11 Language Switch', () => {
  test('switches UI to Polish when PL clicked', async ({ page }) => {
    await page.goto('/')
    await page.getByTestId('lang-toggle-pl').click()
    await expect(page.getByTestId('nav-frameworks')).toHaveText('Frameworki')
  })

  test('switches UI to English when EN clicked', async ({ page }) => {
    await page.goto('/')
    await page.getByTestId('lang-toggle-en').click()
    await expect(page.getByTestId('nav-frameworks')).toHaveText('Frameworks')
  })

  test('code samples are NOT translated', async ({ page }) => {
    await page.goto('/threats/LLM01-2025')
    const enCode = await page.getByTestId('code-snippet').first().textContent()
    await page.getByTestId('lang-toggle-pl').click()
    const plCode = await page.getByTestId('code-snippet').first().textContent()
    expect(plCode).toBe(enCode)
  })

  test('persists language after page reload', async ({ page }) => {
    await page.goto('/')
    await page.getByTestId('lang-toggle-pl').click()
    await page.reload()
    await expect(page.getByTestId('nav-frameworks')).toHaveText('Frameworki')
  })
})
```

---

## US-12 — Bezpieczeństwo frontend/client-side (karty FRE)

**Rola:** React/frontend developer  
**Potrzeba:** przeglądać karty OWASP Cornucopia FRE (DOM XSS, clickjacking, CORS, JWT forgery) z polskimi opisami i referencjami OWASP Client-Side Top 10  
**Cel:** mapować scenariusze ataków client-side na mitigacje w React  

### Polskie tłumaczenia kart FRE (z companion-cards-1.0-en.yaml)

| Karta | Wartość | Polskie tłumaczenie | OWASP ref |
|---|---|---|---|
| FRE4 | 4 | Ana może sfałszować token JWT lub sesję OAuth, wstrzykując złośliwe claimy z powodu braku weryfikacji sygnatury po stronie klienta | A02:2021, Client-Side C04 |
| FRE9 | 9 | Sam może zmienić prawa dostępu strony po stronie klienta (ukryte pola, parametry URL) z powodu braku walidacji server-side | A01:2021 |
| FREX | 10 | Carlos może przeprowadzić atak clickjacking na wrażliwe akcje (np. przelewy) z powodu braku nagłówków X-Frame-Options lub dyrektywy CSP frame-ancestors | Client-Side C05 |
| FREJ | J | Priya może wykonać atak DOM-based XSS przez manipulację document.location lub innerHTML bez użycia DOMPurify | A03:2021, Client-Side C03 |
| FREQ | Q | Marco może obejść zabezpieczenia CORS przez błędną konfigurację Access-Control-Allow-Origin: * zezwalającą każdemu origin | A05:2021 |
| FREK | K | Nikita może wstrzyknąć złośliwy skrypt przez Content-Type sniffing z powodu braku nagłówka X-Content-Type-Options: nosniff | Client-Side C07 |

### Kryteria akceptacji
- Strona `/frameworks/frontend-security` wyświetla 13 kart FRE
- Karty J, Q, K oznaczone badge `KRYTYCZNY`
- Opisy kart sanityzowane przez DOMPurify przed renderowaniem
- Każda karta pokazuje chipy OWASP referencji
- API: `GET /api/v1/threats?suit=FRE&lang=pl` zwraca polskie opisy

### Plan testów TDD

**Backend:**
```scala
// FrontendThreatServiceSpec.scala
object FrontendThreatServiceSpec extends ZIOSpecDefault:
  def spec = suite("FrontendThreatService")(
    test("should return exactly 13 FRE cards") {
      for
        service <- ZIO.service[CardSuitService]
        cards   <- service.getCardsBySuit("FRE")
      yield assert(cards)(hasSize(equalTo(13)))
    },
    test("should return Polish description when locale is pl") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("FREK", "pl")
      yield assert(card.description)(containsString("Content-Type")) &&
            assert(card.descriptionPl)(not(isEmpty))
    },
    test("should mark J, Q, K cards as isCritical=true") {
      for
        service   <- ZIO.service[CardSuitService]
        criticals <- service.getCardsBySuit("FRE")
                       .map(_.filter(c => List("J", "Q", "K").contains(c.value)))
      yield assert(criticals)(forall(c => assertTrue(c.isCritical)))
    },
    test("should include owaspRefs for each FRE card") {
      for
        service <- ZIO.service[CardSuitService]
        cards   <- service.getCardsBySuit("FRE")
      yield assert(cards)(forall(c => assert(c.owaspRefs)(isNonEmpty)))
    },
    test("GET /api/v1/threats?suit=FRE returns 200 with 13 cards") {
      for
        response <- ZIO.serviceWithZIO[TestServer](_.get("/api/v1/threats?suit=FRE"))
      yield assert(response.status)(equalTo(Status.Ok)) &&
            assert(response.bodyAs[PageResult[CornucopiaCard]].items)(hasSize(equalTo(13)))
    },
    test("GET /api/v1/threats/FREK returns isCritical=true") {
      for
        response <- ZIO.serviceWithZIO[TestServer](_.get("/api/v1/threats/FREK"))
        card      = response.bodyAs[CornucopiaCard]
      yield assertTrue(card.isCritical)
    }
  ).provide(CardSuitService.live, TestServer.layer, TestDatabase.layer)
```

**Frontend:**
```typescript
// FrontendSecurity.spec.tsx
import { render, screen } from '@testing-library/react'
import { http, HttpResponse } from 'msw'
import { server } from '../mocks/server'
import { FrontendSecurityPage } from './FrontendSecurityPage'

describe('FrontendSecurityPage', () => {
  it('should render a CornucopiaCard for each FRE card', async () => {
    render(<FrontendSecurityPage />)
    const cards = await screen.findAllByTestId('cornucopia-card')
    expect(cards).toHaveLength(13)
  })

  it('should show KRYTYCZNY badge on J, Q, K cards', async () => {
    render(<FrontendSecurityPage />)
    const badges = await screen.findAllByText('KRYTYCZNY')
    expect(badges.length).toBeGreaterThanOrEqual(3)
  })

  it('should sanitize descriptionPl with DOMPurify — strip <script>', () => {
    const maliciousCard = {
      ...mockFRECard,
      descriptionPl: '<script>alert("XSS")</script>Tekst bezpieczny',
    }
    render(<CornucopiaCard card={maliciousCard} locale="pl" />)
    expect(document.querySelector('script')).toBeNull()
    expect(screen.getByText('Tekst bezpieczny')).toBeInTheDocument()
  })

  it('should display OWASP ref chips on each card', async () => {
    render(<FrontendSecurityPage />)
    const chips = await screen.findAllByTestId('owasp-ref-chip')
    expect(chips.length).toBeGreaterThan(0)
  })

  it('navigates to /threats/:cardId on card click', async () => {
    const { router } = renderWithRouter(<FrontendSecurityPage />)
    const firstCard = await screen.findByTestId('cornucopia-card-FRE2')
    await userEvent.click(firstCard)
    expect(router.state.location.pathname).toBe('/threats/FRE2')
  })
})
```

**E2E:**
```typescript
// us12-frontend-security.spec.ts
test.describe('US-12 Frontend Security Cards', () => {
  test('shows 13 FRE cards on /frameworks/frontend-security', async ({ page }) => {
    await page.goto('/frameworks/frontend-security')
    await expect(page.getByTestId('cornucopia-card')).toHaveCount(13)
  })

  test('shows Polish descriptions when locale=pl', async ({ page }) => {
    await page.goto('/')
    await page.getByTestId('lang-toggle-pl').click()
    await page.goto('/frameworks/frontend-security')
    const firstDesc = await page.getByTestId('card-description').first().textContent()
    expect(firstDesc).not.toBeNull()
  })

  test('FREK card shows KRYTYCZNY badge', async ({ page }) => {
    await page.goto('/frameworks/frontend-security')
    await expect(page.getByTestId('critical-badge-FREK')).toBeVisible()
  })
})
```

---

## US-13 — Bezpieczeństwo LLM (karty LLM + macierz)

**Rola:** ML engineer / AI architect  
**Potrzeba:** eksplorować wszystkie 10 zagrożeń OWASP LLM Top 10 2025 przez karty Cornucopia LLM z interaktywną macierzą  
**Cel:** rozumieć prompt injection, data poisoning, excessive agency w systemach LLM  

### Polskie tłumaczenia kart LLM (z companion-cards-1.0-en.yaml)

| Karta | Wartość | Polskie tłumaczenie | OWASP LLM ref |
|---|---|---|---|
| LLM2 | 2 | Samantha może wyczerpać zasoby obliczeniowe przez rekurencyjne zapytania LLM, prowadząc do niedostępności modelu (Model DoS) | LLM10:2025 Unbounded Consumption |
| LLM3 | 3 | Dave może wykorzystać nadmierne poleganie na wynikach LLM bez ludzkiego nadzoru, podejmując błędne decyzje na podstawie halucynacji | LLM09:2025 Misinformation |
| LLM4 | 4 | David może skłonić model do ujawnienia wrażliwych danych z treningu, promptów systemowych lub kontekstu innych użytkowników przez niewystarczające filtrowanie wyjść | LLM06:2025 Sensitive Information Disclosure |
| LLM7 | 7 | Tyrell może zatruć dane treningowe lub fine-tuning datasets, wprowadzając backdoor do modelu aktywowany specjalnym triggerem | LLM04:2025 Data and Model Poisoning, MITRE ATLAS T0020 |
| LLMX | 10 | Sarah może nadpisać lub zmanipulować prompty systemowe przez spreparowane wejście, powodując ignorowanie przez model swoich ograniczeń | LLM01:2025 Prompt Injection |
| LLMJ | J | Ripley może wprowadzić skompromitowany model, embedding lub złośliwy komponent ML do łańcucha dostaw, prowadząc do ukrytych podatności | LLM03:2025 Supply Chain |
| LLMK | K | Ava może wykorzystać nadmierną autonomię pluginów lub agentów AI do wykonania nieautoryzowanych działań z powodu braku human-in-the-loop | LLM06:2025 Excessive Agency → AgentAI |

### Kryteria akceptacji
- Strona `/frameworks/llm-security` wyświetla 13 kart LLM z polskimi opisami
- Strona `/matrix/llm` wyświetla macierz LLM Top 10 × karty Cornucopia (10 wierszy)
- `GET /api/v1/matrix/llm` zwraca JSON z mapowaniem LLM01–LLM10 → lista cardId
- LLMK oznaczony badge `KRYTYCZNY`

### Plan testów TDD

**Backend:**
```scala
object LlmThreatServiceSpec extends ZIOSpecDefault:
  def spec = suite("LlmThreatService")(
    test("should return 13 LLM cards") {
      for
        service <- ZIO.service[CardSuitService]
        cards   <- service.getCardsBySuit("LLM")
      yield assert(cards)(hasSize(equalTo(13)))
    },
    test("LLMX should have owaspRefs containing LLM01:2025") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("LLMX", "en")
      yield assert(card.owaspRefs)(contains("LLM01:2025"))
    },
    test("LLM7 should have mitreRefs containing MITRE ATLAS T0020") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("LLM7", "en")
      yield assert(card.mitreRefs)(contains("MITRE ATLAS T0020"))
    },
    test("GET /api/v1/matrix/llm returns 10-entry mapping") {
      for
        response <- ZIO.serviceWithZIO[TestServer](_.get("/api/v1/matrix/llm"))
        body      = response.bodyAs[LlmMatrix]
      yield assert(response.status)(equalTo(Status.Ok)) &&
            assert(body.rows)(hasSize(equalTo(10)))
    },
    test("should translate LLM card descriptions to Polish when locale=pl") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("LLM2", "pl")
      yield assert(card.descriptionPl)(containsString("zasoby obliczeniowe"))
    }
  ).provide(CardSuitService.live, MatrixService.live, TestServer.layer, TestDatabase.layer)
```

**Frontend:**
```typescript
// LlmMatrix.spec.tsx
describe('LlmMatrixComponent', () => {
  it('should render 10 rows for LLM01–LLM10', async () => {
    render(<LlmMatrix />)
    const rows = await screen.findAllByTestId('llm-matrix-row')
    expect(rows).toHaveLength(10)
  })

  it('should show card IDs in matrix cells', async () => {
    render(<LlmMatrix />)
    await screen.findByText('LLMX')
  })

  it('should highlight critical K-value cards in red', async () => {
    render(<LlmMatrix />)
    const llmkCell = await screen.findByTestId('matrix-cell-LLMK')
    expect(llmkCell).toHaveClass('critical-cell')
  })
})
```

**E2E:**
```typescript
// us13-llm-security.spec.ts
test.describe('US-13 LLM Security', () => {
  test('shows 13 cards on /frameworks/llm-security', async ({ page }) => {
    await page.goto('/frameworks/llm-security')
    await expect(page.getByTestId('cornucopia-card')).toHaveCount(13)
  })

  test('/matrix/llm shows 10 LLM Top 10 rows', async ({ page }) => {
    await page.goto('/matrix/llm')
    await expect(page.getByTestId('llm-matrix-row')).toHaveCount(10)
  })
})
```

---

## US-14 — Agentic AI (karty AAI)

**Rola:** agentic AI developer  
**Potrzeba:** studiować zagrożenia OWASP Agentic AI Top 10 2026 przez karty AAI (excessive autonomy, unvalidated trust chains, orchestration manipulation)  
**Cel:** projektować human-in-the-loop safeguards dla autonomous agent pipelines  

### Polskie tłumaczenia kart AAI

| Karta | Wartość | Polskie tłumaczenie | AgentAI ref |
|---|---|---|---|
| AAIK | K | Agent może wykonać nieautoryzowane, wysokoryzykowne działania z powodu nadmiernej autonomii i braku wymagania zatwierdzenia przez człowieka (human-in-the-loop) | AgentAI07 Excessive Autonomy |
| AAIJ | J | Attacker może skłonić agenta do ujawnienia lub zmodyfikowania wrażliwych danych z powodu niewalidowanego łańcucha zaufania między agentami | AgentAI10 Inadequate Identity Verification |
| AAIQ | Q | Agent może zostać skłoniony do pominięcia bezpiecznych domyślnych konfiguracji przez zmanipulowany wstrzyknięty cel (manipulacja orkiestracją) | AgentAI09 Orchestration Manipulation |

### Kryteria akceptacji
- Strona `/frameworks/agentic-ai` wyświetla karty AAI
- Karty AAIK i AAIQ oznaczone badge `RYZYKO AUTONOMII`
- Strona `/matrix/agentic` wyświetla porównanie Agentic AI × LLM Top 10
- `GET /api/v1/threats?suit=AAI` zwraca 13 kart

### Plan testów TDD

**Backend:**
```scala
object AgenticAiServiceSpec extends ZIOSpecDefault:
  def spec = suite("AgenticAiService")(
    test("AAIK should have agentAiRefs containing AgentAI07") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("AAIK", "en")
      yield assert(card.agentAiRefs)(contains("AgentAI07"))
    },
    test("isCritical should be true for King card AAIK") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("AAIK", "en")
      yield assertTrue(card.isCritical)
    },
    test("AAIK Polish description mentions human-in-the-loop") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("AAIK", "pl")
      yield assert(card.descriptionPl)(containsString("human-in-the-loop") ||
                                       containsString("zatwierdzenia"))
    },
    test("GET /api/v1/threats?suit=AAI returns 13 cards") {
      for
        response <- ZIO.serviceWithZIO[TestServer](_.get("/api/v1/threats?suit=AAI"))
      yield assert(response.status)(equalTo(Status.Ok)) &&
            assert(response.bodyAs[PageResult[CornucopiaCard]].items)(hasSize(equalTo(13)))
    }
  ).provide(CardSuitService.live, TestServer.layer, TestDatabase.layer)
```

**Frontend:**
```typescript
// AgenticAi.spec.tsx
describe('AgenticAiPage', () => {
  it('should show RYZYKO AUTONOMII badge on AAIK card', async () => {
    render(<AgenticAiPage />)
    const badge = await screen.findByTestId('autonomy-risk-badge-AAIK')
    expect(badge).toBeInTheDocument()
  })

  it('should show AgentAI ref chip on each card', async () => {
    render(<AgenticAiPage />)
    const chips = await screen.findAllByTestId('agentai-ref-chip')
    expect(chips.length).toBeGreaterThan(0)
  })
})
```

**E2E:** `us14-agentic-ai.spec.ts`

---

## US-15 — STRIDE EoP — katalog i heatmapa

**Rola:** security architect / threat modeler  
**Potrzeba:** używać katalogu kart STRIDE EoP (Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege) z interaktywną heatmapą per komponent systemu  
**Cel:** prowadzić ustrukturyzowaną sesję threat modelingu i mapować wyniki do OWASP Web Top 10  

### Polskie tłumaczenia kart STRIDE EoP (z STRIDE__eop-cards-5.0-en.yaml)

| Karta | STRIDE | Polskie tłumaczenie | OWASP ref |
|---|---|---|---|
| SPK | S — Spoofing | System dostarcza domyślne hasło admina i nie wymusza jego zmiany przy pierwszym logowaniu | A07:2021 |
| TAK | T — Tampering | Aplikacja podejmuje decyzje o kontroli dostępu w wielu miejscach kodu zamiast przez centralny kernel bezpieczeństwa | A01:2021 |
| REK | R — Repudiation | Logi systemowe nie są niemodyfikowalne i mogą zostać usunięte przez atakującego, który uzyska dostęp do systemu plików | A09:2021 |
| IDK | I — Information Disclosure | Attacker może uzyskać dostęp do danych wrażliwych (klucze prywatne, hasła) zapisanych w pamięci procesu | A02:2021 |
| DSK | D — Denial of Service | Attacker może amplifikować atak DoS wysyłając małe zapytanie, które wywołuje bardzo dużą odpowiedź serwera | — |
| EPK | E — Elevation of Privilege | Attacker może uzyskać prawa administratora przez SQL injection w niesanowanym zapytaniu do bazy danych | A01:2021 + A03:2021 |

### Kryteria akceptacji
- Strona `/frameworks/stride` wyświetla 6 suit po 13 kart każda (78 kart łącznie)
- Strona `/stride-heatmap` wymaga JWT (redirect do /login bez tokenu)
- `X-Frame-Options: DENY` na endpointach `/stride-heatmap`
- Heatmapa Recharts pokazuje procenty pokrycia per komponent systemu × kategoria STRIDE

### Plan testów TDD

**Backend:**
```scala
object StrideThreatServiceSpec extends ZIOSpecDefault:
  def spec = suite("StrideThreatService")(
    test("should return 6 STRIDE categories with correct codes") {
      for
        service    <- ZIO.service[StrideThreatService]
        categories <- service.getStrideCategories
      yield assert(categories.map(_.code))(
        hasSameElements(List("SP", "TA", "RE", "ID", "DS", "EP")))
    },
    test("each STRIDE suit should have exactly 13 cards") {
      for
        service <- ZIO.service[StrideThreatService]
        all     <- ZIO.foreach(List("SP","TA","RE","ID","DS","EP"))(suit =>
                     service.getCardsBySuit(suit))
      yield assert(all)(forall(cards => assert(cards)(hasSize(equalTo(13)))))
    },
    test("GET /api/v1/stride-heatmap without JWT returns 401") {
      for
        response <- ZIO.serviceWithZIO[TestServer](_.get("/api/v1/stride-heatmap"))
      yield assert(response.status)(equalTo(Status.Unauthorized))
    },
    test("GET /api/v1/stride-heatmap with valid JWT returns 200") {
      for
        token    <- ZIO.service[JwtService].flatMap(_.generateToken("user1", List("USER")))
        response <- ZIO.serviceWithZIO[TestServer](
                      _.get("/api/v1/stride-heatmap",
                            Map("Authorization" -> s"Bearer $token")))
      yield assert(response.status)(equalTo(Status.Ok))
    },
    test("stride-heatmap response has X-Frame-Options: DENY header") {
      for
        token    <- ZIO.service[JwtService].flatMap(_.generateToken("u", List("USER")))
        response <- ZIO.serviceWithZIO[TestServer](
                      _.get("/api/v1/stride-heatmap",
                            Map("Authorization" -> s"Bearer $token")))
      yield assert(response.headers.get("X-Frame-Options"))(isSome(equalTo("DENY")))
    }
  ).provide(StrideThreatService.live, JwtService.live, TestServer.layer, TestDatabase.layer)
```

**Frontend:**
```typescript
// StrideHeatmap.spec.tsx
describe('StrideHeatmapComponent', () => {
  it('renders Recharts HeatMap with 6 STRIDE categories on Y axis', async () => {
    render(<StrideHeatmap data={mockHeatmapData} />)
    const labels = screen.getAllByTestId('stride-category-label')
    expect(labels.map(l => l.textContent)).toEqual(
      expect.arrayContaining(['S', 'T', 'R', 'I', 'D', 'E'])
    )
  })

  it('redirects to /login when user is not authenticated', async () => {
    const { router } = renderWithRouter(<PrivateRoute><StrideHeatmapPage /></PrivateRoute>)
    expect(router.state.location.pathname).toBe('/login')
  })
})
```

**E2E:**
```typescript
// us15-stride.spec.ts
test.describe('US-15 STRIDE Catalogue + Heatmap', () => {
  test('stride catalogue shows 6 sections', async ({ page }) => {
    await page.goto('/frameworks/stride')
    await expect(page.getByTestId('stride-section')).toHaveCount(6)
  })

  test('redirects to /login when visiting /stride-heatmap unauthenticated', async ({ page }) => {
    await page.goto('/stride-heatmap')
    await expect(page).toHaveURL(/\/login/)
  })
})
```

---

## US-16 — Bezpieczeństwo ML (karty MLSec)

**Rola:** data scientist / ML security engineer  
**Potrzeba:** przeglądać ryzyka ML (Model Risk, Input Risk, Output Risk, Dataset Risk) z referencjami MITRE ATLAS  
**Cel:** identyfikować adversarial ML attacks, model theft, data poisoning, output manipulation  

### Polskie tłumaczenia kart MLSec (z RISKS__elevation-of-mlsec-cards-1.0-en.yaml)

| Karta | Suit | Polskie tłumaczenie | MITRE ATLAS ref |
|---|---|---|---|
| EMRX | EMR — Model Risk | Attacker może wykraść model przez wielokrotne zapytania do API, odtwarzając jego parametry (model extraction/theft) | T0010 Model Theft |
| EIRK | EIR — Input Risk | Attacker może przeprowadzić atak adversarial na model, podając spreparowane dane wejściowe powodujące błędną klasyfikację | T0044 Craft Adversarial Data, LLM01:2025 |
| EDRK | EDR — Dataset Risk | Attacker może zaindukować backdoor w modelu przez zatrucie danych treningowych — aktywowany przez specjalny trigger wejściowy | T0014 Data Poisoning, LLM04:2025 |
| EORK | EOR — Output Risk | Attacker może uzyskać wrażliwe dane (PII) przez atak membership inference lub model inversion na wyjściach modelu | T0011 Model Inversion, LLM06:2025 |

### Kryteria akceptacji
- Strona `/frameworks/ml-security` wyświetla 4 suit MLSec (EMR, EIR, EOR, EDR)
- Każda karta MLSec oznaczona badge `ML-SPECIFIC`
- `GET /api/v1/threats/mlsec/categories` zwraca 4 kategorie
- Chipy MITRE ATLAS widoczne na kartach

### Plan testów TDD

**Backend:**
```scala
object MlSecServiceSpec extends ZIOSpecDefault:
  def spec = suite("MlSecThreatService")(
    test("should return 4 MLSec categories: EMR, EIR, EOR, EDR") {
      for
        service    <- ZIO.service[MlSecThreatService]
        categories <- service.getMlSecCategories
      yield assert(categories.map(_.code))(
        hasSameElements(List("EMR", "EIR", "EOR", "EDR")))
    },
    test("EDRK should have mitreRefs containing MITRE ATLAS T0014") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("EDRK", "en")
      yield assert(card.mitreRefs)(contains("MITRE ATLAS T0014"))
    },
    test("EDRK should have owaspRefs containing LLM04:2025") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("EDRK", "en")
      yield assert(card.owaspRefs)(contains("LLM04:2025"))
    },
    test("MitreAtlasRefValidator should accept T0010") {
      for
        validator <- ZIO.service[MitreAtlasRefValidator]
        result    <- validator.validate("MITRE ATLAS T0010").either
      yield assert(result)(isRight(anything))
    },
    test("MitreAtlasRefValidator should reject unknown T9999") {
      for
        validator <- ZIO.service[MitreAtlasRefValidator]
        result    <- validator.validate("MITRE ATLAS T9999").either
      yield assert(result)(isLeft(anything))
    }
  ).provide(MlSecThreatService.live, CardSuitService.live,
            MitreAtlasRefValidator.live, TestDatabase.layer)
```

**Frontend:**
```typescript
// MlSecurity.spec.tsx
describe('MlSecurityPage', () => {
  it('shows 4 suit sections: EMR, EIR, EOR, EDR', async () => {
    render(<MlSecurityPage />)
    await screen.findByTestId('suit-section-EMR')
    await screen.findByTestId('suit-section-EIR')
    await screen.findByTestId('suit-section-EOR')
    await screen.findByTestId('suit-section-EDR')
  })

  it('shows ML-SPECIFIC badge on every MLSec card', async () => {
    render(<MlSecurityPage />)
    const badges = await screen.findAllByTestId('ml-specific-badge')
    expect(badges.length).toBeGreaterThan(0)
  })

  it('shows MITRE ATLAS ref chips', async () => {
    render(<MlSecurityPage />)
    const chips = await screen.findAllByTestId('mitre-ref-chip')
    expect(chips.length).toBeGreaterThan(0)
  })
})
```

**E2E:** `us16-ml-security.spec.ts`

---

## US-17 — Bezpieczeństwo mobile (karty Mobile MAS)

**Rola:** Android/iOS developer  
**Potrzeba:** przeglądać zagrożenia OWASP MASVS przez karty Cornucopia Mobile App (TLS verification, jailbreak detection, hardcoded keys, IPC security) + tabelę MASVS vs Web  
**Cel:** rozumieć jak kontrolki bezpieczeństwa mobile różnią się od web i zastosować wymagania MASVS  

### Polskie tłumaczenia kart Mobile MAS (z mobileapp-cards-1.1-en.yaml)

| Karta | Suit | Polskie tłumaczenie | MASVS ref |
|---|---|---|---|
| NSX | NS — Network & Storage | Attacker może przechwycić ruch TLS z powodu braku certificate pinning lub błędnej weryfikacji certyfikatu (np. zaufanie do self-signed) | MASVS-NETWORK-2 |
| RSX | RS — Resilience | Attacker może ominąć zabezpieczenia aplikacji przez jailbreak lub root detection bypass — jeśli nie wdrożono odpowiedniej obrony przed ingerencją | MASVS-RESILIENCE-4 |
| CRM6 | CRM — Crypto & Risk | Developer może przypadkowo umieścić klucze kryptograficzne w kodzie aplikacji (hardcoded keys), gdzie są łatwo dostępne przez dekompilację lub reverse engineering | MASVS-CRYPTO-1, A02:2021 |
| AAK | AA — Authentication & Auth | Attacker może ominąć autentykację aplikacji mobilnej jeśli brak jest poprawnej implementacji biometrycznego uwierzytelnienia lub fallback do PIN jest niebezpieczny | MASVS-AUTH-2, A07:2021 |

### Kryteria akceptacji
- Strona `/frameworks/mobile-security` wyświetla 6 suit Mobile (PC, AA, NS, RS, CRM, CM)
- Strona `/matrix/mobile-vs-web` wyświetla porównanie MASVS vs OWASP Web Top 10
- `GET /api/v1/threats/mobile/suits` zwraca 6 suit
- Chipy MASVS referencji widoczne na kartach

### Plan testów TDD

**Backend:**
```scala
object MobileSecServiceSpec extends ZIOSpecDefault:
  def spec = suite("MobileSecThreatService")(
    test("should load 6 mobile suits") {
      for
        service <- ZIO.service[MobileSecThreatService]
        suits   <- service.getMobileSuits
      yield assert(suits.map(_.code))(
        hasSameElements(List("PC", "AA", "NS", "RS", "CRM", "CM")))
    },
    test("NSX should have mavsRefs containing MASVS-NETWORK-2") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("NSX", "en")
      yield assert(card.mavsRefs)(contains("MASVS-NETWORK-2"))
    },
    test("MavsRefValidator should accept MASVS-NETWORK-2") {
      for
        validator <- ZIO.service[MavsRefValidator]
        result    <- validator.validate("MASVS-NETWORK-2").either
      yield assert(result)(isRight(anything))
    },
    test("MavsRefValidator should reject MASVS-CUSTOM-99") {
      for
        validator <- ZIO.service[MavsRefValidator]
        result    <- validator.validate("MASVS-CUSTOM-99").either
      yield assert(result)(isLeft(anything))
    },
    test("GET /api/v1/matrix/mobile-vs-web returns comparison table") {
      for
        response <- ZIO.serviceWithZIO[TestServer](_.get("/api/v1/matrix/mobile-vs-web"))
      yield assert(response.status)(equalTo(Status.Ok))
    }
  ).provide(MobileSecThreatService.live, CardSuitService.live,
            MavsRefValidator.live, TestServer.layer, TestDatabase.layer)
```

**Frontend:**
```typescript
// MobileSecurity.spec.tsx
describe('MobileSecurityPage', () => {
  it('shows 6 suit sections', async () => {
    render(<MobileSecurityPage />)
    const sections = await screen.findAllByTestId('mobile-suit-section')
    expect(sections).toHaveLength(6)
  })

  it('shows MASVS ref chips on cards', async () => {
    render(<MobileSecurityPage />)
    const chips = await screen.findAllByTestId('mavs-ref-chip')
    expect(chips.length).toBeGreaterThan(0)
  })
})

// MobileVsWebMatrix.spec.tsx
describe('MobileVsWebMatrix', () => {
  it('renders comparison table with MASVS and OWASP rows', async () => {
    render(<MobileVsWebMatrix />)
    await screen.findByText('MASVS-NETWORK-2')
    await screen.findByText('A02:2021')
  })
})
```

**E2E:** `us17-mobile-security.spec.ts`

---

## US-18 — Bezpieczeństwo DevOps (karty DVO + BOT)

**Rola:** DevSecOps engineer / team lead  
**Potrzeba:** przeglądać ryzyka supply chain (DVO cards) i wzorce automatycznych ataków (BOT cards) z referencjami OWASP CI/CD Security Risk i mitigacjami rate limiting  
**Cel:** chronić potoki CI/CD, walidować integralność artefaktów i bronić się przed botami  

### Polskie tłumaczenia kart DVO + BOT (z companion-cards-1.0-en.yaml)

| Karta | Suit | Polskie tłumaczenie | CICD-SEC / OAT ref |
|---|---|---|---|
| DVOK | DVO — DevOps | Attacker może wstrzyknąć złośliwy kod do procesu CI/CD przez skompromitowany package dependency (supply chain attack na repozytorium zależności) | CICD-SEC-03, A06:2021 |
| DVO8 | DVO | Attacker może zmodyfikować artefakt buildowania między etapem kompilacji a wdrożenia (pipeline poisoning — podmiana pliku .jar/.war) | CICD-SEC-09, A08:2021 |
| BOTK | BOT — Automated Threats | Attacker może skrapować całą bazę wiedzy aplikacji przez zautomatyzowane, systematyczne zapytania HTTP imitujące zachowanie ludzkiego użytkownika | OAT-011 Scraping |
| BOTX | BOT | Attacker może przeprowadzić atak credential stuffing — testując na dużą skalę wykradzione pary login/hasło przez zautomatyzowane skrypty | OAT-008 Credential Cracking |

### Kryteria akceptacji
- Strona `/frameworks/devops-security` zawiera sekcje DVO i BOT
- Kliknięcie krytycznej karty BOT (BOTK, BOTX) otwiera modal ostrzeżenia
- `GET /api/v1/threats?suit=BOT` jest rate-limited (429 po > 60 req/min per IP)
- Przykłady kodu DVO to TYLKO pseudokod — żadnych działających exploitów pipeline
- `GET /api/v1/threats?suit=DVO` zwraca 13 kart z CICD-SEC ref chips

### Plan testów TDD

**Backend:**
```scala
object DevOpsThreatServiceSpec extends ZIOSpecDefault:
  def spec = suite("DevOpsThreatService")(
    test("DVOK should have cicdSecRefs containing CICD-SEC-03") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("DVOK", "en")
      yield assert(card.cicdSecRefs)(contains("CICD-SEC-03"))
    },
    test("BOTK should have oatRefs containing OAT-011") {
      for
        service <- ZIO.service[CardSuitService]
        card    <- service.getCardById("BOTK", "en")
      yield assert(card.oatRefs)(contains("OAT-011"))
    },
    test("CicdSecRefValidator should accept CICD-SEC-03") {
      for
        validator <- ZIO.service[CicdSecRefValidator]
        result    <- validator.validate("CICD-SEC-03").either
      yield assert(result)(isRight(anything))
    },
    test("OatRefValidator should reject unknown OAT-999") {
      for
        validator <- ZIO.service[OatRefValidator]
        result    <- validator.validate("OAT-999").either
      yield assert(result)(isLeft(anything))
    }
  ).provide(CardSuitService.live, CicdSecRefValidator.live,
            OatRefValidator.live, TestDatabase.layer)

object RateLimitMiddlewareSpec extends ZIOSpecDefault:
  def spec = suite("RateLimitMiddleware")(
    test("should allow first 60 requests within one minute") {
      for
        server  <- ZIO.service[TestServer]
        results <- ZIO.foreach((1 to 60).toList)(_ => server.get("/api/v1/threats?suit=BOT"))
      yield assert(results)(forall(r => assert(r.status)(equalTo(Status.Ok))))
    },
    test("should return 429 on request 61 within one minute") {
      for
        server  <- ZIO.service[TestServer]
        _       <- ZIO.foreach((1 to 60).toList)(_ => server.get("/api/v1/threats?suit=BOT"))
        last    <- server.get("/api/v1/threats?suit=BOT")
      yield assert(last.status)(equalTo(Status.TooManyRequests)) &&
            assert(last.headers.get("Retry-After"))(isSome)
    },
    test("ContentIntegrityVerifier should throw on tampered YAML hash") {
      for
        verifier <- ZIO.service[ContentIntegrityVerifier]
        result   <- verifier.verifyFile(
                      Path.of("test-tampered.yaml"), "incorrect-hash").either
      yield assert(result)(isLeft(isSubtype[ContentIntegrityException](anything)))
    }
  ).provide(RateLimitMiddleware.live, ContentIntegrityVerifier.live, TestServer.layer)
```

**Frontend:**
```typescript
// DevOpsSecurity.spec.tsx
describe('DevOpsSecurityPage', () => {
  it('shows DVO section with CI/CD cards', async () => {
    render(<DevOpsSecurityPage />)
    await screen.findByTestId('dvo-section')
  })

  it('shows BOT section with Automated Threats cards', async () => {
    render(<DevOpsSecurityPage />)
    await screen.findByTestId('bot-section')
  })

  it('shows CICD-SEC ref chips on DVO cards', async () => {
    render(<DevOpsSecurityPage />)
    const chips = await screen.findAllByTestId('cicd-sec-ref-chip')
    expect(chips.length).toBeGreaterThan(0)
  })

  it('shows OAT ref chips on BOT cards', async () => {
    render(<DevOpsSecurityPage />)
    const chips = await screen.findAllByTestId('oat-ref-chip')
    expect(chips.length).toBeGreaterThan(0)
  })
})

// BotWarningModal.spec.tsx
describe('BotWarningModal', () => {
  it('opens warning modal on BOTK card click', async () => {
    render(<DevOpsSecurityPage />)
    await userEvent.click(await screen.findByTestId('bot-card-BOTK'))
    expect(screen.getByRole('dialog')).toBeInTheDocument()
    expect(screen.getByText(/Rozumiem ryzyko/i)).toBeInTheDocument()
  })

  it('does NOT navigate without modal confirmation', async () => {
    const { router } = renderWithRouter(<DevOpsSecurityPage />)
    await userEvent.click(await screen.findByTestId('bot-card-BOTK'))
    await userEvent.click(screen.getByText(/Anuluj/i))
    expect(router.state.location.pathname).not.toContain('/threats/BOTK')
  })

  it('navigates to threat detail after confirmation', async () => {
    const { router } = renderWithRouter(<DevOpsSecurityPage />)
    await userEvent.click(await screen.findByTestId('bot-card-BOTK'))
    await userEvent.click(screen.getByText(/Rozumiem ryzyko/i))
    expect(router.state.location.pathname).toBe('/threats/BOTK')
  })

  it('sets bot_warning_ack in localStorage after confirmation', async () => {
    renderWithRouter(<DevOpsSecurityPage />)
    await userEvent.click(await screen.findByTestId('bot-card-BOTK'))
    await userEvent.click(screen.getByText(/Rozumiem ryzyko/i))
    expect(localStorage.getItem('bot_warning_ack')).toBe('true')
  })
})
```

**E2E:**
```typescript
// us18-devops-security.spec.ts
test.describe('US-18 DevOps Security', () => {
  test('shows DVO and BOT sections on /frameworks/devops-security', async ({ page }) => {
    await page.goto('/frameworks/devops-security')
    await expect(page.getByTestId('dvo-section')).toBeVisible()
    await expect(page.getByTestId('bot-section')).toBeVisible()
  })

  test('BOT critical card opens warning modal', async ({ page }) => {
    await page.goto('/frameworks/devops-security')
    await page.getByTestId('bot-card-BOTK').click()
    await expect(page.getByRole('dialog')).toBeVisible()
    await expect(page.getByText(/Rozumiem ryzyko/i)).toBeVisible()
  })

  test('cancelling modal does not navigate away', async ({ page }) => {
    await page.goto('/frameworks/devops-security')
    await page.getByTestId('bot-card-BOTK').click()
    await page.getByText(/Anuluj/i).click()
    await expect(page).toHaveURL(/frameworks\/devops-security/)
  })

  test('API /api/v1/threats?suit=BOT returns 429 after rate limit', async ({ request }) => {
    for (let i = 0; i < 61; i++) {
      const response = await request.get('/api/v1/threats?suit=BOT')
      if (i === 60) {
        expect(response.status()).toBe(429)
        expect(response.headers()['retry-after']).toBeDefined()
      }
    }
  })
})
```

---

## US-19 — Digital-by-Default Harms (karty SCO/ARC/AGE/TRU/POR)

**Rola:** product owner / GRC reviewer w sektorze publicznym
**Potrzeba:** przeglądać talię "Digital-by-Default Harms" (`dbd-cards-1.0-en.yaml`) z polskimi tłumaczeniami, jasno odróżnioną od talii technicznych podatności
**Cel:** ocenić ryzyko wykluczenia cyfrowego i nieprzejrzystego projektowania usługi publicznej oraz zmapować je na OWASP A04:2021 Insecure Design

### Polskie tłumaczenia kart SCO/ARC (z dbd-cards-1.0-en.yaml)

| Karta | Suit | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|---|
| SCO2 | SCO — Scope | "Tommy does not create, publish and maintain publicly all the service assumptions, specifications, constraints, source code, algorithms, formulas, configuration settings, operating instructions and processes" | *"Tommy nie tworzy, nie publikuje i nie utrzymuje publicznie wszystkich założeń usługi, specyfikacji, ograniczeń, kodu źródłowego, algorytmów, formuł, ustawień konfiguracyjnych, instrukcji działania i procesów"* | **OWASP A04:2021 Insecure Design** — brak transparentności projektowej; w ujęciu SecAI+/GRC odpowiada wymogom wyjaśnialności algorytmów (AI Act, art. 13) |
| SCO3 | SCO | "Charlotte designs the service so that claimants themselves have to generate/enter data about personal activities (e.g. job search) or obtain/enter existing data from elsewhere (e.g. care/health services, education providers)" | *"Charlotte projektuje usługę tak, że osoby z niej korzystające muszą samodzielnie generować/wprowadzać dane o swoich działaniach osobistych (np. poszukiwaniu pracy) lub zdobywać/wprowadzać dane już istniejące gdzie indziej (np. z opieki zdrowotnej, edukacji)"* | **A04:2021 Insecure Design** (odwrócona zasada data minimization — usługa domaga się więcej danych niż potrzebne od najsłabszego ogniwa, obywatela) |
| SCO4 | SCO | "Sofia undertakes features which require claimants to provide information repeatedly or which is already held (e.g. address, other welfare benefits awarded, tax code)" | *"Sofia wdraża funkcje wymagające od osób korzystających z usługi ponownego podawania informacji, które już są w posiadaniu systemu (np. adres, inne przyznane świadczenia, kod podatkowy)"* | Naruszenie zasady **"collect once"** i minimalizacji danych (RODO art. 5); klasyfikowane pod **A04:2021**, nie jako podatność techniczna |
| ARC2 | ARC — Architecture | "Theo formulates identity verification resulting in limited ways to verify new accounts (e.g. trusted identifiers like other existing government login credentials cannot be used)" | *"Theo formułuje weryfikację identyfikacji w sposób ograniczający metody weryfikacji nowych kont (np. nie można użyć zaufanych identyfikatorów, takich jak istniejące dane logowania do innych usług rządowych)"* | **A04:2021 Insecure Design** — ograniczona architektura uwierzytelniania zwiększa wykluczenie cyfrowe, pokrewne **STRIDE: Spoofing** (utrudniona, nie ułatwiona, weryfikacja tożsamości) |
| ARC3 | ARC | "Oakley pulls the service into a shape which largely or completely excludes the use of paper for any input and output by claimants (e.g. submitting information on paper forms, formatting output for print, sending and receiving formal correspondence by post)" | *"Oakley nadaje usłudze formę, która w dużej mierze lub całkowicie wyklucza możliwość użycia papieru do jakiegokolwiek wejścia lub wyjścia danych (np. składania informacji na formularzach papierowych, formatowania wyjścia do druku, wysyłania i odbierania formalnej korespondencji pocztą)"* | Harm projektowy — wykluczenie cyfrowe osób bez dostępu do internetu; **A04:2021 Insecure Design** w ujęciu "secure AND accessible by design" |

**Ważna uwaga metodologiczna** (widoczna też w UI jako banner ostrzegawczy): ta talia — w przeciwieństwie do FRE/LLM/AAI/STRIDE/MLSec/Mobile/DVO/BOT — **nie opisuje podatności technicznych z określonym poziomem severity**. Karty SCO/ARC/AGE/TRU/POR opisują błędy projektowania usługi (wykluczenie, nieprzejrzystość, nadmierne zbieranie danych), które nie mają numeru CVE ani wyniku CVSS. Traktowanie ich jak zwykłych zagrożeń technicznych (np. przypisanie im severity `CRITICAL`) byłoby błędem metodologicznym — stąd osobny komponent `DesignHarmBadge` (patrz US-19 kryteria akceptacji) i osobne pole `cardKind = "DESIGN_HARM"` w modelu danych.

### Kryteria akceptacji
- Strona `/frameworks/digital-harms` wyświetla wszystkie karty pogrupowane po 5 suitach (SCO, ARC, AGE, TRU, POR)
- Każda karta renderowana jest z `DesignHarmBadge`, nigdy z `SeverityBadge` używanym dla zagrożeń technicznych
- Każda karta ma widoczny chip `CrossReference` prowadzący do `A04:2021 Insecure Design`
- Banner disclaimera na górze strony wyjaśnia, że talia opisuje harmy projektowe, nie podatności techniczne z CVE
- `GET /api/v1/threats?suit=SCO|ARC|AGE|TRU|POR` zwraca karty z `owaspRefs = ["A04:2021"]`, ale **bez** pola `severity`
- Polskie tłumaczenie widoczne przy przełączniku PL/EN, zgodnie z tą samą bramką jakości co US-11

### Plan testów TDD

**Backend:**
```scala
object DigitalHarmsServiceSpec extends ZIOSpecDefault:
  def spec = suite("DigitalHarmsService")(
    test("SCO2 should have owaspRefs containing A04:2021") {
      for
        service <- ZIO.service[DigitalHarmsService]
        card    <- service.getCardById("SCO2", "en")
      yield assert(card.owaspRefs)(contains("A04:2021"))
    },
    test("SCO2 card should have cardKind DESIGN_HARM, not a Severity value") {
      for
        service <- ZIO.service[DigitalHarmsService]
        card    <- service.getCardById("SCO2", "en")
      yield assert(card.cardKind)(equalTo("DESIGN_HARM")) &&
            assert(card.severity)(isNone)
    },
    test("ARC2 should have reviewed Polish translation, not machine-translated fallback") {
      for
        service <- ZIO.service[DigitalHarmsService]
        card    <- service.getCardById("ARC2", "pl")
      yield assert(card.descriptionPl)(isNonEmptyString) &&
            assert(card.descriptionPl)(not(equalTo(card.descriptionEn)))
    },
    test("digital-harms suits endpoint should return exactly 5 suits") {
      for
        service <- ZIO.service[DigitalHarmsService]
        suits   <- service.listSuits
      yield assert(suits.map(_.code))(
        hasSameElements(List("SCO", "ARC", "AGE", "TRU", "POR")))
    }
  ).provide(DigitalHarmsService.live, TestDatabase.layer)
```

**Frontend:**
```typescript
// DigitalHarmsPage.spec.tsx
describe('DigitalHarmsPage', () => {
  it('renders all 5 suit sections', async () => {
    render(<DigitalHarmsPage />)
    for (const suit of ['sco', 'arc', 'age', 'tru', 'por']) {
      await screen.findByTestId(`${suit}-section`)
    }
  })

  it('renders DesignHarmBadge, never SeverityBadge, on dbd cards', async () => {
    render(<DigitalHarmsPage />)
    const card = await screen.findByTestId('card-SCO2')
    expect(within(card).getByTestId('design-harm-badge')).toBeInTheDocument()
    expect(within(card).queryByTestId('severity-badge')).not.toBeInTheDocument()
  })

  it('shows the non-technical-harm disclaimer banner', async () => {
    render(<DigitalHarmsPage />)
    expect(await screen.findByTestId('harms-disclaimer-banner')).toBeVisible()
  })

  it('shows an A04:2021 cross-reference chip on every card', async () => {
    render(<DigitalHarmsPage />)
    const chips = await screen.findAllByTestId('owasp-ref-chip-A04-2021')
    expect(chips.length).toBeGreaterThan(0)
  })
})
```

**E2E:**
```typescript
// us19-digital-harms.spec.ts
test.describe('US-19 Digital-by-Default Harms', () => {
  test('shows all 5 suits on /frameworks/digital-harms', async ({ page }) => {
    await page.goto('/frameworks/digital-harms')
    for (const suit of ['sco', 'arc', 'age', 'tru', 'por']) {
      await expect(page.getByTestId(`${suit}-section`)).toBeVisible()
    }
  })

  test('disclaimer banner is visible before any card content', async ({ page }) => {
    await page.goto('/frameworks/digital-harms')
    await expect(page.getByTestId('harms-disclaimer-banner')).toBeVisible()
  })

  test('switching to Polish shows reviewed SCO2 translation', async ({ page }) => {
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
| Backend — unit | ZIO Test + Mockito-Scala | ≥ 58 | Serwisy, walidatory, encje (w tym `DigitalHarmsServiceSpec`) |
| Backend — integracja | ZIO Test + Testcontainers PostgreSQL 16 | ≥ 26 | Routes, DB queries, rate-limit |
| Frontend — komponenty | Vitest + React Testing Library | ≥ 43 | Komponenty UI, hooki, reducery (w tym `DigitalHarmsPage.spec.tsx`) |
| Frontend — serwisy | Vitest + MSW 2 | ≥ 15 | Axios serwisy, interceptory, i18n |
| E2E | Playwright | ≥ 27 | 19 plików spec × ~1.4 scenariuszy |
| **RAZEM** | | **≥ 200** | |

### Cele pokrycia kodu

| Warstwa | Narzędzie | Cel |
|---|---|---|
| Backend Scala | Scoverage (`sbt scoverage:test`) | ≥ 80% |
| Frontend React | Vitest v8 coverage (`--coverage`) | ≥ 75% |

### Kolejność wykonania testów w CI

```
[1] sbt test          — ZIO Test unit (szybkie, bez bazy danych)
[2] sbt it:test       — ZIO Test integracja (Testcontainers PostgreSQL 16)
[3] sbt assembly      — fat JAR build
[4] npm run test      — Vitest + RTL (coverage report)
[5] npm run build     — Vite production build (bundle < 500 KB gzip initial)
[6] npm run e2e       — Playwright headless Chromium + Firefox
```

### Pliki testowe E2E (Playwright)

```
e2e/
├── us01-frameworks.spec.ts
├── us02-threat-filter.spec.ts
├── us03-threat-detail.spec.ts
├── us04-cross-reference.spec.ts
├── us05-stride-heatmap.spec.ts
├── us06-global-search.spec.ts
├── us07-export.spec.ts
├── us08-atlas-timeline.spec.ts
├── us09-scala-code.spec.ts
├── us10-lua-code.spec.ts
├── us11-language-switch.spec.ts
├── us12-frontend-security.spec.ts
├── us13-llm-security.spec.ts
├── us14-agentic-ai.spec.ts
├── us15-stride.spec.ts
├── us16-ml-security.spec.ts
├── us17-mobile-security.spec.ts
├── us18-devops-security.spec.ts
└── us19-digital-harms.spec.ts
```

### Kluczowe scenariusze abuse case (powiązane testy)

| Abuse Case | Test | Faza |
|---|---|---|
| AC-01: SQL Injection `?q=` | `ThreatServiceSpec` — rejects SQL payload | Sprint 3–4 |
| AC-02: JWT tampering | `JwtMiddlewareSpec` — tampered payload → 401 | Sprint 1–2 |
| AC-03: Bot scraping | `RateLimitMiddlewareSpec` — 429 after 60 req | Sprint 9 |
| AC-04: XSS w opisie karty | `FrontendSecurity.spec.tsx` — DOMPurify strips script | Sprint 9 |
| AC-05: YAML file tampering | `ContentIntegrityVerifierSpec` — throws on hash mismatch | Sprint 9 |
| AC-06: ReDoS search | `SearchServiceSpec` — rejects >200 char query | Sprint 6–7 |
| AC-07: CSV injection | `ExportServiceSpec` — QuoteMode.ALL | Sprint 6–7 |
| AC-08: Clickjacking heatmap | `StrideThreatServiceSpec` — X-Frame-Options: DENY | Sprint 10–11 |
| AC-09: BotWarning bypass | `us18-devops-security.spec.ts` — direct nav blocked | Sprint 12–13 |
| AC-16: Harms deck misread as CVE severity | `DigitalHarmsPage.spec.tsx` — no `SeverityBadge` ever rendered on `dbd` cards | Sprint 13 |
