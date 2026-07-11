# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "GET /api/v1/frameworks" do
  it "returns at least ten seeded frameworks (US-01)" do
    get "/api/v1/frameworks"
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body).size).to be >= 10
  end

  it "returns a single framework's detail" do
    get "/api/v1/frameworks/OWASP_LLM"
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)["code"]).to eq("OWASP_LLM")
  end

  it "404s for an unknown framework code" do
    get "/api/v1/frameworks/DOES_NOT_EXIST"
    expect(last_response.status).to eq(404)
  end
end
