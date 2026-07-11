# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "GET /api/v1/mitigations/:threat_code" do
  it "returns the mitigation for a threat, with all 5 code samples' languages (US-03)" do
    get "/api/v1/mitigations/A03:2021"
    body = JSON.parse(last_response.body)
    expect(body.map { |m| m["slug"] }).to include("sql-injection-prevention")

    mitigation = body.find { |m| m["slug"] == "sql-injection-prevention" }
    languages = mitigation["codeSamples"].map { |s| s["language"] }.uniq.sort
    expect(languages).to eq(%w[go java lua python scala])
  end

  it "returns an empty array for a threat with no seeded mitigation" do
    get "/api/v1/mitigations/LLM08:2025"
    expect(JSON.parse(last_response.body)).to eq([])
  end
end
