#!/usr/bin/env bash
# Docker-less local dev stack for this machine only.
#
# docker-compose.yml is the real, portable way to run this project - use it
# if Docker is installed and a docker-compose.yml exists here (as of
# 2026-07-11 it does not, see ../CLAUDE.md/../README.md). This script exists
# because Docker isn't installed on THIS machine; it drives the same three
# pieces (Postgres, backend, frontend) as standalone portable installs under
# C:\Users\krish\tools\ instead of containers. The tool paths below are
# specific to this machine - don't assume this script works unmodified
# anywhere else.
#
# NOTE (fixed 2026-07-11): this script used to `cd backend && mvn
# spring-boot:run` - a stale copy of app01_react's script that never actually
# started the C++/Drogon backend (see ../CLAUDE.md "Local dev tooling"). It
# now builds and runs the real Conan/CMake `cppcitadel` binary instead.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.local-dev"
mkdir -p "$RUN_DIR"

TOOLS="/c/Users/krish/tools"
PGBIN="$TOOLS/pgsql/bin"
PGDATA="C:\\Users\\krish\\tools\\pgdata"

export PATH="$PGBIN:$PATH"

DB_NAME="${DB_NAME:-cppcitadel}"
DB_USER="${DB_USER:-cppcitadel}"
DB_PASSWORD="${DB_PASSWORD:-cppcitadel}"
HTTP_PORT="${HTTP_PORT:-8080}"

echo "== Postgres =="
if "$PGBIN/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    echo "already running"
else
    "$PGBIN/pg_ctl.exe" -D "$PGDATA" -l "$RUN_DIR/postgres.log" -o "-p 5432" start
    timeout 30 bash -c 'until "'"$PGBIN"'/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; do sleep 1; done'
    echo "started"
fi

echo "== Database + migrations ($DB_NAME) =="
if ! psql -U postgres -h 127.0.0.1 -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" | grep -q 1; then
    psql -U postgres -h 127.0.0.1 -c "CREATE ROLE ${DB_USER} WITH LOGIN PASSWORD '${DB_PASSWORD}';"
fi
if ! psql -U postgres -h 127.0.0.1 -tAc "SELECT 1 FROM pg_database WHERE datname='${DB_NAME}'" | grep -q 1; then
    psql -U postgres -h 127.0.0.1 -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_USER};"
    psql -U "$DB_USER" -h 127.0.0.1 -d "$DB_NAME" -f "$ROOT_DIR/backend/db/migrations/V1__init_schema.sql"
    psql -U "$DB_USER" -h 127.0.0.1 -d "$DB_NAME" -f "$ROOT_DIR/backend/db/migrations/V2__seed.sql"
    echo "created + migrated + seeded"
else
    echo "already exists (migrations are NOT re-run automatically - there is no migration tool/tracking table yet, see ../CLAUDE.md)"
fi

echo "== Backend build (Conan + CMake, C++23/Drogon, :$HTTP_PORT) =="
BIN="$ROOT_DIR/backend/build/cppcitadel"
if [ ! -x "$BIN" ]; then
    (
        cd "$ROOT_DIR/backend"
        conan install . -of=build --build=missing -s build_type=Release
        cmake --preset conan-release
        cmake --build --preset conan-release
    )
fi

if curl -sf "http://localhost:$HTTP_PORT/api/v1/frameworks" >/dev/null 2>&1; then
    echo "already running"
else
    (
        cd "$ROOT_DIR/backend"
        export DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME="$DB_NAME" DB_USER="$DB_USER" DB_PASSWORD="$DB_PASSWORD" HTTP_PORT="$HTTP_PORT"
        nohup ./build/cppcitadel > "$RUN_DIR/backend.log" 2>&1 &
        echo $! > "$RUN_DIR/backend.pid"
    )
    echo "starting (PID $(cat "$RUN_DIR/backend.pid")), waiting for :$HTTP_PORT ..."
    if timeout 60 bash -c 'until curl -sf "http://localhost:'"$HTTP_PORT"'/api/v1/frameworks" >/dev/null 2>&1; do sleep 2; done'; then
        echo "up"
    else
        echo "TIMED OUT - tail of $RUN_DIR/backend.log:"
        tail -60 "$RUN_DIR/backend.log"
        exit 1
    fi
fi

echo "== Frontend (Vite, :5173) =="
if curl -sf http://localhost:5173 >/dev/null 2>&1; then
    echo "already running"
else
    (
        cd "$ROOT_DIR/frontend"
        nohup npm run dev > "$RUN_DIR/frontend.log" 2>&1 &
        echo $! > "$RUN_DIR/frontend.pid"
    )
    echo "starting (PID $(cat "$RUN_DIR/frontend.pid")), waiting for :5173 ..."
    if timeout 30 bash -c 'until curl -sf http://localhost:5173 >/dev/null 2>&1; do sleep 1; done'; then
        echo "up"
    else
        echo "TIMED OUT - tail of $RUN_DIR/frontend.log:"
        tail -60 "$RUN_DIR/frontend.log"
        exit 1
    fi
fi

echo
echo "Frontend:    http://localhost:5173"
echo "Backend API: http://localhost:$HTTP_PORT/api/v1/frameworks"
echo "Logs:        $RUN_DIR/{postgres,backend,frontend}.log"
echo "Stop with:   scripts/local-dev-down.sh"
