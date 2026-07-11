-- Matches the shared Phase-1 contract's `/health` shape literally
-- (`../../CLAUDE.md` — app01/app02's real route is `/actuator/health`
-- instead; this app has no Spring Actuator equivalent, so the literal
-- `/health` path IS this app's real route, not an approximation of it).
return function(app)
  app:get("/health", function(self)
    return { json = { status = "UP" } }
  end)
end
