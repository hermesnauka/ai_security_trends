-- Composition root for the Lua half of the client — loaded last by
-- Bootstrap.cs, after i18n/api_client/card_engine/game_modes are already in
-- package.loaded. `bootstrap()` is the one function Bootstrap.cs calls into
-- after loading every file; it does not itself contain gameplay logic, only
-- wiring (mirrors backend/app.lua's role of mounting routes without
-- containing route logic itself).

local i18n = require("i18n")

function bootstrap()
  -- Real UI Toolkit scene wiring (LoginScene, FrameworksScene, etc.,
  -- PLAN.md §8) is Editor-authored (.uxml/.uss + scene C# controllers) and
  -- out of this Lua file's scope — this function's job in Phase 1 is only
  -- to confirm the sandboxed Lua environment is alive and the default
  -- locale is set, the same smoke-test role app13's own bootstrap-equivalent
  -- code plays before any real screen exists.
  i18n.set_locale("pl")
end
