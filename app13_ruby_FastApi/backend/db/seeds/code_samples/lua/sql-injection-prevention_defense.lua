-- SECURE pattern
local name = ngx.var.arg_name
-- WHY: ngx.quote_sql_str escapes quotes/backslashes so `name` cannot break out of the string literal
local quoted = ngx.quote_sql_str(name)
local res = db:query("SELECT id, email FROM users WHERE name = " .. quoted)
