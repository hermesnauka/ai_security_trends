# RubyGuard 2026 — User Stories & TDD Test Plan

**Version:** 1.0
**Date:** 2026-07-11
**Stack:** Ruby 3.4, Grape + Sequel + PostgreSQL backend; vanilla ES2022 JS frontend (no framework)
**Test frameworks:** `RSpec` (unit + request specs) + `rantly` (property-based testing) + `Playwright` (E2E)

**Uwaga o pochodzeniu danych (zobacz `PLAN.md` §0.1):** surowe pliki `docs/OWASP_stories/*.yaml`
zawierają wyłącznie pola `id`/`value`/`url`/`desc`/`misc` — żaden plik źródłowy nie ma pola
`severity`, `card_kind` ani referencji do OWASP/MITRE/CWE. Mapowania OWASP/MITRE w tabelach
poniżej są treścią kuratorowaną przez zespół, nie wartościami wyodrębnionymi z YAML.

---

## Konwencje testowe

### Unit / request specs (`RSpec`, real Postgres test database, transactional rollback per example)
```ruby
RSpec.describe "GET /api/v1/threats" do
  it "filters by framework and severity" do
    get "/api/v1/threats", params: { frameworkCode: "OWASP_LLM", severity: "critical" }
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body["content"]).to all(include("frameworkCode" => "OWASP_LLM", "severity" => "critical"))
  end
end
```

### Property-based (`rantly`)
```ruby
RSpec.describe "CardFileLoader" do
  it "rejects unrecognized top-level keys" do
    property_of { sized(1) { string } }.check do |extra_key|
      yaml = "meta:\n  edition: webapp\n#{extra_key}: evil\nsuits: []\n"
      expect { CardFileLoader.decode(yaml) }.to raise_error(CardDecodeError::UnrecognizedFields)
    end
  end
end
```

### E2E (`Playwright` — this series' standard browser-based tool)
```javascript
test("does not show attack-demo code before confirmation", async ({ page }) => {
  await page.goto("/");
  await page.getByRole("link", { name: "Zagrożenia" }).click();
  await page.getByText("LLM01").click();
  await page.getByRole("tab", { name: "Kod" }).click();
  await expect(page.getByTestId("attack-demo-code-body")).toBeHidden();
  await page.getByRole("button", { name: "Rozumiem" }).click();
  await expect(page.getByTestId("attack-demo-code-body")).toBeVisible();
});
```

---

## Zasada TDD stosowana w tym projekcie

```
RED       — napisz test (RSpec, właściwość rantly, lub scenariusz Playwright) opisujący
             oczekiwane zachowanie PRZED napisaniem kodu produkcyjnego
GREEN     — napisz minimalny kod, który sprawia, że test przechodzi
REFACTOR  — poprawiaj kod bez łamania testów; Brakeman/RuboCop w tle na każdym CI run
```

**Uwaga strukturalna:** w Ruby nie ma kompilatora sprawdzającego typy przed uruchomieniem —
warstwa "unit" to prawdziwe testy przeciwko rzeczywistej (ale transakcyjnie wycofywanej po
każdym przykładzie) bazie PostgreSQL, nie w-pamięci fake'owi. Warstwa E2E to Playwright,
sterujący prawdziwą, zbudowaną przeglądarką frontendu, tak jak w `app01_react`/`app03_python_django`.

---

## US-01 — Katalog frameworków bezpieczeństwa

**Rola:** security engineer
**Potrzeba:** przeglądać katalog wszystkich frameworków bezpieczeństwa
**Cel:** mieć jeden punkt dostępu do wszystkich standardów

### Kryteria akceptacji
- Ekran główny wyświetla kafelek per framework z liczbą zagrożeń
- Kliknięcie kafelka nawiguje do listy zagrożeń danego frameworku

### Plan testów TDD
```ruby
it "returns at least ten seeded frameworks" do
  get "/api/v1/frameworks"
  expect(JSON.parse(last_response.body).size).to be >= 10
end
```
**Playwright:** `us01-frameworks.spec.js`.

---

## US-02 — Przeglądarka zagrożeń z filtrami

**Rola:** security engineer
**Potrzeba:** filtrować zagrożenia po frameworku, severity, STRIDE, tagu, `q`
**Cel:** szybko znaleźć zagrożenia istotne dla mojego projektu

### Plan testów TDD
```ruby
it "combines framework and severity filters" do
  get "/api/v1/threats", params: { frameworkCode: "OWASP_LLM", severity: "critical" }
  body = JSON.parse(last_response.body)
  expect(body["content"]).not_to be_empty
end
```
**Playwright:** `us02-threat-filter.spec.js` — combine filters, assert result count changes in place.

---

## US-03 — Szczegóły zagrożenia z mitigacjami i kodem

**Rola:** security engineer
**Potrzeba:** widzieć szczegóły zagrożenia z mitigacjami i próbkami kodu w 5 językach
**Cel:** wiedzieć jak wdrożyć ochronę

### Plan testów TDD (property-based)
```ruby
it "every seeded mitigation has all five languages" do
  property_of { choose(*Mitigation.all.map(&:slug)) }.check do |slug|
    languages = CodeSample.where(mitigation_slug: slug).select_map(:language).uniq
    expect(languages.sort).to eq(%w[go java lua python scala])
  end
end
```
**Playwright:** `us03-threat-detail.spec.js` (shown in "Konwencje testowe" above).

---

## US-04 — Mapowanie cross-framework (LLM01 → MITRE ATLAS)

**Rola:** AI security architect
**Potrzeba:** widzieć, które karty Cornucopia LLM odnoszą się do których zagrożeń OWASP LLM Top 10
**Cel:** budować macierz pokrycia bez ręcznego mapowania

### Kryteria akceptacji
- `GET /api/v1/matrix/llm` zwraca jeden wiersz per zagrożenie OWASP_LLM, z listą `cardIds` kart, które się do niego odnoszą (przez kuratorowane `owasp_refs`)
- Zagrożenia bez dopasowanej karty zwracają pustą listę `cardIds`, nie są pomijane

### Plan testów TDD
```ruby
it "maps LLM10:2025 to card LLM2 via curated owasp_refs" do
  get "/api/v1/matrix/llm"
  row = JSON.parse(last_response.body)["rows"].find { |r| r["threatCode"] == "LLM10:2025" }
  expect(row["cardIds"]).to include("LLM2")
end
```

---

## US-05 — Bezpieczeństwo frontend/client-side (karty FRE)

**Rola:** frontend developer
**Potrzeba:** znać zagrożenia client-side z talii Companion (FRE)
**Cel:** zabezpieczyć kod działający w przeglądarce użytkownika

### Przykładowa karta źródłowa (`__LLM_AI___companion-cards-1.0-en.yaml`, oryginał angielski)
> FRE2 — *(treść analogiczna do kart VE poniżej — client-side input/DOM handling threats)*

### Kryteria akceptacji
- `GET /api/v1/cards?suit=FRE` zwraca karty kuratorowane dla talii FRE
- Każda karta ma `descriptionEn` i `descriptionPl` (fallback na EN gdy brak tłumaczenia)

---

## US-06 — Bezpieczeństwo LLM (karty LLM + macierz)

**Rola:** AI/ML engineer
**Potrzeba:** widzieć zagrożenia specyficzne dla LLM z kuratorowaną klasyfikacją i odniesieniami
**Cel:** wdrożyć obronę na podstawie realnego przykładu ataku

### Przykładowa karta źródłowa (`__LLM_AI___companion-cards-1.0-en.yaml`, suit LLM, oryginał)
> **LLM2:** "Samantha can exhaust computational resources or increase operational costs by
> submitting resource-intensive or recursive LLM queries, leading to model DoS"

### Tłumaczenie na polski (treść kuratorowana, nie z surowego YAML)
> **LLM2:** Samantha może wyczerpać zasoby obliczeniowe lub zwiększyć koszty operacyjne,
> wysyłając zasobożerne lub rekurencyjne zapytania do LLM, prowadząc do odmowy usługi (DoS)
> modelu.

### Pokrycie OWASP
Karta LLM2 jest kuratorowana z `owasp_refs: ["LLM10:2025"]` — **LLM10:2025 "Unbounded
Consumption"** z OWASP Top 10 for LLM Applications (2025). To dokładnie ta sama karta i
mitigacja (`rate-limiting-unbounded-consumption`, próbka Lua, FR-16), które łączą tę
historię użytkownika z realnym kodem obronnym w tej aplikacji.

### Plan testów TDD
```ruby
it "curates LLM2 with owasp_refs including LLM10:2025" do
  card = Card[card_id: "LLM2"]
  expect(card.owasp_refs).to include("LLM10:2025")
end
```

---

## US-07 — Agentic AI + Cloud (karty AAI + CLD)

**Rola:** platform security engineer
**Potrzeba:** widzieć zagrożenia agentowej AI i chmury
**Cel:** ocenić ryzyko nadmiernej autonomii agenta (excessive agency)

### Przykładowa karta źródłowa (suit AAI, oryginał)
> **AAI2:** "Tay can misinterpret user intent due to insufficient context isolation or
> prompt enforcement and execute actions outside the expected task scope"

### Tłumaczenie na polski
> **AAI2:** Tay może błędnie zinterpretować intencję użytkownika z powodu niewystarczającej
> izolacji kontekstu lub braku wymuszenia promptu, i wykonać działania wykraczające poza
> oczekiwany zakres zadania.

### Pokrycie OWASP
Kuratorowane `owasp_refs: ["LLM06:2025"]` — **LLM06:2025 "Excessive Agency"**.

---

## US-08 — STRIDE EoP — katalog i heatmapa

**Rola:** threat modeler
**Potrzeba:** przeglądać talię STRIDE (Elevation of Privilege) i widzieć pokrycie per kategoria
**Cel:** zidentyfikować luki w modelowaniu zagrożeń mojego systemu

### Kryteria akceptacji
- `GET /api/v1/matrix/stride-heatmap` zwraca liczbę kart per kategoria STRIDE (S/T/R/I/D/E)
- Heatmapa to uproszczone zliczenie kart per kategoria, nie pełne pokrycie "per komponent systemu" (ten sam uczciwy zakres co u każdego siostrzanego projektu)

---

## US-09 — Bezpieczeństwo ML (karty MLSec)

**Rola:** ML engineer
**Potrzeba:** widzieć zagrożenia specyficzne dla uczenia maszynowego (talia "Elevation of MLSec")
**Cel:** zabezpieczyć pipeline trenowania/wnioskowania modelu

### Kryteria akceptacji
- `GET /api/v1/cards?edition=mlsec` zwraca karty z sufiksami EMR/EIR/EOR/EDR

---

## US-10 — Bezpieczeństwo mobile (karty Mobile MAS)

**Rola:** mobile security engineer
**Potrzeba:** widzieć zagrożenia mobilne (talia Mobile App: PC/AA/NS/RS/CRM/CM)
**Cel:** ocenić ryzyko aplikacji mobilnej pod kątem OWASP MASVS

### Uwaga podwójnego przeznaczenia
Ta talia jest zarówno przeglądalną treścią (US-10), jak i bezpośrednim źródłem własnego
modelu zagrożeń tej aplikacji (`PLAN.md` §11) — ten sam wzorzec co w `app11_swift_ios`/`app12_kotlin_android`.

---

## US-11 — Bezpieczeństwo DevOps + Cloud (karty DVO + CLD + BOT)

**Rola:** DevOps engineer
**Potrzeba:** widzieć zagrożenia CI/CD, chmury i zautomatyzowane (boty)
**Cel:** zabezpieczyć pipeline wdrożeniowy

### Przykładowa karta źródłowa (suit DVO, ilustracyjna treść analogiczna do reszty talii Companion)
Kuratorowane mitigacje tej aplikacji obejmują `supply-chain-dependency-integrity`
(FR-15, próbka Scala) — bezpośrednio odpowiadające zagrożeniom łańcucha dostaw z tej talii.

---

## US-12 — Bezpieczeństwo Website App (karty VE/AT/SM/AZ/CR/C)

**Rola:** web application security engineer
**Potrzeba:** przeglądać pełną talię Website App Cornucopia (najstarszą, najbardziej dojrzałą talię)
**Cel:** zmapować karty na OWASP Web Top 10

### Przykładowa karta źródłowa (`webapp-cards-3.0-en.yaml`, suit VE, oryginał)
> **VE3:** "Robert can input malicious data because the allowed protocol format is not
> being checked, or duplicates are accepted, or the structure is not being verified..."

### Tłumaczenie na polski
> **VE3:** Robert może wprowadzić złośliwe dane, ponieważ dozwolony format protokołu nie
> jest sprawdzany, akceptowane są duplikaty, lub struktura nie jest weryfikowana.

### Pokrycie OWASP
Kuratorowane `owasp_refs: ["A03:2021"]` — **A03:2021 "Injection"**, dokładnie ta sama
kategoria co mitigacja `sql-injection-prevention` tej aplikacji (FR-13, próbka Python).

---

## US-13 — Próbki kodu Python

**Rola:** backend developer (Python)
**Potrzeba:** widzieć realną, kompletną próbkę kodu Python demonstrującą atak i obronę
**Cel:** zaimplementować parametryzowane zapytania SQL we własnym kodzie

### Kryteria akceptacji
- Mitigacja `sql-injection-prevention` ma próbkę `attack_demo` (string-concatenated query) i `defense` (parametryzowane zapytanie) w Pythonie

---

## US-14 — Próbki kodu Java

**Rola:** backend developer (Java)
**Potrzeba:** widzieć realną próbkę kodu Java dla kontroli dostępu
**Cel:** zapobiec złamanej kontroli dostępu (IDOR)

### Kryteria akceptacji
- Mitigacja `broken-access-control-check` ma próbkę `attack_demo`/`defense` w Javie

---

## US-15 — Próbki kodu Scala (ataki supply-chain)

**Rola:** platform engineer (Scala/JVM)
**Potrzeba:** widzieć próbkę kodu demonstrującą weryfikację integralności zależności
**Cel:** zapobiec atakom na łańcuch dostaw (supply-chain)

### Kryteria akceptacji
- Mitigacja `supply-chain-dependency-integrity` ma próbkę `attack_demo`/`defense` w Scali

---

## US-16 — Próbki kodu Lua (rate limiting / LLM DoS)

**Rola:** platform engineer (API gateway/Lua)
**Potrzeba:** widzieć próbkę kodu limitowania zapytań
**Cel:** zapobiec nieograniczonej konsumpcji zasobów LLM (OWASP LLM10:2025)

### Kryteria akceptacji
- Mitigacja `rate-limiting-unbounded-consumption` ma próbkę `attack_demo`/`defense` w Lua

---

## US-17 — Globalne wyszukiwanie

**Rola:** security engineer
**Potrzeba:** wyszukiwać zagrożenia i karty jednym zapytaniem tekstowym
**Cel:** szybko znaleźć relevantną treść bez znajomości dokładnej kategorii

### Plan testów TDD
```ruby
it "finds a threat by title substring, case-insensitively" do
  get "/api/v1/search", params: { q: "injection" }
  results = JSON.parse(last_response.body)
  expect(results).to include(a_hash_including("code" => "A03:2021"))
end
```
**Uwaga o zakresie (FR-17-equivalent):** to zwykłe zapytanie `ILIKE '%text%'`, nie indeks
pełnotekstowy — ten sam uczciwy zakres co plain-CONTAINS wyszukiwanie u każdego
siostrzanego projektu.

---

## US-18 — Eksport do CSV

**Rola:** security engineer
**Potrzeba:** wyeksportować bieżącą, przefiltrowaną listę zagrożeń do CSV
**Cel:** dołączyć dane do raportu offline

### Kryteria akceptacji
- `GET /api/v1/export.csv` zwraca `Content-Type: text/csv`, respektuje te same parametry filtrowania co `/api/v1/threats`
- Eksport jest generowany synchronicznie w ramach żądania (`PLAN.md` §3) — brak endpointu do pollingu, w przeciwieństwie do asynchronicznego eksportu WP-Cron w `app09_php_WORDPRESS`

---

## US-19 — Digital-by-Default Harms (karty SCO/ARC/AGE/TRU/POR)

**Rola:** public-sector digital service designer
**Potrzeba:** widzieć harmy projektowe (nie techniczne podatności) usług cyfrowych domyślnych
**Cel:** zidentyfikować ryzyko wykluczenia cyfrowego przed wdrożeniem usługi

### Kryteria akceptacji (D-03)
- Karty tej talii mają `card_kind = 'design_harm'` i **strukturalnie** `severity IS NULL`
  (wymuszone przez `CHECK` w bazie danych, `PLAN.md` §4 D-03) — żaden widok nie może
  wyświetlić odznaki severity dla tych kart, bo pole jest zawsze `NULL`

### Plan testów TDD
```ruby
it "never allows a design_harm row to carry a severity" do
  expect {
    DB[:cards].insert(card_id: "TEST1", card_kind: "design_harm", severity: "high", **other_required_fields)
  }.to raise_error(Sequel::CheckConstraintViolation)
end
```
