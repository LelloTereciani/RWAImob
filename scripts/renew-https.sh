#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EDGE_SCRIPT="$ROOT_DIR/infra/edge-proxy/scripts/renew-https.sh"

if [ ! -x "$EDGE_SCRIPT" ]; then
  echo "Missing $EDGE_SCRIPT" >&2
  exit 1
fi

"$EDGE_SCRIPT"

echo "Certificados renovados no edge proxy."
