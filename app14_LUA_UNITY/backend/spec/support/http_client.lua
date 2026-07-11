-- Thin wrapper over Lapis's own `lapis.spec.request` helper (which drives
-- the real `app.lua` through a simulated ngx environment, no separate server
-- process needed) — the Lua/Lapis analogue of app13_ruby_FastApi's
-- Rack::Test-based spec_helper `app`/`last_response` convention.
local lapis_request = require("lapis.spec.request").request
local json = require("cjson")

local http = {}

local function build_query(params)
  if not params then return "" end
  local parts = {}
  for k, v in pairs(params) do
    table.insert(parts, k .. "=" .. tostring(v))
  end
  if #parts == 0 then return "" end
  return "?" .. table.concat(parts, "&")
end

function http.get(path, params)
  local status, body, headers = lapis_request(path .. build_query(params), { method = "GET" })
  local ok, decoded = pcall(json.decode, body)
  return { status = status, body = body, headers = headers, json = ok and decoded or nil }
end

function http.post(path, params)
  local status, body, headers = lapis_request(path, { method = "POST", post = params })
  local ok, decoded = pcall(json.decode, body)
  return { status = status, body = body, headers = headers, json = ok and decoded or nil }
end

return http
