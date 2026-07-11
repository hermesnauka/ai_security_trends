# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "GET /health" do
  it "returns status UP, matching the shared Phase-1 contract literally" do
    get "/health"
    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq("status" => "UP")
  end
end
