#!/usr/bin/env bash
# Companion to local-dev-up.sh - stops the Django dev server and shuts the
# shared Postgres instance down cleanly. Safe to run even if some/all pieces
# are already stopped.
#
# Postgres is SHARED across sibling apps on this machine - stopping it here
# also stops it for any other app (e.g. app01_react, app02_angular)
# currently using it.
set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.local-dev"
PGBIN="/c/Users/krish/tools/pgsql/bin"
PGDATA="C:\\Users\\krish\\tools\\pgdata"

pid="$(netstat -ano | grep ":8000 " | grep LISTENING | awk '{print $NF}' | head -1)"
if [ -n "${pid:-}" ]; then
    taskkill //PID "$pid" //F >/dev/null 2>&1
    echo "Django: stopped (PID $pid, port 8000)"
else
    echo "Django: nothing listening on port 8000"
fi
rm -f "$RUN_DIR/django.pid"

echo "Postgres (shared instance):"
if "$PGBIN/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    "$PGBIN/pg_ctl.exe" -D "$PGDATA" stop -m fast
else
    echo "  not running"
fi
