# frozen_string_literal: true

class Mitigation < Sequel::Model(:mitigations)
  unrestrict_primary_key

  many_to_one :threat, key: :threat_code
  many_to_one :card, key: :card_id
  one_to_many :code_samples, key: :mitigation_slug
end
