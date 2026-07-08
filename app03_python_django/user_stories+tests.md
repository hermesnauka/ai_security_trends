# ThreatCompass 2026 — User Stories & TDD Test Plan

**Version:** 1.0
**Date:** 2026-07-07
**Methodology:** Test-Driven Development (TDD) — Red → Green → Refactor
**Frameworks:** `pytest` + `pytest-django` + `factory_boy` (Django unit/integration) · Playwright for Python (E2E)

---

## Part A — TDD Principles Applied in This Project

```
RED       — Write a failing test that describes the desired behaviour BEFORE writing any code.
GREEN     — Write the minimal production code that makes the test pass.
REFACTOR  — Improve the code without breaking tests.
```

Every user story in this document follows the same five-layer structure:

1. **Acceptance Criteria** (Gherkin Given/When/Then) — drives E2E tests.
2. **Selector/Service unit tests** (`pytest`, no DB or a lightweight `django_db` fixture, no HTTP) — the business-logic layer.
3. **DRF integration tests** (`APITestCase`/`pytest-django` `client`, real test DB) — one per endpoint.
4. **Template/HTMX tests** (`django.test.Client` asserting on rendered HTML fragments) — for partial-swap views.
5. **E2E tests** (Playwright for Python, one browser-level scenario per story).

A PR SHALL include the failing test(s) for a story in the **same commit** as (or an earlier commit than) the production code that makes them pass — enforced by code review, not tooling, per NFR-05.5 in `requirements.md`.

### Test stack (add dependencies before writing the first test)

```toml
# backend_django/pyproject.toml [tool.poetry.group.test.dependencies] (or requirements-test.txt)
pytest = "^8.2"
pytest-django = "^4.9"
factory-boy = "^3.3"
pytest-cov = "^5.0"
playwright = "^1.45"
pytest-playwright = "^0.5"
```

```ini
# backend_django/requirements-test.txt (Celery task testing)
celery[pytest] = "^5.4"     # provides the `celery_app`/`celery_worker` pytest fixtures
```

### Test pyramid overview

```
              ┌────────────────┐
              │   E2E (19+)    │  Playwright (Python) — one per user story US-01..US-19
              │                │  plus 12 for extended card stories US-20..US-31
              ├────────────────┤
              │ Template/HTMX  │  django.test.Client — per partial-swap view
              │ Tests (~30)    │
              ├────────────────┤
              │ DRF Integration│  APITestCase — per REST endpoint
              │ Tests (~35)    │
              ├────────────────┤
              │ Service/Selector│ pytest, pure logic — fast, the bulk of the suite
              │ Unit Tests (80+)│  includes HashVerificationService, MatrixComputationService
              └────────────────┘
Celery tasks (export, YAML re-ingestion, periodic integrity re-check): tested with
CELERY_TASK_ALWAYS_EAGER=True in pytest, so task bodies run synchronously in the test process
— no separate test framework or language needed.
```

---

## Part B — Core User Stories (US-01 – US-19)

### US-01 — Browse the Framework Catalog

**Story:** As a security engineer, I want to browse all supported security frameworks so that I have one entry point to every standard.

```gherkin
Feature: Framework catalog
  Scenario: View all frameworks on the home page
    Given the database contains all seeded frameworks
    When I open "/"
    Then I see one tile per framework with name, version, and threat count
  Scenario: Navigate into a framework
    Given I am on the home page
    When I click the "OWASP LLM Top 10" tile
    Then I am on "/frameworks/OWASP_LLM/" and see its threat list
```

**TDD test list (write first, in this order):**
1. `test_framework_selector_returns_all_frameworks_ordered_by_name` (`frameworks/tests/test_selectors.py`)
2. `test_framework_list_view_renders_one_tile_per_framework` (`frameworks/tests/test_views.py`)
3. `test_framework_detail_view_404_for_unknown_code`
4. `test_api_frameworks_list_returns_expected_shape` (`APITestCase`)
5. `test_e2e_home_page_shows_framework_tiles` (Playwright)

---

### US-02 — Filter Threats by Framework / Severity / STRIDE / Tag

**Story:** As a security engineer, I want to filter threats by framework, severity, STRIDE letter, and tag so that I can quickly find what's relevant.

```gherkin
Scenario: Combine filters
  Given threats exist across several frameworks and severities
  When I request "/threats/?framework=OWASP_LLM&severity=CRITICAL"
  Then only CRITICAL OWASP_LLM threats are returned
  And the response is an HTMX partial (no <html>/<body> wrapper) when triggered via HX-Request
```

**TDD test list:**
1. `test_threat_selector_filters_by_framework_and_severity`
2. `test_threat_selector_filters_by_stride_letter`
3. `test_threat_list_view_returns_partial_template_on_htmx_request`
4. `test_threat_list_view_returns_full_page_on_direct_navigation`
5. `test_api_threats_list_supports_multi_filter_query_params`
6. `test_e2e_filter_panel_updates_results_without_full_reload`

---

### US-03 — View Threat Detail with Mitigations and Code

**Story:** As a security engineer, I want to see a threat's mitigations and code samples so that I know how to implement protection.

```gherkin
Scenario: Open a threat detail page
  Given threat "LLM01" has 2 mitigations, each with 5 code samples
  When I open "/threats/LLM01/"
  Then I see tabs: Overview, Attack Vectors, Mitigations, Code Samples, Cross-References
  And the "Code Samples" tab lists Python, Java, Go, Scala, Lua sub-tabs for each mitigation
```

**TDD test list:**
1. `test_mitigation_selector_returns_mitigations_with_prefetched_code_samples` (avoid N+1 — assert query count with `django.test.utils.CaptureQueriesContext`)
2. `test_threat_detail_view_renders_all_five_language_tabs`
3. `test_attack_demo_sample_requires_confirmation_before_code_is_present_in_response`
4. `test_api_threat_detail_includes_nested_mitigations_and_code_samples`
5. `test_e2e_threat_detail_tabs_switch_via_htmx`

---

### US-04 — Cross-Framework Mapping (LLM ↔ ATLAS ↔ SecAI+)

**Story:** As a CompTIA SecAI+ student, I want to see how LLM01 maps to MITRE ATLAS and SecAI+ so that I understand cross-framework relationships.

```gherkin
Scenario: View the LLM matrix
  Given LLM01 has a CrossReference to AML.T0051 with relationship MAPS_TO
  When I open "/matrix/llm/"
  Then the matrix shows a row for LLM01 with a linked cell to AML.T0051
```

**TDD test list:**
1. `test_cross_reference_selector_returns_mappings_for_source_code`
2. `test_matrix_view_renders_llm_atlas_secai_row_per_threat`
3. `test_api_cross_references_filter_by_source_code`
4. `test_e2e_matrix_cell_click_navigates_to_target_threat`

---

### US-05 — Browse `FRE` (Frontend) Companion Cards

**Story:** As a frontend developer, I want to browse Cornucopia Companion `FRE` cards so that I understand client-side attack scenarios.

**TDD test list:**
1. `test_card_selector_filters_by_suit_code_FRE`
2. `test_cards_companion_frontend_view_renders_all_FRE_cards`
3. `test_api_cards_list_filters_by_suit`
4. `test_e2e_fre_suit_page_lists_cards_with_polish_translation_toggle`

### US-06 — Browse `LLM` Companion Cards with the LLM Matrix

**TDD test list:**
1. `test_card_selector_filters_by_suit_code_LLM`
2. `test_llm_matrix_view_cross_links_LLM_suit_cards_to_owasp_llm_top10`
3. `test_e2e_llm_cards_page_shows_matrix_link_per_card`

### US-07 — Browse `AAI` (Agentic AI) Companion Cards

**TDD test list:**
1. `test_card_selector_filters_by_suit_code_AAI`
2. `test_agentic_matrix_view_compares_AAI_and_LLM_suits`
3. `test_e2e_agentic_page_renders_autonomy_risk_badge_for_critical_cards`

### US-08 — STRIDE EoP Catalogue with Heatmap

**TDD test list:**
1. `test_stride_heatmap_selector_aggregates_coverage_by_framework_and_letter`
2. `test_stride_heatmap_view_renders_color_coded_cells`
3. `test_api_stride_heatmap_returns_json_for_chartjs`
4. `test_e2e_heatmap_cell_click_filters_threat_list`

### US-09 — Elevation of MLSec Cards (Model/Input/Output/Dataset Risk)

**TDD test list:**
1. `test_card_selector_filters_by_edition_mlsec`
2. `test_mlsec_view_groups_cards_by_suit_EMR_EIR_EOR_EDR`
3. `test_e2e_mlsec_page_shows_ml_specific_badge`

### US-10 — Mobile MASVS Cards

**TDD test list:**
1. `test_card_selector_filters_by_edition_mobileapp`
2. `test_mobile_vs_web_matrix_view_renders_comparison_table`
3. `test_e2e_mobile_page_lists_all_six_suits`

### US-11 — DevOps (`DVO`) and Automated Threats (`BOT`) Cards

**TDD test list:**
1. `test_card_selector_filters_by_suit_codes_DVO_and_BOT`
2. `test_bot_card_view_shows_risk_acknowledgement_modal_for_critical_cards`
3. `test_e2e_devops_page_requires_modal_dismissal_before_showing_BOTX_card`

### US-12 — Digital-by-Default Harms Deck

**Story:** As a public-sector product owner, I want to browse the "Digital-by-Default Harms" deck so that I can assess exclusion and over-surveillance risk in a digital service.

**TDD test list:**
1. `test_card_selector_filters_by_edition_dbd`
2. `test_dbd_harms_view_labels_deck_as_non_technical_harms_not_cve_style`
3. `test_e2e_dbd_harms_page_links_to_A04_insecure_design`

### US-13–US-16 — Code Samples per Language (Java, Go, Scala, Lua)

**Story (generalized):** As a `<language>` developer, I want to filter code samples by `language=<LANG>` so that I find language-specific patterns immediately.

**TDD test list (parametrized across the 4 languages: JAVA, GO, SCALA, LUA):**
1. `test_code_sample_selector_filters_by_language[JAVA-GO-SCALA-LUA]`
2. `test_api_code_samples_endpoint_filters_by_language_query_param`
3. `test_e2e_code_sample_language_tab_shows_only_selected_language`

### US-17 — Global Search

**TDD test list:**
1. `test_search_selector_uses_postgres_search_vector_across_threats_cards_mitigations`
2. `test_search_view_highlights_matching_excerpt`
3. `test_api_search_groups_results_by_type`
4. `test_e2e_search_box_present_on_every_page_and_returns_results`

### US-18 — Export to CSV/PDF

**TDD test list:**
1. `test_export_task_enqueues_celery_job_and_returns_job_id` (`CELERY_TASK_ALWAYS_EAGER=True` in tests)
2. `test_generate_csv_task_writes_rows_matching_the_filtered_queryset` (stdlib `csv` module)
3. `test_generate_pdf_task_renders_weasyprint_output_from_django_template`
4. `test_export_status_view_returns_pending_then_done`
5. `test_export_download_view_requires_the_same_session_that_requested_the_export`
6. `test_e2e_export_button_polls_status_and_offers_download_link`

### US-19 — Polish ↔ English Language Switch

**Story:** As a Polish-speaking student, I want to switch the whole application from English to Polish with one click so that I can study in my native language.

```gherkin
Scenario: Switch language
  Given I am viewing "/threats/LLM01/" in English
  When I click the language toggle
  Then the page content re-renders in Polish without a full navigation
  And the "django_language" cookie is set to "pl"
  And code sample bodies remain in English regardless of the UI language

Scenario: Missing Polish translation falls back to English
  Given a ThreatTranslation for locale "pl" does not exist for threat "LLM10"
  When I view "/threats/LLM10/" with locale "pl"
  Then the English text is shown with a small "EN" fallback badge
  And no field is rendered blank
```

**TDD test list:**
1. `test_locale_middleware_defaults_to_pl_when_accept_language_absent`
2. `test_locale_middleware_defaults_to_en_when_accept_language_prefers_en_without_pl`
3. `test_threat_translation_selector_falls_back_to_english_when_polish_missing`
4. `test_card_serializer_returns_description_pl_or_falls_back_to_description_en`
5. `test_compilemessages_check_has_zero_missing_keys` (CI script test)
6. `test_code_sample_body_is_never_translated_regardless_of_locale`
7. `test_e2e_language_toggle_switches_ui_without_full_page_reload`
8. `test_e2e_url_paths_remain_english_after_switching_to_polish`

---

## Part C — Extended User Stories from the OWASP Card Decks (`docs/OWASP_stories/*.yaml`)

Each subsection below takes **real, verbatim card text** from the corresponding YAML file, gives a reviewed Polish translation (to be stored in `data/translations/cards_pl.json`, per FR-17.6), and explains which OWASP/MITRE/STRIDE threat category the card covers. Each subsection ends with one or two new user stories (US-20 and up) plus their TDD test list.

### C.1 — STRIDE Elevation of Privilege v5.0 (`STRIDE__eop-cards-5.0-en.yaml`)

| Card | English (verbatim from YAML) | Polish translation | Threat mapping & explanation |
|---|---|---|---|
| **SP2** | "An attacker could take over the port or socket that the server normally uses" | *"Atakujący może przejąć port lub gniazdo (socket), które normalnie wykorzystuje serwer"* | **STRIDE: Spoofing.** Bez kontroli, kto może związać się z danym portem, atakujący podszywa się pod usługę. Odpowiada **OWASP A05:2021 Security Misconfiguration** — usługa nie wymusza, by dany port mógł otworzyć tylko zaufany proces. |
| **SP3** | "An attacker could try one credential after another and there's nothing to slow them down (online or offline)" | *"Atakujący może próbować kolejnych danych uwierzytelniających jedne po drugich, bez żadnego mechanizmu, który by go spowolnił (online lub offline)"* | **STRIDE: Spoofing.** To klasyczny **brute-force / credential stuffing** — mapuje się na **OWASP A07:2021 Identification and Authentication Failures** oraz **OWASP OAT-007 Credential Cracking / OAT-008 Credential Stuffing** (Automated Threats). |
| **TA2** | "An attacker can take advantage of your custom key exchange or integrity control which you built instead of using standard crypto" | *"Atakujący może wykorzystać własną implementację wymiany kluczy lub kontroli integralności, zbudowaną zamiast użycia standardowej kryptografii"* | **STRIDE: Tampering.** Odpowiada **OWASP A02:2021 Cryptographic Failures** — "nie wynajduj własnej kryptografii" jest jedną z najstarszych i wciąż aktualnych zasad bezpiecznego projektowania. |
| **TA6** | "An attacker can write to a data store your code relies on" | *"Atakujący może zapisywać dane w magazynie danych, na którym opiera się twój kod"* | **STRIDE: Tampering.** Odpowiada **OWASP A01:2021 Broken Access Control** (brak kontroli zapisu) i **A08:2021 Software and Data Integrity Failures**. |

**US-20 — Study STRIDE Spoofing & Tampering with real card scenarios**
*Story:* As a security architect running a threat-modeling workshop, I want each STRIDE card's English text paired with a reviewed Polish translation and its OWASP mapping so that Polish-speaking participants can follow a session without losing precision.

**TDD test list:**
1. `test_card_fixture_loads_SP2_SP3_TA2_TA6_with_non_null_description_pl`
2. `test_card_detail_view_shows_owasp_mapping_badge_for_stride_cards` (`owasp_refs` populated: SP3→["A07:2021"], TA2→["A02:2021"])
3. `test_e2e_stride_card_detail_shows_both_languages_side_by_side_in_admin_preview`

---

### C.2 — OWASP Cornucopia Website App v3.0 (`webapp-cards-3.0-en.yaml`)

| Card | English (verbatim) | Polish translation | Threat mapping |
|---|---|---|---|
| **VE2** | "Brian can gather information about the underlying configurations, schemas, logic, code, software, services and infrastructure due to the content of error messages, or poor configuration, or the presence of default installation files or old, test, backup or copies of resources, or exposure of source code" | *"Brian może zebrać informacje o konfiguracji, schematach, logice, kodzie, oprogramowaniu, usługach i infrastrukturze poprzez treść komunikatów błędów, słabą konfigurację, obecność domyślnych plików instalacyjnych lub starych/testowych/zapasowych kopii zasobów, albo ujawnienie kodu źródłowego"* | **STRIDE: Information Disclosure.** Odpowiada **OWASP A05:2021 Security Misconfiguration** (domyślne pliki, verbose errors) oraz **A09:2021 Security Logging and Monitoring Failures** (błędy ujawniające szczegóły stosu). |
| **VE3** | "Robert can input malicious data because the allowed protocol format is not being checked, or duplicates are accepted, or the structure is not being verified, or the individual data elements are not being sanitized, or preferably validated for format, type, range, size, length and a whitelist of allowed characters or formats" | *"Robert może wprowadzić złośliwe dane, ponieważ nie jest sprawdzany dozwolony format protokołu, akceptowane są duplikaty, nie weryfikuje się struktury, a poszczególne elementy danych nie są sanityzowane ani — najlepiej — walidowane pod względem formatu, typu, zakresu, rozmiaru, długości i białej listy dozwolonych znaków"* | **STRIDE: Tampering.** To podręcznikowy opis braku walidacji wejścia — rdzeń **OWASP A03:2021 Injection**. |
| **VE4** | "Dave can input malicious field names or data because it is not being checked within the context of the current user and process" | *"Dave może wprowadzić złośliwe nazwy pól lub dane, ponieważ nie są one sprawdzane w kontekście aktualnego użytkownika i procesu"* | **STRIDE: Tampering / Elevation of Privilege.** Klasyczny wzorzec **mass assignment** — odpowiada **OWASP A01:2021 Broken Access Control** (decyzje autoryzacyjne ignorujące kontekst wywołania). |

**US-21 — Map every `VE` (Data Validation & Encoding) card to A03:2021 Injection defenses with runnable samples**
*Story:* As a Java developer new to Django, I want VE-suit cards linked to concrete Django/Spring/Gin/Akka/OpenResty validation code so that I can compare "the same defense" across five ecosystems.

**TDD test list:**
1. `test_card_VE3_has_five_code_samples_one_per_language`
2. `test_VE3_python_defense_sample_uses_django_forms_or_drf_serializer_validation`
3. `test_VE3_java_defense_sample_uses_jakarta_bean_validation`
4. `test_e2e_VE_suit_page_links_each_card_to_A03_2021_matrix_row`

---

### C.3 — OWASP Cornucopia Mobile App v1.1 (`mobileapp-cards-1.1-en.yaml`)

| Card | English (verbatim) | Polish translation | Threat mapping |
|---|---|---|---|
| **PC2** | "Andrew can expose sensitive data through the app's auto-generated screenshots when the app moves to the background" | *"Andrew może ujawnić dane wrażliwe poprzez automatycznie generowane zrzuty ekranu, gdy aplikacja przechodzi w tło"* | **STRIDE: Information Disclosure.** Odpowiada **OWASP MASVS-STORAGE** (dane wrażliwe nie mogą trwale trafiać do pamięci zrzutów ekranu / cache podglądu aplikacji). |
| **PC3** | "Harold can spy sensitive data being entered through the user interface because the data is excessive, not properly masked or cleaned up after use" | *"Harold może przechwycić dane wrażliwe wprowadzane w interfejsie użytkownika, ponieważ dane są nadmiarowe, niewłaściwie maskowane lub nieusuwane po użyciu"* | **STRIDE: Information Disclosure.** Odpowiada **MASVS-STORAGE** i zasadzie minimalizacji danych (powiązanej z RODO/GDPR). |
| **PC4** | "Kelly can expose sensitive data by taking advantage of the app's excessive permissions connected to the app's use of location, camera, microphone, storage, etc" | *"Kelly może ujawnić dane wrażliwe, wykorzystując nadmiarowe uprawnienia aplikacji związane z lokalizacją, kamerą, mikrofonem, pamięcią itd."* | **STRIDE: Elevation of Privilege / Information Disclosure.** Odpowiada **MASVS-PLATFORM** oraz ogólnej zasadzie **least privilege** (**OWASP A01:2021**). |

**US-22 — Compare mobile MASVS-STORAGE cards against the OWASP Web equivalent (`VE`/`CR` suits)**
*Story:* As an Android/iOS developer, I want the Mobile `PC` suit cross-linked to the closest Web `VE`/`CR` cards so that I understand which controls are mobile-specific versus universal.

**TDD test list:**
1. `test_mobile_vs_web_matrix_selector_pairs_PC2_with_CR_screen_data_protection_cards`
2. `test_e2e_mobile_vs_web_matrix_page_renders_PC_row_with_linked_web_cell`

---

### C.4 — OWASP Cornucopia Companion v1.0 — `LLM` and `AAI` suits (`__LLM_AI___companion-cards-1.0-en.yaml`)

| Card | English (verbatim) | Polish translation | Threat mapping |
|---|---|---|---|
| **LLM2** | "Samantha can exhaust computational resources or increase operational costs by submitting resource-intensive or recursive LLM queries, leading to model DoS" | *"Samantha może wyczerpać zasoby obliczeniowe lub zwiększyć koszty operacyjne, wysyłając zasobożerne lub rekurencyjne zapytania do LLM, co prowadzi do odmowy usługi modelu"* | **OWASP LLM10:2025 Unbounded Consumption.** **STRIDE: Denial of Service.** Powiązane z **MITRE ATLAS AML.T0029 Denial of ML Service**. |
| **LLM3** | "Dave can exploit overreliance on LLM outputs where critical human oversight is missing, leading to security failures or incorrect decisions based on hallucinations or flawed reasoning" | *"Dave może wykorzystać nadmierne poleganie na wynikach LLM przy braku krytycznego nadzoru człowieka, co prowadzi do błędów bezpieczeństwa lub błędnych decyzji opartych na halucynacjach lub błędnym rozumowaniu"* | **OWASP LLM09:2025 Misinformation / Overreliance.** Kluczowy temat egzaminu **CompTIA SecAI+** — "AI jako cel" wymaga **human-in-the-loop** dla decyzji krytycznych. |
| **LLM4** | "David can cause the model to disclose sensitive information from its training data, system prompts, configuration, services or other users' context due to insufficient output filtering or prompt leakage" | *"David może spowodować, że model ujawni informacje wrażliwe z danych treningowych, system promptów, konfiguracji, usług lub kontekstu innych użytkowników z powodu niewystarczającego filtrowania wyjścia lub wycieku promptu"* | **OWASP LLM02:2025 Sensitive Information Disclosure + LLM07:2025 System Prompt Leakage. STRIDE: Information Disclosure.** |
| **AAI2** | "Tay can misinterpret user intent due to insufficient context isolation or prompt enforcement and execute actions outside the expected task scope" | *"Tay może błędnie zinterpretować intencję użytkownika z powodu niewystarczającej izolacji kontekstu lub wymuszania promptu i wykonać działania wykraczające poza oczekiwany zakres zadania"* | **OWASP Agentic AI Top 10 2026 — Excessive Agency. STRIDE: Elevation of Privilege.** Wymaga kontroli **least privilege dla agentów** (patrz tabela SecAI+ w `docs/Security Architects...md`). |
| **AAI4** | "MissTrial can autonomously loop or chain external tool calls without enforcing rate limits or budget controls" | *"MissTrial może autonomicznie zapętlać lub łączyć wywołania zewnętrznych narzędzi bez wymuszania limitów szybkości lub kontroli budżetu"* | **OWASP Agentic AI Top 10 2026 (Unbounded Tool Use) — pokrewne LLM10:2025. STRIDE: Denial of Service** ("Denial of Wallet"). |
| **AAI5** | "Watson can reveal sensitive internal instructions, policies, or reasoning artifacts when exposed to adversarial prompting patterns" | *"Watson może ujawnić wrażliwe wewnętrzne instrukcje, polityki lub artefakty rozumowania, gdy zostanie poddany wzorcom adwersarialnego prompt engineeringu"* | **OWASP LLM07:2025 System Prompt Leakage. STRIDE: Information Disclosure.** |

**US-23 — Interactive LLM×AAI matrix built from real card text**
*Story:* As an ML engineer / AI architect, I want the `/matrix/llm/` and `/matrix/agentic/` pages to quote the exact Companion card wording (EN + PL) next to each OWASP LLM/Agentic AI Top 10 entry so that the mapping is traceable to source, not paraphrased.

**US-24 — Denial-of-Wallet guardrail demo (LLM2 / AAI4)**
*Story:* As a Lua/OpenResty developer, I want a rate-limiting code sample directly linked to cards LLM2 and AAI4 so that I can configure guardrails preventing model/tool-call DoS ("Denial of Wallet").

**TDD test list (US-23, US-24):**
1. `test_card_LLM2_and_AAI4_share_a_cross_reference_of_type_RELATED`
2. `test_llm_matrix_row_renders_verbatim_card_desc_en_and_reviewed_desc_pl`
3. `test_AAI2_card_owasp_refs_includes_agentic_ai_excessive_agency`
4. `test_lua_defense_sample_for_LLM2_uses_lua_resty_limit_req`
5. `test_e2e_llm_matrix_page_shows_source_yaml_filename_as_provenance_footnote`

---

### C.5 — Elevation of MLSec v1.0 (`RISKS__elevation-of-mlsec-cards-1.0-en.yaml`)

| Card | English (verbatim) | Polish translation | Threat mapping |
|---|---|---|---|
| **EMR2** | "When a model is filled with too much overlapping information, collisions in the representation space may lead to the model 'forgetting' information." *(misc: Catastrophic forgetting)* | *"Gdy model jest przeładowany zbyt dużą liczbą nakładających się informacji, kolizje w przestrzeni reprezentacji mogą prowadzić do 'zapominania' informacji przez model."* *(uwaga: katastroficzne zapominanie)* | **Model Risk — dostępność/integralność modelu.** Nie ma jednego kodu OWASP LLM Top 10, ale łączy się z **CompTIA SecAI+ "AI Model Reliability"** i pośrednio z **LLM04:2025 Data and Model Poisoning** (degradacja modelu w czasie). |
| **EMR3** | "An ML system may end up oscillating and not properly converging if using gradient descent in a space with a misleading gradient." *(misc: Oscillation)* | *"System ML może zacząć oscylować i nie zbiegać prawidłowo, jeśli używa gradientu prostego (gradient descent) w przestrzeni z wprowadzającym w błąd gradientem."* *(uwaga: oscylacja)* | **Model Risk — jakość/stabilność treningu.** Powiązane z **MITRE ATLAS ML Attack Staging** (adwersarialne manipulowanie krajobrazem strat modelu). |
| **EMR4** | "Setting weights and thresholds with a bad RNG can damage system behavior and lead to subtle security issues." *(misc: Randomness)* | *"Ustawianie wag i progów przy użyciu słabego generatora liczb pseudolosowych (RNG) może uszkodzić zachowanie systemu i prowadzić do subtelnych problemów bezpieczeństwa."* *(uwaga: losowość)* | **OWASP A02:2021 Cryptographic Failures (analogicznie — słaba entropia/RNG), rozszerzone na warstwę ML.** |

**US-25 — Model Risk glossary with CompTIA SecAI+ cross-references**
*Story:* As a data scientist / ML security engineer, I want Model Risk cards (EMR) explained in Polish with an explicit note on which are *not* classic OWASP items so that I don't force an artificial 1:1 mapping where none exists.

**TDD test list:**
1. `test_card_EMR2_owasp_refs_is_empty_and_comptia_ref_is_present` (data integrity: no false OWASP mapping)
2. `test_mlsec_view_renders_no_owasp_badge_when_owasp_refs_empty_but_shows_comptia_badge`
3. `test_e2e_mlsec_card_detail_explains_absence_of_direct_owasp_code`

---

### C.6 — Digital-by-Default Harms Deck v1.0 (`dbd-cards-1.0-en.yaml`)

| Card | English (verbatim) | Polish translation | Threat mapping |
|---|---|---|---|
| **SCO2** | "Tommy does not create, publish and maintain publicly all the service assumptions, specifications, constraints, source code, algorithms, formulas, configuration settings, operating instructions and processes" | *"Tommy nie tworzy, nie publikuje i nie utrzymuje publicznie wszystkich założeń usługi, specyfikacji, ograniczeń, kodu źródłowego, algorytmów, formuł, ustawień konfiguracyjnych, instrukcji działania i procesów"* | **OWASP A04:2021 Insecure Design (brak transparentności projektowej).** W ujęciu SecAI+/GRC odpowiada wymogom **wyjaśnialności algorytmów (AI Act, art. 13)**. |
| **SCO3** | "Charlotte designs the service so that claimants themselves have to generate/enter data about personal activities (e.g. job search) or obtain/enter existing data from elsewhere (e.g. care/health services, education providers)" | *"Charlotte projektuje usługę tak, że osoby korzystające z niej muszą samodzielnie generować/wprowadzać dane o swoich działaniach osobistych (np. poszukiwaniu pracy) lub zdobywać/wprowadzać dane już istniejące gdzie indziej (np. z opieki zdrowotnej, edukacji)"* | **Harm projektowy — nadmierne obciążenie użytkownika i ryzyko wykluczenia cyfrowego.** Powiązane z **OWASP A04:2021 Insecure Design** i zasadą **data minimization** (odwrócona: usługa domaga się więcej danych niż potrzebne od najsłabszego ogniwa — obywatela). |
| **SCO4** | "Sofia undertakes features which require claimants to provide information repeatedly or which is already held (e.g. address, other welfare benefits awarded, tax code)" | *"Sofia wdraża funkcje wymagające od osób korzystających z usługi ponownego podawania informacji, które już są w posiadaniu systemu (np. adres, inne przyznane świadczenia, kod podatkowy)"* | **Naruszenie zasady minimalizacji danych (RODO art. 5) i dobrych praktyk projektowych "collect once."** Klasyfikowane tu pod **A04:2021 Insecure Design**, nie pod podatność techniczną. |

**US-26 — Digital-ethics disclaimer and non-technical framing**
*Story:* As a compliance/GRC reviewer, I want the `dbd` deck clearly separated from technical-vulnerability decks in the UI (distinct color, distinct badge text "Harm projektowy / Design Harm") so that the tool is not misread as claiming these are CVE-style bugs.

**TDD test list:**
1. `test_dbd_card_serializer_sets_card_kind_field_to_design_harm_not_vulnerability`
2. `test_dbd_harms_view_renders_distinct_badge_color_and_disclaimer_banner`
3. `test_e2e_dbd_harms_page_disclaimer_links_to_A04_2021_and_grc_glossary_entry`

---

## Part D — Consolidated TDD Coverage Summary

| Story range | New stories added | Test types exercised |
|---|---|---|
| US-01 – US-04 | 0 (core browsing/matrix) | selector, view, DRF, E2E |
| US-05 – US-12 | 0 (core card-suit browsing) | selector, view, DRF, E2E |
| US-13 – US-19 | 0 (code samples, search, export, i18n) | selector, view, DRF, Celery (eager mode), E2E |
| US-20 | STRIDE SP/TA cards, Polish + OWASP mapping | fixture, view badge, E2E |
| US-21 | Webapp `VE` cards → A03:2021 samples | fixture, per-language sample, E2E |
| US-22 | Mobile `PC` cards vs Web `CR`/`VE` | matrix selector, E2E |
| US-23 – US-24 | Companion `LLM`/`AAI` cards, Denial-of-Wallet | cross-ref, matrix, Lua sample, E2E |
| US-25 | MLSec `EMR` cards, honest "no OWASP code" labelling | data-integrity test, badge, E2E |
| US-26 | `dbd` harms deck, non-technical framing disclaimer | serializer field, badge, E2E |

**Total new user stories from card-deck extension: 7 (US-20–US-26), covering all 6 YAML files in `docs/OWASP_stories/`.**
