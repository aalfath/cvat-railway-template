#!/bin/sh
# Railway volumes mount as root: fix ownership, then run Kvrocks as its own user.
set -eu
mkdir -p /var/lib/kvrocks /var/run/kvrocks
chown -R kvrocks:kvrocks /var/lib/kvrocks /var/run/kvrocks
if [ -z "${KVROCKS_PASSWORD:-}" ]; then
    echo "kvrocks-start: KVROCKS_PASSWORD is required" >&2
    exit 1
fi
exec setpriv --reuid=kvrocks --regid=kvrocks --init-groups \
    kvrocks -c /etc/kvrocks/kvrocks.conf \
    --dir /var/lib/kvrocks \
    --pidfile /var/run/kvrocks/kvrocks.pid \
    --bind "0.0.0.0 ::" \
    --port "${KVROCKS_PORT:-6666}" \
    --requirepass "$KVROCKS_PASSWORD" \
    --compact-cron "0 3 * * *"
