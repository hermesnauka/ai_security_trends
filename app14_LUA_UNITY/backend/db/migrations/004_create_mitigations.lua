local schema = require("lapis.db.schema")
local types = schema.types
local db = require("lapis.db")

return {
  up = function()
    schema.create_table("mitigations", {
      { "slug", types.varchar({ primary_key = true }) },
      { "threat_code", types.varchar({ null = true }) },
      { "card_id", types.varchar({ null = true }) },
      { "title", types.varchar({ null = false }) },
      { "description", types.text({ null = false }) },
      { "mitigation_type", types.varchar({ null = false }) },
      { "effort", types.varchar({ null = false }) },
      { "effectiveness", types.varchar({ null = false }) }
    })

    db.query("alter table mitigations add constraint mitigations_threat_code_fk " ..
      "foreign key (threat_code) references threats (code)")
    db.query("alter table mitigations add constraint mitigations_card_id_fk " ..
      "foreign key (card_id) references cards (card_id)")
    db.query("alter table mitigations add constraint mitigations_type_check " ..
      "check (mitigation_type in ('preventive', 'detective', 'corrective', 'compensating'))")
    db.query("alter table mitigations add constraint mitigations_effort_check " ..
      "check (effort in ('low', 'medium', 'high'))")
    db.query("alter table mitigations add constraint mitigations_effectiveness_check " ..
      "check (effectiveness in ('partial', 'significant', 'full'))")
  end,
  down = function()
    schema.drop_table("mitigations")
  end
}
