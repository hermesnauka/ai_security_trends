# frozen_string_literal: true

require "grape"
require "grape-swagger"

Dir[File.join(__dir__, "*.rb")].sort.each { |f| require f unless f == __FILE__ }

module RubyGuard
  module API
    class V1Base < Grape::API
      format :json

      rescue_from Grape::Exceptions::ValidationErrors do |e|
        error!({ timestamp: Time.now.iso8601, status: 400, error: "Bad Request", message: e.message }, 400)
      end

      rescue_from Sequel::DatabaseError do |_e|
        error!({ timestamp: Time.now.iso8601, status: 500, error: "Internal Server Error", message: "A database error occurred" }, 500)
      end

      mount AuthAPI
      mount FrameworksAPI
      mount ThreatsAPI
      mount CardsAPI
      mount MitigationsAPI
      mount MatrixAPI
      mount SearchAPI
      mount ExportAPI

      add_swagger_documentation(
        api_version: "v1",
        hide_documentation_path: false,
        mount_path: "/swagger_doc"
      )
    end

    class RootAPI < Grape::API
      mount HealthAPI
      mount V1Base => "/api/v1"
    end
  end
end
