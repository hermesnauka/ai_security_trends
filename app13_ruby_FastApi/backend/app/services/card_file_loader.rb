# frozen_string_literal: true

require "psych"
require "json"
require "set"
require "digest"
require_relative "card_decode_error"

# D-06/§0.1: decodes a deck's raw YAML (allow-list enforced, D-06), merges in
# curated severity/refs (never read from the YAML itself), and produces
# card-row hashes ready for a Sequel insert. Mirrors app09's Card_Loader,
# app11's CardLoader, app12's CardLoader.
#
# Ruby's Psych/JSON.parse are lenient by default — the opposite end of the
# spectrum from Kotlin's kotlinx.serialization or C#'s YamlDotNet, which
# reject unknown keys "for free." This class hand-checks
# `raw.keys - ALLOWED_KEYS` and raises CardDecodeError::UnrecognizedFields
# rather than relying on a strict decoder default.
class CardFileLoader
  ALLOWED_ROOT_KEYS = %w[meta suits].freeze
  ALLOWED_META_KEYS = %w[edition component language version].freeze
  ALLOWED_SUIT_KEYS = %w[id name cards sentences].freeze
  ALLOWED_CARD_KEYS = %w[id value url desc misc].freeze

  CardSeed = Struct.new(
    :card_id, :suit_code, :suit_name, :edition, :value, :card_kind, :severity,
    :description_en, :description_pl, :misc_note, :source_url,
    :owasp_refs, :mitre_refs, :content_sha256, :is_critical,
    keyword_init: true
  )

  def initialize(reference_validator:, seeds_root:)
    @reference_validator = reference_validator
    @seeds_root = seeds_root
  end

  # Loads every deck in DECK_MANIFEST, then — only once every deck's card IDs
  # are known — checks the shared pl.cards.json translations file for an
  # orphaned key, since that file isn't scoped to a single deck.
  def load_all
    all_seeds = []
    all_card_ids = Set.new

    DECK_MANIFEST.each do |entry|
      seeds = load_deck(entry)
      seeds.each { |s| all_card_ids << s.card_id }
      all_seeds.concat(seeds)
    end

    translations_path = File.join(@seeds_root, "cornucopia", "translations", "pl.cards.json")
    return all_seeds unless File.exist?(translations_path)

    translations = load_translations(translations_path)
    translations.each_key do |card_id|
      raise CardDecodeError::OrphanCurationEntry.new(card_id, "pl.cards.json") unless all_card_ids.include?(card_id)
    end

    all_seeds
  end

  def load_deck(entry)
    yaml_path = File.join(@seeds_root, "cornucopia", "#{entry[:yaml_file_name]}.yaml")
    raise CardDecodeError::MissingRequiredField, "deck file not found: #{yaml_path}" unless File.exist?(yaml_path)

    deck = Psych.safe_load(File.read(yaml_path), permitted_classes: [Symbol], aliases: true)
    assert_allowed_keys(deck.keys, ALLOWED_ROOT_KEYS, "root")
    assert_allowed_keys(deck["meta"].keys, ALLOWED_META_KEYS, "meta") if deck["meta"]

    raw_cards = extract_cards(deck["suits"] || [])
    known_ids = raw_cards.map { |c| c[:card][:id] }.to_set

    curation_path = File.join(@seeds_root, "cornucopia", "#{entry[:curation_file_name]}.json")
    curation = File.exist?(curation_path) ? load_curation(curation_path) : {}
    curation.each_key do |card_id|
      raise CardDecodeError::OrphanCurationEntry.new(card_id, entry[:curation_file_name]) unless known_ids.include?(card_id)
    end

    translations_path = File.join(@seeds_root, "cornucopia", "translations", "pl.cards.json")
    translations = File.exist?(translations_path) ? load_translations(translations_path) : {}

    raw_cards.filter_map do |entry_hash|
      build_seed(
        card: entry_hash[:card],
        suit_code: entry_hash[:suit_code],
        suit_name: entry_hash[:suit_name],
        manifest_entry: entry,
        curation_entry: curation[entry_hash[:card][:id]],
        translation: translations[entry_hash[:card][:id]]
      )
    end
  end

  private

  def extract_cards(suits)
    cards = []
    suits.each do |suit|
      assert_allowed_keys(suit.keys, ALLOWED_SUIT_KEYS, "suit")
      # The "Common"/metadata suit has no `cards` array at all — it carries
      # no threat data and is skipped, not a decode error.
      next unless suit["cards"]

      suit["cards"].each do |card|
        assert_allowed_keys(card.keys, ALLOWED_CARD_KEYS, "card")
        raise CardDecodeError::MissingRequiredField, "id/value/desc" unless card["id"] && card["value"] && card["desc"]

        cards << {
          card: { id: card["id"], value: card["value"], url: card["url"], desc: card["desc"], misc: card["misc"] },
          suit_code: suit["id"],
          suit_name: suit["name"]
        }
      end
    end
    cards
  end

  # Content-scope note (PLAN.md §0.1 / CLAUDE.md): every deck ships far more
  # raw cards than are curated (e.g. the real `webapp` deck has 80 raw cards
  # but only a representative 14 are curated). A card with NO curation entry
  # at all is silently skipped here (`nil`, filtered by `filter_map` above) —
  # that's the expected, common case, not an error. A card that DOES have a
  # curation entry but an invalid/missing `severity` is a real data bug in
  # the curation file and still raises MissingCuratedSeverity — these are two
  # different failure modes and must not be conflated, mirroring the fix made
  # to app11_swift_ios's and app12_kotlin_android's equivalent loaders.
  def build_seed(card:, suit_code:, suit_name:, manifest_entry:, curation_entry:, translation:)
    if manifest_entry[:design_harm]
      card_kind = "design_harm"
      severity = nil
    else
      return nil if curation_entry.nil?

      severity = curation_entry["severity"]
      raise CardDecodeError::MissingCuratedSeverity, card[:id] if severity.nil? || severity.empty?

      card_kind = "technical_threat"
    end

    owasp_refs = curation_entry&.dig("owasp_refs") || []
    mitre_refs = curation_entry&.dig("mitre_refs") || []
    @reference_validator.assert_owasp_refs_valid!(owasp_refs, card[:id])
    @reference_validator.assert_mitre_refs_valid!(mitre_refs, card[:id])

    description_en = card[:desc]
    description_pl = translation || description_en # FR-18.6: fall back to English, never blank

    content_sha256 = Digest::SHA256.hexdigest(
      "#{card[:id]}|#{card[:value]}|#{card[:url]}|#{description_en}|#{card[:misc]}"
    )

    CardSeed.new(
      card_id: card[:id],
      suit_code: suit_code,
      suit_name: suit_name,
      edition: manifest_entry[:edition],
      value: card[:value],
      card_kind: card_kind,
      severity: severity,
      description_en: description_en,
      description_pl: description_pl,
      misc_note: card[:misc],
      source_url: card[:url],
      owasp_refs: owasp_refs,
      mitre_refs: mitre_refs,
      content_sha256: content_sha256,
      is_critical: %w[K Q A].include?(card[:value])
    )
  end

  def assert_allowed_keys(keys, allowed, context)
    unrecognized = keys - allowed
    raise CardDecodeError::UnrecognizedFields.new(unrecognized, context) unless unrecognized.empty?
  end

  # `_comment` is a reserved top-level key holding a plain string, not a card
  # entry — filtered out before typed access, since its value shape doesn't
  # match a curation entry at all.
  def load_curation(path)
    raw = JSON.parse(File.read(path))
    raw.reject { |k, _| k == "_comment" }
  end

  def load_translations(path)
    raw = JSON.parse(File.read(path))
    raw.reject { |k, _| k == "_comment" }
  end

  # Mirrors app09/app11/app12's DeckManifestEntry.all — the six decks, their
  # curation files, and which one (`dbd`) is the design-harm deck whose
  # card_kind is forced by file identity, never read from a field.
  DECK_MANIFEST = [
    { yaml_file_name: "webapp-cards-3.0-en", curation_file_name: "webapp.curation", edition: "webapp", design_harm: false },
    { yaml_file_name: "mobileapp-cards-1.1-en", curation_file_name: "mobileapp.curation", edition: "mobileapp", design_harm: false },
    { yaml_file_name: "companion-llm-cards-1.0-en", curation_file_name: "companion.curation", edition: "companion", design_harm: false },
    { yaml_file_name: "stride-eop-cards-5.0-en", curation_file_name: "stride-eop.curation", edition: "eop", design_harm: false },
    { yaml_file_name: "mlsec-cards-1.0-en", curation_file_name: "mlsec.curation", edition: "mlsec", design_harm: false },
    { yaml_file_name: "dbd-cards-1.0-en", curation_file_name: "dbd.curation", edition: "dbd", design_harm: true }
  ].freeze
end
