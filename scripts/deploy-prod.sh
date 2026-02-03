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

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull --ignore-pull-failures

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d --build

echo "Deploy completo. Acesse: http://portifolio.cloud/RWAImob"
