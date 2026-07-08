---
type: meta
title: "Wiki Index"
updated: 2026-07-07
tags:
  - meta
  - index
status: evergreen
related:
  - "[[overview]]"
  - "[[log]]"
  - "[[hot]]"
  - "[[dashboard]]"
  - "[[Wiki Map]]"
  - "[[concepts/_index]]"
  - "[[entities/_index]]"
  - "[[sources/_index]]"
  - "[[LLM Wiki Pattern]]"
  - "[[Hot Cache]]"
  - "[[Compounding Knowledge]]"
  - "[[Andrej Karpathy]]"
---

# Wiki Index

Last updated: 2026-07-07 | Total pages: 59 | Sources ingested: 4

Navigation: [[overview]] | [[log]] | [[hot]] | [[dashboard]] | [[Wiki Map]] | [[getting-started]]

---

## Concepts

- [[LLM Wiki Pattern]] — the pattern for building persistent, compounding knowledge bases using LLMs (status: mature)
- [[Hot Cache]] — ~500-word session context file, updated after every ingest and session (status: mature)
- [[Compounding Knowledge]] — why wiki knowledge grows more valuable over time, unlike RAG (status: mature)
- [[cherry-picks]] — prioritized feature backlog from ecosystem research; 13 features to add to claude-obsidian (status: current)
- [[SVG Diagram Style Guide]] — canonical visual style for all diagrams: Space Grotesk, #0A0A0A dark theme, #E07850 accent, full design tokens (status: evergreen)
- [[Pro Hub Challenge]] — community challenge pattern for building claude-seo/claude-blog extensions; first challenge produced 6 submissions, 5 integrated in v1.9.0 (status: evergreen)
- [[Semantic Topic Clustering]] — SERP-based keyword grouping replacing paid tools; hub-spoke architecture with interactive visualization (status: evergreen)
- [[Search Experience Optimization]] — "read SERPs backwards" methodology for page-type mismatch detection and persona scoring (status: evergreen)
- [[SEO Drift Monitoring]] — "git for SEO" baseline/diff/track with 17 comparison rules and SQLite persistence (status: evergreen)
- [[DragonScale Memory]] — memory-layer spec inspired by the Heighway dragon curve; fold operator, deterministic page addresses, semantic tiling, boundary-first autoresearch (status: shipped v0.4, all four mechanisms opt-in)
- [[Persistent Wiki Artifact]]: durable Markdown page as the LLM's memory object, distinct from ephemeral chat turns (status: developing)
- [[Source-First Synthesis]]: provenance discipline; raw sources stay immutable while the wiki layer is synthesized and cited (status: developing)
- [[Query-Time Retrieval]]: wiki query path synthesizes with citations; complementary to Obsidian's in-vault search (status: developing)
- [[STRIDE Threat Modeling]] — six-category threat model (Spoofing/Tampering/Repudiation/Info Disclosure/DoS/Elevation); mapped onto OWASP Web Top 10 A01-A10 (status: current)
- [[OWASP LLM Top 10]] — LLM01-LLM10 (2025/2026): prompt injection, data/model poisoning, excessive agency, model DoS, and more (status: current)
- [[MITRE ATLAS]] — adversary tactics/techniques matrix for AI systems, descendant of Lockheed Martin's Cyber Kill Chain (status: current)
- [[CompTIA SecAI+]] — AI-as-target vs AI-as-weapon certification framing; threat-to-framework mapping table (status: current)
- [[Agentic AI Security Principles]] — 6-rule checklist for safely deploying an autonomous coding agent (sandboxing, least privilege, human-in-the-loop, guardrails, session isolation, auditing) (status: current)
- [[Air-Gapped LLM Architecture Pattern]] — Docker-isolated Ollama + LangChain4j Java guardrail architecture for offline coding assistants (status: current)
- [[NIS2 (EU Cybersecurity Directive)]] — EU cybersecurity law, Polish UKSC implementation, board-level personal liability (status: current)
- [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] — 8-tier ranking of how strongly a type system/DB/convention can guarantee an invariant, across 12 languages (status: mature)

---

## Entities

- [[Andrej Karpathy]] — AI researcher, creator of the LLM Wiki pattern, former Tesla AI director (status: developing)
- [[Ar9av-obsidian-wiki]] — multi-agent compatible LLM Wiki plugin; delta tracking manifest (status: current)
- [[Nexus-claudesidian-mcp]] — native Obsidian plugin + MCP bridge; workspace memory, task management (status: current)
- [[ballred-obsidian-claude-pkm]] — goal cascade PKM; auto-commit hooks, /adopt command (status: current)
- [[rvk7895-llm-knowledge-bases]] — 3-depth query system, Marp slides, parallel deep research (status: current)
- [[kepano-obsidian-skills]] — official skills from Obsidian creator; defuddle, obsidian-bases (status: current)
- [[Claudian-YishenTu]] — native Obsidian plugin embedding Claude Code; plan mode, @mention (status: current)
- [[Claude SEO]] — Tier 4 Claude Code skill for SEO analysis; 23 skills, 17 agents, 30 scripts at v1.9.0 (status: evergreen)
- [[Security Architects (game)]] — cooperative STRIDE-teaching card game; Regular/Shift Left/Threat Modeling Workshop modes (status: current)
- [[OpenRouter]] — unified multi-model LLM API aggregator; LLMjacking/API-key-theft risk profile (status: current)
- [[SecureVision 2026 (app01_react)]] — Java/Spring Boot + React OWASP-teaching app (status: current)
- [[ThreatView 2026 (app02_angular)]] — Java/Spring Boot + Angular OWASP-teaching app (status: current)
- [[ThreatCompass 2026 (app03_python_django)]] — single-language Python/Django OWASP-teaching monolith (status: current)
- [[ScalaShield 2026 (app04_scala_react)]] — Scala/ZIO + React OWASP-teaching app (status: current)
- [[GoSentry 2026 (app05_go_react)]] — Go + React OWASP-teaching app (status: current)
- [[HaskShield 2026 (app06_HASKELL_react)]] — Haskell + React OWASP-teaching app, strongest CardKind tier (status: current)
- [[RustBastion 2026 (app07_rust_react)]] — Rust + React OWASP-teaching app, `forbid(unsafe_code)` (status: current)
- [[CppCitadel 2026 (app08_cpp_react)]] — C++ + React, deliberate memory-unsafe counter-example to RustBastion (status: current)
- [[SecurePress 2026 (app09_php_WORDPRESS)]] — WordPress plugin, MySQL CHECK-constraint CardKind pattern (status: current)
- [[SharpGuard 2026 (app10_csharp_react)]] — C#/.NET + React, config-dependent CS8509 CardKind pattern (status: current)
- [[SwiftGuard 2026 (app11_swift_ios)]] — native iOS, no backend, Apple App Review gate (status: current)
- [[KotlinGuard 2026 (app12_kotlin_android)]] — native Android, no backend, iOS's structural twin (status: current)

---

## Sources

- [[claude-obsidian-ecosystem-research]] — 2026-04-08 | web research across 16+ repos | 8 wiki pages created
- [[Security Architects Game and SecAI Threat Landscape]] — 2026-07-07 | Polish AI-security research transcript | 10 wiki pages created
- [[OWASP Security Course App Series]] — 2026-07-07 | 12 planning-doc app sets (48 files) | 15 wiki pages created

---

## Questions

- [[How does the LLM Wiki pattern work]] — how the pattern works and why it outperforms RAG at human scale (status: developing)
- [[jakie-zagrozenia-ai]] — jakie znasz zagrożenia z AI? synthesis across OWASP LLM Top 10, MITRE ATLAS, CompTIA SecAI+, Agentic AI Security Principles (status: developing)

---

## Comparisons

- [[Wiki vs RAG]] — when to use a wiki knowledge base versus RAG; verdict: wiki wins at <1000 pages
- [[claude-obsidian-ecosystem]] — feature matrix of 16+ Claude+Obsidian projects; where claude-obsidian wins and gaps
- [[Security Course App Stack Comparison]] — 12-language stack/CardKind/tooling comparison across the OWASP course app series

---

## Decisions

- [[2026-04-14-community-cta-rollout]] - Skool community CTA footer added to 6 skill repos with per-tool frequency rules (status: active)
- [[2026-04-15-slides-and-release-session]] - Claude SEO v1.9.0 slides (15-slide HTML deck) + GitHub release v1.9.0 with PDF asset (status: complete)
- [[2026-04-15-release-report-session]] - Claude SEO v1.9.0 Release Report PDF: dark theme, 13 pages, WeasyPrint layout fixes, Challenge v2 added (status: complete)
- [[2026-04-14-claude-seo-v190-session]] - Claude SEO v1.9.0 Pro Hub Challenge integration: 5 submissions, 4 new skills, 4 review rounds, cybersecurity audit (status: complete)

---

## Domains

<!-- Add domain entries here after scaffold -->
