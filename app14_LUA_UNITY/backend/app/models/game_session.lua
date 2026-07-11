local Model = require("lapis.db.model").Model
local json = require("cjson")

-- Phase 2+/3 (PLAN.md §6). DR-04: deliberately no `users` relation — sessions
-- are anonymous, identified only by an opaque `player_token`.
local GameSession = Model:extend("game_sessions", {
  components_table = function(self)
    return json.decode(self.components or "[]")
  end,

  set_components_table = function(self, components)
    self:update({ components = json.encode(components) })
  end
})

return GameSession
