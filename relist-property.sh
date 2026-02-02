#!/bin/bash

# Script para re-listar uma propriedade
# Uso: ./relist-property.sh <propertyId> <newPrice>

PROPERTY_ID="$1"
NEW_PRICE_ETH="$2"

if [ -z "$PROPERTY_ID" ] || [ -z "$NEW_PRICE_ETH" ]; then
    echo "Uso: $0 <PropertyID> <Novo Preço em ETH>"
    echo "Exemplo: $0 1 2.5"
    exit 1
fi

# Converter preço para Wei
if command -v python3 &> /dev/null; then
    NEW_PRICE_WEI=$(python3 -c "print(int($NEW_PRICE_ETH * 10**18))")
else
    NEW_PRICE_WEI=$(echo "$NEW_PRICE_ETH * 1000000000000000000" | bc)
fi

echo "🏠 Re-listando Propriedade #$PROPERTY_ID"
echo "  Novo Preço: $NEW_PRICE_ETH ETH ($NEW_PRICE_WEI Wei)"
echo ""

if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

RPC_URL="${RPC_URL:-https://ethereum-sepolia-rpc.publicnode.com}"
PRIVATE_KEY="${PRIVATE_KEY}"
CONTRACT_ADDRESS="${NEXT_PUBLIC_CONTRACT_ADDRESS}"

if [ -z "$PRIVATE_KEY" ] || [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Erro: PRIVATE_KEY e NEXT_PUBLIC_CONTRACT_ADDRESS são obrigatórios no .env"
    exit 1
fi

echo "📍 Contrato: $CONTRACT_ADDRESS"
echo "🔄 Enviando transação relistProperty..."

cast send "$CONTRACT_ADDRESS" \
    "relistProperty(uint256,uint256)" \
    "$PROPERTY_ID" \
    "$NEW_PRICE_WEI" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --legacy

echo "✅ Relistagem enviada!"
