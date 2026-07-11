# frozen_string_literal: true

class ThreatDetailEntity < Grape::Entity
  expose :code
  expose :framework_code, as: :frameworkCode
  expose :title
  expose :severity
  expose :category
  expose :description_en, as: :descriptionEn
  expose :description_pl, as: :descriptionPl
  expose :attack_vector, as: :attackVector
  expose :attack_surface, as: :attackSurface
  expose :stride
  expose :tags
  expose :mitigations, using: MitigationEntity
  expose :cross_references, as: :crossReferences, using: CrossReferenceEntity
end
