# frozen_string_literal: true

class CrossReference < Sequel::Model(:cross_references)
  many_to_one :source_threat, key: :source_threat_code, class: :Threat
end
