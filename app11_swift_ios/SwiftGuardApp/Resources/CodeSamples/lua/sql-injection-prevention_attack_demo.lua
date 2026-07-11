-- VULNERABLE — do not use in production
local name = ngx.var.arg_name
local res = db:query("SELECT id, email FROM users WHERE name = '" .. name .. "'")
