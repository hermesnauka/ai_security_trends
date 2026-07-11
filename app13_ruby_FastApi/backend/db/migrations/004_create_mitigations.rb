# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:mitigations) do
      String :slug, primary_key: true
      foreign_key :threat_code, :threats, key: :code, type: String
      foreign_key :card_id, :cards, key: :card_id, type: String
      String :title, null: false
      String :description, text: true, null: false
      String :mitigation_type, null: false
      String :effort, null: false
      String :effectiveness, null: false

      constraint(:mitigations_type_check) do
        Sequel.lit("mitigation_type IN ('preventive', 'detective', 'corrective', 'compensating')")
      end
      constraint(:mitigations_effort_check) { Sequel.lit("effort IN ('low', 'medium', 'high')") }
      constraint(:mitigations_effectiveness_check) do
        Sequel.lit("effectiveness IN ('partial', 'significant', 'full')")
      end
    end
  end
end
