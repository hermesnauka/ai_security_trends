# frozen_string_literal: true

require "jwt"

# D-01/SR-02: JWT HS256 with a shared secret sourced only from an environment
# variable, never committed — matches app01_react's JwtService contract
# exactly (no key pair, no RS256; that is app05_go_react's one stated,
# intentional exception, not a pattern to copy here).
class JwtService
  ALGORITHM = "HS256"

  class << self
    def secret
      ENV.fetch("JWT_SECRET") do
        raise "JWT_SECRET environment variable is not set — refusing to start with no secret"
      end
    end

    def encode(username:, role:, expires_in: 3600)
      payload = {
        sub: username,
        role: role,
        iat: Time.now.to_i,
        exp: Time.now.to_i + expires_in
      }
      JWT.encode(payload, secret, ALGORITHM)
    end

    # @return [Hash, nil] the decoded payload, or nil if invalid/expired
    def decode(token)
      decoded, = JWT.decode(token, secret, true, algorithm: ALGORITHM)
      decoded
    rescue JWT::DecodeError, JWT::ExpiredSignature
      nil
    end
  end
end
