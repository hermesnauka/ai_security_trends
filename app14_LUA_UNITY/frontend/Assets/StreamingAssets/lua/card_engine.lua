-- Shared STRIDE-matching primitive used by every game mode in game_modes.lua
-- (D-04: STRIDE-as-gameplay is additive, not a replacement taxonomy — the
-- same STRIDE letters (S/T/R/I/D/E) the backend's threats.stride column
-- uses double as this app's attack/protection matching mechanic).

local card_engine = {}

-- @param component table with `stride_open` — array of STRIDE letters this
--   component currently has unprotected
-- @param attack table with `stride` — array of STRIDE letters this attack
--   card targets
-- @return boolean true if the attack matches at least one open vulnerability
function card_engine.resolve_attack(component, attack)
  local open = {}
  for _, letter in ipairs(component.stride_open or {}) do open[letter] = true end

  for _, letter in ipairs(attack.stride or {}) do
    if not open[letter] then
      return false -- an attack requires ALL its listed categories to be open (Regular mode rule)
    end
  end

  return #(attack.stride or {}) > 0
end

-- Applying a Protection card closes exactly one STRIDE category on one
-- component.
function card_engine.apply_protection(component, protection_letter)
  local remaining = {}
  for _, letter in ipairs(component.stride_open or {}) do
    if letter ~= protection_letter then
      table.insert(remaining, letter)
    end
  end
  component.stride_open = remaining
end

return card_engine
