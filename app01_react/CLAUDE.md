# SecureVision 2026 — Java/Spring Boot + React (app01_react)

**This app is the contract of record.** See `../CLAUDE.md` for the sibling
list, the canonical Phase-1 API contract, and shared local-dev setup — this
file only covers what's specific to app01.

## Scope: this is Phase-1 parity, not the full vision

What exists today (`backend/`, `frontend/`) is Phase-1 / milestone M1 only:
frameworks + threats (read-only), one hardcoded admin login, 4 seeded
frameworks, ~33 threats. Later-phase tables (`Mitigation`, `CodeSample`,
`CrossReference`, `ThreatTranslation`, `CornucopiaCard`, `ContentHash`) exist in
the `V1` Flyway migration but are not JPA-mapped or exposed via the API yet.

## Implementation detail beyond the canonical contract

Source of truth: `backend/src/main/java/com/securevision/`. `Page<T>` comes
from Spring Data's native envelope (see `ThreatController` +
`ThreatSpecifications.java` for the filter logic). Error body via
`ApiExceptionHandler`. Auth is `JwtService` (`Keys.hmacShaKeyFor`, single shared
`JWT_SECRET`) — this is the real HS256 contract every sibling should match; the
RS256 key-pair design in `PLAN.md`'s aspirational D-04 was never built. Swagger
UI is live at `/swagger-ui.html` (`OpenApiConfig`).

Entities: `Framework`, `Threat` (`entity/`). `stride`, `cveReferences`, `tags`
are stored as **comma-joined `TEXT`** via `StringListConverter` /
`StrideSetConverter`, not native arrays — a deliberate Phase-1 shortcut (see
the converter's own doc comment) that any sibling using a real array/JSON
column type must still serialize to the same `["S","T"]` JSON shape. Note:
`ThreatResponse.from()` guards `stride` against null but passes
`cveReferences`/`tags` straight from the entity with no null-guard — the
converter itself always returns `List.of()` rather than `null`, so this is
currently safe, but don't assume the guard exists if you touch that DTO.

## Known gaps / things to fix, not "mirror"

- **`docker-compose.yml` line 39 is broken**: `ADMIN_PASSWORD_HASH: ${}` should
  be `ADMIN_PASSWORD_HASH: ${ADMIN_PASSWORD_HASH}`. `docker compose up` as
  currently checked in will not pass the admin hash through to the backend
  container. Fix this before treating `docker compose up` as a working
  smoke-test for this app.
- No rate limiting, Redis usage, `AdminController`, or CRUD endpoints yet,
  despite `docker-compose.yml` provisioning a `redis` service — it's started
  but unused by Phase-1 code.

## Running locally

```bash
docker compose up --build   # frontend :8081, backend :8080, swagger-ui.html
```
This machine has no Docker installed (see `../CLAUDE.md`), so day-to-day dev
uses `scripts/local-dev-up.sh` / `local-dev-down.sh` instead — it ensures the
`securevision` role/DB exist on the shared local Postgres instance, it doesn't
own the server. `frontend/dist` is a committed Vite build output — treat it as
generated, not hand-edited. Copy `.env.example` to `.env` and set real values
before running; the dev-only admin credentials (`admin` / `changeme-dev-only`)
live in `docker-compose.yml`/README, not in source control as real secrets.
