local Model = require("lapis.db.model").Model

local Card = Model:extend("cards", {
  primary_key = "card_id",

  relations = {
    { "mitigations", has_many = "Mitigation", key = "card_id" }
  },

  -- D-03: the only way to read a severity at all — mirrors
  -- app13_ruby_FastApi's Card#severity_or_nil. There is no compiler-enforced
  -- sum type in Lua (PLAN.md D-03); this method plus the DB CHECK constraint
  -- (migration 003) are the only two guarantees.
  severity_or_nil = function(self)
    if self.card_kind == "design_harm" then
      return nil
    end
    return self.severity
  end,

  design_harm = function(self)
    return self.card_kind == "design_harm"
  end,

  localized_description = function(self, locale)
    if locale == "pl" and self.description_pl and self.description_pl ~= "" then
      return self.description_pl
    end
    return self.description_en
  end
})

return Card
