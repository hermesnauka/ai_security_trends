local schema = require("lapis.db.schema")
local types = schema.types
local db = require("lapis.db")

-- Kept as a distinct table (not just threats.description_pl) so a future
-- third locale doesn't need a schema change — mirrors app13_ruby_FastApi's
-- sp_threat_translations-equivalent shape.
return {
  up = function()
    schema.create_table("threat_translations", {
      { "id", types.serial({ primary_key = true }) },
      { "threat_code", types.varchar({ null = false }) },
      { "locale", types.varchar({ null = false }) },
      { "description", types.text({ null = false }) }
    })

    db.query("alter table threat_translations add constraint threat_translations_threat_code_fk " ..
      "foreign key (threat_code) references threats (code)")
    db.query("create unique index threat_translations_unique_per_locale " ..
      "on threat_translations (threat_code, locale)")
  end,
  down = function()
    schema.drop_table("threat_translations")
  end
}
