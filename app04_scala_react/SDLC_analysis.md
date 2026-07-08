# ScalaShield 2026 — Analiza SSDLC

**Wersja:** 1.0  
**Data:** 2026-07-07  
**Metodologia:** Agile — Scrum + Kanban z integracją SSDLC  
**Dotyczy:** US-01 – US-19 / Scala 3.3 LTS + ZIO 2 + React 18

---

## 1. Przegląd metodologii

### 1.1 Scrum z integracją Security

Projekt realizowany w 2-tygodniowych sprintach (Sprints 1–16, 31 tygodni łącznie). Bezpieczeństwo jest wbudowane w każdy sprint — nie jest oddzielną fazą na końcu projektu. Scala 3 i ZIO 2 dostarczają mechanizmów bezpieczeństwa na poziomie systemu typów (opaque types, ZIO effect system, ZIO Quill compile-time SQL), co przesuwa wykrywanie błędów bezpieczeństwa na etap kompilacji.

**Ceremonie Scrum z wymiarem security:**

| Ceremonia | Czas | Element security |
|---|---|---|
| Sprint Planning | 4h | Każda US ma SAC (Security Acceptance Criteria) jako część DoD |
| Daily Standup | 15 min | Stały punkt: "security blocker lub nowy CVE?" |
| Sprint Review | 2h | Demo + wyniki Scalafix/Wartremover/Scapegoat z CI |
| Retrospective | 1.5h | Analiza incydentów / nieudanych SAC z minionego sprintu |
| Backlog Refinement | 2h mid-sprint | Mini-STRIDE dla US w kolejnym sprincie |

### 1.2 Kanban Security Board

```
Backlog → Security Review → In Progress → SAST Check → Code Review → Testing → Done
```

- **Security Review**: mini-STRIDE przed rozpoczęciem pracy nad US
- **SAST Check**: `sbt scalafixAll --check` + `sbt wartremover` + `sbt scapegoat` + ESLint security GREEN
- **Code Review**: min. 1 recenzja security-aware, sprawdzenie ZIO effect boundary
- **Testing**: unit (ZIO Test) + IT (Testcontainers) + E2E (Playwright) + abuse cases GREEN

### 1.3 Definition of Done (DoD) — wymiar security

Każda US jest "Done" gdy:
- [ ] `sbt scalafixAll --check` GREEN (kod nie używa unsafe patterns)
- [ ] `sbt wartremover` GREEN (w tym `NoNull`, `NonUnitStatements`, `OptionPartial`)
- [ ] ESLint security plugin GREEN dla frontendu
- [ ] Brak nowych Critical/High CVEs: `sbt dependencyCheck` + `npm audit --audit-level=high`
- [ ] ZIO effect boundary przestrzegany — brak `Future`, `try/catch` poza ZIO
- [ ] Security Acceptance Criteria (sekcja 2.3) dla danej US GREEN
- [ ] Code review zatwierdzony z adnotacją `[security-ok]`

### 1.4 Mapa sprintów

| Sprint | Tygodnie | Faza | User Stories | Główne deliverables |
|---|---|---|---|---|
| 1–2 | 1–4 | Phase 1 Foundation | US-01 | sbt scaffold, ZIO HTTP, Docker, Flyway, seed data |
| 3–4 | 5–8 | Phase 2 Core | US-02, US-03, US-04 | Tapir endpoints, ThreatService ZIO, React pages |
| 5–6 | 9–12 | Phase 3 Code Samples | US-08, US-09, US-10 | CodeSamplePanel, Shiki lazy, MITRE timeline |
| 6–7 | 11–14 | Phase 4 Advanced | US-05, US-06, US-07 | ZIO Quill FTS, CSV export, STRIDE heatmap |
| 8 | 15–16 | Phase 5 i18n | US-11 | react-i18next PL/EN, Accept-Language ZIO HTTP |
| 9 | 17–18 | Phase 6 FRE+LLM+AAI | US-12, US-13, US-14 | CornucopiaCard, YAML loader, OwaspRefValidator |
| 10–11 | 19–22 | Phase 7 STRIDE+MLSec | US-15, US-16 | STRIDE catalogue, ECharts/D3 heatmap |
| 12–13 | 23–26 | Phase 8 Mobile+DevOps | US-17, US-18 | MASVS, DVO+BOT, BotWarningModal |
| 14–16 | 27–31 | Phase 9 Hardening | All | ZIO Test, Playwright, ZAP, axe, Scoverage |

---

## 2. Faza 0 — Planowanie i modelowanie zagrożeń

### 2.1 Zbieranie wymagań bezpieczeństwa

Przed pierwszym sprintem:
- Warsztat stakeholderów: identyfikacja aktywów (YAML karty, JWT klucze, DB credentials)
- Ocena OWASP SAMM — poziom wyjściowy projektu
- Threat modeling metodą STRIDE dla ScalaShield (sekcja 2.2)
- Inicjalizacja rejestru ryzyk
- Decyzje architektoniczne D-01–D-13 zatwierdzone przez tech lead

**Unikalne cechy bezpieczeństwa Scala 3 + ZIO:**
- D-01: ZIO effect system — wszystkie efekty uboczne opisane w typie (`ZIO[R, E, A]`), brak ukrytych wyjątków
- D-02: ZIO Quill compile-time SQL — interpolacje SQL weryfikowane przez kompilator (brak runtime SQL injection przez konstrukcję zapytań)
- D-03: Scala 3 opaque types — `ThreatCode`, `CardId`, `SuitCode` — niemożliwa podmiana typów
- D-04: Wartremover `NoNull` rule — eliminacja NPE na poziomie kompilacji
- D-05: ZIO STM (Software Transactional Memory) dla rate limiter — atomowe, bez deadlocków

### 2.2 Threat Modeling — STRIDE dla ScalaShield 2026

| Kategoria STRIDE | Komponent | Zagrożenie | Ryzyko | Mitigacja |
|---|---|---|---|---|
| **S** — Spoofing | ZIO HTTP `/admin/**` routes | Nieuprawniony dostęp bez ADMIN JWT | HIGH | `JwtMiddleware.requireRole("ADMIN")` — ZIO HTTP middleware |
| **S** — Spoofing | React localStorage JWT | Token theft przez XSS → session hijacking | HIGH | HttpOnly cookie dla refresh token; access token TTL 15 min |
| **T** — Tampering | YAML card files | Modyfikacja opisów kart Cornucopia | HIGH | `ContentIntegrityVerifier` ZIO layer — SHA-256, `ZIO.die` on mismatch |
| **T** — Tampering | React `dangerouslySetInnerHTML` | XSS przez renderowanie niebezpiecznego HTML | HIGH | `DOMPurify.sanitize()` przed każdym `dangerouslySetInnerHTML` |
| **T** — Tampering | Admin CRUD endpoint | XSS payload w opisie karty przez admina | HIGH | `SafeHtml` — własny, czysto-scalowy sanitizer allow-list (PLAN.md D-14) + DOMPurify frontend |
| **R** — Repudiation | Admin CRUD ZIO HTTP | Admin zaprzecza modyfikacji karty | MEDIUM | Strukturyzowane logi Loki z `sub` claim z JWT |
| **I** — Information Disclosure | ZIO error channel | Wyciek ZIO stack trace przez HTTP 500 | MEDIUM | `ZIO.mapError(_ => ApiError("INTERNAL_ERROR", "An error occurred"))` |
| **I** — Information Disclosure | YAML git history | Ujawnienie nieopublikowanych kart | LOW | gitleaks CI + opcjonalnie git-crypt |
| **D** — Denial of Service | `GET /api/v1/threats?suit=*` | Bot scraping całego API w pętli | HIGH | ZIO STM token bucket 60 req/min per IP; HTTP 429 + `Retry-After` |
| **D** — Denial of Service | ECharts heatmap | Ciężkie dane generowane per request | MEDIUM | ZIO Redis cache TTL 5 min dla danych heatmapy |
| **E** — Elevation of Privilege | ZIO Quill queries | SQL injection przez parametr `q` | HIGH | ZIO Quill compile-time SQL — brak string concat, type-safe interpolation |
| **E** — Elevation of Privilege | ZIO HTTP routes | User bez ADMIN role wykonuje CRUD | HIGH | `requireRole` middleware + Tapir endpoint type-safety |

### 2.3 Security Acceptance Criteria (SAC)

| ID | Kryterium | Weryfikacja w CI |
|---|---|---|
| SAC-01 | Wszystkie `/admin/**` routes chronione przez `JwtMiddleware.requireRole("ADMIN")` | `AdminRoutesSpec` (ZIO Test) |
| SAC-02 | Scalafix + Wartremover + Scapegoat GREEN przed każdym merge | CI job `lint-and-sast` |
| SAC-03 | Brak High/Critical w `sbt dependencyCheck` i `npm audit` | CI job `dependency-check` |
| SAC-04 | `ContentIntegrityVerifier` ZIO layer inicjalizowany przed serwowaniem routes — `ZIO.die` on mismatch | `ContentIntegrityVerifierSpec` |
| SAC-05 | ZIO STM rate limiter zwraca 429 po > 60 req/min per IP na suit endpoints | `RateLimitSpec` |
| SAC-06 | CSP header via ZIO HTTP middleware blokuje inline scripts i eval | ZAP headerscan |
| SAC-07 | `DOMPurify.sanitize()` wywołany na wszystkich opisach kart przed React render | `ThreatCard.spec.tsx` |
| SAC-08 | Scala 3 strict mode + Wartremover `NoNull` GREEN; `sbt compile` bez błędów | CI job `build` |
| SAC-09 | Wszystkie `ATTACK_DEMO` próbki kodu oznaczone badge `PODATNY` w React UI | `CodeSamplePanel.spec.tsx` |
| SAC-10 | `BotWarningModal` wyświetlany przed kartami BOT krytycznymi | `us18-devops-security.spec.ts` |
| SAC-11 | `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` na `/stride-heatmap` | ZAP headerscan |
| SAC-12 | axe-playwright: 0 Critical/Serious WCAG 2.1 AA violations | `axe-playwright` w każdym Playwright spec |
| SAC-13 | Wszystkie 18 plików `*.spec.ts` Playwright GREEN | CI job `e2e` |
| SAC-14 | Backend Scoverage ≥ 80%; frontend V8 coverage ≥ 75% | CI jobs `unit-tests` |
| SAC-15 | DAST ZAP full active scan — 0 High/Critical na staging | CI job `dast-zap` |

---

## 3. Faza 1 — Fundament (Sprint 1–2, Tygodnie 1–4)

### 3.1 Inicjalizacja projektu Scala 3 + ZIO 2

```bash
sbt new scala/scala3.g8 --name=scalashield
```

**build.sbt — kluczowe zależności:**
```scala
val zioVersion     = "2.1.x"
val zioHttpVersion = "3.x"
val tapirVersion   = "1.x"

libraryDependencies ++= Seq(
  "dev.zio"                       %% "zio"                        % zioVersion,
  "dev.zio"                       %% "zio-http"                   % zioHttpVersion,
  "dev.zio"                       %% "io.getquill"                %% "quill-zio"     % "4.x",
  "dev.zio"                       %% "zio-redis"                  % "0.x",
  "dev.zio"                       %% "zio-test"                   % zioVersion % Test,
  "dev.zio"                       %% "zio-test-sbt"               % zioVersion % Test,
  "com.softwaremill.sttp.tapir"   %% "tapir-zio-http-server"      % tapirVersion,
  "com.softwaremill.sttp.tapir"   %% "tapir-swagger-ui-bundle"    % tapirVersion,
  "com.softwaremill.sttp.tapir"   %% "tapir-json-circe"           % tapirVersion,
  "io.circe"                      %% "circe-generic"              % "0.14.x",
  "org.flywaydb"                   % "flyway-core"                % "10.x",
  "com.googlecode.owasp-java-html-sanitizer" % "owasp-java-html-sanitizer" % "20240325.1",
  "io.github.vigoo"               %% "zio-config-typesafe"        % "4.x",
  "com.dimafeng"                  %% "testcontainers-scala-postgresql" % "0.x" % Test,
  "org.testcontainers"             % "testcontainers"             % "1.x" % Test
)
```

**project/plugins.sbt — SAST plugins:**
```scala
addSbtPlugin("ch.epfl.scala"      % "sbt-scalafix"       % "0.12.x")
addSbtPlugin("org.wartremover"    % "sbt-wartremover"    % "3.x")
addSbtPlugin("com.sksamuel.scapegoat" %% "sbt-scapegoat" % "1.x")
addSbtPlugin("net.vonbuchholtz"   % "sbt-dependency-check" % "5.x")
addSbtPlugin("org.scoverage"      % "sbt-scoverage"      % "2.x")
addSbtPlugin("com.eed3si9n"       % "sbt-assembly"       % "2.x")  // fat JAR for Docker
```

**Wartremover konfiguracja (build.sbt):**
```scala
wartremoverWarnings ++= Warts.allBut(Wart.DefaultArguments, Wart.Overloading)
wartremoverErrors   ++= Seq(
  Wart.Null,           // D-04: brak null w kodzie produkcyjnym
  Wart.Return,
  Wart.Throw,          // wymuszenie ZIO.fail zamiast throw
  Wart.AsInstanceOf,
  Wart.IsInstanceOf
)
```

### 3.2 ZIO Application Entry Point

```scala
// Main.scala
object Main extends ZIOAppDefault:

  override def run: ZIO[Any, Throwable, Unit] =
    program
      .provide(
        // ContentIntegrityVerifier inicjalizowany PRZED routes — fail-secure
        ContentIntegrityVerifier.layer,
        DatabaseLayer.live,
        RedisLayer.live,
        ThreatRepository.live,
        CardSuitRepository.live,
        ThreatService.live,
        CardSuitService.live,
        MatrixService.live,
        SearchService.live,
        HttpServer.live
      )

  private val program: ZIO[HttpServer, Throwable, Unit] =
    for
      server <- ZIO.service[HttpServer]
      _      <- server.start
      _      <- ZIO.never
    yield ()
```

```scala
// ContentIntegrityVerifier.scala
final class ContentIntegrityVerifier

object ContentIntegrityVerifier:

  val layer: ZLayer[Any, Nothing, ContentIntegrityVerifier] =
    ZLayer.scoped {
      for
        hashes    <- loadHashesJson("data/hashes.json").orDie
        _         <- ZIO.foreachDiscard(hashes.toList) { case (fileName, expectedHash) =>
                       for
                         actual <- computeSha256(s"data/cornucopia/$fileName").orDie
                         _      <- ZIO.when(actual.toLowerCase != expectedHash.toLowerCase) {
                                     ZIO.logError(
                                       s"INTEGRITY FAIL: $fileName expected=$expectedHash actual=$actual"
                                     ) *> ZIO.die(ContentIntegrityException(s"Tampered YAML: $fileName"))
                                   }
                       yield ()
                     }
        _         <- ZIO.logInfo(s"ContentIntegrityVerifier: all ${hashes.size} YAML files OK")
        verifier  <- ZIO.succeed(new ContentIntegrityVerifier)
      yield verifier
    }

  private def computeSha256(path: String): ZIO[Any, Throwable, String] =
    ZIO.attemptBlocking {
      val digest = java.security.MessageDigest.getInstance("SHA-256")
      val bytes  = java.nio.file.Files.readAllBytes(java.nio.file.Path.of(path))
      java.util.HexFormat.of().formatHex(digest.digest(bytes))
    }
```

### 3.3 ZIO HTTP Security Middleware Stack

```scala
// SecurityMiddleware.scala
object SecurityMiddleware:

  val securityHeaders: Middleware[Any] =
    addHeader("Content-Security-Policy",
      "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; " +
      "frame-ancestors 'none'; object-src 'none'") >>>
    addHeader("X-Frame-Options", "DENY") >>>
    addHeader("X-Content-Type-Options", "nosniff") >>>
    addHeader("Referrer-Policy", "strict-origin-when-cross-origin") >>>
    addHeader("Strict-Transport-Security", "max-age=31536000; includeSubDomains; preload") >>>
    addHeader("Permissions-Policy", "geolocation=(), microphone=(), camera=()")

  private def addHeader(name: String, value: String): Middleware[Any] =
    Middleware.addHeader(Header.Custom(name, value))
```

```scala
// RateLimitMiddleware.scala — ZIO STM token bucket, bez deadlocków
object RateLimitMiddleware:

  case object TooManyRequests extends Exception("Rate limit exceeded")

  def live(limit: Int = 60, windowSec: Int = 60): ZIO[Any, Nothing, Middleware[Any]] =
    for
      buckets <- TMap.empty[String, (Int, Long)].commit
    yield Middleware.interceptIncomingHandler {
      Handler.fromFunctionZIO[Request] { req =>
        val ip = req.header(Header.XForwardedFor).map(_.renderedValue).getOrElse("unknown")
        STM.atomically {
          for
            now                  <- ZSTM.succeed(System.currentTimeMillis() / 1000L)
            (count, windowStart) <- buckets.getOrElse(ip, (limit, now))
            (newCount, newStart)  = if now - windowStart >= windowSec then (limit - 1, now)
                                    else (count - 1, windowStart)
            result               <- if newCount < 0 then ZSTM.fail(TooManyRequests)
                                    else buckets.put(ip, (newCount, newStart)) *> ZSTM.succeed(req)
          yield result
        }.mapError(_ =>
          Response.status(Status.TooManyRequests)
            .addHeader(Header.Custom("Retry-After", windowSec.toString))
        )
      }
    }
```

### 3.4 CI Pipeline — GitHub Actions (Scala-specific)

```
Jobs (kolejność wykonania):

  [1] lint-and-sast
      ├── sbt scalafixAll --check
      ├── sbt wartremover (errors = fail)
      ├── sbt scapegoat
      └── gitleaks detect (secret scanning)

  [2] unit-tests
      ├── sbt test (ZIO Test + Scoverage report)
      ├── npx vitest run --coverage (V8)
      └── Coverage gates: Scoverage ≥ 80%, V8 ≥ 75%

  [3] dependency-check
      ├── sbt dependencyCheck (CVSS ≥ 7 = fail)
      └── npm audit --audit-level=high

  [4] build
      ├── sbt assembly (fat JAR → scalashield.jar)
      └── npm run build (Vite production, budget < 600 KB gzip)

  [5] integration-tests
      └── sbt it:test (ZIO Test + Testcontainers PostgreSQL 16 + Redis 7)

  [6] docker-scan
      └── trivy image --exit-code 1 --severity CRITICAL
```

---

## 4. Faza 2 — Rdzeń funkcjonalności (Sprint 3–4, Tygodnie 5–8)

### 4.1 Type-safe Tapir endpoints (US-02, US-03)

Tapir definiuje endpointy jako wartości Scala — Swagger UI generowany automatycznie z typów:

```scala
// ThreatEndpoints.scala
object ThreatEndpoints:

  // Opaque types — podmiana SuitCode na String jest błędem kompilacji (D-03)
  opaque type SuitCode  = String
  opaque type ThreatId  = java.util.UUID
  opaque type FrameCode = String

  object SuitCode:
    private val allowed = Set("FRE", "LLM", "AAI", "DVO", "BOT",
                               "SP", "TA", "RE", "ID", "DS", "EP",
                               "EMR", "EIR", "EOR", "EDR",
                               "VE", "AT", "SM", "AZ", "CR",
                               "PC", "AA", "NS", "RS", "CRM", "CM")
    def from(s: String): Either[InvalidSuitError, SuitCode] =
      if allowed.contains(s) then Right(s.asInstanceOf[SuitCode])
      else Left(InvalidSuitError(s"Unknown suit: $s"))

  val listThreats: PublicEndpoint[ThreatFilter, AppError, List[ThreatDto], Any] =
    endpoint
      .get
      .in("api" / "v1" / "threats")
      .in(
        query[Option[String]]("frameworkCode").validate(Validator.maxLength(20)) and
        query[Option[String]]("severity")
          .validate(Validator.enumeration(List("CRITICAL","HIGH","MEDIUM","LOW","INFO"))) and
        query[Option[String]]("q").validate(Validator.maxLength(200)) and
        query[Option[String]]("suit")
      )
      .errorOut(jsonBody[AppError])
      .out(jsonBody[List[ThreatDto]])
      .description("Lista zagrożeń z opcjonalnymi filtrami")
```

### 4.2 ZIO Quill — type-safe SQL (D-02)

ZIO Quill weryfikuje SQL w czasie kompilacji — brak runtime SQL injection przez błędną konstrukcję:

```scala
// ThreatRepository.scala
class ThreatRepositoryLive(quill: Quill.Postgres[SnakeCase]) extends ThreatRepository:
  import quill.*

  def findByFilter(filter: ThreatFilter): ZIO[Any, RepositoryError, List[Threat]] =
    // Quill generuje parametryzowane prepared statements — string concat niemożliwy
    run {
      query[Threat]
        .filter(t => filter.frameworkCode.fold(true)(fc => t.frameworkCode == lift(fc)))
        .filter(t => filter.severity.fold(true)(sv => t.severity == lift(sv)))
        .take(lift(filter.pageSize))
        .drop(lift(filter.page * filter.pageSize))
    }.mapError(RepositoryError.apply)

  // Full-text search przez PostgreSQL tsvector
  def fullTextSearch(q: String): ZIO[Any, RepositoryError, List[Threat]] =
    val safQ = q.take(200) // limit długości (Tapir validator już to robi, defensywnie)
    run(
      sql"""SELECT * FROM threat
            WHERE to_tsvector('english', title || ' ' || description)
                  @@ plainto_tsquery('english', $safQ)
            LIMIT 50""".as[Query[Threat]]
    ).mapError(RepositoryError.apply)
    // plainto_tsquery parametryzuje q — brak SQL injection
```

### 4.3 ZIO globalny error handler

```scala
// ErrorHandler.scala
object ErrorHandler:
  val layer: Middleware[Any] =
    Middleware.interceptOutgoingHandler {
      Handler.fromFunctionZIO[Response] { response =>
        if response.status.isError then
          ZIO.succeed(response.copy(
            body = Body.fromString("""{"error":"INTERNAL_ERROR","message":"An error occurred"}""")
            // nigdy: response body z wewnętrznym ZIO stack trace
          ))
        else ZIO.succeed(response)
      }
    }
```

### 4.4 Abuse Cases — Faza 2

**AC-01: SQL Injection via ZIO Quill (compile-time safe)**
```scala
// ThreatRoutesSpec.scala
object ThreatRoutesSpec extends ZIOSpecDefault:
  def spec = suite("ThreatRoutes SQL safety")(
    test("SQL injection in q param should not affect database") {
      for
        _        <- TestServer.get("/api/v1/threats?q='; DROP TABLE threat; --")
        count    <- ThreatRepository.countAll
      yield assert(count)(isGreaterThan(0L))
    },
    test("very long q param is rejected before reaching DB") {
      for
        response <- TestServer.get(s"/api/v1/threats?q=${"a" * 201}")
      yield assert(response.status)(equalTo(Status.BadRequest))
    }
  ).provide(TestServer.layer, ThreatRepository.testLayer, TestDatabaseLayer.live)
```

**AC-02: JWT Tampering**
```scala
test("tampered JWT payload should return 401") {
  val tampered = "eyJhbGciOiJSUzI1NiJ9." +
    java.util.Base64.getEncoder.encodeToString(
      """{"sub":"admin","roles":["ADMIN"]}""".getBytes
    ) + ".invalidsignature"
  for
    response <- TestServer.get("/api/v1/admin/threats",
                  headers = Map("Authorization" -> s"Bearer $tampered"))
  yield assert(response.status)(equalTo(Status.Unauthorized))
}
```

---

## 5. Faza 3 — Próbki kodu (Sprint 5–6, Tygodnie 9–12)

### 5.1 Wymagania bezpieczeństwa — próbki kodu

| ID | Wymaganie | Implementacja |
|---|---|---|
| SR-CODE-01 | `ATTACK_DEMO` badge `PODATNY` — czerwona obwódka w React | CSS klasa `.vulnerable-sample { border-left: 4px solid #b71c1c }` |
| SR-CODE-02 | `codeSnippet` jest plain String w Scala — brak `eval`, `reflect` | Wartremover: brak `asInstanceOf` + code review |
| SR-CODE-03 | Próbki kodu nie tłumaczone | react-i18next namespace `code` wyłączony z tłumaczeń |
| SR-CODE-04 | Shiki ładowany lazy per język | `React.lazy(() => import('./ShikiHighlighter'))` |
| SR-CODE-05 | Copy `ATTACK_DEMO` → `BotWarningModal` przed `clipboard.writeText()` | React state `showBotWarning` + `pendingCopy` |

### 5.2 Testy React — próbki kodu

```typescript
// CodeSamplePanel.spec.tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { CodeSamplePanel } from './CodeSamplePanel'

const mockAttackDemo = {
  id: '1', language: 'PYTHON', sampleType: 'ATTACK_DEMO',
  title: 'SQL Injection Demo', codeSnippet: '# PODATNY\nquery = f"SELECT * FROM users WHERE id={id}"'
}

describe('CodeSamplePanel security', () => {
  it('should show PODATNY badge on ATTACK_DEMO tab', async () => {
    render(<CodeSamplePanel samples={[mockAttackDemo]} />)
    expect(await screen.findByText('PODATNY')).toBeInTheDocument()
  })

  it('should apply vulnerable-sample CSS class on ATTACK_DEMO', () => {
    const { container } = render(<CodeSamplePanel samples={[mockAttackDemo]} />)
    expect(container.querySelector('.vulnerable-sample')).not.toBeNull()
  })

  it('should open BotWarningModal before clipboard copy', async () => {
    const user = userEvent.setup()
    const mockOpen = vi.fn()
    vi.spyOn(window, 'dispatchEvent').mockImplementation(mockOpen)
    render(<CodeSamplePanel samples={[mockAttackDemo]} />)
    await user.click(screen.getByLabelText('Copy attack demo code'))
    expect(mockOpen).toHaveBeenCalled()
  })

  it('should NOT show bot warning for DEFENSE sample', async () => {
    const defense = { ...mockAttackDemo, sampleType: 'DEFENSE' }
    const mockOpen = vi.fn()
    vi.spyOn(window, 'dispatchEvent').mockImplementation(mockOpen)
    render(<CodeSamplePanel samples={[defense]} />)
    await userEvent.click(screen.getByLabelText('Copy defense code'))
    expect(mockOpen).not.toHaveBeenCalled()
  })
})
```

---

## 6. Faza 4 — Zaawansowane funkcje (Sprint 6–7, Tygodnie 11–14)

### 6.1 Full-text Search — ZIO Quill + tsvector

```scala
// SearchRepository.scala
def search(q: String, page: Int): ZIO[Any, RepositoryError, SearchResult] =
  val safe = q.trim.take(200)
  run(
    sql"""
      SELECT id, code, title, severity,
             ts_headline('english', description, plainto_tsquery('english', $safe),
               'MaxFragments=2,FragmentDelimiter=" ... "') AS excerpt
      FROM threat
      WHERE to_tsvector('english', title || ' ' || description || ' ' || coalesce(attack_vector,''))
            @@ plainto_tsquery('english', $safe)
      ORDER BY ts_rank(to_tsvector('english', title || ' ' || description),
                       plainto_tsquery('english', $safe)) DESC
      LIMIT 20 OFFSET ${page * 20}
    """.as[Query[SearchHit]]
  ).mapError(RepositoryError.apply)
  // plainto_tsquery parametryzuje $safe — brak SQL injection, brak ReDoS
```

### 6.2 Abuse Cases — Advanced Features

**AC-06: ReDoS prevention (Tapir validator)**
```scala
// Tapir validator na etapie kompilacji trasy — q > 200 chars = 400 Bad Request
test("query exceeding 200 chars returns 400") {
  for
    response <- TestServer.get(s"/api/v1/search?q=${"a" * 201}")
  yield assert(response.status)(equalTo(Status.BadRequest))
}
```

**AC-07: CSV Injection Prevention**
```scala
// ExportService.scala — JVM interop z Apache Commons CSV
import org.apache.commons.csv.{ CSVFormat, QuoteMode }

def exportToCsv(threats: List[ThreatDto]): ZIO[Any, ExportError, String] =
  ZIO.attemptBlocking {
    val sw     = new java.io.StringWriter()
    val format = CSVFormat.DEFAULT.builder()
      .setQuoteMode(QuoteMode.ALL)   // ochrona przed =FORMULA injection
      .setHeader("ID", "Code", "Title", "Severity", "Category")
      .build()
    val printer = format.print(sw)
    threats.foreach(t => printer.printRecord(t.id.toString, t.code, t.title, t.severity.toString, t.category))
    printer.flush()
    sw.toString
  }.mapError(ExportError.apply)
```

---

## 7. Faza 5 — i18n (Sprint 8, Tygodnie 15–16)

### 7.1 React — react-i18next z Axios LocaleInterceptor

```typescript
// localeInterceptor.ts
import axios from 'axios'
import i18n from './i18n'

axios.interceptors.request.use(config => {
  const locale = localStorage.getItem('ss_locale') ?? 'pl'
  const safe   = ['pl', 'en'].includes(locale) ? locale : 'pl'  // allowlist
  config.headers['Accept-Language'] = safe
  return config
})
```

```scala
// LocaleMiddleware.scala — backend czyta Accept-Language z ZIO HTTP Request
object LocaleMiddleware:
  def extractLocale(req: Request): String =
    req.header(Header.AcceptLanguage)
       .flatMap(_.renderedValue.split(",").headOption)
       .map(_.trim.take(2).toLowerCase)
       .filter(l => Set("pl", "en").contains(l))  // serwer-side allowlist
       .getOrElse("pl")
```

### 7.2 Test parzystości kluczy i18n

```typescript
// i18n-parity.spec.ts
import pl from '../public/locales/pl/translation.json'
import en from '../public/locales/en/translation.json'

describe('i18n key parity', () => {
  it('should have identical top-level keys in pl and en', () => {
    const plKeys = Object.keys(pl).sort()
    const enKeys = Object.keys(en).sort()
    expect(plKeys).toEqual(enKeys)
  })

  it('pl.json should have at least 50 keys', () => {
    expect(Object.keys(pl).length).toBeGreaterThanOrEqual(50)
  })

  it('no value in pl.json should contain HTML tags', () => {
    const htmlPattern = /<[^>]+>/
    Object.entries(pl).forEach(([key, val]) => {
      expect(htmlPattern.test(val as string), `pl key "${key}" contains HTML`).toBeFalsy()
    })
  })

  it('no value in en.json should contain HTML tags', () => {
    const htmlPattern = /<[^>]+>/
    Object.entries(en).forEach(([key, val]) => {
      expect(htmlPattern.test(val as string), `en key "${key}" contains HTML`).toBeFalsy()
    })
  })
})
```

---

## 8. Faza 6 — Cornucopia: FRE + LLM + AAI (Sprint 9, Tygodnie 17–18)

### 8.1 Wymagania bezpieczeństwa — Cornucopia

| ID | Wymaganie | Implementacja Scala/ZIO |
|---|---|---|
| SR-C-01 | `descriptionPl/En`: plain text bez HTML | `YamlCardLoader` + grep CI |
| SR-C-02 | `DOMPurify.sanitize()` przed każdym renderowaniem opisu | React `ThreatCard.tsx` — `dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(desc) }}` |
| SR-C-03 | `ContentIntegrityVerifier` ZIO layer — `ZIO.die` on mismatch | Sekcja 3.2 |
| SR-C-04 | `OwaspRefValidator` — Scala `Set` compile-time allowlist | Poniżej |
| SR-C-05 | ZIO STM rate limit 60 req/min per IP na `/api/v1/threats?suit=*` | Sekcja 3.3 |
| SR-C-06 | Diagramy AAI renderowane server-side jako SVG | Backend ZIO + Apache Batik |
| SR-C-07 | `AUTONOMY RISK` badge na kartach AAI (AAIK, AAIQ) | React: `isCritical && suitCode === 'AAI'` |

### 8.2 OwaspRefValidator — Scala 3 opaque types + Set

```scala
// OwaspRefValidator.scala
opaque type OwaspRef     = String
opaque type MitreRef     = String
opaque type MavsRef      = String
opaque type CicdSecRef   = String
opaque type OatRef       = String

object OwaspRefValidator:
  private val allowedOwaspRefs: Set[String] = Set(
    "A01:2021", "A02:2021", "A03:2021", "A04:2021", "A05:2021",
    "A06:2021", "A07:2021", "A08:2021", "A09:2021", "A10:2021",
    "LLM01:2025", "LLM02:2025", "LLM03:2025", "LLM04:2025", "LLM05:2025",
    "LLM06:2025", "LLM07:2025", "LLM08:2025", "LLM09:2025", "LLM10:2025",
    "Client-Side C01", "Client-Side C02", "Client-Side C03", "Client-Side C04", "Client-Side C05",
    "Client-Side C06", "Client-Side C07", "Client-Side C08", "Client-Side C09", "Client-Side C10",
    "AgentAI01", "AgentAI02", "AgentAI03", "AgentAI04", "AgentAI05",
    "AgentAI06", "AgentAI07", "AgentAI08", "AgentAI09", "AgentAI10",
    "API1", "API2", "API3", "API4", "API5",
    "API6", "API7", "API8", "API9", "API10"
  )

  def validate(ref: String): ZIO[Any, InvalidRefError, OwaspRef] =
    ZIO.fromEither(
      if allowedOwaspRefs.contains(ref) then Right(ref.asInstanceOf[OwaspRef])
      else Left(InvalidRefError(s"Unknown OWASP ref: $ref — not in allowlist"))
    )

object MitreAtlasRefValidator:
  private val allowedTechniques: Set[String] = Set(
    "T0010", "T0011", "T0012", "T0013", "T0014", "T0015",
    "T0016", "T0017", "T0018", "T0019", "T0020",
    "T0024", "T0029", "T0031", "T0034", "T0040",
    "T0043", "T0044", "T0046", "T0051", "T0054"
  ).map("MITRE ATLAS " + _)

  def validate(ref: String): ZIO[Any, InvalidRefError, MitreRef] =
    ZIO.fromEither(
      if allowedTechniques.contains(ref) then Right(ref.asInstanceOf[MitreRef])
      else Left(InvalidRefError(s"Unknown MITRE ATLAS technique: $ref"))
    )
```

### 8.3 YAML Integrity CI Pipeline

```
PR modyfikuje data/cornucopia/*.yaml:
  ↓
CI job: yaml-content-integrity
  Step 1: ajv validate --schema data/cornucopia/card-schema.json --data *.yaml
  Step 2: grep -rE "(system_prompt|<script|javascript:|eval\(|MITRE\.T9999)" data/cornucopia/ → fail if match
  Step 3: sbt "runMain com.scalashield.cli.RefValidatorCLI data/cornucopia/*.yaml" → fail if unknown ref
  ↓ merge
CI job: yaml-hash-update (runs as bot)
  python scripts/hash_generator.py → aktualizuje data/hashes.json → commit by [bot]
  ↓ deploy
ZIO layer ContentIntegrityVerifier:
  SHA-256 każdego YAML vs hashes.json → ZIO.die(ContentIntegrityException) jeśli niezgodność
  → aplikacja nie startuje (fail-secure)
```

### 8.4 Abuse Cases — Cornucopia

**AC-09: Bot scraping (ZIO STM rate limiter)**
```scala
object RateLimitSpec extends ZIOSpecDefault:
  def spec = suite("RateLimitMiddleware")(
    test("should return 429 after exceeding 60 requests per minute") {
      for
        server   <- ZIO.service[TestServer]
        responses <- ZIO.foreach(1 to 61) { i =>
                       server.get(s"/api/v1/threats?suit=FRE",
                         headers = Map("X-Forwarded-For" -> "203.0.113.42"))
                     }
        last      = responses.last
      yield assert(last.status)(equalTo(Status.TooManyRequests)) &&
            assert(last.header("Retry-After"))(isSome)
    }
  ).provide(TestServer.layer, RateLimitMiddleware.testLayer)
```

**AC-10: XSS przez admin update opisu karty**
```scala
test("admin update with XSS payload should sanitize description") {
  val xssPayload = "<script>alert('XSS')</script>Safe text"
  for
    _       <- TestServer.put(s"/api/v1/admin/threats/$cardId",
                  body = UpdateCardRequest(cardId, xssPayload, None),
                  headers = Map("Authorization" -> s"Bearer $adminToken"))
    updated <- CardRepository.findById(cardId)
  yield assert(updated.descriptionPl)(not(containsString("<script>"))) &&
        assert(updated.descriptionPl)(containsString("Safe text"))
}
```

**AC-11: YAML file tampering**
```scala
test("tampered YAML file should cause ZIO.die at startup") {
  val tamperedPath = writeTempFile("tampered: content")
  val originalHash = "abc123def456"  // nie pasuje do tampered content
  val effect = ContentIntegrityVerifier.verifyFile(tamperedPath, originalHash)
  assertZIO(effect.exit)(dies(isSubtype[ContentIntegrityException](anything)))
}
```

**AC-12: Fałszywy MITRE ATLAS ID**
```scala
test("unknown MITRE ATLAS ID should return 422") {
  for
    response <- TestServer.put(s"/api/v1/admin/threats/$cardId",
                  body = UpdateCardRequest(cardId, "desc", Some(List("MITRE.T9999"))),
                  headers = Map("Authorization" -> s"Bearer $adminToken"))
  yield assert(response.status)(equalTo(Status.UnprocessableEntity))
}
```

---

## 9. Faza 7 — STRIDE EoP + MLSec (Sprint 10–11, Tygodnie 19–22)

### 9.1 Wymagania bezpieczeństwa (US-15, US-16)

| ID | Wymaganie | Implementacja |
|---|---|---|
| SR-S-01 | `/stride-heatmap` wymaga JWT | `JwtMiddleware.requireAuth` → ZIO HTTP routes |
| SR-S-02 | `X-Frame-Options: DENY` + CSP `frame-ancestors 'none'` | `SecurityMiddleware.securityHeaders` — już skonfigurowane globalnie |
| SR-S-03 | `MitreAtlasRefValidator` Scala Set | Sekcja 8.2 — `MitreAtlasRefValidator.validate()` |
| SR-S-04 | `ML-SPECIFIC` badge na kartach MLSec | React: `card.edition === 'mlsec'` → `<Badge color="purple">ML-SPECIFIC</Badge>` |
| SR-S-05 | Dane heatmapy cachowane ZIO Redis TTL 5 min | `ZIO.serviceWithZIO[Redis](_.get("stride-heatmap"))` |

### 9.2 JwtMiddleware — ZIO HTTP implementation

```scala
// JwtMiddleware.scala
object JwtMiddleware:

  def requireRole(role: String): Middleware[JwtConfig] =
    Middleware.interceptIncomingHandler {
      Handler.fromFunctionZIO[Request] { req =>
        for
          config  <- ZIO.service[JwtConfig]
          token   <- ZIO.fromOption(
                       req.header(Header.Authorization).flatMap(_.renderedValue.stripPrefix("Bearer ").some)
                     ).mapError(_ => Response.status(Status.Unauthorized))
          claims  <- verifyToken(token, config.publicKey)
                       .mapError(_ => Response.status(Status.Unauthorized))
          _       <- ZIO.unless(claims.roles.contains(role)) {
                       ZIO.fail(Response.status(Status.Forbidden))
                     }
        yield req
      }
    }

  def requireAuth: Middleware[JwtConfig] =
    Middleware.interceptIncomingHandler {
      Handler.fromFunctionZIO[Request] { req =>
        for
          config <- ZIO.service[JwtConfig]
          token  <- ZIO.fromOption(
                      req.header(Header.Authorization).flatMap(h => Some(h.renderedValue.stripPrefix("Bearer ")))
                    ).mapError(_ => Response.status(Status.Unauthorized))
          _      <- verifyToken(token, config.publicKey)
                       .mapError(_ => Response.status(Status.Unauthorized))
        yield req
      }
    }
```

### 9.3 ZIO Redis — cache heatmapy

```scala
// StrideHeatmapService.scala
class StrideHeatmapServiceLive(redis: Redis, repo: StrideHeatmapRepository) extends StrideHeatmapService:

  def getHeatmapData: ZIO[Any, AppError, HeatmapData] =
    val cacheKey = "stride-heatmap-v1"
    for
      cached <- redis.get(cacheKey).option.mapError(AppError.apply)
      result <- cached match
                  case Some(json) =>
                    ZIO.fromEither(io.circe.parser.decode[HeatmapData](json))
                       .mapError(e => AppError(s"Cache decode: ${e.getMessage}"))
                  case None =>
                    for
                      data    <- repo.computeHeatmap.mapError(AppError.apply)
                      encoded  = io.circe.syntax.EncoderOps(data).asJson.noSpaces
                      _       <- redis.setEx(cacheKey, 5.minutes, encoded)
                                   .mapError(AppError.apply)
                    yield data
    yield result
```

---

## 10. Faza 8 — Mobile + DevOps (Sprint 12–13, Tygodnie 23–26)

### 10.1 Wymagania bezpieczeństwa (US-17, US-18)

| ID | Wymaganie | Implementacja |
|---|---|---|
| SR-M-01 | `MavsRefValidator` — MASVS-*-* allowlist | `data/ref-allowlists.json` sekcja mavsRefs |
| SR-M-02 | `CicdSecRefValidator` — CICD-SEC-01–10 | Scala Set z `"CICD-SEC-01"` … `"CICD-SEC-10"` |
| SR-M-03 | `OatRefValidator` — OAT-001–021 | Scala Set + pattern `"OAT-\\d{3}"` |
| SR-M-04 | `BotWarningModal` przed kartami BOT krytycznymi | React state `showBotWarning` + `localStorage ss_bot_warning_ack` |
| SR-M-05 | DVO kod: pseudokod bez działających exploitów pipeline | `CI_EXPLOIT_PATTERN` grep w CI job |
| SR-M-06 | Dogfooding D-11: ScalaShield wdraża własną ochronę BOT | ZIO STM rate limiter aktywny |

### 10.2 React BotWarningModal

```typescript
// DevOpsSecurityPage.tsx
const DevOpsSecurityPage: React.FC = () => {
  const [showBotWarning, setShowBotWarning] = useState(false)
  const [pendingCard, setPendingCard]       = useState<CornucopiaCard | null>(null)
  const navigate = useNavigate()

  const handleBotCardClick = (card: CornucopiaCard) => {
    const acked = localStorage.getItem('ss_bot_warning_ack') === 'true'
    if (acked || !card.isCritical) {
      navigate(`/threats/${card.cardId}`)
      return
    }
    setPendingCard(card)
    setShowBotWarning(true)
  }

  const handleBotWarningConfirm = () => {
    localStorage.setItem('ss_bot_warning_ack', 'true')
    setShowBotWarning(false)
    if (pendingCard) navigate(`/threats/${pendingCard.cardId}`)
  }

  return (
    <>
      {showBotWarning && (
        <BotWarningModal
          onConfirm={handleBotWarningConfirm}
          onCancel={() => setShowBotWarning(false)}
        />
      )}
      {/* ... card list ... */}
    </>
  )
}
```

### 10.3 Abuse Cases — Mobile + DevOps

**AC-13: Credential Stuffing Rate Limit**
```scala
test("BOT suit endpoint should enforce ZIO STM rate limit") {
  for
    responses <- ZIO.foreach(1 to 61) { _ =>
                   TestServer.get("/api/v1/threats?suit=BOT",
                     headers = Map("X-Forwarded-For" -> "198.51.100.1"))
                 }
    last       = responses.last
  yield assert(last.status)(equalTo(Status.TooManyRequests))
}
```

**AC-14: SVG Injection w diagramie AAI**
```scala
test("AAI agent diagram should not contain script tags") {
  for
    response <- TestServer.get("/api/v1/threats/AAIK/diagram")
    body     <- response.body.asString
  yield assert(body)(not(containsString("<script"))) &&
        assert(body)(not(containsString("javascript:"))) &&
        assert(body)(not(containsString("onload=")))
}
```

**AC-15: BotWarningModal bypass via direct navigation**
```typescript
// BotWarningBypass.spec.ts (Playwright)
test('direct navigation to BOT card without ack shows modal', async ({ page }) => {
  await page.context().clearCookies()
  await page.evaluate(() => localStorage.removeItem('ss_bot_warning_ack'))
  await page.goto('/frameworks/devops-security')
  await page.click('[data-testid="bot-card-BOTK"]')
  await expect(page.locator('[data-testid="bot-warning-modal"]')).toBeVisible()
  await page.click('[data-testid="bot-warning-cancel"]')
  await expect(page).not.toHaveURL(/\/threats\/BOTK/)
})
```

---

## 10.5 Faza 8.5 — Digital-by-Default Harms (Sprint 13, Tydzień 26)

Ostatnia z sześciu talii YAML w `docs/OWASP_stories/` — `dbd-cards-1.0-en.yaml` (suity SCO, ARC, AGE, TRU, POR, COR, WC) — była pominięta we wcześniejszym planowaniu i jest dodana tutaj jako uzupełnienie pokrycia (US-19). Wymaga osobnego traktowania w SSDLC, ponieważ różni się fundamentalnie od pięciu poprzednich talii:

| ID | Wymaganie | Implementacja |
|---|---|---|
| SR-H-01 | Karty `dbd` nie mają pola `severity` — model danych `cardKind: "DESIGN_HARM"` odróżnia je od `Threat`/`CornucopiaCard` z severity | `DigitalHarmsService` zwraca DTO bez pola `severity` |
| SR-H-02 | `DesignHarmBadge` (React) nigdy nie dziedziczy stylów `SeverityBadge` | Osobny komponent, weryfikowany testem Vitest (AC-16) |
| SR-H-03 | Cross-reference do A04:2021 tworzony ręcznie przez security-team, nie przez `OwaspRefValidator` (talia nie ma natywnych identyfikatorów OWASP w YAML) | `CrossReference` seed data, code review wymagany |
| SR-H-04 | Polskie tłumaczenia SCO/ARC/AGE/TRU/POR podlegają tej samej bramce jakości i18n co reszta aplikacji (D-10) | Recenzja native speakera przed merge |

**Wniosek dla threat modelu (Faza 0, §2.2):** ta talia jest dobrym przykładem tego, że nie każde "zagrożenie" w katalogu bezpieczeństwa ma CVSS. Włączenie jej bez odróżnienia od reszty groziłoby fałszywym poczuciem, że aplikacja "wykryła 5 nowych krytycznych podatności" — stąd wymaganie SR-H-01/SR-H-02 zostało dodane jako poprawka do pierwotnego threat modelu, nie jako wymaganie funkcjonalne.

**AC-16: Harms deck nie jest błędnie prezentowana jako lista CVE**
```typescript
// DigitalHarmsPage.spec.tsx
it('never renders a SeverityBadge on a dbd card', async () => {
  render(<DigitalHarmsPage />)
  const card = await screen.findByTestId('card-SCO2')
  expect(within(card).queryByTestId('severity-badge')).not.toBeInTheDocument()
  expect(within(card).getByTestId('design-harm-badge')).toBeInTheDocument()
})
```

---

## 11. Faza 9 — Integracja i Hardening (Sprint 14–16, Tygodnie 27–31)

### 11.1 Piramida testów ScalaShield

```
          /\
         /E2E\          ≥ 25 Playwright scenarios (us01–us18.spec.ts)
        /______\
       / IT     \       ≥ 40 ZIO Test + Testcontainers (PostgreSQL 16 + Redis 7)
      /__________\
     / Unit tests \     ≥ 80 ZIO Test (services) + Vitest (React components)
    /______________\
```

**Kolejność wykonania w CI:**
```
lint-and-sast → unit-tests → integration-tests → build → docker-compose up → e2e-playwright → dast-zap
```

### 11.2 Playwright — konfiguracja E2E

```typescript
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'

export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: [['html'], ['junit', { outputFile: 'results.xml' }]],
  use: {
    baseURL: 'http://localhost:5173',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox',  use: { ...devices['Desktop Firefox'] } },
  ],
})
```

### 11.3 Playwright — axe accessibility

```typescript
// us12-frontend-security.spec.ts
import { test, expect } from '@playwright/test'
import { checkA11y, injectAxe } from 'axe-playwright'

test.describe('US-12 Frontend Security Cards', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/frameworks/frontend-security')
  })

  test('should have no WCAG 2.1 AA violations', async ({ page }) => {
    await injectAxe(page)
    await checkA11y(page, null, {
      runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa'] },
      detailedReport: true,
      detailedReportOptions: { html: true }
    })
  })

  test('should show all FRE cards', async ({ page }) => {
    const cards = page.locator('[data-testid="cornucopia-card"]')
    await expect(cards).toHaveCount(13)
  })

  test('should show OWASP ref chips on each card', async ({ page }) => {
    const firstCard = page.locator('[data-testid="cornucopia-card"]').first()
    await expect(firstCard.locator('[data-testid="owasp-ref-chip"]')).toBeVisible()
  })

  test('should show Polish descriptions when locale is PL', async ({ page }) => {
    await page.evaluate(() => localStorage.setItem('ss_locale', 'pl'))
    await page.reload()
    const desc = await page.locator('[data-testid="card-description"]').first().textContent()
    // Polish text: contains polish diacritics or polish words
    expect(desc).toMatch(/[ąćęłńóśźżĄĆĘŁŃÓŚŹŻ]|może|przez|braku/)
  })
})
```

### 11.4 DAST — OWASP ZAP Full Active Scan

```yaml
# .github/workflows/dast.yml
jobs:
  dast-zap:
    runs-on: ubuntu-latest
    steps:
      - name: Start staging environment
        run: docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d

      - name: Wait for backend health
        run: |
          for i in {1..30}; do
            curl -sf http://localhost:8080/api/v1/health && break || sleep 3
          done

      - name: ZAP Active Scan
        uses: zaproxy/action-full-scan@v0.10.0
        with:
          target: 'http://localhost:5173'
          fail_action: true
          cmd_options: '-r zap-report.html -z "-addoninstall ascanrulesAlpha"'

      - name: Upload ZAP report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: zap-report
          path: zap-report.html
```

### 11.5 Vite Bundle Performance

```typescript
// vite.config.ts
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'react-vendor':  ['react', 'react-dom', 'react-router-dom'],
          'i18n-vendor':   ['i18next', 'react-i18next'],
          'echarts-vendor': ['echarts', 'echarts-for-react'],
          'd3-vendor':     ['d3'],
        }
      }
    },
    chunkSizeWarningLimit: 600,  // KB
    target: 'es2020'
  }
})
```

Shiki ładowany lazy — każdy język jako osobny dynamic import:
```typescript
// LazyShikiHighlighter.tsx
const PythonHighlighter = lazy(() => import('./highlighters/PythonHighlighter'))
const ScalaHighlighter  = lazy(() => import('./highlighters/ScalaHighlighter'))
const GoHighlighter     = lazy(() => import('./highlighters/GoHighlighter'))
// ... każdy język < 30 KB gzip
```

### 11.6 Monitoring produkcyjny

**Loki alerts:**

| ID | Trigger | Akcja |
|---|---|---|
| SEC-007 | ZIO STM rejections > 5/min od single IP | PagerDuty MEDIUM |
| SEC-008 | `content_integrity_check_ok == 0` przy starcie | PagerDuty CRITICAL → deployment blocked |
| SEC-009 | JWT verification failures > 10/min | PagerDuty HIGH — potential brute-force |

**Prometheus metrics (ZIO HTTP metrics middleware):**
```scala
// MetricsMiddleware.scala — integracja z Prometheus via zio-metrics-connectors
content_integrity_check_ok{app="scalashield"}   // gauge: 1=OK, 0=FAIL
rate_limit_rejections_total{endpoint="threats"} // counter — ZIO STM bucket exhaustions
http_request_duration_seconds{uri="/api/v1/threats",le="0.2"}  // histogram p95 SLO
```

---

## 12. Tabela mapowania: US → Zagrożenie → Abuse Case → Kontrola

| US | Zagrożenie główne | STRIDE / OWASP | Abuse Case | Kontrola Scala/ZIO | Test |
|---|---|---|---|---|---|
| US-01 | Nieuprawniony dostęp do frameworków | S — A07 | AC-02 | `JwtMiddleware.requireRole` | `AdminRoutesSpec` |
| US-02 | SQL Injection w filtrach | E — A03 | AC-01 | ZIO Quill compile-time SQL | `ThreatRoutesSpec SQL safety` |
| US-03 | ZIO stack trace wyciek | I — A09 | — | `ZIO.mapError → ApiError` generic | `ErrorHandlerSpec` |
| US-04 | Data poisoning w cross-references | T — A03 | AC-01 | Tapir `Validator.maxLength` + Quill | `CrossRefRoutesSpec` |
| US-05 | Clickjacking heatmapy | T — C05 | AC-08 | `SecurityMiddleware.headers` X-Frame-Options | ZAP headerscan |
| US-06 | ReDoS via malicious query | D — A03 | AC-06 | Tapir `Validator.maxLength(200)` | `SearchReDoSSpec` |
| US-07 | CSV injection w eksporcie | T — A03 | AC-07 | Commons CSV `QuoteMode.ALL` | `CsvExportSpec` |
| US-08 | ATLAS data tampering | T | — | ZIO Quill parameterized queries | `AtlasServiceSpec` |
| US-09 | Injection w Scala snippet | T — A03 | — | `codeSnippet` plain String, no eval | `CodeSampleSpec` |
| US-10 | Injection w Lua snippet | T — A03 | — | `codeSnippet` plain String, no eval | `CodeSampleSpec` |
| US-11 | Header injection Accept-Language | T | — | `LocaleMiddleware` allowlist pl/en | `LocaleMiddlewareSpec` |
| US-12 | XSS w opisie karty FRE | XSS — A03/C03 | AC-04, AC-10 | DOMPurify + `SafeHtml` (pure-Scala sanitizer, D-14) | `ThreatCardXSSSpec` |
| US-13 | LLM card YAML poisoning | T — LLM04 | AC-11 | `ContentIntegrityVerifier` SHA-256 | `YamlIntegritySpec` |
| US-14 | AAI SVG injection | T — A03 | AC-14 | Server-side SVG (Batik) | `SvgEndpointSpec` |
| US-15 | Clickjacking `/stride-heatmap` | T — C05 | AC-08 | `SecurityMiddleware` headers | ZAP headerscan |
| US-16 | Fałszywy MITRE ATLAS ID | T — A03 | AC-12 | `MitreAtlasRefValidator` Scala Set | `MitreAtlasValidatorSpec` |
| US-17 | Fałszywy MASVS ID | T — A03 | — | `MavsRefValidator` Scala Set | `MavsValidatorSpec` |
| US-18 | Bot scraping + BotModal bypass | D — OAT-011 | AC-09, AC-13, AC-15 | ZIO STM bucket + BotWarningModal | `RateLimitSpec` + Playwright |
| US-19 | Harms deck błędnie prezentowana jako CVE severity | — (nie STRIDE, projektowy/GRC) A04:2021 | AC-16 | `DesignHarmBadge` ≠ `SeverityBadge`; brak pola `severity` w DTO | `DigitalHarmsPage.spec.tsx` |

---

## 13. Checklista compliance SSDLC

### Faza 0 — Requirements & Threat Modeling
- [ ] STRIDE threat model dla ScalaShield 2026 ukończony (sekcja 2.2)
- [ ] SAC-01–SAC-15 zdefiniowane i włączone do DoD (sekcja 2.3)
- [ ] CODEOWNERS skonfigurowane: `/data/cornucopia/` → @security-team (min. 2 zatwierdzenia)
- [ ] Risk register zainicjowany
- [ ] OWASP SAMM assessment poziomu wyjściowego

### Faza 1 — Foundation
- [ ] Scala 3.3 LTS + ZIO 2 scaffold z `sbt new scala/scala3.g8`
- [ ] Wartremover skonfigurowany: `NoNull`, `Return`, `Throw`, `AsInstanceOf` jako errors
- [ ] Scalafix reguły: `DisableSyntax`, `NoAutoTupling`, `RedundantSyntax`
- [ ] Git pre-commit hooks: `sbt scalafixAll --check` + gitleaks
- [ ] CI pipeline 6 jobów aktywny
- [ ] ZIO effect boundary policy: brak `Future`, `try/catch`, `throw` poza ZIO
- [ ] `SecurityMiddleware.securityHeaders` aktywny globalnie
- [ ] `ErrorHandler` → generic messages w HTTP responses

### Fazy 2–4 — Development
- [ ] Wszystkie SQL przez ZIO Quill compile-time interpolation — brak string concat
- [ ] Tapir validators na wszystkich query params (maxLength, enumeration)
- [ ] Opaque types: `ThreatCode`, `CardId`, `SuitCode` w użyciu
- [ ] `ZIO.mapError(_ => ApiError(...))` na wszystkich zewnętrznych granicach
- [ ] DOMPurify w każdym React komponencie renderującym `description` z API
- [ ] CSV export: `QuoteMode.ALL` (CSV injection prevention)
- [ ] Rate limit na `/api/v1/search` i wszystkich suit endpoints

### Faza 5 — i18n
- [ ] Klucze i18n: tylko plain text, bez HTML
- [ ] `localeInterceptor`: allowlist 'pl'/'en' — nie przekazuje raw value
- [ ] Backend `LocaleMiddleware`: allowlist 'pl'/'en' server-side
- [ ] CI test `i18n-parity.spec.ts` — fail build na niezgodność lub HTML w values

### Fazy 6–8 — Cornucopia
- [ ] `ContentIntegrityVerifier` ZIO layer aktywny — `ZIO.die` on SHA-256 mismatch
- [ ] `OwaspRefValidator` Scala Set aktywny
- [ ] `MitreAtlasRefValidator` Scala Set aktywny
- [ ] `MavsRefValidator`, `CicdSecRefValidator`, `OatRefValidator` aktywne
- [ ] ZIO STM token bucket 60 req/min per IP na suit endpoints
- [ ] `BotWarningModal` wyświetlany przed kartami BOT (BOTX, BOTJ, BOTK)
- [ ] `X-Frame-Options: DENY` via `SecurityMiddleware` na wszystkich odpowiedziach
- [ ] `ML-SPECIFIC` badge na kartach MLSec (edition = 'mlsec')
- [ ] `AUTONOMY RISK` badge na kartach AAIK, AAIQ
- [ ] CI job `yaml-content-integrity` GREEN dla każdego PR modyfikującego YAML
- [ ] DVO kod: pseudokod — `CI_EXPLOIT_PATTERN` grep GREEN

### Faza 8.5 — Digital-by-Default Harms
- [ ] Wszystkie 6 plików YAML z `docs/OWASP_stories/` załadowane (włącznie z `dbd-cards-1.0-en.yaml`)
- [ ] `DigitalHarmsService` nigdy nie zwraca pola `severity` dla kart `dbd`
- [ ] `DesignHarmBadge` komponent nie dzieli stylów z `SeverityBadge` (AC-16 GREEN)
- [ ] Banner disclaimera widoczny na `/frameworks/digital-harms` przed treścią kart
- [ ] Polskie tłumaczenia SCO/ARC/AGE/TRU/POR zrecenzowane przez native speakera

### Faza 9 — Hardening
- [ ] ZAP full active scan: 0 High/Critical alerts
- [ ] `sbt dependencyCheck`: 0 Critical CVEs
- [ ] `npm audit`: 0 High/Critical
- [ ] Trivy Docker scan: 0 CRITICAL
- [ ] axe-playwright: 0 Critical/Serious WCAG 2.1 AA violations
- [ ] Lighthouse mobile Performance ≥ 85
- [ ] Lighthouse Accessibility ≥ 90
- [ ] Vite production bundle initial chunk < 600 KB gzip
- [ ] Scoverage ≥ 80% (backend)
- [ ] V8 coverage ≥ 75% (frontend)
- [ ] Wszystkie 19 plików Playwright `*.spec.ts` GREEN
- [ ] Abuse cases AC-01–AC-16 GREEN
- [ ] Monitoring aktywny: Loki alerts SEC-007, SEC-008, SEC-009
- [ ] Prometheus: `content_integrity_check_ok` i `rate_limit_rejections_total` zbierane
- [ ] README: instrukcja `docker compose up` quick-start
- [ ] `sbt scalafixAll --check` GREEN na całym codebase (zero linting violations)
- [ ] Wartremover: zero errors na całym codebase (CI enforced)
