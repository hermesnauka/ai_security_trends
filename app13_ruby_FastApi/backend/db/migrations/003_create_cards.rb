# frozen_string_literal: true

Sequel.migration do
  change do
    create_table(:cards) do
      String :card_id, primary_key: true
      String :suit_code, null: false
      String :suit_name, null: false
      String :edition, null: false
      String :value, null: false
      String :card_kind, null: false
      String :severity # NULL-able — see D-03 constraint below
      String :description_en, text: true, null: false
      String :description_pl, text: true, null: false, default: ""
      String :misc_note, text: true
      String :source_url
      column :owasp_refs, "text[]", null: false, default: Sequel.lit("'{}'")
      column :mitre_refs, "text[]", null: false, default: Sequel.lit("'{}'")
      String :content_sha256, null: false
      TrueClass :is_critical, null: false, default: false

      index :suit_code
      index :edition

      # D-03: it is structurally impossible, at the database level, for a
      # design_harm card to carry a severity, or for a technical_threat card
      # to lack one — the runtime-enforced analogue of the compiler-enforced
      # sum types every statically-typed sibling in this series gets instead.
      constraint(:cards_kind_check) do
        Sequel.lit("card_kind IN ('technical_threat', 'design_harm')")
      end
      constraint(:cards_severity_matches_kind_check) do
        Sequel.lit(
          "(card_kind = 'design_harm' AND severity IS NULL) OR " \
          "(card_kind = 'technical_threat' AND severity IS NOT NULL)"
        )
      end
    end
  end
end
