local Model = require("lapis.db.model").Model

local CodeSample = Model:extend("code_samples", {
  relations = {
    { "mitigation", belongs_to = "Mitigation", key = "mitigation_slug" }
  }
})

return CodeSample
