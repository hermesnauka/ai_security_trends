# SwiftGuard 2026 — native iOS implementation (app11_swift_ios)

Pure native iOS: Swift 6, SwiftUI, SwiftData. No code exists yet — no Xcode
project, no `.swift` files, nothing scaffolded. This directory currently holds
only `PLAN.md`, `requirements.md`, `SDLC_analysis.md`, and
`user_stories+tests.md`, describing a large aspirational 19-user-story end
state (§15 of `PLAN.md`). Building from scratch starts with `xcodegen`/Xcode's
"New Project", not by editing existing sources. See `../CLAUDE.md` for the
sibling list — this app is one of the two (with `app12_kotlin_android`) that
deliberately don't follow the shared API contract documented there.

## This is NOT a client of app01's REST API — don't build an API client

Unlike every sibling from `app02` through `app10` (and unlike
`app06_HASKELL_react`, whose own CLAUDE.md mirrors app01's `/api/v1/...`
contract), **this app has no client-server model at all.** Per `PLAN.md` §0
and §3: no backend framework, no REST API, no Postgres/MySQL, no Docker
Compose. All data — frameworks, threats, mitigations, card decks, code
samples — lives on-device in **SwiftData**, seeded from **JSON/YAML bundled
in the app resources** by a `ContentSeeder` on first launch (`PLAN.md` §3,
§6 Phase 1). There is no ongoing sync of core content with any server, ever.

The **only** network calls anywhere in this codebase are Apple's own
**Sign in with Apple** + **CloudKit** frameworks, used exclusively for the
*optional* cross-device bookmark-sync feature (D-07, Phase 6) — and even that
is Apple-managed infrastructure this project's own code never implements.
Do not attempt to point this app at app01's `/api/v1/frameworks` or
`/api/v1/threats` endpoints; that contract is irrelevant here.

## Architecture decisions to know before writing any code (see `PLAN.md` §2–§5)

- **Min iOS 17.0+** — required for SwiftData and the `Observation` framework.
- **State**: `@Observable` macro + `@Bindable`/`@Environment`, no third-party
  state library.
- **Persistence**: SwiftData `@Model` classes (`Framework`, `Threat`,
  `CornucopiaCard`, `Mitigation`, `CodeSample`, `CrossReference`,
  `ContentHash`, `Bookmark` — full schema in `PLAN.md` §5) over an embedded
  SQLite store. Queries use the `#Predicate` macro, which is compile-time
  type-checked against `@Model` properties — there is no SQL string anywhere
  in this codebase, so SQL injection isn't a class this app needs to defend
  against at all.
- **Two local Swift packages**: `SwiftGuardData` (models, `ContentSeeder`,
  `IntegrityService`) and `SwiftGuardUI` (Views, ViewModels) — the package
  boundary is what gives Swift's `internal` access control real cross-target
  teeth (D-02), since a single app target has no such boundary on its own.
- **`Codable` gotcha (D-06)**: Swift's synthesized `Decodable` **silently
  ignores unrecognized JSON/YAML keys by default** — the opposite default
  from `app10_csharp_react`'s `YamlDotNet` (which rejects unknown fields
  unless explicitly loosened) and from app12's Kotlin/`kotlinx.serialization`
  equivalent. Every type decoding the six Cornucopia YAML decks needs a
  hand-written `init(from:)` with a `DynamicKey` container to reject unknown
  fields — this is not free here the way it is in some sibling stacks.
- **`enum` + exhaustive `switch`** (D-03) is a hard, unconfigurable compiler
  error for missed cases — same unconditional tier as Rust/Haskell, stronger
  than C#'s `CS8509` (a warning promotable to error, but revertable).
- **Localization**: in-app PL/EN toggle via a custom `LocalizationManager`
  (Bundle-swap technique), independent of iOS system language — not just
  String Catalog auto-localization.
- **No job queue**: exports (CSV/PDF) are generated synchronously on-device
  via `.fileExporter`/`UIActivityViewController`; periodic integrity
  re-verification uses `BGAppRefreshTask`, not a background worker service.

## What replaces the tooling other siblings have

There are no `scripts/`, no `nginx`, no `docker-compose.yml`, and none of
that will ever apply here. Local development needs **Xcode 15+ and the iOS
Simulator** instead: build/run via `xcodebuild`/`xcrun simctl` or Xcode
itself, test via `XCTest` + `SwiftCheck` (property-based) + `XCUITest`
(replaces Playwright — there's no browser to drive), lint via `SwiftLint`,
and static analysis via Xcode's `Product ▸ Analyze`.

## Where to look for more depth

`PLAN.md` is the primary source (architecture §2–§9, risk register §13,
phased build plan §6). `requirements.md` has the functional requirements;
`user_stories+tests.md` has full acceptance criteria and TDD test plans per
user story; `SDLC_analysis.md` covers the SSDLC/threat-modeling angle this
app's own content doubles as (OWASP MASVS, Mobile Cornucopia deck). Treat
`PLAN.md` §6's phase breakdown as the build order — Phase 1 (Xcode project +
two packages + SwiftData schema + `ContentSeeder`) comes before anything
else.
