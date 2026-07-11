local Model = require("lapis.db.model").Model

local Framework = Model:extend("frameworks", {
  primary_key = "code"
})

return Framework
