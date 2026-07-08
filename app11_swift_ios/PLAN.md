# SwiftGuard 2026 — Application Development Plan

**Version:** 1.0
**Date:** 2026-07-07
**Status:** Living document — updated after each sprint planning session
**Directory:** `app11_swift_ios`
**Sibling projects:** `app01_react`/`app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django), `app04_scala_react` (Scala/ZIO), `app05_go_react` (Go), `app06_HASKELL_react` (Haskell), `app07_rust_react` (Rust), `app08_cpp_react` (C++), `app09_php_WORDPRESS` (PHP/WordPress), `app10_csharp_react` (C#/.NET)

---

## 0. Note on the Stack — the Second, and More Complete, Architectural Departure in This Series

This application is a **native iOS app, written entirely in Swift**, using **SwiftUI** for the interface and **SwiftData** for on-device persistence. It is the tenth backend/platform choice in this course's comparison series, and it departs from every prior sibling more completely than `app09_php_WORDPRESS` did:

- `app09_php_WORDPRESS` kept a client-server model (a browser talking to a PHP backend over HTTP) but replaced the React SPA with server-rendered PHP + vanilla JS.
- **This application has no client-server model at all.** There is no backend web framework, no REST API, no PostgreSQL/MySQL server, and no Docker Compose stack to stand up. The entire application — data storage, business logic, and UI — runs on the user's iPhone/iPad, offline-capable by default. The only network calls this app makes are Apple's own **Sign in with Apple** and **CloudKit** frameworks (§4 D-07), used exclusively for the optional cross-device bookmark sync feature (US-18's equivalent in this app, see §15), and even those are Apple-managed infrastructure this project's own code never has to implement, secure, or operate.

**Why this matters for the course, and why it is the right app to close this series with:** every prior sibling had to build its own answer to "how do I enforce least privilege," using a compiler, a linter, a database constraint, or a code-review checklist. A native iOS app gets a materially different answer for free, at the operating-system level: **Apple's App Sandbox, code-signing, and per-entitlement permission model enforce process isolation and capability restriction independent of anything this project's own Swift code does correctly or incorrectly** — the closest thing in this entire series to a guarantee that holds even against a bug in the application itself, comparable in spirit to `app09_php_WORDPRESS`'s database `CHECK` constraint (D-04 in that project) but broader in scope, since it constrains the whole process, not one table. This plan states that clearly (§4 D-01) rather than treating "it's an iOS app" as making security automatic — sandboxing constrains *what the process can reach*, not *whether the process's own logic is correct*, and this app still needs everything from strict input decoding to exhaustive pattern matching that every prior sibling needed.

**A second, equally important reframing:** this app's own attack surface is best described by **OWASP MASVS** and the **Mobile App Cornucopia deck** (`mobileapp-cards-1.1-en.yaml`, suits PC/AA/NS/RS/CRM/CM) that this app itself teaches — not the OWASP Web Top 10 every prior sibling's own SSDLC section centered on. This is the first app in the series where the educational content and the application's own threat model are, to a significant degree, **the same document** (§11, `SDLC_analysis.md` Phase 0/7).

**Note on code samples:** the application still *teaches* countermeasures in five languages — Python, Java, Go, Scala, and Lua (see §10) — because that is separate, deliberately polyglot **content**, not the application's own runtime. None of those five languages, and no web backend language at all, is used in this application's own implementation; it is Swift only (plus a small amount of Apple's own declarative UI/data DSLs, which are Swift language features, not separate languages).

---

## 1. Project Overview

**Name:** SwiftGuard 2026
**Purpose:** A bilingual (Polish/English) reference and learning app mapping security threats, vulnerabilities and mitigations across **OWASP** (Web Top 10, LLM Top 10, Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, Automated Threats/OAT, MASVS), **MITRE ATLAS**, and **CompTIA Security+ SY0-701 / SecAI+ 2026**, plus the full catalogue of **OWASP Cornucopia-family card decks** found in `docs/OWASP_stories/*.yaml`. Each threat is presented with working countermeasure code in **five languages**: Python, Java, Go, Scala, and Lua.

**Source material:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md` and all six card decks under `docs/OWASP_stories/`:

| File | Edition | Suits |
|---|---|---|
| `webapp-cards-3.0-en.yaml` | OWASP Cornucopia — Website App v3.0 | VE, AT, SM, AZ, CR, C, WC |
| `mobileapp-cards-1.1-en.yaml` | OWASP Cornucopia — Mobile App v1.1 | PC, AA, NS, RS, CRM, CM, WC |
| `__LLM_AI___companion-cards-1.0-en.yaml` | OWASP Cornucopia — Companion (AI/Cloud/DevOps) v1.0 | LLM, CLD, FRE, DVO, BOT, AAI, Common |
| `STRIDE__eop-cards-5.0-en.yaml` | Microsoft "Elevation of Privilege" (STRIDE) v5.0 | SP, TA, RE, ID, DS, EP |
| `RISKS__elevation-of-mlsec-cards-1.0-en.yaml` | "Elevation of MLSec" v1.0 | EMR, EIR, EOR, EDR |
| `dbd-cards-1.0-en.yaml` | Digital-by-Default Harms Deck v1.0 | SCO, ARC, AGE, TRU, POR, COR, WC |

All six decks are in scope from day one of this plan (§11, §15) — the gap the `app04_scala_react` plan initially had (and was later corrected for) is avoided here from the start, as it was for every subsequent sibling. Notably, the **Mobile App deck (PC/AA/NS/RS/CRM/CM)** gets dual billing here: it is both a browsable content deck (US-10) *and* the direct source of this app's own threat model (§11).

**UI languages:** Polish (default) and English, switched instantly with no app restart, via an in-app `LocalizationManager` (§4 D-05) rather than requiring the user to change their iOS system language.

---

## 2. Technology Stack

### Application (100% Swift, no server component)
| Layer | Technology | Version (2026) |
|---|---|---|
| Language | Swift | 6.0 (strict concurrency checking enabled) |
| Minimum OS | iOS | 17.0+ (required for SwiftData and the `Observation` framework) |
| UI framework | SwiftUI | — |
| State management | the `Observation` framework (`@Observable` macro), `@Bindable`, `@Environment` — no third-party state library | — |
| Persistence | **SwiftData** (`@Model` macro over an embedded SQLite store) — no separate database server, no PostgreSQL/MySQL anywhere in this stack | — |
| Querying | SwiftData's `#Predicate` macro — compile-time-checked against the `@Model` type, inherently parameterized (there is no string-based query-construction path in idiomatic SwiftData use at all) | — |
| Networking (optional feature only) | `URLSession` with default App Transport Security (ATS) enforcement — used only by the CloudKit/Sign in with Apple sync feature, never for core content | — |
| Cross-device sync (optional) | **CloudKit** (private database) + **Sign in with Apple** — Apple-managed infrastructure, no custom auth server or custom sync protocol implemented by this project (§4 D-07) | — |
| Local secure storage | **Keychain Services** (via a thin wrapper) for the CloudKit sync token only; all educational content is non-sensitive and stored in the ordinary, sandboxed SwiftData store | — |
| Data-at-rest protection | iOS Data Protection API — the SwiftData store's underlying file is protected under `.completeFileProtectionUntilFirstUserAuthentication` (the default for app data on modern iOS), enforced by the OS, not by this app's code | — |
| YAML/JSON parsing | `Yams` (Swift YAML library) + `Codable`/`JSONDecoder` for bundled resource decoding — **`Codable`'s synthesized `Decodable` conformance silently ignores unrecognized keys by default**, the opposite default from `app10_csharp_react`'s `YamlDotNet`; this project adds an explicit unknown-key check (§4 D-06) rather than relying on a language default that does not exist here | — |
| Background tasks | `BGAppRefreshTask`/`BGProcessingTask` (`BackgroundTasks` framework) — replaces every prior sibling's job-queue library (River/apalis/odd-jobs/Hangfire/WP-Cron) for periodic integrity re-verification; there is no export job queue because exports are generated synchronously on-device and handed to the native Share Sheet | — |
| Export | `UIActivityViewController` / SwiftUI's `.fileExporter` — native iOS share/export, no server-side rendering | — |
| Localization | Xcode 15+ **String Catalogs** (`.xcstrings`) for UI strings; a custom `LocalizationManager` for the in-app (non-system-language) PL/EN toggle (§4 D-05) | — |
| Testing | `XCTest` (unit + integration) + `SwiftCheck` (property-based testing, Swift's QuickCheck/`proptest`/`FsCheck` equivalent) + `XCUITest` (native UI/E2E testing — **replaces Playwright**, since there is no browser to drive) | TDD — see `user_stories+tests.md` |
| SAST | `SwiftLint` (style + some security-adjacent rules) + Xcode's built-in static analyzer (`Product ▸ Analyze`, Clang-Static-Analyzer-based infrastructure shared with the LLVM toolchain) | — |
| SCA | `swift package audit`-style tooling (no single tool as mature as `dotnet list package --vulnerable`/`cargo audit` exists yet for Swift Package Manager as of 2026 — this plan states that gap explicitly, §13) plus manual tracking against the GitHub Advisory Database for the handful of third-party SPM packages this app uses (`Yams`, `SwiftCheck`) | — |

### Infrastructure (there is no server infrastructure — this replaces every sibling's Docker Compose/Nginx/database section)
| Component | Technology |
|---|---|
| Build & CI | Xcode Cloud or GitHub Actions macOS runners (`xcodebuild`/`xcrun xctest`) |
| Distribution | TestFlight (internal/beta) → App Store (production) — **Apple's App Review process is itself an external, independent security gate no other sibling's deployment pipeline has** (§13, `SDLC_analysis.md` Phase 5) |
| Crash/monitoring | Apple's own MetricKit + Xcode Organizer crash reports; no self-hosted Grafana/Loki/Prometheus stack is needed or appropriate for a client-only app |
| Code signing | Apple Developer Program certificate + provisioning profile; App Store Connect API key for CI-driven `xcodebuild` archive/export/upload | — |
| Secrets | No server-side secrets exist. The only credential-adjacent value is the CloudKit container identifier and Sign in with Apple configuration, both stored in the app's entitlements file (not a runtime secret in the traditional sense) | — |

---

## 3. High-Level Architecture

```
┌──────────────────────────── iOS App Sandbox (D-01) ────────────────────────────┐
│                                                                                    │
│  SwiftUI Views  ──observes──►  @Observable ViewModels  ──calls──►  Repositories   │
│  (Threats, Cards, Matrix,       (ThreatBrowserViewModel,           (ThreatRepo,    │
│   StrideHeatmap, DigitalHarms,   CardBrowserViewModel, ...)          CardRepo, ...) │
│   LanguageToggle, ...)                                                    │         │
│                                                                            ▼         │
│                                                              SwiftData ModelContext  │
│                                                              (@Model: Threat, Card,  │
│                                                               Mitigation, CodeSample,│
│                                                               CrossReference,        │
│                                                               ContentHash, ...)      │
│                                                                            │         │
│                                                                            ▼         │
│                                                        Embedded SQLite store, under   │
│                                                        iOS Data Protection (OS-level) │
│                                                                                        │
│  ContentSeeder (first launch / app-update)  ──decodes──►  Bundled JSON/YAML resources  │
│  IntegrityService.verify()  ◄──BGAppRefreshTask (periodic)──                          │
│                                                                                        │
│  (Optional) SyncCoordinator ──uses──► Sign in with Apple + CloudKit private database   │
│             (the ONLY network-reachable code path in this entire application)         │
└──────────────────────────────────────────────────────────────────────────────────────┘
```

**Where the trust boundaries are, restated for a platform with no server process at all:** every prior sibling's "Trust Boundary 1" was the browser-to-backend HTTP boundary. Here, that boundary does not exist — the "server" and the "client" are the same sandboxed process. The trust boundaries that *do* exist are: (1) the iOS App Sandbox boundary between this app's process and every other process on the device, enforced by the kernel and code-signing, independent of this app's own code (D-01); (2) the boundary between `ContentSeeder`/`IntegrityService` (the only code paths permitted to write seed/verified content) and the `ViewModels`/`Repositories` that read it, enforced by Swift access control (`internal`/`private` — §4 D-02) the same way every sibling since `app05_go_react` enforces this with its own language's visibility tools; and (3) the boundary around the optional CloudKit sync path, which is the only place this app's data ever leaves the device at all.

---

## 4. Architecture Design Decisions

### D-01 — App Sandbox, code signing, and per-entitlement permissions: the strongest, most OS-enforced guarantee in the entire series
Every iOS app runs inside Apple's App Sandbox: a kernel-enforced container restricting filesystem access to the app's own container directory, restricting inter-process communication, and requiring an explicit, user-consented **entitlement** for any sensitive capability (network access, camera, location, iCloud). This app requests the absolute minimum entitlement set: `com.apple.developer.icloud-services` (for the optional CloudKit sync) and nothing else — no camera, no location, no contacts, no background audio, no arbitrary network access beyond what CloudKit/Sign-in-with-Apple's own frameworks require. **This is enforced by the operating system kernel and Apple's code-signing/notarization pipeline, independent of whether this app's own Swift code has a bug** — the closest analogue in this series to `app09_php_WORDPRESS`'s database-level `CHECK` constraint (D-04 in that project), but broader in scope: it constrains the entire process's reachable capabilities, not one data invariant. The honest limit, stated the same way this series has stated every other platform-level guarantee's limit: sandboxing does not make this app's *own logic* correct, and a jailbroken device or an OS-level vulnerability can, in principle, weaken these guarantees — this app's own SSDLC (`SDLC_analysis.md`) still needs everything from strict decoding to exhaustive pattern matching regardless.

### D-02 — Swift access control (`internal`/`private`/`fileprivate`) as the least-privilege enforcement mechanism for `IntegrityService`
```swift
// IntegrityService.swift
struct IntegrityService {
    private init() {}
    static func verify(fileName: String, expectedSha256: String, data: Data) -> ContentHash { /* ... */ }
}
```
`IntegrityService.verify` is called only from `ContentSeeder` (first launch / app-update path) and from the `BGAppRefreshTask` handler — never from a `ViewModel`. Because this entire application is a single compiled binary with no separate assemblies/packages the way `app05_go_react`'s `internal/` or `app07_rust_react`'s module visibility provide a *cross-boundary* guarantee, this project additionally organizes `IntegrityService`, `ContentSeeder`, and the background-task handler into their own Swift Package Manager **local package target** (`SwiftGuardData`), separate from the `SwiftGuardUI` target that contains all `ViewModel`/`View` code — giving Swift's real `internal` access-control keyword actual cross-target teeth, the same pattern every sibling since `app05_go_react` uses in its own language's idiom. A `SwiftLint` custom rule additionally flags any `import SwiftGuardData` inside a file under `SwiftGuardUI/ViewModels/` that references `IntegrityService` by name.

### D-03 — Swift `enum` with associated values + exhaustive `switch` — an unconditional compile-time guarantee, the strongest tier in this series alongside Rust and Haskell
```swift
enum CardKind {
    case technicalThreat(severity: Severity)
    case designHarm
}

func severity(of kind: CardKind) -> Severity? {
    switch kind {
    case .technicalThreat(let severity): return severity
    case .designHarm: return nil
    // no `default:` — Swift requires every case to be handled; omitting one is an
    // unconditional COMPILE ERROR, not a warning that can be configured away
    }
}
```
Unlike `app10_csharp_react`'s `CS8509` (a warning promoted to an error by project configuration that could be silently reverted), Swift's `switch`-exhaustiveness-over-an-`enum` check is a **hard compiler error with no configuration flag that disables it** — the same unconditional tier as Rust's `match` and Haskell's `case`. This is this project's strongest type-level security guarantee, and it required no special project setup to obtain, unlike C#'s equivalent.

### D-04 — SwiftData's `#Predicate` macro: compile-time-checked, inherently parameterized queries — no SQL string ever exists in this codebase
```swift
let severity = Severity.critical
let predicate = #Predicate<Threat> { $0.severity == severity && $0.frameworkCode == "OWASP_LLM" }
let threats = try modelContext.fetch(FetchDescriptor(predicate: predicate))
```
`#Predicate` is a Swift macro, expanded and type-checked by the compiler at build time against the `@Model` type's actual properties — a query that references a renamed or removed property fails to *compile*, not merely to run. There is no SQL string anywhere in this codebase for this project's own queries (SwiftData generates and parameterizes the underlying SQLite access itself); the SQL-injection question every prior sibling had to answer with an ORM, a macro, or a linter rule simply does not have an attack surface to answer here, because there is no code path capable of constructing a query from untrusted string input at all.

### D-05 — An in-app `LocalizationManager`, not just system-locale-following localization
```swift
@Observable
final class LocalizationManager {
    private(set) var currentLocale: AppLocale = .polish
    func setLocale(_ locale: AppLocale) {
        currentLocale = locale
        Bundle.setLanguage(locale.bundleIdentifier) // swaps the active .lproj-equivalent bundle at runtime
    }
}
```
Ordinary iOS localization follows the device's system language automatically via String Catalogs — sufficient for most apps, but not for this brief's explicit requirement that the *user* can switch languages inside the app, independent of their device's system setting. `LocalizationManager` implements the well-established `Bundle`-swizzling technique to swap the effective language at runtime with no app restart, backed by the same String Catalog (`.xcstrings`) infrastructure every other string in the app already uses — this is a deliberate enhancement layered on top of the platform's own mature i18n system, not a replacement for it, in the same spirit as `app09_php_WORDPRESS`'s decision to reuse WordPress's own i18n mechanism rather than build a bespoke one.

### D-06 — A hand-written unknown-key check, because `Codable` does not provide one by default — the honest, opposite-default counterpart to `app10_csharp_react`'s `YamlDotNet`
```swift
struct CardFile: Decodable {
    let meta: Meta
    let suits: [Suit]

    private enum CodingKeys: String, CodingKey { case meta, suits }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKey.self)
        let recognized: Set<String> = ["meta", "suits"]
        let unrecognized = Set(container.allKeys.map(\.stringValue)).subtracting(recognized)
        guard unrecognized.isEmpty else {
            throw CardDecodeError.unrecognizedFields(unrecognized)
        }
        // ... decode meta/suits normally via a second, typed container ...
    }
}
```
Swift's synthesized `Decodable` conformance (the "free" `Codable` derivation every tutorial shows) **silently ignores JSON/YAML keys it doesn't recognize** — the opposite default from `app10_csharp_react`'s `YamlDotNet`, which rejects unrecognized keys unless explicitly loosened. This project's `CardFile` (and every other type decoding the six Cornucopia YAML decks) uses a hand-written `init(from:)` with a `DynamicKey`-based container specifically to recover the same "reject unrecognized fields" guarantee `app05_go_react`/`app06_HASKELL_react`/`app07_rust_react` get from a one-line derive attribute and `app10_csharp_react` gets from a library default — the same accepted, hand-maintained gap `app08_cpp_react` and `app09_php_WORDPRESS` each state for their own ecosystems, backed by a `SwiftCheck` property test (§ `user_stories+tests.md`).

### D-07 — Sign in with Apple + CloudKit for the one optional feature that needs a network at all
Bookmark/favorite sync across a user's devices uses **Sign in with Apple** (no password this app ever sees or stores) and **CloudKit**'s private database (Apple's own managed, end-to-end-authenticated sync infrastructure, scoped per-user by Apple's own account system). This project implements no custom authentication server, no custom sync protocol, and no custom token storage beyond what `AuthenticationServices`/`CloudKit` already manage — the same "reuse the platform's mature, battle-tested mechanism instead of building a bespoke one" decision `app09_php_WORDPRESS` made with WordPress's nonce/capability system, made here with Apple's own frameworks.

### D-08 — Attack-demo code samples ship read-only, bundled, never executed
Every code sample (all five languages) is bundled, read-only content, rendered as syntax-highlighted text. There is no code-execution feature anywhere in this app, and the `AttackDemoWarning` confirmation sheet (SwiftUI `.confirmationDialog`) gates *viewing/copying* the content, the same UX pattern every sibling uses, adapted to a native modal presentation.

---

## 5. Data Model (SwiftData `@Model` types)

### 5.1 Core enums and the `CardKind` type (see D-03 for the full guarantee)
```swift
enum Severity: String, Codable { case critical, high, medium, low, info }
enum StrideCategory: String, Codable { case s, t, r, i, d, e }
enum SampleType: String, Codable { case attackDemo, defense }
enum CodeLanguage: String, Codable { case python, java, go, scala, lua }
enum MitigationType: String, Codable { case preventive, detective, corrective, compensating }
enum Effort: String, Codable { case low, medium, high }
enum Effectiveness: String, Codable { case partial, significant, full }
enum RelationshipType: String, Codable { case equivalent, related, parentChild, mapsTo }

enum CardKind: Codable, Equatable {
    case technicalThreat(severity: Severity)
    case designHarm
}
```

### 5.2 Framework
```swift
@Model
final class Framework {
    @Attribute(.unique) var code: String   // "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS", ...
    var name: String
    var version: String
    var description: String
    var referenceUrl: String
    @Relationship(deleteRule: .cascade) var threats: [Threat] = []
}
```

### 5.3 Threat
```swift
@Model
final class Threat {
    @Attribute(.unique) var code: String        // "LLM01:2025", "A03:2021", "AML.T0051"
    var title: String
    var severity: Severity
    var category: String
    var descriptionEn: String
    var descriptionPl: String                    // i18n content lives on the model directly —
                                                    // no separate translation table is needed since
                                                    // there is no multi-tenant/multi-row-per-locale
                                                    // concern on a single-device local store
    var attackVector: String
    var attackSurface: String
    var stride: [StrideCategory]
    var tags: [String]
    @Relationship(deleteRule: .cascade) var mitigations: [Mitigation] = []
}
```

### 5.4 CornucopiaCard *(all six YAML decks — see D-03 for `CardKind`)*
```swift
@Model
final class CornucopiaCard {
    @Attribute(.unique) var cardId: String       // "VE3", "LLM4", "SCO2"
    var suitCode: String
    var suitName: String
    var edition: String                           // webapp, mobileapp, companion, eop, mlsec, dbd
    var value: String                              // "2".."10","J","Q","K","A"
    var kind: CardKind                              // D-03: technicalThreat(severity) | designHarm
    var descriptionEn: String
    var descriptionPl: String
    var miscNote: String?
    var sourceUrl: String?
    var owaspRefs: [String]
    var mitreRefs: [String]
    var contentSha256: String
    @Relationship(deleteRule: .cascade) var mitigations: [Mitigation] = []
}
```

### 5.5 Mitigation
```swift
@Model
final class Mitigation {
    var title: String
    var descriptionText: String
    var mitigationType: MitigationType
    var effort: Effort
    var effectiveness: Effectiveness
    @Relationship(deleteRule: .cascade) var codeSamples: [CodeSample] = []
    // non-emptiness of codeSamples verified by a SwiftCheck property over seed data,
    // not the type itself — [CodeSample] has no non-empty variant, the same accepted
    // gap every sibling without a dedicated NonEmpty type states
}
```

### 5.6 CodeSample
```swift
@Model
final class CodeSample {
    var language: CodeLanguage
    var sampleType: SampleType
    var title: String
    var descriptionText: String
    var code: String
    var frameworkHint: String   // "SwiftData #Predicate", "Spring Boot 3.3", "Django ORM"...
    var versionNote: String
}
```

### 5.7 CrossReference
```swift
@Model
final class CrossReference {
    var sourceThreatCode: String
    var targetThreatCode: String
    var relationshipType: RelationshipType
    var descriptionText: String
}
```

### 5.8 ContentHash
```swift
@Model
final class ContentHash {
    @Attribute(.unique) var fileName: String
    var sha256Hash: String
    var verifiedAt: Date
    var isValid: Bool
    var verifiedBy: String = "swiftguard-integrity-service"
}
```

### 5.9 Bookmark *(the only user-generated, sync-eligible data)*
```swift
@Model
final class Bookmark {
    var threatOrCardCode: String
    var createdAt: Date
    var cloudKitRecordName: String?   // set only if CloudKit sync (D-07) is enabled
}
```

---

## 6. Development Phases

*(Numbering aligned with the Agile/Scrum sprint plan in `SDLC_analysis.md`, §4.)*

### Phase 1 — Foundation (Sprints 1–2)
Covers: US-01, US-02
- [ ] Xcode project with two local Swift packages: `SwiftGuardData` (models, `ContentSeeder`, `IntegrityService`) and `SwiftGuardUI` (Views, ViewModels) — the boundary from D-02
- [ ] Swift 6 strict concurrency mode enabled project-wide
- [ ] SwiftData schema for models in §5.1–5.9
- [ ] `ContentSeeder` — decodes bundled JSON for OWASP Web/LLM/Agentic/API, MITRE ATLAS, CompTIA SecAI+ into SwiftData on first launch
- [ ] `FrameworkListView` + `FrameworkListViewModel` — the home screen
- [ ] `LocalizationManager` (D-05) + String Catalog scaffolding for `pl`/`en`
- [ ] `SwiftLint` + Xcode `Analyze` wired into CI (not yet blocking)

**Security checkpoint:** App Sandbox entitlements file contains no capability beyond what Phase 6's CloudKit feature will need (i.e., nothing yet); `SwiftLint` custom rule confirms `SwiftGuardUI` does not import `IntegrityService` by name.

### Phase 2 — Core Threat Browser (Sprints 3–4)
Covers: US-02, US-03, US-04
- [ ] `#Predicate`-based filtering: framework, severity, stride, category, tag, q
- [ ] `ThreatDetailView` — tabs: Overview | Attack Vectors | Mitigations | Code | Cross-References
- [ ] `ThreatBrowserViewModel` with debounced search text binding
- [ ] `MatrixView` — cross-framework mapping table

**Security checkpoint:** confirmed, by code review, that no `NSPredicate(format:)` string-interpolation path exists anywhere (the one way a SwiftData query *could* reintroduce a string-construction risk if `#Predicate` were bypassed) — a `SwiftLint` custom rule additionally flags any use of `NSPredicate(format:)` in the codebase.

### Phase 3 — Card Decks & Content Integrity (Sprints 5–7)
Covers: US-05–US-12, US-19
- [ ] `CardFile` decoders (D-06) for **all six** `docs/OWASP_stories/*.yaml` files, bundled as app resources
- [ ] `IntegrityService.verify()` — SHA-256 vs bundled `hashes.json`; called only from `ContentSeeder` and the `BGAppRefreshTask` handler (D-02)
- [ ] Card suit browser views: FRE, LLM, AAI, CLD (Companion), SP/TA/RE/ID/DS/EP (STRIDE), EMR/EIR/EOR/EDR (MLSec), PC/AA/NS/RS/CRM/CM (Mobile — **this app's own threat-model source**, §11), VE/AT/SM/AZ/CR/C (Website App), **SCO/ARC/AGE/TRU/POR (Digital-by-Default Harms, US-19 — in scope here, not bolted on later)**
- [ ] `AttackDemoWarningSheet` (`.confirmationDialog`) before revealing `attackDemo` code samples

**Security checkpoint:** malformed/unknown-field YAML throws `CardDecodeError` (a `SwiftCheck` property generates random extra keys and asserts the throw); content hash mismatch aborts seeding and surfaces a user-visible "content integrity error" state rather than silently loading unverified data.

### Phase 4 — Code Samples: 5 Languages (Sprints 7–9)
Covers: US-13–US-16
- [ ] Code sample seed data for every mitigation × 5 languages (Python, Java, Go, Scala, Lua)
- [ ] `CodeSamplePanelView` — per-language tabs, Attack Demo / Defense sub-tabs, syntax highlighting (a Swift-native highlighter or a bundled Highlight.js running in a sandboxed `WKWebView` with JavaScript otherwise disabled — evaluated for footprint, §13)
- [ ] MITRE ATLAS Kill-Chain timeline (native SwiftUI `Canvas`/`Chart` — no third-party charting library)

### Phase 5 — i18n Polish ↔ English (Sprint 9–10)
Covers: US-11 (folded into every story's acceptance criteria, see §15 note)
- [ ] Full String Catalog coverage for every UI string
- [ ] `LanguageToggleView` driving `LocalizationManager` (D-05)
- [ ] Card/threat content's `descriptionPl`/`descriptionEn` fields switched by the same `LocalizationManager` state
- [ ] Code samples **never** translated
- [ ] CI check: a script diffing String Catalog keys used in Views against keys present in the `.xcstrings` file fails the build on any mismatch (this project's equivalent of every sibling's i18n key-parity check)

### Phase 6 — Search, Export, Matrix Completion, Optional Sync (Sprints 10–12)
Covers: US-17, US-18
- [ ] `#Predicate`-based full-text-ish search (SwiftData supports basic string predicates; a lightweight on-device tokenized index is added if search relevance needs improve beyond `CONTAINS`)
- [ ] `.fileExporter`/`UIActivityViewController`-based CSV/PDF export, generated synchronously on-device (no job queue needed at this data scale)
- [ ] `MatrixLlmView`, `MatrixAgenticView`, `MatrixMobileVsWebView`, `StrideHeatmapView`, `MatrixDigitalHarmsView`
- [ ] (Optional feature) Sign in with Apple + CloudKit sync for `Bookmark` (D-07) — the `com.apple.developer.icloud-services` entitlement is added to the sandbox profile at this point, and only at this point

### Phase 7 — Hardening, Testing & Release (Sprints 12–14)
Covers: full regression across US-01–US-19
- [ ] `XCTest` + `SwiftCheck` properties, coverage ≥ 85% on `SwiftGuardData`
- [ ] `XCUITest` suite — one scenario per user story, driving the real app UI (replaces every sibling's Playwright suite)
- [ ] `SwiftLint` + Xcode `Analyze` in CI, zero HIGH findings
- [ ] Manual review of the entitlements file confirming no capability beyond CloudKit is requested
- [ ] TestFlight beta distribution → Apple App Review submission → App Store release

---

## 7. Repository / Data-Access Layer Map

*(This section replaces every sibling's "API Endpoint Map" — there is no HTTP surface in this application at all.)*

```swift
protocol FrameworkRepository {
    func list() throws -> [Framework]
    func detail(code: String) throws -> Framework?
}

protocol ThreatRepository {
    func list(filter: ThreatFilter) throws -> [Threat]
    func detail(code: String) throws -> Threat?
    func crossReferences(sourceCode: String) throws -> [CrossReference]
}

protocol CardRepository {
    func bySuit(_ suitCode: String) throws -> [CornucopiaCard]
    func byCardId(_ cardId: String) throws -> CornucopiaCard?
    func suits(forEdition edition: String) throws -> [String]
    // Digital-by-Default Harms (US-19): callers use `card.kind` via the exhaustive switch
    // in D-03 — there is no separate "severity" accessor that could accidentally be called
    // on a design-harm card, because Severity is only reachable through that switch at all.
}

protocol MatrixRepository {
    func llmMatrix() throws -> Matrix
    func agenticMatrix() throws -> Matrix
    func mobileVsWebMatrix() throws -> Matrix
    func strideHeatmap() throws -> StrideHeatmap
}

protocol SearchRepository {
    func query(_ text: String, locale: AppLocale) throws -> [SearchResult]
}

protocol ExportService {
    func exportCsv(filter: ThreatFilter) throws -> URL   // synchronous, on-device, no job queue
    func exportPdf(threatCode: String) throws -> URL
}

protocol BookmarkRepository {
    func add(code: String) throws
    func remove(code: String) throws
    func list() throws -> [Bookmark]
    // (Optional) sync via SyncCoordinator, which is the ONLY type in this app that imports CloudKit
}
```

There is no `CornucopiaCard` write method anywhere in this protocol surface, and no implementation exists in `SwiftGuardData` either (the C-08-equivalent constraint every sibling since `app05_go_react` states) — cards are written only by `ContentSeeder` and the periodic re-seed path, both internal to the `SwiftGuardData` package.

---

## 8. SwiftUI View & Feature Structure

```
Views (SwiftGuardUI):
  RootView                        → TabView: Frameworks | Threats | Search | Bookmarks | About
  FrameworkListView / FrameworkDetailView
  ThreatBrowserView / ThreatDetailView (tabs: Overview | Attack Vectors | Mitigations | Code | Cross-Refs)
  CardSuitView(edition:)           → generic, parameterized by edition/suit — used for:
    - Website App suits (US-12)       - FRE (US-05)
    - LLM (US-06) + LlmMatrixView      - AAI + CLD (US-07)
    - STRIDE catalogue (US-08) + StrideHeatmapView
    - MLSec (US-09)                    - Mobile (US-10) + MobileVsWebMatrixView
    - DevOps: DVO + BOT (US-11)
  DigitalHarmsView (US-19)          → DesignHarmBadge (its Swift type has no severity case to read)
  CodeSamplePanelView               → per-language tabs, AttackDemoWarningSheet
  SearchResultsView
  LanguageToggleView (D-05)
  BotWarningSheet (US-11)
  AboutView
```

---

## 9. Swift Package/Project Layout

```
app11_swift_ios/
├── SwiftGuard.xcodeproj
├── SwiftGuardData/                       ← local Swift package
│   ├── Package.swift
│   └── Sources/SwiftGuardData/
│       ├── Models/
│       │   ├── Enums.swift               ← Section 5 enums
│       │   └── CardKind.swift            ← D-03
│       ├── Seeding/
│       │   └── ContentSeeder.swift
│       ├── Cards/
│       │   └── CardFileDecoders.swift    ← D-06, one decoder per YAML shape
│       ├── Integrity/
│       │   └── IntegrityService.swift    ← isolated per D-02
│       ├── Sync/
│       │   └── SyncCoordinator.swift     ← the only file importing CloudKit (D-07)
│       └── Repositories/                  ← §7 protocol implementations
├── SwiftGuardUI/                          ← local Swift package
│   └── Sources/SwiftGuardUI/
│       ├── Views/                          ← §8
│       ├── ViewModels/                      ← @Observable classes
│       └── Localization/
│           └── LocalizationManager.swift   ← D-05
├── SwiftGuardApp/                          ← the actual .app target, thin composition root
│   ├── SwiftGuardApp.swift                 ← @main App struct
│   └── Resources/
│       ├── owasp_web_top10.json
│       ├── owasp_llm_top10.json
│       ├── owasp_agentic_top10.json
│       ├── mitre_atlas.json
│       ├── comptia_secai.json
│       ├── Cornucopia/
│       │   ├── webapp-cards-3.0-en.yaml
│       │   ├── companion-llm-cards-1.0-en.yaml
│       │   ├── mobileapp-cards-1.1-en.yaml
│       │   ├── stride-eop-cards-5.0-en.yaml
│       │   ├── mlsec-cards-1.0-en.yaml
│       │   ├── dbd-cards-1.0-en.yaml     ← Digital-by-Default Harms (US-19)
│       │   └── Translations/pl.cards.json
│       ├── hashes.json
│       ├── mitre-atlas-allowlist.json
│       ├── ref-allowlists.json
│       ├── CodeSamples/{python,java,go,scala,lua}/
│       └── Localizable.xcstrings          ← PL/EN String Catalog
├── SwiftGuardTests/                        ← XCTest + SwiftCheck (unit/property, on SwiftGuardData)
└── SwiftGuardUITests/                      ← XCUITest, one file per user story (us01..us19)
```

---

## 10. Code Sample Strategy

Every `Mitigation` ships exactly **five** `CodeSample` records. As in every sibling since `app07_rust_react`, completeness is verified by a `SwiftCheck` property over the seeded dataset, not a type-level guarantee — `[CodeSample]` has no non-empty variant in the Swift standard library.

| Language | Primary framework/library used in samples |
|---|---|
| Python | Django ORM / FastAPI + Pydantic |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | `chi` + `sqlc` + `pgx` |
| Scala | Akka HTTP / http4s, Slick 3.x, ZIO 2 |
| Lua | OpenResty / NGINX Lua, `lua-resty-jwt`, LuaSQL |

```
sampleType: attackDemo   // VULNERABLE — do not use in production
sampleType: defense      // SECURE pattern, with a one-line WHY comment
```

**A note on why "Swift" is not a sixth sample language:** the brief specifies five sample languages (Python, Java, Go, Scala, Lua) as content, deliberately distinct from the app's own implementation language — the same rule every sibling has followed. Threats for which a *mobile-specific* Swift/iOS countermeasure would be pedagogically valuable (e.g., Keychain usage, ATS configuration) are instead covered directly in this app's own `SDLC_analysis.md` and in the Mobile Cornucopia deck's card detail pages (US-10) as *this app's own worked example*, rather than as a sixth formal code-sample language.

---

## 11. Security Data Coverage Plan

| Framework | Coverage target | Source |
|---|---|---|
| OWASP Web Top 10 (2021) | A01–A10, all 10 | seeded JSON, cross-refs to `VE/AT/SM/AZ/CR/C` cards |
| OWASP LLM Top 10 (2025) | LLM01–LLM10, all 10 | seeded JSON + `LLM` suit (Companion) |
| OWASP Agentic AI Top 10 (2026) | AgentAI01–10 | seeded JSON + `AAI` suit (Companion) |
| OWASP API Security Top 10 | API1–API10 | seeded JSON |
| OWASP Client-Side Top 10 | C01–C10 | `FRE` suit (Companion) |
| OWASP CI/CD Security Top 10 | CICD-SEC-01–10 | `DVO` suit (Companion) |
| OWASP Automated Threats (OAT) | ≥ 13 of 21 | `BOT` suit (Companion) |
| Cloud misconfiguration (A05/A01:2021) | — | `CLD` suit (Companion) |
| **OWASP MASVS 2.0 — this app's own primary threat model, not just browsable content** | all 7 categories | `PC/AA/NS/RS/CRM/CM` suits (Mobile) — cross-referenced directly against SwiftGuard's own App Sandbox (D-01), Data Protection (D-01), and CloudKit (D-07) design decisions in `SDLC_analysis.md` Phase 0/2 |
| STRIDE | S,T,R,I,D,E — all 6 | `SP/TA/RE/ID/DS/EP` suits (EoP v5.0) |
| Elevation of MLSec | Model/Input/Output/Dataset Risk | `EMR/EIR/EOR/EDR` suits |
| MITRE ATLAS | ≥ 15 techniques across ≥ 5 tactics | seeded JSON, cross-referenced from LLM/AAI/mlsec cards |
| CompTIA Security+ / SecAI+ | ≥ 20 topics | seeded JSON, from `docs/Security Architects...md` mapping table |
| OWASP A04:2021 Insecure Design — Digital-by-Default Harms | Scope/Architecture/Agency/Trust/Porosity | `SCO/ARC/AGE/TRU/POR` suits (US-19) — **not** a technical-vulnerability deck, see D-03 |

---

## 12. Cornucopia Content Pipeline

```
SwiftGuardApp/Resources/Cornucopia/
├── webapp-cards-3.0-en.yaml
├── companion-llm-cards-1.0-en.yaml
├── mobileapp-cards-1.1-en.yaml
├── stride-eop-cards-5.0-en.yaml
├── mlsec-cards-1.0-en.yaml
├── dbd-cards-1.0-en.yaml            ← Digital-by-Default Harms (US-19)
└── Translations/pl.cards.json

Resources/hashes.json                 ← SHA-256 per YAML file
Resources/mitre-atlas-allowlist.json
Resources/ref-allowlists.json
```

**Workflow:**
1. PR touching `Resources/Cornucopia/*.yaml` → CODEOWNERS `@security-team`, min. 2 approvals.
2. CI job `yaml-content-integrity`: the hand-written `CardFile` decoders (D-06) must succeed against every file (any unrecognized shape throws `CardDecodeError`) + injection-pattern grep + ref-allowlist validation.
3. Post-merge: a `hash-generator` CI step updates `Resources/hashes.json`.
4. `ContentSeeder` and the `BGAppRefreshTask` handler both call `IntegrityService.verify()` on app launch/refresh — **note the changed threat model versus every server-based sibling**: because the app bundle is code-signed by Apple and the sandbox prevents another process from modifying it post-install, this check's primary value shifts from "detect a malicious runtime tamperer" (the primary concern for `app03_python_django` through `app10_csharp_react`, all of which serve content over a network from a mutable server filesystem) to "catch a bad build/CI mistake before it ships" and "detect corruption of the on-device SwiftData cache" — `SDLC_analysis.md` Phase 7 discusses this reframing in full.

---

## 13. Risk Register

| Risk | Mitigation |
|---|---|
| Codable's default lenient decoding silently accepts a malformed/injected YAML shape | Hand-written `init(from:)` unknown-key rejection (D-06) + `SwiftCheck` property test |
| Digital-by-Default Harms deck misread as CVE severity | `CardKind` enum with associated values (D-03) — the strongest, unconditional guarantee in this series, tied with Rust/Haskell |
| `IntegrityService` called from an unintended location | Two-Swift-package boundary (`SwiftGuardData`/`SwiftGuardUI`) + `SwiftLint` custom rule (D-02) — weaker than a full compiled-binary process boundary but stronger than a same-binary convention |
| Immature Swift Package Manager SCA tooling (no `cargo audit`/`dotnet list package --vulnerable` equivalent as of 2026) | Manual quarterly review of the small (2–3 package) dependency list against the GitHub Advisory Database; dependency count kept deliberately minimal specifically to make manual review tractable |
| Over-broad entitlement request slipping into a future release (e.g., an unrelated feature accidentally requesting camera access) | Manual entitlements-file review as a release-blocking checklist item (Phase 7); App Review itself is a second, external check on this exact risk |
| CloudKit sync token exposure | Stored in Keychain (`kSecAttrAccessibleWhenUnlockedThisDeviceOnly`), never in `UserDefaults` or SwiftData |
| Attack-demo code confused with production-safe code | Red-styled badge + `.confirmationDialog` before code is shown/copied |
| Bundled resource JSON/YAML tampered in a PR | CODEOWNERS review + `IntegrityService.verify()` SHA-256 check |

---

## 14. Directory Layout

```
app11_swift_ios/
├── PLAN.md
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
└── (Xcode project — see §9 for full internal layout)
```

---

## 15. User Stories — Complete List

*(Full acceptance criteria and TDD test plans in `user_stories+tests.md`. All six YAML decks — including Digital-by-Default Harms — are covered from the start of this plan.)*

| ID | Role | Need | Goal |
|---|---|---|---|
| US-01 | security engineer | browse security framework catalogue | single access point to all standards |
| US-02 | security engineer | filter threats by framework, severity, STRIDE, tag, q | quickly find threats relevant to my project |
| US-03 | security engineer | see threat details with mitigations and code samples | understand how to implement protection |
| US-04 | CompTIA SecAI+ student | see how LLM01 Prompt Injection maps to MITRE ATLAS AML.T0051 | understand cross-framework dependencies |
| US-05 | mobile/frontend developer | browse Cornucopia FRE cards (Companion) | map client-side attack scenarios to mitigations |
| US-06 | ML engineer / AI architect | explore OWASP LLM Top 10 via Cornucopia LLM cards with interactive matrix | understand prompt injection, poisoning, excessive agency |
| US-07 | agentic AI / cloud developer | study AAI + CLD cards | design human-in-the-loop safeguards; spot IAM/storage misconfiguration |
| US-08 | security architect / threat modeler | use STRIDE EoP catalogue with interactive heatmap | run structured threat modeling session |
| US-09 | data scientist / ML security engineer | browse MLSec cards (EMR/EIR/EOR/EDR) with MITRE ATLAS refs | identify adversarial ML, model theft, data poisoning |
| US-10 | iOS/Android developer | see OWASP MASVS threats via Mobile App cards, cross-referenced to this very app's own design decisions | understand mobile vs. web security differences using a live, in-app example |
| US-11 | DevSecOps engineer | browse DVO/CLD/BOT cards | protect CI/CD pipelines, spot cloud misconfig, defend against bots |
| US-12 | backend developer | browse Website App Cornucopia cards (VE/AT/SM/AZ/CR/C) | map classic OWASP Web Top 10 attack scenarios to mitigations |
| US-13 | Python developer | see a Python code sample for each mitigation | copy a secure implementation pattern |
| US-14 | Java developer | see a Java code sample for each mitigation | compare against this app's own Swift/SwiftData idioms |
| US-15 | Scala developer | find Scala code samples for supply-chain attacks | implement SCA in a Scala pipeline |
| US-16 | Lua/OpenResty developer | see Lua examples for rate limiting preventing LLM DoS | configure NGINX guardrails for an LLM API proxy |
| US-17 | pentester | search a term and find related threats with defenses | assemble a client test checklist |
| US-18 | team lead | export the filtered threat list to CSV/PDF via the native Share Sheet | include it in a risk register |
| US-19 | public-sector product owner / GRC reviewer | browse the "Digital-by-Default Harms" deck (SCO/ARC/AGE/TRU/POR), clearly separated from technical decks | assess digital-exclusion and opaque-design risk, map to A04:2021 |

*(The Polish↔English language switch is folded into every story's acceptance criteria per FR-18 in `requirements.md` rather than numbered separately here.)*

---

## 16. Milestones & Acceptance Criteria

| Milestone | Deliverable | Done when |
|---|---|---|
| M1 | Working skeleton | App launches in the Simulator; home screen shows framework tiles from bundled seed data |
| M2 | Full data seed | All frameworks + threats + mitigations present in the on-device store; counts match expected totals |
| M3 | All six card decks ingested | `IntegrityService` reports `isValid = true` for all six YAML files, including `dbd-cards-1.0-en.yaml` |
| M4 | Code samples complete | Every mitigation has 5 language samples visible on Threat Detail |
| M5 | Matrix + heatmap | Cross-reference table renders; STRIDE heatmap shows coverage % |
| M6 | i18n complete | In-app PL/EN toggle works everywhere, no restart required; String Catalog key-parity check passes in CI |
| M7 | Search + export work | On-device search returns results; CSV/PDF export completes via the native Share Sheet |
| M8 | Digital-by-Default Harms | `DigitalHarmsView` renders all 5 suits with a design-harm badge; A04:2021 cross-reference visible; every `CardKind` switch confirmed exhaustive by the compiler (no `default:` case present anywhere it reads `CardKind`) |
| M9 | Security hardening | `SwiftLint`/Xcode `Analyze` zero HIGH; entitlements file reviewed and contains only the CloudKit capability; manual MASVS self-assessment (§11) completed |
| M10 | Tests green | ≥ 90% of TDD test list in `user_stories+tests.md` passing in CI; TestFlight build distributed |
