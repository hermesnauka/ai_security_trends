require("spec.spec_helper")
local ReferenceValidator = require("app.services.reference_validator")

describe("ReferenceValidator", function()
  local validator = ReferenceValidator.new(SEEDS_ROOT)

  it("accepts a known OWASP ref", function()
    assert.has_no.errors(function() validator:assert_owasp_refs_valid({ "A03:2021" }, "TEST") end)
  end)

  it("accepts a known MITRE ATLAS ref", function()
    assert.has_no.errors(function() validator:assert_mitre_refs_valid({ "AML.T0051" }, "TEST") end)
  end)

  it("rejects an unknown OWASP ref", function()
    local ok, err = pcall(function() validator:assert_owasp_refs_valid({ "A99:2099" }, "TEST") end)
    assert.is_false(ok)
    assert.are.equal("A99:2099", err.value)
    assert.are.equal("owasp_refs", err.field)
    assert.are.equal("TEST", err.card_id)
  end)

  it("rejects an unknown MITRE ref", function()
    assert.has_error(function() validator:assert_mitre_refs_valid({ "AML.T9999" }, "TEST") end)
  end)

  it("never raises for an empty refs list", function()
    assert.has_no.errors(function() validator:assert_owasp_refs_valid({}, "TEST") end)
    assert.has_no.errors(function() validator:assert_mitre_refs_valid({}, "TEST") end)
  end)
end)
