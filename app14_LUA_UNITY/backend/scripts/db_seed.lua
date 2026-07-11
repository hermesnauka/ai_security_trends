-- Lua/Lapis equivalent of app13_ruby_FastApi's `rake db:seed`.
local config = require("lapis.config").get()
local ContentSeeder = require("app.services.content_seeder")

ContentSeeder.new(config.seeds_root):seed()
print("Seeding complete.")
