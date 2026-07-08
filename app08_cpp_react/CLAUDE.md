# CppCitadel 2026 — C++/Drogon implementation (app08_cpp_react)

The C++ implementation — included deliberately as the **counter-example**: no
borrow checker, no macro-checked SQL, no derive-based schema validation. See
`PLAN.md` §0 for the full "what C++ doesn't give you for free" framing, and
`../CLAUDE.md` for the sibling list, canonical API contract, and shared
local-dev setup.

## Current state: backend does not exist yet

Only `frontend/` (React 18 + TS + Vite, already built — `node_modules`/`dist` present)
and `nginx/` (reverse-proxy config) exist. **There is no `backend/` directory, no
`CMakeLists.txt`, no C++ source file anywhere in this app.** `PLAN.md`,
`requirements.md`, `SDLC_analysis.md`, and `user_stories+tests.md` describe a large
19-user-story end state (six OWASP Cornucopia-family card decks, i18n, background
jobs, fuzzing pipeline) — none of it is built. If you are starting backend work here,
you are writing the first line of C++ in this app, not extending existing code.

**`scripts/local-dev-up.sh` is stale/misleading**: it `cd`s into a nonexistent
`backend/` and runs `mvn spring-boot:run` — it was copied from `app01_react` and never
adapted. `.local-dev/backend.log` is a leftover Spring Boot log from that copy, not
evidence of any C++ backend having run. Don't trust either file; rewrite the script
once there's an actual C++ binary to launch.

## Frontend already expects the canonical contract

`frontend/src/types/*.ts` is already written against the canonical contract's
shape (see `../CLAUDE.md`) — don't change it without updating the frontend.

## Planned stack (decided in PLAN.md §2, nothing built against it yet)

- **Language/toolchain**: C++23, GCC 14+ or Clang 18+
- **Web framework**: Drogon 1.9.x (async, C++20 coroutines)
- **Build system**: CMake, top-level `CMakeLists.txt` with subdirectories for
  `core`/`api`/`worker`; dependency manifest is `conanfile.txt` **or** `vcpkg.json` —
  PLAN.md hasn't committed to one yet (§5.7/appendix), decide this before scaffolding
- **DB access**: `libpqxx` (parameterized queries) + `sqlpp11` for the subset of
  hot-path queries that want compile-time query-shape checking; Postgres 16
- **Auth**: `jwt-cpp` doing RS256 (PLAN.md D-04) — per `../CLAUDE.md`, app01's actual
  auth is HS256 with a shared secret, not a key pair; resolve that mismatch before
  implementing, don't silently "fix" the contract's actual behavior back to RS256
- **Password hashing**: `libsodium` Argon2id (never hand-rolled)
- **JSON / YAML / logging**: `nlohmann::json`, `yaml-cpp` (hand-written unknown-key
  rejection, PLAN.md D-03), `spdlog`
- **Testing**: GoogleTest + GoogleMock + RapidCheck (property tests), Drogon's own
  HTTP test client; every `ctest` run under AddressSanitizer+UndefinedBehaviorSanitizer
- **API docs**: hand-maintained OpenAPI 3 YAML, checked in CI against the Drogon route
  table — there is no servant-swagger/Tapir/utoipa equivalent for C++, so this is
  manually kept in sync, not generated

## Before scaffolding backend/

1. Read `../app01_react/backend/src/main/java/com/securevision/` for the actual
   Phase-1 endpoint/field behavior — treat PLAN.md's aspirational sections (RS256 JWT,
   background jobs, six card decks) as out of scope until Phase-1 parity is done.
2. Check whether `app07_rust_react` or `app06_HASKELL_react` backends have already
   picked conventions worth mirroring (route layout, migration runner style) before
   inventing new ones here.
3. Decide Conan vs vcpkg once, in `PLAN.md`'s note, before generating build files —
   don't let it become an undocumented default.
