-- busted spec helper — analogue of app13_ruby_FastApi's spec_helper.rb.
-- Run via `busted` from backend/ (busted picks up .busted config below).
os.setenv = os.setenv or function() end -- standard os has no setenv; env vars are set by the shell/CI, not here

package.path = "./?.lua;./?/init.lua;" .. package.path

_G.SEEDS_ROOT = "db/seeds"
_G.TEST_ADMIN_USERNAME = "admin"
_G.TEST_ADMIN_PASSWORD = "test-password-not-for-production"

-- Real busted specs run against a real Postgres test database + Lapis app,
-- wrapping each example in a transaction rollback the same way app13's
-- RSpec suite does (`DB.transaction(rollback: :always)`), via
-- `lapis.db.transaction` in a `before_each`/`after_each` pair declared by
-- each spec file — this shared helper only sets up path/env constants.
