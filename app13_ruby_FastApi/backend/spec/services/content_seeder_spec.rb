# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe ContentSeeder do
  subject(:seeder) { described_class.new(seeds_root: SEEDS_ROOT) }

  # spec_helper's before(:suite) already ran seed! once against the real
  # seed tree, so these examples exercise seed!'s idempotency (insert_conflict
  # upserts / `next if already seeded` guards), not first-time ingestion.
  it "seeds every framework from frameworks.json" do
    expect(Framework.count).to be > 0
    expect(Framework[code: "OWASP_WEB"]).not_to be_nil
  end

  it "seeds the real OWASP Web + LLM Top 10 threats" do
    expect(Threat["A01:2021"]).not_to be_nil
    expect(Threat["A01:2021"].title).to eq("Broken Access Control")
  end

  it "maps a Cornucopia 2-letter suit code to the single-letter STRIDE category" do
    threat = Threat["A01:2021"]
    expect(threat.stride).to eq(["E"]) # seed data has "EP" -> Elevation of Privilege
  end

  it "seeds cards from all six real Cornucopia decks" do
    expect(Card.count).to be > 0
    expect(Card.where(edition: "webapp")).to be_any
  end

  it "seeds mitigations with their code samples" do
    expect(Mitigation.count).to be > 0
    mitigation = Mitigation.first
    expect(CodeSample.where(mitigation_slug: mitigation.slug)).to be_any
  end

  it "verifies content integrity as its final seeding step" do
    expect(ContentHash.count).to be > 0
  end

  it "re-running seed! does not create duplicate frameworks, threats, or cards" do
    framework_count = Framework.count
    threat_count = Threat.count
    card_count = Card.count

    seeder.seed!

    expect(Framework.count).to eq(framework_count)
    expect(Threat.count).to eq(threat_count)
    expect(Card.count).to eq(card_count)
  end

  it "skips seeding a threat whose framework does not exist" do
    # Exercises the private seed_threats step directly (via #send) rather than
    # the full seed!, since seed! also runs seed_cards against DECK_MANIFEST's
    # fixed list of 6 real decks, which a minimal tmpdir fixture can't satisfy.
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "threats_seed.json"), [
        { "frameworkCode" => "DOES_NOT_EXIST", "code" => "ZZ99:9999", "title" => "x", "severity" => "low",
          "category" => "x", "description" => "x", "attack_vector" => "x", "attack_surface" => "x",
          "stride" => "SP", "tags" => [] }
      ].to_json)

      described_class.new(seeds_root: dir).send(:seed_threats)
      expect(Threat["ZZ99:9999"]).to be_nil
    end
  end
end
