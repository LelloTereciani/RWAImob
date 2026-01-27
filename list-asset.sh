#!/bin/bash

# Carregar variáveis do arquivo .env se ele existir
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

# Fallback para valores padrão se não estiverem no .env
RPC_URL="${RPC_URL:-http://127.0.0.1:8545}"
CHAIN_ID="31337"
PRIVATE_KEY="${PRIVATE_KEY}"

# Argumentos
LOCATION="$1"
PRICE_ETH="$2"
URI="$3"

if [ -z "$LOCATION" ] || [ -z "$PRICE_ETH" ] || [ -z "$URI" ]; then
    echo "Uso: $0 <Localização> <Preço em ETH> <URI da Imagem>"
    echo "Exemplo: $0 \"Penthouse em NY\" \"50\" \"https://exemplo.com/foto.png\""
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    echo "Erro: PRIVATE_KEY não definida no .env"
    exit 1
fi

# Converter Preço para Wei
if command -v python3 &> /dev/null; then
    PRICE_WEI=$(python3 -c "print(int($PRICE_ETH * 10**18))")
else
    PRICE_WEI=$(echo "$PRICE_ETH * 1000000000000000000" | bc)
fi

echo "📋 Listando Ativo:"
echo "  Localização: $LOCATION"
echo "  Preço: $PRICE_ETH ETH"

# Detectar endereço do contrato
DEPLOYMENT_FILE="broadcast/DeployPropertySale.s.sol/$CHAIN_ID/run-latest.json"

if [ -z "$NEXT_PUBLIC_CONTRACT_ADDRESS" ]; then
    if [ -f "$DEPLOYMENT_FILE" ] && command -v jq &> /dev/null; then
        CONTRACT_ADDRESS=$(jq -r '.transactions[] | select(.contractName == "TransparentUpgradeableProxy") | .contractAddress' "$DEPLOYMENT_FILE" | tail -n 1)
    fi
else
    CONTRACT_ADDRESS="$NEXT_PUBLIC_CONTRACT_ADDRESS"
fi

if [ -z "$CONTRACT_ADDRESS" ] || [ "$CONTRACT_ADDRESS" == "null" ]; then
    echo "Erro: Não foi possível detectar o endereço do contrato. Defina NEXT_PUBLIC_CONTRACT_ADDRESS no .env"
    exit 1
fi

echo "📍 Contrato: $CONTRACT_ADDRESS"

# Exportar para o script Foundry
export PROPERTYSALE_ADDRESS="$CONTRACT_ADDRESS"
export LOCATION="$LOCATION"
export PRICE="$PRICE_WEI"
export URI="$URI"
export PRIVATE_KEY="$PRIVATE_KEY"

forge script script/interact/ListProperty.s.sol:ListProperty \
    --rpc-url "$RPC_URL" \
    --broadcast \
    --legacy

echo "✅ Concluído!"
