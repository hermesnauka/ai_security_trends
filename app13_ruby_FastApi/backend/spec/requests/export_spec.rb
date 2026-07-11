# frozen_string_literal: true

require_relative "../spec_helper"
require "csv"

RSpec.describe "GET /api/v1/export/csv" do
  it "returns a CSV with a header row and one row per matching threat (US-18)" do
    get "/api/v1/export/csv", { frameworkCode: "OWASP_LLM" }
    expect(last_response.status).to eq(200)
    expect(last_response.headers["Content-Type"]).to eq("text/csv")
    expect(last_response.headers["Content-Disposition"]).to include("threats.csv")

    rows = CSV.parse(last_response.body, headers: true)
    expect(rows.headers).to eq(%w[code frameworkCode title severity category])
    expect(rows.size).to eq(10) # all 10 OWASP_LLM threats
    expect(rows.map { |r| r["frameworkCode"] }.uniq).to eq(["OWASP_LLM"])
  end

  it "exports every threat when no filter is given" do
    get "/api/v1/export/csv"
    rows = CSV.parse(last_response.body, headers: true)
    expect(rows.size).to eq(20)
  end
end
