# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "GET /api/v1/search" do
  it "finds a threat by title substring, case-insensitively (US-17)" do
    get "/api/v1/search", { q: "injection" }
    results = JSON.parse(last_response.body)
    expect(results).to include(a_hash_including("code" => "A03:2021"))
    expect(results).to include(a_hash_including("code" => "LLM01:2025"))
  end

  it "finds a card by description substring" do
    get "/api/v1/search", { q: "computational" }
    results = JSON.parse(last_response.body)
    expect(results).to include(a_hash_including("code" => "LLM2", "kind" => "card"))
  end

  it "returns no results for a nonsense query" do
    get "/api/v1/search", { q: "zzzznonexistentqueryzzzz" }
    expect(JSON.parse(last_response.body)).to eq([])
  end
end
