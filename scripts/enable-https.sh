#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
COMPOSE_FILE="$ROOT_DIR/docker-compose.prod.yml"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create it first." >&2
  exit 1
fi

EMAIL="$(grep -E '^LETSENCRYPT_EMAIL=' "$ENV_FILE" | cut -d= -f2- || true)"
if [ -z "$EMAIL" ]; then
  echo "LETSENCRYPT_EMAIL is missing in .env" >&2
  exit 1
fi

cd "$ROOT_DIR"

# Ensure nginx is up to serve the ACME challenge

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d nginx

# Request certificate

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" run --rm --entrypoint certbot certbot certonly \
  --webroot \
  --webroot-path /var/www/certbot \
  -d portifolio.cloud \
  -d www.portifolio.cloud \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email

# Enable SSL config after certs are issued

if [ -f "$ROOT_DIR/nginx/ssl.conf.template" ]; then
  cp "$ROOT_DIR/nginx/ssl.conf.template" "$ROOT_DIR/nginx/conf.d/ssl.conf"
fi

# Reload nginx to use the certs

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" exec nginx nginx -s reload

echo "HTTPS ativado. Acesse: https://portifolio.cloud/RWAImob"
