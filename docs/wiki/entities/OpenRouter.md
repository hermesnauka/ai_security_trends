---
type: entity
title: "OpenRouter"
address: c-000011
entity_type: product
role: "Unified multi-model LLM API aggregator"
first_mentioned: "[[Security Architects Game and SecAI Threat Landscape]]"
created: 2026-07-07
updated: 2026-07-07
tags:
  - entity
  - product
  - ai-security
status: current
related:
  - "[[Agentic AI Security Principles]]"
  - "[[Security Architects Game and SecAI Threat Landscape]]"
sources:
  - "[[Security Architects Game and SecAI Threat Landscape]]"
---

# OpenRouter

A centralized API aggregator (`openrouter.ai`) giving access to most major LLM providers (OpenAI, Google, Anthropic, Mistral, etc.) through one account and one API key, on a shared prepaid-balance billing model at the same per-token price as going direct — the platform monetizes via B2B wholesale discounts rather than end-user markup. Its main practical value, per this source: it removes the need to pick a single "best" model up front, and its unified API makes multi-model fallback chains trivial to implement (see [[Air-Gapped LLM Architecture Pattern]]'s `handleAIRequest` pattern for a from-scratch equivalent using OpenAI + Anthropic SDKs directly).

## Security Profile (per this source, referencing a Feb 2026 blog post by Tomasz Dunia)

OpenRouter has no known critical vulnerabilities in its own core API. The real risk is **LLMjacking** — theft of an OpenRouter API key (typically leaked via an IDE plugin's config file accidentally committed to Git), after which an attacker runs up large usage costs on the victim's account (scraping, or training a competing model on the stolen access).

Recommended mitigations, per the source:

- Set daily/monthly budget limits in the account dashboard.
- Use OpenRouter's own Guardrails feature to reject requests containing PII before they reach a model.
- Regularly review the Activity log for anomalous usage.
- Enable two-factor authentication (2FA/MFA) on the account.
- Be aware that enabling request logging (offered in exchange for a pricing discount) trades away the platform's default **Zero Data Retention** privacy stance — a real risk for any organization piping confidential prompts through it.

## Relationship to This Vault

Directly relevant to any Claude Code / agent workflow that stores API keys in a project config file — the exact leak vector this entity page describes (`.env`, plugin settings, or MCP server config accidentally committed) is a generic risk for this vault's own multi-provider tooling, not unique to OpenRouter.
