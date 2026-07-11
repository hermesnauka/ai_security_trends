# frozen_string_literal: true

require_relative "../spec_helper"
require "rantly"
require "rantly/rspec_extensions"

# PLAN.md §10: "completeness is verified by an rantly-based property test
# over the seeded dataset, not a type-level guarantee — Ruby has no
# NonEmpty/exhaustive-coverage collection type." Mirrors app11_swift_ios's
# SwiftCheck-based and app12_kotlin_android's Kotest-based equivalents.
RSpec.describe "code sample completeness" do
  it "every seeded mitigation has all five languages" do
    slugs = Mitigation.all.map(&:slug)
    expect(slugs).not_to be_empty

    property_of { choose(*slugs) }.check do |slug|
      languages = CodeSample.where(mitigation_slug: slug).select_map(:language).uniq.sort
      expect(languages).to eq(%w[go java lua python scala])
    end
  end

  it "every mitigation has both an attack_demo and a defense sample per language" do
    slugs = Mitigation.all.map(&:slug)

    property_of { choose(*slugs) }.check do |slug|
      samples = CodeSample.where(mitigation_slug: slug).all
      %w[python java go scala lua].each do |language|
        for_language = samples.select { |s| s.language == language }
        expect(for_language.map(&:sample_type)).to include("attack_demo", "defense")
      end
    end
  end
end
