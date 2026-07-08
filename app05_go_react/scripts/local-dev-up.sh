#!/usr/bin/env bash
# Docker-less local dev stack for this machine only.
#
# docker-compose.yml is the real, portable way to run this project - use it
# if Docker is installed. This script exists because Docker isn't installed
# on THIS machine; it drives Postgres (shared instance across sibling apps -
# see app01_react/scripts for why), the Go backend (goose migrate -> seed ->
# cmd/api), and the Vite frontend as standalone portable installs under
# C:\Users\krish\tools\ instead of containers. The tool paths below are
# specific to this machine - don't assume this script works unmodified
# anywhere else.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.local-dev"
mkdir -p "$RUN_DIR"

TOOLS="/c/Users/krish/tools"
PGBIN="$TOOLS/pgsql/bin"
PGDATA="C:\\Users\\krish\\tools\\pgdata"
GOROOT_DIR="$TOOLS/go"
GOPATH_DIR="$TOOLS/gopath"

export GOROOT="$GOROOT_DIR"
export GOPATH="$GOPATH_DIR"
export PATH="$GOROOT_DIR/bin:$GOPATH_DIR/bin:$PGBIN:$PATH"

echo "== Postgres =="
if "$PGBIN/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    echo "already running"
else
    "$PGBIN/pg_ctl.exe" -D "$PGDATA" -l "$RUN_DIR/postgres.log" -o "-p 5432" start
    timeout 30 bash -c 'until "'"$PGBIN"'/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; do sleep 1; done'
    echo "started"
fi

echo "== gosentry role/database =="
"$PGBIN/psql.exe" -U securevision -h 127.0.0.1 -p 5432 -d postgres -c \
    "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'gosentry') THEN CREATE ROLE gosentry LOGIN PASSWORD \${POSTGRES_PASSWORD}; END IF; END \$\$;" >/dev/null 2>&1 || true
"$PGBIN/psql.exe" -U securevision -h 127.0.0.1 -p 5432 -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'gosentry'" 2>/dev/null | grep -q 1 \
    || "$PGBIN/psql.exe" -U securevision -h 127.0.0.1 -p 5432 -d postgres -c "CREATE DATABASE gosentry OWNER gosentry;" >/dev/null 2>&1
echo "ready"

cd "$ROOT_DIR/backend"
export DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME="${POSTGRES_DB}" DB_USER="${POSTGRES_USER}" DB_PASSWORD="${POSTGRES_PASSWORD}" HTTP_PORT=8080
export GOOSE_DRIVER=postgres
export GOOSE_DBSTRING="postgres://gosentry:gosentry@127.0.0.1:5432/gosentry?sslmode=disable"

echo "== Migrations =="
"$GOPATH_DIR/bin/goose.exe" -dir migrations up

echo "== Seed =="
go run ./cmd/seed

echo "== Backend (chi, :8080) =="
if curl -sf http://localhost:8080/api/v1/health >/dev/null 2>&1; then
    echo "already running"
else
    nohup go run ./cmd/api > "$RUN_DIR/backend.log" 2>&1 &
    echo $! > "$RUN_DIR/backend.pid"
    echo "starting (PID $(cat "$RUN_DIR/backend.pid")), waiting for :8080 ..."
    if timeout 60 bash -c 'until curl -sf http://localhost:8080/api/v1/health >/dev/null 2>&1; do sleep 2; done'; then
        echo "up"
    else
        echo "TIMED OUT - tail of $RUN_DIR/backend.log:"
        tail -80 "$RUN_DIR/backend.log"
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
echo "Backend API: http://localhost:8080/api/v1/frameworks"
echo "Health:      http://localhost:8080/api/v1/health"
echo "Logs:        $RUN_DIR/{postgres,backend,frontend}.log"
echo "Stop with:   scripts/local-dev-down.sh"
