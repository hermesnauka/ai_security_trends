# KotlinGuard 2026 — User Stories & TDD Test Plan

**Version:** 1.0
**Date:** 2026-07-07
**Approach:** Test-Driven Development — RED (failing test first) → GREEN (minimal implementation) → REFACTOR
**Test stack:** JUnit 5 (unit) · Kotest (property-based testing) · Jetpack Compose UI Testing (`createAndroidComposeRule`, instrumented)

---

## 0. Test Conventions

- **Unit tests** (`:data/src/test/kotlin`) — JUnit 5, run on the local JVM, no Android device/emulator required. Cover repositories, decoders, `IntegrityChecker`, `CardKind` handling.
- **Property tests** (`:data/src/test/kotlin`, using **Kotest**'s property-testing module) — generate random inputs (e.g., arbitrary extra YAML keys, random `CardKind` values, random filter combinations) to catch classes of bugs a fixed example can miss. Kotest here plays the same role `SwiftCheck`/`eris`/`QuickCheck`/`proptest` play in the Swift/Haskell/Scala/Rust siblings.
- **Instrumented UI tests** (`:app/src/androidTest/kotlin`) — Jetpack Compose UI Testing, run on an emulator or physical device via `createAndroidComposeRule<MainActivity>()`. One test file per user story (`Us01FrameworkListTest.kt` … `Us19DigitalHarmsTest.kt`).
- **RED/GREEN/REFACTOR discipline:** every acceptance criterion below is written as a test **before** the corresponding production code exists. A PR introducing a new Composable/repository method without an accompanying failing-then-passing test is rejected in review.
- **Coverage target:** ≥ 90% of listed test cases passing in CI before a milestone (per `PLAN.md` §16) is marked done; ≥ 85% statement coverage on `:data` (NFR-07).

---

## US-01 — Browse the Security Framework Catalogue

**As a** security engineer, **I want** a single home screen listing every security framework in scope, **so that** I have one access point to all standards.

**Acceptance criteria:**
1. Home screen displays a tile for each of: OWASP Web Top 10, OWASP LLM Top 10, OWASP Agentic AI Top 10, OWASP API Security Top 10, OWASP Client-Side Top 10, OWASP CI/CD Security Top 10, OWASP Automated Threats (OAT), MITRE ATLAS, CompTIA Security+/SecAI+.
2. Tapping a tile navigates to that framework's detail/threat-list screen.
3. Screen renders correctly in both Polish and English (FR-18).

```kotlin
// data/src/test/kotlin/.../FrameworkRepositoryTest.kt
class FrameworkRepositoryTest {
    @Test
    fun `list returns all nine seeded frameworks`() = runTest {
        val repo: FrameworkRepository = FakeFrameworkRepository(seedFrameworks())
        val result = repo.list()
        assertEquals(9, result.size)
        assertTrue(result.any { it.code == "OWASP_LLM" })
        assertTrue(result.any { it.code == "MITRE_ATLAS" })
    }
}

// app/src/androidTest/kotlin/.../Us01FrameworkListTest.kt
class Us01FrameworkListTest {
    @get:Rule val composeRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun homeScreenShowsAllFrameworkTiles() {
        composeRule.onNodeWithText("OWASP LLM Top 10").assertIsDisplayed()
        composeRule.onNodeWithText("MITRE ATLAS").assertIsDisplayed()
        composeRule.onNodeWithText("MITRE ATLAS").performClick()
        composeRule.onNodeWithTag("FrameworkDetailScreen").assertIsDisplayed()
    }
}
```

---

## US-02 — Filter Threats by Framework, Severity, STRIDE, Tag

**Acceptance criteria:**
1. `ThreatRepository.list(filter)` returns only threats matching every non-null filter field.
2. An empty filter returns the full threat list.
3. Filtering by an unknown framework code returns an empty list, not an error.

```kotlin
class ThreatRepositoryFilterTest {
    @Test
    fun `filter by severity CRITICAL returns only critical threats`() = runTest {
        val repo = realRepository(seedThreats())
        val result = repo.list(ThreatFilter(severity = Severity.CRITICAL))
        assertTrue(result.all { it.severity == Severity.CRITICAL })
    }

    @Test
    fun `filter by unknown framework code returns empty list`() = runTest {
        val repo = realRepository(seedThreats())
        assertTrue(repo.list(ThreatFilter(frameworkCode = "DOES_NOT_EXIST")).isEmpty())
    }
}

// Kotest property test — the Room @Query is verified at compile time (D-04);
// this property spot-checks the RUNTIME filtering logic against random combinations.
class ThreatFilterPropertyTest : StringSpec({
    "combining severity and framework filters never returns a threat matching neither" {
        checkAll(Arb.enum<Severity>(), Arb.string(3..10)) { severity, frameworkCode ->
            val result = realRepository(seedThreats()).list(ThreatFilter(severity, frameworkCode))
            result.all { it.severity == severity && it.frameworkCode == frameworkCode }
        }
    }
})
```

---

## US-03 — Threat Detail with Mitigations and Code

**Acceptance criteria:** detail screen shows Overview/Attack Vectors/Mitigations/Code/Cross-References sections; every mitigation lists ≥ 5 code samples (DR-03).

```kotlin
class MitigationCompletenessPropertyTest : StringSpec({
    "every seeded mitigation has exactly 5 code samples, one per required language" {
        val required = setOf(CodeLanguage.PYTHON, CodeLanguage.JAVA, CodeLanguage.GO, CodeLanguage.SCALA, CodeLanguage.LUA)
        seedMitigations().forAll { mitigation ->
            val langs = seedCodeSamples().filter { it.mitigationId == mitigation.id }.map { it.language }.toSet()
            langs == required
        }
    }
})
```

---

## US-04 — Cross-Framework Matrix (LLM01 ↔ MITRE ATLAS)

```kotlin
class MatrixRepositoryTest {
    @Test
    fun `llmMatrix maps LLM01 2025 to AML T0051`() = runTest {
        val matrix = realMatrixRepository().llmMatrix()
        assertTrue(matrix.rows.any { it.owaspCode == "LLM01:2025" && it.atlasCodes.contains("AML.T0051") })
    }
}
```

---

## US-05 — Website App Cornucopia FRE Suit (Client-Side Threats)

**Real card content, translated to Polish, from `__LLM_AI___companion-cards-1.0-en.yaml` — FRE suit:**

| Card | English | Polish | OWASP mapping |
|---|---|---|---|
| FRE2 | *As a Fraudster, I can create synthetic identities using AI-generated profile photos and fabricated personal data, so that I can pass identity verification checks and open fraudulent accounts.* | *Jako oszust, mogę tworzyć syntetyczne tożsamości przy użyciu wygenerowanych przez AI zdjęć profilowych i sfabrykowanych danych osobowych, aby przejść weryfikację tożsamości i otworzyć fałszywe konta.* | OWASP Client-Side Top 10 (C01), OAT-019 (Account Creation) |
| FRE3 | *As a Fraudster, I can use AI voice cloning from short audio samples to bypass voice biometric authentication, so that I can impersonate a legitimate account holder.* | *Jako oszust, mogę użyć klonowania głosu AI z krótkich próbek audio, aby obejść uwierzytelnianie biometryczne głosem, i podszyć się pod prawowitego posiadacza konta.* | CompTIA Security+ (biometric spoofing), MITRE ATLAS AML.T0043 |
| FRE4 | *As a Fraudster, I can automate the generation of thousands of realistic-looking phishing pages using AI, so that I can scale credential-harvesting campaigns beyond manual capacity.* | *Jako oszust, mogę zautomatyzować generowanie tysięcy realistycznie wyglądających stron phishingowych za pomocą AI, aby skalować kampanie wyłudzania poświadczeń poza ręczne możliwości.* | OWASP Client-Side Top 10, OAT-006 (Expediting) |
| FRE5 | *As a Fraudster, I can use an LLM to generate convincing, personalized social-engineering scripts at scale, so that I can increase the success rate of vishing/smishing campaigns.* | *Jako oszust, mogę użyć LLM do generowania przekonujących, spersonalizowanych skryptów socjotechnicznych na skalę, aby zwiększyć skuteczność kampanii vishing/smishing.* | OWASP LLM Top 10 (LLM09 Misinformation, misuse), CompTIA SecAI+ |

**Acceptance criteria:** all 4 FRE cards render with both languages; each cross-references at least one OWASP/MITRE code.

```kotlin
class FreCardDecoderTest {
    @Test
    fun `FRE suit decodes with Polish and English descriptions and non-empty OWASP refs`() {
        val cards = CardFileDecoders.decodeCompanion(loadAsset("cornucopia/companion-llm-cards-1.0-en.yaml"))
            .filter { it.suitCode == "FRE" }
        assertEquals(4, cards.size) // FRE2..FRE5 in scope
        cards.forEach {
            assertTrue(it.descriptionPl.isNotBlank())
            assertTrue(it.owaspRefs.isNotEmpty())
        }
    }
}
```

---

## US-06 — LLM Cornucopia Suit + Interactive Matrix

| Card | English | Polish | OWASP mapping |
|---|---|---|---|
| LLM2 | *As an Attacker, I can inject malicious instructions hidden in retrieved documents (indirect prompt injection), so that I can hijack the LLM's behavior without directly interacting with the prompt.* | *Jako atakujący, mogę wstrzyknąć złośliwe instrukcje ukryte w pobranych dokumentach (pośrednia iniekcja promptu), aby przejąć kontrolę nad zachowaniem LLM bez bezpośredniej interakcji z promptem.* | LLM01:2025 Prompt Injection |
| LLM3 | *As an Attacker, I can poison the training or fine-tuning dataset with subtly biased or malicious examples, so that the model learns harmful behavior that activates only under specific trigger conditions.* | *Jako atakujący, mogę zatruć zbiór danych treningowych lub fine-tuningowych subtelnie stronniczymi lub złośliwymi przykładami, aby model nauczył się szkodliwego zachowania aktywowanego tylko w określonych warunkach.* | LLM04:2025 Data and Model Poisoning |
| LLM4 | *As an Attacker, I can exploit an LLM agent's excessive autonomy to invoke tools/APIs beyond its intended scope, so that I can exfiltrate data or perform unauthorized actions.* | *Jako atakujący, mogę wykorzystać nadmierną autonomię agenta LLM do wywoływania narzędzi/API poza jego zamierzonym zakresem, aby wyeksfiltrować dane lub wykonać nieautoryzowane działania.* | LLM06:2025 Excessive Agency |

**Acceptance criteria:** LLM suit screen includes an interactive matrix cross-referencing each card to its OWASP LLM Top 10 entry.

```kotlin
@Test
fun `llm suit cards map onto distinct OWASP LLM Top 10 entries`() = runTest {
    val cards = cardRepository.bySuit("LLM")
    val mapped = cards.flatMap { it.owaspRefs }.filter { it.startsWith("LLM0") }
    assertTrue(mapped.toSet().size >= 3)
}
```

---

## US-07 — AAI (Agentic AI) + CLD (Cloud) Suits

| Card | English | Polish | OWASP/other mapping |
|---|---|---|---|
| AAI2 | *As an Attacker, I can manipulate an autonomous agent's planning loop to skip a required human-approval checkpoint, so that I can execute a high-impact action without oversight.* | *Jako atakujący, mogę manipulować pętlą planowania autonomicznego agenta, aby pominąć wymagany punkt zatwierdzenia przez człowieka, i wykonać działanie o wysokim wpływie bez nadzoru.* | OWASP Agentic AI Top 10 (Human-in-the-Loop bypass) |
| AAI4 | *As an Attacker, I can chain multiple agent tool calls to escalate privileges beyond any single tool's individual permission scope, so that I gain access no single authorized call would grant.* | *Jako atakujący, mogę łączyć wiele wywołań narzędzi agenta, aby eskalować uprawnienia poza zakres pojedynczego narzędzia, i uzyskać dostęp, którego żadne pojedyncze autoryzowane wywołanie by nie przyznało.* | OWASP Agentic AI Top 10, MITRE ATLAS AML.T0053 |
| AAI5 | *As an Attacker, I can poison an agent's long-term memory store with false facts, so that future planning decisions are made on corrupted context.* | *Jako atakujący, mogę zatruć długoterminową pamięć agenta fałszywymi faktami, aby przyszłe decyzje planistyczne opierały się na skorumpowanym kontekście.* | OWASP Agentic AI Top 10, LLM04:2025 |
| CLD2 | *As an Attacker, I can exploit an overly permissive IAM role attached to a serverless function, so that I can pivot from the function's limited scope into broader cloud account access.* | *Jako atakujący, mogę wykorzystać zbyt permisywną rolę IAM przypisaną do funkcji bezserwerowej, aby przejść z ograniczonego zakresu funkcji do szerszego dostępu do konta chmurowego.* | OWASP Cloud-Native Top 10, CompTIA Security+ (IAM) |
| CLD3 | *As an Attacker, I can discover a publicly exposed object-storage bucket with default permissions, so that I can read or modify sensitive data without authentication.* | *Jako atakujący, mogę odkryć publicznie dostępny zasobnik obiektowy z domyślnymi uprawnieniami, aby odczytać lub zmodyfikować wrażliwe dane bez uwierzytelnienia.* | OWASP A05:2021 Security Misconfiguration |
| CLD4 | *As an Attacker, I can abuse a misconfigured CI/CD pipeline's cloud credentials cached in a build log, so that I can obtain persistent access to production infrastructure.* | *Jako atakujący, mogę wykorzystać dane uwierzytelniające chmury z niewłaściwie skonfigurowanego potoku CI/CD, zapisane w logu builda, aby uzyskać trwały dostęp do infrastruktury produkcyjnej.* | OWASP CI/CD Security Top 10 (CICD-SEC-6) |

```kotlin
@Test
fun `AAI and CLD suits both present with non-empty translated descriptions`() = runTest {
    listOf("AAI", "CLD").forEach { suit ->
        val cards = cardRepository.bySuit(suit)
        assertTrue(cards.isNotEmpty())
        cards.forEach { assertTrue(it.descriptionPl.isNotBlank()) }
    }
}
```

---

## US-08 — STRIDE/EoP Catalogue + Heatmap

| Card | English | Polish | STRIDE category |
|---|---|---|---|
| SP2 | *As an Attacker, I can spoof a trusted internal service's hostname via DNS cache poisoning, so that clients send requests intended for the real service to my malicious endpoint.* | *Jako atakujący, mogę podszyć się pod nazwę hosta zaufanej usługi wewnętrznej poprzez zatrucie pamięci podręcznej DNS, aby klienci wysyłali żądania przeznaczone dla prawdziwej usługi na mój złośliwy punkt końcowy.* | Spoofing |
| TA2 | *As an Attacker, I can intercept and modify an unsigned firmware update package in transit, so that I can install persistent malicious code on the target device.* | *Jako atakujący, mogę przechwycić i zmodyfikować niepodpisany pakiet aktualizacji oprogramowania układowego podczas przesyłania, aby zainstalować trwały złośliwy kod na urządzeniu docelowym.* | Tampering |
| TA6 | *As an Attacker, I can tamper with a log-forwarding pipeline to alter events before they reach the SIEM, so that my subsequent malicious activity is not recorded for detection.* | *Jako atakujący, mogę manipulować potokiem przesyłania logów, aby zmienić zdarzenia przed dotarciem do SIEM, tak aby moja późniejsza złośliwa aktywność nie została zarejestrowana do wykrycia.* | Tampering |

**Acceptance criteria:** heatmap Composable renders 6 cells (S/T/R/I/D/E) with per-category card counts; tapping a cell filters the card list.

```kotlin
class StrideHeatmapViewModelTest {
    @Test
    fun `heatmap counts sum to total seeded STRIDE cards`() = runTest {
        val vm = StrideHeatmapViewModel(FakeCardRepository(seedStrideCards()))
        val total = vm.state.value.categoryCounts.values.sum()
        assertEquals(seedStrideCards().size, total)
    }
}
```

---

## US-09 — Elevation-of-MLSec Deck

| Card | English | Polish | MITRE ATLAS mapping |
|---|---|---|---|
| EMR2 | *As an Attacker, I can craft adversarial input perturbations invisible to a human reviewer, so that the model misclassifies malicious content as benign.* | *Jako atakujący, mogę spreparować przeciwstawne (adversarial) zaburzenia danych wejściowych, niewidoczne dla ludzkiego recenzenta, aby model błędnie sklasyfikował złośliwą treść jako nieszkodliwą.* | AML.T0043 (Craft Adversarial Data) |
| EMR3 | *As an Attacker, I can repeatedly query a deployed model's API to reconstruct its decision boundary, so that I can steal an approximation of the proprietary model.* | *Jako atakujący, mogę wielokrotnie odpytywać API wdrożonego modelu, aby zrekonstruować jego granicę decyzyjną, i wykraść przybliżenie zastrzeżonego modelu.* | AML.T0024 (Model Extraction) |
| EMR4 | *As an Attacker, I can submit specially crafted queries to a deployed model to infer whether a specific record was part of its training set, so that I violate the privacy of individuals in the training data.* | *Jako atakujący, mogę przesyłać specjalnie spreparowane zapytania do wdrożonego modelu, aby wywnioskować, czy konkretny rekord znajdował się w zbiorze treningowym, i naruszyć prywatność osób w danych treningowych.* | AML.T0024, CompTIA SecAI+ (membership inference) |

```kotlin
@Test
fun `mlsec cards cross-reference at least one MITRE ATLAS technique each`() = runTest {
    cardRepository.bySuit("EMR").forEach { assertTrue(it.mitreRefs.isNotEmpty()) }
}
```

---

## US-10 — Mobile App Cornucopia Deck — This App's OWN Threat Model

| Card | English | Polish | Cross-reference to KotlinGuard's own design |
|---|---|---|---|
| PC2 | *As an Attacker, I can access a mobile app's exported Activity or Service from another app installed on the same device, so that I can trigger privileged functionality without the intended UI-level access controls.* | *Jako atakujący, mogę uzyskać dostęp do eksportowanej Activity lub Service aplikacji mobilnej z innej aplikacji zainstalowanej na tym samym urządzeniu, aby wywołać uprzywilejowaną funkcjonalność z pominięciem zamierzonej kontroli dostępu na poziomie UI.* | Directly mitigated by **D-02**: every KotlinGuard component is `exported="false"` except the launcher `MainActivity` |
| PC3 | *As an Attacker, I can read data written by a mobile app to unencrypted `SharedPreferences` or external storage, so that I can extract sensitive tokens or user data from a rooted or backed-up device.* | *Jako atakujący, mogę odczytać dane zapisane przez aplikację mobilną w niezaszyfrowanych `SharedPreferences` lub pamięci zewnętrznej, aby wydobyć wrażliwe tokeny lub dane użytkownika z zrootowanego lub zapisanego w kopii zapasowej urządzenia.* | Directly mitigated by **D-07/SR-09**: the Firestore sync token uses `EncryptedSharedPreferences` (Keystore-backed) and **SR-15**: `allowBackup="false"` |
| PC4 | *As an Attacker, I can perform a man-in-the-middle attack against a mobile app's network traffic by installing a rogue CA certificate, so that I can intercept and modify data in transit if the app accepts cleartext or improperly validated TLS.* | *Jako atakujący, mogę przeprowadzić atak man-in-the-middle na ruch sieciowy aplikacji mobilnej, instalując fałszywy certyfikat CA, aby przechwycić i zmodyfikować dane w tranzycie, jeśli aplikacja akceptuje niezaszyfrowany ruch lub niepoprawnie zweryfikowany TLS.* | Directly mitigated by **SR-10.1**: `network_security_config.xml` disables cleartext traffic for all destinations |

**Acceptance criteria:** each PC card's detail view includes a visible "How KotlinGuard defends against this" panel linking to the actual design decision.

```kotlin
class Us10MobileThreatModelTest {
    @Test
    fun `PC2 card links to this app's own exported-component design decision`() = runTest {
        val card = cardRepository.byCardId("PC2")
        assertNotNull(card)
        val selfDefense = selfDefenseRepository.forCardId("PC2")
        assertEquals("D-02", selfDefense?.designDecisionId)
    }
}
```

---

## US-11 — DevOps (DVO) + Bots (BOT)

| Card | English | Polish | OWASP mapping |
|---|---|---|---|
| DVOK | *As an Attacker, I can exploit a CI/CD pipeline that runs untrusted pull-request code with access to repository secrets, so that I can exfiltrate deployment credentials.* | *Jako atakujący, mogę wykorzystać potok CI/CD, który uruchamia niezaufany kod z pull requesta mając dostęp do sekretów repozytorium, aby wyeksfiltrować dane uwierzytelniające wdrożenia.* | CICD-SEC-4 (Poisoned Pipeline Execution) |
| DVOQ | *As an Attacker, I can push a malicious dependency update that passes automated checks, so that it is auto-merged and deployed without human review.* | *Jako atakujący, mogę wypchnąć złośliwą aktualizację zależności, która przechodzi automatyczne kontrole, aby została automatycznie scalona i wdrożona bez przeglądu przez człowieka.* | CICD-SEC-3 (Dependency Chain Abuse) |
| BOTK | *As an Attacker, I can deploy a botnet to perform credential stuffing against a login endpoint at high volume, so that I can identify valid account credentials from a leaked password list.* | *Jako atakujący, mogę wdrożyć botnet do przeprowadzenia credential stuffing na punkcie logowania z dużą częstotliwością, aby zidentyfikować prawidłowe dane logowania z wyciekłej listy haseł.* | OAT-008 Credential Stuffing |
| BOTX | *As an Attacker, I can use automated scraping bots to harvest an app's entire content catalogue, so that I can republish or resell scraped data without authorization.* | *Jako atakujący, mogę użyć zautomatyzowanych botów skrobiących do zebrania całego katalogu treści aplikacji, aby ponownie opublikować lub odsprzedać zeskrobane dane bez autoryzacji.* | OAT-011 Scraping |

```kotlin
@Test
fun `DVO and BOT suits render with OWASP cross-references`() = runTest {
    listOf("DVO", "BOT").forEach { suit ->
        cardRepository.bySuit(suit).forEach { assertTrue(it.owaspRefs.isNotEmpty()) }
    }
}
```

---

## US-12 — Website App Cornucopia (VE/AT/SM/AZ/CR/C)

| Card | English | Polish | OWASP mapping |
|---|---|---|---|
| VE2 | *As an Attacker, I can submit unvalidated input containing SQL metacharacters through a web form, so that I can extract or modify data directly from the backing database.* | *Jako atakujący, mogę przesłać niezwalidowane dane wejściowe zawierające metaznaki SQL przez formularz internetowy, aby wydobyć lub zmodyfikować dane bezpośrednio z bazy danych.* | A03:2021 Injection |
| VE3 | *As an Attacker, I can inject a crafted script into a comment field that is rendered unescaped to other users, so that I can execute arbitrary JavaScript in their browser session.* | *Jako atakujący, mogę wstrzyknąć spreparowany skrypt w pole komentarza, które jest renderowane bez escapowania innym użytkownikom, aby wykonać dowolny JavaScript w ich sesji przeglądarki.* | A03:2021 Injection (XSS) |
| VE4 | *As an Attacker, I can submit an oversized or malformed file upload that the server fails to validate, so that I can trigger a denial-of-service condition or execute uploaded code.* | *Jako atakujący, mogę przesłać zbyt duży lub zniekształcony plik, którego serwer nie waliduje, aby wywołać odmowę usługi lub wykonać przesłany kod.* | A04:2021 Insecure Design |

```kotlin
@Test
fun `website app suit VE cards map to OWASP A03 or A04`() = runTest {
    val cards = cardRepository.bySuit("VE")
    assertTrue(cards.all { it.owaspRefs.any { ref -> ref.startsWith("A03") || ref.startsWith("A04") } })
}
```

---

## US-13 to US-16 — Code Samples in 5 Languages

**Acceptance criteria:** for a representative threat (SQL Injection, A03:2021), the Code Samples panel shows one attack-demo/defense pair per language.

```kotlin
class Us13To16CodeSamplePanelTest {
    @get:Rule val composeRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun `code sample panel shows tabs for all five languages`() {
        navigateToThreat(composeRule, "A03:2021")
        listOf("Python", "Java", "Go", "Scala", "Lua").forEach { lang ->
            composeRule.onNodeWithText(lang).assertIsDisplayed()
        }
    }

    @Test
    fun `attack demo sample requires acknowledgement dialog before code is shown`() {
        navigateToThreat(composeRule, "A03:2021")
        composeRule.onNodeWithText("Python").performClick()
        composeRule.onNodeWithText("Attack Demo").performClick()
        composeRule.onNodeWithTag("AttackDemoWarningDialog").assertIsDisplayed()
        composeRule.onNodeWithText("I Understand").performClick()
        composeRule.onNodeWithTag("CodeBlock").assertIsDisplayed()
    }
}
```

---

## US-17 — Search

```kotlin
class SearchRepositoryTest {
    @Test
    fun `searching prompt injection in Polish returns LLM01 threat`() = runTest {
        val results = searchRepository.query("wstrzykiwanie promptu", AppLocale.PL)
        assertTrue(results.any { it.code == "LLM01:2025" })
    }
}
```

---

## US-18 — Export via Native Share Sheet

```kotlin
class ExportServiceTest {
    @Test
    fun `exportCsv produces a content uri shareable via FileProvider`() = runTest {
        val uri = exportService.exportCsv(ThreatFilter(severity = Severity.CRITICAL))
        assertEquals("content", uri.scheme)
        assertTrue(contentResolver.openInputStream(uri)!!.readBytes().isNotEmpty())
    }
}
```

---

## US-19 — Digital-by-Default Harms Deck (`dbd-cards-1.0-en.yaml`)

**Real card content, translated to Polish:**

| Card | English | Polish | OWASP mapping |
|---|---|---|---|
| SCO2 | *As a Public Service Designer, I can mandate an online-only application channel without a supported offline alternative, so that citizens without reliable internet access or digital literacy are structurally excluded from the service.* | *Jako projektant usługi publicznej, mogę narzucić kanał składania wniosków wyłącznie online, bez wspieranej alternatywy offline, przez co obywatele bez niezawodnego dostępu do internetu lub umiejętności cyfrowych są strukturalnie wykluczeni z usługi.* | A04:2021 Insecure Design |
| SCO3 | *As a Public Service Designer, I can require a smartphone-only authentication app for benefit access with no alternative verification path, so that elderly or low-income users without a compatible device cannot access their entitlements.* | *Jako projektant usługi publicznej, mogę wymagać aplikacji uwierzytelniającej działającej wyłącznie na smartfonie, bez alternatywnej ścieżki weryfikacji, przez co starsi lub ubożsi użytkownicy bez odpowiedniego urządzenia nie mogą uzyskać dostępu do swoich świadczeń.* | A04:2021 Insecure Design |
| SCO4 | *As a Public Service Designer, I can set a form timeout too short for a user relying on assistive technology to complete, so that users with disabilities are systematically unable to finish their application.* | *Jako projektant usługi publicznej, mogę ustawić czas wypełniania formularza zbyt krótki dla użytkownika korzystającego z technologii wspomagających, przez co osoby z niepełnosprawnościami systematycznie nie są w stanie ukończyć wniosku.* | A04:2021 Insecure Design |
| ARC2 | *As a System Architect, I can design an eligibility-determination algorithm with no human review step, so that an incorrect automated denial cannot be caught or appealed before harm occurs.* | *Jako architekt systemu, mogę zaprojektować algorytm ustalania uprawnień bez etapu przeglądu przez człowieka, przez co błędna automatyczna odmowa nie może zostać wychwycona ani zaskarżona przed wystąpieniem szkody.* | A04:2021 Insecure Design |
| ARC3 | *As a System Architect, I can integrate a third-party risk-scoring model into a benefits system without documenting its decision logic, so that affected citizens cannot understand or challenge decisions made about them.* | *Jako architekt systemu, mogę zintegrować model oceny ryzyka firmy trzeciej z systemem świadczeń bez dokumentowania jego logiki decyzyjnej, przez co dotknięci obywatele nie mogą zrozumieć ani zakwestionować podjętych wobec nich decyzji.* | A04:2021 Insecure Design |

**Why these are structurally distinct from every other deck in this app:** these cards describe **design and policy harms**, not exploitable technical vulnerabilities — there is no "patch" for SCO2 in the way there is a patch for a SQL injection flaw. This is precisely what `CardKind.DesignHarm` (D-03) encodes: these cards **cannot** carry a `Severity`, because "severity" implies a technical risk-scoring frame that does not fit an exclusion-by-design harm.

**Acceptance criteria:**
1. The Digital-by-Default Harms screen is visually and structurally separate from every technical-vulnerability screen (distinct color treatment, a `DesignHarmBadge`, no "Severity" field displayed anywhere on the card).
2. Every card in this deck decodes to `CardKind.DesignHarm`.
3. Attempting to read a `Severity` from a `DesignHarm` card is a **compile error** at every call site (D-03) — enforced by the Kotlin compiler, not a runtime check.
4. Each card cross-references OWASP A04:2021.

```kotlin
// data/src/test/kotlin/.../DigitalHarmsDecoderTest.kt
class DigitalHarmsDecoderTest {
    @Test
    fun `dbd deck decodes all cards as CardKind DesignHarm with no severity`() {
        val cards = CardFileDecoders.decodeDbd(loadAsset("cornucopia/dbd-cards-1.0-en.yaml"))
        assertTrue(cards.isNotEmpty())
        cards.forEach { card ->
            assertEquals(CardKind.DesignHarm, card.kind)
            assertTrue(card.owaspRefs.contains("A04:2021"))
        }
    }
}

// Kotest property test — the KEY guarantee for this user story
class CardKindExhaustivenessPropertyTest : StringSpec({
    "severityOf is total: every CardKind value produces a defined result, DesignHarm always null" {
        checkAll(Arb.severityEnum(), Arb.boolean()) { severity, isDesignHarm ->
            val kind: CardKind = if (isDesignHarm) CardKind.DesignHarm else CardKind.TechnicalThreat(severity)
            val result = severityOf(kind) // the `when` expression from PLAN.md D-03
            if (isDesignHarm) result == null else result == severity
        }
    }
})

// app/src/androidTest/kotlin/.../Us19DigitalHarmsTest.kt
class Us19DigitalHarmsTest {
    @get:Rule val composeRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun `digital harms screen shows design-harm badge and no severity chip`() {
        composeRule.onNodeWithText("Digital-by-Default Harms").performClick()
        composeRule.onNodeWithTag("DesignHarmBadge").assertIsDisplayed()
        composeRule.onAllNodesWithTag("SeverityChip").assertCountEquals(0)
    }

    @Test
    fun `SCO2 card cross-references A04 2021`() {
        composeRule.onNodeWithText("Digital-by-Default Harms").performClick()
        composeRule.onNodeWithText("SCO2").performClick()
        composeRule.onNodeWithText("A04:2021", substring = true).assertIsDisplayed()
    }
}
```

**A compile-time note worth stating explicitly for the course:** unlike a unit test, which can only prove the tested cases behave correctly, `CardKindExhaustivenessPropertyTest` above is almost redundant with the compiler's own guarantee — if `severityOf` ever failed to handle a `CardKind` variant, the project would not compile at all, since `when` is used as an expression with no `else`. The property test is retained anyway (a) as living documentation of the contract, and (b) to catch a regression if a future refactor changes `severityOf` to a `when` **statement** or reintroduces an `else` branch — the one way this guarantee can be silently defeated (see `PLAN.md` D-03 caveat and Risk Register §13).

---

## Podsumowanie planu testów (Test Plan Summary)

| Kategoria | Liczba testów (przybliżona) |
|---|---|
| Testy jednostkowe (JUnit 5, `:data`) | ~95 |
| Testy właściwości (Kotest property) | ~20 |
| Testy UI (Compose UI Testing, `:app/androidTest`) | ~55 (jeden zestaw na każdą z 19 historyjek użytkownika, plus warianty PL/EN) |
| **Razem** | **~170** |

**Cel pokrycia:** ≥ 85% pokrycia instrukcji w module `:data` (NFR-07); ≥ 90% z powyższej listy przechodzące w CI przed oznaczeniem kamienia milowego jako ukończonego (`PLAN.md` §16).

**Kolejność wykonania w CI:**
1. `./gradlew :data:testDebugUnitTest` (JUnit 5 + Kotest, szybkie, brak emulatora)
2. `./gradlew detekt lintDebug` (SAST)
3. `./gradlew dependencyCheckAnalyze` (SCA)
4. `./gradlew :app:connectedDebugAndroidTest` (Compose UI Testing na emulatorze/urządzeniu w CI)
5. Build release + weryfikacja R8

**Pliki testów E2E (Compose UI Testing), po jednym na historyjkę:**
`Us01FrameworkListTest.kt` … `Us19DigitalHarmsTest.kt` (19 plików), plus `LocaleToggleE2ETest.kt` weryfikujący przełącznik PL/EN na reprezentatywnym podzbiorze ekranów.

**Tabela przypadków nadużyć (Abuse Cases) zweryfikowanych testami:**

| AC ID | Pokryty przez |
|---|---|
| AC-01 | Manualny przegląd `AndroidManifest.xml` + Android Lint `ExportedContentQuery` (SR-01) |
| AC-02 | `detekt` custom rule + `Us19`/deck decoder tests asserting `ignoreUnknownKeys == false` |
| AC-03 | `CardKindExhaustivenessPropertyTest` + kompilator Kotlina (D-03) |
| AC-04 | Manualna weryfikacja `allowBackup=false` w konfiguracji release |
| AC-05 | `detekt` custom rule zakazująca `rawQuery` poza udokumentowanym wyjątkiem |
| AC-06 | `Us13To16CodeSamplePanelTest` (dialog potwierdzenia) |
| AC-07 | `dependencyCheckAnalyze` w CI |
| AC-08 | CODEOWNERS + `IntegrityChecker` hash-mismatch test |
