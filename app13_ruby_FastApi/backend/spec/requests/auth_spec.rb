# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "POST /api/v1/auth/login" do
  it "returns a bearer token for the correct credentials (D-01)" do
    post "/api/v1/auth/login", { username: TEST_ADMIN_USERNAME, password: TEST_ADMIN_PASSWORD }.to_json,
         "CONTENT_TYPE" => "application/json"

    expect(last_response.status).to eq(200)
    body = JSON.parse(last_response.body)
    expect(body["tokenType"]).to eq("Bearer")
    expect(body["role"]).to eq("ADMIN")
    expect(body["token"]).not_to be_empty

    decoded = JwtService.decode(body["token"])
    expect(decoded["sub"]).to eq(TEST_ADMIN_USERNAME)
    expect(decoded["role"]).to eq("ADMIN")
  end

  it "401s for a wrong password" do
    post "/api/v1/auth/login", { username: TEST_ADMIN_USERNAME, password: "definitely-wrong" }.to_json,
         "CONTENT_TYPE" => "application/json"
    expect(last_response.status).to eq(401)
  end

  it "401s for an unknown username" do
    post "/api/v1/auth/login", { username: "does-not-exist", password: "whatever" }.to_json,
         "CONTENT_TYPE" => "application/json"
    expect(last_response.status).to eq(401)
  end

  it "400s when username is missing (D-02: Grape params validation)" do
    post "/api/v1/auth/login", { password: "whatever" }.to_json, "CONTENT_TYPE" => "application/json"
    expect(last_response.status).to eq(400)
  end

  # SR-05: throttled per source IP after 5 attempts within 60 seconds.
  it "rate-limits repeated login attempts from the same IP" do
    6.times do
      post "/api/v1/auth/login", { username: TEST_ADMIN_USERNAME, password: "wrong" }.to_json,
           "CONTENT_TYPE" => "application/json"
    end
    expect(last_response.status).to eq(429)
  end
end
