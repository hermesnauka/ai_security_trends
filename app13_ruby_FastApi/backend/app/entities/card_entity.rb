# frozen_string_literal: true

class CardEntity < Grape::Entity
  expose :card_id, as: :cardId
  expose :suit_code, as: :suitCode
  expose :suit_name, as: :suitName
  expose :edition
  expose :value
  expose :card_kind, as: :cardKind
  # D-03: severity is exposed only via `severity_or_nil` — there is no way
  # for a design-harm card to have a severity read off it, structurally
  # impossible by construction at the database level (CHECK constraint) and
  # by this entity only ever calling the nil-safe accessor.
  expose :severity_or_nil, as: :severity
  expose :description_en, as: :descriptionEn
  expose :description_pl, as: :descriptionPl
  expose :misc_note, as: :miscNote
  expose :source_url, as: :sourceUrl
  expose :owasp_refs, as: :owaspRefs
  expose :mitre_refs, as: :mitreRefs
  expose :is_critical, as: :isCritical
end
