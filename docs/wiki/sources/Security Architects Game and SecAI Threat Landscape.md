---
type: source
title: "Security Architects Game and SecAI+ Threat Landscape"
address: c-000003
source_type: transcript
author: ""
date_published: 2026-02-26
url: ""
confidence: medium
created: 2026-07-07
updated: 2026-07-07
tags:
  - source
  - security
  - ai-security
  - owasp
  - mitre
  - comptia
status: current
related:
  - "[[Security Architects (game)]]"
  - "[[STRIDE Threat Modeling]]"
  - "[[OWASP LLM Top 10]]"
  - "[[MITRE ATLAS]]"
  - "[[CompTIA SecAI+]]"
  - "[[Agentic AI Security Principles]]"
  - "[[Air-Gapped LLM Architecture Pattern]]"
  - "[[OpenRouter]]"
  - "[[NIS2 (EU Cybersecurity Directive)]]"
key_claims:
  - "The board game Security Architects teaches STRIDE threat modeling through a cooperative card mechanic (Component/Protection/Attack/Event cards)."
  - "OWASP Cornucopia's Companion deck extends the same card format to LLM and Agentic AI threats, cross-referencing OWASP LLM Top 10 and MITRE ATLAS IDs directly on card backs."
  - "CompTIA SecAI+ frames AI security as two tracks: AI as attack target (model/data/privacy attacks) and AI as attacker's weapon (deepfakes, polymorphic malware, automated phishing)."
  - "Securing an agentic AI coding assistant (e.g. in an IDE) requires treating every model output as untrusted input from an unknown internet user — sandboxing, least-privilege tool scopes, human-in-the-loop gates, semantic guardrails, session isolation, and full audit logging."
sources:
  - ".raw/Instrukcja do Gry Security Architects+ Comptia+OWASP LLM top10__v01b.md"
---

# Source: Security Architects Game and SecAI+ Threat Landscape

**Type**: AI-assisted research transcript (Polish, Gemini-based), translation + deep-dive analysis
**Date**: 2026-02-26 (OpenRouter/OpenClaw section dated 2026-02-26; earlier sections undated)
**Raw file**: `.raw/Instrukcja do Gry Security Architects+ Comptia+OWASP LLM top10__v01b.md` (3046 lines, Polish)

## Summary

A long, meandering Polish-language research conversation that starts by translating and analyzing the physical board game **[[Security Architects (game)]]** page-by-page (PL and EN), then expands outward into the broader 2026 AI-security curriculum landscape: OWASP Cornucopia's LLM/Agentic-AI companion cards, the **[[OWASP LLM Top 10]]**, **[[MITRE ATLAS]]**, the classic OWASP Web Top 10 mapped onto STRIDE letters, **[[CompTIA SecAI+]]** exam content, the EU's **[[NIS2 (EU Cybersecurity Directive)]]**, Red Team/Blue Team methodology, and a detailed encyclopedia of LLM/agent attacks (prompt injection, data/model poisoning, model inversion/extraction, model DoS). It closes with a concrete architecture for a **secure, air-gapped Java + Ollama + LangChain4j** local coding assistant, written from the perspective of a senior Java developer building an offline AI pair-programmer.

The questionnaire embedded mid-document (§"PROGRAM", ~line 1807) reads as training-needs intake for a SecAI+-oriented course aimed at experienced Java developers wanting to safely add local, air-gapped LLM assistants to IDEs and existing Java applications — closely matching this course's own stated audience.

## Pages Created from This Source

- [[Security Architects (game)]] — entity page for the STRIDE card game itself, full PL/EN rules summary
- [[STRIDE Threat Modeling]] — concept page, the six-letter model plus its mapping to OWASP Web Top 10 A01-A10
- [[OWASP LLM Top 10]] — concept page, LLM01-LLM10 (2025/2026) explained
- [[MITRE ATLAS]] — concept page, tactics/techniques + worked HR-chatbot kill-chain example + Lockheed Martin Cyber Kill Chain lineage
- [[CompTIA SecAI+]] — concept page, AI-as-target vs AI-as-weapon framing, GRC/NIST AI RMF
- [[Agentic AI Security Principles]] — concept page, the 6-rule checklist for safely deploying an autonomous coding agent
- [[Air-Gapped LLM Architecture Pattern]] — concept page, Docker-isolated Ollama + LangChain4j Java guardrail pattern
- [[OpenRouter]] — entity page, multi-model API aggregator and its LLMjacking risk profile
- [[NIS2 (EU Cybersecurity Directive)]] — concept page, Polish UKSC implementation

## Key Findings

1. **Cornucopia's Companion deck is the direct bridge between a physical threat-modeling card game and OWASP LLM Top 10 / MITRE ATLAS** — each Companion card cites both a Top-10 entry and an ATLAS technique ID on the card itself.
2. **The same STRIDE letters used by the board game map onto classic OWASP Web Top 10 categories** (S→A07, T→A03/A08, R→A09, I→A02/A05, D→infra/rate-limiting, E→A01) — a clean bridge between the game's teaching mechanic and real-world web AppSec.
3. **CompTIA's SecAI+ track is explicitly two-directional**: AI as a thing you must defend (data/model/privacy attacks) and AI as a thing attackers now wield (deepfakes, polymorphic malware, AI-assisted fuzzing, biometric/CAPTCHA bypass).
4. **Indirect prompt injection via IDE-opened files is the single most emphasized risk** for coding agents in this source — a hidden instruction in a code comment or README, read by an agent for context, gets treated as an instruction rather than data.
5. **Air-gapping only closes the confidentiality/exfiltration gap**, not the integrity/availability one — the source's own conclusion is that indirect prompt injection and insecure output handling remain the top residual risks even in a fully offline deployment.
6. **The document quality is uneven**: it is a raw multi-turn AI chat transcript, not an edited article. It contains at least one duplicated section (§"Rygorystyczne Przełamywanie Kontekstu" appears twice, lines 1706 and 1718-1724), a refused prompt (line 1278, model declined an ambiguous "Mitra... skąpca sekund" request), and a fully unrelated tail Q&A about Linux/VirtualBox keyboard shortcuts (lines 3018-3045) that was excluded from wiki synthesis as off-topic.

## Contradictions / Open Questions

> [!gap] Unresolved terminology
> The source uses "ARP" once to mean "Incident Address/Response Plan" (line 1546) and later correctly as "Address Resolution Protocol" (line 2586, ARP spoofing against a local Ollama server). Treat "ARP" as ambiguous without surrounding context; this wiki page follows the source's own later, standard-networking usage where relevant.

## Raw File

`.raw/Instrukcja do Gry Security Architects+ Comptia+OWASP LLM top10__v01b.md` — full bilingual game rules + threat-landscape research notes, 3046 lines.
