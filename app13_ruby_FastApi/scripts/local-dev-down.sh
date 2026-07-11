#!/usr/bin/env bash
# Does NOT stop the shared local Postgres instance (../../CLAUDE.md) — other
# apps on this machine may still be using it. This script only exists for
# symmetry with local-dev-up.sh and to stop this app's own backend/frontend
# dev processes if they were started in the background by the developer.
set -euo pipefail

echo "rubyguard: nothing app-specific to tear down — Postgres is shared, see ../../CLAUDE.md."
echo "Stop your own backend (Puma)/frontend (esbuild --watch) processes manually if still running."
