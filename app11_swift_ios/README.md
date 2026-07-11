# SwiftGuard 2026 (app11_swift_ios)

Native iOS app (Swift 6, SwiftUI, SwiftData). **There is no backend and no server to run** —
see `../CLAUDE.md` and this directory's own `CLAUDE.md` for why: all content lives on-device,
seeded from bundled JSON/YAML on first launch. Do not look for a `docker-compose.yml` or a
`scripts/local-dev-up.sh` here; there isn't one, by design.

## What you can actually run today

**No `.xcodeproj` exists in this repo** (see `CLAUDE.md` "Not built at all"), so there is no
way to launch the full app in the iOS Simulator yet. What *is* real and runnable is the two
local Swift packages' test suites, via the Swift command-line toolchain alone — no Xcode, no
simulator required.

### Prerequisites

- Swift 6 toolchain (`swift --version` should report 6.0+; install via Xcode 15+ or the
  standalone [swift.org](https://swift.org) toolchain on Linux/macOS).
- No database, no Docker, no Node — this is entirely self-contained.

### Run the data-layer test suite (`SwiftGuardData`)

```sh
cd SwiftGuardData
swift test
```

This exercises `CardKind`, `Hashing`, the Cornucopia YAML decoders (`CardFile`/`CardLoader`),
`ReferenceValidator`, `IntegrityService`, `ContentSeeder` end-to-end, all 7 repository
implementations, and 2 `SwiftCheck` property tests — against the real bundled seed content
(`Tests/SwiftGuardDataTests/*` are symlinks into `../SwiftGuardApp/Resources/`, not synthetic
fixtures), entirely through `swift test`.

### Run the UI-layer test suite (`SwiftGuardUI`)

```sh
cd SwiftGuardUI
swift test
```

This exercises `LocalizationManager` and all 5 `@Observable` ViewModels against a small
hand-inserted in-memory dataset — no bundle, no simulator needed.

### What you cannot run yet

- **The actual app** (`SwiftGuardApp/SwiftGuardApp.swift`, the `@main` entry point) and its 11
  SwiftUI Views cannot be launched — that requires an Xcode project (`.xcodeproj`) that adds
  `SwiftGuardData`/`SwiftGuardUI` as local package dependencies and wires up an iOS app target,
  which does not exist in this repo yet (see `CLAUDE.md` for exactly what someone would need to
  do in Xcode to create it).
- **The 2 XCUITest files** under `SwiftGuardUITests/` (`US01FrameworksUITests.swift`,
  `US03ThreatDetailUITests.swift`) likewise need a real UI test target inside that
  not-yet-created Xcode project, plus a Simulator, to execute.
- Nothing in this app has ever been compiled in the environment it was authored in (no Swift
  toolchain was available there) — treat all source as real but unverified until you run
  `swift test` yourself.

## Where to look for more

`CLAUDE.md` has the full current-state breakdown; `PLAN.md` §2–§9 has the architecture and
file layout; `requirements.md` has the FR/SR/NFR list; `user_stories+tests.md` has acceptance
criteria per user story.
