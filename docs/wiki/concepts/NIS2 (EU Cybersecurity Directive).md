---
type: concept
title: "NIS2 (EU Cybersecurity Directive)"
address: c-000012
complexity: basic
domain: security
aliases:
  - "NIS2"
  - "Network and Information Security Directive 2"
  - "UKSC (Polish implementation)"
created: 2026-07-07
updated: 2026-07-07
tags:
  - concept
  - security
  - regulation
  - eu
status: current
related:
  - "[[CompTIA SecAI+]]"
  - "[[Security Architects Game and SecAI Threat Landscape]]"
sources:
  - "[[Security Architects Game and SecAI Threat Landscape]]"
---

# NIS2 (EU Cybersecurity Directive)

An EU directive on cybersecurity that member states had to transpose into national law by mid-October 2024. Not to be confused with **NIST** (the US National Institute of Standards and Technology) — a mix-up the source explicitly corrects. In Poland, NIS2 was implemented via a major amendment to the **Ustawa o Krajowym Systemie Cyberbezpieczeństwa (UKSC)** — the National Cybersecurity System Act — fully in force as of 2026 per this source.

## Key Provisions (Polish implementation, per this source)

1. **Massively expanded scope.** The predecessor NIS1 covered a narrow set of essential-service operators (large banks, power plants, hospitals). NIS2 pulls in thousands more organizations, generally mid-size-and-larger companies (roughly 50+ employees or €10M+ turnover), split into two tiers:
   - **Essential entities** — energy, transport, banking, healthcare, water, digital infrastructure, public administration.
   - **Important entities** — postal services, waste management, chemicals, food production, medical devices, machinery, vehicles.
2. **Personal management liability.** A genuinely novel provision: company management board members are personally liable for cybersecurity compliance failures, must complete training, and must actively approve risk-management strategy. In extreme cases, a board member can be temporarily suspended from their role.
3. **New mandatory obligations**, including regular technical/organizational audits, **supply-chain security** review of vendors and subcontractors, and strict incident-reporting timelines: an early-warning notification to the relevant CSIRT within **24 hours**, a full report within **72 hours**, and a final report within **one month**. Also mandates MFA and strong cryptography for corporate communications.
4. **GDPR-style financial penalties**: up to €10,000,000 or 2% of global annual turnover for essential entities; up to €7,000,000 or 1.4% for important entities.

## Relationship to AI Security

The source explicitly ties NIS2's defensive mechanisms (training, access control, threat modeling) back to the same concepts covered in [[CompTIA SecAI+]] and the [[Security Architects (game)]] board game — the point being that NIS2 turns what used to be "an IT problem" into a board-level, personally-liable business risk, which is the same argument CompTIA SecAI+ makes for treating AI-specific risk (model poisoning, prompt injection, supply-chain-compromised model weights) as a governance concern rather than a purely technical one.
