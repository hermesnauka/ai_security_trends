# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe CardFileLoader do
  let(:reference_validator) { ReferenceValidator.new(seeds_root: SEEDS_ROOT) }
  let(:loader) { described_class.new(reference_validator: reference_validator, seeds_root: SEEDS_ROOT) }

  # Regression test: the real `webapp` deck has 80 raw cards but only a
  # representative 14 are curated — loading it must succeed and silently
  # skip every uncurated card, NOT raise. This mirrors the exact bug found
  # and fixed in app11_swift_ios's and app12_kotlin_android's equivalent
  # loaders while writing their test suites: `build_seed` used to raise
  # MissingCuratedSeverity for ANY card with no curation entry at all,
  # rather than only for a curated-but-malformed entry.
  it "loads the real webapp deck, skipping uncurated cards instead of raising" do
    entry = CardFileLoader::DECK_MANIFEST.find { |e| e[:edition] == "webapp" }
    seeds = loader.load_deck(entry)

    expect(seeds).not_to be_empty
    expect(seeds.size).to be < 80
    expect(seeds.map(&:card_id)).to include("VE3")
  end

  it "loads all six real decks successfully" do
    seeds = loader.load_all
    expect(seeds.map(&:edition).uniq.sort).to eq(%w[companion dbd eop mlsec mobileapp webapp])
  end

  it "marks every dbd card as design_harm" do
    entry = CardFileLoader::DECK_MANIFEST.find { |e| e[:design_harm] }
    seeds = loader.load_deck(entry)
    expect(seeds).not_to be_empty
    expect(seeds).to all(have_attributes(card_kind: "design_harm", severity: nil))
  end

  it "raises MissingCuratedSeverity for a curated-but-malformed severity entry" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "cornucopia"))
      File.write(File.join(dir, "cornucopia", "fixture-deck.yaml"), <<~YAML)
        meta:
          edition: "fixture"
          component: "cards"
          language: "en"
          version: "1.0"
        suits:
        -
          id: "FX"
          name: "Fixture"
          cards:
          -
            id: "FX1"
            value: "2"
            desc: "A fixture card."
      YAML
      File.write(File.join(dir, "cornucopia", "fixture.curation.json"), '{ "FX1": { "severity": "", "owasp_refs": [], "mitre_refs": [] } }')
      File.write(File.join(dir, "ref-allowlists.json"), '{ "owasp_refs": [] }')
      File.write(File.join(dir, "mitre-atlas-allowlist.json"), '{ "mitre_refs": [] }')

      fixture_validator = ReferenceValidator.new(seeds_root: dir)
      fixture_loader = described_class.new(reference_validator: fixture_validator, seeds_root: dir)
      entry = { yaml_file_name: "fixture-deck", curation_file_name: "fixture.curation", edition: "fixture", design_harm: false }

      expect { fixture_loader.load_deck(entry) }.to raise_error(CardDecodeError::MissingCuratedSeverity)
    end
  end

  it "rejects a YAML file with an unrecognized top-level key (D-06)" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "cornucopia"))
      File.write(File.join(dir, "cornucopia", "fixture-deck.yaml"), <<~YAML)
        meta:
          edition: "fixture"
          component: "cards"
          language: "en"
          version: "1.0"
        suits: []
        extra_top_level_key: "evil"
      YAML

      fixture_loader = described_class.new(reference_validator: reference_validator, seeds_root: dir)
      entry = { yaml_file_name: "fixture-deck", curation_file_name: "fixture.curation", edition: "fixture", design_harm: false }

      expect { fixture_loader.load_deck(entry) }.to raise_error(CardDecodeError::UnrecognizedFields)
    end
  end
end
