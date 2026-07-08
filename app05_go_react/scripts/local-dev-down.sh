#!/usr/bin/env bash
# Companion to local-dev-up.sh - stops backend/frontend and shuts Postgres
# down cleanly. Safe to run even if some/all pieces are already stopped.
#
# Kills by the port's actual Windows PID (via netstat + taskkill), not by the
# PID file bash's `$!` recorded. On this Git Bash/MSYS setup `$!` after
# `npm run dev &` is the npm wrapper's PID, not the real node process -
# killing it leaves the actual server running.
#
# `go run ./cmd/api &` has a SIMILAR but distinct failure mode: `go run`
# compiles to a temp binary (named after the last path segment - "api.exe"
# here) and execs it as a CHILD of the `go` process. netstat's LISTENING
# entry can report the port under the parent `go.exe` PID rather than the
# child `api.exe` PID that's still holding the socket after the parent
# exits/is reaped - plain `taskkill //PID //F` on that PID alone was
# observed to leave `api.exe` running. `//T` (tree-kill, cascades to child
# processes) fixes this and is harmless for the npm/node case too.
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
        taskkill //PID "$pid" //F //T >/dev/null 2>&1
        echo "$name: stopped (PID $pid, port $port)"
    else
        echo "$name: nothing listening on port $port"
    fi
}

stop_by_port "Backend " 8080
stop_by_port "Frontend" 5173
# Belt-and-suspenders for the go-run child-process case: if the parent `go`
# process had already exited by the time stop_by_port ran, `api.exe` may
# have been reparented and missed by the tree-kill above.
taskkill //IM api.exe //F //T >/dev/null 2>&1 || true
rm -f "$RUN_DIR/backend.pid" "$RUN_DIR/frontend.pid"

echo "Postgres:"
if "$PGBIN/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    "$PGBIN/pg_ctl.exe" -D "$PGDATA" stop -m fast
else
    echo "  not running"
fi
