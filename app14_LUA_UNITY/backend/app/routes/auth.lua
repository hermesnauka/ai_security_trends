local User = require("app.models.user")
local JwtService = require("app.services.jwt_service")
local RateLimiter = require("app.services.rate_limiter")

local function error_body(status, err, message)
  return {
    timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
    status = status,
    error = err,
    message = message
  }
end

return function(app)
  app:post("/api/v1/auth/login", function(self)
    local username = self.params.username
    local password = self.params.password

    if type(username) ~= "string" or username == "" or type(password) ~= "string" or password == "" then
      return { status = 400, json = error_body(400, "Bad Request", "username and password are required") }
    end

    if not RateLimiter.check_login_attempt(self.req.headers["x-forwarded-for"] or ngx.var.remote_addr) then
      return { status = 429, json = error_body(429, "Too Many Requests", "Too many login attempts — try again later") }
    end

    local user = User:find({ username = username })
    if not user or not user:authenticate(password) then
      return { status = 401, json = error_body(401, "Unauthorized", "Invalid username or password") }
    end

    return {
      status = 200,
      json = {
        token = JwtService.encode(user.username, user.role),
        tokenType = "Bearer",
        role = user.role
      }
    }
  end)
end
