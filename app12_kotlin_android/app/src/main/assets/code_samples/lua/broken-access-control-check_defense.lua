-- SECURE pattern
local id = tonumber(ngx.var.arg_id)
local user_id = tonumber(ngx.ctx.authenticated_user_id)
-- WHY: the WHERE clause itself restricts rows to the authenticated user, not just the requested id
local invoice = db:query("SELECT * FROM invoices WHERE id = " .. id .. " AND owner_id = " .. user_id)
ngx.say(cjson.encode(invoice))
