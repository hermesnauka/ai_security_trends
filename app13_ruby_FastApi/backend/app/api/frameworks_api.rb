# frozen_string_literal: true

module RubyGuard
  module API
    class FrameworksAPI < Grape::API
      resource :frameworks do
        desc "List every seeded framework"
        get do
          present Framework.order(:name).all, with: FrameworkEntity
        end

        desc "A single framework's detail"
        params do
          requires :code, type: String
        end
        get ":code" do
          framework = Framework[params[:code]]
          error!({ timestamp: Time.now.iso8601, status: 404, error: "Not Found", message: "No such framework" }, 404) unless framework

          present framework, with: FrameworkEntity
        end
      end
    end
  end
end
