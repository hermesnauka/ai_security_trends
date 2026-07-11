# frozen_string_literal: true

module RubyGuard
  module API
    class HealthAPI < Grape::API
      # Matches the shared Phase-1 contract's aspirational `/health` shape
      # literally (`../../CLAUDE.md` notes app01/app02's real route is
      # `/actuator/health` instead — this app has no Spring Actuator
      # equivalent, so the literal `/health` path IS this app's real route,
      # not an approximation of it).
      get "/health" do
        { status: "UP" }
      end
    end
  end
end
