local schema = require("lapis.db.schema")
local types = schema.types
local db = require("lapis.db")

return {
  up = function()
    schema.create_table("threats", {
      { "code", types.varchar({ primary_key = true }) },
      { "framework_code", types.varchar({ null = false }) },
      { "title", types.varchar({ null = false }) },
      { "severity", types.varchar({ null = false }) },
      { "category", types.varchar({ null = false }) },
      { "description_en", types.text({ null = false }) },
      { "description_pl", types.text({ null = false, default = "" }) },
      { "attack_vector", types.text({ null = false, default = "" }) },
      { "attack_surface", types.text({ null = false, default = "" }) },
      { "stride", "text[] not null default '{}'" },
      { "tags", "text[] not null default '{}'" }
    })

    db.query("alter table threats add constraint threats_framework_code_fk " ..
      "foreign key (framework_code) references frameworks (code)")
    db.query("alter table threats add constraint threats_severity_check " ..
      "check (severity in ('critical', 'high', 'medium', 'low', 'info'))")
    db.query("create index threats_framework_code_idx on threats (framework_code)")
    db.query("create index threats_severity_idx on threats (severity)")
  end,
  down = function()
    schema.drop_table("threats")
  end
}
