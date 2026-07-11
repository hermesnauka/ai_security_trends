# frozen_string_literal: true

require "json"

# The single entry point tying every seed step together — mirrors app09's
# Seed_Loader + Card_Ingestion_Service + Mitigation_Seed_Loader, and app11/
# app12's ContentSeeder. Idempotent: safe to call on every deploy, upserting
# rather than duplicating.
class ContentSeeder
  def initialize(seeds_root:)
    @seeds_root = seeds_root
    @reference_validator = ReferenceValidator.new(seeds_root: seeds_root)
    @card_loader = CardFileLoader.new(reference_validator: @reference_validator, seeds_root: seeds_root)
    @integrity_checker = IntegrityChecker.new(seeds_root: seeds_root)
  end

  def seed!
    seed_frameworks
    seed_threats
    seed_threat_translations
    seed_cross_references
    seed_cards
    seed_mitigations_and_code_samples
    @integrity_checker.verify!
  end

  private

  def read_json(name)
    path = File.join(@seeds_root, name)
    return nil unless File.exist?(path)

    JSON.parse(File.read(path))
  end

  def seed_frameworks
    (read_json("frameworks.json") || []).each do |seed|
      Framework.dataset.insert_conflict(
        target: :code,
        update: { name: seed["name"], version: seed["version"], description: seed["description"], reference_url: seed["referenceUrl"] }
      ).insert(
        code: seed["code"], name: seed["name"], version: seed["version"],
        description: seed["description"], reference_url: seed["referenceUrl"]
      )
    end
  end

  def seed_threats
    (read_json("threats_seed.json") || []).each do |seed|
      next if Threat[seed["code"]] # threats are seeded once; edits happen via translations, not re-seeding
      next unless Framework[seed["frameworkCode"]]

      Threat.create(
        code: seed["code"],
        framework_code: seed["frameworkCode"],
        title: seed["title"],
        severity: seed["severity"],
        category: seed["category"],
        description_en: seed["description"],
        description_pl: seed["description"], # overwritten by seed_threat_translations if a 'pl' row exists
        attack_vector: seed["attack_vector"],
        attack_surface: seed["attack_surface"],
        stride: Sequel.pg_array(stride_categories(seed["stride"])),
        tags: Sequel.pg_array(seed["tags"] || [])
      )
    end
  end

  # Seed data stores STRIDE as the Cornucopia 2-letter suit code (SP, TA, RE,
  # ID, DS, EP), matching every sibling's convention — mapped here to the
  # single-letter STRIDE categories this app's own filter/heatmap use.
  def stride_categories(suit_code)
    mapping = { "SP" => "S", "TA" => "T", "RE" => "R", "ID" => "I", "DS" => "D", "EP" => "E" }
    [mapping[suit_code]].compact
  end

  def seed_threat_translations
    (read_json("threat_translations_seed.json") || []).select { |t| t["locale"] == "pl" }.each do |seed|
      threat = Threat[seed["code"]]
      next unless threat

      threat.update(description_pl: seed["description"])
    end
  end

  def seed_cross_references
    (read_json("cross_references_seed.json") || []).each do |seed|
      target = Threat[seed["targetCode"]]
      next unless target
      next if CrossReference.where(source_threat_code: seed["sourceCode"], target_threat_code: seed["targetCode"]).any?

      CrossReference.create(
        source_threat_code: seed["sourceCode"],
        target_threat_code: seed["targetCode"],
        target_threat_title: target.title,
        relationship_type: seed["relationshipType"],
        description: seed["description"]
      )
    end
  end

  def seed_cards
    @card_loader.load_all.each do |seed|
      row = {
        card_id: seed.card_id, suit_code: seed.suit_code, suit_name: seed.suit_name,
        edition: seed.edition, value: seed.value, card_kind: seed.card_kind, severity: seed.severity,
        description_en: seed.description_en, description_pl: seed.description_pl,
        misc_note: seed.misc_note, source_url: seed.source_url,
        owasp_refs: Sequel.pg_array(seed.owasp_refs), mitre_refs: Sequel.pg_array(seed.mitre_refs),
        content_sha256: seed.content_sha256, is_critical: seed.is_critical
      }
      Card.dataset.insert_conflict(target: :card_id, update: row).insert(row)
    end
  end

  def seed_mitigations_and_code_samples
    mitigation_seeds = read_json("mitigations_seed.json") || []
    mitigation_seeds.each do |seed|
      row = {
        slug: seed["slug"], threat_code: seed["threatCode"], card_id: seed["cardId"],
        title: seed["title"], description: seed["description"],
        mitigation_type: seed["mitigationType"], effort: seed["effort"], effectiveness: seed["effectiveness"]
      }
      Mitigation.dataset.insert_conflict(target: :slug, update: row).insert(row)
    end

    manifest = read_json("code_samples_manifest.json") || []
    manifest.each do |entry|
      next unless Mitigation[entry["mitigationSlug"]]
      next if CodeSample.where(mitigation_slug: entry["mitigationSlug"], language: entry["language"], sample_type: entry["sampleType"]).any?

      code_path = File.join(@seeds_root, "code_samples", entry["file"])
      next unless File.exist?(code_path)

      CodeSample.create(
        mitigation_slug: entry["mitigationSlug"],
        language: entry["language"],
        sample_type: entry["sampleType"],
        title: entry["title"],
        description: entry["description"],
        code: File.read(code_path),
        framework_hint: entry["frameworkHint"],
        version_note: entry["versionNote"]
      )
    end
  end
end
