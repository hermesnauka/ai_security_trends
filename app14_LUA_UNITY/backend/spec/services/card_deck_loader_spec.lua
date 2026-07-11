require("spec.spec_helper")
local ReferenceValidator = require("app.services.reference_validator")
local CardDeckLoader = require("app.services.card_deck_loader")

describe("CardDeckLoader", function()
  local reference_validator = ReferenceValidator.new(SEEDS_ROOT)
  local loader = CardDeckLoader.new(reference_validator, SEEDS_ROOT)

  -- Regression test: the real `webapp` deck has 80 raw cards but only a
  -- representative 14 are curated — loading it must succeed and silently
  -- skip every uncurated card, NOT raise. Mirrors the exact bug found and
  -- fixed in app11/app12/app13's equivalent loaders: `build_seed` used to
  -- raise MissingCuratedSeverity for ANY card with no curation entry at
  -- all, rather than only for a curated-but-malformed entry.
  it("loads the real webapp deck, skipping uncurated cards instead of raising", function()
    local entry
    for _, e in ipairs(CardDeckLoader.DECK_MANIFEST) do
      if e.edition == "webapp" then entry = e end
    end

    local seeds = loader:load_deck(entry)

    assert.is_true(#seeds > 0)
    assert.is_true(#seeds < 80)

    local found_ve3 = false
    for _, seed in ipairs(seeds) do
      if seed.card_id == "VE3" then found_ve3 = true end
    end
    assert.is_true(found_ve3)
  end)

  it("loads all six real decks successfully", function()
    local seeds = loader:load_all()
    local editions = {}
    for _, seed in ipairs(seeds) do editions[seed.edition] = true end

    local expected = { companion = true, dbd = true, eop = true, mlsec = true, mobileapp = true, webapp = true }
    assert.are.same(expected, editions)
  end)

  it("marks every dbd card as design_harm with a nil severity", function()
    local entry
    for _, e in ipairs(CardDeckLoader.DECK_MANIFEST) do
      if e.design_harm then entry = e end
    end

    local seeds = loader:load_deck(entry)
    assert.is_true(#seeds > 0)
    for _, seed in ipairs(seeds) do
      assert.are.equal("design_harm", seed.card_kind)
      assert.is_nil(seed.severity)
    end
  end)

  it("raises MissingCuratedSeverity for a curated-but-malformed severity entry", function()
    local tmp_dir = os.tmpname() .. "_dir"
    os.execute("mkdir -p " .. tmp_dir .. "/cornucopia")

    local yaml_content = [[
meta:
  edition: "fixture"
  component: "cards"
  language: "en"
  version: "1.0"
suits:
-
  id: "FX"
  name: "Fixture"
  cards:
  -
    id: "FX1"
    value: "2"
    desc: "A fixture card."
]]
    local f = io.open(tmp_dir .. "/cornucopia/fixture-deck.yaml", "w")
    f:write(yaml_content)
    f:close()

    f = io.open(tmp_dir .. "/cornucopia/fixture.curation.json", "w")
    f:write('{ "FX1": { "severity": "", "owasp_refs": [], "mitre_refs": [] } }')
    f:close()

    f = io.open(tmp_dir .. "/ref-allowlists.json", "w")
    f:write('{ "owasp_refs": [] }')
    f:close()

    f = io.open(tmp_dir .. "/mitre-atlas-allowlist.json", "w")
    f:write('{ "mitre_refs": [] }')
    f:close()

    local fixture_validator = ReferenceValidator.new(tmp_dir)
    local fixture_loader = CardDeckLoader.new(fixture_validator, tmp_dir)
    local entry = { yaml_file_name = "fixture-deck", curation_file_name = "fixture.curation", edition = "fixture", design_harm = false }

    assert.has_error(function() fixture_loader:load_deck(entry) end)

    os.execute("rm -rf " .. tmp_dir)
  end)

  it("rejects a YAML file with an unrecognized top-level key (D-06)", function()
    local tmp_dir = os.tmpname() .. "_dir"
    os.execute("mkdir -p " .. tmp_dir .. "/cornucopia")

    local yaml_content = [[
meta:
  edition: "fixture"
  component: "cards"
  language: "en"
  version: "1.0"
suits: []
extra_top_level_key: "evil"
]]
    local f = io.open(tmp_dir .. "/cornucopia/fixture-deck.yaml", "w")
    f:write(yaml_content)
    f:close()

    local fixture_loader = CardDeckLoader.new(reference_validator, tmp_dir)
    local entry = { yaml_file_name = "fixture-deck", curation_file_name = "fixture.curation", edition = "fixture", design_harm = false }

    assert.has_error(function() fixture_loader:load_deck(entry) end)

    os.execute("rm -rf " .. tmp_dir)
  end)
end)
