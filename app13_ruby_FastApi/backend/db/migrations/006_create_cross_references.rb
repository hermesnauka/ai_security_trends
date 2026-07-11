# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:cross_references) do
      primary_key :id
      foreign_key :source_threat_code, :threats, key: :code, type: String, null: false
      String :target_threat_code, null: false
      String :target_threat_title, null: false
      String :relationship_type, null: false
      String :description, text: true, null: false

      constraint(:cross_references_relationship_type_check) do
        Sequel.lit("relationship_type IN ('equivalent', 'related', 'parent_child', 'maps_to')")
      end

      index :source_threat_code
      index %i[source_threat_code target_threat_code], unique: true, name: :cross_references_unique_pair
    end
  end
end
