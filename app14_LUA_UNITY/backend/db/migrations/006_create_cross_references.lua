local schema = require("lapis.db.schema")
local types = schema.types
local db = require("lapis.db")

return {
  up = function()
    schema.create_table("cross_references", {
      { "id", types.serial({ primary_key = true }) },
      { "source_threat_code", types.varchar({ null = false }) },
      { "target_threat_code", types.varchar({ null = false }) },
      { "target_threat_title", types.varchar({ null = false }) },
      { "relationship_type", types.varchar({ null = false }) },
      { "description", types.text({ null = false, default = "" }) }
    })

    db.query("alter table cross_references add constraint cross_references_target_fk " ..
      "foreign key (target_threat_code) references threats (code)")
    db.query("create index cross_references_source_idx on cross_references (source_threat_code)")
  end,
  down = function()
    schema.drop_table("cross_references")
  end
}
