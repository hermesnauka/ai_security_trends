local Model = require("lapis.db.model").Model

local ThreatTranslation = Model:extend("threat_translations", {
  relations = {
    { "threat", belongs_to = "Threat", key = "threat_code" }
  }
})

return ThreatTranslation
