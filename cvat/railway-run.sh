#!/usr/bin/env bash
# Runs as the django user: defaults, migrations, first admin, then supervisord.
set -euo pipefail
cd /home/django

# Fixed settings (override any of them with a service variable).
export ALLOWED_HOSTS="${ALLOWED_HOSTS:-*}"
export CVAT_HOST="${CVAT_HOST:-${RAILWAY_PUBLIC_DOMAIN:-localhost}}"
if [ -z "${CVAT_BASE_URL:-}" ]; then
    if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
        export CVAT_BASE_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
    else
        export CVAT_BASE_URL="http://${CVAT_HOST}:${PORT:-8080}"
    fi
fi
export CVAT_POSTGRES_PORT="${CVAT_POSTGRES_PORT:-5432}"
export CVAT_REDIS_INMEM_PORT="${CVAT_REDIS_INMEM_PORT:-6379}"
export CVAT_REDIS_INMEM_PASSWORD="${CVAT_REDIS_INMEM_PASSWORD:-}"
export CVAT_REDIS_ONDISK_PORT="${CVAT_REDIS_ONDISK_PORT:-6666}"
export CVAT_REDIS_ONDISK_PASSWORD="${CVAT_REDIS_ONDISK_PASSWORD:-}"
export CVAT_OPA_URL="${CVAT_OPA_URL:-http://127.0.0.1:8181}"
export CVAT_LOG_IMPORT_ERRORS="${CVAT_LOG_IMPORT_ERRORS:-true}"
export CVAT_ALLOW_STATIC_CACHE="${CVAT_ALLOW_STATIC_CACHE:-no}"
export SMOKESCREEN_OPTS="${SMOKESCREEN_OPTS:-}"
export NUMPROCS="${CVAT_SERVER_PROCESSES:-2}"
# Proxies in front of uvicorn: Railway's edge (CVAT_NUM_PROXIES, default 1)
# plus the nginx inside this container.
export CVAT_NUM_PROXIES=$(( ${CVAT_NUM_PROXIES:-1} + 1 ))
export CVAT_SUPERVISORD_INCLUDES=""

# Migrations (Postgres, Redis) and periodic jobs: CVAT's own init step.
/opt/cvat/backend_entrypoint.sh init

# First administrator, created once from CVAT_ADMIN_USERNAME / CVAT_ADMIN_PASSWORD.
if [ -n "${CVAT_ADMIN_PASSWORD:-}" ]; then
    django-admin shell -c '
import os
from django.contrib.auth import get_user_model
User = get_user_model()
name = os.environ.get("CVAT_ADMIN_USERNAME") or "admin"
if not User.objects.filter(username=name).exists():
    User.objects.create_superuser(name, os.environ.get("CVAT_ADMIN_EMAIL", ""), os.environ["CVAT_ADMIN_PASSWORD"])
    print(f"railway-run: created administrator {name!r}")
else:
    print(f"railway-run: administrator {name!r} already exists, password left unchanged")
'
fi

django-admin collectstatic --no-input >/dev/null
echo "railway-run: starting CVAT (server, workers, OPA, UI) on port ${PORT:-8080}"
exec supervisord -c /opt/cvat/supervisord/railway.conf
