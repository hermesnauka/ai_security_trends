-- VULNERABLE — do not use in production
local body = ngx.req.get_body_data()
local reply = llm_client.complete(body)
ngx.say(reply)
