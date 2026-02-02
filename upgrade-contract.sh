#!/bin/bash

# Carregar variáveis do arquivo .env se ele existir
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

RPC_URL="${RPC_URL:-http://127.0.0.1:8545}"
PRIVATE_KEY="${PRIVATE_KEY}"
PROXY_ADDRESS="${NEXT_PUBLIC_CONTRACT_ADDRESS}"

# Detectar ProxyAdmin se não estiver no env
if [ -z "$PROXY_ADMIN_ADDRESS" ]; then
    DEPLOYMENT_FILE="broadcast/DeployPropertySale.s.sol/11155111/run-latest.json"
    if [ -f "$DEPLOYMENT_FILE" ] && command -v jq &> /dev/null; then
        PROXY_ADMIN_ADDRESS=$(jq -r '.transactions[] | select(.contractName == "ProxyAdmin") | .contractAddress' "$DEPLOYMENT_FILE" | tail -n 1)
    fi
fi

if [ -z "$PRIVATE_KEY" ] || [ -z "$PROXY_ADDRESS" ] || [ -z "$PROXY_ADMIN_ADDRESS" ]; then
    echo "Erro: Variáveis necessárias (PRIVATE_KEY, NEXT_PUBLIC_CONTRACT_ADDRESS, PROXY_ADMIN_ADDRESS) não encontradas."
    exit 1
fi

echo "🔄 Iniciando Upgrade do PropertySale..."
echo "📍 Proxy: $PROXY_ADDRESS"
echo "🛡️ Admin: $PROXY_ADMIN_ADDRESS"

# 1. Deploy nova implementação
echo "📦 Deployando nova implementação..."
NEW_IMPL=$(forge create src/contracts/PropertySale.sol:PropertySale \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --legacy \
    --broadcast \
    | grep "Deployed to:" | awk '{print $3}')

if [ -z "$NEW_IMPL" ]; then
    echo "❌ Erro no deploy da nova implementação."
    exit 1
fi

echo "✅ Nova implementação: $NEW_IMPL"

# 2. Fazer upgrade via ProxyAdmin
echo "🔄 Executando upgrade no contrato..."
cast send "$PROXY_ADMIN_ADDRESS" \
    "upgrade(address,address)" \
    "$PROXY_ADDRESS" \
    "$NEW_IMPL" \
    --rpc-url "$RPC_URL" \
    --private-key "$PRIVATE_KEY" \
    --legacy

echo "✅ Upgrade concluído com sucesso!"
