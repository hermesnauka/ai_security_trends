local db = require("lapis.db")

local function card_entity(c)
  return {
    cardId = c.card_id,
    suitCode = c.suit_code,
    suitName = c.suit_name,
    edition = c.edition,
    value = c.value,
    cardKind = c.card_kind,
    severity = c.severity, -- always nil for design_harm rows, enforced by the DB CHECK constraint (D-03)
    descriptionEn = c.description_en,
    descriptionPl = c.description_pl,
    miscNote = c.misc_note,
    sourceUrl = c.source_url,
    owaspRefs = c.owasp_refs,
    mitreRefs = c.mitre_refs,
    isCritical = c.is_critical
  }
end

-- Phase 2 (PLAN.md §6/§7): a `suit`/`edition` param delegates to cards
-- instead of a parallel unified-listing endpoint, matching the pattern
-- app09_php_WORDPRESS's PLAN.md §7 calls for.
return function(app)
  app:get("/api/v1/cards", function(self)
    local p = self.params
    local conditions = {}

    if p.suitCode then
      table.insert(conditions, "suit_code = " .. db.escape_literal(p.suitCode))
    end
    if p.edition then
      table.insert(conditions, "edition = " .. db.escape_literal(p.edition))
    end

    local where_clause = ""
    if #conditions > 0 then
      where_clause = "where " .. table.concat(conditions, " and ")
    end

    local rows = db.select("* from cards " .. where_clause .. " order by card_id")
    local content = {}
    for _, row in ipairs(rows) do table.insert(content, card_entity(row)) end
    return { json = content }
  end)

  app:get("/api/v1/cards/:card_id", function(self)
    local rows = db.select("* from cards where card_id = ? limit 1", self.params.card_id)
    if not rows[1] then
      return {
        status = 404,
        json = {
          timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
          status = 404,
          error = "Not Found",
          message = "No such card"
        }
      }
    end
    return { json = card_entity(rows[1]) }
  end)
end
