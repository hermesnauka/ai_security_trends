# frozen_string_literal: true

class CodeSampleEntity < Grape::Entity
  expose :language
  expose :sample_type, as: :sampleType
  expose :title
  expose :description
  expose :code
  expose :framework_hint, as: :frameworkHint
  expose :version_note, as: :versionNote
end
