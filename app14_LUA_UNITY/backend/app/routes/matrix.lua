local db = require("lapis.db")

-- FR-15/US-04: cross-framework mapping — which Cornucopia LLM cards
-- correspond to which OWASP LLM Top 10 threats, via curated owasp_refs.
-- Threats with no matching card return an empty cardIds list, not omitted
-- (matches app13_ruby_FastApi's US-04 acceptance criteria).
return function(app)
  app:get("/api/v1/matrix/llm", function(self)
    local threats = db.select("code from threats where framework_code = 'OWASP_LLM' order by code")
    local cards = db.select("card_id, owasp_refs, mitre_refs from cards where edition = 'companion'")

    local rows = {}
    for _, threat in ipairs(threats) do
      local card_ids = {}
      for _, card in ipairs(cards) do
        for _, ref in ipairs(card.owasp_refs or {}) do
          if ref == threat.code then
            table.insert(card_ids, card.card_id)
            break
          end
        end
      end
      table.insert(rows, { threatCode = threat.code, cardIds = card_ids })
    end

    return { json = { rows = rows } }
  end)

  -- US-06/PLAN.md §7: a simplified per-suit-code card count over the STRIDE
  -- (eop) deck, not the "per system component" coverage the aspirational
  -- vision describes — the same honest scope every sibling's stride-heatmap
  -- states. `cards` has no `stride` column of its own (only `threats` does);
  -- this counts cards by their raw Cornucopia 2-letter suit_code directly
  -- rather than remapping to single-letter STRIDE, since a single suit_code
  -- (e.g. "EP") already corresponds 1:1 to one STRIDE category here.
  app:get("/api/v1/matrix/stride-heatmap", function(self)
    local rows = db.select(
      "suit_code, count(*) as card_count from cards where edition = 'eop' group by suit_code order by suit_code"
    )
    return { json = { categories = rows } }
  end)
end
