require("spec.spec_helper")
local db = require("lapis.db")
local Card = require("app.models.card")

describe("Card", function()
  -- US-09/D-03: a design_harm row's severity is enforced NULL by a database
  -- CHECK constraint — not merely an application-level convention.
  it("never allows a design_harm row to carry a severity", function()
    assert.has_error(function()
      db.query(
        "insert into cards (card_id, suit_code, suit_name, edition, value, card_kind, severity, " ..
        "description_en, content_sha256, is_critical) values " ..
        "('TEST_DESIGN_HARM_WITH_SEVERITY', 'TS', 'Test', 'test', '2', 'design_harm', 'high', 'x', 'x', false)"
      )
    end)
  end)

  it("never allows a technical_threat row to have a NULL severity", function()
    assert.has_error(function()
      db.query(
        "insert into cards (card_id, suit_code, suit_name, edition, value, card_kind, severity, " ..
        "description_en, content_sha256, is_critical) values " ..
        "('TEST_TECH_THREAT_NO_SEVERITY', 'TS', 'Test', 'test', '2', 'technical_threat', null, 'x', 'x', false)"
      )
    end)
  end)

  it("severity_or_nil is always nil for a design_harm card, regardless of the column", function()
    local dbd_card = Card:find({ edition = "dbd" })
    assert.is_nil(dbd_card:severity_or_nil())
    assert.is_true(dbd_card:design_harm())
  end)
end)
