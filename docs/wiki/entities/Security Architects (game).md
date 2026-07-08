---
type: entity
title: "Security Architects (game)"
address: c-000004
entity_type: product
role: "Cooperative card game teaching STRIDE threat modeling"
first_mentioned: "[[Security Architects Game and SecAI Threat Landscape]]"
created: 2026-07-07
updated: 2026-07-07
tags:
  - entity
  - product
  - security
  - stride
  - serious-game
status: current
related:
  - "[[STRIDE Threat Modeling]]"
  - "[[Security Architects Game and SecAI Threat Landscape]]"
sources:
  - "[[Security Architects Game and SecAI Threat Landscape]]"
---

# Security Architects (game)

A cooperative card game in which players act as a company's security team, defending IT system **Components** against **Attacks** by covering **STRIDE**-lettered vulnerabilities with **Protection** cards, while managing a shared **Reputation** track over 6 turns.

## Modes

- **Regular** — basic cooperative mode. Each turn: a protection phase (players place Protection cards from a shared pool) then a random-events phase (draw from a shared deck of Attack/Component/Event cards). A successful attack costs exactly 1 reputation point regardless of how many components it could have hit — defenders choose which component "takes the hit."
- **Shift Left** — advanced mode adding **Development** and **Production** zones. New Components land in Development first (unattackable) and move to Production only after the next protection phase. Attacks become **area-effect**: they hit *every* matching open component in Production simultaneously, so an unpatched shared vulnerability across several components can cost several reputation points in one draw. Named for the IT "shift left" philosophy of moving security/testing earlier in the SDLC — the term has no relation to the Polish card-game concept of "lewa" (trick), a coincidental phonetic collision only.
- **Threat Modeling Workshop** — a competitive/collaborative facilitation technique, not a board-based game at all. Component cards are set aside; Attack and Protection cards are dealt to real workshop participants who apply them to a diagram of the *actual* system being analyzed, arguing for or against a given risk's applicability. Points are a participation incentive, not a game outcome.

## Game Components

15 Component cards, 48 Protection cards (green backs, freely visible), 36 Attack cards, 4 single-use Threat Modeling cards, 12 Event cards, 1 Reputation tracker, 1 Round tracker, 2 Development/Production phase cards (Shift Left only).

## STRIDE Mapping

Each Component card lists which of the six STRIDE letters (Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege) it is vulnerable to. See [[STRIDE Threat Modeling]] for the full definitions and the mapping onto OWASP Web Top 10 categories that this source draws out.

## Relationship to OWASP Cornucopia

The game's underlying mechanic (STRIDE-lettered Component cards defended by matching Protection cards) is the same design lineage as the official **OWASP Cornucopia** card-game project (`cornucopia.owasp.org`, GitHub `OWASP/cornucopia`), which has since grown a *Companion Cards* extension for LLM and Agentic AI threats, directly citing [[OWASP LLM Top 10]] and [[MITRE ATLAS]] IDs. See [[Security Architects Game and SecAI Threat Landscape]] for how this source traces that lineage.
