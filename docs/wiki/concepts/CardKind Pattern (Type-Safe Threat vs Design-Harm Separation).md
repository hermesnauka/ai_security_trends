---
type: concept
title: "CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)"
address: c-000015
complexity: advanced
domain: ai-security
aliases:
  - "CardKind"
  - "Technical Threat vs Design Harm"
created: 2026-07-07
updated: 2026-07-07
tags:
  - concept
  - security
  - type-safety
  - software-design
status: mature
related:
  - "[[Security Course App Stack Comparison]]"
  - "[[OWASP Security Course App Series]]"
  - "[[NIS2 (EU Cybersecurity Directive)]]"
sources:
  - "[[OWASP Security Course App Series]]"
---

# CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)

A recurring design problem, and case study, that appears identically across a 12-language comparison series of security-education apps (see [[OWASP Security Course App Series]]): the "Digital-by-Default Harms" content deck (exclusion-by-design harms like an online-only benefit application channel, or a smartphone-only auth requirement) is fundamentally different from a technical vulnerability card — it has no CVE-style severity rating, because "severity" implies a risk-scoring frame that doesn't fit a policy/design harm. Each app needs some mechanism to guarantee that a **design-harm** item can never accidentally carry a **Severity** value the way a **technical-threat** item does.

The value of this case study is not any single app's answer — it's that the exact same problem gets a **measurably different strength of guarantee** in each language/platform, and the series states each guarantee's real strength honestly rather than treating "we modeled it as two kinds" as automatically safe.

## The Eight Tiers (strongest to weakest, as observed across the series)

| Tier | Mechanism | Example App(s) | Why it lands here |
|---|---|---|---|
| **1 — Unconditional compile-time exhaustiveness** | Sum type / sealed hierarchy + exhaustive pattern match, no config can disable the check | Haskell (`data CardKind = TechnicalThreat Severity \| DesignHarm`, GHC `-Wincomplete-patterns -Werror`), Rust (`enum CardKind`, `clippy -D warnings`), Swift (`enum CardKind` + `switch`), Kotlin (`sealed interface CardKind` + `when` expression) | The compiler itself refuses to build if a case is unhandled; there is no settings flag, environment variable, or code path that restores the old, unsafe behavior. |
| **2 — Database-enforced, code-independent** | A `CHECK` constraint at the schema layer | PHP/WordPress (`CONSTRAINT chk_design_harm_has_no_severity CHECK (...)` on `sp_cards`) | Holds even against a direct SQL `INSERT` that bypasses the application entirely — arguably comparable to Tier 1 in strength, just enforced at a different layer (data, not types). |
| **3 — Compile-time exhaustiveness, but config-dependent** | Exhaustiveness diagnostic exists but is a warning by default, promoted to a build error only via project configuration | C# (sealed `record` + `switch` expression, Roslyn `CS8509`, promoted via `.editorconfig`/`<WarningsAsErrors>`) | The guarantee is real once configured, but a single reverted config line silently restores the unsafe default — a genuinely weaker guarantee than Tier 1, and the series' own plan says so explicitly. |
| **4 — Compile-time exhaustiveness, but developer-bypassable** | An exhaustive-checked access pattern exists, but an alternate, non-exhaustive access pattern to the same data also exists and compiles fine | C++ (`std::variant<TechnicalThreat, DesignHarm>` + exhaustive `std::visit`, but `std::get_if` silently ignores unhandled alternatives) | The safe path is real, but nothing stops a developer from reaching for the unsafe path; enforcement falls back to code review policy. |
| **5 — Constructor-signature-enforced** | No sum type; a specific constructor function simply omits the disallowed parameter from its signature | Go (`NewDesignHarmCard(...)` has no `Severity` parameter at all) | Structural, and a genuine barrier (you cannot pass an argument that doesn't exist in the signature), but it's a single function's shape, not a type-system-wide guarantee — nothing stops a *different* constructor from being added later without the same discipline. |
| **6 — Field-omission DTO + component separation, test-enforced** | A separate output shape (DTO) simply doesn't include the field; enforcement is a dedicated test asserting the field never appears | Scala (separate `DigitalHarmsService` DTO omitting `severity`, paired with a React `DesignHarmBadge` component that never shares props with `SeverityBadge`, verified by a Vitest test) | Structural at the DTO level, but nothing in the type system stops a future refactor from merging the DTOs back together and losing the guarantee; the test is the only thing that would catch it. |
| **7 — Runtime convention + single unit test** | A field is set by convention in application code (e.g. a serializer), with one test asserting the convention holds | Python/Django (`card_kind` field set to `"design_harm"` by the serializer; `CornucopiaCard` happens to have no `severity` field at all as a schema-wide accident, not a targeted guarantee) | The weakest tier that still "exists" — a single missed code path or a future serializer change could violate the invariant with no structural barrier at all. |
| **8 — Not present** | No CardKind concept, no distinguishing mechanism | Java/Spring apps (app01_react `SecureVision 2026`, app02_angular `ThreatView 2026`) | `Threat` always carries a severity enum; `CornucopiaCard` is simply a separate, independently-modeled entity with no severity field — the separation is incidental (two different schemas), not an explicit guarantee against misuse. |

## What This Teaches

1. **"We modeled it as two types" is not one guarantee — it's at least eight**, ranging from "the compiler makes it impossible" down to "we have a test that would probably catch it." Naming the exact enforcement mechanism (compiler, database, function signature, test) is what separates an honest security claim from an overclaimed one.
2. **The strongest guarantees (Tier 1) come from the type system, not from more code or more tests.** Tier 7-8 apps could add arbitrarily more tests and never reach Tier 1's guarantee, because the invariant is checked at every call site automatically only when the *type* makes the invalid state unrepresentable.
3. **A Tier 1 guarantee can still be silently defeated by idiom drift** — Kotlin's `when` guarantee only holds if it's used as an *expression* with no `else`; switching to a `when` *statement* or adding a catch-all `else` "just in case" silently reverts to Tier 8 behavior with no compiler complaint. The series' own risk registers flag this exact caveat for Kotlin, Swift, and (differently) C++.
4. **Database constraints (Tier 2) are an underused, genuinely strong option** for enforcing an invariant across every code path that touches the data — including future code paths nobody has written yet — which application-level types alone cannot do (a type system only constrains the code written *in that language*; a DB constraint constrains every writer, in any language, forever).

## See Also

[[Security Course App Stack Comparison]] for the full per-app stack/tooling comparison this pattern is extracted from, and [[OWASP Security Course App Series]] for the source material.
