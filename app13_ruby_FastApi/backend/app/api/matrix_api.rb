# frozen_string_literal: true

module RubyGuard
  module API
    class MatrixAPI < Grape::API
      resource :matrix do
        desc "LLM threats <-> Cornucopia LLM-suit cards, via curated owasp_refs"
        get "llm" do
          llm_cards = Card.where(suit_code: "LLM").all
          llm_threats = Threat.where(framework_code: "OWASP_LLM").order(:code).all

          rows = llm_threats.map do |threat|
            matching_card_ids = llm_cards.select { |c| c.owasp_refs.include?(threat.code) }.map(&:card_id)
            { threatCode: threat.code, threatTitle: threat.title, cardIds: matching_card_ids }
          end

          { rows: rows, note: nil }
        end

        desc "OWASP Agentic AI Top 10 threats <-> AAI-suit cards"
        get "agentic" do
          agentic_threats = Threat.where(framework_code: "OWASP_AGENTIC").all
          aai_cards = Card.where(suit_code: "AAI").all

          if agentic_threats.empty?
            {
              rows: [],
              note: "OWASP Agentic AI Top 10 threats are not yet seeded (requirements.md DR-01.4) — showing only the AAI suit cards."
            }
          else
            { rows: [{ threatCode: "", threatTitle: "", cardIds: aai_cards.map(&:card_id) }], note: nil }
          end
        end

        desc "Per-STRIDE-category card counts — a simplified heatmap, not per-system-component coverage"
        get "stride-heatmap" do
          suits = { "S" => "SP", "T" => "TA", "R" => "RE", "I" => "ID", "D" => "DS", "E" => "EP" }
          counts = suits.transform_values { |suit_code| Card.where(suit_code: suit_code).count }
          { categoryCounts: counts }
        end
      end
    end
  end
end
