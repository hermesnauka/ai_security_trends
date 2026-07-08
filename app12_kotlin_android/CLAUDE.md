# KotlinGuard 2026 — Kotlin/Android implementation (app12_kotlin_android)

The native Android implementation — Kotlin, Jetpack Compose, Room. See
`../CLAUDE.md` for the sibling list — this app is one of the two (with
`app11_swift_ios`) that deliberately don't follow the shared API contract
documented there. See `PLAN.md`, `requirements.md`, `SDLC_analysis.md`, and
`user_stories+tests.md` for the full 19-user-story aspirational end state.

## Nothing is built yet

This directory currently contains only the four planning docs plus `.gitignore`. **There
is no Gradle project, no `settings.gradle.kts`, no Android Studio project, no source
code at all.** Whoever starts building needs to scaffold the Gradle multi-module project
from scratch per PLAN.md §9 (`:data`, `:ui`, `:app` modules) before anything else is
possible. Don't assume any class, screen, or entity named in PLAN.md exists — treat every
code block in that file as a target, not a description of current state.

## Not a client of app01's API — this is fully on-device, offline-first

Unlike most siblings in this repo, this app has **no backend, no REST API, and (with one
narrow exception) no networking at all**. It never calls `app01_react`'s Spring Boot API
or any other sibling's backend. All framework/threat/card content ships as bundled
JSON/YAML assets under `app/src/main/assets/` and is loaded into a local Room (SQLite)
database by a `ContentSeeder` on first launch — see PLAN.md §3, §6 Phase 1, §12. The
**only** network-reachable code path in the entire app is an optional, later-phase
bookmark-sync feature (Google Sign-In + Cloud Firestore, D-07) — core content and every
other feature work with the `INTERNET` permission absent entirely.

## Structural twin: app11_swift_ios — read the two plans together

This app is the direct Android counterpart of `../app11_swift_ios` (native iOS, same
"no client-server model at all" departure). PLAN.md is written to be read *alongside*
app11's — most design-decision sections (§4, D-01 through D-08) explicitly call out
where Android's answer matches iOS's and where it genuinely differs. The one to
remember when writing serialization code: **`kotlinx.serialization`'s default `Json` is
strict-by-default** (`ignoreUnknownKeys = false` — an unrecognized key throws
`SerializationException`), the **opposite default** from Swift's `Codable`, which is
lenient-by-default and silently ignores unknown keys unless you write a custom decoder.
Never set `ignoreUnknownKeys = true` (PLAN.md D-06); a planned `detekt` rule is meant to
flag it if someone does.

## Architecture & key decisions (PLAN.md §2–§5)

- **Kotlin 2.1**, min SDK **API 26 (Android 8.0)**, target **API 35**.
- UI: **Jetpack Compose** (Material 3). State: `ViewModel` + `StateFlow` — no MVI
  framework, no third-party state library. Data flows `Compose UI → ViewModel
  (StateFlow) → Repository → Room DAO`.
- Persistence: **Room** over embedded SQLite. `@Query` SQL strings are parsed and
  verified against the entity schema at **compile time** via KSP (D-04) — this is the
  strongest SQL-safety guarantee claimed anywhere in this Room layer; never bypass it
  with `SupportSQLiteDatabase.rawQuery` + string concatenation.
- Core entities (PLAN.md §5): `FrameworkEntity`, `ThreatEntity`, `CornucopiaCardEntity`
  (uses a `sealed interface CardKind` — D-03 — for the exhaustive
  technical-threat-vs-design-harm distinction), `MitigationEntity`, `CodeSampleEntity`,
  `CrossReferenceEntity`, `ContentHashEntity` (SHA-256 integrity check on seeded assets),
  `BookmarkEntity` (the only user-generated, sync-eligible row).
- Every `AndroidManifest.xml` component is `android:exported="false"` except the
  launcher `MainActivity` (D-02) — Android's IPC surface is called out in PLAN.md as a
  risk category with no iOS equivalent; don't add an exported component without a
  documented reason.
- i18n: in-app `LocaleController` (D-05) using `AppCompatDelegate.setApplicationLocales`
  for instant PL/EN switching, not system-locale-following.

## Tooling: no scripts/nginx/docker — this needs Android Studio instead

There is no server, so there's nothing to `docker compose up`. To do anything with this
app you need: **Android Studio** (or a standalone Gradle + Android SDK/NDK install), a
configured **Android emulator** (or physical device) targeting API 26+, and KSP wired
into Gradle for Room's annotation processing. CI (per PLAN.md §2) runs on GitHub
Actions using Ubuntu or macOS runners with the Android SDK/Gradle toolchain — no
platform-specific host requirement the way `app11_swift_ios`'s macOS-only CI has.
