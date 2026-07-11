# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:content_hashes) do
      String :file_name, primary_key: true
      String :sha256_hash, null: false
      Time :verified_at, null: false
      TrueClass :is_valid, null: false
      String :verified_by, null: false, default: "rubyguard-integrity-checker"
    end
  end
end
