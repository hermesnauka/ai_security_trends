-- Phase 2+/3 (PLAN.md §6, requirements.md FR-12-14): the three "Security
-- Architects" game modes described in
-- ../../../../docs/Security Architects+ Comptia+OWASP LLM top10__v01b.md.
-- Every rule below is transcribed directly from that source manual's
-- Regular/Shift Left/Workshop mode sections — see user_stories+tests.md
-- US-15/16/17 for the acceptance criteria these implement.

local card_engine = require("card_engine")

local game_modes = { regular = {}, shift_left = {}, workshop = {} }

-- === Regular Mode ===

function game_modes.regular.new_session()
  return {
    mode = "regular",
    turn = 0,
    reputation = 10,
    components = {
      { id = 1, stride_open = { "S", "T" } },
      { id = 2, stride_open = { "E" } },
      { id = 3, stride_open = { "I", "D" } }
    }
  }
end

-- "If several components match the attack, the defenders arbitrarily choose
-- only one of them to take the hit (in this simplified mode, each attack
-- takes a maximum of 1 point)." — source manual, Regular Mode.
function game_modes.regular.resolve_attack(session, attack)
  for _, component in ipairs(session.components) do
    if card_engine.resolve_attack(component, attack) then
      session.reputation = math.max(0, session.reputation - 1)
      return true
    end
  end
  return false
end

function game_modes.regular.check_end_state(session)
  if session.reputation <= 0 then return "defeat" end
  if session.turn >= 6 then return "victory" end
  return "ongoing"
end

-- === Shift Left Mode ===

function game_modes.shift_left.new_session()
  return {
    mode = "shift_left",
    turn = 0,
    reputation = 10,
    components = {}
  }
end

function game_modes.shift_left.draw_component(session)
  local component = {
    id = #session.components + 1,
    zone = "development",
    stride_open = { "E" }
  }
  table.insert(session.components, component)
  return component
end

-- "At the beginning of the next turn, players have a chance to protect
-- them, after which all Development area components are moved to the
-- Production area (where they can be attacked)." — source manual.
function game_modes.shift_left.advance_turn(session)
  for _, component in ipairs(session.components) do
    if component.zone == "development" then
      component.zone = "production"
    end
  end
  session.turn = session.turn + 1
end

-- "When an attack is drawn, it is immediately applied to ALL components in
-- the Production area that have an open matching vulnerability. The company
-- loses as many reputation points as the number of matching components."
-- — source manual, Shift Left Mode (area/multiple damage).
function game_modes.shift_left.resolve_attack(session, attack)
  local hits = 0
  for _, component in ipairs(session.components) do
    if component.zone == "production" and card_engine.resolve_attack(component, attack) then
      hits = hits + 1
    end
  end
  session.reputation = math.max(0, session.reputation - hits)
  return hits
end

function game_modes.shift_left.check_end_state(session)
  if session.reputation <= 0 then return "defeat" end
  if session.turn >= 6 then return "victory" end
  return "ongoing"
end

-- === Threat Modeling Workshop Mode ===
-- No Component cards — Attack/Protection cards dealt to players against a
-- real system diagram, scored by proposal/counter (source manual).

function game_modes.workshop.new_session()
  return { mode = "workshop", scores = {} }
end

-- @param session table
-- @param attacker_id any player identifier
-- @param countered boolean whether another player successfully countered
--   with a Protection card
function game_modes.workshop.play_attack(session, attacker_id, countered, defender_id)
  session.scores[attacker_id] = session.scores[attacker_id] or 0
  if countered then
    -- "this player steals the attacker's point (gaining +1, while the
    -- attacker gets 0 for this move)" — source manual.
    session.scores[defender_id] = (session.scores[defender_id] or 0) + 1
  else
    session.scores[attacker_id] = session.scores[attacker_id] + 1
  end
end

return game_modes
