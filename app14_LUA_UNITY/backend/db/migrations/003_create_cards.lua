local schema = require("lapis.db.schema")
local types = schema.types
local db = require("lapis.db")

-- D-03/§4: card_kind has no compiler-enforced sum type in Lua (no ADTs, no
-- interfaces at all) — the CHECK constraint below is the ONLY guarantee that
-- a design_harm row never carries a severity. See PLAN.md D-03.
return {
  up = function()
    schema.create_table("cards", {
      { "card_id", types.varchar({ primary_key = true }) },
      { "suit_code", types.varchar({ null = false }) },
      { "suit_name", types.varchar({ null = false }) },
      { "edition", types.varchar({ null = false }) },
      { "value", types.varchar({ null = false }) },
      { "card_kind", types.varchar({ null = false, default = "technical_threat" }) },
      { "severity", types.varchar({ null = true }) },
      { "description_en", types.text({ null = false }) },
      { "description_pl", types.text({ null = false, default = "" }) },
      { "misc_note", types.text({ null = false, default = "" }) },
      { "source_url", types.varchar({ null = false, default = "" }) },
      { "owasp_refs", "text[] not null default '{}'" },
      { "mitre_refs", "text[] not null default '{}'" },
      { "content_sha256", types.varchar({ null = false }) },
      { "is_critical", types.boolean({ null = false, default = false }) }
    })

    db.query("alter table cards add constraint cards_kind_check " ..
      "check (card_kind in ('technical_threat', 'design_harm'))")
    db.query("alter table cards add constraint cards_design_harm_severity_check " ..
      "check ((card_kind = 'design_harm' and severity is null) or " ..
      "(card_kind = 'technical_threat' and severity is not null))")
    db.query("create index cards_edition_idx on cards (edition)")
    db.query("create index cards_suit_code_idx on cards (suit_code)")
  end,
  down = function()
    schema.drop_table("cards")
  end
}
