# frozen_string_literal: true

class ThreatSummaryEntity < Grape::Entity
  expose :code
  expose :framework_code, as: :frameworkCode
  expose :title
  expose :severity
  expose :category
  expose :tags
end
