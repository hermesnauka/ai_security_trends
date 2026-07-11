# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:threats) do
      String :code, primary_key: true
      foreign_key :framework_code, :frameworks, key: :code, type: String, null: false
      String :title, null: false
      String :severity, null: false
      String :category, null: false
      String :description_en, text: true, null: false
      String :description_pl, text: true, null: false, default: ""
      String :attack_vector, text: true, null: false, default: ""
      String :attack_surface, text: true, null: false, default: ""
      column :stride, "text[]", null: false, default: Sequel.lit("'{}'")
      column :tags, "text[]", null: false, default: Sequel.lit("'{}'")

      constraint(:threats_severity_check) do
        Sequel.lit("severity IN ('critical', 'high', 'medium', 'low', 'info')")
      end

      index :framework_code
      index :severity
    end
  end
end
