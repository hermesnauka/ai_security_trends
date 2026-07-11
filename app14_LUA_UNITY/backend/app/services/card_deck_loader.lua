local yaml = require("lyaml")
local json = require("cjson")
local sha256 = require("resty.sha256")
local str = require("resty.string")
local CardDecodeError = require("app.services.card_decode_error")

-- D-06/§0.1: decodes a deck's raw YAML (allow-list enforced), merges in
-- curated severity/refs (never read from the YAML itself), and produces
-- card-row tables ready for a Postgres insert. Mirrors app13_ruby_FastApi's
-- CardFileLoader.
--
-- lyaml's underlying libyaml is lenient by default — the opposite end of the
-- spectrum from a strict decoder. This module hand-checks
-- `raw_keys - ALLOWED_KEYS` and raises CardDecodeError.unrecognized_fields
-- rather than relying on a strict decoder default (D-06).
local CardDeckLoader = {}
CardDeckLoader.__index = CardDeckLoader

local ALLOWED_ROOT_KEYS = { meta = true, suits = true }
local ALLOWED_META_KEYS = { edition = true, component = true, language = true, version = true }
local ALLOWED_SUIT_KEYS = { id = true, name = true, cards = true, sentences = true }
local ALLOWED_CARD_KEYS = { id = true, value = true, url = true, desc = true, misc = true }

-- Mirrors app09/app11/app12/app13's DeckManifestEntry.all — the six decks,
-- their curation files, and which one (dbd) is the design-harm deck whose
-- card_kind is forced by file identity, never read from a field.
CardDeckLoader.DECK_MANIFEST = {
  { yaml_file_name = "webapp-cards-3.0-en", curation_file_name = "webapp.curation", edition = "webapp", design_harm = false },
  { yaml_file_name = "mobileapp-cards-1.1-en", curation_file_name = "mobileapp.curation", edition = "mobileapp", design_harm = false },
  { yaml_file_name = "companion-llm-cards-1.0-en", curation_file_name = "companion.curation", edition = "companion", design_harm = false },
  { yaml_file_name = "stride-eop-cards-5.0-en", curation_file_name = "stride-eop.curation", edition = "eop", design_harm = false },
  { yaml_file_name = "mlsec-cards-1.0-en", curation_file_name = "mlsec.curation", edition = "mlsec", design_harm = false },
  { yaml_file_name = "dbd-cards-1.0-en", curation_file_name = "dbd.curation", edition = "dbd", design_harm = true }
}

function CardDeckLoader.new(reference_validator, seeds_root)
  local self = setmetatable({}, CardDeckLoader)
  self.reference_validator = reference_validator
  self.seeds_root = seeds_root
  return self
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close(); return true end
  return false
end

local function keys_of(t)
  local keys = {}
  for k in pairs(t or {}) do table.insert(keys, k) end
  return keys
end

local function assert_allowed_keys(t, allowed, context)
  local unrecognized = {}
  for k in pairs(t or {}) do
    if not allowed[k] then table.insert(unrecognized, k) end
  end
  if #unrecognized > 0 then
    error(CardDecodeError.unrecognized_fields(context, unrecognized))
  end
end

local function sha256_hex(input)
  local digest = sha256:new()
  digest:update(input)
  return str.to_hex(digest:final())
end

local function is_critical_value(value)
  return value == "K" or value == "Q" or value == "A"
end

local function load_json_object(path)
  if not file_exists(path) then return {} end
  local raw = json.decode(read_file(path))
  raw["_comment"] = nil -- reserved top-level key, plain string, not a card entry
  return raw
end

local function extract_cards(suits)
  local cards = {}
  for _, suit in ipairs(suits or {}) do
    assert_allowed_keys(suit, ALLOWED_SUIT_KEYS, "suit")
    -- The "Common"/metadata suit has no `cards` array at all — it carries no
    -- threat data and is skipped, not a decode error.
    if suit.cards then
      for _, card in ipairs(suit.cards) do
        assert_allowed_keys(card, ALLOWED_CARD_KEYS, "card")
        if not (card.id and card.value and card.desc) then
          error(CardDecodeError.missing_required_field("id/value/desc"))
        end
        table.insert(cards, {
          card = { id = card.id, value = card.value, url = card.url, desc = card.desc, misc = card.misc },
          suit_code = suit.id,
          suit_name = suit.name
        })
      end
    end
  end
  return cards
end

-- Content-scope note (PLAN.md §0.1): every deck ships far more raw cards than
-- are curated. A card with NO curation entry at all is silently skipped here
-- (returns nil) — that's the expected, common case, not an error. A card
-- that DOES have a curation entry but an invalid/missing severity is a real
-- data bug in the curation file and still raises MissingCuratedSeverity —
-- these are two different failure modes and must not be conflated, mirroring
-- the fix made to app11_swift_ios's/app12_kotlin_android's/app13's loaders.
function CardDeckLoader:build_seed(card, suit_code, suit_name, manifest_entry, curation_entry, translation)
  local card_kind, severity

  if manifest_entry.design_harm then
    card_kind = "design_harm"
    severity = nil
  else
    if curation_entry == nil then return nil end

    severity = curation_entry.severity
    if severity == nil or severity == "" then
      error(CardDecodeError.missing_curated_severity(card.id))
    end
    card_kind = "technical_threat"
  end

  local owasp_refs = (curation_entry and curation_entry.owasp_refs) or {}
  local mitre_refs = (curation_entry and curation_entry.mitre_refs) or {}
  self.reference_validator:assert_owasp_refs_valid(owasp_refs, card.id)
  self.reference_validator:assert_mitre_refs_valid(mitre_refs, card.id)

  local description_en = card.desc
  local description_pl = translation or description_en -- FR-18.6: fall back to English, never blank

  local content_sha256 = sha256_hex(
    table.concat({ card.id, card.value, card.url or "", description_en, card.misc or "" }, "|")
  )

  return {
    card_id = card.id,
    suit_code = suit_code,
    suit_name = suit_name,
    edition = manifest_entry.edition,
    value = card.value,
    card_kind = card_kind,
    severity = severity,
    description_en = description_en,
    description_pl = description_pl,
    misc_note = card.misc or "",
    source_url = card.url or "",
    owasp_refs = owasp_refs,
    mitre_refs = mitre_refs,
    content_sha256 = content_sha256,
    is_critical = is_critical_value(card.value)
  }
end

function CardDeckLoader:load_deck(entry)
  local yaml_path = self.seeds_root .. "/cornucopia/" .. entry.yaml_file_name .. ".yaml"
  if not file_exists(yaml_path) then
    error(CardDecodeError.missing_required_field("deck file not found: " .. yaml_path))
  end

  local deck = yaml.load(read_file(yaml_path))
  assert_allowed_keys(deck, ALLOWED_ROOT_KEYS, "root")
  if deck.meta then
    assert_allowed_keys(deck.meta, ALLOWED_META_KEYS, "meta")
  end

  local raw_cards = extract_cards(deck.suits or {})
  local known_ids = {}
  for _, entry_hash in ipairs(raw_cards) do known_ids[entry_hash.card.id] = true end

  local curation_path = self.seeds_root .. "/cornucopia/" .. entry.curation_file_name .. ".json"
  local curation = load_json_object(curation_path)
  for card_id in pairs(curation) do
    if not known_ids[card_id] then
      error(CardDecodeError.orphan_curation_entry(card_id, entry.curation_file_name))
    end
  end

  local translations_path = self.seeds_root .. "/cornucopia/translations/pl.cards.json"
  local translations = load_json_object(translations_path)

  local seeds = {}
  for _, entry_hash in ipairs(raw_cards) do
    local seed = self:build_seed(
      entry_hash.card, entry_hash.suit_code, entry_hash.suit_name,
      entry, curation[entry_hash.card.id], translations[entry_hash.card.id]
    )
    if seed then table.insert(seeds, seed) end
  end

  return seeds
end

-- Loads every deck in DECK_MANIFEST, then — only once every deck's card IDs
-- are known — checks the shared pl.cards.json translations file for an
-- orphaned key, since that file isn't scoped to a single deck.
function CardDeckLoader:load_all()
  local all_seeds = {}
  local all_card_ids = {}

  for _, entry in ipairs(self.DECK_MANIFEST) do
    local seeds = self:load_deck(entry)
    for _, seed in ipairs(seeds) do
      all_card_ids[seed.card_id] = true
      table.insert(all_seeds, seed)
    end
  end

  local translations_path = self.seeds_root .. "/cornucopia/translations/pl.cards.json"
  if file_exists(translations_path) then
    local translations = load_json_object(translations_path)
    for card_id in pairs(translations) do
      if not all_card_ids[card_id] then
        error(CardDecodeError.orphan_curation_entry(card_id, "pl.cards.json"))
      end
    end
  end

  return all_seeds
end

return CardDeckLoader
