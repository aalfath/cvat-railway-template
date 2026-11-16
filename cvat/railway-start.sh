#!/usr/bin/env bash
# Runs as root: prepare the data volume and nginx port, then drop to "django".
set -euo pipefail

DATA_DIR=/home/django/data
mkdir -p "$DATA_DIR"
# Railway volumes mount as root. Hand them to the django user once.
if [ "$(stat -c %u "$DATA_DIR")" != "1000" ]; then
    echo "railway-start: fixing ownership of $DATA_DIR"
    chown -R 1000:1000 "$DATA_DIR"
fi

# supervisord (as django) logs to /dev/stdout. The container's stdout/stderr
# belong to root, so hand them to uid 1000; if that isn't possible, log to files.
chown 1000:1000 /proc/self/fd/1 /proc/self/fd/2 2>/dev/null || true
if ! setpriv --reuid=1000 --regid=1000 --init-groups sh -c ': > /dev/stdout' 2>/dev/null; then
    echo "railway-start: /dev/stdout not writable by django, supervisord logs go to /tmp/supervisord"
    sed -i 's#^logfile = /dev/stdout#logfile = /tmp/supervisord/supervisord.log#' /opt/cvat/supervisord/reusable/supervisord.conf
    sed -i 's#^stdout_logfile=/dev/stdout#stdout_logfile=AUTO#; /^stdout_logfile_maxbytes=0/d' /opt/cvat/supervisord/railway.conf
fi

PORT="${PORT:-8080}"
sed -i -E "s/listen [0-9]+;/listen ${PORT};/; s/listen \[::\]:[0-9]+;/listen [::]:${PORT};/" /etc/nginx/nginx.conf

exec setpriv --reuid=1000 --regid=1000 --init-groups env HOME=/home/django USER=django \
    /usr/local/bin/railway-run.sh "$@"
