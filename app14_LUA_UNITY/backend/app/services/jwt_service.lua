local jwt = require("resty.jwt")

-- D-01/SR-02: JWT HS256 with a shared secret sourced only from an environment
-- variable, never committed — matches app01_react's JwtService contract
-- exactly (no key pair, no RS256; that's app05_go_react's one stated
-- exception, not a pattern to copy here).
local config = require("lapis.config").get()

local JwtService = {}

local function secret()
  local s = config.jwt_secret
  if not s or s == "" then
    error("JWT_SECRET environment variable is not set — refusing to start with no secret")
  end
  return s
end

function JwtService.encode(username, role, expires_in)
  expires_in = expires_in or 3600
  local now = ngx and ngx.time() or os.time()
  local token = jwt:sign(secret(), {
    header = { typ = "JWT", alg = "HS256" },
    payload = {
      sub = username,
      role = role,
      iat = now,
      exp = now + expires_in
    }
  })
  return token
end

-- @return table|nil the decoded payload, or nil if invalid/expired
function JwtService.decode(token)
  local ok, verified = pcall(function()
    return jwt:verify(secret(), token)
  end)

  if not ok or not verified or not verified.verified then
    return nil
  end

  return verified.payload
end

return JwtService
