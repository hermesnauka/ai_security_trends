# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe IntegrityChecker do
  it "verifies every real Cornucopia deck against its recorded SHA-256 hash" do
    results = described_class.new(seeds_root: SEEDS_ROOT).verify!

    expect(results).not_to be_empty
    expect(results.values).to all(be true)
  end

  it "records a row in content_hashes for every verified file" do
    described_class.new(seeds_root: SEEDS_ROOT).verify!

    hashes = JSON.parse(File.read(File.join(SEEDS_ROOT, "hashes.json")))
    hashes.each_key do |file_name|
      row = ContentHash[file_name]
      expect(row).not_to be_nil
      expect(row.is_valid).to be true
    end
  end

  it "all_valid? is true for the real seed tree" do
    expect(described_class.new(seeds_root: SEEDS_ROOT).all_valid?).to be true
  end

  it "flags a deck file as invalid when its content no longer matches the recorded hash" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "cornucopia"))
      File.write(File.join(dir, "cornucopia", "tampered-deck.yaml"), "tampered contents")
      File.write(File.join(dir, "hashes.json"), { "tampered-deck.yaml" => Digest::SHA256.hexdigest("original contents") }.to_json)

      results = described_class.new(seeds_root: dir).verify!
      expect(results["tampered-deck.yaml"]).to be false
      expect(ContentHash["tampered-deck.yaml"].is_valid).to be false
    end
  end

  it "flags a deck file as invalid when it is missing entirely" do
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(File.join(dir, "cornucopia"))
      File.write(File.join(dir, "hashes.json"), { "does-not-exist.yaml" => "deadbeef" }.to_json)

      results = described_class.new(seeds_root: dir).verify!
      expect(results["does-not-exist.yaml"]).to be false
    end
  end

  it "returns an empty result when there is no hashes.json at all" do
    Dir.mktmpdir do |dir|
      expect(described_class.new(seeds_root: dir).verify!).to eq({})
    end
  end

  it "re-running verify! updates the existing row instead of raising a primary-key violation" do
    checker = described_class.new(seeds_root: SEEDS_ROOT)
    checker.verify!
    expect { checker.verify! }.not_to raise_error
  end
end
