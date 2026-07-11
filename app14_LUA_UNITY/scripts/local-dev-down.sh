#!/usr/bin/env bash
# Does NOT stop the shared local Postgres instance (../../CLAUDE.md) — other
# apps on this machine may still be using it. This script only exists for
# symmetry with local-dev-up.sh and to stop this app's own backend dev
# process if it was started in the background by the developer. There is no
# frontend dev process to stop — Unity is run from the Editor, not a CLI
# watch process.
set -euo pipefail

echo "luaguard: nothing app-specific to tear down — Postgres is shared, see ../../CLAUDE.md."
echo "Stop your own backend (openresty) process manually if still running."
