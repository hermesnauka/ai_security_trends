# KotlinGuard 2026 — Kotlin/Android implementation (app12_kotlin_android)

Native Android: Kotlin 2.0, Jetpack Compose, Room. See `../CLAUDE.md` for the sibling
list — this app is one of the two (with `app11_swift_ios`, its structural twin) that
deliberately don't follow the shared API contract documented there.

## This is NOT a client of app01's REST API — don't build an API client

Unlike every sibling from `app02` through `app10`, **this app has no client-server model
at all.** Per `PLAN.md` §0 and §3: no backend framework, no REST API, no Postgres/MySQL,
no Docker Compose. All data — frameworks, threats, mitigations, card decks, code samples —
lives on-device in **Room** (embedded SQLite), seeded from JSON/YAML bundled under
`app/src/main/assets/` by `ContentSeeder` on first launch. There is no ongoing sync of
core content with any server, ever. The **only** network calls anywhere in this codebase
would be an *optional*, later-phase Google Sign-In + Cloud Firestore bookmark-sync feature
(D-07) — **not implemented yet** (see below). Do not point this app at app01's
`/api/v1/...` endpoints; that contract is irrelevant here.

## Current state (verify against the filesystem before trusting this)

Planning docs (`PLAN.md`, `requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md`)
were already excellent before this session and were kept largely intact — only a
`PLAN.md` §0.1 provenance section was added (what the shared `../docs/` source material
actually contains vs. what's curated/authored content) plus version bumps, rather than a
wasteful full rewrite of already-good content.

**Real Kotlin source now exists**, ported/adapted from app09's and app11's equivalent
pipelines (same underlying OWASP/Cornucopia content, same 50 five-language code samples —
language-agnostic educational content, reused rather than re-authored) as a genuine
three-module Gradle project (`:data`, `:ui`, `:app`, PLAN.md §9):

- **`:data`**: all 8 `@Entity` classes from `PLAN.md` §5 (`FrameworkEntity`,
  `ThreatEntity`, `CornucopiaCardEntity`, `MitigationEntity`, `CodeSampleEntity`,
  `CrossReferenceEntity`, `ContentHashEntity`, `BookmarkEntity`) with Room
  `@TypeConverter`s for list/enum-hierarchy columns; `CardKind` (D-03, the `sealed
  interface` exhaustive-`when` guarantee); kotlinx.serialization + kaml decoders for the
  six raw Cornucopia YAML decks — no hand-written unknown-key check needed here (D-06:
  kotlinx.serialization/kaml reject unrecognized keys by default, the opposite of Swift's
  lenient `Codable`); `ReferenceValidator` (allowlist check for curated OWASP/MITRE refs);
  `CardLoader` (merges raw YAML + curation JSON + Polish translations, rejects orphaned
  curation/translation entries referencing a nonexistent `card_id`); `IntegrityChecker`
  (SHA-256 check against bundled `hashes.json` using `java.security.MessageDigest`,
  upserts `ContentHashEntity` rows); `ContentSeeder` (the single entry point tying all of
  the above together, called from the `:app` composition root); Room `@Dao` interfaces for
  all 8 entities; and Room-backed repository implementations for every contract in
  `PLAN.md` §7 (`RoomFrameworkRepository`, `RoomThreatRepository`, `RoomCardRepository`,
  `RoomMitigationRepository`, `RoomMatrixRepository`, `RoomSearchRepository`,
  `RoomBookmarkRepository`); a `DataContainer` manual composition class (no Hilt/Koin —
  PLAN.md never asked for a DI framework).
- **`:ui`**: `LocaleManager` (D-05 — a `@Stable` Compose state holder tracking the
  current locale; the model layer's `localizedDescription(locale)` methods already use it
  correctly, but Android's `AppCompatDelegate.setApplicationLocales` per-app-locale wiring
  for UI-chrome `strings.xml` resources is *not* implemented — same scope gap as app11's
  `LocalizationManager`), six `ViewModel`s (`FrameworkListViewModel`,
  `ThreatBrowserViewModel` with a 300ms debounce, `ThreatDetailViewModel`,
  `CardSuitViewModel`, `SearchViewModel`, `BookmarksViewModel`), and Compose screens
  covering `RootScreen`'s bottom-navigation shell, framework/threat/card browsing, threat
  detail (mitigations + language-tabbed code samples with a `D-08` attack-demo
  confirmation dialog + cross-references), the Digital-by-Default Harms screen
  (structurally cannot render a severity badge — `CardKind.severityOrNull()` is `null` for
  every card here), search, bookmarks, and about.
- **`:app`**: `KotlinGuardApplication` (the composition root — builds `DataContainer`,
  launches `ContentSeeder.seedIfNeeded()` on a background dispatcher since Room forbids
  main-thread DB access, unlike SwiftData's `@MainActor`-bound context) and
  `MainActivity` (shows a loading spinner until seeding completes, then hosts
  `RootScreen` via `ComponentActivity.setContent`).
- Gradle wiring: root `build.gradle.kts`/`settings.gradle.kts`, per-module
  `build.gradle.kts` (AGP 8.6.0, Kotlin 2.0.20, KSP 2.0.20-1.0.25, Room 2.6.1,
  kotlinx-serialization 1.7.3, kaml 0.61.0, Compose BOM 2024.10.00, Navigation Compose
  2.8.3), `AndroidManifest.xml`, launcher adaptive icon, and `values`/`values-pl`
  `strings.xml`.

**Content scope, same representative-slice pattern as every prior sibling in this
series:** 20 threats (OWASP Web Top 10 + LLM Top 10, in full), a representative sample of
curated cards per deck (not every card in any deck), and 5 mitigations (not most threats
have one) — each with a real attack-demo + defense code sample in Python/Java/Go/Scala/
Lua. Every other framework family (Agentic AI, API, Client-Side, CI/CD, OAT, MASVS) exists
as a catalogue row with no seeded threats yet.

**The test suite is now real** (previously `data/src/test`/`app/src/androidTest` were both
empty directories):

- **`data/src/test/kotlin/`** (JVM unit tests — `FileAssetSource` reads the REAL bundled
  content directly via a relative filesystem path into `../app/src/main/assets/`, not a
  synthetic duplicate, so tests assert realistic facts: ≥10 frameworks, 20 threats, 5
  mitigations, all 5 languages per mitigation): `CardKind`, `Hashing` (real SHA-256
  vectors), `CardFile`/kaml YAML decoding (D-06 unknown-key rejection at every nesting
  level, no Robolectric needed — pure kotlinx.serialization), `CurationFileLoader`,
  `ReferenceValidator` (real allowlists), `CardLoader` (real 6-deck `loadAll()` plus
  fixture-based negative cases via a temp-directory `FileAssetSource.fixture(...)`),
  `IntegrityChecker`, `ContentSeeder` end to end, all 7 repositories, and 2 property tests
  (Kotest's `Arb`/`checkAll`, used as a plain library call inside ordinary JUnit4 `@Test`s —
  not via Kotest's own Spec/JUnit5 runner, to avoid mixing two test frameworks in one
  module).
  - **Room fundamentally needs an Android runtime** (unlike SwiftData, a pure
    Swift/Foundation library — app11_swift_ios's equivalent tests run under plain `swift
    test` alone) — every Room-touching test class here uses **Robolectric**
    (`@RunWith(RobolectricTestRunner::class)`, `@Config(sdk = [34])`,
    `Room.inMemoryDatabaseBuilder(...).allowMainThreadQueries()`) to get real SQL execution
    without a connected device/emulator. This is a genuine, unavoidable architectural
    difference from app11's twin test suite, not an oversight — see `data/build.gradle.kts`
    for the full JUnit4 + Robolectric + androidx.test dependency set this required.
  - **A real bug was caught and fixed while writing these tests**: `CardLoader.buildSeed`
    used to fail on ANY card with no curation entry — since only a representative slice of
    each deck is curated (e.g. the real `webapp` deck has 80 raw cards but only 14
    curated), `ContentSeeder.seedIfNeeded()` would have crashed immediately if ever
    actually run. Fixed so an uncurated card is silently skipped (the common, expected
    case) while a curated-but-malformed-severity entry still throws (a real data bug,
    correctly still fatal) — identical fix also made in app11_swift_ios's Swift port of
    this same loader, discovered there first.
  - **A second real bug, found the same way**: `CardDecodeError`'s subclasses
    (`UnknownReference`, `OrphanCurationEntry`, `MissingCuratedSeverity`,
    `MissingRequiredField`) took constructor parameters that were never declared `val` —
    meaning no caller could ever actually read `.value`/`.field`/`.cardId` off a caught
    exception. Fixed to expose them as properties.
- **`ui/src/test/kotlin/`** (JVM unit tests, deliberately Robolectric-free): ViewModels
  depend only on `:data`'s Repository *interfaces*, so they're tested against
  hand-written in-memory fakes (`FakeFrameworkRepository`, `FakeThreatRepository`, etc. in
  `support/FakeRepositories.kt`) — no Room, no Android runtime needed at all for this
  module. `MainDispatcherRule` installs a shared `TestDispatcher` as `Dispatchers.Main` so
  `viewModelScope.launch` work is deterministically controllable; the debounce test for
  `ThreatBrowserViewModel`/`SearchViewModel` uses `advanceTimeBy` (virtual time — instant,
  no wall-clock wait), an improvement over app11_swift_ios's equivalent test, which does a
  real ~450ms `Task.sleep` since Swift's `Task.sleep` isn't virtual-time controllable the
  way a `TestDispatcher` is.
  - **A third real bug, found while trying to write these tests at all**:
    `ThreatDetailViewModel` depended on the concrete `DataContainer` class directly (plus a
    redundant, inconsistent `dataContainer.bookmarkRepository` reference alongside its own
    separately-injected `bookmarkRepository` parameter) — making it impossible to unit-test
    with a fake. Fixed by adding a proper `CodeSampleRepository` interface +
    `RoomCodeSampleRepository` (Room entities have no live relationship traversal the way
    SwiftData's `Mitigation.codeSamples` does, so this abstraction is what fills that gap),
    and having the ViewModel depend on that instead of `DataContainer`.
- **`app/src/androidTest/kotlin/`** has 2 representative Compose UI tests
  (`US01FrameworksUiTest.kt`, `US03ThreatDetailUiTest.kt`) — real source, consistent with
  real `Modifier.testTag(...)` values now added to
  `RootScreen`/`FrameworkListScreen`/`ThreatBrowserScreen`/`CodeSamplePanel` specifically
  for this. **Cannot run here**: Compose's instrumented UI-testing API needs a connected
  device/emulator, the same category of requirement as app11_swift_ios's XCUITest needing
  the iOS Simulator. The other 17 user stories' UI tests are not written yet — same
  representative-slice pattern as the content scope above, not an oversight.
- **Still not built**: Google Sign-In + Cloud Firestore bookmark sync (D-07), a
  `WorkManager` periodic re-verification job (the `BGAppRefreshTask` analogue), export
  (`Intent.ACTION_SEND`/`ShareSheet`), the MITRE ATLAS kill-chain timeline Composable,
  matrix/heatmap screens (the `RoomMatrixRepository` backing them exists in `:data`, but no
  `LlmMatrixScreen`/`StrideHeatmapScreen`/etc. consume it yet), and `detekt` config.
- **Nothing has actually been executed.** No Android SDK/Gradle/JDK toolchain exists in
  the environment this was written in — every file here, including the test suite itself,
  is real, structurally-checked-by-hand Kotlin, but none of it has been run through
  `./gradlew build`/`./gradlew test` or Android Studio. Treat it the same as app09's Docker
  Compose files and app11's Swift package: unverified-but-real source.

## Architecture decisions to know before writing more code (see `PLAN.md` §2–§5)

- **Min SDK 26 (Android 8.0)**, target SDK 35 — matches app11's iOS 17.0+ modernity bar.
- **Persistence**: Room over embedded SQLite, `@Query` SQL strings verified against the
  entity schema at **compile time** by the KSP annotation processor (D-04) — a
  column-name typo is a build error, not a runtime one, the strongest guarantee this
  layer claims. Optional filters use a `:param IS NULL OR column = :param` bound-parameter
  pattern (see `ThreatDao.list` in `db/Daos.kt`) — the SQL-string analogue of app11's
  single-`#Predicate` "`filter == nil || ...`" expression. `stride`/`tags` columns store a
  kotlinx.serialization JSON array as TEXT (Room has no native array-column type), so
  matching one element is a documented `LIKE '%"X"%'` substring check — less type-safe
  than SwiftData's native `Array.contains` in app11's equivalent query.
- **Three Gradle modules** (`:data`/`:ui`/`:app`) give Kotlin's `internal` visibility real
  cross-module teeth (D-02) — a single-module app has no such boundary on its own.
  `IntegrityChecker` is called only from `ContentSeeder`; nothing in `:ui` should ever
  import it directly.
- **kotlinx.serialization + kaml are strict-by-default (D-06)**: an unrecognized JSON/YAML
  key throws `SerializationException` — the opposite default from Swift's `Codable`, which
  silently ignores unknown keys unless a custom decoder is hand-written. This app gets the
  D-06 guarantee "for free" from the library default; never set `ignoreUnknownKeys = true`
  or pass a lenient `YamlConfiguration`.
- **`sealed interface` + exhaustive `when`** (D-03, `CardKind`) is a hard, unconfigurable
  compiler error for missed branches — the strongest guarantee in this series alongside
  Rust/Haskell/Swift. It is structurally impossible to construct a `DesignHarm` card
  carrying a `Severity` — there is no such constructor.
- **No background job wired up yet at all** (see "Not built" above) — `WorkManager`/export
  are still just `PLAN.md` §6 Phase 6 plans.
- Room's built-in enum-to-`TEXT` column support (since Room 2.4) is used directly for
  simple enums (`Severity`, `CodeLanguage`, `MitigationType`, etc.) — only `List<T>` and
  the `CardKind` sealed interface need a hand-written `Converters` class
  (`db/Converters.kt`), since Room has no native support for either shape.

## What replaces the tooling other siblings have

No `scripts/`, `nginx`, or `docker-compose.yml` — local development needs **Android
Studio** (or a standalone Gradle + Android SDK install) instead: build/run via
`./gradlew assembleDebug` / `./gradlew installDebug` targeting an emulator or device
(API 26+), unit-test via `./gradlew :data:test :ui:test` (JUnit4 + Robolectric for
Room-backed `:data` tests, plain JUnit4 + fakes for `:ui`), instrumented-test via
`./gradlew :app:connectedAndroidTest` (Compose UI testing — replaces Playwright, needs a
device/emulator), lint via `detekt`. None of this has actually been run here either — see
"Not built" above.

## Where to look for more depth

`PLAN.md` is the primary source (§0.1 source-material provenance, architecture §2–§9, risk
register §13, phased build plan §6). `requirements.md` has the functional requirements;
`user_stories+tests.md` has full acceptance criteria, TDD test plans, and real
Polish-translated Cornucopia card examples per user story; `SDLC_analysis.md` covers the
SSDLC/threat-modeling angle this app's own content doubles as (OWASP MASVS, Mobile
Cornucopia deck).
