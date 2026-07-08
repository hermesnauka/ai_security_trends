---
type: concept
title: "OWASP LLM Top 10"
address: c-000006
complexity: intermediate
domain: ai-security
aliases:
  - "OWASP Top 10 for LLM Applications"
created: 2026-07-07
updated: 2026-07-07
tags:
  - concept
  - security
  - ai-security
  - owasp
  - llm
status: current
related:
  - "[[MITRE ATLAS]]"
  - "[[CompTIA SecAI+]]"
  - "[[Agentic AI Security Principles]]"
  - "[[Security Architects Game and SecAI Threat Landscape]]"
sources:
  - "[[Security Architects Game and SecAI Threat Landscape]]"
---

# OWASP LLM Top 10

The ten most critical security risks for applications built on large language models and AI agents, per the source's 2025/2026-version summary. Complementary to [[MITRE ATLAS]]: OWASP catalogues *what* can go wrong in an LLM application's implementation; MITRE ATLAS catalogues *how* real adversaries actually carry an attack out.

## The Ten Risks

1. **LLM01 — Prompt Injection.** Manipulating the model via crafted input to ignore its original instructions. **Direct** (jailbreaking: user types "ignore previous instructions..."), or **Indirect** (malicious instructions hidden in a document/webpage the model is asked to summarize or, for a coding agent, hidden in a file/comment it reads for context).
2. **LLM02 — Sensitive Information Disclosure.** The model leaks confidential data (PII, trade secrets, credentials) in its responses, usually from unfiltered inputs, training-data memorization, or missing RBAC.
3. **LLM03 — Supply Chain Vulnerabilities.** Building on compromised external components: an infected open-source model download (e.g. from Hugging Face), malicious Python packages, or a compromised data vendor.
4. **LLM04 — Data and Model Poisoning.** Deliberately injecting flawed, biased, or malicious data into a training set or a RAG knowledge base to manipulate future outputs, degrade accuracy, or plant a backdoor.
5. **LLM05 — Improper Output Handling.** Blindly trusting and forwarding LLM-generated output for execution — the classic path to XSS, SQL injection, or remote code execution if the model is coaxed into emitting a malicious payload.
6. **LLM06 — Excessive Agency.** An agentic AI system given more permission than it needs (e.g. full DB write access instead of read-only) or the ability to take high-impact actions (send email, delete files) without a human-in-the-loop check.
7. **LLM07 — System Prompt Leakage.** Extracting a model's hidden system instructions, which often contain business logic, behavioral design, or even embedded API keys.
8. **LLM08 — Vector and Embedding Weaknesses.** RAG/vector-database-specific flaws: cross-tenant data leakage between customers sharing one vector store, embedding poisoning, or vector-inversion attacks to reconstruct original confidential text.
9. **LLM09 — Misinformation / Overreliance.** Models hallucinate fluently and convincingly; blind trust in LLM output without verification leads to legal, financial, or reputational mistakes.
10. **LLM10 — Unbounded Consumption.** Denial-of-service against the model itself: attackers force maximal context expansion and token generation, degrading service for others and running up cloud API costs (a "denial of wallet" attack).

## Relationship to Classic OWASP Top 10

OWASP is not a single list — it runs parallel Top 10s for Web, API, Mobile, and LLM applications. See [[STRIDE Threat Modeling]] for how this source maps the *classic* Web Top 10 (A01-A10) onto STRIDE letters, which is the bridge the [[Security Architects (game)]] card mechanic uses.

## In CompTIA SecAI+

[[CompTIA SecAI+]] maps its own "AI as attack target" curriculum block almost one-to-one onto this list — see that page for the exam-oriented framing and the AI-as-weapon counterpart this list does not cover (deepfakes, polymorphic malware, AI-assisted vulnerability discovery).
