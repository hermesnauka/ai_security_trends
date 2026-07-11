# KotlinGuard 2026 — Requirements Specification

**Version:** 1.0
**Date:** 2026-07-07
**Companion document:** `PLAN.md`

---

## 1. Functional Requirements

| ID | Requirement |
|---|---|
| FR-01 | The app SHALL display a home screen listing all security frameworks in scope (OWASP Web/LLM/Agentic/API/Client-Side/CI-CD Top 10, OAT, MITRE ATLAS, CompTIA Security+/SecAI+). |
| FR-02 | The app SHALL allow filtering the threat list by framework, severity, STRIDE category, tag, and free-text query, using Room `@Query`-backed repository methods. |
| FR-03 | The app SHALL display, for each threat, a detail screen with sections: Overview, Attack Vectors, Mitigations, Code Samples, Cross-References. |
| FR-04 | The app SHALL display cross-framework mappings (e.g., LLM01:2025 ↔ MITRE ATLAS AML.T0051) in a dedicated Matrix screen. |
| FR-05 | The app SHALL present the OWASP Cornucopia Companion deck's FRE suit (client-side threats) with Polish and English descriptions. |
| FR-06 | The app SHALL present the OWASP Cornucopia Companion deck's LLM suit with an interactive LLM-vs-OWASP-LLM-Top-10 matrix. |
| FR-07 | The app SHALL present the AAI (Agentic AI) and CLD (Cloud) suits from the Companion deck. |
| FR-08 | The app SHALL present the STRIDE/Elevation-of-Privilege deck (SP/TA/RE/ID/DS/EP) with an interactive coverage heatmap. |
| FR-09 | The app SHALL present the Elevation-of-MLSec deck (EMR/EIR/EOR/EDR) with MITRE ATLAS cross-references. |
| FR-10 | The app SHALL present the OWASP Cornucopia Mobile App deck (PC/AA/NS/RS/CRM/CM) and SHALL cross-reference each relevant card against this application's own Android-specific design decisions (sandbox, exported-component discipline, Keystore usage). |
| FR-11 | The app SHALL present the DVO (CI/CD) and BOT (Automated Threats) suits from the Companion deck. |
| FR-12 | The app SHALL present the OWASP Cornucopia Website App deck (VE/AT/SM/AZ/CR/C) suits. |
| FR-13 | The app SHALL display, for every mitigation, a Python code sample (attack demo and/or defense). |
| FR-14 | The app SHALL display, for every mitigation, a Java code sample. |
| FR-15 | The app SHALL display, for every mitigation, a Scala code sample. |
| FR-16 | The app SHALL display, for every mitigation, a Lua code sample. |
| FR-17 | The app SHALL display, for every mitigation, a Go code sample. |
| FR-18 | The app SHALL provide an in-app control to switch the UI and content language between Polish and English instantly, without requiring an app restart or a change to the device's system language. |
| FR-19 | The app SHALL present the "Digital-by-Default Harms" deck (SCO/ARC/AGE/TRU/POR suits from `dbd-cards-1.0-en.yaml`) on a dedicated screen, visually and structurally distinguished from technical-vulnerability decks, and SHALL cross-reference it to OWASP A04:2021 (Insecure Design). |
| FR-20 | The app SHALL allow the user to search across all threats and cards by free text and locale-aware content. |
| FR-21 | The app SHALL allow the user to export a filtered threat list as CSV or PDF via the native Android Share Sheet (`Intent.ACTION_SEND`). |
| FR-22 | The app SHALL allow the user to bookmark any threat or card for later reference. |
| FR-23 | The app MAY allow the user to sign in with a Google account to sync bookmarks across their own devices via Cloud Firestore; this feature SHALL be optional and off by default. |

---

## 2. Security Requirements

| ID | Requirement |
|---|---|
| SR-01 | Every `AndroidManifest.xml` component (`Activity`, `Service`, `BroadcastReceiver`, `ContentProvider`) SHALL be declared `android:exported="false"` unless a specific, documented, code-reviewed reason requires otherwise. The launcher `MainActivity` is the only accepted exception. |
| SR-02 | The app SHALL declare the minimum Android permission set required for its features. As of this specification, only `android.permission.INTERNET` (required solely for the optional Firestore sync feature, FR-23) SHALL be declared. |
| SR-03 | The `CardKind` type modeling technical-threat cards versus design-harm cards (dbd deck, FR-19) SHALL be implemented as a Kotlin `sealed interface`, and every site that reads a card's severity SHALL do so via a `when` expression (not a `when` statement, and without an `else`/`is CardKind ->` catch-all branch), so that a design-harm card can never yield a `Severity` value and the Kotlin compiler rejects any incomplete handling at build time. |
| SR-04 | `kotlinx.serialization`'s `Json` and `kaml`'s `Yaml` decoders SHALL be configured with `ignoreUnknownKeys = false` / `strictMode = true` (the library defaults) everywhere in the codebase; no code path SHALL set either flag to relax this behavior. |
| SR-05 | All bundled security-framework and card-deck content (JSON/YAML assets) SHALL be verified against a bundled SHA-256 manifest (`hashes.json`) on first launch and on each periodic `WorkManager` refresh; a hash mismatch SHALL block seeding and surface a user-visible integrity-error state rather than silently loading unverified content. |
| SR-06 | Attack-demonstration code samples (`sampleType = ATTACK_DEMO`) SHALL be visually distinguished (a persistent warning badge) and SHALL require an explicit user acknowledgement (`AlertDialog`) before the code is revealed or made copyable. |
| SR-07 | The application SHALL contain no code-execution feature; all code samples are rendered as static, read-only, syntax-highlighted text. |
| SR-08 | Every Room `@Query` used by this application SHALL use bound parameters exclusively; no SQL string SHALL ever be constructed by concatenating untrusted input, and any use of `SupportSQLiteDatabase.rawQuery` SHALL require a documented, reviewed exception. |
| SR-09 | The optional Firestore sync token (FR-23) SHALL be stored using `EncryptedSharedPreferences`, backed by the Android Keystore; it SHALL NOT be stored in plain `SharedPreferences`, the Room database, or any log output. |
| SR-10 | Firestore Security Rules SHALL scope every synced document to `request.auth.uid == resource.data.ownerId`, so that no authenticated user can read or write another user's bookmark data. |
| SR-10.1 | `network_security_config.xml` SHALL disable cleartext (non-HTTPS) traffic for all network destinations used by this application. |
| SR-11 | CI SHALL run `dependency-check-gradle` (OWASP Dependency-Check) against every Gradle dependency on every pull request; a build with a HIGH or CRITICAL finding SHALL fail. |
| SR-12 | CI SHALL run Android Lint (including `ExportedContentQuery`, `TrustAllX509TrustManager`, `AllowAllHostnameVerifier`, `AllowBackup`) and `detekt` on every pull request; a build with a HIGH-severity finding SHALL fail. |
| SR-13 | Release (non-debug) build variants SHALL enable R8 code shrinking and obfuscation, and this configuration SHALL be verified functional (not merely present) in CI before a release is promoted. |
| SR-14 | Pull requests modifying any file under `assets/cornucopia/*.yaml` SHALL require CODEOWNERS review from the designated security-content owners, with a minimum of two approvals. |
| SR-15 | `android:allowBackup` SHALL be set to `false` (or backup rules SHALL explicitly exclude the Room database and `EncryptedSharedPreferences` file), preventing sensitive local state from being extracted via ADB backup. |

---

## 3. Non-Functional Requirements

| ID | Requirement |
|---|---|
| NFR-01 | The app SHALL run offline for every feature except the optional bookmark-sync feature (FR-23). |
| NFR-02 | Cold app launch (first frame drawn) SHALL complete in under 2 seconds on a mid-range 2024-class Android device. |
| NFR-03 | The Room database SHALL support at least 2,000 threat/card records and associated code samples without a filtered query exceeding 150ms on a mid-range device. |
| NFR-04 | The app SHALL support Android API 26 (Android 8.0) through the latest stable API level available at release time. |
| NFR-05 | The app SHALL comply with WCAG 2.1 AA-equivalent accessibility via Jetpack Compose's semantics APIs (TalkBack support, minimum touch target size, sufficient contrast). |
| NFR-06 | The app SHALL be distributed as an Android App Bundle (`.aab`), signed via Play App Signing. |
| NFR-07 | Unit and property-based test coverage on the `:data` Gradle module SHALL be at least 85% of statements. |
| NFR-08 | The app's APK/AAB download size SHALL not exceed 40MB (excluding on-demand asset packs, if introduced later). |

---

## 4. Design Constraints

| ID | Constraint |
|---|---|
| C-01 | The application SHALL be implemented entirely in Kotlin. No part of the application's own runtime (UI, persistence, business logic, background work) SHALL be implemented in Java, Python, Go, Scala, Lua, or any other language — those five languages are used exclusively for in-app **content** (code samples), never for the app's own implementation. |
| C-02 | The application SHALL have no server-side component: no REST API, no application server, no self-hosted database server. All data resides in an on-device Room/SQLite store, with the sole exception of the optional Firestore sync feature (FR-23), which uses Google-managed infrastructure and stores only bookmark references. |
| C-03 | The UI SHALL be implemented using Jetpack Compose exclusively; no `View`/XML-layout-based screens SHALL be introduced. |
| C-04 | All six YAML card decks under `docs/OWASP_stories/` SHALL be included from the first release, including the Digital-by-Default Harms deck — no deck SHALL be deferred to a later phase. |
| C-05 | The app SHALL NOT request any Android permission not directly required by an implemented feature (principle of least privilege at the manifest level). |
| C-06 | Google Sign-In and Firestore SDK usage SHALL be confined to a single, isolated module/class (`SyncCoordinator`); no other part of the codebase SHALL import these SDKs directly. |

---

## 5. Data Requirements

| ID | Requirement |
|---|---|
| DR-01 | Every `ThreatEntity` SHALL carry both `descriptionEn` and `descriptionPl` fields, populated at seed time; neither SHALL be blank. |
| DR-02 | Every `CornucopiaCardEntity` SHALL carry a `contentSha256` value matching the entry recorded for its source file in `hashes.json` at seed time. |
| DR-03 | Every `MitigationEntity` SHALL have at least 5 associated `CodeSampleEntity` rows (one per required language: Python, Java, Go, Scala, Lua), verified by an automated `Kotest` property test over the seeded dataset. |
| DR-04 | Card entities originating from `dbd-cards-1.0-en.yaml` SHALL be persisted with `kind = CardKind.DesignHarm` and SHALL NOT carry a non-null severity value anywhere in the data pipeline. |
| DR-05 | `CrossReferenceEntity` rows SHALL only reference `threatCode` values that exist in the seeded `ThreatEntity` table (validated by a seed-time consistency check that fails fast on a dangling reference). |

---

## 6. Abuse Case Requirements

| ID | Abuse Case | Required Defense |
|---|---|---|
| AC-01 | A malicious co-installed app attempts to invoke or bind to one of this app's `Activity`/`Service`/`BroadcastReceiver`/`ContentProvider` components. | SR-01 (all components unexported except the launcher) |
| AC-02 | A future contributor sets `ignoreUnknownKeys = true` "to fix a parsing crash" after a card-deck schema change, silently permitting malformed or injected fields into seeded content. | SR-04 + a `detekt` custom rule forbidding this flag |
| AC-03 | A developer reads a `CardKind.DesignHarm` card through code that assumes every card has a severity, causing a "Digital-by-Default Harms" item to display a fabricated or default severity. | SR-03 (exhaustive `when` expression, compiler-enforced) |
| AC-04 | An attacker with physical/ADB access to a rooted or debuggable device attempts to extract the Firestore sync token via `adb backup`. | SR-09, SR-15 |
| AC-05 | A pull request introduces a Room DAO method using `rawQuery` with string-concatenated filter input, reintroducing a SQL-injection-shaped code path. | SR-08, code review, `detekt` custom rule |
| AC-06 | A user copies an `ATTACK_DEMO` code sample directly into a production project without recognizing it as intentionally vulnerable. | SR-06 (warning badge + acknowledgement dialog) |
| AC-07 | A vulnerable transitive Gradle dependency (e.g., a compromised or CVE-flagged library) is introduced via a routine dependency bump PR. | SR-11 (`dependency-check-gradle` in CI) |
| AC-08 | A tampered or corrupted YAML card-deck file is merged into `assets/cornucopia/` via a compromised or careless PR. | SR-14 (CODEOWNERS review) + SR-05 (hash verification at seed time) |

---

## 7. Traceability Matrix (excerpt)

| Requirement | User Story | Design Decision |
|---|---|---|
| FR-19, SR-03 | US-19 | D-03 (`sealed interface CardKind`) |
| FR-10 | US-10 | D-01, D-02 (Android sandbox, exported-component discipline) |
| FR-18 | all (cross-cutting) | D-05 (`LocaleController`) |
| FR-02 | US-02 | D-04 (Room `@Query` compile-time verification) |
| FR-23, SR-09, SR-10 | — (optional feature) | D-07 (Google Sign-In + Firestore) |
| SR-04 | US-05–US-12, US-19 | D-06 (`kotlinx.serialization`/`kaml` strict decoding) |
| SR-01, SR-02 | — (platform-wide) | D-01, D-02 |

Full matrix (all 19 user stories × all FR/SR/NFR/C/DR/AC IDs) is maintained in the project's issue tracker, mirroring the structure used in `app11_swift_ios/requirements.md`.

---

## 8. Glossary

| Term | Definition |
|---|---|
| KSP | Kotlin Symbol Processing — the annotation-processing framework Room uses to generate DAO implementations and verify `@Query` SQL at compile time. |
| Sealed interface | A Kotlin type whose full set of implementers is known at compile time within the same module, enabling exhaustiveness checking in `when` expressions. |
| Exported component | An Android `Activity`/`Service`/`BroadcastReceiver`/`ContentProvider` reachable by other apps on the device, either explicitly (`android:exported="true"`) or implicitly (via an `<intent-filter>` on API levels before the exported attribute became mandatory). |
| Keystore | The Android hardware-backed (where available) secure key storage system, used here to protect the optional Firestore sync token. |
| R8 | Android's default code shrinker/obfuscator/optimizer for release builds, successor to ProGuard. |
| Firestore Security Rules | Google Cloud Firestore's declarative, server-enforced per-document access-control language. |
| Cornucopia (deck) | An OWASP card-game-format threat-elicitation methodology; this project consumes six such decks (Website App, Mobile App, Companion, STRIDE/EoP, MLSec, Digital-by-Default Harms) as structured YAML content. |
| CardKind | This project's own Kotlin type distinguishing technical-vulnerability cards (which carry a `Severity`) from design-harm cards (which structurally cannot). |
