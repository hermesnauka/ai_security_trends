local schema = require("lapis.db.schema")
local types = schema.types
local db = require("lapis.db")

return {
  up = function()
    schema.create_table("users", {
      { "id", types.serial({ primary_key = true }) },
      { "username", types.varchar({ null = false }) },
      { "password_digest", types.varchar({ null = false }) },
      { "role", types.varchar({ null = false, default = "ADMIN" }) }
    })

    db.query("create unique index users_username_idx on users (username)")
    db.query("alter table users add constraint users_role_check check (role in ('ADMIN'))")
  end,
  down = function()
    schema.drop_table("users")
  end
}
