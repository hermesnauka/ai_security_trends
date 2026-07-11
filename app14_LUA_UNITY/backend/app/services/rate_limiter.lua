-- SR-05: per-source-IP rate limiting for the login route, backed by an
-- OpenResty shared-dict counter (`lua_shared_dict rate_limit_login 10m;` in
-- nginx.conf) — the Lua/OpenResty analogue of app13_ruby_FastApi's
-- rack-attack. `limit_count.new` comes from lua-resty-limit-traffic.
local limit_count = require("resty.limit.count")

local RateLimiter = {}

-- 5 attempts per 60 seconds, matching every sibling's SR-05-equivalent.
function RateLimiter.check_login_attempt(source_ip)
  local lim, err = limit_count.new("rate_limit_login", 5, 60)
  if not lim then
    ngx.log(ngx.ERR, "failed to instantiate login rate limiter: ", err)
    return true -- fail open on limiter misconfiguration, never fail closed on a bug here
  end

  local delay, limit_err = lim:incoming(source_ip, true)
  if not delay then
    if limit_err == "rejected" then
      return false
    end
    ngx.log(ngx.ERR, "rate limiter error: ", limit_err)
    return true
  end

  return true
end

return RateLimiter
