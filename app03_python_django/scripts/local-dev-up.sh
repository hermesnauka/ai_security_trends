#!/usr/bin/env bash
# Docker-less local dev stack for this machine only.
#
# docker-compose.yml is the real, portable way to run this project - use it
# if Docker is installed. This script exists because Docker isn't installed
# on THIS machine. It starts Postgres (shared instance across sibling apps -
# see app01_react/scripts for why) and the Django dev server from a local
# venv. Celery worker/beat are NOT started here - they don't run any real
# tasks yet (Phase 3/6 scope), so there's nothing to verify by running them
# outside Docker.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RUN_DIR="$ROOT_DIR/.local-dev"
mkdir -p "$RUN_DIR"

TOOLS="/c/Users/krish/tools"
PGBIN="$TOOLS/pgsql/bin"
PGDATA="C:\\Users\\krish\\tools\\pgdata"
PYTHON_HOME="/c/Users/krish/AppData/Local/Programs/Python/Python313"

export PATH="$PYTHON_HOME:$PYTHON_HOME/Scripts:$PGBIN:$PATH"

echo "== Postgres =="
if "$PGBIN/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; then
    echo "already running"
else
    "$PGBIN/pg_ctl.exe" -D "$PGDATA" -l "$RUN_DIR/postgres.log" -o "-p 5432" start
    timeout 30 bash -c 'until "'"$PGBIN"'/pg_isready.exe" -h 127.0.0.1 -p 5432 >/dev/null 2>&1; do sleep 1; done'
    echo "started"
fi

echo "== threatcompass role/database =="
"$PGBIN/psql.exe" -U securevision -h 127.0.0.1 -p 5432 -d postgres -c \
    "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'threatcompass') THEN CREATE ROLE threatcompass LOGIN PASSWORD \${POSTGRES_PASSWORD}; END IF; END \$\$;" >/dev/null 2>&1 || true
"$PGBIN/psql.exe" -U securevision -h 127.0.0.1 -p 5432 -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = 'threatcompass'" 2>/dev/null | grep -q 1 \
    || "$PGBIN/psql.exe" -U securevision -h 127.0.0.1 -p 5432 -d postgres -c "CREATE DATABASE threatcompass OWNER threatcompass;" >/dev/null 2>&1
echo "ready"

cd "$ROOT_DIR/backend_django"
if [ ! -d .venv ]; then
    echo "== Creating venv (first run) =="
    python -m venv .venv
    ".venv/Scripts/python.exe" -m pip install --upgrade pip >/dev/null
    ".venv/Scripts/python.exe" -m pip install \
        "Django>=5.2,<5.3" "djangorestframework>=3.16,<3.17" "drf-spectacular>=0.27,<0.28" \
        "djangorestframework-simplejwt>=5.3,<5.4" "psycopg[binary]>=3.2,<3.3" "django-redis>=5.4,<5.5" \
        "celery>=5.4,<5.5" "redis>=5.0,<6.0" "gunicorn>=22.0,<23.0" "python-dotenv>=1.0,<2.0"
fi

export DB_HOST=127.0.0.1 DB_PORT=5432 DB_NAME="${POSTGRES_DB}" DB_USER="${POSTGRES_USER}" DB_PASSWORD="${POSTGRES_PASSWORD}"

echo "== Migrations + seed =="
".venv/Scripts/python.exe" manage.py migrate --noinput
".venv/Scripts/python.exe" manage.py seed_frameworks

echo "== Django dev server (:8000) =="
if curl -sf http://localhost:8000/ >/dev/null 2>&1; then
    echo "already running"
else
    nohup ".venv/Scripts/python.exe" manage.py runserver 0.0.0.0:8000 --noreload > "$RUN_DIR/django.log" 2>&1 &
    echo $! > "$RUN_DIR/django.pid"
    echo "starting (PID $(cat "$RUN_DIR/django.pid")), waiting for :8000 ..."
    if timeout 30 bash -c 'until curl -sf http://localhost:8000/ >/dev/null 2>&1; do sleep 1; done'; then
        echo "up"
    else
        echo "TIMED OUT - tail of $RUN_DIR/django.log:"
        tail -60 "$RUN_DIR/django.log"
        exit 1
    fi
fi

echo
echo "Home:        http://localhost:8000/"
echo "API:         http://localhost:8000/api/v1/frameworks/"
echo "Swagger UI:  http://localhost:8000/api/v1/schema/swagger-ui/"
echo "Logs:        $RUN_DIR/{postgres,django}.log"
echo "Stop with:   scripts/local-dev-down.sh"
