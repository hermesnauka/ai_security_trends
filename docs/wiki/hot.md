---
type: meta
title: "Hot Cache"
updated: 2026-07-07T09:00:00
tags:
  - meta
  - hot-cache
status: evergreen
related:
  - "[[index]]"
  - "[[log]]"
  - "[[Wiki Map]]"
  - "[[getting-started]]"
  - "[[DragonScale Memory]]"
---

# Recent Context

Navigation: [[index]] | [[log]] | [[overview]]

> Rewritten from scratch 2026-07-07 (second rewrite same day) per the wiki skill's own rule ("overwrite completely, it is a cache not a journal"). Full history in [[log]] and dated pages under `wiki/meta/`.

## Last Updated

2026-07-07: Two large ingests landed earlier today — [[Security Architects Game and SecAI Threat Landscape]] (Polish AI-security transcript → 9 pages: [[Security Architects (game)]], [[STRIDE Threat Modeling]], [[OWASP LLM Top 10]], [[MITRE ATLAS]], [[CompTIA SecAI+]], [[Agentic AI Security Principles]], [[Air-Gapped LLM Architecture Pattern]], [[OpenRouter]], [[NIS2 (EU Cybersecurity Directive)]]) and [[OWASP Security Course App Series]] (12 planning-only sibling apps → 15 pages, headlined by [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]]). After those ingests, answered a standard query — "jakie znasz zagrożenia z AI?" — synthesizing across all four threat-catalog pages; filed as [[jakie-zagrozenia-ai]].

## Key Recent Facts

- **Plugin version is v1.9.2**, not v1.7.1 as this cache said until today — it had gone stale across several sessions without being refreshed. Refresh after every session, not just after ingests.
- **Transport**: `.vault-meta/transport.json` (detected 2026-07-07) shows Obsidian CLI absent on this machine → `preferred: filesystem`. All vault writes this session used Claude's Read/Write/Edit directly.
- **wiki-retrieve is not provisioned** (`scripts/retrieve.py` / `.vault-meta/chunks` / bm25 index all absent) — queries use the legacy hot→index→drill read order, not hybrid retrieval.
- `flock` is unavailable in this Windows Git Bash environment — `wiki-lock.sh` / `allocate-address.sh` can't take real locks. Worked around manually during the batch ingest (single-writer, sequential). Not yet fixed in the scripts.
- Address counter at 28 (next free: `c-000028`).

## Recent Changes

- Created: [[jakie-zagrozenia-ai]] (question page), plus the 24 pages from the two ingests above.
- Updated: `wiki/index.md` (Questions section + ingest entries), `wiki/log.md` (append-only, new entries at top), `wiki/concepts/_index.md`, `wiki/entities/_index.md`, `wiki/sources/_index.md`.

## Active Threads

- **Uncommitted work is piling up**: the two ingests above plus this query's file-back are all sitting as uncommitted/untracked changes in git (confirmed via `git status` earlier this session). Nothing committed yet — ask before committing, but flag it's overdue.
- **`HERM_Agrici/`** — a separate, nested Obsidian vault (its own `.obsidian/` + a `Witaj.md`) discovered living inside this repo directory. Unclear if intentional; not yet investigated. Don't touch without asking.
- `.claude/` + `skills-lock.json` — plugin-marketplace-installed copy of the `wiki` skill from `agricidaniel/claude-obsidian` on GitHub. Looks like normal installer output, not flagged as a problem.

## Plugin State (condensed — see [[log]] for the full version history)

- Version: 1.9.2. Skills: wiki, wiki-ingest, wiki-query, wiki-lint, wiki-fold, save, autoresearch, canvas, defuddle, obsidian-bases, obsidian-markdown, wiki-cli, wiki-retrieve (opt-in), wiki-mode, think.
- DragonScale (opt-in): all 4 mechanisms shipped — fold operator, deterministic addresses, semantic tiling, boundary-first autoresearch.

## Style Preferences

- No em dashes (U+2014) or `--` as punctuation. Periods, commas, colons, or parentheses. Hyphens in compound words are fine.
- Short and direct responses. No trailing summaries.
- Parallel tool calls when independent.

## Repo Locations

- Working: `C:\Users\krish\Videos\__HERM_github\claude-obsidian`
- Public: https://github.com/AI-Marketing-Hub/claude-obsidian
