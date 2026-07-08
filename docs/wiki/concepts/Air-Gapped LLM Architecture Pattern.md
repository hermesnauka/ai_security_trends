---
type: concept
title: "Air-Gapped LLM Architecture Pattern"
address: c-000010
complexity: advanced
domain: ai-security
aliases:
  - "Offline LLM coding assistant architecture"
created: 2026-07-07
updated: 2026-07-07
tags:
  - concept
  - security
  - ai-security
  - java
  - architecture
status: current
related:
  - "[[Agentic AI Security Principles]]"
  - "[[MITRE ATLAS]]"
  - "[[Security Architects Game and SecAI Threat Landscape]]"
sources:
  - "[[Security Architects Game and SecAI Threat Landscape]]"
---

# Air-Gapped LLM Architecture Pattern

A concrete reference architecture from the source for running a **local, offline (air-gapped) LLM coding assistant** inside a Java shop, aimed at a senior Java developer who is also the architect of the deployment. The pattern's core claim: air-gapping eliminates the *confidentiality/exfiltration* risk almost entirely, but does **nothing** for *integrity* and *availability* risks — indirect prompt injection and insecure output handling remain the top residual dangers even fully offline.

## Layer 1 — Network Isolation (Docker Compose)

The local model server (Ollama, serving a quantized model such as Bielik or Mistral in **GGUF** format) is bound only to `127.0.0.1` and placed on an `internal: true` Docker network with no route out:

```yaml
services:
  ollama-local:
    image: ollama/ollama:latest
    ports:
      - "127.0.0.1:11434:11434"
    networks:
      - ai_isolated_net
    environment:
      - OLLAMA_NUM_PARALLEL=4   # bounds concurrency — a Model DoS mitigation
networks:
  ai_isolated_net:
    internal: true
```

`OLLAMA_NUM_PARALLEL` is the concrete defense against the **KV-cache exhaustion** attack described in the source: an attacker (or buggy caller) sending huge, repetitive prompts that fill the GPU's key/value cache and OOM-crash the shared local server for every developer using it.

## Layer 2 — Guardrails in the Java Application (LangChain4j)

A `SecureLocalAiOrchestrator` wraps two Ollama-backed models: the primary coding model, and a small, fast **guardrail model** (e.g. a quantized LlamaGuard) used purely to classify a prompt as SAFE/UNSAFE before it reaches the primary model. Processing pipeline, in order:

1. **Deterministic regex pre-filter** — cheap, catches obvious jailbreak phrases (`ignore previous instructions`, `system prompt`, `developer mode`) before spending any model inference budget.
2. **Semantic guardrail-model check** — the fast classifier model judges intent, catching injections a regex would miss.
3. **Role-separated prompt templating** — the user's code is embedded inside a fixed template that explicitly instructs the model never to execute instructions found inside the *content* it's asked to analyze (the direct mitigation for indirect prompt injection from file comments).
4. **Primary model inference** — low `temperature` (0.2) specifically to reduce code-hallucination rate.
5. **Output sanitization** — response text is scanned for dangerous constructs (`Runtime.getRuntime().exec`, `ProcessBuilder`) before being shown to the developer; a match blocks the output rather than displaying it.

This is a direct implementation of [[Agentic AI Security Principles]] rules 2 (least privilege — read-only analysis, no auto-execution), 4 (layered semantic guardrails), and part of 6 (the orchestrator is a natural place to add chain-of-thought logging, though the source's code sample doesn't implement it).

## Why Air-Gapping Doesn't Close Every Gap

Mapped onto [[MITRE ATLAS]] tactics, three risks the source flags as surviving full network isolation:

- **Reconnaissance** — an attacker with local network access can still fingerprint which model is deployed from response timing/style.
- **Initial Access** — a malicious file committed to a repository is opened by a developer's IDE agent regardless of whether that agent can reach the internet; the payload doesn't need network access to do damage locally.
- **Exfiltration (indirect)** — even air-gapped, an attacker can encode secrets as Base64 inside generated code, betting that a developer will unknowingly copy that code onto an internet-connected machine later. Air-gapping the *model* does not air-gap the *human copy-paste workflow* around it.

## Supply Chain Note

The source recommends preferring the **GGUF** and **Safetensors** model file formats over the older PyTorch `.bin`/`.pt` (pickle-based) format, because pickle deserialization can execute arbitrary code at load time — a direct instance of [[OWASP LLM Top 10]]'s LLM03 Supply Chain Vulnerabilities applied to the specific choice of model file format, and a real, orthogonal reason (beyond the file being untampered) to reject a `.pt`/`.bin` download.

## ARP note

In this networking context, "ARP" is the classic **Address Resolution Protocol**: on a local network, an attacker performing ARP spoofing could redirect traffic meant for `127.0.0.1:11434` (the local Ollama server) to their own malicious LLM endpoint, substituting backdoored generated code for legitimate output. The source's own recommendation is to require TLS + token auth even over what would otherwise be treated as a trusted `localhost` connection.
