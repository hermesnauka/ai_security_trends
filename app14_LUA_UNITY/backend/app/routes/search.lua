local db = require("lapis.db")

-- FR-09: a plain ILIKE query, not a full-text index — the same honest scope
-- every sibling's own plain-CONTAINS search states (PLAN.md §7).
return function(app)
  app:get("/api/v1/search", function(self)
    local q = self.params.q
    if not q or q == "" then
      return { json = {} }
    end

    local like = "%" .. q .. "%"

    local threats = db.select(
      "code, title, severity, framework_code from threats where title ilike ? or description_en ilike ? order by code",
      like, like
    )
    local cards = db.select(
      "card_id, description_en, suit_code from cards where description_en ilike ? order by card_id",
      like
    )

    local results = {}
    for _, t in ipairs(threats) do
      table.insert(results, {
        kind = "threat", code = t.code, title = t.title,
        severity = t.severity, frameworkCode = t.framework_code
      })
    end
    for _, c in ipairs(cards) do
      table.insert(results, {
        kind = "card", cardId = c.card_id, description = c.description_en, suitCode = c.suit_code
      })
    end

    return { json = results }
  end)
end
