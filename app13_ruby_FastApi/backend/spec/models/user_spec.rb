# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe User do
  it "hashes the password with bcrypt rather than storing it in plaintext" do
    user = User.new(username: "bcrypt-test", role: "ADMIN")
    user.password = "correct-horse-battery-staple"
    user.save

    expect(user.password_digest).not_to eq("correct-horse-battery-staple")
    expect(BCrypt::Password.new(user.password_digest)).to eq("correct-horse-battery-staple")
  end

  it "authenticate returns the user for the correct password" do
    user = User.new(username: "auth-test", role: "ADMIN")
    user.password = "hunter2"
    user.save

    expect(user.authenticate("hunter2")).to eq(user)
  end

  it "authenticate returns false for a wrong password" do
    user = User.new(username: "auth-test-wrong", role: "ADMIN")
    user.password = "hunter2"
    user.save

    expect(user.authenticate("wrong-password")).to be false
  end

  # D-01: the users_role_check constraint only permits 'ADMIN' today — there
  # are no other roles in this Phase-1 slice.
  it "never allows a role other than ADMIN at the database level" do
    expect do
      DB[:users].insert(username: "not-admin", password_digest: "x", role: "SUPERUSER")
    end.to raise_error(Sequel::CheckConstraintViolation)
  end

  it "never allows two users with the same username" do
    User.new(username: "dup-test", role: "ADMIN").tap { |u| u.password = "x" }.save

    expect do
      User.new(username: "dup-test", role: "ADMIN").tap { |u| u.password = "y" }.save
    end.to raise_error(Sequel::UniqueConstraintViolation)
  end
end
