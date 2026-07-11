# frozen_string_literal: true

class CrossReferenceEntity < Grape::Entity
  expose :target_threat_code, as: :targetThreatCode
  expose :target_threat_title, as: :targetThreatTitle
  expose :relationship_type, as: :relationshipType
  expose :description
end
