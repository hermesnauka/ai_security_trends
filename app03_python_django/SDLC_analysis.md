# ThreatCompass 2026 — SSDLC / SDLC Analysis

**Version:** 1.1
**Date:** 2026-07-07
**Document type:** Secure Software Development Lifecycle (SSDLC) analysis, mapped against the classic SDLC
**Scope:** Full lifecycle analysis of the application defined in `PLAN.md`, `requirements.md`, and `user_stories+tests.md`
**Methodology:** Agile — Scrum for planning/cadence, Kanban overlay for the engineering + security workflow

---

## Executive Summary

ThreatCompass 2026 carries the same double obligation as its sibling projects (`app01_react`, `app02_angular`, `app04_scala_react`): it **teaches** OWASP/MITRE ATLAS/CompTIA SecAI+ security content, so it must itself **be** secure — an app about SQL Injection that is vulnerable to SQL Injection trains people with a false sense of authority.

This project adds three lifecycle wrinkles that the other three apps don't have, and this document is organized around them:

1. **A single-language, single-codebase backend** (Django/Python only — web process and Celery worker/beat processes share the same code). This removes a cross-language trust boundary, but it does **not** remove the need to reason about least privilege: the boundary simply moves *inside* Django, between modules, roles, and processes, and this document treats that boundary with the same rigor a cross-language boundary would get.
2. **A content-integrity pipeline** for six externally-authored YAML card decks (`docs/OWASP_stories/*.yaml`) that are ingested as **security-sensitive data**, not just static assets.
3. **Full bilingual delivery (PL/EN)** of both UI strings and security content, which introduces its own supply chain (translation review) and its own class of "bug" (a stale or missing translation is a content-integrity defect, not just a cosmetic one).

Security is not a phase — it is a continuous activity present in every sprint ceremony, every pull request, and every deployment. The lifecycle below follows **Agile Scrum for cadence, with a Kanban board carrying explicit security-gate columns**, per the user's request to focus on Agile/Scrum/Kanban.

---

## SSDLC vs Classic SDLC — Where Security Moves

```
Classic SDLC (security bolted on late):
  Planning & Analysis → Design → Implementation → Testing → Deployment → Maintenance
                                                        ↑
                                          Security testing added HERE — too late,
                                          architecture and code are already frozen.

SSDLC ("Shift Left" — security integrated at every stage):
  Secure          Secure       Secure            Secure          Secure           Secure
  Planning &  →   Design   →   Implementation →  Testing     →   Deployment   →   Maintenance
  Analysis        │            │                 │               │                │
    ↑             ↑            ↑                 ↑               ↑                ↑
  Threat Model   Module       Secure Django     SAST + DAST     Hardened infra   Runtime
  + Compliance   boundaries   coding standards  + SCA + abuse   + secrets mgmt   monitoring +
  mapping        + Least      + safe YAML       case tests      + CI/CD gates    patch cadence +
  (OWASP/ATLAS/  Privilege    parsing                                            card-deck
  SecAI+/GDPR)   inside the                                                      integrity review
                 monolith
```

Both models describe the **same six stages**; SSDLC's contribution is that security activities happen *inside* each stage rather than as a single gate before release. The table in the final section of this document maps every classic SDLC stage to its SSDLC security activities for this specific project.

---

## Agile Framework: Scrum for Cadence, Kanban for Flow

### Scrum structure

```
Sprint length:      2 weeks
Team size:           4–6 (3 Python/Django, 1 frontend/HTMX-Alpine, 1 QA/security, 1 PL translator part-time)
Velocity target:     ~18–22 story points/sprint
Total duration:      14 sprints (~28 weeks) — matches PLAN.md §5 phases

Ceremonies:
  Sprint Planning        — Monday, Day 1, 2h max — pulls from the Product Backlog (PLAN.md §13 + this doc's abuse cases)
  Daily Standup          — daily, 15 min, includes a mandatory "any security blocker?" round
  Mid-Sprint Security Gate — Wednesday, Day 7, 30 min — peer review of anything touching auth, the integrity/export
                             Celery tasks, or card ingestion
  Sprint Review          — Friday, Day 10, 1h — demo includes a security angle (e.g. "here is the attack-demo warning modal")
  Sprint Retrospective   — Friday, Day 10, 45 min — one mandatory security-process retro item
```

### Kanban board — security-gated columns

```
BACKLOG → SPRINT → IN DEV → SEC REVIEW → I18N REVIEW → TEST → DONE

  BACKLOG       Product backlog: user stories (US-01..US-26), bugs, abuse cases (AC-01..)
  SPRINT        Committed for the current sprint
  IN DEV        Actively coded — TDD red/green cycle in progress
  SEC REVIEW    Mandatory gate for anything touching: auth, the `integrity` app,
                YAML ingestion, raw SQL, file I/O, Celery tasks, or admin/editor permissions
  I18N REVIEW   Mandatory gate for anything adding user-visible strings or card translations —
                a native Polish speaker signs off before merge (this column does NOT exist in
                app01_react/app02_angular — it is specific to this project's i18n scope)
  TEST          Unit + DRF integration + Celery (eager-mode) + Playwright E2E running in CI
  DONE          Meets the Definition of Done below

WIP limits:  IN DEV ≤ 2/dev · SEC REVIEW ≤ 3 total · I18N REVIEW ≤ 3 total · TEST ≤ 5 total
```

### Definition of Done (security- and i18n-enforced)

```
CODE QUALITY
  [ ] pytest suite passes; coverage ≥ 85% on services/selectors
  [ ] Ruff/Black clean
  [ ] No Bandit HIGH/MEDIUM findings

SECURITY GATES
  [ ] SAST passed with zero HIGH findings (Bandit)
  [ ] SCA passed: pip-audit / Trivy report no CVE ≥ CVSS 7.0
  [ ] Peer security review completed for anything in the SEC REVIEW trigger list above
  [ ] No secrets committed (detect-secrets / trufflehog pre-commit hook green)
  [ ] All DB access via Django ORM / parameterized queries — grep check `SELECT.*%s` / string concat forbidden
  [ ] `HashVerificationService.verify()` is called only from the management command or the
      `integrity` Celery task — never from a view, serializer, or template tag

I18N GATES
  [ ] `manage.py compilemessages --check` passes — zero missing keys in either `pl` or `en` `.po`
  [ ] Any new/changed card translation reviewed and signed off by a native Polish speaker
  [ ] No hardcoded user-visible string added outside `{% trans %}` / `gettext_lazy`

DOCUMENTATION
  [ ] `requirements.md` traceability updated if scope changed
  [ ] `user_stories+tests.md` TDD test list updated for the story being closed
```

---

## Phase 0 — Sprint Zero: SSDLC & Tooling Setup

### 0.1 Threat modeling session (uses the project's own content — dogfooding)

Sprint Zero opens with a structured threat-modeling session run *using the STRIDE Elevation-of-Privilege deck this application itself will later serve* (`docs/OWASP_stories/STRIDE__eop-cards-5.0-en.yaml`). Three system components are modeled first, because they are the highest-risk parts of the architecture:

| Component | STRIDE categories in scope | Key finding → design decision |
|---|---|---|
| `integrity` app (hash verification) | Tampering, Elevation of Privilege | → `HashVerificationService.verify()` is only reachable from the management command and a Celery task, never from a view (`FR-14.3`) |
| YAML card ingestion (`load_cornucopia_cards`) | Tampering, Repudiation | → `yaml.safe_load` only, SHA-256 verification, CODEOWNERS review (`FR-16`) |
| PL/EN translation storage | Information Disclosure (mistranslation leaking wrong severity), Repudiation (who approved a translation?) | → translations stored in DB with a `verified_by` reviewer field, never machine-translated at request time (`FR-17.6`) |
| Celery broker (Redis) | Spoofing, Denial of Service | → password-protected broker, not published on the host, so no external process can inject a fake export/re-ingestion job (`NFR-02.8`) |

### 0.2 Security tooling setup (added to CI before any feature branch merges)

```yaml
# .github/workflows/ci.yml (excerpt)
- name: Python SAST
  run: bandit -r backend_django -ll
- name: Python SCA
  run: pip-audit -r backend_django/requirements.txt
- name: Container scan
  run: trivy image threatcompass-django:latest
- name: i18n key parity
  run: python manage.py compilemessages --check
- name: DAST baseline (every PR, passive only)
  run: docker run -t ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t https://staging.threatcompass.local
```

### 0.3 Branch protection

- `main` requires 1 approval + all CI checks green + no `SEC REVIEW`/`I18N REVIEW` Kanban card still open for the linked issue.
- CODEOWNERS: `@security-team` required for `backend_django/cards/`, `backend_django/integrity/`, `data/hashes.json`, and any `docs/OWASP_stories/*.yaml` change.

---

## Phase 1 — Planning & Analysis (Secure Requirements)

### 1.1 Business goals vs security constraints

| Business goal | Security constraint it must respect |
|---|---|
| Teach OWASP/ATLAS/SecAI+ content accurately and fast | Content integrity (FR-16) must not be sacrificed for speed of publishing |
| Serve both PL and EN learners | Missing translations must degrade gracefully (FR-17.6), never expose a blank/broken page |
| Keep the stack simple (single language) | Simplicity must not become an excuse to skip least-privilege thinking — see Phase 2 |
| Let editors update content | Cornucopia card records stay read-only (C-08) — editors cannot silently rewrite externally-sourced security content |

### 1.2 Compliance requirements mapping

| Regulation / standard | Relevance | Where it lands in requirements.md |
|---|---|---|
| GDPR / RODO | User accounts, bookmarks, translator reviewer identity | NFR-02 (no unnecessary PII), FR-11 (anonymous bookmarks by default) |
| EU AI Act (transparency, Art. 13) | `dbd` harms deck explicitly references this | FR-13.6, SCR-05 |
| NIS2 / Polish KSC (Krajowy System Cyberbezpieczeństwa) | Educational content on GRC topics | SCR-04 |
| WCAG 2.1 AA | Public-facing educational tool | NFR-03.3 |

### 1.3 Security requirements traceability (excerpt)

| Requirement | Threat addressed | Verified by |
|---|---|---|
| NFR-02.7 (`yaml.safe_load` only) | Arbitrary code execution via crafted YAML (`!!python/object` deserialization gadget) | Bandit rule `B506`, unit test asserting `yaml.load`/`yaml.unsafe_load` are absent from the codebase |
| FR-14.3 (`HashVerificationService` callable only from non-view code) | A compromised or buggy public view forging a fake "content verified" record | Unit test asserting the function is not imported anywhere under `*/views.py` or `*/serializers.py` (AST/import-graph check) |
| FR-05.5 (attack-demo confirmation) | Copy-pasting vulnerable "teaching" code straight into production by mistake | E2E test asserting code is not present in the DOM before confirmation |
| FR-17.10 (i18n key-parity CI check) | Silent content drift between locales (a security *content* bug, since a missing Polish mitigation description could mislead a learner) | CI step `compilemessages --check` |

### 1.4 Abuse cases (negative user stories)

| ID | Abuse case |
|---|---|
| AC-01 | An attacker submits a crafted `docs/OWASP_stories/*.yaml` PR containing a Python object-deserialization payload, hoping `load_cornucopia_cards` uses the unsafe YAML loader. |
| AC-02 | An attacker who gains code execution in a request-handling view attempts to import and call `HashVerificationService.verify()` directly to forge a "content verified" record, bypassing the management-command-only design rule. |
| AC-03 | An attacker scripts thousands of requests to `/api/v1/threats?q=...` to scrape the entire catalogue for republishing without attribution. |
| AC-04 | A malicious "editor" account tries to edit a `CornucopiaCard` description directly through the Django admin, hoping to inject misleading security guidance. |
| AC-05 | An attacker submits a translation "correction" for `description_pl` that subtly downgrades a CRITICAL mitigation's guidance (a content-integrity / social-engineering abuse case unique to the i18n feature). |
| AC-06 | A user pastes an `ATTACK_DEMO` sample straight into a real project because the warning modal was skippable via a direct API call rather than only the UI. |
| AC-07 | An attacker without valid Redis credentials attempts to enqueue a Celery task directly against the broker, trying to trigger unbounded PDF generation (resource exhaustion). |

Each abuse case becomes a **negative test** in `user_stories+tests.md`-style suites (e.g., AC-01 → `test_yaml_loader_rejects_python_object_tag`, AC-02 → `test_hash_verification_service_not_importable_from_views`, AC-04 → `test_admin_cannot_edit_cornucopiacard_via_django_admin_form`, AC-07 → `test_celery_broker_requires_password`).

---

## Phase 2 — Secure Design

### 2.1 Trust boundaries (inside a single-language monolith)

Dropping a second backend language does not remove the need for trust boundaries — it just means all of them now live *inside* one Django project. This is the key design point students should take from this project: **"one language" is not a synonym for "one trust level."**

```
┌─────────────────────────── Untrusted ───────────────────────────┐
│  Browser (any locale, any user)                                  │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ HTTPS, CSRF token, session/JWT
┌────────────────────────────── Trust Boundary 1 ──────────────────┐
│  Nginx → Django (Gunicorn) request-handling code                  │
│    - validates all input via Forms/DRF serializers                │
│    - enforces auth/roles                                          │
│    - MUST NOT import integrity.services.HashVerificationService   │
│      or call it directly (enforced by an import-graph test)       │
└───────────────────────────────┬──────────────────────────────────┘
                                 │ enqueue via Redis (password-protected, internal network only)
┌────────────────────────────── Trust Boundary 2 ──────────────────┐
│  Celery worker + beat process (same codebase, separate OS process)│
│    - runs export.tasks, cards.tasks, integrity.tasks               │
│    - is the ONLY caller of HashVerificationService.verify()        │
│    - has no HTTP listener at all — cannot be reached from a browser│
└───────────────────────────────┬──────────────────────────────────┘
                                 │ local filesystem read-only
┌────────────────────────────── Trust Boundary 3 ──────────────────┐
│  docs/OWASP_stories/*.yaml + data/hashes.json                     │
│    - treated as security-sensitive content, CODEOWNERS-gated      │
└────────────────────────────────────────────────────────────────────┘
```

**Design decision D-01:** the integrity-verification code path is deliberately given the *smallest possible* set of callers — a management command and one Celery task, nothing else. This is enforced not by a network boundary (there is none, it is the same process family) but by an **import-graph test** and code review, which is exactly the kind of control a Java/Spring developer would recognize as "package-private by convention, enforced by a linter" rather than by the JVM's own visibility modifiers. The lesson for the course: **least privilege is a design discipline, not a byproduct of splitting languages or services** — you have to choose to enforce it either way.

### 2.2 Least privilege applied to the data model

- `CornucopiaCard` has no `save()` path reachable from any view or serializer marked writable — only the management command and the Celery re-ingestion task write it, inside a DB transaction (`FR-12.2`, `C-08`).
- `editor` role can write `Threat`/`Mitigation`/`CodeSample`; only `admin` can delete.
- The Celery worker process runs with the same DB credentials as Django (there is no second credential to manage), but its *code* is scoped so tasks only ever call the specific `services.py` functions they need — a Celery task is not a general-purpose shell into the ORM.

### 2.3 STRIDE analysis of the designed architecture

| STRIDE | Applies to | Mitigation already in the design |
|---|---|---|
| Spoofing | Browser→Django session; unauthenticated Celery job injection | Django session/JWT auth; Redis `requirepass` + internal-network-only broker |
| Tampering | YAML card content; DB records | `yaml.safe_load` + SHA-256 verification; ORM-only writes; CSRF protection |
| Repudiation | Who approved a translation or a hash-allowlist update | CODEOWNERS-enforced PR review is logged in Git history; `ContentHash.verified_by` field |
| Information Disclosure | Error pages; Celery task tracebacks | `DEBUG=False` in prod, custom 500 page; Celery task failures logged server-side only, never returned to the browser |
| Denial of Service | Export jobs; search; card scraping | Celery async export (never blocks the web worker); `django-ratelimit` 60 req/min/IP; PostgreSQL GIN index for search |
| Elevation of Privilege | Editor trying to write `CornucopiaCard`; anonymous user hitting admin routes | Read-only card model at the ORM/serializer level, not just UI-hidden; Django permission classes on every admin view |

### 2.4 Data classification

| Data | Classification | Handling |
|---|---|---|
| Threat/card content (EN + PL) | Public, but integrity-critical | SHA-256 verified, CODEOWNERS-reviewed |
| User accounts (email, password hash) | Personal data | `django-allauth` hashing (Argon2/PBKDF2), never logged |
| Bookmarks (anonymous) | Non-personal | `localStorage`, never sent to the server unless the user authenticates |
| Celery/Redis broker password, `DJANGO_SECRET_KEY` | Secret | Environment variable / Docker secret, rotated quarterly |

---

## Phase 3 — Implementation (Secure Coding)

### 3.1 Secure coding standards — Python / Django

```python
# ALWAYS — ORM, never raw SQL string concatenation
Threat.objects.filter(framework__code=framework_code, severity=severity)

# ALWAYS — safe YAML loading
import yaml
with open(path, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f)          # never yaml.load() or yaml.unsafe_load()

# ALWAYS — serializer-level validation, not manual dict access
class ThreatCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Threat
        fields = [...]
        # no "code" field writable after creation — immutable identifier

# ALWAYS — integrity verification stays out of the request path
# integrity/services.py
def verify(file_name: str, computed_sha256: str) -> ContentHash:
    ...
# This function is called ONLY from:
#   cards/management/commands/load_cornucopia_cards.py
#   integrity/tasks.py::periodic_hash_reverify
# A CI check greps for "HashVerificationService" or "from integrity.services import verify"
# anywhere under */views.py, */serializers.py, */api/* and fails the build if found.

# NEVER — string-formatted queries
# Threat.objects.raw(f"SELECT * FROM threats WHERE code = '{code}'")   # FORBIDDEN, caught by Bandit B608
```

### 3.2 Secure coding standards — Celery tasks

```python
# export/tasks.py
from celery import shared_task
from export.services import build_csv_bytes, build_pdf_bytes   # business logic lives in services.py

@shared_task(bind=True, max_retries=2, soft_time_limit=30)
def generate_csv(self, filters: dict, requested_by_user_id: int) -> str:
    # ALWAYS validate the filters dict against the same serializer used by the API view —
    # a Celery task receives untrusted-shaped data (it came from a browser-originated request)
    # even though it runs in a "trusted" worker process.
    validated = ExportFilterSerializer(data=filters)
    validated.is_valid(raise_exception=True)
    return build_csv_bytes(validated.validated_data)

# NEVER let a task accept a free-form dict and pass it straight into an ORM filter(**kwargs) call —
# that reintroduces the same injection-shaped risk a view would have, just one hop later.
```

### 3.3 Sprint-by-sprint security activities

| Sprint | Feature work | Security activity in parallel |
|---|---|---|
| 1–2 | Foundation, auth | Threat model review of auth flow; Bandit wired into CI (not yet blocking) |
| 3–4 | Threat browser | SAST becomes blocking; first abuse-case tests (AC-03 rate limiting) |
| 5–7 | Card decks + integrity service | AC-01, AC-02 abuse tests written FIRST (TDD) before the ingestion command exists |
| 7–9 | 5-language code samples | Review that no `ATTACK_DEMO` sample is runnable without the confirmation gate (AC-06) |
| 9–10 | i18n | I18N REVIEW Kanban column activated; AC-05 (malicious translation) test added |
| 10–12 | Search, export, matrix | AC-07 (Celery broker auth) test added; DAST baseline extended to cover `/export/` and `/search/` |
| 12–14 | Hardening & release | Full ZAP active scan; penetration-test-style abuse case sweep across AC-01..AC-07 |

---

## Phase 4 — Security Testing

### 4.1 Test pyramid with security layers

```
E2E (Playwright)         — includes AC-01..AC-07 abuse-case scenarios end-to-end
Template/HTMX tests       — confirm partial responses never leak more than the full-page equivalent
DRF integration tests     — auth/permission boundary tests per endpoint
Unit tests (pytest)       — YAML safe-loading, hash comparison, rate-limit logic, import-graph checks,
                            Celery tasks run with CELERY_TASK_ALWAYS_EAGER=True
```

### 4.2 SAST
- **Bandit** (Python): blocking on any HIGH/MEDIUM; specifically watches for `B506` (unsafe yaml load), `B608` (SQL injection via string formatting), `B105`/`B106` (hardcoded secrets).
- A custom CI grep/AST check (not a generic SAST rule, written specifically for this project) enforces that `integrity.services.verify` has no importers outside the allowed list (Phase 3.1).

### 4.3 SCA
- `pip-audit` against `requirements.txt`, Trivy against the container image — build fails on any CVE ≥ CVSS 7.0.

### 4.4 DAST (OWASP ZAP)
- Baseline (passive) scan on every PR against a staging environment.
- Full active scan before each production release, targeting all public Django routes.

### 4.5 Abuse-case tests (integration level)
Each AC-0x from Phase 1 becomes an automated integration test executed in CI, e.g.:
```python
def test_AC01_yaml_loader_rejects_python_object_tag(tmp_path):
    malicious_yaml = "!!python/object/apply:os.system ['echo pwned']"
    (tmp_path / "evil.yaml").write_text(malicious_yaml)
    with pytest.raises(yaml.YAMLError):
        load_card_file(tmp_path / "evil.yaml")   # must use safe_load internally

def test_AC02_hash_verification_service_has_no_disallowed_importers():
    forbidden_roots = ["views.py", "serializers.py", "api/"]
    importers = find_importers("integrity.services.verify")
    assert not any(any(f in path for f in forbidden_roots) for path in importers)

def test_AC07_celery_broker_rejects_connection_without_password():
    with pytest.raises(redis.AuthenticationError):
        redis.Redis(host="redis", port=6379).ping()
```

### 4.6 Security regression testing
Every fixed security bug gets a permanent regression test tagged `@pytest.mark.security_regression`, run on every CI build, never skipped.

---

## Phase 5 — Deployment (Secure Release)

### 5.1 CI/CD pipeline with security gates (summary — full YAML lives in the repo, not duplicated here)
```
lint/format → unit tests → SAST → SCA → build image → container scan (Trivy)
   → deploy to staging → DAST baseline → E2E (Playwright) → manual QA sign-off
   → deploy to production (blue/green) → DAST full scan (scheduled, not blocking)
```

### 5.2 Infrastructure hardening checklist

```
Nginx        TLS 1.2+/1.3 only; HSTS; security headers; request size limits
Django       DEBUG=False; ALLOWED_HOSTS pinned; SECURE_* settings (SSL redirect, cookie flags)
Celery       worker/beat containers have no published ports at all — they only connect outbound
             to Redis and PostgreSQL, never accept inbound connections
PostgreSQL   least-privilege DB user for the Django app (no SUPERUSER); network isolated
Redis        password-protected (`requirepass`); not exposed on the host
Docker       non-root user in the image; read-only root filesystem where feasible
```

### 5.3 Secrets management
`.env` files never committed (`.gitignore` already covers this at repo root); `DJANGO_SECRET_KEY`, the Redis/Celery broker password, and DB credentials are injected via Docker secrets / GitHub Actions secrets, rotated quarterly and immediately on suspected exposure.

---

## Phase 6 — Maintenance & Runtime Monitoring

### 6.1 Runtime monitoring
- Prometheus + `django-prometheus` for request metrics; a dedicated Celery task exports queue depth/failure-rate metrics.
- Grafana dashboards: request latency, `django-ratelimit` block rate, YAML integrity-check pass/fail metric, Celery export queue depth.
- Loki alert `SEC-CARD-HASH-MISMATCH` fires directly from the ingestion command's/task's log line (Phase 0/2 threat model finding, closing the loop).

### 6.2 Patch management (Kanban)
A dedicated `DEPENDENCY UPDATES` swimlane on the Kanban board, fed weekly by Dependabot (Python + Docker base image); any CVE ≥ CVSS 7.0 auto-creates a `SEC REVIEW`-gated card with a 5-business-day SLA.

### 6.3 Incident response (outline)
1. Detect (monitoring alert or report) → 2. Contain (feature flag / disable route) → 3. Eradicate (patch) → 4. Recover (redeploy) → 5. Post-mortem, feeding new abuse cases back into Phase 1.

### 6.4 Content & translation review schedule
- Quarterly re-verification that every `CornucopiaCard.content_sha256` still matches its source YAML (catches accidental or malicious drift).
- Quarterly Polish translation audit sampling 10% of `description_pl` fields against the current `description_en` for staleness (flagged via the `content_sha256` comparison described in `PLAN.md` §11 risk register).

---

## Phase 7 — i18n-Specific SSDLC Considerations (unique to this project vs. app01/app02/app04)

Internationalization is usually treated as a UX feature with no security dimension. In this project it is explicitly a security-relevant supply chain, because the "product" is security guidance itself:

1. **Translation as a change to security content, not just UI copy.** A PR that edits `description_pl` for a CRITICAL mitigation goes through the same `SEC REVIEW`-adjacent scrutiny as a code change — see AC-05.
2. **Fallback must never silently mislead.** FR-17.6's rule (fall back to English with a visible "EN" badge, never a blank field) exists specifically so a missing translation cannot be mistaken for "this threat has no mitigation."
3. **CI enforces key parity, not just presence.** `compilemessages --check` (FR-17.10) is a build-breaking gate, treated with the same severity as a failing unit test — a missing UI string is, in this app's threat model, indistinguishable in risk from a broken feature.
4. **Locale is never trusted as an authorization signal.** `Accept-Language`/`?lang=` only ever selects *which text* is shown, never *which data* the user is authorized to see — this is called out explicitly to preempt a subtle bug class where locale-based branching accidentally becomes an access-control check.

---

## SDLC × SSDLC Master Mapping Table

| Classic SDLC stage | SSDLC security activity in this project | Primary artifact |
|---|---|---|
| Planning & Analysis | Threat modeling with the project's own STRIDE deck; compliance mapping (GDPR/AI Act/NIS2); abuse cases AC-01–AC-07 | `requirements.md` §1–3, this document Phase 1 |
| Design | Trust-boundary diagram (Django request path ↔ Celery worker ↔ YAML source); least privilege on `CornucopiaCard` and on `HashVerificationService`; STRIDE-per-component table | `PLAN.md` §3–4, this document Phase 2 |
| Implementation | Secure Django coding standards; TDD red-green with security tests written first | `user_stories+tests.md`, this document Phase 3 |
| Testing | SAST (Bandit + import-graph check), SCA (pip-audit/Trivy), DAST (ZAP), abuse-case integration tests | this document Phase 4 |
| Deployment | CI/CD security gates, infra hardening checklist, secrets management | this document Phase 5 |
| Maintenance | Runtime monitoring, Kanban-driven patch management, incident response, quarterly content/translation integrity review | this document Phase 6 |

---

## Agile Ceremonies — Security & i18n Integration Points

```
Sprint Planning        → New security/i18n stories pulled from backlog alongside features;
                          every card-deck story (US-20–US-26) is estimated with its Polish
                          translation review as part of the story, not a separate ticket.
Daily Standup          → "Any SEC REVIEW or I18N REVIEW blocker?" is a standing question.
Mid-Sprint Security Gate → Dedicated 30-minute slot for anything touching the `integrity` app,
                          Celery tasks, or YAML ingestion — cannot be deferred to sprint end.
Sprint Review          → Demo always includes one security-relevant moment (e.g., showing
                          the attack-demo confirmation modal, or a rejected malformed YAML PR).
Sprint Retrospective   → One mandatory retro item: "did any security or translation issue
                          reach TEST or DONE that SEC REVIEW/I18N REVIEW should have caught?"
```

---

## Summary: SSDLC Compliance Checklist for ThreatCompass 2026

```
[ ] Threat model exists and is reviewed each quarter (Phase 0, 6.4)
[ ] HashVerificationService.verify() has no callers outside the management command / Celery task (Phase 2.1, D-01)
[ ] YAML ingestion uses only the safe loader (Phase 3.1)
[ ] SAST/SCA/DAST are all CI-blocking, not advisory (Phase 4)
[ ] Every abuse case AC-01–AC-07 has an automated regression test (Phase 4.5)
[ ] i18n key parity and translation review are enforced as release gates, not best-effort (Phase 7)
[ ] Card content is read-only in the application and change-controlled at the source (C-08, FR-16)
[ ] Kanban board carries explicit SEC REVIEW and I18N REVIEW columns with WIP limits
[ ] Incident response and patch-management processes exist before, not after, first production release
```
