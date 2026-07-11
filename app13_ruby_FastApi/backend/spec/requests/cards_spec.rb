# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "GET /api/v1/cards" do
  it "filters by suit (US-06)" do
    get "/api/v1/cards", { suit: "LLM" }
    body = JSON.parse(last_response.body)
    expect(body.map { |c| c["cardId"] }.sort).to eq(%w[LLM2 LLM3 LLM4])
    expect(body).to all(include("suitCode" => "LLM"))
  end

  it "filters by edition, and every dbd card is a design_harm with a null severity (US-19/D-03)" do
    get "/api/v1/cards", { edition: "dbd" }
    body = JSON.parse(last_response.body)
    expect(body).not_to be_empty
    expect(body).to all(include("cardKind" => "design_harm", "severity" => nil))
  end

  it "returns a single card's detail" do
    get "/api/v1/cards/LLM2"
    body = JSON.parse(last_response.body)
    expect(body["cardId"]).to eq("LLM2")
    expect(body["owaspRefs"]).to include("LLM10:2025")
  end

  it "404s for an unknown card id" do
    get "/api/v1/cards/DOES_NOT_EXIST"
    expect(last_response.status).to eq(404)
  end
end
