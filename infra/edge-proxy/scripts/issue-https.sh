#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/docker-compose.yml"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE" >&2
  exit 1
fi

EMAIL="$(grep -E '^LETSENCRYPT_EMAIL=' "$ENV_FILE" | cut -d= -f2- || true)"
if [ -z "$EMAIL" ]; then
  echo "LETSENCRYPT_EMAIL is missing in $ENV_FILE" >&2
  exit 1
fi

if ! docker network inspect edge >/dev/null 2>&1; then
  docker network create edge
fi

docker compose -f "$COMPOSE_FILE" up -d nginx

docker compose --profile manual-certbot -f "$COMPOSE_FILE" run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  -d portifolio.cloud -d www.portifolio.cloud \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  --non-interactive

docker compose -f "$COMPOSE_FILE" exec -T nginx nginx -s reload

echo "HTTPS emitido e nginx recarregado."
