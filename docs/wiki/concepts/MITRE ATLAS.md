---
type: concept
title: "MITRE ATLAS"
address: c-000007
complexity: intermediate
domain: ai-security
aliases:
  - "Adversarial Threat Landscape for Artificial-Intelligence Systems"
created: 2026-07-07
updated: 2026-07-07
tags:
  - concept
  - security
  - ai-security
  - mitre
status: current
related:
  - "[[OWASP LLM Top 10]]"
  - "[[CompTIA SecAI+]]"
  - "[[Security Architects Game and SecAI Threat Landscape]]"
sources:
  - "[[Security Architects Game and SecAI Threat Landscape]]"
---

# MITRE ATLAS

MITRE's dedicated adversary-tactics-and-techniques matrix for AI/ML systems — the AI-security analogue of the well-known **MITRE ATT&CK** framework for classic IT. Where [[OWASP LLM Top 10]] catalogues *what* implementation mistakes are dangerous, ATLAS catalogues *how* real adversaries actually execute an attack across the AI system lifecycle, organized as Tactics (the attacker's goal at a stage) each containing specific Techniques (the concrete method).

## Lineage: Lockheed Martin's Cyber Kill Chain

ATLAS (and ATT&CK before it) is a structured descendant of the **Cyber Kill Chain**, a 7-phase linear attack model created by Lockheed Martin by adapting military attack doctrine to cyberspace: Reconnaissance → Weaponization → Delivery → Exploitation → Installation → Command & Control → Actions on Objectives. Defenders only need to break the chain at any single phase to stop the attack. MITRE's contribution was to replace the Kill Chain's broad linear phases with a richer matrix: each phase becomes a **Tactic** (the goal), decomposed into many specific **Techniques** (the concrete "how").

## Key Tactics and Techniques (as summarized in this source)

| Tactic | Example Technique | What it looks like |
|---|---|---|
| Initial Access (TA0003) | AML.T0010 — ML supply chain compromise | Malicious code injected into an external ML library |
| Initial Access (TA0003) | AML.T0051 — Prompt Injection | Gaining influence over a chatbot's behavior |
| ML Attack Staging (TA0012) | AML.T0020 — Poison training data | Imperceptible perturbations added to training images/text |
| Defense Evasion (TA0008) | AML.T0043 — Adversarial perturbation | Input modified imperceptibly to humans but decision-flipping for the model (e.g. a sticker on a STOP sign fooling a self-driving car) |
| Exfiltration (TA0013) | AML.T0024 — Model extraction | Querying a commercial model millions of times to train a free clone |
| Impact (TA0014) | AML.T0029 — Denial of ML service | Overloading the GPU/TPU infrastructure serving a model |

## Worked Example: An HR Chatbot Attack Chain

The source walks a concrete 5-stage attack against a fictional corporate HR chatbot with access to employee records, illustrating how Tactics chain together:

1. **Reconnaissance** — attacker probes the chatbot with unusual questions, timing responses to fingerprint whether it's an open-source model or GPT-4-class.
2. **Initial Access** — via **Supply Chain Compromise**: attacker plants a malicious model on Hugging Face disguised as a popular tool; HR engineers download and deploy it.
3. **ML Attack Staging** — via **Data Poisoning**: attacker seeds the chatbot's knowledge base with a hidden trigger phrase ("Watermelon") that bypasses identity verification when typed.
4. **Execution** — via **Prompt Injection**: attacker (or a bribed employee) types the trigger phrase plus an instruction to dump five years of executive salary data.
5. **Exfiltration** — via **Model Extraction**: separately, a script queries the chatbot millions of times to train a free clone of the (expensive to train) proprietary model.

## Relationship to This Vault

The **Air-Gapped LLM Architecture Pattern** page describes mapping local, offline-deployment threats onto these same three tactics (Reconnaissance, Initial Access, Exfiltration) even when the network-exfiltration path is closed — see [[Air-Gapped LLM Architecture Pattern]].
