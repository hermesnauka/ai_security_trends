# frozen_string_literal: true

class FrameworkEntity < Grape::Entity
  expose :code
  expose :name
  expose :version
  expose :description
  expose :reference_url, as: :referenceUrl
end
