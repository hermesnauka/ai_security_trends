local schema = require("lapis.db.schema")
local types = schema.types
local db = require("lapis.db")

return {
  up = function()
    schema.create_table("code_samples", {
      { "id", types.serial({ primary_key = true }) },
      { "mitigation_slug", types.varchar({ null = false }) },
      { "language", types.varchar({ null = false }) },
      { "sample_type", types.varchar({ null = false }) },
      { "title", types.varchar({ null = false }) },
      { "description", types.text({ null = false }) },
      { "code", types.text({ null = false }) },
      { "framework_hint", types.varchar({ null = false, default = "" }) },
      { "version_note", types.varchar({ null = false, default = "" }) }
    })

    db.query("alter table code_samples add constraint code_samples_mitigation_slug_fk " ..
      "foreign key (mitigation_slug) references mitigations (slug)")
    db.query("alter table code_samples add constraint code_samples_language_check " ..
      "check (language in ('python', 'java', 'go', 'scala', 'lua'))")
    db.query("alter table code_samples add constraint code_samples_sample_type_check " ..
      "check (sample_type in ('attack_demo', 'defense'))")
    db.query("create unique index code_samples_unique_per_mitigation_lang_type " ..
      "on code_samples (mitigation_slug, language, sample_type)")
  end,
  down = function()
    schema.drop_table("code_samples")
  end
}
