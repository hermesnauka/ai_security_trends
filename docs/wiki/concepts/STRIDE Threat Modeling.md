---
type: concept
title: "STRIDE Threat Modeling"
address: c-000005
complexity: basic
domain: security
aliases:
  - "STRIDE"
created: 2026-07-07
updated: 2026-07-07
tags:
  - concept
  - security
  - threat-modeling
status: current
related:
  - "[[Security Architects (game)]]"
  - "[[Security Architects Game and SecAI Threat Landscape]]"
  - "[[MITRE ATLAS]]"
sources:
  - "[[Security Architects Game and SecAI Threat Landscape]]"
---

# STRIDE Threat Modeling

A six-category threat classification originally developed by Microsoft engineers, used both as a real-world threat-modeling methodology and as the core teaching mechanic of the [[Security Architects (game)]] board game and the official OWASP Cornucopia card game.

## The Six Categories

| Letter | Threat | Definition |
|---|---|---|
| **S** | Spoofing | Pretending to be someone or something else |
| **T** | Tampering | Unauthorized modification of data or code |
| **R** | Repudiation | Denying an action occurred, with no way to prove otherwise |
| **I** | Information Disclosure | Exposing sensitive information to unauthorized parties |
| **D** | Denial of Service | Degrading or crashing a system so legitimate users can't use it |
| **E** | Elevation of Privilege | Gaining access beyond what was intended |

## Mapping to OWASP Web Top 10 (2021)

This source draws an explicit letter-to-category bridge that is a genuinely useful teaching device — it is not an official OWASP mapping, but the source's own synthesis, worth treating as a plausible but non-canonical simplification:

| STRIDE | OWASP Top 10 category | Why |
|---|---|---|
| S (Spoofing) | A07: Identification and Authentication Failures | Weak login lets an attacker impersonate someone else |
| T (Tampering) | A03: Injection, A08: Software and Data Integrity Failures | SQL injection lets an attacker silently modify data |
| R (Repudiation) | A09: Security Logging and Monitoring Failures | No logs means no way to prove what happened |
| I (Information Disclosure) | A02: Cryptographic Failures, A05: Security Misconfiguration | Unencrypted connections or over-verbose errors leak data |
| D (Denial of Service) | Usually A05 or infrastructure-level (rate limiting) | Not a single numbered category in OWASP Top 10 2021 |
| E (Elevation of Privilege) | A01: Broken Access Control | Cookie/parameter tampering to gain admin rights |

## In the Game

Both the [[Security Architects (game)]] board game and OWASP Cornucopia use STRIDE letters printed on Component cards to mark open vulnerabilities; Protection cards close one letter each; a printed Attack card is only "successful" if *every* one of its listed letters is simultaneously open on the same component. See [[Security Architects (game)]] for the full ruleset, including how the Shift Left mode changes a single-letter loss into an area-effect loss across every matching open component.

## Extension to AI/LLM Threats

OWASP Cornucopia's *Companion Cards* extend the same STRIDE-card mechanic to LLM and Agentic AI threats, with each card cross-referencing an [[OWASP LLM Top 10]] entry and a [[MITRE ATLAS]] technique ID directly. This is the bridge this source uses to go from a physical board game to the modern AI threat landscape.
