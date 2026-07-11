-- frozen: same "env-var only, never committed" discipline every sibling's
-- JWT_SECRET/DB credential handling follows (PLAN.md D-01, requirements.md SR-02/SR-03).
local config = require("lapis.config")

config("development", {
  postgres = {
    host = os.getenv("DB_HOST") or "127.0.0.1",
    port = tonumber(os.getenv("DB_PORT")) or 5432,
    user = os.getenv("DB_USER") or "luaguard",
    password = os.getenv("DB_PASSWORD"),
    database = os.getenv("DB_NAME") or "luaguard_dev"
  },
  jwt_secret = os.getenv("JWT_SECRET"),
  seeds_root = os.getenv("SEEDS_ROOT") or "db/seeds"
})

config("test", {
  postgres = {
    host = os.getenv("DB_HOST") or "127.0.0.1",
    port = tonumber(os.getenv("DB_PORT")) or 5432,
    user = os.getenv("DB_USER") or "luaguard",
    password = os.getenv("DB_PASSWORD"),
    database = os.getenv("DB_NAME") or "luaguard_test"
  },
  jwt_secret = os.getenv("JWT_SECRET") or "test-secret-not-for-production",
  seeds_root = os.getenv("SEEDS_ROOT") or "db/seeds"
})

config("production", {
  postgres = {
    host = os.getenv("DB_HOST"),
    port = tonumber(os.getenv("DB_PORT")) or 5432,
    user = os.getenv("DB_USER"),
    password = os.getenv("DB_PASSWORD"),
    database = os.getenv("DB_NAME") or "luaguard_production"
  },
  jwt_secret = os.getenv("JWT_SECRET"),
  seeds_root = os.getenv("SEEDS_ROOT") or "db/seeds"
})
