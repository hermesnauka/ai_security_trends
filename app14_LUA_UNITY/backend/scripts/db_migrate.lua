-- Lua/Lapis equivalent of app13_ruby_FastApi's `rake db:migrate` — invoked
-- via `lua scripts/db_migrate.lua` or the shared local-dev scripts.
require("lapis.cmd.actions").migrate.command({}, {
  environment = os.getenv("LAPIS_ENVIRONMENT") or "development"
})
print("Migrated to latest version.")
