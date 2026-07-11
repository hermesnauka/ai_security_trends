# frozen_string_literal: true

class Threat < Sequel::Model(:threats)
  unrestrict_primary_key

  many_to_one :framework, key: :framework_code
  one_to_many :mitigations, key: :threat_code
  one_to_many :cross_references, key: :source_threat_code

  # FR-18.6-equivalent: falls back to English when no Polish translation
  # exists yet, never a blank field. `title`/`attack_vector`/`attack_surface`
  # are not localized in this schema — only the longer `description` carries
  # a Polish variant, matching every sibling's D-05.
  def localized_description(locale)
    locale == "pl" && !description_pl.to_s.empty? ? description_pl : description_en
  end
end
