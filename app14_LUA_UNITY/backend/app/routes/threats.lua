local db = require("lapis.db")
local Threat = require("app.models.threat")

-- D-02/SR-01: every clause below is built with db.escape_literal/parameterized
-- placeholders — never raw string concatenation of a request parameter,
-- mirroring app13_ruby_FastApi's Sequel dataset usage (Lapis/pgmoon has no
-- Sequel-style chained dataset builder, so the WHERE clause is assembled by
-- hand here, but every value still passes through escape_literal).
local ALLOWED_SEVERITIES = { critical = true, high = true, medium = true, low = true, info = true }
local ALLOWED_STRIDE = { S = true, T = true, R = true, I = true, D = true, E = true }

local function threat_summary_entity(t)
  return {
    code = t.code,
    frameworkCode = t.framework_code,
    title = t.title,
    severity = t.severity,
    category = t.category,
    stride = t.stride,
    tags = t.tags
  }
end

local function threat_detail_entity(t)
  local summary = threat_summary_entity(t)
  summary.descriptionEn = t.description_en
  summary.descriptionPl = t.description_pl
  summary.attackVector = t.attack_vector
  summary.attackSurface = t.attack_surface
  return summary
end

local function not_found(message)
  return {
    status = 404,
    json = {
      timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
      status = 404,
      error = "Not Found",
      message = message
    }
  }
end

local function bad_request(message)
  return {
    status = 400,
    json = {
      timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
      status = 400,
      error = "Bad Request",
      message = message
    }
  }
end

return function(app)
  app:get("/api/v1/threats", function(self)
    local p = self.params
    local severity = p.severity
    local stride = p.stride

    if severity and not ALLOWED_SEVERITIES[severity] then
      return bad_request("invalid severity value")
    end
    if stride and not ALLOWED_STRIDE[stride] then
      return bad_request("invalid stride value")
    end

    local page = tonumber(p.page) or 0
    local size = tonumber(p.size) or 20
    if page < 0 then return bad_request("page must be >= 0") end
    if size <= 0 or size > 100 then return bad_request("size must be between 1 and 100") end

    local sort = p.sort or "code"

    local conditions = {}
    if p.frameworkCode then
      table.insert(conditions, "framework_code = " .. db.escape_literal(p.frameworkCode))
    end
    if severity then
      table.insert(conditions, "severity = " .. db.escape_literal(severity))
    end
    if stride then
      table.insert(conditions, "stride @> ARRAY[" .. db.escape_literal(stride) .. "]::text[]")
    end
    if p.tag then
      table.insert(conditions, "tags @> ARRAY[" .. db.escape_literal(p.tag) .. "]::text[]")
    end
    if p.q then
      local like = db.escape_literal("%" .. p.q .. "%")
      table.insert(conditions, "(title ILIKE " .. like .. " OR description_en ILIKE " .. like .. ")")
    end

    local where_clause = ""
    if #conditions > 0 then
      where_clause = "where " .. table.concat(conditions, " and ")
    end

    local total = db.select(
      "count(*) as total from threats " .. where_clause
    )[1].total

    local rows = db.select(
      "* from threats " .. where_clause ..
      " order by " .. db.escape_identifier(sort) ..
      " limit " .. db.escape_literal(size) ..
      " offset " .. db.escape_literal(page * size)
    )

    local content = {}
    for _, row in ipairs(rows) do table.insert(content, threat_summary_entity(row)) end

    return {
      json = {
        content = content,
        totalElements = total,
        totalPages = math.ceil(total / size),
        number = page,
        size = size
      }
    }
  end)

  app:get("/api/v1/threats/:id", function(self)
    local threat = Threat:find(self.params.id)
    if not threat then
      return not_found("No such threat")
    end
    return { json = threat_detail_entity(threat) }
  end)
end
