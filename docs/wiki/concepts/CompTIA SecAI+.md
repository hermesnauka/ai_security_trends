---
type: concept
title: "CompTIA SecAI+"
address: c-000008
complexity: intermediate
domain: ai-security
aliases:
  - "CompTIA Security+ SY0-701"
created: 2026-07-07
updated: 2026-07-07
tags:
  - concept
  - security
  - ai-security
  - certification
  - comptia
status: current
related:
  - "[[OWASP LLM Top 10]]"
  - "[[MITRE ATLAS]]"
  - "[[NIS2 (EU Cybersecurity Directive)]]"
  - "[[Security Architects Game and SecAI Threat Landscape]]"
sources:
  - "[[Security Architects Game and SecAI Threat Landscape]]"
---

# CompTIA SecAI+

A dedicated AI-security certification track, positioned as a specialization sitting alongside the foundational **CompTIA Security+ (SY0-701)** exam. The source frames its entire AI-security curriculum around one governing idea: AI is treated **two-directionally** — as a **new attack surface** to defend, and as a **new weapon** attackers use against you.

## Track 1 — Security+ (SY0-701): AI as Threat Vector and Defensive Tool

The foundational exam treats AI mostly as something *around* the core IT security fundamentals:

- **AI-powered attacks**: mass-personalized phishing with no language tells, deepfake voice/video (vishing, biometric bypass), polymorphic malware that rewrites its own signature via an LLM, AI-assisted vulnerability scanning.
- **Organizational/governance gaps**: "Shadow AI" (employees using public tools like ChatGPT without IT approval), leaking IP or source code into public models that may retrain on it.
- **AI in defense**: behavioral-analysis EDR/XDR, SOAR automation for blocking attacks without human intervention.

## Track 2 — SecAI+: AI as Direct Attack Target

The specialist track maps closely onto [[OWASP LLM Top 10]] and [[MITRE ATLAS]]:

- **A. Integrity attacks**: Data Poisoning, Model Poisoning (swapped weights / compromised MLOps supply chain), Adversarial Examples.
- **B. Interface/prompt attacks**: Prompt Injection (direct/indirect), System Prompt Leakage, Excessive Agency, Improper Output Handling.
- **C. Confidentiality/IP attacks**: Model Inversion, Membership Inference, Model Extraction/Theft.
- **D. Availability attacks**: Model DoS (context-window exhaustion), Denial of Wallet (token-cost exhaustion attacks).
- **E. Defensive architecture & GRC**: AI TRiSM (Trust, Risk, and Security Management), Input/Output Guardrails, Differential Privacy, NIST AI RMF, AI Act / GDPR compliance auditing.

## Threat-to-Framework Mapping Table

The source's own synthesized cross-reference table (threat → OWASP LLM Top 10 → MITRE ATLAS tactic → CompTIA role):

| Threat | OWASP LLM | MITRE ATLAS | CompTIA Role |
|---|---|---|---|
| Prompt Injection | LLM01 | TA0001 Initial Access | AI as target — direct (chat) and indirect (RAG, malicious web pages) vectors |
| Data Poisoning | LLM04 | TA0006-adjacent, poisoned supply chain | AI as target — MLOps pipeline/data warehouse vector |
| Model Theft | LLM10 | TA0010 Exfiltration | AI as target — API-querying vector to clone weights/IP |
| Excessive Agency | LLM02/LLM07 | TA0002 Execution via LLM plugins | AI as target — plugin/tool integration vulnerability |
| Membership Inference / Inversion | LLM06 | TA0009 Discovery | AI as target — confidence-score-based privacy attack |
| AI-mutating malware | n/a (infra, not LLM-app) | TA0003 Defense Evasion | AI as **weapon** — attacker uses LLM to rewrite malware signatures |
| Automated phishing/deepfake | n/a (external social-engineering) | TA0001 Reconnaissance | AI as **weapon** — victim profiling + voice/video synthesis |
| Adversarial examples | LLM01 (broad) | TA0003 Evasion via adversarial input | AI as target — imperceptible input noise to fool a classifier |

## Practical Defenses (Shift Left for AI)

The source frames mitigation around the same **Shift Left** philosophy the [[Security Architects (game)]] board game teaches: push AI risk mitigation into design, not post-deployment.

- **Guardrails** — a separate input-filtering layer before a prompt reaches the model, and an output-filtering layer before a response reaches the user or downstream system.
- **AI-BOM** (AI Bill of Materials) — a documented "digital receipt" for a model: provenance, training data, dependency libraries.
- **Least privilege for AI agents** — read-only by default; destructive actions require human authorization.
- **Rate limiting** — throttling per-account/IP query volume to blunt both DoS and model-extraction attacks.
- **Zero Trust Architecture** — assume internal network compromise; verify every device/user/data flow regardless of origin.
- **XDR/EDR** — behavior-based detection to catch polymorphic, signature-evading malware.
- **Phishing-resistant MFA** (hardware keys, FIDO2) — closes the human-targeted AI-as-weapon vector.

## See Also

[[NIS2 (EU Cybersecurity Directive)]] for the EU regulatory backdrop this training material connects the same governance concepts to, and [[Agentic AI Security Principles]] for the source's more detailed, developer-facing rule set for safely deploying an autonomous coding agent.
