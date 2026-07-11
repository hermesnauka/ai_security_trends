# LuaGuard 2026 — User Stories & TDD Test Plan

**Version:** 1.0
**Date:** 2026-07-11
**Stack:** Lua (LuaJIT/OpenResty + Lapis) backend, PostgreSQL; Unity 2022 LTS + MoonSharp (Lua)
frontend
**Test frameworks:** `busted` (backend unit + request specs; also run standalone against the
frontend's `StreamingAssets/lua/*.lua` files, independent of Unity), Unity Test Framework
(`EditMode` for C#-only glue, `PlayMode` for scene-level smoke tests)

**Uwaga o pochodzeniu danych (zobacz `PLAN.md` §0.1):** surowe pliki `../docs/OWASP_stories/*.yaml`
zawierają wyłącznie pola `id`/`value`/`url`/`desc`/`misc` — żaden plik źródłowy nie ma pola
`severity`, `card_kind` ani referencji do OWASP/MITRE/CWE. Mapowania OWASP/MITRE w tabelach
poniżej są treścią kuratorowaną przez zespół, nie wartościami wyodrębnionymi bezpośrednio z YAML.
Cytaty angielskie poniżej są dosłownymi fragmentami tych plików; tłumaczenia polskie są
kuratorowaną treścią tej aplikacji.

---

## Konwencje testowe

### Backend unit / request specs (`busted`, real Postgres test database, transaction rollback per example)
```lua
describe("GET /api/v1/threats", function()
  it("filters by framework and severity", function()
    local res = http.get("/api/v1/threats", { frameworkCode = "OWASP_LLM", severity = "critical" })
    assert.are.equal(200, res.status)
    local body = json.decode(res.body)
    for _, threat in ipairs(body.content) do
      assert.are.equal("OWASP_LLM", threat.frameworkCode)
      assert.are.equal("critical", threat.severity)
    end
  end)
end)
```

### Frontend Lua logic, tested standalone (no Unity Editor needed)
```lua
-- frontend/Assets/StreamingAssets/lua/spec/card_engine_spec.lua
describe("card_engine.resolve_attack", function()
  it("matches an attack to an open component vulnerability by STRIDE letter", function()
    local component = { stride_open = { "E" } }
    local attack = { stride = { "E" } }
    assert.is_true(card_engine.resolve_attack(component, attack))
  end)

  it("does not match when the component's vulnerability is already protected", function()
    local component = { stride_open = {} }
    local attack = { stride = { "E" } }
    assert.is_false(card_engine.resolve_attack(component, attack))
  end)
end)
```

### Unity `EditMode` (C# glue only — the sandbox boundary itself, not gameplay logic)
```csharp
[Test]
public void LuaSandbox_NeverEnablesIoOrOsModules() {
    var script = LuaSandbox.CreateSandboxedScript();
    Assert.Throws<ScriptRuntimeException>(() => script.DoString("return io.open('/etc/passwd')"));
    Assert.Throws<ScriptRuntimeException>(() => script.DoString("return os.execute('ls')"));
}
```

---

## Zasada TDD stosowana w tym projekcie

```
RED       — napisz test (busted spec, Unity EditMode/PlayMode test) opisujący oczekiwane
             zachowanie PRZED napisaniem kodu produkcyjnego
GREEN     — napisz minimalny kod, który sprawia, że test przechodzi
REFACTOR  — poprawiaj kod bez łamania testów; luacheck w tle na każdym CI run
```

**Uwaga strukturalna:** Lua (w obu środowiskach uruchomieniowych) nie ma kompilatora
sprawdzającego typy przed uruchomieniem — dokładnie ta sama sytuacja co w Ruby
(`app13_ruby_FastApi`) i PHP (`app09_php_WORDPRESS`), ale bez żadnego z ich odpowiedników
statycznej analizy typów opcjonalnych. Warstwa "unit" backendu to prawdziwe testy przeciwko
rzeczywistej (ale wycofywanej transakcyjnie po każdym przykładzie) bazie PostgreSQL. Warstwa
frontendowa Lua (`card_engine.lua`, `game_modes.lua`, `i18n.lua`) jest testowana **dwukrotnie**:
raz przez `busted` uruchomiony samodzielnie (szybka pętla RED/GREEN bez Unity), raz przez
Unity `PlayMode` (potwierdzenie, że MoonSharp faktycznie wykonuje ten sam plik `.lua`
identycznie wewnątrz silnika).

---

## US-01 — Katalog frameworków bezpieczeństwa

**Rola:** security engineer
**Potrzeba:** przeglądać katalog wszystkich frameworków bezpieczeństwa
**Cel:** mieć jeden punkt dostępu do wszystkich standardów

### Kryteria akceptacji
- `FrameworksScene` wyświetla kafelek per framework z liczbą zagrożeń
- Kliknięcie kafelka nawiguje do `ThreatsScene` przefiltrowanej po tym frameworku

### Plan testów TDD
```lua
it("returns at least five seeded frameworks", function()
  local res = http.get("/api/v1/frameworks")
  assert.is_true(#json.decode(res.body) >= 5)
end)
```

---

## US-02 — Przeglądarka zagrożeń z filtrami

**Rola:** security engineer
**Potrzeba:** filtrować zagrożenia po frameworku, severity, STRIDE, tagu, `q`
**Cel:** szybko znaleźć zagrożenia istotne dla mojego projektu

### Plan testów TDD
```lua
it("combines framework and severity filters", function()
  local res = http.get("/api/v1/threats", { frameworkCode = "OWASP_LLM", severity = "critical" })
  local body = json.decode(res.body)
  assert.is_true(#body.content > 0)
end)
```

---

## US-03 — Szczegóły zagrożenia z mitigacjami i kodem w 5 językach

**Rola:** security engineer
**Potrzeba:** widzieć szczegóły zagrożenia z mitigacjami i próbkami kodu (Python/Java/Go/Scala/Lua)
**Cel:** wiedzieć jak wdrożyć ochronę

### Plan testów TDD
```lua
it("every seeded mitigation has all five languages", function()
  for _, mitigation in ipairs(Mitigation:select()) do
    local languages = {}
    for _, sample in ipairs(CodeSample:select("where mitigation_slug = ?", mitigation.slug)) do
      languages[sample.language] = true
    end
    local expected = { python = true, java = true, go = true, scala = true, lua = true }
    assert.are.same(expected, languages)
  end
end)
```
**Unity `PlayMode`:** `ThreatDetailScene` renders 5 code-sample tabs; the attack-demo tab body
is hidden until the confirmation modal is dismissed (D-09, SR-09).

---

## US-04 — Mapowanie cross-framework (LLM ↔ MITRE ATLAS)

**Rola:** AI security architect
**Potrzeba:** widzieć, które karty Cornucopia LLM odnoszą się do których zagrożeń OWASP LLM Top 10 i technik MITRE ATLAS
**Cel:** budować macierz pokrycia bez ręcznego mapowania

### Przykładowa karta źródłowa (`__LLM_AI___companion-cards-1.0-en.yaml`, suit LLM, oryginał)
> **LLM2:** "Samantha can exhaust computational resources or increase operational costs by
> submitting resource-intensive or recursive LLM queries, leading to model DoS"

### Tłumaczenie na polski (treść kuratorowana)
> **LLM2:** Samantha może wyczerpać zasoby obliczeniowe lub zwiększyć koszty operacyjne,
> wysyłając zasobożerne lub rekurencyjne zapytania do LLM, prowadząc do odmowy usługi (DoS)
> modelu.

### Pokrycie OWASP i MITRE ATLAS
Karta LLM2 jest kuratorowana z `owasp_refs: ["LLM10:2025"]` — **LLM10:2025 "Unbounded
Consumption"** — oraz `mitre_refs: ["AML.T0029"]` (Denial of ML Service), zgodnie z mapowaniem
w `../docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`. To ta sama karta i
mitigacja (`rate-limiting-unbounded-consumption`, próbka Lua, FR-08), która łączy tę historię
użytkownika z realnym kodem obronnym w tej aplikacji.

### Plan testów TDD
```lua
it("maps LLM2 to LLM10:2025 and AML.T0029", function()
  local row = json.decode(http.get("/api/v1/matrix/llm").body).rows
  local llm2 = find_by(row, "cardId", "LLM2")
  assert.is_true(includes(llm2.owaspRefs, "LLM10:2025"))
  assert.is_true(includes(llm2.mitreRefs, "AML.T0029"))
end)
```

---

## US-05 — Nadmierna sprawczość agenta AI (karta LLM3 — overreliance)

**Rola:** AI/ML engineer
**Potrzeba:** widzieć zagrożenie nadmiernego polegania na wynikach LLM bez weryfikacji człowieka
**Cel:** wdrożyć bramkę human-in-the-loop przed wykonaniem krytycznej akcji

### Przykładowa karta źródłowa (suit LLM, oryginał)
> **LLM3:** "Dave can exploit overreliance on LLM outputs where critical human oversight is
> missing, leading to security failures or incorrect decisions based on hallucinations or
> flawed reasoning"

### Tłumaczenie na polski
> **LLM3:** Dave może wykorzystać nadmierne poleganie na wynikach LLM w sytuacji braku
> krytycznego nadzoru człowieka, prowadząc do awarii bezpieczeństwa lub błędnych decyzji
> opartych na halucynacjach lub wadliwym rozumowaniu.

### Pokrycie OWASP
Kuratorowane `owasp_refs: ["LLM09:2025"]` — **LLM09:2025 "Misinformation"** (dawniej
Overreliance) z OWASP Top 10 for LLM Applications.

---

## US-06 — STRIDE Spoofing i Elevation of Privilege — katalog i heatmapa

**Rola:** threat modeler
**Potrzeba:** przeglądać talię STRIDE (Spoofing/Elevation of Privilege) i widzieć pokrycie per kategoria
**Cel:** zidentyfikować luki w modelowaniu zagrożeń mojego systemu

### Przykładowe karty źródłowe (`STRIDE__eop-cards-5.0-en.yaml`, oryginał)
> **SP2:** "An attacker could take over the port or socket that the server normally uses"
> **EP2:** "An attacker has compromised a key technology supplier"

### Tłumaczenie na polski
> **SP2:** Atakujący mógłby przejąć port lub gniazdo sieciowe, którego normalnie używa serwer.
> **EP2:** Atakujący skompromitował kluczowego dostawcę technologii.

### Pokrycie OWASP/STRIDE
SP2 → kategoria STRIDE **S (Spoofing)**. EP2 → kategoria STRIDE **E (Elevation of Privilege)**,
kuratorowane `owasp_refs: ["A03:2021"]` (łańcuch dostaw jako wektor eskalacji uprawnień, ta sama
klasa zagrożenia co mitigacja `supply-chain-dependency-integrity`, FR-08, próbka Scala).

### Kryteria akceptacji
- `GET /api/v1/matrix/stride-heatmap` zwraca liczbę kart per kategoria STRIDE (S/T/R/I/D/E)
- Heatmapa to uproszczone zliczenie kart per kategoria, nie pełne pokrycie "per komponent
  systemu" — ten sam uczciwy zakres co u każdego siostrzanego projektu

### Grywalne powiązanie (Phase 2+, FR-12)
Karty SP2/EP2 to realne przykłady kart Attack z gry "Security Architects" — w trybie Regular
gracz broni komponentu przed dokładnie takim atakiem, dobierając kartę Protection z tej samej
litery STRIDE.

---

## US-07 — Bezpieczeństwo ML (karty MLSec — catastrophic forgetting)

**Rola:** ML engineer
**Potrzeba:** widzieć zagrożenia specyficzne dla uczenia maszynowego (talia "Elevation of MLSec")
**Cel:** zabezpieczyć pipeline trenowania/wnioskowania modelu

### Przykładowa karta źródłowa (`RISKS__elevation-of-mlsec-cards-1.0-en.yaml`, oryginał)
> **EMR2:** "When a model is filled with too much overlapping information, collisions in the
> representation space may lead to the model "forgetting" information." *(misc: Catastrophic
> forgetting)*

### Tłumaczenie na polski
> **EMR2:** Gdy model zostaje przeładowany nadmiarowo nakładającymi się informacjami, kolizje
> w przestrzeni reprezentacji mogą prowadzić do "zapominania" informacji przez model.
> *(Catastrophic forgetting — katastrofalne zapominanie)*

### Kryteria akceptacji
- `GET /api/v1/cards?edition=mlsec` zwraca karty z prefiksem `EMR`/`EIR`/`EOR`/`EDR`

---

## US-08 — Bezpieczeństwo mobile (karty Mobile — ekran w tle)

**Rola:** mobile security engineer
**Potrzeba:** widzieć zagrożenia mobilne (talia Mobile App)
**Cel:** ocenić ryzyko aplikacji mobilnej pod kątem OWASP MASVS

### Przykładowa karta źródłowa (`mobileapp-cards-1.1-en.yaml`, oryginał)
> **PC2:** "Andrew can expose sensitive data through the app's auto-generated screenshots when
> the app moves to the background"

### Tłumaczenie na polski
> **PC2:** Andrew może ujawnić wrażliwe dane poprzez automatycznie generowane zrzuty ekranu
> aplikacji, gdy aplikacja przechodzi w tło.

### Uwaga o podwójnym znaczeniu dla tej aplikacji
Ta karta jest bezpośrednio istotna dla samej aplikacji Unity — Unity generuje podobne
zrzuty stanu ekranu przy przełączaniu aplikacji w tło na urządzeniach mobilnych; Phase-1 nie
implementuje żadnego ekranu wprowadzania hasła/tokenu, który wymagałby zaciemnienia w tym
momencie (login screen jest jedynym wyjątkiem, patrz `PLAN.md` D-08's caveat), ale karta jest
udokumentowana tutaj jako świadomie przyjęte ryzyko do rewizji przy realnym mobilnym buildzie.

---

## US-09 — Digital-by-Default Harms (karta SCO2 — brak transparentności)

**Rola:** public-sector digital service designer
**Potrzeba:** widzieć harmy projektowe (nie techniczne podatności) usług cyfrowych domyślnych
**Cel:** zidentyfikować ryzyko braku transparentności przed wdrożeniem usługi

### Przykładowa karta źródłowa (`dbd-cards-1.0-en.yaml`, oryginał)
> **SCO2:** "Tommy does not create, publish and maintain publicly all the service
> assumptions, specifications, constraints, source code, algorithms, formulas, configuration
> settings, operating instructions and processes"

### Tłumaczenie na polski
> **SCO2:** Tommy nie tworzy, nie publikuje i nie utrzymuje publicznie wszystkich założeń,
> specyfikacji, ograniczeń, kodu źródłowego, algorytmów, formuł, ustawień konfiguracyjnych,
> instrukcji obsługi ani procesów usługi.

### Kryteria akceptacji (D-03)
- Karty tej talii mają `card_kind = 'design_harm'` i **strukturalnie** `severity IS NULL`
  (wymuszone przez `CHECK` w bazie danych, `PLAN.md` §4 D-03)

### Plan testów TDD
```lua
it("never allows a design_harm row to carry a severity", function()
  assert.has_error(function()
    db.insert("cards", { card_id = "TEST1", card_kind = "design_harm", severity = "high" })
  end)
end)
```

---

## US-10 — Website App / Injection (karta VE2)

**Rola:** web application security engineer
**Potrzeba:** przeglądać talię Website App Cornucopia (najstarszą, najbardziej dojrzałą talię)
**Cel:** zmapować karty na OWASP Web Top 10

### Przykładowa karta źródłowa (`webapp-cards-3.0-en.yaml`, oryginał)
> **VE3:** "Robert can input malicious data because the allowed protocol format is not being
> checked, or duplicates are accepted, or the structure is not being verified..."

### Tłumaczenie na polski
> **VE3:** Robert może wprowadzić złośliwe dane, ponieważ dozwolony format protokołu nie jest
> sprawdzany, akceptowane są duplikaty, lub struktura nie jest weryfikowana.

### Pokrycie OWASP
Kuratorowane `owasp_refs: ["A03:2021"]` — **A03:2021 "Injection"**, ta sama kategoria co
mitigacja `sql-injection-prevention` (FR-08, próbka Python).

---

## US-11 — Próbki kodu w pięciu językach (Python/Java/Go/Scala/Lua)

**Rola:** backend developer (dowolny z pięciu ekosystemów)
**Potrzeba:** widzieć realną, kompletną próbkę kodu demonstrującą atak i obronę we własnym języku
**Cel:** zaimplementować odpowiednią mitigację we własnym stosie technologicznym

### Kryteria akceptacji
- Mitigacja `sql-injection-prevention`: Python (`attack_demo`/`defense`)
- Mitigacja `broken-access-control-check`: Java (`attack_demo`/`defense`)
- Mitigacja `supply-chain-dependency-integrity`: Scala (`attack_demo`/`defense`)
- Mitigacja `rate-limiting-unbounded-consumption`: Lua (`attack_demo`/`defense`) — **jedyny
  przypadek w tej aplikacji, gdzie język próbki kodu jest tym samym językiem, w którym
  napisany jest sam backend** (`PLAN.md` §10) — warto to jawnie sprawdzić testem, żeby próbka
  faktycznie różniła się (inny kontekst: klucz API gateway vs. framework webowy), a nie była
  przypadkowo skopiowanym fragmentem samego backendu
- Mitigacja `prompt-injection-defense` (Go): `attack_demo`/`defense`

### Plan testów TDD
```lua
it("the Lua code sample is not a verbatim copy of the backend's own route handler", function()
  local sample = CodeSample:find_by("rate-limiting-unbounded-consumption", "lua", "defense")
  local route_source = read_file("app/routes/threats.lua")
  assert.is_false(string.find(route_source, sample.code, 1, true) ~= nil)
end)
```

---

## US-12 — Globalne wyszukiwanie

**Rola:** security engineer
**Potrzeba:** wyszukiwać zagrożenia i karty jednym zapytaniem tekstowym
**Cel:** szybko znaleźć relevantną treść bez znajomości dokładnej kategorii

### Plan testów TDD
```lua
it("finds a threat by title substring, case-insensitively", function()
  local res = json.decode(http.get("/api/v1/search", { q = "injection" }).body)
  assert.is_true(any(res, function(r) return r.code == "A03:2021" end))
end)
```

---

## US-13 — Przełącznik języka Polski/Angielski

**Rola:** dowolny użytkownik (polsko- lub anglojęzyczny)
**Potrzeba:** przełączyć cały interfejs i treść zagrożeń/kart między polskim a angielskim w jedno kliknięcie
**Cel:** korzystać z aplikacji w preferowanym języku bez przeładowania sceny

### Kryteria akceptacji (D-05, FR-10)
- Domyślny język to polski
- Przełącznik w `LoginScene`/ekranie ustawień natychmiast aktualizuje wszystkie widoczne
  napisy UI (Lua `i18n.lua`) oraz treść zagrożeń/kart pobraną z `?locale=` (bez ponownego
  ładowania sceny Unity)
- Żaden string interfejsu nie istnieje tylko w jednym języku (NFR-06)

### Plan testów TDD (frontend Lua, standalone `busted`)
```lua
it("switching locale updates a UI string instantly", function()
  i18n.set_locale("en")
  assert.are.equal("Threats", i18n.t("nav.threats"))
  i18n.set_locale("pl")
  assert.are.equal("Zagrożenia", i18n.t("nav.threats"))
end)

it("every key in the Polish table also exists in the English table and vice versa", function()
  local pl_keys, en_keys = i18n.key_set("pl"), i18n.key_set("en")
  assert.are.same(pl_keys, en_keys)
end)
```

---

## US-14 — Sandbox MoonSharp (D-07 — unikalne dla tej aplikacji)

**Rola:** platform security engineer
**Potrzeba:** mieć pewność, że silnik Lua osadzony w kliencie Unity nigdy nie zyskuje dostępu do
systemu plików lub procesów
**Cel:** zapobiec eskalacji od "błędu w danych karty" do "zdalnego wykonania kodu na urządzeniu gracza"

### Kryteria akceptacji (SR-10, SR-11)
- Instancja `Script` MoonSharp jest tworzona wyłącznie z `CoreModules.Preset_SoftSandbox` minus
  `os`/`io`
- `CoreModules.Full` nie pojawia się nigdzie w kodzie (weryfikowane przez CI grep-check)
- Żaden obiekt C# zarejestrowany jako `UserData` nie jest przekazywany do Lua — granica
  C#↔Lua przenosi wyłącznie dane (tabele/stringi/liczby/booleany)

### Plan testów TDD
```csharp
[Test]
public void LuaSandbox_CannotReadArbitraryFiles() {
    var script = LuaSandbox.CreateSandboxedScript();
    Assert.Throws<ScriptRuntimeException>(() => script.DoString("return io.open('/etc/passwd'):read('*a')"));
}

[Test]
public void LuaSandbox_CannotSpawnProcesses() {
    var script = LuaSandbox.CreateSandboxedScript();
    Assert.Throws<ScriptRuntimeException>(() => script.DoString("os.execute('rm -rf /')"));
}
```
**CI grep-check:** `! grep -rn "CoreModules.Full" frontend/Assets/Scripts/` must exit 0 (no match).

---

## US-15 — Tryb Regular gry "Security Architects: Digital" (Phase 2+)

**Rola:** gracz ucząca się STRIDE
**Potrzeba:** rozegrać sesję trybu Regular, broniąc komponentów przez 6 tur
**Cel:** nauczyć się kategorii STRIDE poprzez rozgrywkę, nie tylko czytanie katalogu

### Kryteria akceptacji (FR-12, zasady z `../docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`)
- Sesja zaczyna się z reputacją 10, 3 kartami komponentów na stole
- Każda tura: faza ochrony (dobranie kart Protection) → faza zdarzeń losowych (Component/Event/Attack)
- Atak trafia tylko wtedy, gdy istnieje komponent z otwartą (niezabezpieczoną) podatnością
  odpowiadającą literze STRIDE ataku — trafienie odejmuje 1 punkt reputacji
- Zwycięstwo: przetrwanie 6 tur z reputacją > 0. Porażka: reputacja spada do 0

### Plan testów TDD
```lua
describe("game_modes.regular", function()
  it("an attack against a fully-protected component does nothing", function()
    local session = game_modes.regular.new_session()
    session.components[1].stride_open = {}
    local rep_before = session.reputation
    game_modes.regular.resolve_attack(session, { stride = { "E" } })
    assert.are.equal(rep_before, session.reputation)
  end)

  it("an attack against an open matching vulnerability costs exactly 1 reputation", function()
    local session = game_modes.regular.new_session()
    session.components[1].stride_open = { "E" }
    local rep_before = session.reputation
    game_modes.regular.resolve_attack(session, { stride = { "E" } })
    assert.are.equal(rep_before - 1, session.reputation)
  end)

  it("declares defeat when reputation reaches 0", function()
    local session = game_modes.regular.new_session()
    session.reputation = 0
    assert.are.equal("defeat", game_modes.regular.check_end_state(session))
  end)
end)
```

---

## US-16 — Tryb Shift Left (Phase 2+)

**Rola:** gracz ucząca się DevSecOps
**Potrzeba:** rozegrać sesję trybu Shift Left ze strefami Development/Production
**Cel:** zrozumieć, dlaczego wcześniejsze wykrycie luk (przed produkcją) zmniejsza ryzyko

### Kryteria akceptacji (FR-13)
- Nowo dobrany komponent trafia najpierw do strefy Development — nie może być zaatakowany
- Na początku kolejnej tury komponenty z Development przenoszą się do Production
- Atak w strefie Production trafia **wszystkie** pasujące otwarte komponenty jednocześnie
  (uszkodzenia obszarowe), nie tylko jeden

### Plan testów TDD
```lua
it("a component in the development zone cannot be attacked", function()
  local session = game_modes.shift_left.new_session()
  local component = game_modes.shift_left.draw_component(session)
  assert.are.equal("development", component.zone)
  game_modes.shift_left.resolve_attack(session, { stride = component.stride_open })
  assert.are.equal(10, session.reputation) -- unchanged
end)
```

---

## US-17 — Tryb Warsztatowy Modelowania Zagrożeń (Phase 2+)

**Rola:** facylitator warsztatu threat modeling w firmie
**Potrzeba:** rozegrać sesję warsztatową na realnym diagramie systemu, bez kart komponentów
**Cel:** wygenerować realną listę zagrożeń i mitygacji dla własnego systemu w grupie

### Kryteria akceptacji (FR-14)
- Karty Attack i Protection są rozdzielane równo między graczy — karty Component nie są używane
- Zagranie karty Attack na element diagramu i akceptacja grupy daje +1 punkt atakującemu
- Kontra kartą Protection **kradnie** punkt atakującemu (atakujący traci przyznany punkt,
  broniący zyskuje +1) — to jedyny tryb, gdzie wynik rundy może się cofnąć po przyznaniu

---

## US-18 — Eksport do CSV

**Rola:** security engineer
**Potrzeba:** wyeksportować bieżącą, przefiltrowaną listę zagrożeń do CSV
**Cel:** dołączyć dane do raportu offline

### Kryteria akceptacji
- `GET /api/v1/export.csv` zwraca `Content-Type: text/csv`, respektuje te same parametry
  filtrowania co `/api/v1/threats`
- Eksport jest generowany synchronicznie w ramach żądania — brak endpointu do pollingu, w
  przeciwieństwie do asynchronicznego eksportu WP-Cron w `app09_php_WORDPRESS`
