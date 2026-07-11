-- VULNERABLE — do not use in production
local id = ngx.var.arg_id
local invoice = db:query("SELECT * FROM invoices WHERE id = " .. id)
ngx.say(cjson.encode(invoice))
