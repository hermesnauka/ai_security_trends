local schema = require("lapis.db.schema")
local types = schema.types

return {
  up = function()
    schema.create_table("frameworks", {
      { "code", types.varchar({ primary_key = true }) },
      { "name", types.varchar({ null = false }) },
      { "version", types.varchar({ null = false, default = "" }) },
      { "description", types.text({ null = false, default = "" }) },
      { "reference_url", types.varchar({ null = false, default = "" }) }
    })
  end,
  down = function()
    schema.drop_table("frameworks")
  end
}
