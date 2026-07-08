# SwiftGuard 2026 — Requirements Specification

**Version:** 1.0
**Date:** 2026-07-07
**Project:** `app11_swift_ios`
**Sources:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md`, `docs/OWASP_stories/*.yaml` (all 6 card decks), `PLAN.md`

---

## 1. Scope

SwiftGuard 2026 is a bilingual (PL/EN) security-education **native iOS application** built entirely in **Swift 6** (SwiftUI + SwiftData), with no server backend, no separate database server, and no web frontend. It presents OWASP Web/LLM/Agentic AI/API/Client-Side/CI-CD/Automated-Threats/MASVS content, MITRE ATLAS, CompTIA Security+/SecAI+, and all six OWASP Cornucopia-family card decks under `docs/OWASP_stories/`, each threat/card backed by countermeasure code samples in five languages (Python, Java, Go, Scala, Lua). None of those five sample languages is the application's own implementation language.

**This document, consistent with this series' practice since `app07_rust_react`, states each requirement's enforcement mechanism precisely — compiler, OS-level sandbox, or code review — and is explicit that this app's own threat model is drawn primarily from OWASP MASVS and the Mobile App Cornucopia deck rather than the Web Top 10 every prior sibling centered on.**

---

## 2. Functional Requirements

### FR-01 — Framework Catalog (US-01)
- FR-01.1 The home screen shall list all supported frameworks: OWASP Web Top 10, LLM Top 10, Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, Automated Threats (OAT), MASVS 2.0, MITRE ATLAS, CompTIA Security+/SecAI+, and the six Cornucopia-family card decks.
- FR-01.2 Each tile shall show name, version, description, reference URL, and threat/card count.
- FR-01.3 Tapping a tile shall navigate to that framework's threat/card list.

### FR-02 — Threat & Card Browser (US-02)
- FR-02.1 A unified, filterable, searchable list shall cover all threats and all Cornucopia cards.
- FR-02.2 Filters (combinable): framework/edition, suit, severity, STRIDE category, category, tag, free-text query.
- FR-02.3 Sorting: severity (highest first), framework code, alphabetical.
- FR-02.4 Filtering shall debounce at 300 ms and update results in place via SwiftUI state changes — there is no page-reload concept in a native app, so this requirement's equivalent concern is: filtering shall never block the main thread (all `#Predicate` fetches run via SwiftData's async fetch API).

### FR-03 — Threat / Card Detail Screen (US-03)
- FR-03.1 Each threat/card shall have a detail screen with sections: Overview | Attack Vectors | Mitigations | Code Samples | Cross-References.
- FR-03.2 Every mitigation shall list at least one code sample per language (Python, Java, Go, Scala, Lua), each in Attack Demo and Defense sub-tabs. As in every sibling since `app07_rust_react`, this is verified by a `SwiftCheck` property over the seeded dataset, not a type-level non-empty-collection guarantee.
- FR-03.3 Code samples shall be grouped by language, each with Attack Demo and Defense sub-tabs, rendered with syntax highlighting.
- FR-03.4 Attack-demo code shall require dismissing a `.confirmationDialog` before the code is shown or copyable.

### FR-04 — Cross-Framework Mapping (US-04)
- FR-04.1 A Matrix screen shall map threats across frameworks (at minimum OWASP LLM Top 10 ↔ MITRE ATLAS ↔ CompTIA SecAI+).
- FR-04.2 Matrix cells shall navigate to the corresponding detail screen when tapped.
- FR-04.3 The "Cross-References" detail section shall list relationship type (Equivalent/Related/MapsTo/ParentChild).

### FR-05 — Cornucopia: Frontend Security (FRE) (US-05)
- FR-05.1 A dedicated screen shall display all Cornucopia `FRE` cards from the **Companion Edition v1.0** (`__LLM_AI___companion-cards-1.0-en.yaml`).
- FR-05.2 Cards shall show card ID, value, suit, PL/EN-selectable description, OWASP reference chips.

### FR-06 — Cornucopia: LLM Security (US-06)
- FR-06.1 A dedicated screen shall display all `LLM` suit cards (Companion Edition v1.0).
- FR-06.2 A matrix screen shall map OWASP LLM Top 10 (2025) entries to Cornucopia `LLM` cards, indicating coverage gaps visually.

### FR-07 — Cornucopia: Agentic AI + Cloud (US-07)
- FR-07.1 A dedicated screen shall display all `AAI` suit cards; cards with value `K`/`A` shall show an "AUTONOMY RISK" badge.
- FR-07.2 A matrix screen shall compare OWASP Agentic AI Top 10 (2026) with OWASP LLM Top 10 (2025).
- FR-07.3 `CLD` (Cloud) suit cards shall be displayed on the DevOps screen (FR-11) rather than a separate screen.

### FR-08 — Cornucopia: STRIDE EoP (US-08)
- FR-08.1 A dedicated catalogue screen shall display all 78 STRIDE EoP v5.0 cards, grouped by the 6 STRIDE suits.
- FR-08.2 The STRIDE heatmap screen shall show per-system-component STRIDE coverage; since this app has no server-side authentication concept, access is gated by the device's own local authentication (Face ID/Touch ID/passcode via `LocalAuthentication`) rather than a role check, reflecting the fact that "the user" and "the administrator" are the same person on a personal device.

### FR-09 — Cornucopia: ML Security (MLSec) (US-09)
- FR-09.1 A dedicated screen shall display all 52 MLSec v1.0 cards (EMR/EIR/EOR/EDR).
- FR-09.2 Cards shall show MITRE ATLAS reference chips; adversarial-ML/model-extraction cards shall carry an "ML-SPECIFIC" badge.

### FR-10 — Cornucopia: Mobile App Security (US-10) — this app's own primary threat-model source
- FR-10.1 A dedicated screen shall display all Mobile App Edition v1.1 cards (PC/AA/NS/RS/CRM/CM).
- FR-10.2 A matrix screen shall compare MASVS 2.0 categories with OWASP Web Top 10.
- FR-10.3 Each MASVS category's card list shall include an explicit cross-reference to **this application's own corresponding design decision** (e.g., the `MASVS-STORAGE` cards cross-reference `PLAN.md` D-01's Data Protection discussion; `MASVS-NETWORK` cards cross-reference the ATS-default networking policy) — a requirement with no equivalent in any prior sibling, since none of them are themselves a mobile app subject to MASVS.

### FR-11 — Cornucopia: DevOps + Cloud + BOT Security (US-11)
- FR-11.1 A dedicated screen shall contain a DVO section (CICD-SEC chips), a CLD section (A05:2021/A01:2021 chips), and a BOT section (OAT chips).
- FR-11.2 A `.confirmationDialog` shall appear before any BOT suit card's attack-demo content is shown.
- FR-11.3 DVO and CLD code examples shall be pseudocode only.

### FR-12 — Cornucopia: Website App Security (US-12)
- FR-12.1 A dedicated screen shall display all Cornucopia Website App Edition v3.0 cards (VE, AT, SM, AZ, CR, C), grouped by suit.
- FR-12.2 Cards shall cross-reference the OWASP Web Top 10 entry they correspond to (e.g. `VE3` → `A03:2021`).

### FR-13 — Python Code Samples (US-13)
- FR-13.1 Every mitigation with a code sample shall include a Python tab (Django ORM or FastAPI + Pydantic idioms).

### FR-14 — Java Code Samples (US-14)
- FR-14.1 Every mitigation with a code sample shall include a Java tab (Spring Boot 3.3, Spring Security 6, Spring Data JPA).
- FR-14.2 Java code appears **only** as sample content; it is never part of the application's own build.

### FR-15 — Scala Code Samples (US-15)
- FR-15.1 Every mitigation with a code sample shall include a Scala tab (Akka HTTP/http4s, Slick/Doobie, ZIO 2 idioms).

### FR-16 — Lua Code Samples (US-16)
- FR-16.1 Every mitigation with a code sample shall include a Lua tab (OpenResty/NGINX Lua idioms).

### FR-17 — Global Search & Export (US-17, US-18)
- FR-17.1 A search field shall be present on the main tab bar, querying threat/mitigation/card text via SwiftData predicates.
- FR-17.2 Results shall be grouped by type with the matching term highlighted.
- FR-17.3 Users shall be able to export the filtered threat list as CSV or PDF via `.fileExporter`/`UIActivityViewController`, generated synchronously on-device.
- FR-17.4 No polling or job-status screen is required — export completion is synchronous and immediate, a structural simplification versus every server-based sibling's async export flow.

### FR-18 — i18n: Polish ↔ English
- FR-18.1 The application shall support Polish and English locales only; the app defaults to **Polish** on first launch, independent of the device's system language.
- FR-18.2 A language toggle control shall switch locales instantly, with no app restart, via `LocalizationManager` (`PLAN.md` D-05).
- FR-18.3 The selected locale shall persist across app launches (`UserDefaults`).
- FR-18.4 Threat/card titles, descriptions, and attack-vector text shall be served from the `descriptionPl`/`descriptionEn` fields on the relevant model, switched by `LocalizationManager`.
- FR-18.5 Code samples shall never be translated; in-code comments remain in English.
- FR-18.6 Missing Polish translations shall fall back to English content with a small "EN" badge — never a blank field.
- FR-18.7 All static UI strings shall be present in the String Catalog (`Localizable.xcstrings`) for both `pl` and `en`; a CI script diffing keys used in source against keys present in the catalog shall fail the build on any mismatch.

### FR-19 — Cornucopia: Digital-by-Default Harms (US-19)
- FR-19.1 A dedicated screen shall display all Cornucopia `dbd-cards-1.0-en.yaml` cards, grouped by suit (SCO, ARC, AGE, TRU, POR).
- FR-19.2 Each card shall render with a design-harm badge, never the severity badge used for technical threats. This shall be enforced by the `CardKind` Swift `enum` with associated values (`PLAN.md` D-03: `.technicalThreat(severity:) | .designHarm`) read exclusively through an exhaustive `switch` — Swift's compiler treats an incomplete `switch` over an `enum` with no `default:` case as an **unconditional compile error**, with no project-configuration flag that could disable this check (a stronger, unconditional version of the guarantee `app10_csharp_react`'s FR-19.2 states as configuration-dependent).
- FR-19.3 Each card shall display a cross-reference to OWASP A04:2021 Insecure Design, and, where relevant, to the CompTIA SecAI+ GRC/AI-Act topic list.
- FR-19.4 The screen shall display a disclaimer banner stating that this deck models *service-design harms in public-sector digital services* (source: `digitalbenefits.uk`), not exploitable technical vulnerabilities.
- FR-19.5 Cards shall be filterable by suit and searchable by description keyword, consistent with FR-05–FR-12.
- FR-19.6 Polish translations of all SCO/ARC/AGE/TRU/POR card descriptions shall be reviewed by a native Polish speaker before merge, following the same i18n gate as FR-18.

---

## 3. Security Requirements

### SR-01 — App Sandbox & Entitlements (the platform-level foundation every other requirement in this section builds on)
- SR-01.1 The application's entitlements file shall request **only** `com.apple.developer.icloud-services` (for the optional CloudKit sync, `PLAN.md` D-07) — no camera, location, contacts, background audio, or broad network entitlement is requested.
- SR-01.2 A manual entitlements-file review is a release-blocking checklist item on every version bump (`SDLC_analysis.md` Phase 5).
- SR-01.3 This requirement documents that App Sandbox enforcement is performed by the OS kernel and Apple's code-signing pipeline, independent of this application's own Swift code — the platform-level backstop every other requirement in this section still needs, since sandboxing constrains *reachable capability*, not *application logic correctness*.

### SR-02 — Data Protection (data at rest)
- SR-02.1 The SwiftData store's underlying file uses the default (and, for this app, sufficient) `.completeFileProtectionUntilFirstUserAuthentication` Data Protection class — enforced by iOS, not by application code.
- SR-02.2 The only user-generated data (`Bookmark`) contains no sensitive personal information beyond a reference to which threat/card the user bookmarked.
- SR-02.3 The CloudKit sync token is stored in the Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` — never in `UserDefaults` or the SwiftData store.

### SR-03 — Network Security (App Transport Security)
- SR-03.1 No `NSAppTransportSecurity` exception is present in `Info.plist` — all network traffic (limited to Sign in with Apple and CloudKit, `PLAN.md` D-07) uses the platform's default ATS enforcement (TLS 1.2+, no insecure HTTP).
- SR-03.2 This application makes no network call for its core content at all — every threat, mitigation, and code sample is bundled and verified on-device (SR-06).

### SR-04 — Injection Prevention (structurally different from every server-based sibling)
- SR-04.1 All on-device queries use SwiftData's `#Predicate` macro (`PLAN.md` D-04), which is compiled and type-checked against the `@Model` schema — there is no code path in this application capable of constructing a query from a raw string at all, `NSPredicate(format:)`-based string interpolation included, which a `SwiftLint` custom rule forbids outright.
- SR-04.2 This requirement documents that the SQL-injection question every sibling since `app03_python_django` had to answer with an ORM, a compile-time-checked macro, or a linter rule does not have an attack surface to answer in this application at all — there is no server, no network-reachable query construction, and no string-based query path in the client either.

### SR-05 — XSS-Equivalent / Content Rendering Safety
- SR-05.1 All threat/card text is rendered via SwiftUI's native `Text`, which does not interpret HTML/Markdown by default — there is no `dangerouslySetInnerHTML`-equivalent risk in this application's rendering path.
- SR-05.2 If a future release renders any HTML-bearing content (none currently planned), it shall use a sandboxed `WKWebView` with JavaScript explicitly disabled (`WKWebpagePreferences.allowsContentJavaScript = false`), never `UIWebView` (deprecated, unsandboxed relative to modern `WKWebView`).

### SR-06 — Content Integrity
- SR-06.1 `IntegrityService.verify()` runs from `ContentSeeder` at first launch/app-update and from the periodic `BGAppRefreshTask` handler.
- SR-06.2 On any SHA-256 mismatch against the bundled `hashes.json`, seeding aborts and the app surfaces a user-visible "content integrity error" state rather than silently loading unverified data — there is no "partial write" concern the way a server-side transaction has, since SwiftData writes are local and the check runs before any UI reads the affected data.
- SR-06.3 `hashes.json` is regenerated only by a CI automation step after a reviewed merge to `main`.
- SR-06.4 `IntegrityService.verify()` is declared in the `SwiftGuardData` package and never called from any file in `SwiftGuardUI` (`PLAN.md` D-02); a `SwiftLint` custom rule enforces this by name-based reference detection.
- SR-06.5 This requirement documents the changed threat model versus every server-based sibling (`PLAN.md` §12): because the app bundle is code-signed and sandboxed, the primary value of SR-06.1–SR-06.4 is catching a CI/build mistake and detecting on-device cache corruption, not defending against a runtime attacker modifying files on a mutable server filesystem, which is the scenario every sibling from `app03_python_django` onward primarily defends against with this same class of check.

### SR-07 — Reference ID Allowlists
- SR-07.1 `OwaspRef`, `MitreRef`, `MavsRef`, `CicdSecRef`, `OatRef` values are validated against allowlists loaded from bundled `ref-allowlists.json`/`mitre-atlas-allowlist.json` inside `ContentSeeder`, before being written to a `@Model` instance's `owaspRefs`/`mitreRefs` arrays.
- SR-07.2 Since `CornucopiaCard` has no write path outside `ContentSeeder` (SR-08), there is no runtime admin-CRUD path that could supply an unknown reference ID at all — this validation exists to catch a bad YAML edit before it ships, not to defend a live write endpoint that does not exist.

### SR-08 — Card Write-Path Isolation
- SR-08.1 No method in the `SwiftGuardData` package's public API allows writing a `CornucopiaCard` outside `ContentSeeder`'s initial-seed and re-seed paths — verified by a `SwiftLint` custom rule and code review, and, more fundamentally, by the fact that no UI screen or `ViewModel` in `SwiftGuardUI` exposes any card-editing affordance at all.
- SR-08.2 This is a structurally simpler version of the guarantee every server-based sibling states for its own admin-write-path absence (e.g. `app10_csharp_react`'s "no Minimal API route exists"), here achieved by there being no client-server boundary across which such a route could even be defined.

### SR-09 — YAML/JSON Parsing Safety
- SR-09.1 All six Cornucopia YAML decks are decoded via hand-written `init(from:)` implementations that explicitly enumerate and reject unrecognized keys (`PLAN.md` D-06) — Swift's synthesized `Decodable` conformance does **not** do this by default, the opposite default from `app10_csharp_react`'s `YamlDotNet`.
- SR-09.2 A `SwiftCheck` property test generates YAML documents with random extra keys and asserts decoding throws `CardDecodeError`.
- SR-09.3 This requirement documents the same accepted, hand-maintained gap `app08_cpp_react` and `app09_php_WORDPRESS` each state for their own ecosystems — this app's decoders must be kept in sync with `CornucopiaCard`'s shape by a human, not a compiler or a library default.

### SR-10 — SAST / SCA
- SR-10.1 `SwiftLint` runs on every PR; build fails on any finding at or above the configured severity, including the custom rules in SR-04.1, SR-06.4, and SR-08.1.
- SR-10.2 Xcode's `Analyze` build action (Clang-Static-Analyzer-based) runs in CI on every PR.
- SR-10.3 The project's third-party Swift Package Manager dependencies (`Yams`, `SwiftCheck` — deliberately kept to a minimal count) are manually reviewed against the GitHub Advisory Database quarterly; this requirement documents that no SPM-native tool as mature as `dotnet list package --vulnerable`/`cargo audit` exists as of 2026, an accepted ecosystem-maturity gap rather than a project oversight.
- SR-10.4 Trivy is not applicable (there is no container image to scan) — this requirement is intentionally omitted rather than stated as satisfied by an inapplicable tool.

### SR-11 — Authentication (Sign in with Apple + CloudKit only, no custom auth)
- SR-11.1 The optional bookmark-sync feature uses Sign in with Apple exclusively; this application never sees, stores, or transmits a password.
- SR-11.2 CloudKit's private database scoping (per-iCloud-account, Apple-managed) is relied upon for data isolation between users — this application implements no custom multi-tenancy or authorization logic of its own for sync data.

### SR-12 — Code Sample Safety
- SR-12.1 Attack-demo snippets are bundled, read-only text and are never executed on-device.
- SR-12.2 DVO/CLD code examples are pseudocode only.
- SR-12.3 A `.confirmationDialog` gates any BOT card attack-demo content.

### SR-13 — i18n Security
- SR-13.1 `LocalizationManager`'s `AppLocale` is a closed two-case `enum` (`polish`, `english`) — there is no third value the type can hold, so "an unsupported locale reached business logic" is not a state the rest of the app needs to guard against once the value exists at all.
- SR-13.2 Translation values contain only plain text rendered via `Text` — no interpolation of user input into any localized string format that could change its structure.

---

## 4. Non-Functional Requirements

### NFR-01 — Performance
- NFR-01.1 Screen transitions and filter updates complete in ≤ 100 ms on a mid-tier supported device (iPhone 13 or later).
- NFR-01.2 On-device search returns results in ≤ 200 ms for the full seeded dataset.
- NFR-01.3 Cold launch time (including first-run seeding) is ≤ 2 s on a mid-tier supported device; subsequent launches (seed already present) are ≤ 500 ms.
- NFR-01.4 The compiled app size (excluding on-device generated data) targets ≤ 50 MB — a meaningful, App-Store-relevant figure with no direct equivalent to any server-based sibling's container-image-size target, since there is no container here at all.

### NFR-02 — Usability & Accessibility
- NFR-02.1 Full support for Dynamic Type, VoiceOver, and both light/dark appearance — native SwiftUI accessibility support used as-is, not reimplemented.
- NFR-02.2 All interactive elements meet WCAG 2.1 AA-equivalent contrast ratios (assessed via Xcode's Accessibility Inspector).
- NFR-02.3 Full support for iPad multitasking (Split View, Slide Over) and Mac Catalyst is a stretch goal, not a Phase 1–7 requirement.

### NFR-03 — Maintainability
- NFR-03.1 All seed data lives under `SwiftGuardApp/Resources/` as JSON/YAML, loaded via `ContentSeeder` — never hand-written as Swift object literals mixed into application code.
- NFR-03.2 Every `CodeSample` carries a `versionNote` so maintainers know when to refresh it.
- NFR-03.3 Swift code follows the `SwiftGuardData` (Models/Seeding/Cards/Integrity/Sync/Repositories) and `SwiftGuardUI` (Views/ViewModels/Localization) package boundary in `PLAN.md` §9; Views stay declarative and free of business logic, which lives in ViewModels and Repositories.
- NFR-03.4 Every model type, repository protocol, and `CardKind`-reading function is documented with DocC comments sufficient to generate a browsable API reference for future contributors.

### NFR-04 — Testability (TDD — see `user_stories+tests.md`)
- NFR-04.1 `SwiftGuardData` code coverage ≥ 85% (via Xcode's built-in code coverage reporting).
- NFR-04.2 Every Repository protocol implementation has an `XCTest`-based integration test using an in-memory SwiftData `ModelContainer`.
- NFR-04.3 Every function decoding or validating untrusted bundled input (YAML/JSON) shall have at least one `SwiftCheck` property test in addition to example-based `XCTest` cases.
- NFR-04.4 At least one `XCUITest` end-to-end test per user story (US-01–US-19), driving the real compiled app in the Simulator.
- NFR-04.5 Tests are written **before** implementation for every new feature (Red → Green → Refactor); a PR adding production code without a preceding failing test in the same PR fails review.

### NFR-05 — Portability
- NFR-05.1 The app targets iOS 17.0+ on iPhone and iPad; no server, container, or database installation is required to run it — `git clone` + open in Xcode + Run is the entire "deployment" story for local development.
- NFR-05.2 CI runs on GitHub Actions macOS runners (or Xcode Cloud) using `xcodebuild test`/`xcodebuild archive`.
- NFR-05.3 No external CDN or third-party font/analytics dependency exists — all fonts are system fonts, all assets are bundled.

### NFR-06 — Internationalization Quality
- NFR-06.1 Language switching completes with no perceptible delay and no app restart (`LocalizationManager`, `PLAN.md` D-05).
- NFR-06.2 No hardcoded user-visible string exists in any SwiftUI `View` outside the String Catalog.
- NFR-06.3 Polish strings are reviewed by at least one native Polish-speaking security professional before each App Store submission.

### NFR-07 — Deployment & Distribution
- NFR-07.1 This requirement category, present in every prior sibling's specification as a container-image-size/deployment-footprint target, is replaced here by: (a) the compiled `.ipa` size target (NFR-01.4), and (b) successful passage through Apple's App Review process (`SDLC_analysis.md` Phase 5) — a distribution gate with no equivalent in any web-based sibling's pipeline.

---

## 5. Design Constraints & Technology Mandates

- C-01 The application shall be written entirely in Swift 6, using SwiftUI and SwiftData. No server backend, no separate database server (no PostgreSQL/MySQL/etc.), and no web frontend framework are used anywhere in this application.
- C-02 Code **samples** shown to users (Python, Java, Go, Scala, Lua) are educational content, not part of the application's own runtime; none of these five languages, and no web backend language, is used in the application's own implementation.
- C-03 No third-party analytics, tracking SDK, or externally-hosted font/CDN dependency is used.
- C-04 Every screen displays a disclaimer that content is educational and must be verified against official sources.
- C-05 The application makes no network call for its core content at runtime; all data is seeded locally from bundled resources. The only network calls this app ever makes are Sign in with Apple and CloudKit, both used exclusively for the optional bookmark-sync feature.
- C-06 Every code sample carries a version annotation.
- C-07 Only Polish and English are supported; the String Catalog must be complete for both locales before a new string reaches production.
- C-08 `CornucopiaCard` records (all six decks) are never editable through any UI — no such screen or `ViewModel` method exists anywhere in `SwiftGuardUI`. Content changes only through a reviewed PR to the source YAML plus a hash-allowlist update.
- C-09 The application's entitlements file requests no capability beyond `com.apple.developer.icloud-services` (SR-01.1).
- C-10 No `NSAppTransportSecurity` exception is present in `Info.plist` (SR-03.1).

---

## 6. Data Requirements

### DR-01 — Minimum Seeded Data
- DR-01.1 All 10 OWASP Web Top 10 (2021) entries with mitigations and 5-language code samples.
- DR-01.2 All 10 OWASP LLM Top 10 (2025) entries with mitigations and 5-language code samples.
- DR-01.3 Minimum 15 MITRE ATLAS techniques (≥ 5 tactics): AML.T0000, T0002, T0010, T0051, T0018, T0020, T0019, T0041, T0043, T0015, T0012, T0024, T0025, T0029, T0046.
- DR-01.4 All 10 OWASP Agentic AI Top 10 (2026) entries.
- DR-01.5 Minimum 20 CompTIA SecAI+/Security+ SY0-701 topics, including mobile-specific topics (MASVS, jailbreak/tamper detection, mobile credential storage) given this app's own platform.
- DR-01.6 Full Cornucopia Website App Edition v3.0 cards (VE, AT, SM, AZ, CR, C suits).
- DR-01.7 Full Cornucopia Companion Edition v1.0 cards (LLM, FRE, DVO, BOT, CLD, AAI suits).
- DR-01.8 Full Cornucopia Mobile App Edition v1.1 cards (PC, AA, NS, RS, CRM, CM suits) — this app's own primary threat-model source (FR-10.3).
- DR-01.9 Full Cornucopia STRIDE EoP v5.0 cards (78 cards: SP, TA, RE, ID, DS, EP suits).
- DR-01.10 Full Cornucopia MLSec v1.0 cards (52 cards: EMR, EIR, EOR, EDR suits).
- DR-01.11 Full Digital-by-Default Harms v1.0 cards (SCO, ARC, AGE, TRU, POR, COR, WC suits), each with a reviewed Polish translation and a cross-reference to OWASP A04:2021 Insecure Design.

### DR-02 — YAML/JSON Source-of-Truth
- DR-02.1 Cornucopia cards are maintained as YAML files bundled under `SwiftGuardApp/Resources/Cornucopia/`.
- DR-02.2 `ContentSeeder` loads all six YAML files on first launch and on every subsequent app-version update (detected via a stored "last seeded app version" value in `UserDefaults`).
- DR-02.3 Every `CornucopiaCard` stores `contentSha256`, verified against the bundled `hashes.json` before being marked valid.

### DR-03 — Schema Migrations
- DR-03.1 SwiftData schema changes are managed via `VersionedSchema`/`SchemaMigrationPlan`, ensuring existing users' on-device `Bookmark` data survives an app update even as the rest of the schema is re-seeded from bundled resources.
- DR-03.2 Migrations are forward-only; no destructive migration ships without a corresponding data-loss warning surfaced to the user beforehand if user-generated data (`Bookmark`) would be affected.

---

## 7. Abuse Case Requirements

| ID | Threat | Requirement |
|---|---|---|
| AC-01 | Injection via a search/filter string | Structurally absent — SR-04 documents there is no string-based query-construction path at all in this application |
| AC-02 | Malicious content rendered as HTML/script | SwiftUI `Text` does not interpret HTML by default; any future `WKWebView` use disables JavaScript (SR-05) |
| AC-03 | CSRF | Not applicable — there is no server session or form-submission concept in a native client-only app |
| AC-04 | Sign in with Apple token forgery | Apple's own frameworks perform signature verification; this app never implements its own JWT/token verification logic |
| AC-05 | Bundled resource content tampered in a PR | CODEOWNERS review + `IntegrityService.verify()` SHA-256 check (SR-06) |
| AC-06 | A future contributor loosens `CardFile`'s hand-written decoder to accept unknown keys | `SwiftCheck` property test (SR-09.2) catches the regression; code review is the primary control since there is no compiler backstop for this specific mistake |
| AC-07 | Fake OWASP/MITRE reference injected via a compromised YAML source | `ContentSeeder`'s allowlist validation (SR-07) — but since there is no runtime write path at all (SR-08), this can only occur via a compromised build, not a compromised running app |
| AC-08 | Digital-by-Default Harms deck misread as a CVE-style severity list | `CardKind` `enum` with associated values, read only via an exhaustive `switch` (SR-13-adjacent, `PLAN.md` D-03) — an **unconditional** compiler guarantee, the strongest tier in this series |
| AC-09 | Over-broad entitlement request in a future release | Manual entitlements review, release-blocking (SR-01.2); Apple App Review as an independent second check |
| AC-10 | CloudKit sync token stored insecurely | Keychain-only storage with `ThisDeviceOnly` accessibility (SR-02.3) |
| AC-11 | `IntegrityService` called from `SwiftGuardUI` | `SwiftLint` custom rule + code review (SR-06.4) — weaker than a cross-binary process boundary, the same category of accepted gap `app08_cpp_react`/`app09_php_WORDPRESS` each state for their own weakest-isolation mechanism |
| AC-12 | Jailbroken-device tampering with the app bundle or its data | Out of scope for this app's own guarantees (the same limit App Sandbox itself has, `PLAN.md` D-01) — optionally mitigated by a jailbreak-detection heuristic as a stretch goal, documented as best-effort, not a guarantee |

---

## 8. Traceability Matrix (abbreviated)

| Requirement | User Story | Security Design Decision | Test Coverage |
|---|---|---|---|
| FR-01, FR-02 | US-01, US-02 | D-04 (`#Predicate`) | US-01/US-02 XCUITest |
| FR-05 | US-05 | D-06 | US-05 XCUITest |
| FR-06 | US-06 | D-06 | US-06 XCUITest |
| FR-07 | US-07 | D-06 | US-07 XCUITest |
| FR-08 | US-08 | Local authentication (Face ID/Touch ID) | US-08 XCUITest |
| FR-09 | US-09 | D-06 | US-09 XCUITest |
| FR-10 | US-10 | D-01 (App Sandbox self-reference) | US-10 XCUITest |
| FR-11 | US-11 | — | US-11 XCUITest |
| FR-12 | US-12 | D-06 | US-12 XCUITest |
| FR-17 | US-17, US-18 | Native `.fileExporter`/Share Sheet | US-17/US-18 XCUITest |
| FR-18 | — (cross-cutting i18n) | D-05 | String-Catalog-parity CI script |
| FR-19 | US-19 | D-03 (enum, unconditional exhaustiveness) | US-19 XCUITest, AC-08 |
| SR-04 | — | D-04 | Structural absence, documented not tested |
| SR-06 | — | D-02 | AC-05 integration test |
| SR-07 | — | — | AC-07 integration test |
| SR-09 | — | D-06 | `SwiftCheck`: unknown-field rejection property |
| SR-10 | — | — | CI SAST gates |

---

## 9. Glossary

| Term | Definition |
|---|---|
| App Sandbox | Apple's OS-kernel-enforced process isolation and capability-restriction model for iOS/macOS apps |
| Entitlement | A specific, user-consented capability (e.g., iCloud access) an app must explicitly declare to use |
| SwiftData | Apple's modern, macro-based (`@Model`) persistence framework, built atop an embedded SQLite store |
| `#Predicate` | A Swift macro producing a compile-time-checked, type-safe query predicate for SwiftData |
| `Codable`/`Decodable` | Swift's protocol pair for automatic (or custom) serialization/deserialization; synthesized conformance ignores unrecognized input keys by default |
| String Catalog (`.xcstrings`) | Xcode's modern, structured localization file format, replacing `.strings`/`.stringsdict` |
| Sign in with Apple | Apple's privacy-preserving authentication service; this app never sees a user's password |
| CloudKit | Apple's managed cloud database service, used here only for optional bookmark sync |
| `SwiftCheck` | A property-based testing library for Swift, this ecosystem's equivalent to QuickCheck/`proptest`/`FsCheck`/`eris` |
| `XCUITest` | Apple's native UI-automation testing framework for iOS/macOS apps — this app's equivalent to Playwright |
| MASVS | OWASP Mobile Application Security Verification Standard — this app's own primary self-assessment framework |
| Cornucopia | OWASP's card-game family for threat modeling (Website App, Mobile App, Companion editions) |
| STRIDE | Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege |
| MITRE ATLAS | Adversarial Threat Landscape for AI Systems |
| Digital-by-Default Harms deck | `dbd-cards-1.0-en.yaml` — models service-design harms (exclusion, opaque design) in public-sector digital services; mapped to OWASP A04:2021 Insecure Design, not a technical CVE-style vulnerability |
