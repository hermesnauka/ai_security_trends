# KotlinGuard 2026 — Application Development Plan

**Version:** 1.0
**Date:** 2026-07-07
**Status:** Living document — updated after each sprint planning session
**Directory:** `app12_kotlin_android`
**Sibling projects:** `app01_react`/`app02_angular` (Java/Spring Boot), `app03_python_django` (Python/Django), `app04_scala_react` (Scala/ZIO), `app05_go_react` (Go), `app06_HASKELL_react` (Haskell), `app07_rust_react` (Rust), `app08_cpp_react` (C++), `app09_php_WORDPRESS` (PHP/WordPress), `app10_csharp_react` (C#/.NET), `app11_swift_ios` (Swift/iOS)

---

## 0. Note on the Stack — the Android Twin of `app11_swift_ios`

This application is a **native Android app, written entirely in Kotlin**, using **Jetpack Compose** for the interface and **Room** for on-device persistence. It is the eleventh backend/platform choice in this course's comparison series, and it is the direct structural twin of `app11_swift_ios`: no backend web framework, no REST API, no PostgreSQL/MySQL server, offline-first by default, with the same "no client-server model at all" departure that app introduced. This plan is written to be read *alongside* `app11_swift_ios`'s — most sections below note explicitly where the Android platform's answer to a given concern is the same shape as iOS's, and where it genuinely differs.

**Where Android's platform-level guarantees differ from iOS's, stated precisely rather than assumed equivalent:**

- **Both platforms sandbox each app at the OS level**, but the mechanisms differ: iOS's App Sandbox is a single, Apple-controlled container model with an explicit, narrow entitlement list; Android's sandbox gives **each app its own Linux user ID (UID)**, enforced by the kernel and SELinux, with permissions declared in `AndroidManifest.xml`. Both are genuine, kernel-enforced isolation — this plan does not claim one is "more secure" than the other in the abstract — but Android's **inter-process communication surface (Intents, exported Activities/Services/BroadcastReceivers/ContentProviders)** is historically larger and has a longer history of misconfiguration-driven vulnerabilities (an unintentionally exported component reachable by any other app on the device) than iOS's comparatively more locked-down IPC model. This app's own threat model (§11) treats "exported component" hygiene as a first-class, Android-specific concern with no direct iOS equivalent.
- **Room's `@Query` annotations are verified against the entity schema at compile time** by the Room compiler (via KSP) — a genuinely stronger, more direct analogue to `app05_go_react`'s `sqlc`/`app06_HASKELL_react`'s `hasql-th`/`app07_rust_react`'s `sqlx::query!` than `app11_swift_ios`'s `#Predicate` macro, because Room's compiler actually parses and validates the *SQL string* against the table schema, not merely a Swift/Kotlin expression tree.
- **`kotlinx.serialization`'s default `Json` configuration rejects unrecognized keys unless `ignoreUnknownKeys = true` is explicitly set** — the *strict-by-default* end of the spectrum, the same tier as `app10_csharp_react`'s `YamlDotNet` and the **opposite default** from `app11_swift_ios`'s `Codable` (which is lenient-by-default). These two adjacent mobile-platform apps land on opposite sides of this series' recurring "strict vs. lenient by default" comparison, and this plan states that explicitly (§4 D-06) rather than assuming "mobile" implies one answer.
- **The JVM/Kotlin ecosystem inherits a materially more mature SCA (Software Composition Analysis) tooling story than Swift's**, because Android/Kotlin dependencies are resolved via Gradle/Maven, for which the OWASP Dependency-Check Gradle plugin (checking against the NVD) is a mature, widely-adopted tool — closing the exact gap `app11_swift_ios`'s `requirements.md` SR-10.3 stated as an accepted, ecosystem-level limitation for Swift Package Manager.
- **Distribution via Google Play** involves its own review process (Google Play's automated and human review, plus Play Protect scanning), generally faster and more automated than Apple's App Review, but still a real, external gate this plan budgets for (§13, `SDLC_analysis.md` Phase 5) — the same *category* of external check `app11_swift_ios` introduced to this series, with a different cadence.

**Note on code samples:** the application still *teaches* countermeasures in five languages — Python, Java, Go, Scala, and Lua (see §10) — because that is separate, deliberately polyglot **content**, not the application's own runtime. Kotlin is the JVM-adjacent, but distinct, language actually implementing this app; **Java** remains one of the five sample languages precisely because it is different from Kotlin as a matter of project scope, even though both run on the JVM/ART — the same "sample language ≠ implementation language" rule every sibling has followed is followed here too, and is worth stating explicitly given how close Kotlin and Java are as languages.

---

## 1. Project Overview

**Name:** KotlinGuard 2026
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

All six decks are in scope from day one of this plan (§11, §15) — the gap the `app04_scala_react` plan initially had (and was later corrected for) is avoided here from the start, as it was for every subsequent sibling. As in `app11_swift_ios`, the **Mobile App deck (PC/AA/NS/RS/CRM/CM)** is dual-billed: browsable content (US-10) *and* the direct source of this app's own threat model (§11).

**UI languages:** Polish (default) and English, switched instantly with no app restart, via an in-app `LocaleController` (§4 D-05) rather than requiring the user to change their Android system language.

---

## 2. Technology Stack

### Application (100% Kotlin, no server component)
| Layer | Technology | Version (2026) |
|---|---|---|
| Language | Kotlin | 2.1 |
| Minimum OS | Android | API 26 (Android 8.0)+, target API 35 |
| UI framework | Jetpack Compose (Material 3) | — |
| State management | Compose `State`/`remember`, `ViewModel` (Jetpack Lifecycle) with `StateFlow` — no third-party state library | — |
| Persistence | **Room** (annotation-processed via KSP) over an embedded SQLite store — no separate database server | — |
| Querying | Room's `@Query` — the **SQL string is parsed and verified against the entity schema by the Room compiler at build time**, the strongest compile-time SQL-shape guarantee of any mobile app in this series | — |
| Networking (optional feature only) | `OkHttp`/`Retrofit`, restricted by an explicit `network_security_config.xml` that disables cleartext traffic entirely — used only by the optional cross-device sync feature, never for core content | — |
| Cross-device sync (optional) | **Google Sign-In** (Credential Manager API) + **Cloud Firestore** (a user-scoped collection) — Google-managed infrastructure, no custom auth server or custom sync protocol implemented by this project (§4 D-07), the Android analogue of `app11_swift_ios`'s Sign in with Apple + CloudKit choice | — |
| Local secure storage | **`EncryptedSharedPreferences`** (AndroidX Security library) backed by the **Android Keystore** (hardware-backed where available) for the Firestore sync token only; all educational content is non-sensitive and stored in the ordinary Room database | — |
| Serialization | **`kotlinx.serialization`** (`Json`, default `ignoreUnknownKeys = false` — strict by default) + **`kaml`** for YAML, which layers on the same strict `kotlinx.serialization` decoding (§4 D-06) | — |
| Background tasks | **WorkManager** (Jetpack) — replaces every prior sibling's job-queue library (River/apalis/odd-jobs/Hangfire/WP-Cron/`BGTaskScheduler`) for periodic integrity re-verification; exports are generated synchronously on-device, handed to the native Share Sheet (`Intent.ACTION_SEND`) | — |
| Export | `Intent.ACTION_SEND` with a `FileProvider`-shared URI — native Android share, no server-side rendering | — |
| Localization | Android resource qualifiers (`values-pl/strings.xml`, `values/strings.xml`) for UI strings; a custom `LocaleController` (via `AppCompatDelegate.setApplicationLocales`, the modern **per-app language** API, Android 13+, with a manual fallback for older supported versions) for the in-app PL/EN toggle (§4 D-05) | — |
| Testing | `JUnit 5` (unit) + `Kotest` (property-based testing module, Kotlin's QuickCheck/`proptest`/`SwiftCheck`/`eris` equivalent) + **Compose UI Testing** (`createAndroidComposeRule`, Jetpack's native UI-automation API — replaces Playwright/XCUITest, since this is a native Android UI, not a browser or an iOS UI) | TDD — see `user_stories+tests.md` |
| SAST | **Android Lint** (built into the Android Gradle Plugin, with security-specific checks: `ExportedContentQuery`, `TrustAllX509TrustManager`, `AllowBackup`, `AllowAllHostnameVerifier`, and more) + `detekt` (Kotlin static analysis, style + complexity + some security-adjacent rules) | — |
| SCA | **OWASP Dependency-Check's Gradle plugin** (`dependency-check-gradle`), checking every Gradle dependency against the NVD — a materially more mature tool than anything available for Swift Package Manager as of 2026, closing the exact gap `app11_swift_ios` states as an accepted limitation | — |
| Release hardening | **R8** (code shrinking, obfuscation, and optimization for release builds) — an Android-specific hardening step with no direct iOS equivalent, making static reverse-engineering of a shipped APK meaningfully harder | — |

### Infrastructure (there is no server infrastructure — this replaces every sibling's Docker Compose/Nginx/database section)
| Component | Technology |
|---|---|
| Build & CI | GitHub Actions (Ubuntu or macOS runners both support the Android SDK/Gradle toolchain — this app's CI is more portable than `app11_swift_ios`'s macOS-only requirement) |
| Distribution | Internal testing track → closed/open testing → Google Play production release — Google Play's review process is this project's external distribution gate (§13, `SDLC_analysis.md` Phase 5), generally faster-cadence than Apple's equivalent but not to be treated as a formality |
| Crash/monitoring | Android Vitals (Google Play Console) + Firebase Crashlytics; no self-hosted Grafana/Loki/Prometheus stack is needed or appropriate for a client-only app |
| Code signing | Android App Bundle (`.aab`) signed with a Play App Signing key; Google manages the final APK signing key, this project retains the upload key | — |
| Secrets | No server-side secrets exist. The Firestore project configuration (`google-services.json`) is not a runtime secret in the traditional sense (it identifies, but does not authenticate, the backend project) — actual access control is enforced by Firestore Security Rules, scoped per authenticated user | — |

---

## 3. High-Level Architecture

```
┌──────────────────────────── Android App Sandbox (separate Linux UID, D-01) ───────────┐
│                                                                                           │
│  Jetpack Compose UI  ──observes──►  ViewModels (StateFlow)  ──calls──►  Repositories      │
│  (Threats, Cards, Matrix,             (ThreatBrowserViewModel,          (ThreatRepository, │
│   StrideHeatmap, DigitalHarms,         CardBrowserViewModel, ...)         CardRepository,   │
│   LocaleToggle, ...)                                                       ...)             │
│                                                                              ▼               │
│                                                                    Room Database (@Dao,      │
│                                                                    @Entity: Threat, Card,    │
│                                                                    Mitigation, CodeSample,    │
│                                                                    CrossReference,            │
│                                                                    ContentHash, ...)          │
│                                                                              │                │
│                                                                              ▼                │
│                                                          Embedded SQLite store, in the app's  │
│                                                          private data directory (OS-sandboxed) │
│                                                                                                 │
│  ContentSeeder (first launch / app-update)  ──decodes──►  Bundled JSON/YAML assets              │
│  IntegrityWorker (WorkManager, periodic)  ──calls──►  IntegrityChecker.verify()                 │
│                                                                                                  │
│  (Optional) SyncCoordinator ──uses──► Google Sign-In + Cloud Firestore                          │
│             (the ONLY network-reachable code path in this entire application)                  │
│                                                                                                  │
│  AndroidManifest.xml: every Activity/Service/BroadcastReceiver/ContentProvider is               │
│  android:exported="false" unless a specific, documented reason requires otherwise (D-02)        │
└───────────────────────────────────────────────────────────────────────────────────────────────┘
```

**Where the trust boundaries are, restated for a platform with no server process at all:** the same structural point `app11_swift_ios` makes applies here — there is no browser-to-backend HTTP boundary, because the "server" and the "client" are the same sandboxed process. The trust boundaries that *do* exist are: (1) the Android application sandbox boundary (separate Linux UID + SELinux) between this app's process and every other process/app on the device, enforced by the kernel, independent of this app's own code (D-01); (2) the boundary between `ContentSeeder`/`IntegrityChecker` (the only code paths permitted to write seed/verified content) and the `ViewModel`/`Repository` layers that read it, enforced by Kotlin module/visibility structure (D-02); and (3) the boundary around the optional Firestore sync path, the only place this app's data ever leaves the device at all; and (4) a boundary with **no direct equivalent in `app11_swift_ios`**: the boundary around every exported (or, correctly, *non*-exported) Android component, since Android's richer IPC model means "which of my own components can another app on the device reach" is itself a real question this app must answer explicitly, not simply inherit from the platform's defaults the way iOS's more locked-down model allows.

---

## 4. Architecture Design Decisions

### D-01 — Android application sandbox (per-app Linux UID + SELinux): the same category of OS-enforced guarantee as `app11_swift_ios`'s App Sandbox, with a genuinely larger IPC surface to manage
Every Android app runs under its own Linux user ID, with SELinux mandatory access control further restricting what the process can touch, independent of anything this app's own Kotlin code does correctly or incorrectly — the same *category* of platform-enforced isolation `app11_swift_ios`'s D-01 describes for iOS. This app requests the minimum permission set in `AndroidManifest.xml`: `android.permission.INTERNET` (required only for the optional Firestore sync feature) and nothing else — no storage, camera, location, or contacts permissions. **The honest difference from iOS, stated plainly:** Android additionally exposes a rich inter-process communication surface (Intents, exported Activities/Services/BroadcastReceivers/ContentProviders) that a misconfigured app can accidentally expose to every other app on the device — a historically real vulnerability class with no iOS equivalent of the same shape — which is why D-02 exists as its own, additional design decision rather than being folded into "the sandbox handles it."

### D-02 — Every Android component is `android:exported="false"` by default, with any exception explicitly justified
```xml
<activity android:name=".MainActivity" android:exported="true" /> <!-- required: the launcher activity -->
<activity android:name=".ThreatDetailActivity" android:exported="false" />
<!-- every other Activity, and every Service/BroadcastReceiver/ContentProvider, is exported="false"
     unless a specific, code-reviewed reason (documented in a comment above the manifest entry)
     requires otherwise -->
```
Android Lint's `ExportedContentQuery` and related checks (§2) enforce this as a build-blocking SAST rule, not merely a manifest-review convention. This app has exactly one legitimate reason for an exported component (the launcher `MainActivity`, which the OS itself requires to be reachable) — every other component defaults to unexported, closing the specific, historically real Android vulnerability class (an unintentionally exported `ContentProvider` leaking data, or an exported `Activity`/`Service` reachable by a malicious co-installed app) that has no direct analogue in `app11_swift_ios`'s threat model.

### D-03 — `sealed interface` with a `when` expression — an unconditional compile-time guarantee, the same strongest tier as Swift, Rust, and Haskell
```kotlin
sealed interface CardKind {
    data class TechnicalThreat(val severity: Severity) : CardKind
    data object DesignHarm : CardKind
}

fun severityOf(kind: CardKind): Severity? = when (kind) {
    is CardKind.TechnicalThreat -> kind.severity
    is CardKind.DesignHarm -> null
    // no `else` branch — when `when` is used as an EXPRESSION over a sealed hierarchy,
    // Kotlin requires every case to be handled; omitting one is an unconditional COMPILE
    // ERROR, with no project-configuration flag that disables this check
}
```
Like Swift's `switch` over an `enum` and unlike `app10_csharp_react`'s `CS8509` (a warning promoted to an error by project configuration that could be silently reverted), Kotlin's exhaustiveness check for a `when` **expression** over a `sealed` hierarchy is unconditional — there is no equivalent of removing a configuration line to regain the ability to ship a non-exhaustive branch. (The one caveat worth stating for completeness: using `when` as a *statement* rather than an *expression*, or adding an `else` branch "just in case," would both silently defeat this guarantee — the same category of developer-discipline caveat `app08_cpp_react` states for `std::visit` versus `std::get_if`, and this project's `SEC REVIEW` checklist includes verifying that every `CardKind`-reading `when` is used as an expression with no `else`.)

### D-04 — Room's `@Query`: compile-time-verified SQL, the strongest SQL-safety guarantee of any mobile app in this series
```kotlin
@Dao
interface ThreatDao {
    @Query("SELECT * FROM threats WHERE severity = :severity AND frameworkCode = :frameworkCode")
    suspend fun findBySeverityAndFramework(severity: Severity, frameworkCode: String): List<ThreatEntity>
}
```
Room's KSP-based annotation processor parses this SQL string at **build time** and verifies it against the actual `@Entity`-derived schema — a column-name typo or a type mismatch is a **compile error**, not a runtime failure. This is the closest mobile-app analogue in this series to `app05_go_react`'s `sqlc`/`app06_HASKELL_react`'s `hasql-th`/`app07_rust_react`'s `sqlx::query!`, and a stronger, more literal "SQL shape checked at compile time" guarantee than `app11_swift_ios`'s `#Predicate` macro (which type-checks a Swift expression tree against a Swift model, not a SQL string against a schema). There is no code path in this application capable of constructing a query from untrusted string input at all — Room's `@Query` parameters are always bound, never interpolated.

### D-05 — An in-app `LocaleController`, not just system-locale-following localization
```kotlin
class LocaleController(private val context: Context) {
    fun setLocale(locale: AppLocale) {
        val localeList = LocaleListCompat.forLanguageTags(locale.languageTag)
        AppCompatDelegate.setApplicationLocales(localeList) // per-app language override, no restart needed
    }
}
```
`AppCompatDelegate.setApplicationLocales` (backed by Android 13's native per-app language feature, with `AppCompat`'s own backward-compatible implementation for earlier supported API levels) switches the app's effective locale immediately, without a process restart — the Android-idiomatic equivalent of `app11_swift_ios`'s `Bundle`-swizzling `LocalizationManager`, achieved here via a first-class platform API rather than a custom technique, because Android's per-app language support is more directly exposed to app developers than iOS's equivalent.

### D-06 — `kotlinx.serialization` + `kaml`: strict-by-default decoding, the opposite default from `app11_swift_ios`'s `Codable`
```kotlin
val json = Json { ignoreUnknownKeys = false } // this IS the default — stated explicitly, never loosened
val yaml = Yaml(configuration = YamlConfiguration(strictMode = true)) // kaml, layered on kotlinx.serialization
```
Unlike Swift's `Codable`, which silently ignores unrecognized keys unless a custom decoder is written, `kotlinx.serialization`'s default configuration **throws `SerializationException` on an unrecognized key** — the same strict-by-default tier as `app10_csharp_react`'s `YamlDotNet`. This project's only obligation is to never set `ignoreUnknownKeys = true`; a `detekt` custom rule flags any occurrence of that flag being set to `true` anywhere in the codebase, the same defensive stance `app10_csharp_react` takes toward `YamlDotNet.IgnoreUnmatchedProperties()`.

### D-07 — Google Sign-In + Cloud Firestore for the one optional feature that needs a network at all
Bookmark/favorite sync across a user's devices uses the **Credential Manager API's Google Sign-In flow** (no password this app ever sees or stores) and **Cloud Firestore**, with **Firestore Security Rules** scoping every document to `request.auth.uid == resource.data.ownerId` — Google-managed authentication and per-user data isolation, the direct Android analogue of `app11_swift_ios`'s Sign in with Apple + CloudKit decision. This project implements no custom authentication server and no custom sync protocol.

### D-08 — Attack-demo code samples ship read-only, bundled, never executed
Every code sample (all five languages) is bundled as an Android asset, read-only, rendered as syntax-highlighted text in a Composable. There is no code-execution feature anywhere in this app, and an `AttackDemoWarningDialog` (a Compose `AlertDialog`) gates *viewing/copying* the content, the same UX pattern every sibling uses.

---

## 5. Data Model (Room `@Entity` types)

### 5.1 Core enums and the `CardKind` type (see D-03 for the full guarantee)
```kotlin
enum class Severity { CRITICAL, HIGH, MEDIUM, LOW, INFO }
enum class StrideCategory { S, T, R, I, D, E }
enum class SampleType { ATTACK_DEMO, DEFENSE }
enum class CodeLanguage { PYTHON, JAVA, GO, SCALA, LUA }
enum class MitigationType { PREVENTIVE, DETECTIVE, CORRECTIVE, COMPENSATING }
enum class Effort { LOW, MEDIUM, HIGH }
enum class Effectiveness { PARTIAL, SIGNIFICANT, FULL }
enum class RelationshipType { EQUIVALENT, RELATED, PARENT_CHILD, MAPS_TO }

sealed interface CardKind {
    data class TechnicalThreat(val severity: Severity) : CardKind
    data object DesignHarm : CardKind
}
```

### 5.2 Framework
```kotlin
@Entity(tableName = "frameworks")
data class FrameworkEntity(
    @PrimaryKey val code: String,          // "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS", ...
    val name: String,
    val version: String,
    val description: String,
    val referenceUrl: String
)
```

### 5.3 Threat
```kotlin
@Entity(tableName = "threats")
data class ThreatEntity(
    @PrimaryKey val code: String,          // "LLM01:2025", "A03:2021", "AML.T0051"
    val frameworkCode: String,
    val title: String,
    val severity: Severity,
    val category: String,
    val descriptionEn: String,
    val descriptionPl: String,              // content i18n lives on the entity directly, the
                                              // same single-device-store simplification app11
                                              // makes versus a separate translation table
    val attackVector: String,
    val attackSurface: String,
    val stride: List<StrideCategory>,       // Room TypeConverter for the list
    val tags: List<String>
)
```

### 5.4 CornucopiaCard *(all six YAML decks — see D-03 for `CardKind`)*
```kotlin
@Entity(tableName = "cards")
data class CornucopiaCardEntity(
    @PrimaryKey val cardId: String,        // "VE3", "LLM4", "SCO2"
    val suitCode: String,
    val suitName: String,
    val edition: String,                    // webapp, mobileapp, companion, eop, mlsec, dbd
    val value: String,                       // "2".."10","J","Q","K","A"
    val kind: CardKind,                       // D-03: TechnicalThreat(severity) | DesignHarm
    val descriptionEn: String,
    val descriptionPl: String,
    val miscNote: String?,
    val sourceUrl: String?,
    val owaspRefs: List<String>,
    val mitreRefs: List<String>,
    val contentSha256: String
)
```

### 5.5 Mitigation
```kotlin
@Entity(
    tableName = "mitigations",
    foreignKeys = [
        ForeignKey(entity = ThreatEntity::class, parentColumns = ["code"], childColumns = ["threatCode"]),
        ForeignKey(entity = CornucopiaCardEntity::class, parentColumns = ["cardId"], childColumns = ["cardId"])
    ]
)
data class MitigationEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val threatCode: String?,
    val cardId: String?,
    val title: String,
    val description: String,
    val mitigationType: MitigationType,
    val effort: Effort,
    val effectiveness: Effectiveness
    // non-emptiness of associated CodeSamples verified by a Kotest property over seed data,
    // not the type itself — the same accepted gap every sibling without a dedicated
    // NonEmpty-collection type states
)
```

### 5.6 CodeSample
```kotlin
@Entity(tableName = "code_samples")
data class CodeSampleEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val mitigationId: Long,
    val language: CodeLanguage,
    val sampleType: SampleType,
    val title: String,
    val description: String,
    val code: String,
    val frameworkHint: String,   // "Room @Query", "Spring Boot 3.3", "Django ORM"...
    val versionNote: String
)
```

### 5.7 CrossReference
```kotlin
@Entity(tableName = "cross_references")
data class CrossReferenceEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val sourceThreatCode: String,
    val targetThreatCode: String,
    val relationshipType: RelationshipType,
    val description: String
)
```

### 5.8 ContentHash
```kotlin
@Entity(tableName = "content_hashes")
data class ContentHashEntity(
    @PrimaryKey val fileName: String,
    val sha256Hash: String,
    val verifiedAt: Long,   // epoch millis
    val isValid: Boolean,
    val verifiedBy: String = "kotlinguard-integrity-checker"
)
```

### 5.9 Bookmark *(the only user-generated, sync-eligible data)*
```kotlin
@Entity(tableName = "bookmarks")
data class BookmarkEntity(
    @PrimaryKey val threatOrCardCode: String,
    val createdAt: Long,
    val firestoreDocId: String?   // set only if Firestore sync (D-07) is enabled
)
```

---

## 6. Development Phases

*(Numbering aligned with the Agile/Scrum sprint plan in `SDLC_analysis.md`, §4.)*

### Phase 1 — Foundation (Sprints 1–2)
Covers: US-01, US-02
- [ ] Gradle multi-module project: `:data` (Room, `ContentSeeder`, `IntegrityChecker`, Repositories), `:ui` (Compose, ViewModels), `:app` (thin composition root, `MainActivity`)
- [ ] `AndroidManifest.xml` with every component `android:exported="false"` except the launcher `MainActivity` (D-02)
- [ ] Room database schema for entities in §5.1–5.9; KSP annotation processing wired into Gradle
- [ ] `ContentSeeder` — decodes bundled JSON assets for OWASP Web/LLM/Agentic/API, MITRE ATLAS, CompTIA SecAI+ into Room on first launch
- [ ] `FrameworkListScreen` (Compose) + `FrameworkListViewModel` — the home screen
- [ ] `LocaleController` (D-05) + resource-qualifier scaffolding for `values`/`values-pl`
- [ ] Android Lint + `detekt` wired into CI (not yet blocking)

**Security checkpoint:** `AndroidManifest.xml` review confirms only the launcher `Activity` is exported; Android Lint's `ExportedContentQuery` check passes with zero findings; `INTERNET` permission is the only one declared.

### Phase 2 — Core Threat Browser (Sprints 3–4)
Covers: US-02, US-03, US-04
- [ ] Room `@Query`-based filtering: framework, severity, stride, category, tag, q (D-04)
- [ ] `ThreatDetailScreen` — sections: Overview | Attack Vectors | Mitigations | Code | Cross-References
- [ ] `ThreatBrowserViewModel` with a debounced `StateFlow<String>` search query
- [ ] `MatrixScreen` — cross-framework mapping table

**Security checkpoint:** Room compiler build output confirmed to contain zero `@Query` compilation warnings; code review confirms no `SupportSQLiteDatabase.rawQuery` with string-concatenated input exists anywhere (the one way Room's own guarantee could be bypassed).

### Phase 3 — Card Decks & Content Integrity (Sprints 5–7)
Covers: US-05–US-12, US-19
- [ ] `kotlinx.serialization`/`kaml`-based decoders (D-06) for **all six** `docs/OWASP_stories/*.yaml` files, bundled as Android assets
- [ ] `IntegrityChecker.verify()` — SHA-256 vs bundled `hashes.json`; called only from `ContentSeeder` and `IntegrityWorker` (D-02-style module isolation, enforced by Gradle module boundaries — `:ui` does not depend on `IntegrityChecker`'s internal module)
- [ ] Card suit browser screens: FRE, LLM, AAI, CLD (Companion), SP/TA/RE/ID/DS/EP (STRIDE), EMR/EIR/EOR/EDR (MLSec), PC/AA/NS/RS/CRM/CM (Mobile — **this app's own threat-model source**, §11), VE/AT/SM/AZ/CR/C (Website App), **SCO/ARC/AGE/TRU/POR (Digital-by-Default Harms, US-19 — in scope here, not bolted on later)**
- [ ] `AttackDemoWarningDialog` (Compose `AlertDialog`) before revealing `ATTACK_DEMO` code samples

**Security checkpoint:** malformed/unknown-field YAML throws `SerializationException` by default (a `Kotest` property generates random extra keys and asserts the throw); content hash mismatch aborts seeding and surfaces a user-visible "content integrity error" state.

### Phase 4 — Code Samples: 5 Languages (Sprints 7–9)
Covers: US-13–US-16
- [ ] Code sample seed data for every mitigation × 5 languages (Python, Java, Go, Scala, Lua)
- [ ] `CodeSamplePanel` Composable — per-language tabs, Attack Demo / Defense sub-tabs, syntax highlighting
- [ ] MITRE ATLAS Kill-Chain timeline (native Compose `Canvas`, no third-party charting library)

### Phase 5 — i18n Polish ↔ English (Sprint 9–10)
Covers: US-11 (folded into every story's acceptance criteria, see §15 note)
- [ ] Full `strings.xml`/`values-pl/strings.xml` coverage for every UI string
- [ ] `LocaleToggle` Composable driving `LocaleController` (D-05)
- [ ] Card/threat content's `descriptionPl`/`descriptionEn` fields switched by the same locale state
- [ ] Code samples **never** translated
- [ ] CI check: a script diffing string resource keys used in Composables against keys present in both `strings.xml` files fails the build on any mismatch

### Phase 6 — Search, Export, Matrix Completion, Optional Sync (Sprints 10–12)
Covers: US-17, US-18
- [ ] Room `@Query`-based search (`LIKE`-based, with an FTS4/FTS5 virtual table considered if relevance needs improve beyond simple matching)
- [ ] `Intent.ACTION_SEND`-based CSV/PDF export via `FileProvider`, generated synchronously on-device
- [ ] `MatrixLlmScreen`, `MatrixAgenticScreen`, `MatrixMobileVsWebScreen`, `StrideHeatmapScreen`, `MatrixDigitalHarmsScreen`
- [ ] (Optional feature) Google Sign-In + Cloud Firestore sync for `Bookmark` (D-07) — the `INTERNET` permission and Firestore Security Rules are finalized at this point

### Phase 7 — Hardening, Testing & Release (Sprints 12–14)
Covers: full regression across US-01–US-19
- [ ] `JUnit 5` + `Kotest` properties, coverage ≥ 85% on `:data`
- [ ] Compose UI Testing suite (`createAndroidComposeRule`) — one scenario per user story
- [ ] Android Lint + `detekt` in CI, zero HIGH findings
- [ ] `dependency-check-gradle` (OWASP Dependency-Check) in CI, zero HIGH/CRITICAL
- [ ] R8 shrinking/obfuscation confirmed active and non-breaking in the release build variant
- [ ] Manual `AndroidManifest.xml` review confirming no unintended exported component
- [ ] Internal testing track → closed testing → Google Play production release

---

## 7. Repository / Data-Access Layer Map

*(This section replaces every sibling's "API Endpoint Map" — there is no HTTP surface in this application at all, the same structural point `app11_swift_ios` makes.)*

```kotlin
interface FrameworkRepository {
    suspend fun list(): List<Framework>
    suspend fun detail(code: String): Framework?
}

interface ThreatRepository {
    suspend fun list(filter: ThreatFilter): List<Threat>
    suspend fun detail(code: String): Threat?
    suspend fun crossReferences(sourceCode: String): List<CrossReference>
}

interface CardRepository {
    suspend fun bySuit(suitCode: String): List<CornucopiaCard>
    suspend fun byCardId(cardId: String): CornucopiaCard?
    suspend fun suits(edition: String): List<String>
    // Digital-by-Default Harms (US-19): callers use `card.kind` via the exhaustive `when` in
    // D-03 — there is no separate "severity" accessor that could accidentally be called on a
    // design-harm card, because Severity is only reachable through that `when` at all.
}

interface MatrixRepository {
    suspend fun llmMatrix(): Matrix
    suspend fun agenticMatrix(): Matrix
    suspend fun mobileVsWebMatrix(): Matrix
    suspend fun strideHeatmap(): StrideHeatmap
}

interface SearchRepository {
    suspend fun query(text: String, locale: AppLocale): List<SearchResult>
}

interface ExportService {
    suspend fun exportCsv(filter: ThreatFilter): Uri   // synchronous, on-device, shared via FileProvider
    suspend fun exportPdf(threatCode: String): Uri
}

interface BookmarkRepository {
    suspend fun add(code: String)
    suspend fun remove(code: String)
    suspend fun list(): List<Bookmark>
    // (Optional) sync via SyncCoordinator, which is the ONLY type in this app that imports
    // the Firestore/Google Sign-In SDKs
}
```

There is no `CornucopiaCard` write method anywhere in this interface surface, and no implementation exists in `:data` either (the C-08-equivalent constraint every sibling since `app05_go_react` states) — cards are written only by `ContentSeeder` and the periodic re-seed path.

---

## 8. Jetpack Compose Screen & Feature Structure

```
Screens (:ui):
  RootScreen                       → NavigationBar: Frameworks | Threats | Search | Bookmarks | About
  FrameworkListScreen / FrameworkDetailScreen
  ThreatBrowserScreen / ThreatDetailScreen (sections: Overview | Attack Vectors | Mitigations | Code | Cross-Refs)
  CardSuitScreen(edition:)          → generic, parameterized by edition/suit — used for:
    - Website App suits (US-12)        - FRE (US-05)
    - LLM (US-06) + LlmMatrixScreen     - AAI + CLD (US-07)
    - STRIDE catalogue (US-08) + StrideHeatmapScreen
    - MLSec (US-09)                     - Mobile (US-10) + MobileVsWebMatrixScreen
    - DevOps: DVO + BOT (US-11)
  DigitalHarmsScreen (US-19)         → DesignHarmBadge (its Kotlin type has no severity branch to read)
  CodeSamplePanel                     → per-language tabs, AttackDemoWarningDialog
  SearchResultsScreen
  LocaleToggle (D-05)
  BotWarningDialog (US-11)
  AboutScreen
```

---

## 9. Gradle Module / Project Layout

```
app12_kotlin_android/
├── settings.gradle.kts
├── build.gradle.kts
├── data/                                  ← Gradle module
│   ├── build.gradle.kts                   ← KSP, Room, kotlinx.serialization, kaml
│   └── src/main/kotlin/.../data/
│       ├── model/
│       │   ├── Enums.kt                   ← Section 5 enums
│       │   └── CardKind.kt                ← D-03
│       ├── seeding/
│       │   └── ContentSeeder.kt
│       ├── cards/
│       │   └── CardFileDecoders.kt        ← D-06, one decoder per YAML shape
│       ├── integrity/
│       │   └── IntegrityChecker.kt        ← module-internal, isolated per D-02-style boundary
│       ├── sync/
│       │   └── SyncCoordinator.kt         ← the only file importing Firestore/Google Sign-In (D-07)
│       ├── db/                             ← Room @Dao interfaces, @Database class
│       └── repository/                      ← §7 interface implementations
├── ui/                                      ← Gradle module, depends on :data's public API only
│   └── src/main/kotlin/.../ui/
│       ├── screens/                          ← §8
│       ├── viewmodel/                          ← ViewModel + StateFlow classes
│       └── locale/
│           └── LocaleController.kt             ← D-05
├── app/                                      ← the actual application module, thin composition root
│   ├── build.gradle.kts
│   ├── src/main/
│   │   ├── AndroidManifest.xml                ← D-02: every component exported="false" except launcher
│   │   ├── kotlin/.../MainActivity.kt
│   │   └── assets/
│   │       ├── owasp_web_top10.json
│   │       ├── owasp_llm_top10.json
│   │       ├── owasp_agentic_top10.json
│   │       ├── mitre_atlas.json
│   │       ├── comptia_secai.json
│   │       ├── cornucopia/
│   │       │   ├── webapp-cards-3.0-en.yaml
│   │       │   ├── companion-llm-cards-1.0-en.yaml
│   │       │   ├── mobileapp-cards-1.1-en.yaml
│   │       │   ├── stride-eop-cards-5.0-en.yaml
│   │       │   ├── mlsec-cards-1.0-en.yaml
│   │       │   ├── dbd-cards-1.0-en.yaml      ← Digital-by-Default Harms (US-19)
│   │       │   └── translations/pl.cards.json
│   │       ├── hashes.json
│   │       ├── mitre-atlas-allowlist.json
│   │       ├── ref-allowlists.json
│   │       └── code_samples/{python,java,go,scala,lua}/
│   └── src/main/res/values/strings.xml, values-pl/strings.xml   ← PL/EN string resources
├── data/src/test/                              ← JUnit 5 + Kotest (unit/property, on :data)
└── app/src/androidTest/                         ← Compose UI Testing, one file per user story (us01..us19)
```

---

## 10. Code Sample Strategy

Every `Mitigation` ships exactly **five** `CodeSample` entities. As in every sibling since `app07_rust_react`, completeness is verified by a `Kotest` property over the seeded dataset, not a type-level guarantee.

| Language | Primary framework/library used in samples |
|---|---|
| Python | Django ORM / FastAPI + Pydantic |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | `chi` + `sqlc` + `pgx` |
| Scala | Akka HTTP / http4s, Slick 3.x, ZIO 2 |
| Lua | OpenResty / NGINX Lua, `lua-resty-jwt`, LuaSQL |

```
sampleType: ATTACK_DEMO   // VULNERABLE — do not use in production
sampleType: DEFENSE       // SECURE pattern, with a one-line WHY comment
```

**A note on Java as a sample language versus this app's own Kotlin:** Kotlin and Java share the JVM/ART runtime, which makes the Java code-sample tab an unusually direct, line-by-line comparison point for this app's own idioms (Room's `@Query` versus Spring Data JPA's `@Query`, both compile-time-checked in their own way) — the Code Samples tab, for the relevant threats, cross-links to this app's own source as an implicit sixth example without adding Kotlin as a seventh formal sample language (the brief specifies five: Python, Java, Go, Scala, Lua).

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
| **OWASP MASVS 2.0 — this app's own primary threat model, not just browsable content** | all 7 categories | `PC/AA/NS/RS/CRM/CM` suits (Mobile) — cross-referenced directly against KotlinGuard's own Android Sandbox (D-01), exported-component discipline (D-02), and Firestore sync (D-07) design decisions in `SDLC_analysis.md` Phase 0/2 |
| STRIDE | S,T,R,I,D,E — all 6 | `SP/TA/RE/ID/DS/EP` suits (EoP v5.0) |
| Elevation of MLSec | Model/Input/Output/Dataset Risk | `EMR/EIR/EOR/EDR` suits |
| MITRE ATLAS | ≥ 15 techniques across ≥ 5 tactics | seeded JSON, cross-referenced from LLM/AAI/mlsec cards |
| CompTIA Security+ / SecAI+ | ≥ 20 topics, including Android-specific mobile-security topics (exported components, `network_security_config`, Keystore) | seeded JSON, from `docs/Security Architects...md` mapping table |
| OWASP A04:2021 Insecure Design — Digital-by-Default Harms | Scope/Architecture/Agency/Trust/Porosity | `SCO/ARC/AGE/TRU/POR` suits (US-19) — **not** a technical-vulnerability deck, see D-03 |

---

## 12. Cornucopia Content Pipeline

```
app/src/main/assets/cornucopia/
├── webapp-cards-3.0-en.yaml
├── companion-llm-cards-1.0-en.yaml
├── mobileapp-cards-1.1-en.yaml
├── stride-eop-cards-5.0-en.yaml
├── mlsec-cards-1.0-en.yaml
├── dbd-cards-1.0-en.yaml            ← Digital-by-Default Harms (US-19)
└── translations/pl.cards.json

app/src/main/assets/hashes.json       ← SHA-256 per YAML file
app/src/main/assets/mitre-atlas-allowlist.json
app/src/main/assets/ref-allowlists.json
```

**Workflow:**
1. PR touching `assets/cornucopia/*.yaml` → CODEOWNERS `@security-team`, min. 2 approvals.
2. CI job `yaml-content-integrity`: `kaml`'s strict decoding (D-06) must succeed against every file (any unrecognized shape throws `SerializationException`) + injection-pattern grep + ref-allowlist validation.
3. Post-merge: a `hash-generator` CI step updates `assets/hashes.json`.
4. `ContentSeeder` and `IntegrityWorker` both call `IntegrityChecker.verify()` on app launch/periodic refresh — the same reframing `app11_swift_ios`'s §12 describes applies here: because the APK/AAB is signed and the sandbox prevents another app from modifying this app's assets post-install, this check's primary value is catching a bad build/CI mistake and detecting on-device Room-database corruption, not defending against a runtime attacker modifying files on a mutable server filesystem.

---

## 13. Risk Register

| Risk | Mitigation |
|---|---|
| An Activity/Service/BroadcastReceiver/ContentProvider accidentally left exported | Android Lint's `ExportedContentQuery` (build-blocking) + manual `AndroidManifest.xml` review before every release (D-02) — **this app's single largest Android-specific risk with no direct `app11_swift_ios` equivalent** |
| `kotlinx.serialization`'s `ignoreUnknownKeys` flipped to `true` by a future contributor "to fix a crash" | `detekt` custom rule flagging any occurrence of `ignoreUnknownKeys = true`; `Kotest` property test regression coverage |
| Digital-by-Default Harms deck misread as CVE severity | `CardKind` sealed interface with a `when` expression (D-03) — the strongest, unconditional guarantee in this series, tied with Swift/Rust/Haskell, *provided* every read site uses `when` as an expression with no `else` |
| `IntegrityChecker` called from an unintended module | Gradle module boundary (`:ui` does not depend on `:data`'s internal integrity package) + `detekt` custom rule |
| A future `SupportSQLiteDatabase.rawQuery` call reintroduces string-built SQL, bypassing Room's `@Query` guarantee | Code review + a `detekt`/Android Lint custom rule forbidding `rawQuery` outside a documented, reviewed exception |
| Firestore sync token exposure | Stored in `EncryptedSharedPreferences` (Keystore-backed), never in plain `SharedPreferences` or the Room database |
| R8 obfuscation breaking a reflection-dependent library at runtime, discovered only in a release build | R8/ProGuard rules tested against a release build variant in CI, not only debug builds |
| Attack-demo code confused with production-safe code | Red-styled badge + `AlertDialog` confirmation before code is shown/copied |
| Bundled asset JSON/YAML tampered in a PR | CODEOWNERS review + `IntegrityChecker.verify()` SHA-256 check |

---

## 14. Directory Layout

```
app12_kotlin_android/
├── PLAN.md
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
└── (Gradle/Android Studio project — see §9 for full internal layout)
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
| US-10 | Android/iOS developer | see OWASP MASVS threats via Mobile App cards, cross-referenced to this very app's own design decisions | understand mobile vs. web security differences using a live, in-app example |
| US-11 | DevSecOps engineer | browse DVO/CLD/BOT cards | protect CI/CD pipelines, spot cloud misconfig, defend against bots |
| US-12 | backend developer | browse Website App Cornucopia cards (VE/AT/SM/AZ/CR/C) | map classic OWASP Web Top 10 attack scenarios to mitigations |
| US-13 | Python developer | see a Python code sample for each mitigation | copy a secure implementation pattern |
| US-14 | Java developer | see a Java code sample for each mitigation | compare against this app's own Kotlin/Room idioms |
| US-15 | Scala developer | find Scala code samples for supply-chain attacks | implement SCA in a Scala pipeline |
| US-16 | Lua/OpenResty developer | see Lua examples for rate limiting preventing LLM DoS | configure NGINX guardrails for an LLM API proxy |
| US-17 | pentester | search a term and find related threats with defenses | assemble a client test checklist |
| US-18 | team lead | export the filtered threat list to CSV/PDF via the native Android share sheet | include it in a risk register |
| US-19 | public-sector product owner / GRC reviewer | browse the "Digital-by-Default Harms" deck (SCO/ARC/AGE/TRU/POR), clearly separated from technical decks | assess digital-exclusion and opaque-design risk, map to A04:2021 |

*(The Polish↔English language switch is folded into every story's acceptance criteria per FR-18 in `requirements.md` rather than numbered separately here.)*

---

## 16. Milestones & Acceptance Criteria

| Milestone | Deliverable | Done when |
|---|---|---|
| M1 | Working skeleton | App launches in the Emulator; home screen shows framework tiles from bundled seed data |
| M2 | Full data seed | All frameworks + threats + mitigations present in the Room database; counts match expected totals |
| M3 | All six card decks ingested | `IntegrityChecker` reports `isValid = true` for all six YAML files, including `dbd-cards-1.0-en.yaml` |
| M4 | Code samples complete | Every mitigation has 5 language samples visible on Threat Detail |
| M5 | Matrix + heatmap | Cross-reference table renders; STRIDE heatmap shows coverage % |
| M6 | i18n complete | In-app PL/EN toggle works everywhere, no restart required; string-resource key-parity check passes in CI |
| M7 | Search + export work | On-device search returns results; CSV/PDF export completes via the native Android share sheet |
| M8 | Digital-by-Default Harms | `DigitalHarmsScreen` renders all 5 suits with a design-harm badge; A04:2021 cross-reference visible; every `CardKind` `when` confirmed exhaustive by the compiler (no `else` branch present anywhere it reads `CardKind`) |
| M9 | Security hardening | Android Lint/`detekt`/`dependency-check-gradle` zero HIGH; `AndroidManifest.xml` reviewed and contains only the launcher-activity export plus the `INTERNET` permission; R8 release build verified functional |
| M10 | Tests green | ≥ 90% of TDD test list in `user_stories+tests.md` passing in CI; internal testing track build distributed |
