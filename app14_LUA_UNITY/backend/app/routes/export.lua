local db = require("lapis.db")

local function csv_escape(value)
  if value == nil then return "" end
  local s = tostring(value)
  if s:find('[",\n]') then
    return '"' .. s:gsub('"', '""') .. '"'
  end
  return s
end

-- FR-20-equivalent: synchronous CSV export generated within the request,
-- same query-parameter filters as /api/v1/threats — no polling endpoint, in
-- contrast to app09_php_WORDPRESS's asynchronous WP-Cron export.
return function(app)
  app:get("/api/v1/export.csv", function(self)
    local p = self.params
    local conditions = {}

    if p.frameworkCode then
      table.insert(conditions, "framework_code = " .. db.escape_literal(p.frameworkCode))
    end
    if p.severity then
      table.insert(conditions, "severity = " .. db.escape_literal(p.severity))
    end

    local where_clause = ""
    if #conditions > 0 then
      where_clause = "where " .. table.concat(conditions, " and ")
    end

    local rows = db.select("code, title, severity, category, framework_code from threats " .. where_clause .. " order by code")

    local lines = { "code,title,severity,category,frameworkCode" }
    for _, row in ipairs(rows) do
      table.insert(lines, table.concat({
        csv_escape(row.code), csv_escape(row.title), csv_escape(row.severity),
        csv_escape(row.category), csv_escape(row.framework_code)
      }, ","))
    end

    self.res.headers["Content-Type"] = "text/csv"
    self.res.headers["Content-Disposition"] = "attachment; filename=\"threats.csv\""
    return { layout = false, table.concat(lines, "\n") }
  end)
end
