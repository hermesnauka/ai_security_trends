-- Calls the C#-registered native_http_get/native_http_post functions
-- (Bootstrap.cs) — this module never touches UnityWebRequest directly, and
-- native_http_* never hand this module a live C# object (D-07/SR-11), only
-- plain tables/strings via ApiBridge's JSON-to-Lua-table conversion.

local api_client = {}

local function build_query(params)
  if not params then return "" end
  local parts = {}
  for k, v in pairs(params) do
    if v ~= nil and v ~= "" then
      table.insert(parts, k .. "=" .. tostring(v))
    end
  end
  if #parts == 0 then return "" end
  return "?" .. table.concat(parts, "&")
end

function api_client.login(username, password, on_success, on_error)
  local body = string.format('{"username":"%s","password":"%s"}', username, password)
  native_http_post("/api/v1/auth/login", body, function(result)
    native_set_pref("luaguard.token", result.token)
    on_success(result)
  end, on_error)
end

function api_client.frameworks(on_success, on_error)
  native_http_get("/api/v1/frameworks", "", on_success, on_error)
end

function api_client.threats(params, on_success, on_error)
  native_http_get("/api/v1/threats", build_query(params), on_success, on_error)
end

function api_client.threat(code, on_success, on_error)
  native_http_get("/api/v1/threats/" .. code, "", on_success, on_error)
end

function api_client.cards(params, on_success, on_error)
  native_http_get("/api/v1/cards", build_query(params), on_success, on_error)
end

function api_client.mitigations_for_threat(threat_code, on_success, on_error)
  native_http_get("/api/v1/mitigations/" .. threat_code, "", on_success, on_error)
end

function api_client.search(query, on_success, on_error)
  native_http_get("/api/v1/search", build_query({ q = query }), on_success, on_error)
end

return api_client
