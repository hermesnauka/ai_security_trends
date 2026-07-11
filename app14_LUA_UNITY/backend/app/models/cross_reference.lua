local Model = require("lapis.db.model").Model

local CrossReference = Model:extend("cross_references", {
  relations = {
    { "target_threat", belongs_to = "Threat", key = "target_threat_code" }
  }
})

return CrossReference
