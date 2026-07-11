# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :username, null: false, unique: true
      String :password_digest, null: false
      String :role, null: false, default: "ADMIN"

      constraint(:users_role_check) { Sequel.lit("role IN ('ADMIN')") }
    end
  end
end
