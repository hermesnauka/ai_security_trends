local json = require("cjson")
local CardDecodeError = require("app.services.card_decode_error")

-- SR-07/D-06: every curated owasp_refs/mitre_refs value is validated against
-- a bundled allowlist before being written to the database — an unknown
-- reference aborts ingestion, mirroring app13_ruby_FastApi's ReferenceValidator.
local ReferenceValidator = {}
ReferenceValidator.__index = ReferenceValidator

local function read_json(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return json.decode(content)
end

function ReferenceValidator.new(seeds_root)
  local self = setmetatable({}, ReferenceValidator)
  self.seeds_root = seeds_root

  local owasp = read_json(seeds_root .. "/ref-allowlists.json") or {}
  local mitre = read_json(seeds_root .. "/mitre-atlas-allowlist.json") or {}

  self.owasp_refs = {}
  for _, ref in ipairs(owasp.owasp_refs or {}) do self.owasp_refs[ref] = true end

  self.mitre_refs = {}
  for _, ref in ipairs(mitre.mitre_refs or {}) do self.mitre_refs[ref] = true end

  return self
end

function ReferenceValidator:assert_owasp_refs_valid(refs, card_id)
  for _, ref in ipairs(refs or {}) do
    if not self.owasp_refs[ref] then
      error(CardDecodeError.unknown_reference(ref, "owasp_refs", card_id))
    end
  end
end

function ReferenceValidator:assert_mitre_refs_valid(refs, card_id)
  for _, ref in ipairs(refs or {}) do
    if not self.mitre_refs[ref] then
      error(CardDecodeError.unknown_reference(ref, "mitre_refs", card_id))
    end
  end
end

return ReferenceValidator
