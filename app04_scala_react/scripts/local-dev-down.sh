#!/usr/bin/env bash
# Companion to local-dev-up.sh - stops backend/frontend and shuts Postgres
# down cleanly. Safe to run even if some/all pieces are already stopped.
#
# Kills by the port's actual Windows PID (via netstat + taskkill), not by the
# PID file bash's `$!` recorded. On this Git Bash/MSYS setup `$!` after
# `npm run dev &`/`sbt run &` is the npm/sbt wrapper's PID, not the real
# node/JVM process - killing it leaves the actual server running.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.local-dev"
PGBIN="/c/Users/krish/tools/pgsql/bin"
PGDATA="C:\\Users\\krish\\tools\\pgdata"

stop_by_port() {
    local name="$1" port="$2"
    local pid
    pid="$(netstat -ano | grep ":$port " | grep LISTENING | awk '{print $NF}' | head -1)"
    if [ -n "${pid:-}" ]; then
        taskkill //PID "$pid" //F >/dev/null 2>&1
        echo "$name: stopped (PID $pid, port $port)"
    else
        echo "$name: nothing listening on port $port"
    fi
}

stop_by_port "Backend " 8080
stop_by_port "Frontend" 5173
rm -f "$RUN_DIR/backend.pid" "$RUN_DIR/frontend.pid"

echo "Postgres:"
if "$PGBIN/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    "$PGBIN/pg_ctl.exe" -D "$PGDATA" stop -m fast
else
    echo "  not running"
fi
