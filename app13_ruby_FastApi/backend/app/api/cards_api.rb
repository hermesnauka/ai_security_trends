# frozen_string_literal: true

module RubyGuard
  module API
    class CardsAPI < Grape::API
      resource :cards do
        desc "Cards, filterable by suit or edition"
        params do
          optional :suit, type: String
          optional :edition, type: String
        end
        get do
          dataset = Card.dataset
          dataset = dataset.where(suit_code: params[:suit].upcase) if params[:suit]
          dataset = dataset.where(edition: params[:edition]) if params[:edition]

          present dataset.order(:suit_code, :value).all, with: CardEntity
        end

        params do
          requires :card_id, type: String
        end
        get ":card_id" do
          card = Card[params[:card_id]]
          error!({ timestamp: Time.now.iso8601, status: 404, error: "Not Found", message: "No such card" }, 404) unless card

          present card, with: CardEntity
        end
      end
    end
  end
end
