#!/bin/bash

set -euo pipefail

# Carregar variáveis do arquivo .env se ele existir
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

RPC_URL="${RPC_URL:-https://eth-sepolia.g.alchemy.com/v2/YOUR_ALCHEMY_KEY}"
PRIVATE_KEY="${PRIVATE_KEY:-}"

if [ -z "$PRIVATE_KEY" ]; then
    echo "Erro: PRIVATE_KEY não definida no .env"
    exit 1
fi

if [ -z "$RPC_URL" ]; then
    echo "Erro: RPC_URL não definida no .env"
    exit 1
fi

echo "🚀 Fazendo deploy real do PropertySale na Sepolia..."
DEPLOY_LOG=$(forge script script/deploy/DeployPropertySale.s.sol --rpc-url "$RPC_URL" --broadcast)
CONTRACT_ADDRESS=$(echo "$DEPLOY_LOG" | grep "Contrato RWA pronto em:" | awk '{print $NF}')

if [ -z "$CONTRACT_ADDRESS" ]; then
    echo "Erro: não foi possível capturar o endereço do contrato."
    exit 1
fi

echo "✅ Contrato deployado em: $CONTRACT_ADDRESS"

# Atualizar .env com o novo endereço
sed -i "s/NEXT_PUBLIC_CONTRACT_ADDRESS=.*/NEXT_PUBLIC_CONTRACT_ADDRESS=$CONTRACT_ADDRESS/" .env

# Ajustar start block para acelerar indexação
if command -v cast &> /dev/null; then
    START_BLOCK=$(cast block-number --rpc-url "$RPC_URL")
    sed -i "s/PONDER_START_BLOCK=.*/PONDER_START_BLOCK=$START_BLOCK/" .env 2>/dev/null || echo "PONDER_START_BLOCK=$START_BLOCK" >> .env
    echo "✅ PONDER_START_BLOCK definido para $START_BLOCK"
fi

echo "✅ Deploy finalizado."
