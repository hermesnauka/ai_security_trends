# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Threat do
  describe "#localized_description" do
    it "returns the Polish description when one has been seeded" do
      threat = Threat.create(
        code: "TEST:PL", framework_code: "OWASP_WEB", title: "Test", severity: "low", category: "Test",
        description_en: "English text", description_pl: "Polski tekst"
      )
      expect(threat.localized_description("pl")).to eq("Polski tekst")
    end

    it "falls back to English when no Polish translation exists yet (FR-18.6)" do
      threat = Threat.create(
        code: "TEST:NOPL", framework_code: "OWASP_WEB", title: "Test", severity: "low", category: "Test",
        description_en: "English text", description_pl: ""
      )
      expect(threat.localized_description("pl")).to eq("English text")
    end

    it "returns the English description for any non-pl locale" do
      threat = Threat.create(
        code: "TEST:EN", framework_code: "OWASP_WEB", title: "Test", severity: "low", category: "Test",
        description_en: "English text", description_pl: "Polski tekst"
      )
      expect(threat.localized_description("en")).to eq("English text")
    end
  end

  it "belongs to its framework" do
    threat = Threat["A01:2021"]
    expect(threat.framework.code).to eq("OWASP_WEB")
  end

  it "has many mitigations keyed by threat_code" do
    mitigation = Mitigation.first
    threat = Threat[mitigation.threat_code]
    expect(threat.mitigations.map(&:slug)).to include(mitigation.slug)
  end

  # D-03-equivalent for threats: severity is constrained to the same five
  # levels the API filters/sorts on.
  it "never allows a severity outside the five known levels" do
    expect do
      Threat.create(
        code: "TEST:BADSEV", framework_code: "OWASP_WEB", title: "Test",
        severity: "catastrophic", category: "Test", description_en: "x"
      )
    end.to raise_error(Sequel::CheckConstraintViolation)
  end

  it "never allows a threat referencing an unknown framework code" do
    expect do
      Threat.create(
        code: "TEST:BADFW", framework_code: "DOES_NOT_EXIST", title: "Test",
        severity: "low", category: "Test", description_en: "x"
      )
    end.to raise_error(Sequel::ForeignKeyConstraintViolation)
  end
end
