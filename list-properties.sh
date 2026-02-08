#!/bin/bash

set -euo pipefail

# Carregar variáveis do arquivo .env se ele existir
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

PONDER_URL="${PONDER_URL:-http://127.0.0.1:42069}"

# Ajustar endpoint GraphQL conforme o tipo de URL
if [[ "$PONDER_URL" == */graphql ]]; then
  GRAPHQL_URL="$PONDER_URL"
elif [[ "$PONDER_URL" == */api ]]; then
  GRAPHQL_URL="$PONDER_URL"
else
  GRAPHQL_URL="$PONDER_URL/graphql"
fi

if ! command -v jq &> /dev/null; then
    echo "Erro: jq não encontrado. Instale jq para usar este script."
    exit 1
fi

response=$(curl -s -H 'content-type: application/json' \
  --data '{"query":"{ propertys { items { id owner price forSale listedAt soldAt location locationHash } } }"}' \
  "$GRAPHQL_URL")

echo "$response" | jq -r '
  .data.propertys.items[]
  | "ID: \(.id) | Owner: \(.owner) | Price: \(.price) | ForSale: \(.forSale) | Location: \(.location) | LocationHash: \(.locationHash) | ListedAt: \(.listedAt) | SoldAt: \(.soldAt)"'
