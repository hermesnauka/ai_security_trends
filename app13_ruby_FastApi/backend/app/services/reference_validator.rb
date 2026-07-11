# frozen_string_literal: true

require "json"
require_relative "card_decode_error"

# SR-07-equivalent: owasp_refs/mitre_refs values are validated against
# bundled allowlist files before any card row is written to Postgres — the
# same guard every sibling's ReferenceValidator provides, since every one of
# these values is curated content (PLAN.md §0.1), never extracted from the
# raw YAML.
class ReferenceValidator
  def initialize(seeds_root:)
    @owasp_allowlist = load_allowlist(File.join(seeds_root, "ref-allowlists.json"), "owasp_refs")
    @mitre_allowlist = load_allowlist(File.join(seeds_root, "mitre-atlas-allowlist.json"), "mitre_refs")
  end

  def assert_owasp_refs_valid!(refs, card_id)
    refs.each do |ref|
      raise CardDecodeError::UnknownReference.new(ref, "owasp_refs", card_id) unless @owasp_allowlist.include?(ref)
    end
  end

  def assert_mitre_refs_valid!(refs, card_id)
    refs.each do |ref|
      raise CardDecodeError::UnknownReference.new(ref, "mitre_refs", card_id) unless @mitre_allowlist.include?(ref)
    end
  end

  private

  def load_allowlist(path, key)
    return Set.new unless File.exist?(path)

    JSON.parse(File.read(path))[key].to_a.to_set
  end
end
