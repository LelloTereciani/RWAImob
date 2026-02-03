#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
COMPOSE_FILE="$ROOT_DIR/docker-compose.prod.yml"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create it first." >&2
  exit 1
fi

cd "$ROOT_DIR"

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" run --rm certbot renew \
  --webroot -w /var/www/certbot

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec nginx nginx -s reload

echo "Certificados renovados e nginx recarregado."
