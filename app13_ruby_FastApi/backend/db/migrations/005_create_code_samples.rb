# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:code_samples) do
      primary_key :id
      foreign_key :mitigation_slug, :mitigations, key: :slug, type: String, null: false
      String :language, null: false
      String :sample_type, null: false
      String :title, null: false
      String :description, text: true, null: false
      String :code, text: true, null: false
      String :framework_hint, null: false, default: ""
      String :version_note, null: false, default: ""

      constraint(:code_samples_language_check) do
        Sequel.lit("language IN ('python', 'java', 'go', 'scala', 'lua')")
      end
      constraint(:code_samples_sample_type_check) do
        Sequel.lit("sample_type IN ('attack_demo', 'defense')")
      end

      index %i[mitigation_slug language sample_type], unique: true, name: :code_samples_unique_per_mitigation_lang_type
    end
  end
end
