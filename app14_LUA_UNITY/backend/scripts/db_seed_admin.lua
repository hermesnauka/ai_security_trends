-- Lua/Lapis equivalent of app13_ruby_FastApi's `rake db:seed_admin`.
local User = require("app.models.user")

local username = os.getenv("ADMIN_USERNAME") or "admin"
local password = os.getenv("ADMIN_PASSWORD")
if not password or password == "" then
  error("ADMIN_PASSWORD environment variable is required")
end

local user = User:find({ username = username })
if not user then
  user = User:create({ username = username, role = "ADMIN", password_digest = "" })
end
user:set_password(password)

print(string.format("Admin user '%s' ready.", username))
