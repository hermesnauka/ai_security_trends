local schema = require("lapis.db.schema")
local types = schema.types

return {
  up = function()
    schema.create_table("content_hashes", {
      { "file_name", types.varchar({ primary_key = true }) },
      { "sha256_hash", types.varchar({ null = false }) },
      { "verified_at", types.time({ null = false }) },
      { "is_valid", types.boolean({ null = false }) },
      { "verified_by", types.varchar({ null = false, default = "luaguard-integrity-checker" }) }
    })
  end,
  down = function()
    schema.drop_table("content_hashes")
  end
}
