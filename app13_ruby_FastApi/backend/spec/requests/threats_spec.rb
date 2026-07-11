# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "GET /api/v1/threats" do
  it "combines framework and severity filters (US-02)" do
    get "/api/v1/threats", { frameworkCode: "OWASP_LLM", severity: "critical" }
    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body["content"]).not_to be_empty
    expect(body["content"]).to all(include("frameworkCode" => "OWASP_LLM", "severity" => "critical"))
  end

  it "returns every seeded threat with no filters, in the Page<T> envelope shape" do
    get "/api/v1/threats", { size: 50 }
    body = JSON.parse(last_response.body)
    expect(body).to include("content", "totalElements", "totalPages", "number", "size")
    expect(body["totalElements"]).to eq(20)
  end

  it "returns a threat's full detail including mitigations and cross-references" do
    get "/api/v1/threats/A03:2021"
    body = JSON.parse(last_response.body)
    expect(body["title"]).to eq("Injection")
    expect(body["mitigations"].map { |m| m["slug"] }).to include("sql-injection-prevention")
  end

  it "404s for an unknown threat code" do
    get "/api/v1/threats/DOES_NOT_EXIST"
    expect(last_response.status).to eq(404)
  end
end
