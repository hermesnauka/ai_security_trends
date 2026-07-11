# frozen_string_literal: true

module RubyGuard
  module API
    class AuthAPI < Grape::API
      namespace :auth do
        desc "Log in with the one seeded admin account"
        params do
          requires :username, type: String
          requires :password, type: String
        end
        post "login" do
          user = User.first(username: params[:username])
          unauthorized! unless user && user.authenticate(params[:password])

          # Grape defaults every `post` to `201 Created` — wrong semantics for
          # a login endpoint (nothing is "created"); matches app01_react's
          # actual contract, which returns 200 on successful login.
          status 200
          {
            token: JwtService.encode(username: user.username, role: user.role),
            tokenType: "Bearer",
            role: user.role
          }
        end
      end

      helpers do
        def unauthorized!
          error!({ timestamp: Time.now.iso8601, status: 401, error: "Unauthorized", message: "Invalid username or password" }, 401)
        end
      end
    end
  end
end
