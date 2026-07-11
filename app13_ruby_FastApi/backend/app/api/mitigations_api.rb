# frozen_string_literal: true

module RubyGuard
  module API
    class MitigationsAPI < Grape::API
      resource :mitigations do
        desc "Every mitigation for a given threat code"
        params do
          requires :threat_code, type: String
        end
        get ":threat_code" do
          present Mitigation.where(threat_code: params[:threat_code]).all, with: MitigationEntity
        end
      end
    end
  end
end
