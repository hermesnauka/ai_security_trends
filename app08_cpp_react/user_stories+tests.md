# CppCitadel 2026 — User Stories & TDD Test Plan

**Version:** 1.0
**Date:** 2026-07-07
**Stack:** C++23 + Drogon + libpqxx/sqlpp11 (backend) · React 18 + TypeScript + Vite (frontend)
**Test frameworks:** GoogleTest + GoogleMock + `RapidCheck` (property-based) + Drogon test client + `libFuzzer` · Vitest + React Testing Library · Playwright

---

## Konwencje testowe

### Backend (C++ — GoogleTest)
```cpp
TEST(ThreatServiceTest, FiltersBySeverity) {
    auto env = testEnv();
    auto result = ThreatService::list(env, ThreatFilter{.severity = Severity::Critical});
    for (const auto& t : result) {
        EXPECT_EQ(t.severity, Severity::Critical);
    }
}
```

### Backend properties (`RapidCheck`)
```cpp
RC_GTEST_PROP(CardLoaderTest, RejectsUnknownTopLevelFields, (const std::string& extraKey)) {
    RC_PRE(extraKey.size() >= 3 && extraKey.size() <= 10);
    std::string yaml = "meta:\n  edition: webapp\n" + extraKey + ": evil\nsuits: []\n";
    RC_ASSERT_THROWS_AS(decode_card_file(YAML::Load(yaml)), CardDecodeError);
}
```

### Backend HTTP (Drogon test client)
```cpp
TEST(ThreatControllerTest, ListReturns200ForValidFramework) {
    auto client = drogon::HttpClient::newHttpClient("http://127.0.0.1:8080");
    auto req = drogon::HttpRequest::newHttpRequest();
    req->setPath("/api/v1/threats");
    req->setParameter("framework", "OWASP_LLM");
    auto [result, resp] = client->sendRequest(req);
    ASSERT_EQ(result, drogon::ReqResult::Ok);
    EXPECT_EQ(resp->statusCode(), drogon::k200OK);
}
```

### Fuzzing (`libFuzzer`)
```cpp
// fuzz/fuzz_card_loader.cpp
extern "C" int LLVMFuzzerTestOneInput(const uint8_t* data, size_t size) {
    std::string input(reinterpret_cast<const char*>(data), size);
    try {
        auto node = YAML::Load(input);
        decode_card_file(node);
    } catch (const std::exception&) {
        // expected for malformed input — the harness is checking for CRASHES, not exceptions
    }
    return 0;
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
RED       — napisz test (GoogleTest, właściwość RapidCheck, lub harness libFuzzer) opisujący
             oczekiwane zachowanie PRZED napisaniem kodu produkcyjnego
GREEN     — napisz minimalny kod, który sprawia, że test przechodzi
REFACTOR  — poprawiaj kod bez łamania testów; clang-tidy pilnuje jakości, ASan/UBSan pilnuje
             bezpieczeństwa pamięci w tle na każdym uruchomieniu testów
```

W przeciwieństwie do `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react`, gdzie duża część "testowania" bezpieczeństwa pamięci jest zbędna (kompilator już to gwarantuje), w tym projekcie **testy z sanitizerami (ASan/UBSan/TSan) i fuzzing są częścią głównego cyklu TDD**, nie dodatkiem — RED dla funkcji parsującej niezaufane dane oznacza tu również "napisz najpierw harness fuzzingowy", nie tylko przykład.

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
```cpp
TEST(FrameworkServiceTest, ListReturnsAtLeastTenSeededFrameworks) {
    auto env = testEnv();
    auto frameworks = FrameworkService::list(env);
    EXPECT_GE(frameworks.size(), 10);
}

TEST(FrameworkControllerTest, Detail404sForUnknownCode) {
    auto client = testClient();
    auto req = drogon::HttpRequest::newHttpRequest();
    req->setPath("/api/v1/frameworks/NOT_REAL");
    auto [result, resp] = client->sendRequest(req);
    EXPECT_EQ(resp->statusCode(), drogon::k404NotFound);
}
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
```cpp
TEST(ThreatServiceTest, CombinesFrameworkAndSeverityFilters) {
    auto env = testEnv();
    auto result = ThreatService::list(env, ThreatFilter{
        .frameworkCode = "OWASP_LLM", .severity = Severity::Critical});
    for (const auto& t : result) {
        EXPECT_EQ(t.frameworkCode, "OWASP_LLM");
        EXPECT_EQ(t.severity, Severity::Critical);
    }
}

TEST(ThreatControllerTest, RejectsQueryLongerThan200Chars) {
    auto client = testClient();
    auto req = drogon::HttpRequest::newHttpRequest();
    req->setPath("/api/v1/threats");
    req->setParameter("q", std::string(201, 'a'));
    auto [result, resp] = client->sendRequest(req);
    EXPECT_EQ(resp->statusCode(), drogon::k422UnprocessableEntity);
}
```

**E2E:** `us02-threat-filter.spec.ts` — combine filters, assert result count changes without navigation.

---

## US-03 — Szczegóły zagrożenia z mitigacjami i kodem

**Rola:** security engineer
**Potrzeba:** widzieć szczegóły zagrożenia z mitigacjami i próbkami kodu w 5 językach
**Cel:** wiedzieć jak wdrożyć ochronę

### Plan testów TDD

**Backend:**
```cpp
RC_GTEST_PROP(MitigationTest, EverySeededMitigationHasAllFiveLanguages, ()) {
    auto mitigation = *rc::gen::elementOf(seededMitigations());
    std::set<CodeLanguage> langs;
    for (const auto& s : mitigation.codeSamples) langs.insert(s.language);
    RC_ASSERT(langs == std::set<CodeLanguage>{
        CodeLanguage::Python, CodeLanguage::Java, CodeLanguage::Go,
        CodeLanguage::Scala, CodeLanguage::Lua});
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

**E2E:** `us03-threat-detail.spec.ts`.

---

## US-04 — Mapowanie cross-framework (LLM01 → MITRE ATLAS)

**Rola:** CompTIA SecAI+ student
**Potrzeba:** zobaczyć jak LLM01 Prompt Injection mapuje do MITRE ATLAS AML.T0051
**Cel:** zrozumieć zależności między frameworkami

### Plan testów TDD

**Backend:**
```cpp
TEST(CrossReferenceServiceTest, Llm01MapsToAmlT0051) {
    auto env = testEnv();
    auto refs = CrossReferenceService::bySourceCode(env, "LLM01");
    bool found = std::ranges::any_of(refs, [](auto& r) { return r.targetCode == "AML.T0051"; });
    EXPECT_TRUE(found);
}
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
```cpp
TEST(CardServiceTest, FreCardsEachCarryAtLeastOneOwaspRef) {
    auto env = testEnv();
    auto cards = CardService::bySuit(env, "FRE");
    for (const auto& c : cards) EXPECT_FALSE(c.owaspRefs.empty());
}

TEST(CardServiceTest, Fre4PolishTranslationIsReviewedNotIdenticalToEnglish) {
    auto env = testEnv();
    auto card = CardService::byCardId(env, "FRE4", Locale::Pl);
    EXPECT_NE(card.descriptionPl, card.descriptionEn);
    EXPECT_NE(card.descriptionPl.find("James wstrzykuje"), std::string::npos);
}
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
```cpp
TEST(MatrixServiceTest, LlmMatrixMapsLlm10ToCardLlm2) {
    auto env = testEnv();
    auto matrix = MatrixService::llm(env);
    auto rows = matrix.rowsFor("LLM10");
    bool found = std::ranges::any_of(rows, [](auto& r) { return r.cardId == "LLM2"; });
    EXPECT_TRUE(found);
}
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
```cpp
TEST(CardServiceTest, AaiKIsFlaggedCritical) {
    auto env = testEnv();
    auto card = CardService::byCardId(env, "AAIK", Locale::En);
    EXPECT_TRUE(card.isCritical);
}

TEST(CardServiceTest, Cld3CrossReferencesA05) {
    auto env = testEnv();
    auto card = CardService::byCardId(env, "CLD3", Locale::En);
    EXPECT_TRUE(std::ranges::find(card.owaspRefs, OwaspRef::trusted("A05:2021")) != card.owaspRefs.end());
}
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
```cpp
TEST(StrideHeatmapServiceTest, ReturnsExactlySixCategories) {
    auto env = testEnv();
    auto heatmap = StrideHeatmapService::compute(env);
    EXPECT_EQ(heatmap.categories.size(), 6);
}

TEST(StrideHeatmapControllerTest, RequiresAuth) {
    auto client = testClient();
    auto req = drogon::HttpRequest::newHttpRequest();
    req->setPath("/api/v1/stride-heatmap");
    auto [result, resp] = client->sendRequest(req);
    EXPECT_EQ(resp->statusCode(), drogon::k401Unauthorized);
}
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
```cpp
TEST(CardServiceTest, Emr2HasNoOwaspRefButHasMiscNote) {
    auto env = testEnv();
    auto card = CardService::byCardId(env, "EMR2", Locale::En);
    EXPECT_TRUE(card.owaspRefs.empty());
    EXPECT_TRUE(card.miscNote.has_value());
}
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
```cpp
TEST(MatrixServiceTest, MobileVsWebMapsMasvsStorage) {
    auto env = testEnv();
    auto matrix = MatrixService::mobileVsWeb(env);
    EXPECT_FALSE(matrix.rowsFor("MASVS-STORAGE").empty());
}
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
```cpp
TEST(RateLimitTest, BotSuitReturns429After60Requests) {
    auto client = testClient();
    for (int i = 0; i < 60; ++i) {
        auto req = drogon::HttpRequest::newHttpRequest();
        req->setPath("/api/v1/threats");
        req->setParameter("suit", "BOT");
        client->sendRequest(req);
    }
    auto req = drogon::HttpRequest::newHttpRequest();
    req->setPath("/api/v1/threats");
    req->setParameter("suit", "BOT");
    auto [result, resp] = client->sendRequest(req);
    EXPECT_EQ(resp->statusCode(), drogon::k429TooManyRequests);
    EXPECT_TRUE(resp->getHeader("Retry-After").size() > 0);
}

TEST(CardServiceTest, DvoKCrossReferencesA06) {
    auto env = testEnv();
    auto card = CardService::byCardId(env, "DVOK", Locale::En);
    EXPECT_TRUE(std::ranges::find(card.owaspRefs, OwaspRef::trusted("A06:2021")) != card.owaspRefs.end());
}
```

**Concurrency note:** this test suite (and the rate limiter it exercises) is additionally run under `-fsanitize=thread` in the nightly CI job (`PLAN.md` D-08, SR-05.4) — the `#[tokio::test]`/STM-equivalent race-freedom guarantee `app04_scala_react`/`app06_HASKELL_react`/`app07_rust_react` get from their language is, here, only as strong as this TSan run's coverage of the code path.

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
```cpp
TEST(CardServiceTest, WebsiteAppHasExactlySixSuits) {
    auto env = testEnv();
    auto suits = CardService::suitsByEdition(env, Edition::Webapp);
    std::sort(suits.begin(), suits.end());
    EXPECT_EQ(suits, (std::vector<std::string>{"AT", "AZ", "C", "CR", "SM", "VE"}));
}

TEST(CardServiceTest, Ve3CrossReferencesA03) {
    auto env = testEnv();
    auto card = CardService::byCardId(env, "VE3", Locale::En);
    EXPECT_TRUE(std::ranges::find(card.owaspRefs, OwaspRef::trusted("A03:2021")) != card.owaspRefs.end());
}
```

**E2E:** `us12-website-app.spec.ts`.

---

## US-13 — Próbki kodu Python

**Rola:** Python developer
**Potrzeba:** zobaczyć próbkę kodu Python dla każdej mitigacji
**Cel:** skopiować bezpieczny wzorzec

### Plan testów TDD

**Backend:**
```cpp
RC_GTEST_PROP(CodeSampleTest, EverySeededMitigationHasAPythonSample, ()) {
    auto mitigation = *rc::gen::elementOf(seededMitigations());
    bool hasPython = std::ranges::any_of(mitigation.codeSamples,
        [](auto& s) { return s.language == CodeLanguage::Python; });
    RC_ASSERT(hasPython);
}
```

**E2E:** `us13-python-code.spec.ts`.

---

## US-14 — Próbki kodu Java

**Rola:** Java developer
**Potrzeba:** zobaczyć próbkę kodu Java dla każdej mitigacji
**Cel:** porównać z implementacją C++ tej samej aplikacji

### Plan testów TDD

**Backend:** analogicznie do US-13, właściwość sprawdza obecność `Java` w każdej mitigacji.

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
```cpp
TEST(CodeSampleServiceTest, Llm2MitigationHasLuaRestyLimitReqSample) {
    auto env = testEnv();
    auto samples = CodeSampleService::byMitigationId(env, llm2MitigationId());
    auto it = std::ranges::find_if(samples, [](auto& s) { return s.language == CodeLanguage::Lua; });
    ASSERT_NE(it, samples.end());
    EXPECT_NE(it->code.find("lua-resty-limit-req"), std::string::npos);
}
```

**E2E:** `us16-lua-code.spec.ts`.

---

## US-17 — Globalne wyszukiwanie

**Rola:** pentester
**Potrzeba:** wyszukać frazę i znaleźć wszystkie powiązane zagrożenia z obroną
**Cel:** złożyć checklistę testów dla klienta

### Plan testów TDD

**Backend:**
```cpp
TEST(SearchServiceTest, ReturnsHighlightedExcerpts) {
    auto env = testEnv();
    auto results = SearchService::query(env, "deepfake", Locale::En);
    ASSERT_FALSE(results.empty());
    EXPECT_NE(results[0].excerpt.find("<mark>"), std::string::npos);
}

TEST(SearchControllerTest, RejectsQueryOver200Chars) {
    auto client = testClient();
    auto req = drogon::HttpRequest::newHttpRequest();
    req->setPath("/api/v1/search");
    req->setParameter("q", std::string(201, 'a'));
    auto [result, resp] = client->sendRequest(req);
    EXPECT_EQ(resp->statusCode(), drogon::k422UnprocessableEntity);
}
```

**E2E:** `us17-global-search.spec.ts`.

---

## US-18 — Eksport do CSV/PDF

**Rola:** team lead
**Potrzeba:** wyeksportować przefiltrowaną listę zagrożeń do CSV/PDF
**Cel:** dodać ją do rejestru ryzyk

### Plan testów TDD

**Backend:**
```cpp
TEST(ExportControllerTest, EnqueuesJobAndReturns202) {
    auto client = testClient();
    auto req = drogon::HttpRequest::newHttpRequest();
    req->setPath("/api/v1/export");
    req->setParameter("format", "csv");
    req->setParameter("framework", "OWASP_LLM");
    auto [result, resp] = client->sendRequest(req);
    EXPECT_EQ(resp->statusCode(), drogon::k202Accepted);
    auto json = nlohmann::json::parse(resp->body());
    EXPECT_FALSE(json["jobId"].get<std::string>().empty());
}

TEST(ExportJobTest, RejectsArgsMissingFramework) {
    ExportCsvArgs args{.format = "csv", .framework = ""};
    EXPECT_FALSE(validateExportArgs(args).has_value()); // AC-14
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
| ARC2 | ARC — Architecture | "Theo formulates identity verification resulting in limited ways to verify new accounts" | *"Theo formułuje weryfikację identyfikacji w sposób ograniczający metody weryfikacji nowych kont"* | **A04:2021 Insecure Design**, pokrewne STRIDE: Spoofing |
| ARC3 | ARC | "Oakley pulls the service into a shape which largely or completely excludes the use of paper for any input and output by claimants" | *"Oakley nadaje usłudze formę, która w dużej mierze lub całkowicie wyklucza możliwość użycia papieru do wejścia lub wyjścia danych"* | Harm projektowy — wykluczenie cyfrowe; **A04:2021** ("secure AND accessible by design") |

**Ważna uwaga metodologiczna:** ta talia — w przeciwieństwie do FRE/LLM/AAI/CLD/STRIDE/MLSec/Mobile/DVO/BOT/Website App — **nie opisuje podatności technicznych z określonym poziomem severity**. W modelu danych C++ karta `dbd` ma `kind` będące `std::variant<TechnicalThreat, DesignHarm>` z wartością `DesignHarm{}` — alternatywa **bez pola** severity (patrz `PLAN.md` D-04). `std::visit` z wyczerpującym zbiorem przeciążeń jest błędem kompilacji, jeśli nie obsługuje obu alternatyw — **ale** to jedyna gwarancja w tym projekcie, która zależy od tego, czy programista użył `std::visit`, a nie `std::get_if<TechnicalThreat>` z zignorowaniem przypadku `DesignHarm`. Test integracyjny poniżej istnieje właśnie po to, by wykryć regresję do tego drugiego wzorca.

### Kryteria akceptacji
- `/frameworks/digital-harms` wyświetla wszystkie karty pogrupowane po 5 suitach
- Każda karta renderowana jest z `DesignHarmBadge`, nigdy z `SeverityBadge`
- Banner disclaimera wyjaśnia harm projektowy vs. podatność techniczna
- Odpowiedź JSON dla kart `SCO|ARC|AGE|TRU|POR` nigdy nie zawiera wartości severity

### Plan testów TDD

**Backend:**
```cpp
TEST(CardKindTest, DesignHarmVariantHasNoSeverityField) {
    CardKind kind = DesignHarm{};
    auto severity = severity_of(kind); // std::visit z wyczerpującym overloaded{} — patrz D-04
    EXPECT_FALSE(severity.has_value());
}

TEST(CardServiceTest, Sco2CrossReferencesA04) {
    auto env = testEnv();
    auto card = CardService::byCardId(env, "SCO2", Locale::En);
    EXPECT_TRUE(std::ranges::find(card.owaspRefs, OwaspRef::trusted("A04:2021")) != card.owaspRefs.end());
}

TEST(CardControllerTest, DigitalHarmsSuitsNeverReturnASeverityValue) {
    auto client = testClient();
    auto req = drogon::HttpRequest::newHttpRequest();
    req->setPath("/api/v1/threats");
    req->setParameter("suit", "SCO");
    auto [result, resp] = client->sendRequest(req);
    auto json = nlohmann::json::parse(resp->body());
    for (const auto& item : json["items"]) {
        EXPECT_EQ(item["kind"]["kind"], "DesignHarm");
        EXPECT_FALSE(item["kind"].contains("severity"));
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

  test('API response for dbd cards never carries a severity value', async ({ request }) => {
    const response = await request.get('/api/v1/threats?suit=SCO')
    const body = await response.json()
    for (const card of body.items) {
      expect(card.kind.kind).toBe('DesignHarm')
      expect(card.kind.severity).toBeUndefined()
    }
  })
})
```

---

## Podsumowanie planu testów

### Cel: ≥ 200 testów łącznie

| Warstwa | Framework | Liczba | Typ |
|---|---|---|---|
| Backend — unit | GoogleTest | ≥ 55 | Serwisy, konstruktory typów, JSON encoding |
| Backend — właściwości | `RapidCheck` | ≥ 15 | Niezmienniki (5 języków per mitigacja, YAML z nieznanymi polami odrzucany) |
| Backend — integracja | Drogon test client + testowa PostgreSQL (Docker) | ≥ 26 | Kontrolery, zapytania libpqxx/sqlpp11, rate-limit |
| Backend — fuzzing | `libFuzzer` | ≥ 5 harnessów | Loader YAML (6 talii), deserializery JSON, parser Accept-Language |
| Frontend — komponenty | Vitest + React Testing Library | ≥ 43 | Komponenty UI, hooki, store'y |
| Frontend — serwisy | Vitest + MSW 2 | ≥ 15 | fetch/React Query, interceptory, i18n |
| E2E | Playwright | ≥ 27 | 19 plików spec × ~1.4 scenariuszy |
| **RAZEM** | | **≥ 200 + fuzzing continuous** | |

### Cele pokrycia kodu

| Warstwa | Narzędzie | Cel |
|---|---|---|
| Backend C++ | `gcov`/`llvm-cov` | ≥ 85% dla `core::service` |
| Frontend React | Vitest v8 coverage | ≥ 75% |

### Kolejność wykonania testów w CI

```
[1] clang-tidy (cppcoreguidelines/bugprone/cert)  — SAST, na każdym PR
[2] cmake --build . --config Debug -DSANITIZE=address,undefined  — build z ASan/UBSan
[3] ctest                                          — GoogleTest + RapidCheck (build z sanitizerami)
[4] libFuzzer targets (10 min budget per PR)        — fuzzing powierzchni parsujących
[5] cmake --build . --config Debug -DSANITIZE=thread — build z TSan (nightly)
[6] ctest --label-regex concurrency                 — testy współbieżności pod TSan (nightly)
[7] OWASP Dependency-Check + vcpkg/conan audit       — SCA
[8] npm run test                                     — Vitest + RTL (coverage report)
[9] npm run build                                     — Vite production build (< 600 KB gzip initial)
[10] npm run e2e                                      — Playwright headless Chromium + Firefox
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
| AC-01: SQL Injection `?q=` | CI grep + integration test — brak ścieżki string-built SQL | Sprint 3–4 |
| AC-02: XSS w opisie karty | `SafeHtml`/DOMPurify integration test | Sprint 5–7 |
| AC-05: Bot scraping | Drogon test client — 429 po 60 req | Sprint 10–12 |
| AC-06: YAML file tampering | `integrity::verify` — abort na hash mismatch | Sprint 5–7 |
| AC-09: Privilege escalation `/stride-heatmap` | JWT middleware — 401 bez roli | Sprint 5–7 |
| AC-11: i18n locale injection | `Locale` enum — parsowanie nieznanej wartości zwraca `En` | Sprint 9–10 |
| AC-14: Malicious job payload | `validateExportArgs` odrzuca niekompletne dane | Sprint 10–12 |
| AC-15: BotWarningModal bypass | `us11-devops-security.spec.ts` — bezpośrednie wywołanie API wciąż zablokowane | Sprint 5–7 |
| AC-16: Harms deck misread as CVE severity | Test JSON encoding — brak wartości severity dla `DesignHarm`; wymaga code review na `std::visit` vs `std::get_if` | Sprint 5–7 |
| AC-17: Memory-corruption vulnerability | ASan/UBSan na każdym uruchomieniu testów; `libFuzzer` continuous run; **jedyny abuse case w serii wymagający ciągłego, a nie jednorazowego, dowodu nieobecności** | Sprint 1–2 (weryfikowane co sprint) |
