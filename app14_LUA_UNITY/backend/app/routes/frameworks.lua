local Framework = require("app.models.framework")

local function framework_entity(f)
  return {
    code = f.code,
    name = f.name,
    version = f.version,
    description = f.description,
    referenceUrl = f.reference_url
  }
end

return function(app)
  app:get("/api/v1/frameworks", function(self)
    local frameworks = Framework:select()
    local content = {}
    for _, f in ipairs(frameworks) do table.insert(content, framework_entity(f)) end
    return { json = content }
  end)

  app:get("/api/v1/frameworks/:code", function(self)
    local framework = Framework:find(self.params.code)
    if not framework then
      return {
        status = 404,
        json = {
          timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
          status = 404,
          error = "Not Found",
          message = "No such framework"
        }
      }
    end
    return { json = framework_entity(framework) }
  end)
end
