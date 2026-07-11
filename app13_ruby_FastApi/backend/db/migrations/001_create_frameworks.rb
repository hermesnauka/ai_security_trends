# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:frameworks) do
      String :code, primary_key: true
      String :name, null: false
      String :version, null: false
      String :description, text: true, null: false, default: ""
      String :reference_url, null: false, default: ""
    end
  end
end
