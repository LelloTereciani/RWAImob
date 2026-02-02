#!/bin/bash

set -euo pipefail

# Carregar variáveis do arquivo .env se ele existir
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

PONDER_URL="${PONDER_URL:-http://127.0.0.1:42069}"

if ! command -v jq &> /dev/null; then
    echo "Erro: jq não encontrado. Instale jq para usar este script."
    exit 1
fi

response=$(curl -s -H 'content-type: application/json' \
  --data '{"query":"{ propertys { items { id owner price forSale listedAt soldAt location locationHash } } }"}' \
  "$PONDER_URL/graphql")

echo "$response" | jq -r '
  .data.propertys.items[]
  | "ID: \(.id) | Owner: \(.owner) | Price: \(.price) | ForSale: \(.forSale) | Location: \(.location) | LocationHash: \(.locationHash) | ListedAt: \(.listedAt) | SoldAt: \(.soldAt)"'
