# frozen_string_literal: true

require "sequel"
require "logger"
require "rack/attack"

RACK_ENV = ENV.fetch("RACK_ENV", "development")

DB = Sequel.connect(
  ENV.fetch("DATABASE_URL", "postgres://localhost/rubyguard_#{RACK_ENV}"),
  logger: RACK_ENV == "development" ? Logger.new($stdout) : nil
)

Sequel.extension :migration
DB.extension :pg_array
DB.extension :pg_array_ops
Sequel::Model.plugin :json_serializer

# D-01/SR-05: throttle login attempts per source IP — brute-force mitigation.
# The cache store is set explicitly (rather than relying on rack-attack's
# own default) so behavior doesn't depend on an assumption about what that
# default is — a single-process in-memory store is correct for this app
# (one Puma process per container in Phase-1 scope; a multi-process
# deployment would need a shared store, e.g. Redis, to throttle correctly
# across processes — not needed yet, stated here rather than silently
# assumed away).
require "active_support/cache/memory_store"
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

class Rack::Attack
  throttle("logins/ip", limit: 5, period: 60) do |req|
    req.ip if req.path == "/api/v1/auth/login" && req.post?
  end
end

Dir[File.join(__dir__, "..", "app", "models", "*.rb")].sort.each { |f| require f }
Dir[File.join(__dir__, "..", "app", "services", "*.rb")].sort.each { |f| require f }
Dir[File.join(__dir__, "..", "app", "entities", "*.rb")].sort.each { |f| require f }
