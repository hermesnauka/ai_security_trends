local json = require("cjson")
local db = require("lapis.db")
local Framework = require("app.models.framework")
local Threat = require("app.models.threat")
local ThreatTranslation = require("app.models.threat_translation")
local CrossReference = require("app.models.cross_reference")
local Card = require("app.models.card")
local Mitigation = require("app.models.mitigation")
local CodeSample = require("app.models.code_sample")
local ReferenceValidator = require("app.services.reference_validator")
local CardDeckLoader = require("app.services.card_deck_loader")
local IntegrityChecker = require("app.services.integrity_checker")

-- The single entry point tying every seed step together — mirrors
-- app13_ruby_FastApi's ContentSeeder. Idempotent: safe to call on every
-- deploy, upserting rather than duplicating.
local ContentSeeder = {}
ContentSeeder.__index = ContentSeeder

function ContentSeeder.new(seeds_root)
  local self = setmetatable({}, ContentSeeder)
  self.seeds_root = seeds_root
  self.reference_validator = ReferenceValidator.new(seeds_root)
  self.card_loader = CardDeckLoader.new(self.reference_validator, seeds_root)
  self.integrity_checker = IntegrityChecker.new(seeds_root)
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

local function read_json(seeds_root, name)
  local path = seeds_root .. "/" .. name
  if not file_exists(path) then return {} end
  return json.decode(read_file(path))
end

-- Seed data stores STRIDE as the Cornucopia 2-letter suit code (SP, TA, RE,
-- ID, DS, EP), matching every sibling's convention — mapped here to the
-- single-letter STRIDE categories this app's own filter/heatmap use.
local STRIDE_MAPPING = { SP = "S", TA = "T", RE = "R", ID = "I", DS = "D", EP = "E" }

local function stride_categories(suit_code)
  local mapped = STRIDE_MAPPING[suit_code]
  if mapped then return { mapped } end
  return {}
end

local function pg_array(values)
  -- pgmoon/Lapis represent a text[] literal as "{a,b,c}" for a raw insert;
  -- callers passing this through db.query build the literal themselves.
  local escaped = {}
  for _, v in ipairs(values or {}) do table.insert(escaped, v) end
  return "{" .. table.concat(escaped, ",") .. "}"
end

function ContentSeeder:seed_frameworks()
  for _, seed in ipairs(read_json(self.seeds_root, "frameworks.json")) do
    db.query(
      "insert into frameworks (code, name, version, description, reference_url) values (?, ?, ?, ?, ?) " ..
      "on conflict (code) do update set name = excluded.name, version = excluded.version, " ..
      "description = excluded.description, reference_url = excluded.reference_url",
      seed.code, seed.name, seed.version, seed.description, seed.referenceUrl
    )
  end
end

function ContentSeeder:seed_threats()
  for _, seed in ipairs(read_json(self.seeds_root, "threats_seed.json")) do
    local exists = Threat:find(seed.code)
    local framework_exists = Framework:find(seed.frameworkCode)
    -- Threats are seeded once; edits happen via translations, not re-seeding.
    if not exists and framework_exists then
      Threat:create({
        code = seed.code,
        framework_code = seed.frameworkCode,
        title = seed.title,
        severity = seed.severity,
        category = seed.category,
        description_en = seed.description,
        description_pl = seed.description, -- overwritten by seed_threat_translations if a 'pl' row exists
        attack_vector = seed.attack_vector or "",
        attack_surface = seed.attack_surface or "",
        stride = pg_array(stride_categories(seed.stride)),
        tags = pg_array(seed.tags or {})
      })
    end
  end
end

function ContentSeeder:seed_threat_translations()
  for _, seed in ipairs(read_json(self.seeds_root, "threat_translations_seed.json")) do
    if seed.locale == "pl" then
      local threat = Threat:find(seed.code)
      if threat then
        threat:update({ description_pl = seed.description })
      end
    end
  end
end

function ContentSeeder:seed_cross_references()
  for _, seed in ipairs(read_json(self.seeds_root, "cross_references_seed.json")) do
    local target = Threat:find(seed.targetCode)
    if target then
      local already_seeded = CrossReference:find({
        source_threat_code = seed.sourceCode,
        target_threat_code = seed.targetCode
      })
      if not already_seeded then
        CrossReference:create({
          source_threat_code = seed.sourceCode,
          target_threat_code = seed.targetCode,
          target_threat_title = target.title,
          relationship_type = seed.relationshipType,
          description = seed.description or ""
        })
      end
    end
  end
end

function ContentSeeder:seed_cards()
  for _, seed in ipairs(self.card_loader:load_all()) do
    db.query(
      "insert into cards (card_id, suit_code, suit_name, edition, value, card_kind, severity, " ..
      "description_en, description_pl, misc_note, source_url, owasp_refs, mitre_refs, " ..
      "content_sha256, is_critical) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) " ..
      "on conflict (card_id) do update set severity = excluded.severity, " ..
      "description_en = excluded.description_en, description_pl = excluded.description_pl, " ..
      "owasp_refs = excluded.owasp_refs, mitre_refs = excluded.mitre_refs, " ..
      "content_sha256 = excluded.content_sha256",
      seed.card_id, seed.suit_code, seed.suit_name, seed.edition, seed.value, seed.card_kind,
      seed.severity, seed.description_en, seed.description_pl, seed.misc_note, seed.source_url,
      pg_array(seed.owasp_refs), pg_array(seed.mitre_refs), seed.content_sha256, seed.is_critical
    )
  end
end

function ContentSeeder:seed_mitigations_and_code_samples()
  for _, seed in ipairs(read_json(self.seeds_root, "mitigations_seed.json")) do
    db.query(
      "insert into mitigations (slug, threat_code, card_id, title, description, mitigation_type, " ..
      "effort, effectiveness) values (?, ?, ?, ?, ?, ?, ?, ?) " ..
      "on conflict (slug) do update set title = excluded.title, description = excluded.description, " ..
      "mitigation_type = excluded.mitigation_type, effort = excluded.effort, " ..
      "effectiveness = excluded.effectiveness",
      seed.slug, seed.threatCode, seed.cardId, seed.title, seed.description,
      seed.mitigationType, seed.effort, seed.effectiveness
    )
  end

  for _, entry in ipairs(read_json(self.seeds_root, "code_samples_manifest.json")) do
    local mitigation = Mitigation:find(entry.mitigationSlug)
    if mitigation then
      local already_seeded = CodeSample:find({
        mitigation_slug = entry.mitigationSlug,
        language = entry.language,
        sample_type = entry.sampleType
      })
      if not already_seeded then
        local code_path = self.seeds_root .. "/code_samples/" .. entry.file
        if file_exists(code_path) then
          CodeSample:create({
            mitigation_slug = entry.mitigationSlug,
            language = entry.language,
            sample_type = entry.sampleType,
            title = entry.title,
            description = entry.description,
            code = read_file(code_path),
            framework_hint = entry.frameworkHint or "",
            version_note = entry.versionNote or ""
          })
        end
      end
    end
  end
end

function ContentSeeder:seed()
  self:seed_frameworks()
  self:seed_threats()
  self:seed_threat_translations()
  self:seed_cross_references()
  self:seed_cards()
  self:seed_mitigations_and_code_samples()
  self.integrity_checker:verify()
end

return ContentSeeder
