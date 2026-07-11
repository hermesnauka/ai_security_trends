local Model = require("lapis.db.model").Model

local Mitigation = Model:extend("mitigations", {
  primary_key = "slug",

  relations = {
    { "threat", belongs_to = "Threat", key = "threat_code" },
    { "card", belongs_to = "Card", key = "card_id" },
    { "code_samples", has_many = "CodeSample", key = "mitigation_slug" }
  }
})

return Mitigation
