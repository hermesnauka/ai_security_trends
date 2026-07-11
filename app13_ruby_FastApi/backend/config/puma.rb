# frozen_string_literal: true

workers ENV.fetch("PUMA_WORKERS", 2).to_i
threads ENV.fetch("PUMA_MIN_THREADS", 2).to_i, ENV.fetch("PUMA_MAX_THREADS", 5).to_i

port ENV.fetch("PORT", 9292)
environment ENV.fetch("RACK_ENV", "development")

preload_app!

rackup DefaultRackup
