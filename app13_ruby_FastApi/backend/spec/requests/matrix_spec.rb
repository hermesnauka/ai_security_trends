# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "GET /api/v1/matrix/llm" do
  it "maps LLM10:2025 to card LLM2 via curated owasp_refs (US-04/US-06)" do
    get "/api/v1/matrix/llm"
    body = JSON.parse(last_response.body)
    expect(body["rows"].size).to eq(10)

    row = body["rows"].find { |r| r["threatCode"] == "LLM10:2025" }
    expect(row["cardIds"]).to include("LLM2")
  end
end

RSpec.describe "GET /api/v1/matrix/agentic" do
  it "reports its own incompleteness when no Agentic AI threats are seeded (DR-01.4)" do
    get "/api/v1/matrix/agentic"
    body = JSON.parse(last_response.body)
    expect(body["rows"]).to eq([])
    expect(body["note"]).not_to be_nil
  end
end

RSpec.describe "GET /api/v1/matrix/stride-heatmap" do
  it "counts cards per STRIDE category" do
    get "/api/v1/matrix/stride-heatmap"
    body = JSON.parse(last_response.body)
    expect(body["categoryCounts"].keys.sort).to eq(%w[D E I R S T])
  end
end
