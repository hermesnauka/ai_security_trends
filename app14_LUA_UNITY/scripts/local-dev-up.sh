#!/usr/bin/env bash
# Ensures this app's own Postgres role/DB exists on the shared, Docker-less
# local Postgres instance every backend sibling on this machine uses
# (../../CLAUDE.md "Local dev environment") — does NOT start/stop Postgres
# itself, since it's shared across every app.
set -euo pipefail

DB_NAME="${LUAGUARD_DB_NAME:-luaguard_development}"
DB_ROLE="${LUAGUARD_DB_ROLE:-luaguard}"

if ! psql -U postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_ROLE}'" | grep -q 1; then
  psql -U postgres -c "CREATE ROLE ${DB_ROLE} WITH LOGIN PASSWORD 'luaguard';"
fi

if ! psql -U postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1; then
  psql -U postgres -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_ROLE};"
fi

echo "luaguard: role '${DB_ROLE}' and database '${DB_NAME}' ready on the shared local Postgres instance."
echo "Next: cd backend && luarocks install --tree lua_modules lapis pgmoon lua-resty-jwt lyaml bcrypt lua-resty-limit-traffic"
echo "      && lua scripts/db_migrate.lua && lua scripts/db_seed.lua"
