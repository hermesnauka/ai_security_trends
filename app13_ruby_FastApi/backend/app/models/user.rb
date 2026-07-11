# frozen_string_literal: true

require "bcrypt"

class User < Sequel::Model(:users)
  # D-01/SR-03: the one hardcoded admin credential is bcrypt-hashed at rest —
  # never compared in plaintext, never logged.
  def password=(plaintext)
    self.password_digest = BCrypt::Password.create(plaintext)
  end

  def authenticate(plaintext)
    BCrypt::Password.new(password_digest) == plaintext ? self : false
  end
end
