# frozen_string_literal: true

class Card < Sequel::Model(:cards)
  unrestrict_primary_key

  one_to_many :mitigations, key: :card_id

  # D-03: the only way to read a severity at all — there is no other
  # accessor, so a design-harm card can never have a severity read off it by
  # mistake. This is the runtime-checked analogue of Kotlin's
  # `CardKind.severityOrNull()`/Swift's `CardKind.severity` exhaustive switch.
  def severity_or_nil
    card_kind == "design_harm" ? nil : severity
  end

  def design_harm?
    card_kind == "design_harm"
  end

  def localized_description(locale)
    locale == "pl" && !description_pl.to_s.empty? ? description_pl : description_en
  end
end
