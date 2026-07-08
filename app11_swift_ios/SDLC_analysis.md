# SwiftGuard 2026 — SSDLC / SDLC Analysis

**Version:** 1.0
**Date:** 2026-07-07
**Document type:** Secure Software Development Lifecycle (SSDLC) analysis, mapped against the classic SDLC
**Scope:** Full lifecycle analysis of the application defined in `PLAN.md`, `requirements.md`, and `user_stories+tests.md`
**Methodology:** Agile — Scrum for planning/cadence, Kanban overlay for the engineering + security workflow
**Dotyczy:** US-01 – US-19 / Swift 6, SwiftUI + SwiftData, native iOS, no server backend

---

## Executive Summary

SwiftGuard 2026 carries the same double obligation as its sibling projects (`app01_react` through `app10_csharp_react`): it **teaches** OWASP/MITRE ATLAS/CompTIA SecAI+ security content, so it must itself **be** secure. For this app, that obligation resolves differently than for any prior sibling, because this app has no server, no network-facing attack surface for its core function, and no OWASP-Web-Top-10-shaped threat model to begin with:

1. **This app's threat model is drawn from OWASP MASVS and the Mobile App Cornucopia deck it itself teaches, not the Web Top 10 every prior sibling's SSDLC centered on.** `PLAN.md` §11 and `requirements.md` FR-10.3 make this explicit rather than mechanically reusing a threat-modeling template built for a client-server web app — a template that would leave this app's actual risks (entitlement over-request, insecure local data storage, weak sync-token handling) almost entirely unaddressed.
2. **The strongest "least privilege" guarantee in this entire series is not in this app's own code at all — it is the operating system's.** Apple's App Sandbox, code-signing, and per-entitlement permission model (`PLAN.md` D-01) constrain what this process can reach, enforced by the kernel, independent of whether this app's Swift code is correct. This is broader in scope than `app09_php_WORDPRESS`'s database `CHECK` constraint (the previous strongest platform-level guarantee in the series) but the same *kind* of claim: a guarantee that holds even against a bug in the application's own logic, and this document states its limit with the same care — sandboxing does not make the app's logic correct, only contains the blast radius when it is not.
3. **Swift's `enum` exhaustiveness gives the Digital-by-Default Harms deck's guarantee the strongest, most unconditional form in this entire series, tied with Rust and Haskell and ahead of `app10_csharp_react`'s configuration-dependent `CS8509`.** No project setting can disable it.
4. **The classic SDLC's "Deployment" phase gains a genuinely new, external actor: Apple's App Review.** No prior sibling's release pipeline has an independent third party reviewing the application before it can reach any user at all — this document treats that as a real, additional SSDLC gate (Phase 5), not a formality.

The lifecycle below follows **Agile Scrum for cadence, with a Kanban board carrying explicit security-gate columns**, per the requested focus on Agile/Scrum/Kanban.

---

## SSDLC vs Classic SDLC — Where Security Moves for an Offline, Sandboxed Client

```
Classic SDLC (security bolted on late):
  Planning & Analysis → Design → Implementation → Testing → Deployment → Maintenance
                                                        ↑
                                          Security testing added HERE — too late,
                                          architecture and code are already frozen.

SSDLC as this project achieves it (platform-provided isolation + language-level exhaustiveness):
  Secure          Secure       Secure            Secure          Secure           Secure
  Planning &  →   Design   →   Implementation →  Testing     →   Deployment   →   Maintenance
  Analysis        │            │                 │               │                │
    ↑             ↑            ↑                 ↑               ↑                ↑
  Threat model   App Sandbox  #Predicate         SwiftLint +     TestFlight →     Runtime
  from MASVS +   (D-01, OS-   removes query-      Xcode Analyze   Apple App        monitoring +
  Mobile         enforced) +  injection risk        + SwiftCheck   Review           patch cadence +
  Cornucopia,    Swift access entirely; enum         property       (an EXTERNAL     card-deck +
  not Web        control      exhaustiveness         tests          gate no          translation
  Top 10         (D-02)       (unconditional)                       sibling has)      integrity +
                                                                                        entitlements
                                                                                        audit
```

Both models describe the **same six stages**; SSDLC's contribution is that security activities happen *inside* each stage rather than as a single gate before release. This project's version of the diagram differs from every prior sibling's most visibly at "Deployment," where an external reviewer — Apple — sits between this project's own CI/CD and any user ever seeing the app at all.

---

## Agile Framework: Scrum for Cadence, Kanban for Flow

### Scrum structure

```
Sprint length:      2 weeks
Team size:           2–3 iOS/Swift engineers, 1 QA/security engineer with mobile-security
                      experience (MASVS familiarity specifically), 1 PL translator part-time
                      — a SMALLER team than any web-based sibling's estimate, reflecting that
                      there is no separate backend to build, deploy, or operate at all
Velocity target:     ~18–22 story points/sprint
Total duration:      14 sprints (~28 weeks) — comparable to the web-based siblings despite the
                      smaller team, because Phase 3's six-deck ingestion work, native
                      localization infrastructure, and App Review submission cycles (which can
                      themselves take days per round-trip) absorb the schedule differently

Ceremonies:
  Sprint Planning        — Monday, Day 1, 2h max — pulls from the Product Backlog (PLAN.md §15 + this doc's abuse cases)
  Daily Standup          — daily, 15 min, includes a mandatory "any security blocker?" round
  Mid-Sprint Security Gate — Wednesday, Day 7, 30 min — peer review of anything touching the
                             entitlements file, IntegrityService's package boundary, or any
                             CardKind switch statement
  Sprint Review          — Friday, Day 10, 1h — demo includes a security angle (e.g. "here's
                             the entitlements file, still exactly one capability")
  Sprint Retrospective   — Friday, Day 10, 45 min — one mandatory security-process retro item
```

### Kanban board — security-gated columns

```
BACKLOG → SPRINT → IN DEV → SEC REVIEW → I18N REVIEW → TEST → DONE

  BACKLOG       Product backlog: user stories (US-01..US-19), bugs, abuse cases (AC-01..AC-12)
  SPRINT        Committed for the current sprint
  IN DEV        Actively coded — TDD red/green cycle in progress
  SEC REVIEW    Mandatory gate for anything touching: the entitlements file (Info.plist/
                *.entitlements), IntegrityService's package-boundary, CardKind switch
                statements, or the Keychain-backed sync token
  I18N REVIEW   Mandatory gate for anything adding user-visible strings or card translations —
                a native Polish speaker signs off before merge
  TEST          XCTest + SwiftCheck + XCUITest running in CI on macOS runners
  DONE          Meets the Definition of Done below

WIP limits:  IN DEV ≤ 2/dev · SEC REVIEW ≤ 3 total · I18N REVIEW ≤ 3 total · TEST ≤ 5 total
```

**An iOS-specific Kanban nuance:** `SEC REVIEW` for this project includes a review trigger with no equivalent in any web-based sibling — any diff touching the entitlements file is *always* routed through `SEC REVIEW`, regardless of how small the change looks, because an entitlement addition that seems innocuous in a diff (one new line) can represent a meaningfully larger capability grant than its line-count would suggest. `TEST`'s `XCUITest` stage is also this project's slowest column in wall-clock terms (booting a Simulator and driving real UI per scenario), the same practical trade-off `app08_cpp_react`'s `FUZZ/SANITIZE` column had for a different reason — this project's `TEST` WIP limit accounts for that.

### Definition of Done (security- and i18n-enforced)

```
CODE QUALITY
  [ ] xcodebuild test passes (XCTest + SwiftCheck); coverage ≥ 85% on SwiftGuardData
  [ ] SwiftLint zero findings, including the custom rules for #Predicate-only queries,
      IntegrityService isolation, and no-NSPredicate(format:)

SECURITY GATES
  [ ] Xcode Analyze (static analyzer) zero findings at or above configured severity
  [ ] Entitlements file diff reviewed line-by-line if changed this PR — SR-01.2
  [ ] IntegrityService.verify() has no callers outside SwiftGuardData — SwiftLint rule + review
  [ ] Every CardKind switch statement confirmed to have no default: case masking non-exhaustiveness
      (the compiler already enforces exhaustiveness; this checklist item catches the one way a
      developer could opt OUT of that enforcement by adding an unnecessary default: arm)
  [ ] No secrets committed (detect-secrets / trufflehog pre-commit hook green)
  [ ] Third-party SPM dependency list unchanged, or the new dependency reviewed against the
      GitHub Advisory Database manually (SR-10.3)

I18N GATES
  [ ] String Catalog key-parity script passes — zero missing keys in either pl or en
  [ ] Any new/changed card translation reviewed and signed off by a native Polish speaker
  [ ] No hardcoded user-visible string added outside the String Catalog

DOCUMENTATION
  [ ] requirements.md traceability updated if scope changed
  [ ] user_stories+tests.md TDD test list updated for the story being closed
```

---

## Phase 0 — Sprint Zero: SSDLC & Tooling Setup

### 0.1 Threat modeling session — using OWASP MASVS and the Mobile Cornucopia deck as the primary source, not a web-app template

This session deliberately does **not** start from the STRIDE-per-web-component template every prior sibling's Phase 0 used, because most of that template's components (a backend server, a database, a network-facing API) do not exist in this app. Instead, the session walks the **MASVS categories directly** and asks, for each, "does this app's design already satisfy this, and by what mechanism":

| MASVS category | This app's answer | Source |
|---|---|---|
| MASVS-STORAGE | No sensitive data is stored at all beyond a non-sensitive `Bookmark` reference; the SwiftData store still inherits iOS Data Protection by default | `PLAN.md` D-01, SR-02 |
| MASVS-CRYPTO | This app implements no cryptography of its own; Sign in with Apple and CloudKit handle all cryptographic operations for the one feature that needs any | SR-11, D-07 |
| MASVS-AUTH | No custom authentication exists; Sign in with Apple is used exclusively | SR-11 |
| MASVS-NETWORK | Default ATS enforcement, no exception; no network call for core content at all | SR-03 |
| MASVS-PLATFORM | Minimum entitlement set (one capability); no `NSPredicate(format:)`-based query construction | SR-01, SR-04 |
| MASVS-CODE | Strict, hand-written YAML/JSON decoding (D-06); SwiftLint + Xcode Analyze in CI | SR-09, SR-10 |
| MASVS-RESILIENCE | Jailbreak/tamper detection is explicitly a stretch goal, not a Phase 1–7 requirement — this gap is stated, not hidden | `requirements.md` AC-12 |

This table **is** this project's threat model — not a supplement to a STRIDE diagram. The STRIDE deck (`STRIDE__eop-cards-5.0-en.yaml`) is still used, but as *educational content this app teaches* (US-08), not as *the primary tool for modeling this app's own threats*, a reversal of every prior sibling's relationship to that deck.

### 0.2 Security tooling setup

```yaml
# .github/workflows/ci.yml (excerpt, macOS runner)
- name: SwiftLint (SAST)
  run: swiftlint --strict
- name: Xcode Analyze
  run: xcodebuild analyze -scheme SwiftGuardData -destination 'platform=iOS Simulator,name=iPhone 15'
- name: Unit + property tests
  run: xcodebuild test -scheme SwiftGuardDataTests -destination 'platform=iOS Simulator,name=iPhone 15'
- name: UI tests
  run: xcodebuild test -scheme SwiftGuardUITests -destination 'platform=iOS Simulator,name=iPhone 15'
- name: Entitlements diff check
  run: python scripts/check_entitlements_diff.py SwiftGuard.entitlements
- name: String Catalog key parity
  run: swift scripts/check-i18n-parity.swift
- name: SPM dependency manual-review reminder
  run: python scripts/list_spm_dependencies.py  # informational — no automated vulnerability DB exists yet
```

### 0.3 Branch protection
- `main` requires 1 approval + all CI checks green + no `SEC REVIEW`/`I18N REVIEW` Kanban card still open for the linked issue.
- CODEOWNERS: `@security-team` required for `SwiftGuardData/Sources/SwiftGuardData/Integrity/`, any `*.entitlements` file, `Resources/hashes.json`, and any `docs/OWASP_stories/*.yaml` change.

---

## Phase 1 — Planning & Analysis (Secure Requirements)

### 1.1 Business goals vs security constraints

| Business goal | Security constraint it must respect |
|---|---|
| Teach OWASP/ATLAS/SecAI+ content accurately and fast | Content integrity (`requirements.md` SR-06) must not be sacrificed for speed of publishing |
| Serve both PL and EN learners | Missing translations degrade gracefully (FR-18.6), never a blank field |
| Offer optional cross-device bookmark sync | The sync feature must not become an excuse to request any entitlement beyond CloudKit, or to implement any custom auth (SR-11, D-07) |
| Cover all six Cornucopia decks, including the non-technical harms deck | The harms deck (US-19) must never be presented as if it had CVE-style severity — enforced unconditionally at the type level (D-03) |

### 1.2 Compliance requirements mapping

| Regulation / standard | Relevance | Where it lands in requirements.md |
|---|---|---|
| GDPR / RODO | The only user-generated data (`Bookmark`) is minimal and non-sensitive; no analytics SDK exists | C-03, SR-02.2 |
| EU AI Act (transparency, Art. 13) | `dbd` harms deck explicitly references this | FR-19.3, DR-01.11 |
| NIS2 / Polish KSC | Educational content on GRC topics | DR-01.5 |
| Apple App Store Review Guidelines | A compliance requirement with no equivalent in any prior sibling — this app must satisfy Apple's own privacy, content, and technical guidelines to be distributed at all | `SDLC_analysis.md` Phase 5 |
| OWASP MASVS 2.0 | This app's own primary self-assessment framework, not just browsable content | §11, `requirements.md` FR-10.3 |

### 1.3 Security requirements traceability (excerpt)

| Requirement | Threat addressed | Verified by |
|---|---|---|
| SR-01.1 (minimum entitlement set) | Over-privileged app process, MASVS-PLATFORM | Manual entitlements review, release-blocking (SR-01.2) |
| SR-04.1 (`#Predicate`-only queries) | Injection via query construction | Structural absence + `SwiftLint` rule forbidding `NSPredicate(format:)` |
| SR-06.4 (`IntegrityService` package isolation) | A compromised View/ViewModel forging a "content verified" record | `SwiftLint` custom rule + code review — a same-binary, package-level boundary, weaker than a cross-process one but stronger than a same-file convention |
| FR-19.2 (`CardKind` `enum` exhaustiveness) | Digital-by-Default Harms deck misread as a CVE-style severity list | Unconditional Swift compiler error on any non-exhaustive `switch` over `CardKind` with no `default:` |

### 1.4 Abuse cases (negative user stories)

See `requirements.md` §7 for the full table (AC-01–AC-12). Highlights specific to this project's platform:

| ID | Abuse case |
|---|---|
| AC-08 | A user copy-pastes the Digital-by-Default Harms deck into a report as if `SCO2` were a CVSS-scored finding — structurally impossible to even construct the data shape that would allow this, since `CardKind.designHarm` has no associated `Severity` value to have copy-pasted from in the first place. |
| AC-09 | A future release accidentally requests the camera or location entitlement while adding an unrelated feature (e.g., a "scan a QR code to import a bookmark" feature nobody asked for) — caught by mandatory entitlements review, and, as a second, independent check, by Apple's own App Review process during submission. |
| AC-12 | A jailbroken device weakens the App Sandbox guarantees this whole plan otherwise leans on — explicitly out of scope for this app's own guarantees, the same honest limit `app07_rust_react` states for a kernel-level 0-day undermining Rust's own memory-safety guarantees, or `app09_php_WORDPRESS` states for a MySQL version regression disabling `CHECK` enforcement. |

---

## Phase 2 — Secure Design

### 2.1 Trust boundaries

```
┌─────────────────────────── Untrusted (outside the sandbox) ───────────────────┐
│  Every other process on the device; the network, for the two Apple-managed    │
│  frameworks this app uses at all                                               │
└───────────────────────────────┬──────────────────────────────────────────────┘
                                 │ App Sandbox boundary — kernel + code-signing enforced (D-01)
┌────────────────────────────── Trust Boundary 1 (this app's process) ──────────┐
│  SwiftGuardUI (Views, ViewModels)                                              │
│    - reads via Repository protocols only                                      │
│    - CANNOT call IntegrityService.verify() — declared in a separate local     │
│      Swift package (SwiftGuardData), not imported by name in SwiftGuardUI     │
└───────────────────────────────┬──────────────────────────────────────────────┘
                                 │ same process, package boundary (Swift access control, D-02)
┌────────────────────────────── Trust Boundary 2 ────────────────────────────────┐
│  SwiftGuardData (ContentSeeder, IntegrityService, Repositories)                │
│    - the ONLY code that writes CornucopiaCard/Threat/Mitigation data           │
│    - SyncCoordinator is the ONLY type here that imports CloudKit at all        │
└───────────────────────────────┬──────────────────────────────────────────────┘
                                 │ local filesystem, iOS Data Protection (OS-level)
┌────────────────────────────── Trust Boundary 3 ────────────────────────────────┐
│  Bundled resources (Resources/*.yaml, hashes.json) + on-device SwiftData store │
│    - bundled resources are code-signed as part of the app; on-device store is │
│      sandboxed and Data-Protection-encrypted by the OS, not by this app's code │
└────────────────────────────────────────────────────────────────────────────────┘
```

**Design decision D-01 (this document; distinct from `PLAN.md`'s own D-01, App Sandbox):** unlike every prior sibling, "Trust Boundary 1" here is not a network boundary at all — it is the boundary between two Swift packages inside one signed binary. This is a materially different security model: there is no possibility of an unauthenticated remote attacker reaching this app's data at all (barring a network compromise of Apple's own CloudKit/Sign-in-with-Apple infrastructure, which is outside this project's threat model to defend against, the same way `app09_php_WORDPRESS`'s threat model does not attempt to defend against a WordPress-core-itself 0-day, only to patch it quickly when disclosed).

### 2.2 Least privilege applied to the data model

- `CornucopiaCard` records (all six decks) have **no** write path from any View/ViewModel — no such method exists anywhere in `SwiftGuardUI`'s dependency surface at all (`requirements.md` C-08).
- The `Bookmark` model is the only user-writable data, and it contains no sensitive fields.
- The strongest instance of least privilege in this whole app is not in the data model at all — it is the entitlements file itself (SR-01), which is this app's literal, OS-enforced permission boundary.

### 2.3 STRIDE analysis, applied where it still fits (and noted where it does not)

| STRIDE | Applies to | Mitigation already in the design |
|---|---|---|
| Spoofing | Sign in with Apple identity | Apple's own signature verification; this app implements none of its own |
| Tampering | Bundled YAML/JSON content; the on-device SwiftData store | Code-signing (bundled content) + `IntegrityService` (catches build/CI mistakes, D-06) + OS Data Protection (on-device store) |
| Repudiation | Who approved a translation or a hash-allowlist update | CODEOWNERS-enforced PR review logged in Git history |
| Information Disclosure | The CloudKit sync token; crash reports | Keychain-only token storage (SR-02.3); Apple's own crash-report redaction |
| Denial of Service | N/A in the traditional network sense — noted explicitly as **not applicable** to an offline-first client, rather than force-fitted with a rate-limiter this app has no need for | — |
| Elevation of Privilege | An over-broad entitlement request | Manual review (SR-01.2) + Apple App Review (Phase 5) |

### 2.4 Data classification

| Data | Classification | Handling |
|---|---|---|
| Threat/card content (EN + PL) | Public, but integrity-critical | Bundled, code-signed, SHA-256 verified against build-time drift |
| `Bookmark` (which threat/card codes a user saved) | Low-sensitivity personal data | Local SwiftData store (OS Data Protection); optionally synced via the user's own iCloud account |
| CloudKit sync token | Secret (session-equivalent) | Keychain, `ThisDeviceOnly` accessibility |

---

## Phase 3 — Implementation (Secure Coding)

### 3.1 Secure coding standards — Swift

```swift
// ALWAYS — #Predicate, never NSPredicate(format:) with string interpolation
let predicate = #Predicate<Threat> { $0.frameworkCode == frameworkCode }

// ALWAYS — exhaustive switch over CardKind, no default: arm
switch card.kind {
case .technicalThreat(let severity): renderSeverityBadge(severity)
case .designHarm: renderDesignHarmBadge()
}

// ALWAYS — hand-written unknown-key rejection for every Cornucopia YAML shape (D-06)

// ALWAYS — Keychain for the one secret this app has
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
]

// NEVER — NSPredicate(format:) with string interpolation of any kind (SwiftLint-forbidden);
// NEVER — a default: arm added to a CardKind switch "to silence a warning" (there is no such
// warning to silence — adding default: only exists to defeat the compiler's own guarantee,
// and is exactly the mistake the SEC REVIEW checklist's exhaustiveness item exists to catch)
```

### 3.2 Sprint-by-sprint security activities

| Sprint | Feature work | Security activity in parallel |
|---|---|---|
| 1–2 | Foundation, package boundary | MASVS-based threat model review (Phase 0.1); `SwiftLint`/Xcode Analyze wired into CI (not yet blocking) |
| 3–4 | Threat browser | SAST becomes blocking; `#Predicate`-only rule enforced |
| 5–7 | Card decks (all six, including `dbd`) + integrity | AC-06, AC-08 abuse tests written FIRST (TDD) before the decoders/`CardKind` exist |
| 7–9 | 5-language code samples | Review that no `attackDemo` sample is viewable without the confirmation dialog |
| 9–10 | i18n | I18N REVIEW Kanban column activated |
| 10–12 | Search, export, optional CloudKit sync | Entitlements file changes for the first time this project — `SEC REVIEW` mandatory; AC-09 test added |
| 12–14 | Hardening & release | First TestFlight build; first Apple App Review submission cycle |

---

## Phase 4 — Security Testing

### 4.1 Test pyramid with security layers

```
XCUITest (native UI/E2E)     — includes AC-01..AC-12 abuse-case scenarios end-to-end,
                                driving the real compiled app in the Simulator
XCTest integration            — Repository behavior against an in-memory ModelContainer
XCTest unit                    — service-layer behavior with concrete fixtures
SwiftCheck properties           — invariants over generated data: YAML decode-rejects-unknown-
                                  fields, every mitigation has 5 languages
```

### 4.2 SAST
`SwiftLint` runs on every PR with custom rules specific to this project's own guarantees (no `NSPredicate(format:)`, no `IntegrityService` import outside `SwiftGuardData`, no stray `default:` arm on a `CardKind` switch). Xcode's `Analyze` build action adds general-purpose static analysis shared with the LLVM/Clang toolchain. Neither tool needs to catch memory-safety bugs the way `app08_cpp_react`'s tooling does — Swift is memory-safe by default the same way every managed-runtime sibling is — so this SAST layer's focus is entirely on this project's *specific* guarantees, not a general memory-safety sweep.

### 4.3 SCA — an honestly-stated ecosystem gap
This project's third-party dependency count is deliberately minimal (`Yams`, `SwiftCheck`) specifically because no Swift Package Manager tool as mature as `dotnet list package --vulnerable`/`cargo audit`/`composer audit` exists as of 2026. `requirements.md` SR-10.3 states this as an accepted ecosystem-maturity gap, mitigated by keeping the dependency surface small enough for a quarterly manual review against the GitHub Advisory Database to remain tractable — the same "minimize what needs a workaround" strategy `app08_cpp_react` applies to its own weakest-tooling area.

### 4.4 DAST — not applicable, stated as such rather than skipped silently
There is no network-facing API to run OWASP ZAP against. This requirement category, present in every prior sibling's specification, is intentionally absent here rather than satisfied by an inapplicable tool run against nothing meaningful — the same discipline `app11_swift_ios`'s own `requirements.md` SR-10.4 applies to Trivy (no container to scan).

### 4.5 Abuse-case tests (integration/UI level)
```swift
func testAc08_DesignHarmCaseHasNoSeverityAssociatedValue() {
    let kind = CardKind.designHarm
    XCTAssertNil(severityOf(kind))
    // The type itself, not just this instance, has no path to a Severity for this case.
}

func testAc09_EntitlementsFileContainsExactlyOneCapability() throws {
    let entitlements = try EntitlementsFileParser.parse(path: "SwiftGuard.entitlements")
    XCTAssertEqual(entitlements.capabilities, ["com.apple.developer.icloud-services"])
}
```

### 4.6 Security regression testing
Every fixed security bug gets a permanent regression test, run on every CI build, never skipped.

---

## Phase 5 — Deployment (Secure Release) — including an external gate no sibling has

### 5.1 CI/CD pipeline with security gates
```
lint (SwiftLint) → static analysis (Xcode Analyze) → unit+property tests (XCTest/SwiftCheck)
   → UI tests (XCUITest) → entitlements diff check → archive & sign (xcodebuild archive)
   → upload to TestFlight → internal QA on TestFlight → submit for Apple App Review
   → [external, days-long, independent review by Apple] → App Store release
```

### 5.2 Infrastructure hardening checklist — a much shorter list than any server-based sibling's, for a structural reason
```
Code signing     Valid Apple Developer Program certificate; automatic/manual signing
                 consistently configured, no ad-hoc signing in release builds
Entitlements     Exactly one capability (com.apple.developer.icloud-services); reviewed
                 on every change and audited before every submission
ATS              No exception in Info.plist; default TLS enforcement relied upon as-is
Data Protection  Default file-protection class for the SwiftData store; no override to a
                 weaker class anywhere in the codebase
```
There is no reverse proxy, no container image, no database server, and no secrets-management infrastructure to harden — this app's "infrastructure" is Apple's own platform, and this project's obligation is to configure the small number of platform-provided controls correctly, not to build and operate infrastructure of its own.

### 5.3 Apple App Review as an SSDLC-relevant external gate
Every release must pass Apple's own review before reaching any user — a mandatory, independent, security- and privacy-relevant check (Apple reviews entitlement usage, data-collection disclosures, and general policy compliance) that this project's own CI cannot bypass or shortcut. This document treats App Review the way `app09_php_WORDPRESS`'s document treats the WPScan vulnerability database: an external source of truth this project's own process must account for in its release timeline (App Review turnaround can be hours to several days) rather than assume away.

---

## Phase 6 — Maintenance & Runtime Monitoring

### 6.1 Runtime monitoring
- Apple's own **MetricKit** (crash reports, hangs, disk-write metrics) and Xcode Organizer provide this app's entire runtime-monitoring story — there is no self-hosted Grafana/Loki/Prometheus stack, because there is no server process to instrument.
- A crash report clustering around `IntegrityService.verify()` or a `CardKind` decode path is treated as security-relevant by default (the same practice `app08_cpp_react`'s Phase 6.1 established for crash reports as a possible symptom of an underlying memory-safety issue — here, of a content-integrity or decoding issue instead, since Swift's own memory safety removes the C++-specific concern).

### 6.2 Patch management (Kanban)
A dedicated `DEPENDENCY UPDATES` swimlane, fed by a quarterly manual review of the two-package SPM dependency list (SR-10.3) rather than an automated nightly scan, given the ecosystem-tooling gap stated in Phase 4.3. **A second, iOS-specific swimlane item tracks new major iOS releases** — each new iOS version can introduce new App Sandbox/entitlement behavior, new SwiftData capabilities, or new App Review policy requirements, none of which have an equivalent "dependency bump" concept in any server-based sibling's maintenance schedule.

### 6.3 Incident response (outline)
1. Detect (crash report, user-submitted App Store review flagging a bug, or a security researcher's disclosure) → 2. Contain (there is no feature flag/remote kill-switch infrastructure in a pure client app without a backend — containment for a serious issue may require an **expedited App Review request**, itself a process unique to this platform) → 3. Eradicate (patch) → 4. Recover (release a new version, which must again pass App Review before reaching users — a slower recovery cycle than any server-based sibling's "redeploy" step) → 5. Post-mortem, feeding new abuse cases back into Phase 1.

### 6.4 Content & translation review schedule
- Quarterly re-verification that every `CornucopiaCard.contentSha256` still matches its source YAML.
- Quarterly Polish translation audit sampling 10% of `descriptionPl` fields against current `descriptionEn` for staleness.
- Quarterly entitlements-file audit, independent of any code change, confirming the capability list has not grown (Phase 0.2's CI check covers changes; this covers drift-by-omission if the check itself were ever weakened).

---

## Phase 7 — iOS/Swift-Specific SSDLC Considerations

1. **This is the first app in the series where the educational content and the application's own SSDLC threat model are substantially the same document.** Every MASVS category this app teaches (US-10) is also a section of this app's own Phase 0.1 self-assessment. This is a deliberate design choice, not a coincidence of subject matter, and it gives students a uniquely concrete way to see "how would I actually assess my own app against this standard" answered in full.
2. **The App Sandbox guarantee and the database-`CHECK`-constraint guarantee from `app09_php_WORDPRESS` are close cousins, and it's worth being precise about how.** Both hold independent of the application's own code correctness; both have a stated, honest limit (a MySQL version regression for one, a jailbreak or OS 0-day for the other); the sandbox's is broader in scope (it constrains an entire process's reachable capabilities, not one data invariant) but shallower in what it guarantees about *this app's own logic* (it says nothing about whether `CardKind` is read correctly, the same way the `CHECK` constraint said nothing about whether a REST route had a `permission_callback`).
3. **Dropping the network entirely does not mean dropping the SSDLC — it changes which controls are load-bearing.** SQL injection, CSRF, and DAST all become structurally inapplicable (Phase 4.3–4.4), but content-integrity verification, strict decoding, exhaustive pattern matching, and entitlement minimization all remain exactly as necessary as for any prior sibling — this document's job has been to show precisely which controls transferred, which became moot, and which (App Review, entitlements review) are genuinely new.
4. **"Batteries included" platform tooling reaches its highest point in this series here, and its biggest gap simultaneously.** Swift's `enum` exhaustiveness and SwiftData's `#Predicate` give stronger, more automatic guarantees than almost anything in this series required custom tooling for elsewhere — while Swift Package Manager's SCA tooling is, honestly, the least mature of any ecosystem in this series. Both facts are stated plainly, in keeping with this whole series' practice of specific, checkable claims over blanket praise or blanket caution for any one platform.

---

## SDLC × SSDLC Master Mapping Table

| Classic SDLC stage | SSDLC security activity in this project | Primary artifact |
|---|---|---|
| Planning & Analysis | Threat modeling via OWASP MASVS categories directly (not a web-app STRIDE template); compliance mapping (GDPR/AI Act/NIS2/Apple Review Guidelines); abuse cases AC-01–AC-12 | `requirements.md` §1–7, this document Phase 1 |
| Design | Trust-boundary diagram (App Sandbox ↔ package boundary ↔ on-device store); least privilege via the entitlements file; STRIDE-where-applicable table | `PLAN.md` §3–5, this document Phase 2 |
| Implementation | Secure Swift coding standards (`#Predicate`-only queries, exhaustive `enum` switches, strict YAML decoding, Keychain-only secret storage); TDD red-green with security tests (and `SwiftCheck` properties) written first | `user_stories+tests.md`, this document Phase 3 |
| Testing | SAST (`SwiftLint`/Xcode Analyze), SCA (manual, ecosystem-gap-acknowledged), DAST (not applicable, stated as such), `XCUITest` abuse-case scenarios | this document Phase 4 |
| Deployment | CI/CD security gates, entitlements hardening, code signing, **Apple App Review as an external gate** | this document Phase 5 |
| Maintenance | MetricKit-based runtime monitoring, Kanban-driven patch management (including iOS-version tracking), incident response constrained by App Review turnaround, quarterly content/translation/entitlements review | this document Phase 6 |

---

## Agile Ceremonies — Security & i18n Integration Points

```
Sprint Planning        → New security/i18n stories pulled from backlog alongside features;
                          every card-deck story (US-05–US-12, US-19) is estimated with its Polish
                          translation review as part of the story, not a separate ticket.
Daily Standup          → "Any SEC REVIEW or I18N REVIEW blocker?" is a standing question.
Mid-Sprint Security Gate → Dedicated 30-minute slot for anything touching the entitlements
                          file, IntegrityService's package boundary, or CardKind switches.
Sprint Review          → Demo always includes one security-relevant moment (e.g., the
                          entitlements file review, or the attack-demo confirmation dialog).
Sprint Retrospective   → One mandatory retro item: "did any security or translation issue
                          reach TEST or DONE that SEC REVIEW/I18N REVIEW should have caught?"
```

---

## Summary: SSDLC Compliance Checklist for SwiftGuard 2026

```
[ ] Threat model exists, built from OWASP MASVS categories directly, and is reviewed each
    quarter (Phase 0, 6.4)
[ ] IntegrityService.verify() has no callers outside the SwiftGuardData package — SwiftLint +
    review, a same-binary package boundary (Phase 2.1)
[ ] All on-device queries go through #Predicate — zero NSPredicate(format:) usage (Phase 3.1)
[ ] All six YAML decks decoded via hand-written, unknown-key-rejecting init(from:) implementations;
    SHA-256 verified regardless (Phase 3, D-06)
[ ] Every CardKind switch is exhaustive with no stray default: arm (unconditional compiler
    guarantee, spot-checked in SEC REVIEW for the one way a developer could opt out) (Phase 4.2)
[ ] SAST (SwiftLint/Xcode Analyze) is CI-blocking; SCA is an acknowledged manual process given
    ecosystem tooling gaps; DAST is explicitly marked not applicable (Phase 4)
[ ] Every abuse case AC-01–AC-12 has an automated regression test or a documented structural-
    absence rationale (Phase 4.5)
[ ] i18n key parity (String Catalog) and translation review are enforced as release gates
    (Phase 1, I18N REVIEW column)
[ ] Card content (all 6 decks) is read-only in the application — no write path exists in
    SwiftGuardUI at all
[ ] Entitlements file requests exactly one capability, reviewed on every change and before
    every App Store submission (Phase 5.2)
[ ] Apple App Review is budgeted into the release timeline as an external, independent gate
    (Phase 5.3)
[ ] Digital-by-Default Harms deck cannot carry a Severity value — unconditional Swift compiler
    guarantee, the strongest tier in this series (Phase 1.3, FR-19.2)
[ ] Kanban board carries explicit SEC REVIEW and I18N REVIEW columns with WIP limits
[ ] Incident response accounts for App-Review-gated recovery timelines; patch-management
    processes exist before, not after, first App Store release
```
