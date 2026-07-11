# frozen_string_literal: true

module RubyGuard
  module API
    class SearchAPI < Grape::API
      # FR-17.1-equivalent: a plain `ILIKE '%text%'` scan, not Postgres full-
      # text search (`tsvector`/`tsquery`) — PLAN.md §6 Phase 5 states a
      # dedicated FTS index would be added if relevance needs improve,
      # mirroring every sibling's own plain-CONTAINS search note.
      resource :search do
        params do
          requires :q, type: String
          optional :locale, type: String, values: %w[pl en], default: "pl"
        end
        get do
          like = "%#{params[:q]}%"

          threat_results = Threat.where(Sequel.ilike(:title, like) | Sequel.ilike(:description_en, like)).all.map do |t|
            {
              code: t.code,
              title: t.title,
              excerpt: excerpt(t.localized_description(params[:locale]), params[:q]),
              kind: "threat"
            }
          end

          card_results = Card.where(Sequel.ilike(:description_en, like) | Sequel.ilike(:description_pl, like)).all.map do |c|
            {
              code: c.card_id,
              title: c.card_id,
              excerpt: excerpt(c.localized_description(params[:locale]), params[:q]),
              kind: "card"
            }
          end

          threat_results + card_results
        end
      end

      helpers do
        def excerpt(text, term, context_chars: 80)
          index = text.downcase.index(term.downcase)
          return text[0, context_chars * 2] unless index

          start_index = [index - context_chars, 0].max
          end_index = [index + term.length + context_chars, text.length].min
          text[start_index...end_index]
        end
      end
    end
  end
end
