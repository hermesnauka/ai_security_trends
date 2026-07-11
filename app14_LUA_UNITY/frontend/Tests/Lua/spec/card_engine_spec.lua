-- Run standalone via `busted` from Tests/Lua/, no Unity Editor needed
-- (user_stories+tests.md's "Konwencje testowe" — frontend Lua is tested
-- twice: once here, once by Unity PlayMode running the same file through
-- MoonSharp).
package.path = "../../Assets/StreamingAssets/lua/?.lua;" .. package.path
local card_engine = require("card_engine")

describe("card_engine.resolve_attack", function()
  it("matches an attack to an open component vulnerability by STRIDE letter", function()
    local component = { stride_open = { "E" } }
    local attack = { stride = { "E" } }
    assert.is_true(card_engine.resolve_attack(component, attack))
  end)

  it("does not match when the component's vulnerability is already protected", function()
    local component = { stride_open = {} }
    local attack = { stride = { "E" } }
    assert.is_false(card_engine.resolve_attack(component, attack))
  end)

  it("requires ALL of a combined attack's STRIDE letters to be open", function()
    local component = { stride_open = { "S" } }
    local attack = { stride = { "S", "T" } }
    assert.is_false(card_engine.resolve_attack(component, attack))
  end)

  it("matches a combined attack when every listed letter is open", function()
    local component = { stride_open = { "S", "T", "R" } }
    local attack = { stride = { "S", "T" } }
    assert.is_true(card_engine.resolve_attack(component, attack))
  end)
end)

describe("card_engine.apply_protection", function()
  it("closes exactly the specified STRIDE letter, leaving others open", function()
    local component = { stride_open = { "S", "T", "E" } }
    card_engine.apply_protection(component, "T")
    table.sort(component.stride_open)
    assert.are.same({ "E", "S" }, component.stride_open)
  end)
end)
