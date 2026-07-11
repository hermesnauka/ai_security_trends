# frozen_string_literal: true

require_relative "../spec_helper"
require "base64"

RSpec.describe JwtService do
  it "round-trips a token: encodes then decodes back the same claims" do
    token = described_class.encode(username: "admin", role: "ADMIN")
    decoded = described_class.decode(token)

    expect(decoded["sub"]).to eq("admin")
    expect(decoded["role"]).to eq("ADMIN")
    expect(decoded["exp"]).to be > decoded["iat"]
  end

  it "returns nil for a garbage token instead of raising" do
    expect(described_class.decode("not-a-real-jwt")).to be_nil
  end

  it "returns nil for a token signed with a different secret" do
    forged = JWT.encode({ sub: "admin", role: "ADMIN", iat: Time.now.to_i, exp: Time.now.to_i + 3600 },
                         "a-completely-different-secret", "HS256")
    expect(described_class.decode(forged)).to be_nil
  end

  it "returns nil for an already-expired token" do
    expired = described_class.encode(username: "admin", role: "ADMIN", expires_in: -10)
    expect(described_class.decode(expired)).to be_nil
  end

  it "rejects a token whose payload was tampered with after signing" do
    token = described_class.encode(username: "admin", role: "ADMIN")
    header, payload, signature = token.split(".")
    tampered_payload = Base64.urlsafe_encode64({ sub: "admin", role: "SUPERADMIN" }.to_json, padding: false)
    expect(described_class.decode([header, tampered_payload, signature].join("."))).to be_nil
  end
end
