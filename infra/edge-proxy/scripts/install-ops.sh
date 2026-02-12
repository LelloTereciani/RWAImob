#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGROTATE_SRC="$ROOT_DIR/ops/logrotate-2days.conf"
LOGROTATE_DST="/etc/logrotate.d/rwaimob-and-docker-2days"
RENEW_SCRIPT="/root/RWAImob/scripts/renew-certs-and-reload-nginx.sh"
CLEANUP_SCRIPT="/root/RWAImob/scripts/cleanup-project-logs-2days.sh"

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root." >&2
  exit 1
fi

cp "$LOGROTATE_SRC" "$LOGROTATE_DST"

(crontab -l 2>/dev/null | grep -v 'renew-certs-and-reload-nginx.sh' || true; \
 echo "17 3,15 * * * $RENEW_SCRIPT >> /var/log/ssl-renew.log 2>&1") | crontab -

(crontab -l 2>/dev/null | grep -v 'cleanup-project-logs-2days.sh' || true; \
 echo "27 3 * * * $CLEANUP_SCRIPT >> /var/log/project-log-cleanup.log 2>&1") | crontab -

logrotate -f "$LOGROTATE_DST" || true

echo "Ops policy aplicada (cron + logrotate 2 dias)."
