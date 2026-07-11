local schema = require("lapis.db.schema")
local types = schema.types
local db = require("lapis.db")

-- Phase 2+/3 feature (PLAN.md §6, requirements.md FR-12-14) — this table
-- exists from Phase 1 onward so migration ordering is stable, but no route
-- writes to it until the game-mode work begins. Deliberately NOT linked to
-- `users` (DR-04): gameplay sessions are anonymous.
return {
  up = function()
    schema.create_table("game_sessions", {
      { "id", types.serial({ primary_key = true }) },
      { "player_token", types.varchar({ null = false }) },
      { "mode", types.varchar({ null = false }) },
      { "turn", types.integer({ null = false, default = 0 }) },
      { "reputation", types.integer({ null = false, default = 10 }) },
      { "components", types.text({ null = false, default = "[]" }) }, -- jsonb-as-text via pgmoon cast at query time
      { "created_at", types.time({ null = false }) },
      { "completed_at", types.time({ null = true }) }
    })

    db.query("alter table game_sessions add constraint game_sessions_mode_check " ..
      "check (mode in ('regular', 'shift_left', 'workshop'))")
    db.query("alter table game_sessions add constraint game_sessions_reputation_check " ..
      "check (reputation >= 0 and reputation <= 10)")
  end,
  down = function()
    schema.drop_table("game_sessions")
  end
}
