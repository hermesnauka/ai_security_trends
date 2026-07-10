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

export JAVA_HOME
export PATH="$JAVA_HOME/bin:$MAVEN_BIN:$PGBIN:$PATH"

echo "== Postgres =="
if "$PGBIN/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    echo "already running"
else
    "$PGBIN/pg_ctl.exe" -D "$PGDATA" -l "$RUN_DIR/postgres.log" -o "-p 5432" start
    timeout 30 bash -c 'until "'"$PGBIN"'/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; do sleep 1; done'
    echo "started"
fi

echo "== Backend (Spring Boot, :8080) =="
if curl -sf http://localhost:8080/api/v1/frameworks >/dev/null 2>&1; then
    echo "already running"
else
    (
        cd "$ROOT_DIR/backend"
        export DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME=securevision DB_USER=securevision DB_PASSWORD=${POSTGRES_PASSWORD}
        nohup mvn spring-boot:run > "$RUN_DIR/backend.log" 2>&1 &
        echo $! > "$RUN_DIR/backend.pid"
    )
    echo "starting (PID $(cat "$RUN_DIR/backend.pid")), waiting for :8080 ..."
    if timeout 90 bash -c 'until curl -sf http://localhost:8080/api/v1/frameworks >/dev/null 2>&1; do sleep 2; done'; then
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
echo "Swagger UI:  http://localhost:8080/swagger-ui.html"
echo "Logs:        $RUN_DIR/{postgres,backend,frontend}.log"
echo "Stop with:   scripts/local-dev-down.sh"
