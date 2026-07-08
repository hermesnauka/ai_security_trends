# ThreatCompass 2026 — Application Development Plan

**Version:** 1.1
**Date:** 2026-07-07
**Status:** Living document — updated after each sprint planning session
**Directory:** `app03_python_django`
**Sibling projects:** `app01_react` (Java/Spring Boot + React), `app02_angular` (Java/Spring Boot + Angular), `app04_scala_react` (Scala + React)

---

## 0. Note on the Stack

This application is written **entirely in Python, using Django**, end to end — there is no second backend language or microservice. This is a deliberate contrast with the sibling projects (`app01_react`/`app02_angular` are Java/Spring Boot backends; `app04_scala_react` is Scala): this project gives the course's Java-background audience a clean, single-language Django reference implementation to compare against.

Everything that might otherwise be split into a separate service — content-integrity verification of the OWASP Cornucopia YAML decks, cross-framework matrix computation, PDF/CSV export — is implemented as ordinary Django app code (`services.py` modules) and, where it benefits from running off the request/response cycle, as **Celery tasks** running in a separate *process* but the same *language and codebase*. Section 3 shows exactly how these pieces fit together and where the trust boundaries actually are in a single-language stack.

**Note on code samples:** the application still *teaches* countermeasures in five languages — Python, Java, Go, Scala, and Lua (see Section 8) — because that is separate, deliberately polyglot **content**, not the application's own runtime. A page of ThreatCompass can show a Java Spring Security snippet as an example of a secure pattern without a single line of the application itself being written in Java.

---

## 1. Project Overview

**Name:** ThreatCompass 2026
**Purpose:** A bilingual (Polish/English) reference and learning platform mapping security threats, vulnerabilities and mitigations across **OWASP** (Web Top 10, LLM Top 10, Agentic AI Top 10, API Security Top 10, Client-Side Top 10, CI/CD Security Top 10, Automated Threats/OAT, MASVS), **MITRE ATLAS** (adversarial ML tactics/techniques), and **CompTIA Security+ SY0-701 / SecAI+**, plus the full catalogue of **OWASP Cornucopia-family card decks** found in `docs/OWASP_stories/*.yaml`. Each threat is presented with working countermeasure code in **five languages**: Python, Java, Go, Scala, and Lua.

**Source material:** `docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md` (translated "Security Architects" card-game analysis + SecAI+ mapping tables) and the six card decks under `docs/OWASP_stories/`:

| File | Edition | Suits |
|---|---|---|
| `webapp-cards-3.0-en.yaml` | OWASP Cornucopia — Website App v3.0 | VE, AT, SM, AZ, CR, C, WC |
| `mobileapp-cards-1.1-en.yaml` | OWASP Cornucopia — Mobile App v1.1 | PC, AA, NS, RS, CRM, CM, WC |
| `__LLM_AI___companion-cards-1.0-en.yaml` | OWASP Cornucopia — Companion (AI/Cloud/DevOps) v1.0 | LLM, CLD, FRE, DVO, BOT, AAI, Common |
| `STRIDE__eop-cards-5.0-en.yaml` | Microsoft "Elevation of Privilege" (STRIDE) v5.0 | SP, TA, RE, ID, DO, EP |
| `RISKS__elevation-of-mlsec-cards-1.0-en.yaml` | "Elevation of MLSec" v1.0 | EMR, EIR, EOR, EDR |
| `dbd-cards-1.0-en.yaml` | Digital-by-Default Harms Deck v1.0 | SCO, ARC, AGE, TRU, POR, COR, WC |

**UI languages:** Polish (default) and English, switched instantly with no page reload; toggle persists in `localStorage` **and**, for authenticated users, in the Django session/DB profile.

---

## 2. Technology Stack

### Backend (100% Python / Django)
| Layer | Technology | Version (2026) |
|---|---|---|
| Runtime | Python | 3.13 |
| Framework | Django | 5.2 LTS |
| API layer | Django REST Framework (DRF) | 3.16.x |
| Templating | Django Templates + HTMX 2.x + Alpine.js 3.x | — |
| i18n | Django `django.utils.translation` + `gettext` (`.po`/`.mo`) | — |
| Persistence | PostgreSQL 16 | via Django ORM |
| Cache / rate limit backend | Redis 7 | `django-redis` |
| Async tasks | Celery 5 + Redis broker | export jobs, YAML re-ingestion, periodic integrity re-checks |
| Auth | `django-allauth` + DRF Token/JWT (`djangorestframework-simplejwt`) | admin/editor roles |
| Migrations | Django migrations | — |
| Docs | `drf-spectacular` | OpenAPI 3 / Swagger UI |
| Testing | `pytest`, `pytest-django`, `factory_boy`, `Hypothesis` | TDD — see `user_stories+tests.md` |
| Rate limiting | `django-ratelimit` | per-IP throttling on public API |
| Input sanitization | `bleach` (HTML) + DRF serializer validation | — |
| YAML parsing | `PyYAML` (`safe_load` only — never `yaml.load`) | — |
| Hashing / integrity | `hashlib` (stdlib SHA-256) | — |
| PDF export | WeasyPrint (HTML→PDF, reuses Django templates) | — |
| CSV export | Python stdlib `csv` module | — |
| Static files | `django-compressor` / WhiteNoise | — |

### Frontend
Django serves its own frontend — **no separate SPA build** (deliberate contrast with `app01_react`/`app02_angular`/`app04_scala_react`):
| Layer | Technology |
|---|---|
| Templates | Django Templates (server-rendered, SEO-friendly, fast first paint) |
| Interactivity | HTMX 2.x (partial page swaps: filters, search, tabs) |
| Micro-interactivity | Alpine.js 3.x (language toggle, dark mode, copy-to-clipboard) |
| Styling | Tailwind CSS 3.x (compiled at build time, no CDN at runtime) |
| Syntax highlight | Pygments (server-side, no client JS bundle needed) |
| Charts / heatmap | Chart.js (loaded locally, no CDN) |

### Infrastructure
| Component | Technology |
|---|---|
| Reverse proxy | Nginx |
| Container | Docker + Docker Compose |
| CI/CD | GitHub Actions |
| Monitoring | Grafana + Loki + Prometheus (`django-prometheus`) |
| Secrets | Docker Secrets / GitHub Secrets / `.env` (never committed) |
| SAST | Bandit (Python) + `eslint-plugin-security` (Alpine snippets) |
| DAST | OWASP ZAP |
| SCA | `pip-audit` + Trivy (containers) |

---

## 3. High-Level Architecture

```
Browser (Django templates + HTMX + Alpine.js, PL/EN)
        │
        │  HTTPS
        ▼
  Nginx (port 443)
   ├── /            ─────► Django (Gunicorn, port 8000)
   │                          ├── urls.py → apps: frameworks, threats, cards, matrix,
   │                          │            search, export, integrity, i18n, accounts
   │                          ├── DRF API under /api/v1/*
   │                          └── enqueues Celery tasks (export, YAML re-ingest, integrity re-check)
   │
   └── /swagger-ui/  ─────► drf-spectacular (Django, public read-only docs)

Celery workers (same Django codebase, separate OS process)
   ├── export.tasks.generate_csv / generate_pdf   ← csv module / WeasyPrint
   ├── cards.tasks.reingest_cornucopia_decks       ← calls integrity.services.HashVerificationService
   └── integrity.tasks.periodic_hash_reverify       ← scheduled via Celery beat

PostgreSQL 16   ◄── Django ORM (threats, mitigations, code samples, translations, users)
Redis 7         ◄── Django cache, Celery broker (password-protected, not exposed on the host), django-ratelimit counters
```

**Where the trust boundaries actually are (teaching point, reinforced in `SDLC_analysis.md`):** removing the second language does not remove the need to think about least privilege — it just moves the boundary *inside* Django. The `integrity` app's `HashVerificationService` is the **only** code path allowed to mark a `ContentHash` as valid; it is never called from a request-handling view, only from the management command and the Celery task, so a compromised public-facing view cannot forge an integrity pass. The Celery broker (Redis) requires a password and is not published on the host, so a process outside the Docker network cannot inject fake export/re-ingestion jobs.

---

## 4. Data Model (Django ORM — `models.py` per app)

### 4.1 `frameworks.Framework`
```python
class Framework(models.Model):
    code = models.CharField(max_length=32, unique=True)   # "OWASP_WEB", "OWASP_LLM", "MITRE_ATLAS",
                                                            # "COMPTIA_SECAI", "CORNUCOPIA_WEBAPP",
                                                            # "CORNUCOPIA_MOBILE", "CORNUCOPIA_COMPANION",
                                                            # "STRIDE_EOP", "MLSEC", "DBD_HARMS"
    name = models.CharField(max_length=200)
    version = models.CharField(max_length=20)
    description = models.TextField()
    reference_url = models.URLField()
```

### 4.2 `threats.Threat`
```python
class Threat(models.Model):
    framework = models.ForeignKey(Framework, on_delete=models.PROTECT, related_name="threats")
    code = models.CharField(max_length=40)         # "LLM01:2025", "A03:2021", "AML.T0051", "SP3"
    title = models.CharField(max_length=300)
    severity = models.CharField(max_length=10, choices=Severity.choices)  # CRITICAL..INFO
    category = models.CharField(max_length=100)
    description = models.TextField()
    attack_vector = models.TextField(blank=True)
    attack_surface = models.TextField(blank=True)
    stride = models.CharField(max_length=6, blank=True)   # e.g. "SI" for combined Spoof+InfoDisclosure
    tags = models.JSONField(default=list)
```

### 4.3 `threats.ThreatTranslation` *(i18n)*
```python
class ThreatTranslation(models.Model):
    threat = models.ForeignKey(Threat, on_delete=models.CASCADE, related_name="translations")
    locale = models.CharField(max_length=5, choices=[("pl", "Polski"), ("en", "English")])
    title = models.CharField(max_length=300)
    description = models.TextField()
    attack_vector = models.TextField(blank=True)
    class Meta:
        unique_together = ("threat", "locale")
```

### 4.4 `cards.CornucopiaCard` *(the six YAML decks)*
```python
class CornucopiaCard(models.Model):
    card_id = models.CharField(max_length=10, unique=True)   # "VE3", "LLM4", "SPX", "EMR2", "SCO2"
    suit_code = models.CharField(max_length=10)               # "VE","AT","SM","AZ","CR","C",
                                                                # "PC","AA","NS","RS","CRM","CM",
                                                                # "LLM","CLD","FRE","DVO","BOT","AAI",
                                                                # "SP","TA","RE","ID","DO","EP",
                                                                # "EMR","EIR","EOR","EDR",
                                                                # "SCO","ARC","AGE","TRU","POR","COR","WC"
    suit_name = models.CharField(max_length=100)
    edition = models.CharField(max_length=20)   # webapp, mobileapp, companion, eop, mlsec, dbd
    value = models.CharField(max_length=2)       # "2".."10","J","Q","K","A"
    is_critical = models.BooleanField(default=False)   # true for J, Q, K, A
    description_en = models.TextField()          # verbatim from YAML
    description_pl = models.TextField()          # human-reviewed Polish translation
    misc_note = models.TextField(blank=True)
    source_url = models.URLField(blank=True)
    owasp_refs = models.JSONField(default=list)   # ["A03:2021"]
    mitre_refs = models.JSONField(default=list)   # ["AML.T0051"]
    content_sha256 = models.CharField(max_length=64)   # verified via integrity.services.HashVerificationService
    class Meta:
        indexes = [models.Index(fields=["suit_code"]), models.Index(fields=["edition"])]
```

### 4.5 `threats.Mitigation`
```python
class Mitigation(models.Model):
    threat = models.ForeignKey(Threat, null=True, blank=True, on_delete=models.CASCADE, related_name="mitigations")
    card = models.ForeignKey(CornucopiaCard, null=True, blank=True, on_delete=models.CASCADE, related_name="mitigations")
    title = models.CharField(max_length=300)
    description = models.TextField()
    mitigation_type = models.CharField(max_length=15, choices=MitigationType.choices)   # PREVENTIVE/DETECTIVE/CORRECTIVE/COMPENSATING
    effort = models.CharField(max_length=10, choices=Effort.choices)                    # LOW/MEDIUM/HIGH
    effectiveness = models.CharField(max_length=15, choices=Effectiveness.choices)       # PARTIAL/SIGNIFICANT/FULL
```

### 4.6 `threats.CodeSample`
```python
class CodeSample(models.Model):
    mitigation = models.ForeignKey(Mitigation, on_delete=models.CASCADE, related_name="code_samples")
    language = models.CharField(max_length=10, choices=Language.choices)   # PYTHON, JAVA, GO, SCALA, LUA
    sample_type = models.CharField(max_length=12, choices=SampleType.choices)  # ATTACK_DEMO, DEFENSE
    title = models.CharField(max_length=200)
    description = models.TextField()
    code = models.TextField()
    framework_hint = models.CharField(max_length=100)   # "Django 5.2 ORM", "Spring Data JPA 3.x", "Gin 1.9"...
    version_note = models.CharField(max_length=100)
```

### 4.7 `matrix.CrossReference`
```python
class CrossReference(models.Model):
    source = models.ForeignKey(Threat, on_delete=models.CASCADE, related_name="+")
    target = models.ForeignKey(Threat, on_delete=models.CASCADE, related_name="+")
    relationship = models.CharField(max_length=15, choices=Relationship.choices)  # EQUIVALENT/RELATED/MAPS_TO/PARENT_CHILD
    description = models.TextField(blank=True)
```

### 4.8 `integrity.ContentHash`
```python
class ContentHash(models.Model):
    file_name = models.CharField(max_length=100)   # "webapp-cards-3.0-en.yaml"
    sha256_hash = models.CharField(max_length=64)
    verified_at = models.DateTimeField()
    is_valid = models.BooleanField()
    verified_by = models.CharField(max_length=30, default="django-integrity-service")
```

---

## 5. Development Phases

*(Numbering aligned with the Agile/Scrum sprint plan detailed in `SDLC_analysis.md`, §4.)*

### Phase 1 — Foundation (Sprints 1–2)
Covers: US-01, US-02, US-19 (i18n skeleton)
- [ ] `django-admin startproject threatcompass` + apps: `frameworks`, `threats`, `cards`, `matrix`, `search`, `export`, `integrity`, `accounts`
- [ ] Docker Compose: PostgreSQL 16 + Redis 7 + Django (Gunicorn) + Celery worker + Celery beat + Nginx
- [ ] Django migrations for models in §4.1–4.8
- [ ] Seed command `manage.py seed_frameworks` loading OWASP Web/LLM/Agentic/API, MITRE ATLAS, CompTIA SecAI+
- [ ] DRF: `GET /api/v1/frameworks`, `GET /api/v1/threats` (paginated)
- [ ] `django-allauth` + `simplejwt` — editor/admin roles
- [ ] `drf-spectacular` at `/api/v1/schema/swagger-ui/`
- [ ] Base template with navbar, language switch stub, dark-mode stub

### Phase 2 — Core Threat Browser (Sprints 3–4)
Covers: US-02, US-03, US-04
- [ ] `GET /api/v1/threats` filters: framework, severity, stride, category, tag, q
- [ ] `GET /api/v1/threats/{id}` with nested mitigations + code samples
- [ ] Django views: `/threats/` (HTMX filter panel, no full reload), `/threats/<id>/`
- [ ] Tabs (HTMX partials): Overview | Attack Vectors | Mitigations | Code Samples | Cross-References
- [ ] Pygments syntax highlighting per code sample
- [ ] `/matrix/` page — base cross-framework table

### Phase 3 — Card Decks & Content Integrity Service (Sprints 5–7)
Covers: US-05–US-10
- [ ] YAML loader (`manage.py load_cornucopia_cards`) reading all six `docs/OWASP_stories/*.yaml` files with `yaml.safe_load`
- [ ] `integrity.services.HashVerificationService` — pure Python `hashlib.sha256`, compares against `data/hashes.json`, fail-secure if mismatch
- [ ] `cards` app: suit browsers for VE/AT/SM/AZ/CR (webapp), PC/AA/NS/RS/CRM (mobile), LLM/AAI/FRE/DVO/BOT/CLD (companion), SP/TA/RE/ID/DO/EP (STRIDE), EMR/EIR/EOR/EDR (mlsec), SCO/ARC/AGE/TRU/POR (dbd)
- [ ] Django admin: read-only card browser + `content_sha256` displayed (no inline edit — cards are content-controlled, see NFR-Security)
- [ ] `AttackDemoWarning` HTMX modal before rendering `ATTACK_DEMO` code samples
- [ ] Celery beat schedule: `integrity.tasks.periodic_hash_reverify` runs weekly

### Phase 4 — Code Samples: 5 Languages (Sprints 7–9)
Covers: US-11, US-12, US-13
- [ ] Code sample seed data for every mitigation × 5 languages (Python, Java, Go, Scala, Lua)
- [ ] Attack-demo / defense sub-tabs per sample, red-bordered warning label on `ATTACK_DEMO`
- [ ] "Copy to clipboard" (Alpine.js, no external JS dependency)
- [ ] `/matrix/mitre-atlas/` — Kill-Chain timeline (Chart.js)

### Phase 5 — i18n Polish ↔ English (Sprint 9–10)
Covers: US-19
- [ ] `LocaleMiddleware`, `USE_I18N=True`, `LANGUAGES=[("pl","Polski"),("en","English")]`
- [ ] `{% trans %}` / `{% blocktrans %}` in all templates; `django.po`/`.mo` compiled at build time
- [ ] `ThreatTranslation` served via `Accept-Language`/`?lang=` — DRF `LocaleMiddleware`-aware serializer
- [ ] Alpine.js language toggle in navbar; cookie `django_language` + `localStorage` mirror
- [ ] Code samples **never** translated — comments stay in English (see requirements FR-17.7)
- [ ] CI check: `manage.py compilemessages --check` — missing translation keys fail the build

### Phase 6 — Search, Export, Matrix Completion (Sprints 10–12)
Covers: US-14, US-15, US-16
- [ ] PostgreSQL full-text search (`SearchVector`/`SearchQuery`) across threats, mitigations, cards
- [ ] `/search/?q=` HTMX live results, highlighted excerpts
- [ ] `export.tasks.generate_csv` / `generate_pdf` (Celery) — `csv` stdlib module / WeasyPrint → signed download link
- [ ] `/matrix/llm/`, `/matrix/agentic/`, `/matrix/mobile-vs-web/`, `/stride-heatmap/`
- [ ] `django-ratelimit`: 60 req/min per IP on all public list endpoints

### Phase 7 — Hardening, Testing & Release (Sprints 12–14)
Covers: full regression across US-01–US-19
- [ ] `pytest-django` unit tests ≥ 85% coverage on `services`/`selectors`
- [ ] DRF integration tests (`APITestCase`) for every endpoint
- [ ] Playwright (Python) E2E — one scenario per user story
- [ ] Bandit in CI, zero HIGH findings
- [ ] OWASP ZAP full active scan against staging
- [ ] Production Docker image: single `python:3.13-slim` image (Django + Celery worker use the same image, different entrypoints)

---

## 6. API Endpoint Map

### Public — Django DRF (`/api/v1/*`)
```
GET  /api/v1/frameworks
GET  /api/v1/frameworks/{code}
GET  /api/v1/threats?framework=&severity=&stride=&category=&tag=&q=
GET  /api/v1/threats/{id}
GET  /api/v1/threats/{id}/mitigations
GET  /api/v1/threats/{id}/code-samples?language=JAVA
GET  /api/v1/cards?suit=LLM
GET  /api/v1/cards/{card_id}
GET  /api/v1/matrix/cross-references?source_code=LLM01
GET  /api/v1/matrix/stride-heatmap
GET  /api/v1/search?q=prompt+injection
GET  /api/v1/export?format=csv&framework=OWASP_LLM      (enqueues Celery job, returns 202 + poll URL)
GET  /api/v1/export/status/{job_id}                       (poll job status / download link)
POST /api/v1/admin/threats                                [JWT, role=editor]
PUT  /api/v1/admin/threats/{id}                           [JWT, role=editor]
DELETE /api/v1/admin/threats/{id}                          [JWT, role=admin]
GET  /api/v1/integrity/status                              [JWT, role=admin] — last verification run per YAML file
```

There is no separate "internal" API — `integrity`, `matrix`, and `export` are Django apps called in-process (management command, view, or Celery task), not network services. The only asynchronous boundary in the whole system is the Django-process ↔ Celery-worker-process split, communicating over the password-protected, non-public Redis broker.

---

## 7. Django Project / Page Structure

```
/                              Home — framework tiles, quick search, disclaimer
/frameworks/                   All frameworks
/frameworks/<code>/            Framework detail + threat list
/threats/                      Threat browser (HTMX filters)
/threats/<id>/                 Threat detail — tabs: Overview|Attack Vectors|Mitigations|Code|Cross-Refs
/cards/webapp/                 Cornucopia Website App suits (VE, AT, SM, AZ, CR, C)
/cards/mobile/                 Cornucopia Mobile App suits (PC, AA, NS, RS, CRM, CM)
/cards/companion/llm/          Companion — LLM suit
/cards/companion/agentic/      Companion — AAI suit
/cards/companion/frontend/     Companion — FRE suit
/cards/companion/devops/       Companion — DVO + BOT suits
/cards/stride/                 STRIDE EoP — 6 suits + heatmap link
/cards/mlsec/                  Elevation of MLSec — EMR/EIR/EOR/EDR
/cards/dbd-harms/              Digital-by-Default Harms deck — SCO/ARC/AGE/TRU/POR
/matrix/                       Main cross-framework matrix
/matrix/llm/                   LLM Top 10 × Companion LLM cards
/matrix/agentic/                Agentic AI Top 10 × AAI cards
/matrix/mobile-vs-web/          MASVS vs OWASP Web comparison
/stride-heatmap/                Interactive per-component STRIDE heatmap
/search/?q=...                  Global search results
/export/status/<job_id>/        Celery export job polling page
/accounts/...                   django-allauth login/logout/profile
/about/                          Sources, licenses, disclaimer
```

---

## 8. Code Sample Strategy

Every `Mitigation` ships exactly **five** `CodeSample` rows (one per language). Every `CornucopiaCard` mitigation has at least one sample demonstrating the secure pattern. These samples are educational **content** displayed inside the Django app — they are not compiled or executed by ThreatCompass itself.

| Language | Primary framework/library used in samples |
|---|---|
| Python | Django 5.2 ORM / DRF serializers, `bleach`, `secrets` |
| Java | Spring Boot 3.3, Spring Security 6, Spring Data JPA |
| Go | Gin 1.9, `pgx` v5, standard `crypto` package |
| Scala | Akka HTTP / http4s, Slick 3.x, ZIO 2 |
| Lua | OpenResty / NGINX Lua, `lua-resty-jwt`, LuaSQL |

Each sample follows the same two-part shape as `app01_react`:
```
sample_type: ATTACK_DEMO   # VULNERABLE — do not use in production
sample_type: DEFENSE       # SECURE pattern, with a one-line WHY comment
```

---

## 9. Security Data Coverage Plan

| Framework | Coverage target | Source |
|---|---|---|
| OWASP Web Top 10 (2021) | A01–A10, all 10 | seeded JSON, cross-refs to `VE/AT/SM/AZ/CR/C` cards |
| OWASP LLM Top 10 (2025) | LLM01–LLM10, all 10 | seeded JSON + `LLM` suit (Companion) |
| OWASP Agentic AI Top 10 (2026) | AgentAI01–10 | seeded JSON + `AAI` suit (Companion) |
| OWASP API Security Top 10 | API1–API10 | seeded JSON |
| OWASP Client-Side Top 10 | C01–C10 | `FRE` suit (Companion) |
| OWASP CI/CD Security Top 10 | CICD-SEC-01–10 | `DVO` suit (Companion) |
| OWASP Automated Threats (OAT) | ≥ 13 of 21 | `BOT` suit (Companion) |
| OWASP MASVS 2.0 | all 7 categories | `PC/AA/NS/RS/CRM/CM` suits (Mobile) |
| STRIDE | S,T,R,I,D,E — all 6 | `SP/TA/RE/ID/DO/EP` suits (EoP v5.0) |
| Elevation of MLSec | Model/Input/Output/Dataset Risk | `EMR/EIR/EOR/EDR` suits |
| Digital-by-Default Harms | Scope/Architecture/Agency/Trust/Porosity | `SCO/ARC/AGE/TRU/POR` suits — mapped to A04:2021 Insecure Design + GRC/AI-Act content |
| MITRE ATLAS | ≥ 15 techniques across ≥ 5 tactics | seeded JSON, cross-referenced from LLM/AAI/mlsec cards |
| CompTIA Security+ / SecAI+ | ≥ 20 topics | seeded JSON, from `docs/Security Architects...md` mapping table |

---

## 10. Card Content Pipeline (YAML → Django, integrity-checked in-process)

```
docs/OWASP_stories/
├── webapp-cards-3.0-en.yaml
├── mobileapp-cards-1.1-en.yaml
├── __LLM_AI___companion-cards-1.0-en.yaml
├── STRIDE__eop-cards-5.0-en.yaml
├── RISKS__elevation-of-mlsec-cards-1.0-en.yaml
└── dbd-cards-1.0-en.yaml
```

**Ingestion workflow:**
1. `manage.py load_cornucopia_cards` reads each YAML with `yaml.safe_load` (never the unsafe loader — these files are treated as untrusted input even though they ship in-repo).
2. For each file, the command calls `integrity.services.HashVerificationService.verify(file_name, computed_sha256)`, which compares against the allowlist in `data/hashes.json`.
3. `data/hashes.json` is updated only through a reviewed PR (CODEOWNERS: `@security-team`) — the running application itself never writes to this file.
4. On mismatch → command aborts, no partial data is written (`transaction.atomic()`), and a `SEC-CARD-HASH-MISMATCH` alert fires.
5. Polish translations (`description_pl`) are supplied by a **human-reviewed translation table** (`data/translations/cards_pl.json`), never machine-translated at request time — see `requirements.md` FR-17.
6. `integrity.tasks.periodic_hash_reverify` (Celery beat, weekly) re-runs step 2 for all six files so drift is caught even if no one re-ingests manually.

---

## 11. Risk Register for the Build

| Risk | Mitigation |
|---|---|
| YAML card files could be tampered with in a PR | CODEOWNERS review + `HashVerificationService` SHA-256 check, fail-secure |
| Polish translations drift from English source over time | `content_sha256` stored per card; translation table flags `stale=True` when English text changes |
| Large seed dataset is labor-intensive | Seed via JSON/YAML fixtures, not hand-written Python objects |
| Full-text search slow at scale | PostgreSQL `SearchVector` GIN index |
| Export jobs block the web worker | Celery async task + polling endpoint, never synchronous |
| XSS via user-submitted card notes (editor role) | `bleach.clean()` server-side + Django auto-escaping in templates |
| Scraping the full threat/card catalogue | `django-ratelimit` 60 req/min/IP + Cloudflare-style burst protection at Nginx |
| Celery broker (Redis) reachable from outside the Docker network | No published port in `docker-compose.yml`; password-protected `requirepass` |
| A compromised web view forging a fake "integrity verified" record | `HashVerificationService.verify()` is only ever invoked from the management command and the Celery task — never from a request-handling view or serializer |
| Attack-demo code confused with production-safe code | Red border + `ATTACK_DEMO` badge + confirmation modal before code is shown/copied |

---

## 12. Directory Layout

```
app03_python_django/
├── PLAN.md                          ← this file
├── requirements.md
├── user_stories+tests.md
├── SDLC_analysis.md
│
├── backend_django/
│   ├── manage.py
│   ├── pyproject.toml
│   ├── threatcompass/
│   │   ├── settings/
│   │   │   ├── base.py
│   │   │   ├── dev.py
│   │   │   └── prod.py
│   │   ├── celery.py
│   │   ├── urls.py
│   │   └── wsgi.py / asgi.py
│   ├── frameworks/         (models, views, serializers, urls, tests/)
│   ├── threats/
│   ├── cards/
│   │   └── management/commands/load_cornucopia_cards.py
│   ├── matrix/
│   │   └── services.py       ← MatrixComputationService (pure Django ORM aggregation)
│   ├── search/
│   ├── export/
│   │   └── tasks.py           ← Celery tasks: generate_csv (csv module), generate_pdf (WeasyPrint)
│   ├── integrity/
│   │   ├── services.py        ← HashVerificationService (hashlib.sha256)
│   │   ├── tasks.py            ← periodic_hash_reverify (Celery beat)
│   │   └── data/hashes.json
│   ├── accounts/
│   ├── i18n/
│   │   ├── locale/pl/LC_MESSAGES/django.po
│   │   └── locale/en/LC_MESSAGES/django.po
│   ├── templates/
│   │   ├── base.html
│   │   ├── threats/
│   │   ├── cards/
│   │   ├── export/           ← HTML templates rendered to PDF by WeasyPrint
│   │   └── partials/          ← HTMX fragments
│   ├── static/
│   │   ├── css/tailwind.css
│   │   └── js/alpine-components.js
│   └── data/
│       ├── owasp_web_top10.json
│       ├── owasp_llm_top10.json
│       ├── owasp_agentic_top10.json
│       ├── mitre_atlas.json
│       ├── comptia_secai.json
│       ├── translations/cards_pl.json
│       └── code_samples/{python,java,go,scala,lua}/
│
├── e2e/
│   └── *.spec.py             ← Playwright (Python) — one file per user story
│
└── docker-compose.yml         ← django (web), django (celery worker + beat, same image),
                                  postgres, redis, nginx
```

---

## 13. User Stories — Summary Table

*(Full list with acceptance tests in `user_stories+tests.md`.)*

| ID | Rola | Potrzeba | Cel |
|---|---|---|---|
| US-01 | security engineer | przeglądać katalog wszystkich frameworków | jeden punkt dostępu do wszystkich standardów |
| US-02 | security engineer | filtrować zagrożenia po frameworku/severity/STRIDE/tagu | szybko znaleźć istotne zagrożenia |
| US-03 | security engineer | widzieć szczegóły zagrożenia z mitigacjami i kodem | wiedzieć jak wdrożyć ochronę |
| US-04 | CompTIA SecAI+ student | zobaczyć mapowanie LLM01 ↔ MITRE ATLAS ↔ SecAI+ | zrozumieć zależności między frameworkami |
| US-05 | frontend developer | przeglądać karty FRE (Companion) | zrozumieć zagrożenia po stronie klienta |
| US-06 | ML/AI architect | przeglądać karty LLM (Companion) z macierzą LLM Top 10 | zrozumieć prompt injection, poisoning, excessive agency |
| US-07 | agentic AI developer | przeglądać karty AAI (Companion) | projektować human-in-the-loop dla agentów |
| US-08 | security architect / threat modeler | używać katalogu STRIDE EoP z heatmapą | prowadzić sesję threat modelingu |
| US-09 | ML security engineer | przeglądać karty MLSec (Model/Input/Output/Dataset Risk) | rozpoznać adversarial ML i data poisoning |
| US-10 | mobile developer | przeglądać karty Mobile (MASVS) | zrozumieć różnice mobile vs web |
| US-11 | DevSecOps engineer | przeglądać karty DVO + BOT | chronić CI/CD i bronić się przed botami |
| US-12 | polityk/product owner sektora publicznego | przeglądać kartę harms "Digital-by-Default" | ocenić ryzyko wykluczenia i nadmiernej inwigilacji w cyfrowej usłudze |
| US-13 | Java developer | zobaczyć próbkę kodu Java dla każdej mitigacji | skopiować bezpieczny wzorzec |
| US-14 | Go developer | filtrować próbki kodu po language=Go | znaleźć wzorce specyficzne dla Go |
| US-15 | Scala developer | znaleźć próbki kodu Scala dla ataków na supply chain | wdrożyć SCA w pipeline Scali |
| US-16 | Lua/OpenResty developer | zobaczyć przykłady Lua dla rate limiting | skonfigurować guardrails NGINX |
| US-17 | pentester | wyszukać frazę i znaleźć powiązane zagrożenia z obroną | złożyć checklistę testów |
| US-18 | team lead | wyeksportować przefiltrowaną listę do CSV/PDF | dodać do rejestru ryzyk |
| US-19 | polskojęzyczny student | przełączyć aplikację PL ↔ EN jednym kliknięciem | uczyć się w ojczystym języku |

---

## 14. Milestones & Acceptance Criteria

| Milestone | Deliverable | Done when |
|---|---|---|
| M1 | Working skeleton | `docker compose up` → Django home renders, `/api/v1/frameworks` returns JSON |
| M2 | Full seed data | All frameworks + threats + mitigations in DB; correct counts via API |
| M3 | Card decks ingested | All 6 YAML decks loaded; `integrity/status` reports `isValid=true` for all |
| M4 | Code samples complete | Every mitigation has 5 language samples visible on Threat Detail |
| M5 | Matrix + heatmap | Cross-reference table renders; STRIDE heatmap shows coverage % |
| M6 | Search works | Full-text search returns highlighted results |
| M7 | i18n complete | PL/EN toggle works everywhere; `compilemessages --check` passes in CI |
| M8 | Export works | CSV/PDF export completes via Celery worker, downloadable |
| M9 | Security hardening | Bandit zero HIGH; ZAP full scan zero HIGH |
| M10 | Tests green | ≥ 90% of TDD test list in `user_stories+tests.md` passing in CI |
