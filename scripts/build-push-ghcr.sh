#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Missing $ENV_FILE. Create it first." >&2
  exit 1
fi

set -a
source "$ENV_FILE"
set +a

: "${FRONTEND_IMAGE:?Missing FRONTEND_IMAGE in .env}"
: "${PONDER_IMAGE:?Missing PONDER_IMAGE in .env}"

TAG="${IMAGE_TAG:-$(git -C "$ROOT_DIR" rev-parse --short HEAD)}"

frontend_base="${FRONTEND_IMAGE%:*}"
ponder_base="${PONDER_IMAGE%:*}"

frontend_latest="${frontend_base}:latest"
frontend_tagged="${frontend_base}:${TAG}"
ponder_latest="${ponder_base}:latest"
ponder_tagged="${ponder_base}:${TAG}"

docker build \
  --build-arg NEXT_PUBLIC_PONDER_URL="${NEXT_PUBLIC_PONDER_URL:-/RWAImob/api}" \
  --build-arg NEXT_PUBLIC_CONTRACT_ADDRESS="${NEXT_PUBLIC_CONTRACT_ADDRESS}" \
  --build-arg NEXT_PUBLIC_WAGMI_PROJECT_ID="${NEXT_PUBLIC_WAGMI_PROJECT_ID}" \
  --build-arg NEXT_PUBLIC_SEPOLIA_RPC_URL="${NEXT_PUBLIC_SEPOLIA_RPC_URL}" \
  -t "$frontend_latest" \
  -t "$frontend_tagged" \
  "$ROOT_DIR/frontend"

docker build \
  -t "$ponder_latest" \
  -t "$ponder_tagged" \
  "$ROOT_DIR/indexer"

docker push "$frontend_latest"
docker push "$frontend_tagged"
docker push "$ponder_latest"
docker push "$ponder_tagged"

echo "Images pushed:"
echo "  $frontend_latest"
echo "  $frontend_tagged"
echo "  $ponder_latest"
echo "  $ponder_tagged"
