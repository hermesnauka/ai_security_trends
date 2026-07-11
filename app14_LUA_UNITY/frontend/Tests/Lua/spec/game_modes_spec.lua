package.path = "../../Assets/StreamingAssets/lua/?.lua;" .. package.path
local game_modes = require("game_modes")

describe("game_modes.regular", function()
  it("starts with reputation 10", function()
    local session = game_modes.regular.new_session()
    assert.are.equal(10, session.reputation)
  end)

  it("an attack against a fully-protected component does nothing", function()
    local session = game_modes.regular.new_session()
    for _, component in ipairs(session.components) do component.stride_open = {} end
    local rep_before = session.reputation
    game_modes.regular.resolve_attack(session, { stride = { "E" } })
    assert.are.equal(rep_before, session.reputation)
  end)

  it("an attack against an open matching vulnerability costs exactly 1 reputation", function()
    local session = game_modes.regular.new_session()
    session.components[2].stride_open = { "E" }
    local rep_before = session.reputation
    game_modes.regular.resolve_attack(session, { stride = { "E" } })
    assert.are.equal(rep_before - 1, session.reputation)
  end)

  it("declares defeat when reputation reaches 0", function()
    local session = game_modes.regular.new_session()
    session.reputation = 0
    assert.are.equal("defeat", game_modes.regular.check_end_state(session))
  end)

  it("declares victory after 6 turns with reputation > 0", function()
    local session = game_modes.regular.new_session()
    session.turn = 6
    assert.are.equal("victory", game_modes.regular.check_end_state(session))
  end)
end)

describe("game_modes.shift_left", function()
  it("a newly drawn component starts in the development zone", function()
    local session = game_modes.shift_left.new_session()
    local component = game_modes.shift_left.draw_component(session)
    assert.are.equal("development", component.zone)
  end)

  it("a component in the development zone cannot be attacked", function()
    local session = game_modes.shift_left.new_session()
    game_modes.shift_left.draw_component(session)
    local rep_before = session.reputation
    game_modes.shift_left.resolve_attack(session, { stride = { "E" } })
    assert.are.equal(rep_before, session.reputation)
  end)

  it("advance_turn moves development components to production", function()
    local session = game_modes.shift_left.new_session()
    local component = game_modes.shift_left.draw_component(session)
    game_modes.shift_left.advance_turn(session)
    assert.are.equal("production", component.zone)
  end)

  it("an area attack costs 1 reputation per matching open production component", function()
    local session = game_modes.shift_left.new_session()
    game_modes.shift_left.draw_component(session)
    game_modes.shift_left.draw_component(session)
    game_modes.shift_left.advance_turn(session)
    local rep_before = session.reputation
    local hits = game_modes.shift_left.resolve_attack(session, { stride = { "E" } })
    assert.are.equal(2, hits)
    assert.are.equal(rep_before - 2, session.reputation)
  end)
end)

describe("game_modes.workshop", function()
  it("an uncountered attack gives the attacker +1", function()
    local session = game_modes.workshop.new_session()
    game_modes.workshop.play_attack(session, "alice", false)
    assert.are.equal(1, session.scores.alice)
  end)

  it("a countered attack steals the point: attacker gets 0, defender gets +1", function()
    local session = game_modes.workshop.new_session()
    game_modes.workshop.play_attack(session, "alice", true, "bob")
    assert.are.equal(0, session.scores.alice)
    assert.are.equal(1, session.scores.bob)
  end)
end)
