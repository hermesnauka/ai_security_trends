# KotlinGuard 2026 — running this app

This is a **native, offline-only Android app** (Kotlin + Jetpack Compose + Room). It has
**no backend, no REST API, and no server component of any kind** — see `CLAUDE.md`/`PLAN.md`
§0 for why. There is nothing to `docker compose up` and nothing to run "backend + frontend
together"; the entire application is a single Android app process.

## Prerequisites

- **Android Studio** (Ladybird/Koala or newer) — includes a matching JDK and lets you install
  the Android SDK components below through its SDK Manager. A standalone Gradle + Android SDK
  install also works if you'd rather not use the IDE.
- **Android SDK**: platform + build-tools for **API 35**, plus **API 26+** for the emulator/
  device you test against (this project's `minSdk` is 26, `targetSdk` is 35).
- **JDK 17+** (required by AGP 8.6.0 / Kotlin 2.0.20).
- A **Gradle 8.x wrapper** — this repo does not commit a `gradlew`/`gradle-wrapper.jar`; open
  the project in Android Studio first and let it generate one, or run
  `gradle wrapper --gradle-version 8.9` yourself once a modern Gradle is available. The
  `gradle` binary that may already be on your `PATH` could be a much older, incompatible
  version — check `gradle --version` reports 8.x before relying on it directly.

## Build & test

Once the wrapper exists and the Android SDK is installed:

```bash
# Unit + property tests for the data layer (JUnit4 + Robolectric, real Room/SQLite via Robolectric)
./gradlew :data:test

# Unit tests for the presentation layer (JUnit4 + hand-written fakes, no Android runtime needed)
./gradlew :ui:test

# Both together
./gradlew test

# Assemble a debug APK
./gradlew :app:assembleDebug

# Instrumented Compose UI tests — needs a connected device or running emulator (API 26+)
./gradlew :app:connectedAndroidTest

# Install and launch on a connected device/emulator
./gradlew :app:installDebug
```

**Status as of 2026-07-11: none of the above has actually been run in this repo's own dev
environment.** See `CLAUDE.md` for the full explanation — a `gradle`/`java` binary happens to
exist on that machine, but it resolves to Gradle 4.4.1 (from 2012), there's no Android SDK
installed, and no wrapper is committed here, so this project cannot build there. Every source
file is real and structurally hand-checked, but treat "it builds" and "tests pass" as
unverified until you actually run the commands above with a proper Android Studio setup.

## What you'll see if it builds

On first launch, `KotlinGuardApplication` seeds the Room database from bundled JSON/YAML
assets under `app/src/main/assets/` (frameworks, 20 threats, 6 Cornucopia card decks, 5
mitigations × 5 language code samples). `MainActivity` shows a loading state until seeding
completes, then hosts `RootScreen`'s bottom-navigation shell (Frameworks · Threats · Search ·
Bookmarks · About). Toggle the language (Polish default, English available) from the in-app
locale control — no restart required.

## No frontend/backend split

Everything above — persistence (Room/SQLite), business logic, and the Compose UI — runs in
this one app. The only place this app ever talks to a network at all is the optional,
not-yet-implemented Google Sign-In + Cloud Firestore bookmark-sync feature (`PLAN.md` D-07);
core content works entirely offline with the `INTERNET` permission absent.
