# KotlinGuard 2026 — SSDLC / SDLC Analysis

**Version:** 1.0
**Date:** 2026-07-07
**Companion documents:** `PLAN.md`, `requirements.md`, `user_stories+tests.md`
**Methodology focus:** Agile Scrum with a security-gated Kanban board (as requested — this analysis centers on Agile/Scrum/Kanban, not Waterfall)

---

## 1. Executive Summary

This document analyzes the KotlinGuard 2026 plan and requirements through both the classic **SDLC** (Software Development Life Cycle) lens and the **SSDLC** (Secure Software Development Life Cycle) lens, and maps both onto an **Agile Scrum** process running on a **security-gated Kanban board**. As the native-Android twin of `app11_swift_ios`, most of this document's structure mirrors that sibling's directly; where Android's platform model changes what a phase actually requires — exported-component review, a materially stronger SCA tooling story, a Google Play (rather than Apple App Review) distribution gate — this document says so explicitly rather than silently copying the iOS version's conclusions.

**The central SSDLC-vs-classic-SDLC distinction, restated for a client-only mobile app:** classic SDLC treats security as a phase (typically testing, sometimes only at the end); SSDLC treats security as a **continuous, parallel activity across every phase** — threat modeling in Design, secure coding standards in Implementation, SAST/SCA/DAST-equivalent tooling in Testing, manifest/permission review before Deployment, dependency monitoring in Maintenance. For an app with **no server infrastructure at all**, several classic SDLC/SSDLC concerns (network segmentation, server hardening, WAF configuration) simply do not apply — and this document states that absence explicitly rather than manufacturing content to fill the gap, the same discipline `app11_swift_ios`'s analysis applied.

```
Classic SDLC:   Plan → Design → Implement → Test → Deploy → Maintain
                                              ↑
                                    (security concentrated here, if at all)

SSDLC:          Plan → Design → Implement → Test → Deploy → Maintain
                  ↓       ↓          ↓          ↓       ↓         ↓
                Threat   STRIDE   Secure     SAST/    Manifest  Dependency
                model    trust    coding     SCA/UI   review,   monitoring,
                sprint   boundary standards  testing  signing,  Play Console
                (Ph.0)   review            (Ph.4)   Play      Vitals,
                                                     review    Crashlytics
```

---

## 2. Agile Scrum Structure

### 2.1 Team composition
- **Product Owner** — owns the backlog of 19 user stories (US-01…US-19), prioritizes framework/deck coverage
- **Scrum Master** — facilitates ceremonies, removes blockers (e.g., emulator/CI flakiness, Google Play Console access delays)
- **Development team** (4–6 engineers) — Kotlin/Compose/Room developers, cross-functional (no separate "backend" role exists, since there is no backend — a structural Scrum simplification directly inherited from `app11_swift_ios`)
- **Security champion** (embedded, not a separate silo) — owns manifest/permission review, `CardKind`/D-03 correctness review, dependency-check triage
- **Content/translation reviewer** — validates Polish translations of card content against source YAML, a role unique to this bilingual series of apps

### 2.2 Sprint cadence
- **Sprint length:** 2 weeks
- **14 sprints** total, aligned to the 7 Development Phases in `PLAN.md` §6 (roughly 2 sprints per phase)
- **Sprint Zero** (Phase 0, below) precedes Sprint 1 and is **not** a user-story sprint — it is infrastructure/threat-modeling/tooling setup

### 2.3 Kanban board — security-gated columns

```
┌──────────┬─────────────┬────────────┬──────────────┬─────────────┬──────────┬────────┐
│ Backlog  │ In Progress │ Code Review │ SEC REVIEW   │ QA/Testing  │ Staged   │ Done   │
│          │             │ (peer)      │ (gate — see  │ (CI: unit + │ (Internal│ (Play  │
│          │             │             │  below)      │ Compose UI) │ testing) │ prod)  │
└──────────┴─────────────┴────────────┴──────────────┴─────────────┴──────────┴────────┘
```

**SEC REVIEW gate — entry criteria (a card cannot leave this column until all applicable items pass):**
1. If the PR touches `AndroidManifest.xml`: every new/changed component is `exported="false"` unless justified in the PR description, and Android Lint's `ExportedContentQuery` passes (SR-01).
2. If the PR touches a `CardKind`-reading `when`: confirmed used as an expression, no `else` branch (SR-03).
3. If the PR touches a `kotlinx.serialization`/`kaml` decoder: `ignoreUnknownKeys`/`strictMode` unchanged from strict defaults (SR-04).
4. If the PR touches `assets/cornucopia/*.yaml`: CODEOWNERS security-content review, 2 approvals (SR-14).
5. If the PR adds a Gradle dependency: `dependency-check-gradle` reports no new HIGH/CRITICAL (SR-11).
6. If the PR touches Room DAOs: no `rawQuery` with concatenated input (SR-08).
7. `detekt` and Android Lint both pass with zero HIGH findings (SR-12).

A card failing any applicable check is returned to **In Progress**, not silently waived — the same non-negotiable gate discipline every sibling in this series enforces.

### 2.4 Definition of Done
A user story is Done when: (1) all acceptance criteria in `user_stories+tests.md` pass in CI: (2) Polish and English content both render and are reviewed by the translation reviewer; (3) the SEC REVIEW gate has passed; (4) Compose UI Testing coverage exists for the story; (5) the Product Owner has accepted the story in Sprint Review.

---

## 3. Phase 0 — Sprint Zero: Threat Modeling & Tooling Setup

**Not a user-story sprint.** Activities:
- Set up the Gradle multi-module skeleton (`:data`/`:ui`/`:app`), CI pipeline (GitHub Actions with an Android SDK toolchain — portable across Ubuntu and macOS runners, unlike `app11_swift_ios`'s macOS-only CI requirement)
- Initial **STRIDE threat-modeling session** using the SP/TA/RE/ID/DS/EP deck against KotlinGuard's own architecture (§3 of `PLAN.md`) — the same self-referential technique used by every sibling, producing the concrete cross-references in US-10 (Mobile App deck ↔ this app's own design decisions)
- Configure Android Lint, `detekt`, `dependency-check-gradle` in CI (not yet gating)
- Draft `AndroidManifest.xml` skeleton with the exported-component policy (D-02/SR-01) agreed and documented
- Establish the CODEOWNERS file for `assets/cornucopia/*.yaml` (SR-14)

**Output:** an initial risk register (`PLAN.md` §13), a Sprint 1–14 backlog mapped to US-01…US-19, and a CI pipeline with security tooling installed (not yet enforced as a merge gate — enforcement begins in Phase 4/§6 below).

---

## 4. Phase 1 — Planning & Analysis (Sprints 1–2, maps to `PLAN.md` Phase 1)

Classic SDLC "Requirements Analysis," conducted here via Sprint Planning against `requirements.md`. Every FR/SR/NFR is broken into a candidate user story or acceptance criterion before Sprint 1 begins (traceability matrix, `requirements.md` §7).

**SSDLC addition — abuse-case elicitation:** the Abuse Case Requirements table (`requirements.md` §6) is drafted in this phase, not appended later, directly informed by the Sprint Zero STRIDE session and by walking the Mobile App Cornucopia deck (US-10) against KotlinGuard's own architecture — an SSDLC practice with no classic-SDLC analogue (classic requirements analysis asks "what should the system do," not "how could this system be abused").

---

## 5. Phase 2 — Secure Design (Sprints 1–2, overlapping Phase 1)

**Trust boundary identification** (`PLAN.md` §3): the app-sandbox boundary (D-01), the exported-component boundary (D-02, unique in kind to this and `app09_php_WORDPRESS`'s server-boundary style concerns, but with a different mechanism), the `ContentSeeder`/`IntegrityChecker` module boundary, and the Firestore sync boundary (D-07).

**Data classification:**

| Data class | Examples | Handling |
|---|---|---|
| Public/educational | Threats, cards, mitigations, code samples | Bundled read-only assets, no protection needed beyond integrity (SR-05) |
| User-generated, low-sensitivity | Bookmarks | Room database, app-sandboxed |
| Sensitive, small | Firestore sync token | `EncryptedSharedPreferences` / Keystore (SR-09) |

**STRIDE-per-trust-boundary review**, conducted against KotlinGuard's own design and cross-referenced live in-app via US-10 — the same "the app teaches you the threat model by using itself as the example" technique `app11_swift_ios` introduced for iOS, here re-derived for Android's different boundary shape (exported components, not App Sandbox entitlements, as the dominant Android-specific STRIDE finding).

**Design decisions formally reviewed and signed off in this phase:** D-01 through D-08 in `PLAN.md` §4, each with an explicit statement of the guarantee's actual strength (unconditional compiler exhaustiveness for D-03; kernel/SELinux enforcement for D-01; build-time SQL verification for D-04; convention/lint-enforced for D-02) — this project follows the same rule as every sibling: never state a stronger guarantee than the mechanism actually provides.

---

## 6. Phase 3 — Implementation (Sprints 2–9, maps to `PLAN.md` Phases 1–4)

**Secure coding standards enforced via `detekt` custom rules and Android Lint, not only code review:**
- No `ignoreUnknownKeys = true` / lenient YAML mode (SR-04, AC-02)
- No `when` **statement** substituted for a `when` **expression** when reading `CardKind` (SR-03 caveat, AC-03)
- No `rawQuery` with string-concatenated input (SR-08, AC-05)
- No component added to `AndroidManifest.xml` without an explicit `exported` value (SR-01, AC-01)

**Pair programming / mob sessions** recommended specifically for D-03 (`CardKind`) and D-02 (manifest) changes, given how easily both guarantees can be silently weakened by a well-intentioned but uninformed change (adding an `else` branch "to be safe"; exporting a component "temporarily" for debugging and forgetting to revert it).

**Continuous integration on every PR (not batched):** `detekt` + Android Lint + unit tests run on every push; `dependency-check-gradle` runs on every PR touching `build.gradle.kts`; Compose UI Testing runs on every PR touching `:ui` or `:app`.

---

## 7. Phase 4 — Security Testing (Sprints 9–13, maps to `PLAN.md` Phase 7)

| Test type | Tool | Enforcement point |
|---|---|---|
| SAST | Android Lint (security-specific checks) + `detekt` | Blocking CI check, every PR |
| SCA | `dependency-check-gradle` (OWASP Dependency-Check vs. NVD) | Blocking CI check, every PR touching dependencies — **materially more mature than the Swift Package Manager SCA story `app11_swift_ios` accepted as a gap (requirements.md SR-10.3 there)** |
| Unit/property tests | JUnit 5 + Kotest | Blocking CI check, every PR |
| UI/instrumented tests | Compose UI Testing | Blocking CI check, every PR touching UI |
| Manifest/permission review | Manual + Android Lint | Before every release build |
| Dependency license/vulnerability audit | `dependency-check-gradle` report review | Before every release |
| Release-build verification | R8 shrinking/obfuscation functional test on a release APK/AAB, not only debug | Before every release |

**No DAST-equivalent phase exists** for this app, for the same structural reason `app11_swift_ios` states: there is no server endpoint to dynamically scan. The one network-reachable path (Firestore sync, D-07) is Google-managed infrastructure whose security posture is governed by Firestore Security Rules review (SR-10), not a DAST scan this project would run itself.

---

## 8. Phase 5 — Deployment: the Google Play Gate

Distribution proceeds **Internal testing track → Closed/Open testing → Production**, each a genuine Kanban-board stage (§2.3), not a formality:

1. **Internal testing:** immediate distribution to the team after a green CI run; no Google review delay.
2. **Closed testing:** a small external group; still no full Google Play review, but Play Protect's automated malware/behavior scanning applies.
3. **Production release:** subject to **Google Play's review process** — a combination of automated policy/malware scanning and, for some categories or triggered concerns, human review.

**Stated honestly, in contrast to `app11_swift_ios`'s Apple App Review discussion:** Google Play's review process is, as a matter of general industry experience through 2026, typically **faster and more automation-heavy** than Apple's App Review, and Google Play more readily supports staged rollouts (a percentage-based production rollout) as a first-class mechanism — a deployment-risk-reduction tool with no direct Apple App Store equivalent of the same granularity. This is a genuine, positive platform difference worth naming, not a reason to treat the Google Play gate as lower-stakes: a policy violation (e.g., a permission the review flags as unjustified, directly relevant to SR-02/C-05's least-privilege requirement) can still delay or reject a release, and this project's Kanban board budgets calendar time for this exactly as `app11_swift_ios` budgets time for Apple's slower gate.

**Staged rollout as an SSDLC-relevant deployment control:** a production release begins at a small rollout percentage (e.g., 5–10%), monitored via Android Vitals and Firebase Crashlytics (Phase 6) before widening — a risk-reduction technique with no analogue in this series' server-deployed siblings' blue/green deployment sections, because it is Google Play's own built-in mechanism rather than something this project's CI/CD must implement itself.

---

## 9. Phase 6 — Maintenance & Monitoring

- **Android Vitals** (Google Play Console) — crash rate, ANR (Application Not Responding) rate, battery/wakelock health, monitored post-release; a regression here is a triggering event for a hotfix sprint.
- **Firebase Crashlytics** — symbolicated crash reports, the operational feedback loop for defects that passed CI but manifest on real devices/OS versions.
- **Dependency monitoring** — `dependency-check-gradle` re-run on a scheduled (not just PR-triggered) CI job, catching newly disclosed CVEs in already-shipped dependency versions — the same "a dependency can become vulnerable after merge, not just at merge" discipline every sibling's Phase 6 states.
- **Card-deck content updates** — new/changed cards in any of the six YAML decks go through the same SEC REVIEW gate (CODEOWNERS + hash regeneration) as initial content, never a silent hotfix.
- **Quarterly manifest/permission audit** — confirms no component has drifted to `exported="true"` and no new permission has been added without a corresponding, reviewed feature justification (the Android-specific analogue of `app10_csharp_react`'s quarterly `.csproj` `WarningsAsErrors` audit).

---

## 10. Phase 7 — Kotlin/Android-Specific SSDLC Considerations

1. **Compile-time guarantees are a design-phase decision, not a testing-phase afterthought.** D-03 (`CardKind` sealed interface) and D-04 (Room `@Query` compile-time SQL verification) are both decided in Phase 2 (Secure Design), not discovered as a testing gap in Phase 4 — the same "push the guarantee as early as the SDLC allows" principle every sibling in this series applies, instantiated here via Kotlin's own type system and Room's KSP-based compiler plugin.
2. **The exported-component surface is this app's most distinctly Android SSDLC concern**, with no equivalent weight in `app11_swift_ios`'s analysis — it earns its own SEC REVIEW gate checklist item (§2.3) and its own quarterly audit (§9), not because Android is "less secure" than iOS in the abstract, but because the platform genuinely exposes a richer IPC surface that a misconfiguration can widen.
3. **JVM/Kotlin's SCA tooling maturity is a genuine SSDLC asset this project inherits for free**, closing a gap the Swift sibling explicitly accepted — worth noting for the course as a real example of how *ecosystem* maturity, not just language design, shapes how strong an SSDLC's Phase 4 tooling story can be.
4. **Staged rollout (§8) is a deployment-phase risk control unique to this and any other Play/App-Store-distributed sibling**, and is the most direct SSDLC analogue, for a mobile app, to a server-deployed sibling's blue/green or canary deployment strategy.
5. **R8 shrinking/obfuscation is a release-hardening step with no equivalent in any server-deployed sibling's SDLC**, because there is no "client binary" to reverse-engineer in a browser-based or server-rendered architecture — this is a defense specific to shipping a compiled artifact directly into an untrusted environment (the end user's device), the same category of concern that motivates `app11_swift_ios`'s Swift release-build stripping, stated here in Android's own idiom.

---

## 11. SDLC × SSDLC Master Mapping Table

| Classic SDLC Phase | SSDLC Addition | KotlinGuard Artifact |
|---|---|---|
| Planning | Abuse case elicitation | `requirements.md` §6 |
| Requirements Analysis | Security requirements alongside functional | `requirements.md` §2 (SR-01…SR-15) |
| Design | Trust boundary + STRIDE review, design-decision sign-off | `PLAN.md` §3, §4 (D-01…D-08) |
| Implementation | Secure coding standards enforced by static analysis, not just review | `detekt`/Android Lint custom rules, §6 above |
| Testing | SAST + SCA + property + UI testing, no DAST (no server) | `user_stories+tests.md`, §7 above |
| Deployment | Manifest/permission review, staged rollout, Play review gate | §8 above |
| Maintenance | Vitals/Crashlytics monitoring, scheduled SCA, quarterly manifest audit | §9 above |

---

## 12. Agile Ceremonies

| Ceremony | Cadence | Security-relevant addition |
|---|---|---|
| Sprint Planning | Every 2 weeks | Stories entering the sprint are checked against `requirements.md` traceability (§7) before commitment |
| Daily Standup | Daily | Blockers on the SEC REVIEW gate are called out explicitly, not folded into generic "code review" blockers |
| Backlog Refinement | Weekly | New abuse cases discovered mid-sprint (e.g., during a `detekt` rule-writing session) are added to the Abuse Case table, not left undocumented |
| Sprint Review | End of sprint | Demo includes the PL/EN toggle (FR-18) and, for sprints touching US-19, an explicit demonstration that `CardKind.DesignHarm` cannot display a severity |
| Sprint Retrospective | End of sprint | A recurring agenda item: "did the SEC REVIEW gate catch anything this sprint, and should a new automated check exist for it" — the mechanism by which this project's static-analysis rule set grows over time |

---

## 13. Summary Checklist

- [x] SSDLC activities identified for every classic SDLC phase, with explicit "does not apply, and here is why" stated where a server-oriented SSDLC concern (network segmentation, WAF, DAST) has no analogue in a client-only architecture
- [x] Agile Scrum structure defined with a security-gated Kanban board, mirroring but not blindly copying `app11_swift_ios`'s process
- [x] Definition of Done includes bilingual content review and the SEC REVIEW gate, not just "tests pass"
- [x] Threat modeling (Sprint Zero) precedes implementation, and is re-used live in-app as US-10's own content
- [x] All six YAML card decks — including Digital-by-Default Harms — in scope from Sprint Zero planning, not added later
- [x] Every named security guarantee (D-01…D-08) stated with its actual enforcement mechanism and honest limitations, never overclaimed
- [x] Android-specific SSDLC considerations (exported components, staged rollout, R8, mature SCA tooling) treated as first-class, not bolted onto a generic mobile-app template
- [x] Direct, explicit comparison to `app11_swift_ios` throughout, as this series' two native-mobile-no-backend twins
