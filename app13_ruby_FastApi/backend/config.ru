# frozen_string_literal: true

require_relative "config/environment"
require_relative "app/api/root_api"

use Rack::Cors do
  allow do
    origins ENV.fetch("CORS_ORIGIN", "http://localhost:5173")
    resource "/api/*", headers: :any, methods: %i[get post put patch delete options]
  end
end

use Rack::Attack

run RubyGuard::API::RootAPI
