# frozen_string_literal: true

ENV["RACK_ENV"] = "test"
ENV["JWT_SECRET"] ||= "test-secret-not-for-production"

require "rack/test"
require "tmpdir"
require "fileutils"
require_relative "../config/environment"
require_relative "../app/api/root_api"

SEEDS_ROOT = File.join(__dir__, "..", "db", "seeds")
TEST_ADMIN_USERNAME = "admin"
TEST_ADMIN_PASSWORD = "test-password-not-for-production"

RSpec.configure do |config|
  config.include Rack::Test::Methods

  config.before(:suite) do
    Sequel::Migrator.run(DB, File.join(__dir__, "..", "db", "migrations"))
    ContentSeeder.new(seeds_root: SEEDS_ROOT).seed!

    unless User.first(username: TEST_ADMIN_USERNAME)
      user = User.new(username: TEST_ADMIN_USERNAME, role: "ADMIN")
      user.password = TEST_ADMIN_PASSWORD
      user.save
    end
  end

  # rack-attack's counters live in its own in-memory cache store, entirely
  # separate from the per-example DB transaction rollback below — without
  # clearing it, login attempts from one example (e.g. the two 401 cases in
  # auth_spec.rb) would silently count toward another example's rate-limit
  # test, making pass/fail depend on example run order.
  config.before do
    Rack::Attack.cache.store.clear
  end

  config.around do |example|
    DB.transaction(rollback: :always) { example.run }
  end
end

def app
  RubyGuard::API::RootAPI
end
