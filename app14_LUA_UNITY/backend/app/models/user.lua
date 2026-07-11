local Model = require("lapis.db.model").Model
local bcrypt = require("bcrypt")

-- D-01/SR-03: the one hardcoded admin credential is bcrypt-hashed at rest —
-- never compared in plaintext, never logged.
local User = Model:extend("users", {
  set_password = function(self, plaintext)
    self:update({ password_digest = bcrypt.digest(plaintext, 12) })
  end,

  authenticate = function(self, plaintext)
    if bcrypt.verify(plaintext, self.password_digest) then
      return self
    end
    return false
  end
})

return User
