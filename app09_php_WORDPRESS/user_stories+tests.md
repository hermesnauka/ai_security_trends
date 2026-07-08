# SecurePress 2026 — User Stories & TDD Test Plan

**Version:** 1.0
**Date:** 2026-07-07
**Stack:** WordPress 6.8+ / PHP 8.3 (backend) · vanilla JavaScript (frontend enhancement) · MySQL 8
**Test frameworks:** PHPUnit + `WP_UnitTestCase` + `eris` (property-based) + `wp-browser`/Codeception · Playwright

---

## Konwencje testowe

### Backend (PHP — PHPUnit + `WP_UnitTestCase`)
```php
class ThreatServiceTest extends WP_UnitTestCase {
    public function test_filters_by_severity(): void {
        $service = new Threat_Service( new Threat_Repository( $GLOBALS['wpdb'] ) );
        $result  = $service->list( new Threat_Filter( severity: 'critical' ) );
        foreach ( $result as $threat ) {
            $this->assertSame( 'critical', $threat->severity );
        }
    }
}
```

### Backend properties (`eris`)
```php
use Eris\Generator;
use Eris\TestTrait;

class CardLoaderTest extends WP_UnitTestCase {
    use TestTrait;

    public function test_rejects_unknown_top_level_fields(): void {
        $this->forAll( Generator\string() )
            ->then( function ( string $extraKey ) {
                if ( strlen( $extraKey ) < 3 ) { return; }
                $yaml = "meta:\n  edition: webapp\n{$extraKey}: evil\nsuits: []\n";
                $this->expectException( Card_Decode_Exception::class );
                Card_Loader::decode( $yaml );
            } );
    }
}
```

### Backend REST integration (`WP_UnitTestCase` + `WP_REST_Request`)
```php
class ThreatControllerTest extends WP_UnitTestCase {
    public function test_list_returns_200_for_valid_framework(): void {
        $request = new WP_REST_Request( 'GET', '/securepress/v1/threats' );
        $request->set_param( 'framework', 'OWASP_LLM' );
        $response = rest_get_server()->dispatch( $request );
        $this->assertSame( 200, $response->get_status() );
    }
}
```

### Acceptance (`wp-browser`/Codeception)
```php
class ThreatBrowserCest {
    public function filters_update_results_without_full_reload( AcceptanceTester $I ) {
        $I->amOnPage( '/threats/' );
        $I->fillField( '#threat-search', 'prompt injection' );
        $I->waitForElement( '[data-testid="threat-result"]' );
        $I->see( 'LLM01' );
    }
}
```

### E2E (Playwright, against the PHP-rendered pages)
```typescript
test('opis testu', async ({ page }) => {
  await page.goto('/route')
  await expect(page.getByTestId('...')).toBeVisible()
})
```

---

## Zasada TDD stosowana w tym projekcie

```
RED       — napisz test (PHPUnit, właściwość eris, lub scenariusz wp-browser) opisujący
             oczekiwane zachowanie PRZED napisaniem kodu produkcyjnego
GREEN     — napisz minimalny kod, który sprawia, że test przechodzi
REFACTOR  — poprawiaj kod bez łamania testów; PHPCS/WPCS pilnuje jakości i bezpieczeństwa w tle
```

W przeciwieństwie do `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react`, gdzie kompilator wychwytuje część błędów przed uruchomieniem jakiegokolwiek testu, w PHP **nie ma kompilatora sprawdzającego typy czy kształt zapytań SQL** — każdy test w tym planie jest jedynym zabezpieczeniem, jakie istnieje dla danego zachowania. To właśnie uzasadnia szerokie użycie `eris` (property-based testing) dla funkcji parsujących niezaufane dane — więcej przypadków testowych częściowo kompensuje brak gwarancji na poziomie języka.

---

## US-01 — Katalog frameworków bezpieczeństwa

**Rola:** security engineer
**Potrzeba:** przeglądać katalog wszystkich frameworków bezpieczeństwa
**Cel:** mieć jeden punkt dostępu do wszystkich standardów

### Kryteria akceptacji
- `GET /wp-json/securepress/v1/frameworks` zwraca wszystkie frameworki z liczbą zagrożeń
- Szablon `home.php` wyświetla kafelek per framework, renderowany po stronie serwera
- Kliknięcie kafelka nawiguje do archiwum danego frameworku (działa bez JavaScript)

### Plan testów TDD

**Backend:**
```php
class FrameworkServiceTest extends WP_UnitTestCase {
    public function test_list_returns_at_least_ten_seeded_frameworks(): void {
        $frameworks = ( new Framework_Service() )->list();
        $this->assertGreaterThanOrEqual( 10, count( $frameworks ) );
    }
}

class FrameworkControllerTest extends WP_UnitTestCase {
    public function test_detail_404s_for_unknown_code(): void {
        $request  = new WP_REST_Request( 'GET', '/securepress/v1/frameworks/NOT_REAL' );
        $response = rest_get_server()->dispatch( $request );
        $this->assertSame( 404, $response->get_status() );
    }
}
```

**E2E:** `us01-frameworks.spec.ts`.

---

## US-02 — Przeglądarka zagrożeń z filtrami

**Rola:** security engineer
**Potrzeba:** filtrować zagrożenia po frameworku, severity, STRIDE, tagu, `q`
**Cel:** szybko znaleźć zagrożenia istotne dla mojego projektu

### Plan testów TDD

**Backend:**
```php
class ThreatServiceTest extends WP_UnitTestCase {
    public function test_combines_framework_and_severity_filters(): void {
        $result = ( new Threat_Service() )->list( new Threat_Filter(
            framework_code: 'OWASP_LLM',
            severity: 'critical'
        ) );
        foreach ( $result as $threat ) {
            $this->assertSame( 'OWASP_LLM', $threat->framework_code );
            $this->assertSame( 'critical', $threat->severity );
        }
    }
}

class ThreatControllerTest extends WP_UnitTestCase {
    public function test_rejects_query_longer_than_200_chars(): void {
        $request = new WP_REST_Request( 'GET', '/securepress/v1/threats' );
        $request->set_param( 'q', str_repeat( 'a', 201 ) );
        $response = rest_get_server()->dispatch( $request );
        $this->assertSame( 422, $response->get_status() );
    }
}
```

**Acceptance (progressive enhancement, unique to this app):**
```php
class NoJsFilteringCest {
    public function filters_work_via_query_string_without_javascript( AcceptanceTester $I ) {
        $I->amOnPage( '/threats/?framework=OWASP_LLM&severity=critical' );
        $I->see( 'LLM01' );
        $I->dontSee( 'LLM09' ); // assuming LLM09 is not CRITICAL in seed data
    }
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
```php
class MitigationTest extends WP_UnitTestCase {
    use Eris\TestTrait;

    public function test_every_seeded_mitigation_has_all_five_languages(): void {
        $this->forAll( Generator\elements( ...seeded_mitigation_ids() ) )
            ->then( function ( int $mitigationId ) {
                $samples = ( new Code_Sample_Repository() )->by_mitigation_id( $mitigationId );
                $languages = array_unique( array_map( fn( $s ) => $s->language, $samples ) );
                sort( $languages );
                $this->assertSame( array( 'go', 'java', 'lua', 'python', 'scala' ), $languages );
            } );
    }
}
```

**Acceptance:**
```php
class AttackDemoConfirmationCest {
    public function does_not_show_attack_demo_code_before_confirmation( AcceptanceTester $I ) {
        $I->amOnPage( '/threats/llm01/' );
        $I->click( 'Kod' );
        $I->dontSeeElement( '[data-testid="attack-demo-code-body"]' );
        $I->click( 'Rozumiem' );
        $I->seeElement( '[data-testid="attack-demo-code-body"]' );
    }
}
```

**E2E:** `us03-threat-detail.spec.ts`.

---

## US-04 — Mapowanie cross-framework (LLM01 → MITRE ATLAS)

**Rola:** CompTIA SecAI+ student
**Potrzeba:** zobaczyć jak LLM01 Prompt Injection mapuje do MITRE ATLAS AML.T0051
**Cel:** zrozumieć zależności między frameworkami

### Plan testów TDD

**Backend:**
```php
class CrossReferenceServiceTest extends WP_UnitTestCase {
    public function test_llm01_maps_to_aml_t0051(): void {
        $refs = ( new Cross_Reference_Service() )->by_source_code( 'LLM01' );
        $codes = array_map( fn( $r ) => $r->target_code, $refs );
        $this->assertContains( 'AML.T0051', $codes );
    }
}
```

**E2E:** `us04-cross-reference.spec.ts`.

---

## US-05 — Bezpieczeństwo frontend/client-side (karty FRE)

**Rola:** WordPress/PHP developer
**Potrzeba:** przeglądać karty Cornucopia FRE (Companion Edition v1.0) z polskimi opisami
**Cel:** mapować scenariusze ataków po stronie klienta na mitigacje

### Polskie tłumaczenia kart FRE (z `__LLM_AI___companion-cards-1.0-en.yaml`)

| Karta | Angielski oryginał | Polskie tłumaczenie | Mapowanie OWASP |
|---|---|---|---|
| FRE2 | "Marcus bypasses client-side validation and sends malformed or malicious input directly to backend APIs, triggering logic flaws, human errors, and usability issues" | *"Marcus omija walidację po stronie klienta i wysyła zniekształcone lub złośliwe dane bezpośrednio do API backendu, wywołując błędy logiki, błędy ludzkie i problemy użytkowe"* | **A03:2021 Injection / A04:2021 Insecure Design** |
| FRE3 | "Lena can access sensitive or confidential information because it's not removed after logout or when the client session ends" | *"Lena może uzyskać dostęp do danych wrażliwych, ponieważ nie są one usuwane po wylogowaniu lub zakończeniu sesji klienta"* | **A01:2021 Broken Access Control** |
| FRE4 | "James injects JavaScript through user-controlled data that is written into the DOM, executing arbitrary code in the victim's browser" | *"James wstrzykuje JavaScript poprzez dane kontrolowane przez użytkownika, które są zapisywane do DOM, wykonując dowolny kod w przeglądarce ofiary"* | **A03:2021 Injection (DOM XSS)** |
| FRE5 | "Victor compromises or replaces a third-party script loaded from a CDN and runs malicious code in every user's browser" | *"Victor kompromituje lub zamienia skrypt zewnętrzny wczytywany z CDN i wykonuje złośliwy kod w przeglądarce każdego użytkownika"* | **A06:2021 Vulnerable and Outdated Components** |

**Uwaga specyficzna dla WordPress:** karta FRE5 (skompromitowany skrypt z CDN) jest bezpośrednio pokrewna wymaganiu C-03/NFR-05.3 tego projektu — SecurePress 2026 nie wczytuje ŻADNEGO skryptu z zewnętrznego CDN (Prism.js jest self-hosted przez `wp_enqueue_script()`), co samo w sobie jest żywym przykładem mitigacji dla FRE5.

### Plan testów TDD

**Backend:**
```php
class CardServiceTest extends WP_UnitTestCase {
    public function test_fre_cards_each_carry_at_least_one_owasp_ref(): void {
        $cards = ( new Card_Service() )->by_suit( 'fre' );
        foreach ( $cards as $card ) {
            $this->assertNotEmpty( $card->owasp_refs );
        }
    }

    public function test_fre4_polish_translation_is_reviewed_not_identical_to_english(): void {
        $card = ( new Card_Service() )->by_card_id( 'FRE4', 'pl' );
        $this->assertNotSame( $card->description_pl, $card->description_en );
        $this->assertStringContainsString( 'James wstrzykuje', $card->description_pl );
    }
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
```php
class MatrixServiceTest extends WP_UnitTestCase {
    public function test_llm_matrix_maps_llm10_to_card_llm2(): void {
        $matrix = ( new Matrix_Service() )->llm();
        $row_card_ids = array_map( fn( $r ) => $r->card_id, $matrix->rows_for( 'LLM10' ) );
        $this->assertContains( 'LLM2', $row_card_ids );
    }
}
```

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
```php
class CardServiceTest2 extends WP_UnitTestCase {
    public function test_aaik_is_flagged_critical(): void {
        $card = ( new Card_Service() )->by_card_id( 'AAIK', 'en' );
        $this->assertTrue( $card->is_critical );
    }

    public function test_cld3_cross_references_a05(): void {
        $card = ( new Card_Service() )->by_card_id( 'CLD3', 'en' );
        $this->assertContains( 'A05:2021', $card->owasp_refs );
    }
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
| SP3 | Spoofing | "An attacker could try one credential after another and there's nothing to slow them down (online or offline)" | *"Atakujący może próbować kolejnych danych uwierzytelniających bez żadnego mechanizmu spowalniającego"* | **A07:2021 Identification and Authentication Failures**, OAT-007/OAT-008 — pokrewne SR-05.4 (rate limiting `wp-login.php`) |
| TA2 | Tampering | "An attacker can take advantage of your custom key exchange or integrity control which you built instead of using standard crypto" | *"Atakujący może wykorzystać własną implementację wymiany kluczy zamiast standardowej kryptografii"* | **A02:2021 Cryptographic Failures** — pokrewne D-06 (użycie natywnego `wp_hash_password` WordPressa, nie własnej implementacji) |
| TA6 | Tampering | "An attacker can write to a data store your code relies on" | *"Atakujący może zapisywać dane w magazynie danych, na którym opiera się kod"* | **A01:2021 Broken Access Control / A08:2021 Software and Data Integrity Failures** |

### Plan testów TDD

**Backend:**
```php
class StrideHeatmapServiceTest extends WP_UnitTestCase {
    public function test_returns_exactly_six_categories(): void {
        $heatmap = ( new Stride_Heatmap_Service() )->compute();
        $this->assertCount( 6, $heatmap->categories );
    }
}

class StrideHeatmapControllerTest extends WP_UnitTestCase {
    public function test_requires_capability(): void {
        wp_set_current_user( 0 ); // anonymous
        $request  = new WP_REST_Request( 'GET', '/securepress/v1/stride-heatmap' );
        $response = rest_get_server()->dispatch( $request );
        $this->assertSame( 401, $response->get_status() );
    }
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
```php
class CardServiceTest3 extends WP_UnitTestCase {
    public function test_emr2_has_no_owasp_ref_but_has_misc_note(): void {
        $card = ( new Card_Service() )->by_card_id( 'EMR2', 'en' );
        $this->assertEmpty( $card->owasp_refs );
        $this->assertNotNull( $card->misc_note );
    }
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
```php
class MatrixServiceTest2 extends WP_UnitTestCase {
    public function test_mobile_vs_web_maps_masvs_storage(): void {
        $matrix = ( new Matrix_Service() )->mobile_vs_web();
        $this->assertNotEmpty( $matrix->rows_for( 'MASVS-STORAGE' ) );
    }
}
```

**E2E:** `us10-mobile-security.spec.ts`.

---

## US-11 — Bezpieczeństwo DevOps + Cloud, i wzmocnienie samego WordPressa (karty DVO + CLD + BOT)

**Rola:** DevSecOps engineer / administrator instalacji WordPress
**Potrzeba:** przeglądać ryzyka supply chain (DVO), błędną konfigurację cloud (CLD), wzorce automatycznych ataków (BOT) oraz — dodatkowo — wzmocnić samą tę instalację WordPress
**Cel:** chronić potoki CI/CD, ograniczać ryzyko cloud, bronić się przed botami i przed atakami specyficznymi dla WordPress (XML-RPC, brute-force na `wp-login.php`)

### Polskie tłumaczenia kart DVO + BOT

| Karta | Suit | Angielski oryginał | Polskie tłumaczenie | Mapowanie |
|---|---|---|---|---|
| DVOK | DVO | "Timo can compromise software, development environments, or DevOps tooling by injecting malicious code via external dependencies or exploited developer credentials" | *"Timo może skompromitować oprogramowanie, środowiska developerskie lub narzędzia DevOps, wstrzykując złośliwy kod przez zewnętrzne zależności"* | **CICD-SEC-3 Dependency Chain Abuse**, A06:2021 — pokrewne SR-10.4 (skan WPScan) |
| DVOQ | DVO | "Seba can access the code repository, log files, command line history, pipelines, or other places, to gain access to secrets or other sensitive information" | *"Seba może uzyskać dostęp do repozytorium kodu, logów, historii linii komend lub pipeline'ów, aby zdobyć sekrety"* | **CICD-SEC-6 Insufficient Credential Hygiene** |
| BOTK | BOT | "EDVAC can collect application content and/or other data for use elsewhere" | *"EDVAC może zbierać treść aplikacji i/lub inne dane do wykorzystania gdzie indziej"* | **OAT-011 Scraping** |
| BOTX | BOT | "Ferranti Pegasus can enumerate individual authentication credentials, or payment card data... by trying different values" | *"Ferranti Pegasus może enumerować dane uwierzytelniające lub dane karty płatniczej, próbując różnych wartości"* | **OAT-021 Card Cracking / OAT-008 Credential Stuffing** — pokrewne AC-17 (`wp-login.php` credential stuffing) |

### Kryteria akceptacji
- `/frameworks/devops-security/` zawiera sekcje DVO, CLD, BOT
- Kliknięcie krytycznej karty BOT otwiera dialog ostrzeżenia
- `GET /wp-json/securepress/v1/threats?suit=bot` jest rate-limited (429 po > 60 req/min per IP)
- `xmlrpc.php` zwraca 403/404, nie standardową odpowiedź XML-RPC
- 6. nieudane logowanie do `wp-login.php` w ciągu 10 minut z tego samego IP jest blokowane

### Plan testów TDD

**Backend:**
```php
class RateLimitTest extends WP_UnitTestCase {
    public function test_bot_suit_returns_429_after_60_requests(): void {
        for ( $i = 0; $i < 60; $i++ ) {
            $request = new WP_REST_Request( 'GET', '/securepress/v1/threats' );
            $request->set_param( 'suit', 'bot' );
            rest_get_server()->dispatch( $request );
        }
        $request  = new WP_REST_Request( 'GET', '/securepress/v1/threats' );
        $request->set_param( 'suit', 'bot' );
        $response = rest_get_server()->dispatch( $request );
        $this->assertSame( 429, $response->get_status() );
        $this->assertNotEmpty( $response->get_headers()['Retry-After'] ?? null );
    }

    public function test_xmlrpc_is_disabled(): void {
        $this->assertFalse( apply_filters( 'xmlrpc_enabled', true ) );
    }
}

class CardServiceTest4 extends WP_UnitTestCase {
    public function test_dvok_cross_references_a06(): void {
        $card = ( new Card_Service() )->by_card_id( 'DVOK', 'en' );
        $this->assertContains( 'A06:2021', $card->owasp_refs );
    }
}
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
| VE2 | "Brian can gather information about the underlying configurations, schemas, logic, code... due to the content of error messages, or poor configuration, or the presence of default installation files" | *"Brian może zebrać informacje o konfiguracji, schematach, logice, kodzie poprzez treść komunikatów błędów lub słabą konfigurację"* | **A05:2021 Security Misconfiguration + A09:2021 Logging Failures** — pokrewne SR-14.2 (`DISALLOW_FILE_EDIT`), skrytej wersji WordPress |
| VE3 | "Robert can input malicious data because the allowed protocol format is not being checked, or duplicates are accepted, or the structure is not being verified" | *"Robert może wprowadzić złośliwe dane, ponieważ nie jest sprawdzany dozwolony format lub nie weryfikuje się struktury"* | **A03:2021 Injection** |
| VE4 | "Dave can input malicious field names or data because it is not being checked within the context of the current user and process" | *"Dave może wprowadzić złośliwe nazwy pól lub dane, ponieważ nie są sprawdzane w kontekście aktualnego użytkownika i procesu"* | **A01:2021 Broken Access Control** (mass assignment) |

### Plan testów TDD

**Backend:**
```php
class CardServiceTest5 extends WP_UnitTestCase {
    public function test_website_app_has_exactly_six_suits(): void {
        $suits = ( new Card_Service() )->suits_by_edition( 'webapp' );
        sort( $suits );
        $this->assertSame( array( 'at', 'az', 'c', 'cr', 'sm', 've' ), $suits );
    }

    public function test_ve3_cross_references_a03(): void {
        $card = ( new Card_Service() )->by_card_id( 'VE3', 'en' );
        $this->assertContains( 'A03:2021', $card->owasp_refs );
    }
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
```php
class CodeSampleTest extends WP_UnitTestCase {
    use Eris\TestTrait;

    public function test_every_seeded_mitigation_has_a_python_sample(): void {
        $this->forAll( Generator\elements( ...seeded_mitigation_ids() ) )
            ->then( function ( int $mitigationId ) {
                $samples = ( new Code_Sample_Repository() )->by_mitigation_id( $mitigationId );
                $languages = array_map( fn( $s ) => $s->language, $samples );
                $this->assertContains( 'python', $languages );
            } );
    }
}
```

**E2E:** `us13-python-code.spec.ts`.

---

## US-14 — Próbki kodu Java

**Rola:** Java developer
**Potrzeba:** zobaczyć próbkę kodu Java dla każdej mitigacji
**Cel:** porównać z idiomami PHP/WordPress tej aplikacji

### Plan testów TDD

**Backend:** analogicznie do US-13, właściwość sprawdza obecność `java` w każdej mitigacji.

**E2E:** `us14-java-code.spec.ts` — zakładka Java pokazuje idiom Spring Boot/Spring Security; próbka jest jednoznacznie oznaczona jako treść, niezwiązana z żadnym artefaktem budowania backendu.

---

## US-15 — Próbki kodu Scala (ataki supply-chain)

**Rola:** Scala developer
**Potrzeba:** znaleźć próbki kodu Scala dla ataków na łańcuch dostaw
**Cel:** zaimplementować SCA w pipeline Scali

### Plan testów TDD

**E2E:** `us15-scala-code.spec.ts` — filtruj próbki po `language=scala` i `tag=supply-chain`.

---

## US-16 — Próbki kodu Lua (rate limiting / LLM DoS)

**Rola:** Lua/OpenResty developer
**Potrzeba:** zobaczyć przykłady Lua dla rate limiting zapobiegającego LLM DoS
**Cel:** skonfigurować guardrails NGINX dla proxy LLM API

### Plan testów TDD

**Backend:**
```php
class CodeSampleServiceTest extends WP_UnitTestCase {
    public function test_llm2_mitigation_has_lua_resty_limit_req_sample(): void {
        $samples = ( new Code_Sample_Repository() )->by_mitigation_id( llm2_mitigation_id() );
        $lua = array_values( array_filter( $samples, fn( $s ) => $s->language === 'lua' ) )[0];
        $this->assertStringContainsString( 'lua-resty-limit-req', $lua->code );
    }
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
```php
class SearchServiceTest extends WP_UnitTestCase {
    public function test_returns_highlighted_excerpts(): void {
        $results = ( new Search_Service() )->query( 'deepfake', 'en' );
        $this->assertNotEmpty( $results );
        $this->assertStringContainsString( '<mark>', $results[0]->excerpt );
    }
}

class SearchControllerTest extends WP_UnitTestCase {
    public function test_rejects_query_over_200_chars(): void {
        $request = new WP_REST_Request( 'GET', '/securepress/v1/search' );
        $request->set_param( 'q', str_repeat( 'a', 201 ) );
        $response = rest_get_server()->dispatch( $request );
        $this->assertSame( 422, $response->get_status() );
    }
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
```php
class ExportControllerTest extends WP_UnitTestCase {
    public function test_enqueues_job_and_returns_202(): void {
        $request = new WP_REST_Request( 'GET', '/securepress/v1/export' );
        $request->set_param( 'format', 'csv' );
        $request->set_param( 'framework', 'OWASP_LLM' );
        $response = rest_get_server()->dispatch( $request );
        $this->assertSame( 202, $response->get_status() );
        $this->assertNotEmpty( $response->get_data()['jobId'] );
    }
}

class ExportJobTest extends WP_UnitTestCase {
    public function test_rejects_args_missing_framework(): void {
        $args = new Export_Csv_Args( format: 'csv', framework: '' );
        $this->assertFalse( ( new Export_Args_Validator() )->validate( $args )->is_valid() ); // AC-14
    }
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

**Ważna uwaga metodologiczna:** ta talia — w przeciwieństwie do FRE/LLM/AAI/CLD/STRIDE/MLSec/Mobile/DVO/BOT/Website App — **nie opisuje podatności technicznych z określonym poziomem severity**. W tym projekcie gwarancja "karta `design_harm` nigdy nie ma severity" jest wymuszana przez ograniczenie `CHECK` bazy danych MySQL (`chk_design_harm_has_no_severity`, patrz `PLAN.md` D-04) — **jedyne miejsce w tej serii, gdzie gwarancja pochodzi z warstwy danych, nie z kodu aplikacji czy kompilatora**. Poniższy test weryfikuje to bezpośrednio, próbując ominąć całą warstwę PHP.

### Kryteria akceptacji
- `/frameworks/digital-harms/` wyświetla wszystkie karty pogrupowane po 5 suitach
- Każda karta renderowana jest z odznaką "harm projektowy", nigdy z odznaką severity
- Banner disclaimera wyjaśnia harm projektowy vs. podatność techniczna
- Bezpośredni `INSERT` do bazy danych z `card_kind='design_harm'` i niepustym `severity` jest odrzucany przez MySQL

### Plan testów TDD

**Backend:**
```php
class DesignHarmConstraintTest extends WP_UnitTestCase {
    public function test_mysql_check_constraint_rejects_design_harm_with_severity(): void {
        global $wpdb;
        $this->expectException( mysqli_sql_exception::class ); // lub sprawdzenie $wpdb->last_error
        $wpdb->query(
            $wpdb->prepare(
                "INSERT INTO {$wpdb->prefix}sp_cards
                 (card_id, suit_code, suit_name, edition, card_value, card_kind, severity,
                  description_en, description_pl, owasp_refs, mitre_refs, content_sha256)
                 VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)",
                'FAKE1', 'SCO', 'Scope', 'dbd', '2', 'design_harm', 'high',
                'test', 'test', '[]', '[]', str_repeat( '0', 64 )
            )
        );
        // Test przechodzi TYLKO jeśli baza danych odrzuciła zapytanie — to jest weryfikacja
        // AC-16 na poziomie silnika bazy danych, niezależnie od jakiegokolwiek kodu PHP.
    }
}

class CardServiceTest6 extends WP_UnitTestCase {
    public function test_sco2_cross_references_a04(): void {
        $card = ( new Card_Service() )->by_card_id( 'SCO2', 'en' );
        $this->assertContains( 'A04:2021', $card->owasp_refs );
    }
}

class CardControllerTest extends WP_UnitTestCase {
    public function test_digital_harms_suits_never_return_a_severity_value(): void {
        $request = new WP_REST_Request( 'GET', '/securepress/v1/threats' );
        $request->set_param( 'suit', 'sco' );
        $response = rest_get_server()->dispatch( $request );
        foreach ( $response->get_data()['items'] as $item ) {
            $this->assertSame( 'design_harm', $item['cardKind'] );
            $this->assertArrayNotHasKey( 'severity', $item );
        }
    }
}
```

**Acceptance:**
```php
class DigitalHarmsCest {
    public function shows_all_five_suits_and_disclaimer( AcceptanceTester $I ) {
        $I->amOnPage( '/frameworks/digital-harms/' );
        $I->see( 'nie jest listą podatności technicznych' ); // treść bannera disclaimera
        foreach ( array( 'sco', 'arc', 'age', 'tru', 'por' ) as $suit ) {
            $I->seeElement( "[data-testid='{$suit}-section']" );
        }
    }

    public function never_shows_severity_badge_on_dbd_card( AcceptanceTester $I ) {
        $I->amOnPage( '/frameworks/digital-harms/' );
        $I->seeElement( '[data-testid="card-SCO2"] [data-testid="design-harm-badge"]' );
        $I->dontSeeElement( '[data-testid="card-SCO2"] [data-testid="severity-badge"]' );
    }
}
```

**E2E:**
```typescript
test.describe('US-19 Digital-by-Default Harms', () => {
  test('shows all 5 suits and the disclaimer banner', async ({ page }) => {
    await page.goto('/frameworks/digital-harms/')
    await expect(page.getByTestId('harms-disclaimer-banner')).toBeVisible()
    for (const suit of ['sco', 'arc', 'age', 'tru', 'por']) {
      await expect(page.getByTestId(`${suit}-section`)).toBeVisible()
    }
  })

  test('switching to Polish shows the reviewed SCO2 translation', async ({ page }) => {
    await page.goto('/frameworks/digital-harms/?lang=pl')
    await expect(page.getByTestId('card-SCO2')).toContainText(/Tommy nie tworzy/i)
  })

  test('API response for dbd cards never carries a severity value', async ({ request }) => {
    const response = await request.get('/wp-json/securepress/v1/threats?suit=sco')
    const body = await response.json()
    for (const card of body.items) {
      expect(card.cardKind).toBe('design_harm')
      expect(card.severity).toBeUndefined()
    }
  })
})
```

---

## Podsumowanie planu testów

### Cel: ≥ 200 testów łącznie

| Warstwa | Framework | Liczba | Typ |
|---|---|---|---|
| Backend — unit | PHPUnit + `WP_UnitTestCase` | ≥ 55 | Serwisy, repozytoria, walidatory |
| Backend — właściwości | `eris` | ≥ 15 | Niezmienniki (5 języków per mitigacja, YAML z nieznanymi polami odrzucany) |
| Backend — REST integracja | `WP_UnitTestCase` + `WP_REST_Request` | ≥ 26 | Kontrolery, uprawnienia, rate-limit |
| Backend — DB constraint | PHPUnit z bezpośrednim `$wpdb->query()` | ≥ 3 | Weryfikacja `CHECK` constraint na poziomie silnika bazy |
| Acceptance | `wp-browser`/Codeception | ≥ 20 | Scenariusze z prawdziwą instalacją WordPress + MySQL |
| E2E | Playwright | ≥ 27 | 19 plików spec × ~1.4 scenariuszy |
| **RAZEM** | | **≥ 200** | |

### Cele pokrycia kodu

| Warstwa | Narzędzie | Cel |
|---|---|---|
| Backend PHP | PHPUnit + `pcov`/`xdebug` | ≥ 85% dla `includes/service` |
| Frontend JS | (brak frameworka — pokrycie mierzone przez proste testy jednostkowe modułów ES, jeśli dodane) | — |

### Kolejność wykonania testów w CI

```
[1] composer install --no-dev=false                — instalacja z roave/security-advisories
[2] phpcs --standard=WordPress-Extra .              — SAST/WPCS, szybkie
[3] phpstan analyse                                  — statyczna analiza typów + custom rule D-03
[4] wp-env start                                     — lokalna instancja WordPress + MySQL do testów
[5] phpunit                                           — unit + eris (przeciwko testowej bazie)
[6] codecept run acceptance                           — wp-browser przeciwko prawdziwej instalacji
[7] composer audit && wpscan --url http://localhost   — SCA
[8] npm run build                                      — bundlowanie/minifikacja vanilla JS
[9] npm run e2e                                        — Playwright headless Chromium + Firefox
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
| AC-01: SQL Injection `?q=` | WPCS `WordPress.DB.PreparedSQL` sniff + integration test | Sprint 3–4 |
| AC-02: XSS w opisie karty | `wp_kses()`/WPCS `EscapeOutput` sniff + integration test | Sprint 5–7 |
| AC-05: Bot scraping | REST integration test — 429 po 60 req | Sprint 10–12 |
| AC-06: YAML file tampering | `Integrity_Verifier::verify()` — abort na hash mismatch | Sprint 5–7 |
| AC-09: Privilege escalation `/stride-heatmap/` | Capability check — 401 bez roli | Sprint 5–7 |
| AC-11: i18n locale injection | `?lang=` allowlist — fallback do domyślnej lokalizacji | Sprint 9–10 |
| AC-14: REST route bez `permission_callback` | CI grep sprawdzający każde wywołanie `register_rest_route()` | Sprint 1–2 |
| AC-15: BotWarningModal bypass | `us11-devops-security.spec.ts` — bezpośrednie wywołanie API wciąż zablokowane | Sprint 5–7 |
| AC-16: Harms deck misread as CVE severity | **Test na poziomie bazy danych** — bezpośredni `INSERT` odrzucony przez `CHECK` constraint, niezależnie od PHP | Sprint 5–7 |
| AC-17: `wp-login.php` credential stuffing | Test rate-limitera logowania | Sprint 1–2 |
| AC-18: XML-RPC abuse | Test potwierdzający `xmlrpc_enabled` filter zwraca `false` | Sprint 1–2 |
