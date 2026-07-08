#!/usr/bin/env bash
# Docker-less local dev stack for this machine only.
#
# docker-compose.yml is the real, portable way to run this project - use it
# if Docker is installed. This script exists because Docker isn't installed
# on THIS machine; it drives the same three pieces (Postgres, backend,
# frontend) as standalone portable installs under C:\Users\krish\tools\
# instead of containers. The tool paths below are specific to this machine -
# don't assume this script works unmodified anywhere else.
#
# Postgres is a SHARED instance across sibling apps on this machine (one
# pgdata dir, one server on :5432) - this script only ensures the
# `threatview` role/database exist inside it, it doesn't own the server.
# Stopping it via local-dev-down.sh affects any other sibling app currently
# using it too.
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

echo "== threatview role/database =="
"$PGBIN/psql.exe" -U securevision -h 127.0.0.1 -p 5432 -d postgres -v ON_ERROR_STOP=0 -c \
    "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'threatview') THEN CREATE ROLE threatview LOGIN PASSWORD \${POSTGRES_PASSWORD}; END IF; END \$\$;" >/dev/null 2>&1 \
    || "$PGBIN/psql.exe" -U threatview -h 127.0.0.1 -p 5432 -d postgres -c "SELECT 1" >/dev/null 2>&1 \
    || echo "  (couldn't confirm/create role via securevision superuser - check manually if the backend fails to connect)"
"$PGBIN/psql.exe" -U securevision -h 127.0.0.1 -p 5432 -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'threatview'" 2>/dev/null | grep -q 1 \
    || "$PGBIN/psql.exe" -U securevision -h 127.0.0.1 -p 5432 -d postgres -c "CREATE DATABASE threatview OWNER threatview;" >/dev/null 2>&1
echo "ready"

echo "== Backend (Spring Boot, :8080) =="
if curl -sf http://localhost:8080/api/v1/frameworks >/dev/null 2>&1; then
    echo "already running"
else
    (
        cd "$ROOT_DIR/backend"
		
		
		export DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME="${POSTGRES_DB}" DB_USER="${POSTGRES_USER}" DB_PASSWORD="${POSTGRES_PASSWORD}"

		
		
        export DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME=threatview DB_USER=threatview DB_PASSWORD=threatview
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

echo "== Frontend (Angular ng serve, :4200) =="
if curl -sf http://localhost:4200 >/dev/null 2>&1; then
    echo "already running"
else
    (
        cd "$ROOT_DIR/frontend"
        nohup npx ng serve > "$RUN_DIR/frontend.log" 2>&1 &
        echo $! > "$RUN_DIR/frontend.pid"
    )
    echo "starting (PID $(cat "$RUN_DIR/frontend.pid")), waiting for :4200 ..."
    if timeout 60 bash -c 'until curl -sf http://localhost:4200 >/dev/null 2>&1; do sleep 2; done'; then
        echo "up"
    else
        echo "TIMED OUT - tail of $RUN_DIR/frontend.log:"
        tail -60 "$RUN_DIR/frontend.log"
        exit 1
    fi
fi

echo
echo "Frontend:    http://localhost:4200"
echo "Backend API: http://localhost:8080/api/v1/frameworks"
echo "Swagger UI:  http://localhost:8080/swagger-ui.html"
echo "Logs:        $RUN_DIR/{postgres,backend,frontend}.log"
echo "Stop with:   scripts/local-dev-down.sh"
