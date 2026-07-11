# SwiftGuard 2026 — native iOS implementation (app11_swift_ios)

Pure native iOS: Swift 6, SwiftUI, SwiftData. See `../CLAUDE.md` for the sibling list —
this app is one of the two (with `app12_kotlin_android`, its structural twin) that
deliberately don't follow the shared API contract documented there.

## This is NOT a client of app01's REST API — don't build an API client

Unlike every sibling from `app02` through `app10`, **this app has no client-server model
at all.** Per `PLAN.md` §0 and §3: no backend framework, no REST API, no Postgres/MySQL,
no Docker Compose. All data — frameworks, threats, mitigations, card decks, code samples —
lives on-device in **SwiftData**, seeded from JSON/YAML bundled in `SwiftGuardApp/Resources/`
by `ContentSeeder` on first launch. There is no ongoing sync of core content with any
server, ever. The **only** network calls anywhere in this codebase would be Apple's own
Sign in with Apple + CloudKit frameworks for the *optional* cross-device bookmark-sync
feature (D-07) — **and even that is not implemented yet** (see below). Do not point this
app at app01's `/api/v1/...` endpoints; that contract is irrelevant here.

## Current state (verify against the filesystem before trusting this)

Planning docs (`PLAN.md`, `requirements.md`, `SDLC_analysis.md`, `user_stories+tests.md`)
were already excellent before this session and were kept largely intact — only a
`PLAN.md` §0.1 provenance section was added (what the shared `../docs/` source material
actually contains vs. what's curated/authored content) plus version bumps, rather than a
wasteful full rewrite of already-good content.

**Real Swift source now exists**, ported/adapted from app09's equivalent pipeline (same
underlying OWASP/Cornucopia content, same 50 five-language code samples — these are
language-agnostic educational content, reused rather than re-authored):

- **`SwiftGuardData/`** (local SPM package): all 8 `@Model` types from `PLAN.md` §5
  (`Framework`, `Threat`, `CornucopiaCard`, `Mitigation`, `CodeSample`, `CrossReference`,
  `ContentHash`, `Bookmark`) with real `@Relationship(inverse:)` wiring; `CardKind` (D-03,
  the enum-with-associated-values guarantee); hand-written `Decodable` decoders with a
  `DynamicKey`-based unknown-key check (D-06) for the six raw Cornucopia YAML decks;
  `ReferenceValidator` (allowlist check for curated OWASP/MITRE refs); `CardLoader`
  (merges raw YAML + curation JSON + Polish translations, rejects orphaned curation/
  translation entries referencing a nonexistent `card_id`); `IntegrityService` (SHA-256
  check against bundled `hashes.json`, upserts `ContentHash` records); `ContentSeeder`
  (the single entry point tying all of the above together); and SwiftData-backed
  repository implementations for every protocol in `PLAN.md` §7.
- **`SwiftGuardUI/`** (local SPM package): `LocalizationManager` (D-05 — tracks the
  current locale and the model layer's `localizedDescription(_:)` methods already use it
  correctly; the `Bundle.setLanguage`-style runtime swap for **UI-chrome** String Catalog
  strings is *not* implemented — see the scope note in `LocalizationManager.swift`), five
  `@Observable` ViewModels, and eleven SwiftUI Views covering `RootView`'s `TabView` shell,
  framework/threat/card browsing, threat detail (mitigations + tabbed code samples +
  cross-references), the Digital-by-Default Harms view (structurally cannot render a
  severity badge — `CardKind.severity` is `nil` for every card here), search, bookmarks,
  and about.
- **`SwiftGuardApp/SwiftGuardApp.swift`**: the `@main` composition root — builds the
  `ModelContainer`, runs `ContentSeeder` once at launch, injects `LocalizationManager`.

**Content scope, same representative-slice pattern as every prior sibling in this
series:** 20 threats (OWASP Web Top 10 + LLM Top 10, in full), a representative sample of
curated cards per deck (not every card in any deck), and 5 mitigations (not most threats
have one) — each with a real attack-demo + defense code sample in Python/Java/Go/Scala/
Lua. Every other framework family (Agentic AI, API, Client-Side, CI/CD, OAT, MASVS) exists
as a catalogue row with no seeded threats yet.

**The test suite is now real** (previously both `SwiftGuardTests`/`SwiftGuardUITests` were
empty directories):

- **`SwiftGuardData/Tests/SwiftGuardDataTests/`** (package-level, runnable via `swift test`
  alone — no Xcode/simulator needed at all): `TestSupport.inMemoryContainer(seeded:)` seeds
  from the REAL bundled content, not a synthetic duplicate — every item under
  `Tests/SwiftGuardDataTests/` (`Cornucopia/`, `frameworks.json`, etc.) is a **symlink**
  into `../../SwiftGuardApp/Resources`, copied into the test bundle at build time via
  `Package.swift`'s `resources:` list, so `Bundle.module` sees the exact same files
  `SwiftGuardApp` would. Covers: `CardKind` (D-03), `Hashing` (real SHA-256 vectors),
  `CardFile`/raw-YAML decoding (D-06 unknown-key rejection at every nesting level),
  `CurationFileLoader` (`_comment` filtering), `ReferenceValidator` (real allowlists),
  `CardLoader` (real 6-deck `loadAll()`, plus fixture-based negative cases via a
  `Bundle(url:)`-backed temp-directory bundle), `IntegrityService` (real hashes all valid,
  upsert-not-duplicate), `ContentSeeder` end to end (realistic counts: ≥10 frameworks, 20
  threats, 5 mitigations, idempotent re-seed), all 7 repository implementations, and 2
  `SwiftCheck` property tests (every seeded mitigation has all 5 languages, each with both
  an attack-demo and a defense sample) — `Package.swift` adds `SwiftCheck` and `Yams` as
  test-target dependencies for this.
  - **A real bug was caught and fixed while writing these tests**: `CardLoader.buildSeed`
    used to `throw .missingCuratedSeverity` for ANY card with no curation entry at all —
    since only a representative slice of each deck is curated (e.g. the real `webapp` deck
    has 80 raw cards but only 14 curated), this meant `ContentSeeder.seedIfNeeded()` would
    have crashed immediately if ever actually run. Fixed so an uncurated card is silently
    skipped (the common, expected case) while a curated-but-malformed-severity entry still
    throws (a real data bug, correctly still fatal) — see the doc comment on
    `CardLoader.buildSeed`. The identical bug was also fixed in `app12_kotlin_android`'s
    Kotlin port of this same loader.
- **`SwiftGuardUI/Tests/SwiftGuardUITests_Unit/`** (package-level): `LocalizationManager`
  (locale switching, invalid-code fallback), and all 5 `ViewModel`s against a small
  hand-inserted in-memory dataset (no bundle needed) — including an `async` test proving
  `ThreatBrowserViewModel.searchText`'s ~300ms debounce genuinely delays filtering while
  `severityChanged()` applies immediately.
- **Top-level `SwiftGuardTests/`** (app-target, PLAN.md §9's "XCTest + SwiftCheck on
  SwiftGuardData") is deliberately left empty: the package-level `SwiftGuardDataTests`
  above already covers everything that role would, via the resource-symlink trick, and
  running entirely through `swift test` is strictly more portable than requiring the
  (still-nonexistent) Xcode project — don't fill this in as a redundant duplicate.
- **Top-level `SwiftGuardUITests/`** has 2 representative `XCUITest` files
  (`US01FrameworksUITests.swift`, `US03ThreatDetailUITests.swift`) — real source,
  consistent with real `.accessibilityIdentifier` values now added to
  `RootView`/`FrameworkListView`/`ThreatBrowserView`/`CodeSamplePanelView` specifically for
  this (English, stable identifiers, deliberately decoupled from the visible Polish
  labels). The other 17 user stories' XCUITest files are not written yet — same
  representative-slice pattern as the content scope above, not an oversight.
- **Still blocked on the missing `.xcodeproj`**: none of the above can actually execute end
  to end as "launch the real app and drive its UI" until someone creates the Xcode project
  (see below) — `swift test` on the two SPM packages is the only thing runnable today.

**Not built at all:**
- **No `.xcodeproj` exists.** Unlike everything else in this repo, a `project.pbxproj` is
  fragile to hand-author correctly without Xcode itself actually generating it — this was
  deliberately not attempted. Someone needs to open Xcode, create a new iOS App project
  targeting iOS 17+, add `SwiftGuardData`/`SwiftGuardUI` as local Swift Package
  dependencies, add `SwiftGuardApp.swift` and `Resources/` to the app target, wire up
  `SwiftGuardUITests` as a real UI test target, and wire up the entitlements file
  (`com.apple.developer.icloud-services` only, per D-01 — nothing else, not even if
  Xcode's project wizard defaults add more).
- **Nothing has been compiled.** No Swift toolchain exists in the environment this was
  written in — every file here is real, structurally-checked-by-hand Swift (brace-balanced,
  cross-referenced for dangling type names), but none of it has been run through `swiftc`,
  `swift test`, or Xcode. Treat it the same as app09's Docker Compose files:
  unverified-but-real source — including the test suite itself.
- `SyncCoordinator`/CloudKit sync (D-07), `BGAppRefreshTask` periodic re-verification,
  export (`.fileExporter`/`UIActivityViewController`), the MITRE ATLAS kill-chain
  `Canvas`/`Chart` timeline, matrix/heatmap Views (the `SwiftDataMatrixRepository` backing
  them exists in `SwiftGuardData`, but no `MatrixLlmView`/`StrideHeatmapView`/etc. consume
  it yet), `SwiftLint` config, and 17 of the 19 planned per-user-story XCUITest files.

## Architecture decisions to know before writing more code (see `PLAN.md` §2–§5)

- **Min iOS 17.0+** — required for SwiftData and the `Observation` framework.
- **Persistence**: SwiftData `@Model` classes over an embedded SQLite store, queried via
  the compile-time-checked `#Predicate` macro — there is no SQL string anywhere in this
  codebase, so SQL injection isn't a class this app needs to defend against at all. Optional
  filters use the "`filter == nil || property == filter!`" pattern inside one `#Predicate`
  expression (see `SwiftDataThreatRepository.list(filter:)`) rather than runtime-composed
  query building, since `#Predicate` can't be assembled incrementally at runtime.
- **Two local Swift packages** (`SwiftGuardData`/`SwiftGuardUI`) give Swift's `internal`
  access control real cross-target teeth (D-02) — a single app target has no such boundary
  on its own. `IntegrityService` is called only from `ContentSeeder`; nothing in
  `SwiftGuardUI` should ever import it directly.
- **`Codable` gotcha (D-06)**: Swift's synthesized `Decodable` silently ignores
  unrecognized JSON/YAML keys by default. Every Cornucopia YAML decoder in
  `SwiftGuardData/Sources/SwiftGuardData/Cards/` hand-writes `init(from:)` with a
  `DynamicKey` container specifically to reject unknown fields instead.
- **`enum` + exhaustive `switch`** (D-03, `CardKind`) is a hard, unconfigurable compiler
  error for missed cases — the strongest guarantee in this series alongside Rust/Haskell.
- **No job queue**: nothing here has been wired up for background work yet at all (see
  "Not built" above) — `BGAppRefreshTask`/export are still just `PLAN.md` §6 Phase 6 plans.

## What replaces the tooling other siblings have

No `scripts/`, `nginx`, or `docker-compose.yml` — local development needs **Xcode 15+ and
the iOS Simulator** instead (once the `.xcodeproj` above exists): build/run via
`xcodebuild`/`xcrun simctl` or Xcode itself, test via `XCTest` + `SwiftCheck` +
`XCUITest` (replaces Playwright), lint via `SwiftLint`, static analysis via Xcode's
`Product ▸ Analyze`. None of this is set up yet either.

## Where to look for more depth

`PLAN.md` is the primary source (§0.1 source-material provenance, architecture §2–§9, risk
register §13, phased build plan §6). `requirements.md` has the functional requirements;
`user_stories+tests.md` has full acceptance criteria, TDD test plans, and real
Polish-translated Cornucopia card examples per user story; `SDLC_analysis.md` covers the
SSDLC/threat-modeling angle this app's own content doubles as (OWASP MASVS, Mobile
Cornucopia deck).
