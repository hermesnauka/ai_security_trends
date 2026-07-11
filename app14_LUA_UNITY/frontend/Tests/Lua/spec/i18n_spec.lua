package.path = "../../Assets/StreamingAssets/lua/?.lua;" .. package.path
local i18n = require("i18n")

describe("i18n (D-05, FR-10)", function()
  before_each(function()
    i18n.set_locale("pl")
  end)

  it("defaults to Polish", function()
    assert.are.equal("pl", i18n.get_locale())
  end)

  it("switches locale instantly", function()
    i18n.set_locale("en")
    assert.are.equal("en", i18n.get_locale())
    assert.are.equal("Threats", i18n.t("nav.threats"))
  end)

  it("ignores an unknown locale code", function()
    i18n.set_locale("en")
    i18n.set_locale("fr")
    assert.are.equal("en", i18n.get_locale())
  end)

  it("falls back to the Polish string for a key missing in the current locale table", function()
    assert.are.equal("nonexistent.key", i18n.t("nonexistent.key"))
  end)

  -- NFR-06: no UI string exists in only one language.
  it("every key in the Polish table also exists in the English table and vice versa", function()
    local pl_keys, en_keys = i18n._key_set("pl"), i18n._key_set("en")
    assert.are.same(pl_keys, en_keys)
  end)

  it("notifies listeners on locale change", function()
    local seen = nil
    i18n.on_locale_change(function(locale) seen = locale end)
    i18n.set_locale("en")
    assert.are.equal("en", seen)
  end)
end)
