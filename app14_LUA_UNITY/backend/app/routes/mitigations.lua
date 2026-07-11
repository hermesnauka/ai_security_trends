local db = require("lapis.db")

local function code_sample_entity(s)
  return {
    language = s.language,
    sampleType = s.sample_type,
    title = s.title,
    description = s.description,
    code = s.code,
    frameworkHint = s.framework_hint,
    versionNote = s.version_note
  }
end

local function mitigation_entity(m, code_samples)
  return {
    slug = m.slug,
    threatCode = m.threat_code,
    cardId = m.card_id,
    title = m.title,
    description = m.description,
    mitigationType = m.mitigation_type,
    effort = m.effort,
    effectiveness = m.effectiveness,
    codeSamples = code_samples
  }
end

-- FR-08/DR-02: one mitigation, five languages (Python/Java/Go/Scala/Lua),
-- each with an attack_demo + defense pair — SR-09's D-09 confirmation gate
-- is enforced client-side (Unity), not here; this route returns both sample
-- types unconditionally, matching every sibling's own API-level behavior.
return function(app)
  app:get("/api/v1/mitigations/:threat_code", function(self)
    local mitigations = db.select("* from mitigations where threat_code = ? order by slug", self.params.threat_code)
    local result = {}

    for _, m in ipairs(mitigations) do
      local samples = db.select(
        "* from code_samples where mitigation_slug = ? order by language, sample_type", m.slug
      )
      local sample_entities = {}
      for _, s in ipairs(samples) do table.insert(sample_entities, code_sample_entity(s)) end
      table.insert(result, mitigation_entity(m, sample_entities))
    end

    return { json = result }
  end)
end
