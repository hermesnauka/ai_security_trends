-- SECURE pattern
-- WHY: lua-resty-limit-req enforces a leaky-bucket rate per client, bounding LLM call volume and cost (LLM10:2025)
local limit_req = require "resty.limit.req" -- lua-resty-limit-req
local lim, err = limit_req.new("llm_chat_limit_store", 20, 5) -- 20 req/s, burst 5
if not lim then
    ngx.log(ngx.ERR, "failed to instantiate lua-resty-limit-req limiter: ", err)
    return ngx.exit(500)
end

local key = ngx.var.remote_addr
local delay, err = lim:incoming(key, true)
if not delay then
    if err == "rejected" then
        return ngx.exit(429)
    end
    ngx.log(ngx.ERR, "limit_req error: ", err)
    return ngx.exit(500)
end

local body = ngx.req.get_body_data()
local reply = llm_client.complete(body)
ngx.say(reply)
