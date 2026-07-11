require("spec.spec_helper")
local http = require("spec.support.http_client")
local JwtService = require("app.services.jwt_service")

describe("POST /api/v1/auth/login", function()
  it("returns a bearer token for the correct credentials (D-01)", function()
    local res = http.post("/api/v1/auth/login", { username = TEST_ADMIN_USERNAME, password = TEST_ADMIN_PASSWORD })

    assert.are.equal(200, res.status)
    assert.are.equal("Bearer", res.json.tokenType)
    assert.are.equal("ADMIN", res.json.role)
    assert.is_true(#res.json.token > 0)

    local decoded = JwtService.decode(res.json.token)
    assert.are.equal(TEST_ADMIN_USERNAME, decoded.sub)
    assert.are.equal("ADMIN", decoded.role)
  end)

  it("401s for a wrong password", function()
    local res = http.post("/api/v1/auth/login", { username = TEST_ADMIN_USERNAME, password = "definitely-wrong" })
    assert.are.equal(401, res.status)
  end)

  it("401s for an unknown username", function()
    local res = http.post("/api/v1/auth/login", { username = "does-not-exist", password = "whatever" })
    assert.are.equal(401, res.status)
  end)

  it("400s when username is missing", function()
    local res = http.post("/api/v1/auth/login", { password = "whatever" })
    assert.are.equal(400, res.status)
  end)

  -- SR-05: throttled per source IP after 5 attempts within 60 seconds.
  it("rate-limits repeated login attempts from the same IP", function()
    local res
    for _ = 1, 6 do
      res = http.post("/api/v1/auth/login", { username = TEST_ADMIN_USERNAME, password = "wrong" })
    end
    assert.are.equal(429, res.status)
  end)
end)
