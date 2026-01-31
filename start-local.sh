#!/bin/bash

# Cores para o output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Iniciando RWAImob Local Environment ===${NC}"

# 1. Subir Infraestrutura
RESET_CHAIN="n"
if [ -f .anvil/state.json ]; then
    read -p "Deseja recriar o estado da blockchain (Anvil)? Isso apagará imóveis e histórico. (s/n): " RESET_CHAIN
fi

echo -e "${GREEN}[1/6] Subindo Docker (Anvil, Postgres & Indexer)...${NC}"
if [ "$RESET_CHAIN" = "s" ] || [ "$RESET_CHAIN" = "S" ]; then
    rm -f .anvil/state.json
    docker compose up -d --force-recreate anvil
    docker compose up -d db indexer
else
    docker compose up -d
fi

# Esperar Anvil estar pronto
echo -e "${BLUE}Aguardando Anvil iniciar na porta 8545...${NC}"
until curl -s localhost:8545 > /dev/null; do
  sleep 1
done

# 2. Setup de Ambiente
echo -e "${GREEN}[2/6] Configurando variáveis de ambiente...${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo ".env criado a partir do template."
fi

# Carregar segredos do .env
export $(cat .env | grep -v '#' | xargs)

# 3. Deploy dos Contratos (opcional)
REDEPLOY_CONTRACTS="n"
if [ "$RESET_CHAIN" = "s" ] || [ "$RESET_CHAIN" = "S" ]; then
    REDEPLOY_CONTRACTS="s"
elif [ -z "$NEXT_PUBLIC_CONTRACT_ADDRESS" ]; then
    REDEPLOY_CONTRACTS="s"
else
    read -p "Deseja fazer redeploy dos contratos? (s/n): " REDEPLOY_CONTRACTS
fi

if [ "$REDEPLOY_CONTRACTS" = "s" ] || [ "$REDEPLOY_CONTRACTS" = "S" ]; then
    echo -e "${GREEN}[3/6] Fazendo deploy do PropertySale no Anvil...${NC}"
    DEPLOY_LOG=$(forge script script/deploy/DeployPropertySale.s.sol --rpc-url http://localhost:8545 --broadcast)
    CONTRACT_ADDRESS=$(echo "$DEPLOY_LOG" | grep "Contrato RWA pronto em:" | awk '{print $NF}')

    echo -e "${BLUE}Contrato deployado em: $CONTRACT_ADDRESS${NC}"

    # Atualizar .env com o novo endereço
    sed -i "s/NEXT_PUBLIC_CONTRACT_ADDRESS=.*/NEXT_PUBLIC_CONTRACT_ADDRESS=$CONTRACT_ADDRESS/" .env

    # Semeia imoveis iniciais
    read -p "Deseja atualizar (recriar) os imóveis iniciais do marketplace? (s/n): " resposta_seed
    if [ "$resposta_seed" = "s" ] || [ "$resposta_seed" = "S" ]; then
        ./seed-assets.sh
    else
        echo "⏭️  Mantendo imóveis existentes."
    fi
else
    echo -e "${BLUE}Pulando deploy. Mantendo contrato e imóveis existentes.${NC}"
fi

# 4. Sincronizar ABI (Garante que o Frontend e Indexador usem o ABI correto e limpo)
echo -e "${GREEN}[4/6] Sincronizando ABI dos contratos...${NC}"
if [ -f out/PropertySale.sol/PropertySale.json ]; then
    jq '.abi' out/PropertySale.sol/PropertySale.json > frontend/src/abis/PropertySaleAbi.json
    echo "export const PropertySaleAbi = $(cat frontend/src/abis/PropertySaleAbi.json) as const;" > frontend/src/abis/PropertySaleAbi.ts
    cp frontend/src/abis/PropertySaleAbi.ts indexer/abis/PropertySaleAbi.ts
    echo -e "${BLUE}ABI sincronizado com sucesso!${NC}"
else
    echo -e "${BLUE}ABI não encontrado em out/. Pulando sincronização.${NC}"
fi

# 5. Recriar Indexador (Ponder) para pegar ABI/endereços atualizados
echo -e "${GREEN}[5/6] Recriando Indexador Ponder (Docker)...${NC}"
docker compose up -d indexer

# 6. Iniciar Frontend (Next.js)
echo -e "${GREEN}[6/6] Iniciando Frontend Next.js...${NC}"
cd frontend
npm install
echo -e "${BLUE}O Marketplace estará disponível em http://localhost:3000${NC}"
echo -e "${BLUE}Pressione Ctrl+C para encerrar todos os serviços.${NC}"

# Função para encerrar tudo ao sair
trap "docker compose down; exit" INT TERM EXIT

npm run dev
