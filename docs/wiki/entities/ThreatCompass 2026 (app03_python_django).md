---
type: entity
title: "ThreatCompass 2026 (app03_python_django)"
address: c-000018
entity_type: product
role: "Security-education web app (Python/Django, single-language monolith)"
first_mentioned: "[[OWASP Security Course App Series]]"
created: 2026-07-07
updated: 2026-07-07
tags:
  - entity
  - product
  - security
  - ai-security
status: current
related:
  - "[[Security Course App Stack Comparison]]"
  - "[[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]]"
sources:
  - "[[OWASP Security Course App Series]]"
---

# ThreatCompass 2026 (app03_python_django)

Planning-only security-education app built 100% in Python: Django 5.2 LTS end-to-end, including the Celery worker/beat processes — Django Templates + HTMX 2.x + Alpine.js + Tailwind for the frontend (no separate SPA), Django REST Framework, PostgreSQL 16, Redis 7 (cache + Celery broker). A deliberate "no second backend language" contrast to the Java-backed [[SecureVision 2026 (app01_react)]]/[[ThreatView 2026 (app02_angular)]] siblings, aimed at the course's Java-background audience.

## Key Decisions

- `HashVerificationService.verify()` reachable only from the ingestion management command and a Celery task — never a public view/serializer
- Celery broker (Redis) has no published port and requires `requirepass`
- `CornucopiaCard` records read-only at the ORM/serializer level, not just UI-hidden
- YAML parsed only with `yaml.safe_load`, enforced by Bandit rule B506
- i18n key-parity (`compilemessages --check`) is CI-blocking, treated as a content-integrity defect if missing

## CardKind Pattern

**Present, but runtime-only** — see [[CardKind Pattern (Type-Safe Threat vs Design-Harm Separation)]] Tier 7. The Digital-by-Default Harms deck gets a `card_kind` field set to `"design_harm"` by the serializer, backed by one unit test; no model-level constraint or DB `CHECK` enforces the separation. Separately, `CornucopiaCard` has no `severity` field at all (an accident of the shared schema, not a targeted guarantee).

## Testing & Tooling

pytest + pytest-django + factory_boy + Hypothesis; DRF `APITestCase`; Playwright (Python) for E2E; Celery tested via `CELERY_TASK_ALWAYS_EAGER=True`. SAST: Bandit (plus a custom AST/import-graph check for `HashVerificationService` callers). SCA: pip-audit + Trivy.

## Architecture

Single-language monolith — business logic in `services.py`/`selectors.py` (not views); Celery tasks re-validate input via the same serializers as HTTP views, treating worker-process input as untrusted even though it's internal.
