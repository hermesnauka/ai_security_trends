local lapis = require("lapis")
local app = lapis.Application()

app:enable("etlua")

-- Every route below is required to have declared its own auth/validation
-- boundary explicitly — there is no global before-filter granting implicit
-- access (D-01/SR-04's "no route relies on nothing linking to it").
require("app.routes.health")(app)
require("app.routes.auth")(app)
require("app.routes.frameworks")(app)
require("app.routes.threats")(app)
require("app.routes.cards")(app)
require("app.routes.mitigations")(app)
require("app.routes.search")(app)
require("app.routes.matrix")(app)
require("app.routes.export")(app)

return app
