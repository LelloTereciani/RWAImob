#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
COMPOSE_FILE="$ROOT_DIR/docker-compose.prod.yml"
EDGE_SCRIPT="$ROOT_DIR/infra/edge-proxy/scripts/deploy-edge.sh"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create it first." >&2
  exit 1
fi

cd "$ROOT_DIR"

if command -v systemctl >/dev/null 2>&1; then
  systemctl enable --now docker >/dev/null 2>&1 || true
fi

if ! docker network inspect edge >/dev/null 2>&1; then
  docker network create edge
fi

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" pull --ignore-pull-failures

docker compose -f "$COMPOSE_FILE" --env-file "$ENV_FILE" up -d postgres ponder frontend

if [ -x "$EDGE_SCRIPT" ]; then
  "$EDGE_SCRIPT"
fi

echo "Deploy completo. Acesse: https://portifolio.cloud/RWAImob"
