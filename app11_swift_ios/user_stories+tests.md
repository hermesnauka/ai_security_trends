# SwiftGuard 2026 — User Stories & TDD Test Plan

**Version:** 1.0
**Date:** 2026-07-07
**Stack:** Swift 6, SwiftUI + SwiftData (native iOS, no server backend)
**Test frameworks:** `XCTest` (unit/integration) + `SwiftCheck` (property-based) + `XCUITest` (native UI/E2E — replaces Playwright, since there is no browser to drive)

---

## Konwencje testowe

### Unit / integration (`XCTest`, in-memory `ModelContainer`)
```swift
final class ThreatRepositoryTests: XCTestCase {
    func testFiltersBySeverity() throws {
        let container = try TestSupport.inMemoryContainer(seeded: true)
        let repo = SwiftDataThreatRepository(modelContext: container.mainContext)
        let result = try repo.list(filter: ThreatFilter(severity: .critical))
        XCTAssertTrue(result.allSatisfy { $0.severity == .critical })
    }
}
```

### Property-based (`SwiftCheck`)
```swift
final class CardFileDecoderPropertyTests: XCTestCase {
    func testRejectsUnknownTopLevelFields() {
        property("card file decoder rejects unrecognized top-level keys") <- forAll { (extraKey: NonEmptyString) in
            let yaml = "meta:\n  edition: webapp\n\(extraKey.value): evil\nsuits: []\n"
            return (try? CardFileDecoder.decode(yaml: yaml)) == nil
        }
    }
}
```

### UI / E2E (`XCUITest` — the native equivalent to every sibling's Playwright suite)
```swift
final class US03ThreatDetailUITests: XCTestCase {
    func testDoesNotShowAttackDemoCodeBeforeConfirmation() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Threats"].tap()
        app.staticTexts["LLM01"].tap()
        app.buttons["Code"].tap()
        XCTAssertFalse(app.staticTexts["attack-demo-code-body"].exists)
        app.buttons["Rozumiem"].tap()
        XCTAssertTrue(app.staticTexts["attack-demo-code-body"].waitForExistence(timeout: 2))
    }
}
```

---

## Zasada TDD stosowana w tym projekcie

```
RED       — napisz test (XCTest, właściwość SwiftCheck, lub scenariusz XCUITest) opisujący
             oczekiwane zachowanie PRZED napisaniem kodu produkcyjnego
GREEN     — napisz minimalny kod, który sprawia, że test przechodzi
REFACTOR  — poprawiaj kod bez łamania testów; kompilator Swifta (wyczerpujące `switch` nad
             `enum`) pilnuje jakości w tle na każdym build
```

**Uwaga strukturalna:** w tym projekcie nie ma testów integracyjnych API (nie istnieje żadne REST API) — warstwa "integracyjna" to testy `Repository` przeciwko rzeczywistemu, ale w-pamięci, `ModelContainer` SwiftData. Warstwa E2E to `XCUITest`, sterujący prawdziwą, skompilowaną aplikacją w Symulatorze, nie przeglądarką.

---

## US-01 — Katalog frameworków bezpieczeństwa

**Rola:** security engineer
**Potrzeba:** przeglądać katalog wszystkich frameworków bezpieczeństwa
**Cel:** mieć jeden punkt dostępu do wszystkich standardów

### Kryteria akceptacji
- Ekran główny wyświetla kafelek per framework z liczbą zagrożeń
- Dotknięcie kafelka nawiguje do listy zagrożeń danego frameworku

### Plan testów TDD

**Unit/integration:**
```swift
func testList_ReturnsAtLeastTenSeededFrameworks() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataFrameworkRepository(modelContext: container.mainContext)
    XCTAssertGreaterThanOrEqual(try repo.list().count, 10)
}
```

**XCUITest:** `US01FrameworksUITests.swift`.

---

## US-02 — Przeglądarka zagrożeń z filtrami

**Rola:** security engineer
**Potrzeba:** filtrować zagrożenia po frameworku, severity, STRIDE, tagu, `q`
**Cel:** szybko znaleźć zagrożenia istotne dla mojego projektu

### Plan testów TDD

**Unit/integration:**
```swift
func testCombinesFrameworkAndSeverityFilters() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataThreatRepository(modelContext: container.mainContext)
    let result = try repo.list(filter: ThreatFilter(frameworkCode: "OWASP_LLM", severity: .critical))
    XCTAssertTrue(result.allSatisfy { $0.frameworkCode == "OWASP_LLM" && $0.severity == .critical })
}
```

**XCUITest:** `US02ThreatFilterUITests.swift` — combine filters, assert result count changes in place.

---

## US-03 — Szczegóły zagrożenia z mitigacjami i kodem

**Rola:** security engineer
**Potrzeba:** widzieć szczegóły zagrożenia z mitigacjami i próbkami kodu w 5 językach
**Cel:** wiedzieć jak wdrożyć ochronę

### Plan testów TDD

**Property-based:**
```swift
func testEverySeededMitigationHasAllFiveLanguages() {
    property("every seeded mitigation has all five languages") <- forAll(SeededMitigationGen.instance) { mitigation in
        let languages = Set(mitigation.codeSamples.map(\.language))
        return languages == [.python, .java, .go, .scala, .lua]
    }
}
```

**XCUITest:** `US03ThreatDetailUITests.swift` (shown in "Konwencje testowe" above).

---

## US-04 — Mapowanie cross-framework (LLM01 → MITRE ATLAS)

**Rola:** CompTIA SecAI+ student
**Potrzeba:** zobaczyć jak LLM01 Prompt Injection mapuje do MITRE ATLAS AML.T0051
**Cel:** zrozumieć zależności między frameworkami

### Plan testów TDD

**Unit/integration:**
```swift
func testLlm01MapsToAmlT0051() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataMatrixRepository(modelContext: container.mainContext)
    let refs = try repo.crossReferences(sourceCode: "LLM01")
    XCTAssertTrue(refs.contains { $0.targetThreatCode == "AML.T0051" })
}
```

**XCUITest:** `US04CrossReferenceUITests.swift`.

---

## US-05 — Bezpieczeństwo frontend/client-side (karty FRE)

**Rola:** mobile/frontend developer
**Potrzeba:** przeglądać karty Cornucopia FRE (Companion Edition v1.0) z polskimi opisami
**Cel:** mapować scenariusze ataków po stronie klienta na mitigacje

### Polskie tłumaczenia kart FRE (z `__LLM_AI___companion-cards-1.0-en.yaml`)

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie OWASP |
|---|---|---|---|
| FRE2 | "Marcus bypasses client-side validation and sends malformed or malicious input directly to backend APIs, triggering logic flaws, human errors, and usability issues" | *"Marcus omija walidację po stronie klienta i wysyła zniekształcone lub złośliwe dane bezpośrednio do API backendu, wywołując błędy logiki, błędy ludzkie i problemy użytkowe"* | **A03:2021 Injection / A04:2021 Insecure Design** |
| FRE3 | "Lena can access sensitive or confidential information because it's not removed after logout or when the client session ends" | *"Lena może uzyskać dostęp do danych wrażliwych, ponieważ nie są one usuwane po wylogowaniu lub zakończeniu sesji klienta"* | **A01:2021 Broken Access Control** |
| FRE4 | "James injects JavaScript through user-controlled data that is written into the DOM, executing arbitrary code in the victim's browser" | *"James wstrzykuje JavaScript poprzez dane kontrolowane przez użytkownika, które są zapisywane do DOM, wykonując dowolny kod w przeglądarce ofiary"* | **A03:2021 Injection (DOM XSS)** — pokrewne SR-05 (SwiftUI `Text` nie interpretuje HTML) |
| FRE5 | "Victor compromises or replaces a third-party script loaded from a CDN and runs malicious code in every user's browser" | *"Victor kompromituje lub zamienia skrypt zewnętrzny wczytywany z CDN i wykonuje złośliwy kod w przeglądarce każdego użytkownika"* | **A06:2021 Vulnerable and Outdated Components** — pokrewne C-03 (brak zewnętrznych CDN w tej aplikacji) |

### Plan testów TDD

**Unit/integration:**
```swift
func testFreCards_EachCarryAtLeastOneOwaspRef() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCardRepository(modelContext: container.mainContext)
    let cards = try repo.bySuit("FRE")
    XCTAssertTrue(cards.allSatisfy { !$0.owaspRefs.isEmpty })
}

func testFre4_PolishTranslationIsReviewedNotIdenticalToEnglish() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCardRepository(modelContext: container.mainContext)
    let card = try repo.byCardId("FRE4")!
    XCTAssertNotEqual(card.descriptionPl, card.descriptionEn)
    XCTAssertTrue(card.descriptionPl.contains("James wstrzykuje"))
}
```

**XCUITest:** `US05FrontendSecurityUITests.swift`.

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

**Unit/integration:**
```swift
func testLlmMatrix_MapsLlm10ToCardLlm2() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataMatrixRepository(modelContext: container.mainContext)
    let matrix = try repo.llmMatrix()
    XCTAssertTrue(matrix.rows(for: "LLM10").contains { $0.cardId == "LLM2" })
}
```

**XCUITest:** `US06LlmSecurityUITests.swift` — empty cells render a dashed placeholder.

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
| CLD2 | "Dan can abuse overly permissive roles assigned to an application to gain full access to cloud services beyond its intended scope" | *"Dan może wykorzystać nadmiernie permisywne role przypisane aplikacji, aby uzyskać pełny dostęp do usług cloud poza zamierzonym zakresem"* | **A01:2021 Broken Access Control** — pokrewne D-01 (minimalny zestaw entitlements tej aplikacji) |
| CLD3 | "Roupe can discover a publicly accessible cloud storage and download sensitive customer data directly from the internet" | *"Roupe może odnaleźć publicznie dostępny magazyn danych w chmurze i pobrać wrażliwe dane klientów bezpośrednio z internetu"* | **A05:2021 Security Misconfiguration** |
| CLD4 | "Ryan can operate within critical cloud services without triggering alerts by exploiting the absence of audit logs and security monitoring" | *"Ryan może działać w krytycznych usługach cloud bez wywoływania alertów, wykorzystując brak logów audytowych"* | **A09:2021 Security Logging and Monitoring Failures** |

### Plan testów TDD

**Unit/integration:**
```swift
func testAaiK_IsFlaggedCritical() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCardRepository(modelContext: container.mainContext)
    let card = try repo.byCardId("AAIK")!
    XCTAssertTrue(card.isCritical)
}

func testCld3_CrossReferencesA05() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCardRepository(modelContext: container.mainContext)
    let card = try repo.byCardId("CLD3")!
    XCTAssertTrue(card.owaspRefs.contains("A05:2021"))
}
```

**XCUITest:** `US07AgenticAiUITests.swift` — AAIK/AAIQ show "AUTONOMY RISK" badge; CLD cards visible on the DevOps screen.

---

## US-08 — STRIDE EoP — katalog i heatmapa

**Rola:** security architect / threat modeler
**Potrzeba:** używać katalogu kart STRIDE EoP z interaktywną heatmapą
**Cel:** prowadzić ustrukturyzowaną sesję threat modelingu

### Polskie tłumaczenia kart STRIDE (z `STRIDE__eop-cards-5.0-en.yaml`)

| Karta | STRIDE | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|---|
| SP2 | Spoofing | "An attacker could take over the port or socket that the server normally uses" | *"Atakujący może przejąć port lub gniazdo, które normalnie wykorzystuje serwer"* | **A05:2021 Security Misconfiguration** — nieaplikowalne bezpośrednio do tej aplikacji (brak serwera), ale pokrewne treści szkoleniowej dla studenta |
| SP3 | Spoofing | "An attacker could try one credential after another and there's nothing to slow them down (online or offline)" | *"Atakujący może próbować kolejnych danych uwierzytelniających bez żadnego mechanizmu spowalniającego"* | **A07:2021 Identification and Authentication Failures** — pokrewne SR-11 (Sign in with Apple, brak własnego uwierzytelniania) |
| TA2 | Tampering | "An attacker can take advantage of your custom key exchange or integrity control which you built instead of using standard crypto" | *"Atakujący może wykorzystać własną implementację wymiany kluczy zamiast standardowej kryptografii"* | **A02:2021 Cryptographic Failures** — pokrewne SR-11 (użycie natywnych frameworków Apple, brak własnej kryptografii) |
| TA6 | Tampering | "An attacker can write to a data store your code relies on" | *"Atakujący może zapisywać dane w magazynie danych, na którym opiera się kod"* | **A01:2021 Broken Access Control / A08:2021 Software and Data Integrity Failures** — pokrewne D-01 (App Sandbox) |

### Plan testów TDD

**Unit/integration:**
```swift
func testHeatmap_ReturnsExactlySixCategories() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataMatrixRepository(modelContext: container.mainContext)
    let heatmap = try repo.strideHeatmap()
    XCTAssertEqual(heatmap.categories.count, 6)
}
```

**XCUITest:** `US08StrideUITests.swift` — 78 cards across 6 suits; heatmap requires local authentication (Face ID/Touch ID/passcode).

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

**Unit/integration:**
```swift
func testEmr2_HasNoOwaspRefButHasMiscNote() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCardRepository(modelContext: container.mainContext)
    let card = try repo.byCardId("EMR2")!
    XCTAssertTrue(card.owaspRefs.isEmpty)
    XCTAssertNotNil(card.miscNote)
}
```

**XCUITest:** `US09MlSecurityUITests.swift` — "ML-SPECIFIC" badge shown; no fabricated OWASP badge for EMR2.

---

## US-10 — Bezpieczeństwo mobile (karty Mobile MAS) — pokrewne z własnym modelem zagrożeń tej aplikacji

**Rola:** iOS/Android developer
**Potrzeba:** zobaczyć zagrożenia OWASP MASVS przez karty Cornucopia Mobile App, powiązane z decyzjami projektowymi TEJ aplikacji
**Cel:** zrozumieć jak kontrolki bezpieczeństwa mobile różnią się od web, na żywym przykładzie

### Polskie tłumaczenia kart Mobile

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie | Powiązanie z SwiftGuard 2026 |
|---|---|---|---|---|
| PC2 | "Andrew can expose sensitive data through the app's auto-generated screenshots when the app moves to the background" | *"Andrew może ujawnić dane wrażliwe poprzez automatycznie generowane zrzuty ekranu, gdy aplikacja przechodzi w tło"* | **MASVS-STORAGE** | Ta aplikacja nie przechowuje danych wrażliwych wymagających maskowania w tle (treść edukacyjna jest publiczna) — jedyne dane użytkownika to `Bookmark`, bez pól wrażliwych |
| PC3 | "Harold can spy sensitive data being entered through the user interface because the data is excessive, not properly masked or cleaned up after use" | *"Harold może przechwycić dane wrażliwe wprowadzane w interfejsie, ponieważ są nadmiarowe, niewłaściwie maskowane"* | **MASVS-STORAGE** | Nie dotyczy — aplikacja nie posiada formularzy wprowadzania danych uwierzytelniających (Sign in with Apple obsługuje to poza tą aplikacją) |
| PC4 | "Kelly can expose sensitive data by taking advantage of the app's excessive permissions" | *"Kelly może ujawnić dane wrażliwe, wykorzystując nadmiarowe uprawnienia aplikacji"* | **MASVS-PLATFORM** | Bezpośrednio pokrewne SR-01/D-01: entitlements ograniczone wyłącznie do `com.apple.developer.icloud-services` |

### Plan testów TDD

**Unit/integration:**
```swift
func testMobileVsWeb_MapsMasvsStorage() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataMatrixRepository(modelContext: container.mainContext)
    let matrix = try repo.mobileVsWebMatrix()
    XCTAssertFalse(matrix.rows(for: "MASVS-STORAGE").isEmpty)
}

func testMasvsPlatformCard_CrossReferencesOwnEntitlementsDecision() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCardRepository(modelContext: container.mainContext)
    let card = try repo.byCardId("PC4")!
    XCTAssertTrue(card.descriptionPl.contains("entitlements") || card.miscNote?.contains("D-01") == true)
}
```

**XCUITest:** `US10MobileSecurityUITests.swift` — the PC4 card detail screen shows the "SwiftGuard's own design" cross-reference callout (FR-10.3).

---

## US-11 — Bezpieczeństwo DevOps + Cloud (karty DVO + CLD + BOT)

**Rola:** DevSecOps engineer / team lead
**Potrzeba:** przeglądać ryzyka supply chain (DVO), błędną konfigurację cloud (CLD) i wzorce automatycznych ataków (BOT)
**Cel:** chronić potoki CI/CD, ograniczać ryzyko cloud i bronić się przed botami

### Polskie tłumaczenia kart DVO + BOT

| Karta | Suit | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|---|
| DVOK | DVO | "Timo can compromise software, development environments, or DevOps tooling by injecting malicious code via external dependencies or exploited developer credentials" | *"Timo może skompromitować oprogramowanie, środowiska developerskie lub narzędzia DevOps, wstrzykując złośliwy kod przez zewnętrzne zależności"* | **CICD-SEC-3 Dependency Chain Abuse**, A06:2021 — pokrewne SR-10.3 (ograniczona liczba zależności SPM, kwartalny przegląd manualny) |
| DVOQ | DVO | "Seba can access the code repository, log files, command line history, pipelines, or other places, to gain access to secrets or other sensitive information" | *"Seba może uzyskać dostęp do repozytorium kodu, logów, historii linii komend lub pipeline'ów, aby zdobyć sekrety"* | **CICD-SEC-6 Insufficient Credential Hygiene** — pokrewne §2 (brak sekretów po stronie serwera; jedyny "sekret" to App Store Connect API key w CI) |
| BOTK | BOT | "EDVAC can collect application content and/or other data for use elsewhere" | *"EDVAC może zbierać treść aplikacji i/lub inne dane do wykorzystania gdzie indziej"* | **OAT-011 Scraping** — ograniczone znaczenie dla aplikacji offline (brak API do skrapowania) |
| BOTX | BOT | "Ferranti Pegasus can enumerate individual authentication credentials, or payment card data... by trying different values" | *"Ferranti Pegasus może enumerować dane uwierzytelniające lub dane karty płatniczej, próbując różnych wartości"* | **OAT-021 Card Cracking / OAT-008 Credential Stuffing** — nieaplikowalne (brak własnego uwierzytelniania, patrz SR-11) |

### Plan testów TDD

**Unit/integration:**
```swift
func testDvoK_CrossReferencesA06() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCardRepository(modelContext: container.mainContext)
    let card = try repo.byCardId("DVOK")!
    XCTAssertTrue(card.owaspRefs.contains("A06:2021"))
}
```

**XCUITest:** `US11DevOpsSecurityUITests.swift` — DVO/CLD/BOT sections visible; BOT critical card gated by `.confirmationDialog`.

---

## US-12 — Bezpieczeństwo Website App (karty VE/AT/SM/AZ/CR/C)

**Rola:** backend developer
**Potrzeba:** przeglądać karty Cornucopia Website App Edition v3.0
**Cel:** mapować klasyczne scenariusze ataków OWASP Web Top 10 na mitigacje

### Polskie tłumaczenia kart VE (z `webapp-cards-3.0-en.yaml`)

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|
| VE2 | "Brian can gather information about the underlying configurations, schemas, logic, code... due to the content of error messages, or poor configuration, or the presence of default installation files" | *"Brian może zebrać informacje o konfiguracji, schematach, logice, kodzie poprzez treść komunikatów błędów lub słabą konfigurację"* | **A05:2021 Security Misconfiguration + A09:2021 Logging Failures** |
| VE3 | "Robert can input malicious data because the allowed protocol format is not being checked, or duplicates are accepted, or the structure is not being verified" | *"Robert może wprowadzić złośliwe dane, ponieważ nie jest sprawdzany dozwolony format lub nie weryfikuje się struktury"* | **A03:2021 Injection** — patrz SR-04: ta klasa podatności nie istnieje strukturalnie w tej aplikacji |
| VE4 | "Dave can input malicious field names or data because it is not being checked within the context of the current user and process" | *"Dave może wprowadzić złośliwe nazwy pól lub dane, ponieważ nie są sprawdzane w kontekście aktualnego użytkownika i procesu"* | **A01:2021 Broken Access Control** (mass assignment) |

### Plan testów TDD

**Unit/integration:**
```swift
func testWebsiteApp_HasExactlySixSuits() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCardRepository(modelContext: container.mainContext)
    let suits = try repo.suits(forEdition: "webapp").sorted()
    XCTAssertEqual(suits, ["AT", "AZ", "C", "CR", "SM", "VE"])
}

func testVe3_CrossReferencesA03() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCardRepository(modelContext: container.mainContext)
    let card = try repo.byCardId("VE3")!
    XCTAssertTrue(card.owaspRefs.contains("A03:2021"))
}
```

**XCUITest:** `US12WebsiteAppUITests.swift`.

---

## US-13 — Próbki kodu Python

**Rola:** Python developer
**Potrzeba:** zobaczyć próbkę kodu Python dla każdej mitigacji
**Cel:** skopiować bezpieczny wzorzec

### Plan testów TDD

**Property-based:**
```swift
func testEverySeededMitigationHasAPythonSample() {
    property("every seeded mitigation has a Python sample") <- forAll(SeededMitigationGen.instance) { mitigation in
        mitigation.codeSamples.contains { $0.language == .python }
    }
}
```

**XCUITest:** `US13PythonCodeUITests.swift`.

---

## US-14 — Próbki kodu Java

**Rola:** Java developer
**Potrzeba:** zobaczyć próbkę kodu Java dla każdej mitigacji
**Cel:** porównać z idiomami Swift/SwiftData tej aplikacji

### Plan testów TDD

**Property-based:** analogicznie do US-13, właściwość sprawdza obecność `.java` w każdej mitigacji.

**XCUITest:** `US14JavaCodeUITests.swift` — zakładka Java pokazuje idiom Spring Boot/Spring Security; próbka jest jednoznacznie oznaczona jako treść, niezwiązana z żadnym artefaktem budowania tej aplikacji.

---

## US-15 — Próbki kodu Scala (ataki supply-chain)

**Rola:** Scala developer
**Potrzeba:** znaleźć próbki kodu Scala dla ataków na łańcuch dostaw
**Cel:** zaimplementować SCA w pipeline Scali

### Plan testów TDD

**XCUITest:** `US15ScalaCodeUITests.swift` — filtruj próbki po `language=scala` i `tag=supply-chain`.

---

## US-16 — Próbki kodu Lua (rate limiting / LLM DoS)

**Rola:** Lua/OpenResty developer
**Potrzeba:** zobaczyć przykłady Lua dla rate limiting zapobiegającego LLM DoS
**Cel:** skonfigurować guardrails NGINX dla proxy LLM API

### Plan testów TDD

**Unit/integration:**
```swift
func testLlm2Mitigation_HasLuaRestyLimitReqSample() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCodeSampleRepository(modelContext: container.mainContext)
    let samples = try repo.byMitigationId(llm2MitigationId())
    let lua = samples.first { $0.language == .lua }!
    XCTAssertTrue(lua.code.contains("lua-resty-limit-req"))
}
```

**XCUITest:** `US16LuaCodeUITests.swift`.

---

## US-17 — Globalne wyszukiwanie

**Rola:** pentester
**Potrzeba:** wyszukać frazę i znaleźć wszystkie powiązane zagrożenia z obroną
**Cel:** złożyć checklistę testów dla klienta

### Plan testów TDD

**Unit/integration:**
```swift
func testSearch_ReturnsHighlightedExcerpts() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataSearchRepository(modelContext: container.mainContext)
    let results = try repo.query("deepfake", locale: .english)
    XCTAssertFalse(results.isEmpty)
}
```

**XCUITest:** `US17SearchUITests.swift`.

---

## US-18 — Eksport do CSV/PDF (natywny Share Sheet)

**Rola:** team lead
**Potrzeba:** wyeksportować przefiltrowaną listę zagrożeń do CSV/PDF przez natywny Share Sheet
**Cel:** dodać ją do rejestru ryzyk

### Plan testów TDD

**Unit/integration:**
```swift
func testExportCsv_ProducesAValidLocalFileSynchronously() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let service = LocalExportService(modelContext: container.mainContext)
    let url = try service.exportCsv(filter: ThreatFilter(frameworkCode: "OWASP_LLM"))
    XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
}
```

**XCUITest:** `US18ExportUITests.swift` — tapping "Export" presents the native Share Sheet with no polling/status screen (FR-17.4).

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

**Ważna uwaga metodologiczna:** ta talia — w przeciwieństwie do FRE/LLM/AAI/CLD/STRIDE/MLSec/Mobile/DVO/BOT/Website App — **nie opisuje podatności technicznych z określonym poziomem severity**. W modelu danych Swift karta `dbd` ma `kind` będące `CardKind.designHarm` — przypadek enuma **bez wartości skojarzonej** severity (patrz `PLAN.md` D-03). `switch` bez obsługi obu przypadków `CardKind` jest **bezwarunkowym błędem kompilacji** w Swift — nie ostrzeżeniem, i nie istnieje żadna flaga konfiguracyjna projektu, która mogłaby to wyłączyć (silniejsza gwarancja niż `CS8509` w `app10_csharp_react`, tej samej klasy co Rust i Haskell).

### Kryteria akceptacji
- Dedykowany ekran wyświetla wszystkie karty pogrupowane po 5 suitach
- Każda karta renderowana jest z odznaką "harm projektowy", nigdy z odznaką severity
- Banner disclaimera wyjaśnia harm projektowy vs. podatność techniczna
- Nie istnieje żaden sposób odczytania wartości severity dla karty `designHarm` — jest to fakt o systemie typów, nie tylko o danych w runtime

### Plan testów TDD

**Unit/integration:**
```swift
func testDesignHarmCase_HasNoSeverityAssociatedValue() {
    let kind = CardKind.designHarm
    let severity = severityOf(kind) // wyczerpujący switch, patrz PLAN.md D-03
    XCTAssertNil(severity)
    // Nie istnieje ŻADEN sposób skonstruowania `.designHarm` z wartością Severity —
    // ten test dokumentuje fakt o typie, nie tylko jedną instancję danych.
}

func testSco2_CrossReferencesA04() throws {
    let container = try TestSupport.inMemoryContainer(seeded: true)
    let repo = SwiftDataCardRepository(modelContext: container.mainContext)
    let card = try repo.byCardId("SCO2")!
    XCTAssertTrue(card.owaspRefs.contains("A04:2021"))
}
```

**XCUITest:**
```swift
final class US19DigitalHarmsUITests: XCTestCase {
    func testShowsAllFiveSuitsAndDisclaimerBanner() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Frameworks"].tap()
        app.staticTexts["Digital-by-Default Harms"].tap()
        XCTAssertTrue(app.staticTexts["harms-disclaimer-banner"].exists)
        for suit in ["SCO", "ARC", "AGE", "TRU", "POR"] {
            XCTAssertTrue(app.staticTexts[suit].exists)
        }
    }

    func testNeverShowsSeverityBadgeOnDbdCard() throws {
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Frameworks"].tap()
        app.staticTexts["Digital-by-Default Harms"].tap()
        app.staticTexts["SCO2"].tap()
        XCTAssertTrue(app.staticTexts["design-harm-badge"].exists)
        XCTAssertFalse(app.staticTexts["severity-badge"].exists)
    }

    func testSwitchingToPolishShowsReviewedSco2Translation() throws {
        let app = XCUIApplication()
        app.launch()
        app.buttons["language-toggle"].tap()
        app.tabBars.buttons["Frameworks"].tap()
        app.staticTexts["Digital-by-Default Harms"].tap()
        app.staticTexts["SCO2"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Tommy nie tworzy'")).firstMatch.waitForExistence(timeout: 2))
    }
}
```

---

## Podsumowanie planu testów

### Cel: ≥ 180 testów łącznie (nieco mniej niż siostrzane projekty webowe — brak warstwy API/HTTP do testowania integracyjnego zmniejsza łączną liczbę testów bez zmniejszania pokrycia funkcjonalnego)

| Warstwa | Framework | Liczba | Typ |
|---|---|---|---|
| Unit/integration | `XCTest` z `ModelContainer` w pamięci | ≥ 60 | Repozytoria, serwisy, konstruktory typów |
| Właściwości | `SwiftCheck` | ≥ 15 | Niezmienniki (5 języków per mitigacja, YAML z nieznanymi polami odrzucany) |
| UI/E2E | `XCUITest` | ≥ 27 | 19 plików testowych × ~1.4 scenariuszy, sterujące prawdziwą aplikacją w Symulatorze |
| **RAZEM** | | **≥ 100 (bez XCUITest) + 27 XCUITest** | |

### Cele pokrycia kodu

| Warstwa | Narzędzie | Cel |
|---|---|---|
| `SwiftGuardData` | Wbudowane pokrycie kodu Xcode | ≥ 85% |
| `SwiftGuardUI` | Wbudowane pokrycie kodu Xcode | ≥ 70% (Views są w większości deklaratywne, mniej krytyczne do jednostkowego pokrycia niż logika biznesowa) |

### Kolejność wykonania testów w CI

```
[1] swiftlint                                    — SAST, szybkie
[2] xcodebuild -scheme SwiftGuardData analyze     — statyczna analiza Xcode
[3] xcodebuild test -scheme SwiftGuardDataTests   — XCTest + SwiftCheck (bez UI)
[4] xcodebuild test -scheme SwiftGuardUITests      — XCUITest w Symulatorze (najdłuższy etap)
[5] Manualny/skryptowy przegląd entitlements       — SR-01
[6] xcodebuild archive -exportPath ...              — budowa release, weryfikacja podpisu
[7] Upload do TestFlight                             — dystrybucja beta
```

### Pliki testowe XCUITest (zamiast Playwright)

```
SwiftGuardUITests/
├── US01FrameworksUITests.swift
├── US02ThreatFilterUITests.swift
├── US03ThreatDetailUITests.swift
├── US04CrossReferenceUITests.swift
├── US05FrontendSecurityUITests.swift
├── US06LlmSecurityUITests.swift
├── US07AgenticAiUITests.swift
├── US08StrideUITests.swift
├── US09MlSecurityUITests.swift
├── US10MobileSecurityUITests.swift
├── US11DevOpsSecurityUITests.swift
├── US12WebsiteAppUITests.swift
├── US13PythonCodeUITests.swift
├── US14JavaCodeUITests.swift
├── US15ScalaCodeUITests.swift
├── US16LuaCodeUITests.swift
├── US17SearchUITests.swift
├── US18ExportUITests.swift
└── US19DigitalHarmsUITests.swift
```

### Kluczowe scenariusze abuse case (powiązane testy)

| Abuse Case | Test | Faza |
|---|---|---|
| AC-01: Injection strukturalnie nieobecny | Brak testu negatywnego — udokumentowane w SR-04 jako nieaplikowalne | Sprint 3–4 (weryfikacja przez code review) |
| AC-05: Manipulacja zasobami YAML/JSON w PR | `IntegrityService.verify()` — abort na hash mismatch | Sprint 5–7 |
| AC-06: Osłabienie dekodera `CardFile` | `SwiftCheck` — właściwość odrzucania nieznanych pól | Sprint 5–7 |
| AC-08: Talia harms odczytana jako CVE severity | Test na poziomie typu — `CardKind.designHarm` strukturalnie nie może nieść severity | Sprint 5–7 |
| AC-09: Nadmiarowe entitlements w przyszłym wydaniu | Manualny przegląd pliku entitlements, blokujący release | Sprint 12–14 (i każde wydanie) |
| AC-11: `IntegrityService` wywołany z `SwiftGuardUI` | Reguła `SwiftLint` + code review | Sprint 1–2 |
