# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Card do
  # US-19/D-03: a design_harm row's severity is enforced NULL by a database
  # CHECK constraint — not merely an application-level convention.
  it "never allows a design_harm row to carry a severity" do
    expect do
      DB[:cards].insert(
        card_id: "TEST_DESIGN_HARM_WITH_SEVERITY", suit_code: "TS", suit_name: "Test",
        edition: "test", value: "2", card_kind: "design_harm", severity: "high",
        description_en: "x", content_sha256: "x", is_critical: false
      )
    end.to raise_error(Sequel::CheckConstraintViolation)
  end

  it "never allows a technical_threat row to have a NULL severity" do
    expect do
      DB[:cards].insert(
        card_id: "TEST_TECH_THREAT_NO_SEVERITY", suit_code: "TS", suit_name: "Test",
        edition: "test", value: "2", card_kind: "technical_threat", severity: nil,
        description_en: "x", content_sha256: "x", is_critical: false
      )
    end.to raise_error(Sequel::CheckConstraintViolation)
  end

  it "severity_or_nil is always nil for a design_harm card, regardless of the column" do
    dbd_card = Card.where(edition: "dbd").first
    expect(dbd_card.severity_or_nil).to be_nil
    expect(dbd_card.design_harm?).to be true
  end
end
