# frozen_string_literal: true

require "json"
require "digest"

# Per PLAN.md §11: unlike a mobile-app sandbox, this backend runs on a server
# this team controls end to end, so this check's primary value is catching a
# bad build/deploy mistake (a corrupted or truncated seed file shipped to
# production) rather than detecting a malicious runtime tamperer.
class IntegrityChecker
  def initialize(seeds_root:)
    @seeds_root = seeds_root
  end

  # @return [Hash{String => Boolean}] file_name -> is_valid
  def verify!
    hashes_path = File.join(@seeds_root, "hashes.json")
    return {} unless File.exist?(hashes_path)

    expected = JSON.parse(File.read(hashes_path))
    results = {}

    expected.each do |file_name, expected_hash|
      deck_path = File.join(@seeds_root, "cornucopia", file_name)
      is_valid = File.exist?(deck_path) && Digest::SHA256.hexdigest(File.read(deck_path)) == expected_hash
      results[file_name] = is_valid

      # `file_name` is the primary key — Postgres `ON CONFLICT ... DO UPDATE`
      # (Sequel's `insert_conflict`) so a re-run (e.g. a future periodic
      # re-verification job) updates the existing row rather than violating
      # the primary-key constraint.
      row = { file_name: file_name, sha256_hash: expected_hash, verified_at: Time.now, is_valid: is_valid }
      ContentHash.dataset.insert_conflict(target: :file_name, update: row).insert(row)
    end

    results
  end

  def all_valid?
    verify!.values.all?
  end
end
