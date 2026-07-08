#!/usr/bin/env bash
# Docker-less local dev stack for this machine only.
#
# docker-compose.yml is the real, portable way to run this project - use it
# if Docker is installed. This script exists because Docker isn't installed
# on THIS machine; it drives the same three pieces (Postgres, backend,
# frontend) as standalone portable installs under C:\Users\krish\tools\
# instead of containers. The tool paths below are specific to this machine -
# don't assume this script works unmodified anywhere else.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.local-dev"
mkdir -p "$RUN_DIR"

TOOLS="/c/Users/krish/tools"
PGBIN="$TOOLS/pgsql/bin"
PGDATA="C:\\Users\\krish\\tools\\pgdata"
JAVA_HOME="$TOOLS/jdk-21.0.11+10"
MAVEN_BIN="$TOOLS/apache-maven-3.9.9/bin"
GHCUP_BIN="/c/ghcup/bin"

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$MAVEN_BIN:$PGBIN:$GHCUP_BIN:$PATH"

echo "== Postgres =="
if "$PGBIN/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    echo "already running"
else
    "$PGBIN/pg_ctl.exe" -D "$PGDATA" -l "$RUN_DIR/postgres.log" -o "-p 5432" start
    timeout 30 bash -c 'until "'"$PGBIN"'/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; do sleep 1; done'
    echo "started"
fi

echo "== Backend (Haskell/servant, :8080) =="
if curl -sf http://localhost:8080/health >/dev/null 2>&1; then
    echo "already running"
else
    (
        cd "$ROOT_DIR/backend"
        # DB_NAME is "haskshield", NOT "securevision" - this machine runs one
        # shared Postgres instance for every app0N_* course project, and
        # app01_react's Java/Flyway backend already owns a "securevision"
        # database with its OWN schema (comma-joined stride/tags columns,
        # flyway_schema_history). Reusing that name here would collide with
        # app01's tables the first time this backend's migrations run. In a
        # real Docker Compose deployment each app gets its own container +
        # volume, so this collision is specific to this shared, Docker-less
        # local setup - see backend/CLAUDE.md.
        export DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME=haskshield DB_USER="${POSTGRES_USER}" DB_PASSWORD="${POSTGRES_PASSWORD}"
        # Dev-only defaults, matching ../.env's values. .env itself uses
        # docker-compose's "$$" escaping for a literal "$" (e.g.
        # ADMIN_PASSWORD_HASH=...); bash would instead expand "$$"
        # to the current shell's PID if this file were sourced directly, so
        # these are hardcoded here (single-quoted, no expansion) same as the
        # DB_* vars above rather than parsed out of .env.
        export JWT_SECRET='dev-only-secret-change-me-securevision-2026-min-32-bytes'
        export JWT_EXPIRATION_MINUTES=60
        export ADMIN_USERNAME='admin'
        export ADMIN_PASSWORD_HASH="${ADMIN_PASSWORD_HASH}"
        nohup cabal run api > "$RUN_DIR/backend.log" 2>&1 &
        echo $! > "$RUN_DIR/backend.pid"
    )
    echo "starting (PID $(cat "$RUN_DIR/backend.pid")), waiting for :8080 ..."
    echo "(first run compiles every dependency from scratch - can take several minutes)"
    if timeout 900 bash -c 'until curl -sf http://localhost:8080/health >/dev/null 2>&1; do sleep 2; done'; then
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
echo "Backend API: http://localhost:8080/api/v1/frameworks"
echo "Health:      http://localhost:8080/health"
echo "Logs:        $RUN_DIR/{postgres,backend,frontend}.log"
echo "Stop with:   scripts/local-dev-down.sh"
