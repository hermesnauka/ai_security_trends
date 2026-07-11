# frozen_string_literal: true

class MitigationEntity < Grape::Entity
  expose :slug
  expose :title
  expose :description
  expose :mitigation_type, as: :mitigationType
  expose :effort
  expose :effectiveness
  expose :code_samples, as: :codeSamples, using: CodeSampleEntity
end
