#!/usr/bin/env bash
set -euo pipefail

LOCK_FILE="/tmp/ssl-renew.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "[$(date -Is)] another renew process is running; skipping"
  exit 0
fi

cd /root/RWAImob
COMPOSE_FILE="docker-compose.prod.yml"

echo "[$(date -Is)] cert renew start"
docker compose --profile manual-certbot -f "$COMPOSE_FILE" run --rm --entrypoint certbot certbot \
  renew --webroot -w /var/www/certbot --quiet

echo "[$(date -Is)] nginx reload"
docker compose -f "$COMPOSE_FILE" exec -T nginx nginx -s reload

echo "[$(date -Is)] cert renew finished"
