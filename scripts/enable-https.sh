#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"
EDGE_DIR="$ROOT_DIR/infra/edge-proxy"
EDGE_ENV_FILE="$EDGE_DIR/.env"
EDGE_SCRIPT="$EDGE_DIR/scripts/issue-https.sh"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create it first." >&2
  exit 1
fi

if [ ! -x "$EDGE_SCRIPT" ]; then
  echo "Missing $EDGE_SCRIPT" >&2
  exit 1
fi

EMAIL="$(grep -E '^LETSENCRYPT_EMAIL=' "$ENV_FILE" | cut -d= -f2- || true)"
if [ -z "$EMAIL" ]; then
  echo "LETSENCRYPT_EMAIL is missing in .env" >&2
  exit 1
fi

mkdir -p "$EDGE_DIR"
printf 'LETSENCRYPT_EMAIL=%s\n' "$EMAIL" > "$EDGE_ENV_FILE"

"$EDGE_SCRIPT"

echo "HTTPS ativado no edge proxy. Acesse: https://portifolio.cloud/RWAImob"
