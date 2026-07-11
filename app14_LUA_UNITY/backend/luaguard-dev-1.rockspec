package = "luaguard"
version = "dev-1"
source = {
  url = "git+https://example.invalid/luaguard.git"
}
description = {
  summary = "LuaGuard 2026 backend — Lapis/OpenResty API for SecureVision + Security Architects: Digital",
  homepage = "https://example.invalid/luaguard",
  license = "MIT"
}
dependencies = {
  "lua >= 5.1",
  "lapis >= 1.16.0",
  "pgmoon >= 1.16.0",
  "lua-resty-jwt >= 0.2.3",
  "lyaml >= 6.2.8",
  "bcrypt >= 2.1.3"
}
build = {
  type = "builtin",
  modules = {}
}
