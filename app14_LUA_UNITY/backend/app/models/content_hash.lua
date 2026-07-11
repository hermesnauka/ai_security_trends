local Model = require("lapis.db.model").Model

local ContentHash = Model:extend("content_hashes", {
  primary_key = "file_name"
})

return ContentHash
