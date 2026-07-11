local Model = require("lapis.db.model").Model

local Threat = Model:extend("threats", {
  primary_key = "code",

  relations = {
    { "framework", belongs_to = "Framework", key = "framework_code" },
    { "mitigations", has_many = "Mitigation", key = "threat_code" },
    { "cross_references", has_many = "CrossReference", key = "source_threat_code" }
  },

  -- FR-18.6-equivalent: falls back to English when no Polish translation
  -- exists yet, never a blank field (PLAN.md D-05).
  localized_description = function(self, locale)
    if locale == "pl" and self.description_pl and self.description_pl ~= "" then
      return self.description_pl
    end
    return self.description_en
  end
})

return Threat
