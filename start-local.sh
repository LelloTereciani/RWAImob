#!/bin/bash

# Cores para o output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Iniciando RWAImob Local Environment ===${NC}"

# 1. Subir Infraestrutura
echo -e "${GREEN}[1/5] Subindo Docker (Anvil & Postgres)...${NC}"
docker compose up -d

# Esperar Anvil estar pronto
echo -e "${BLUE}Aguardando Anvil iniciar na porta 8545...${NC}"
until curl -s localhost:8545 > /dev/null; do
  sleep 1
done

# 2. Setup de Ambiente
echo -e "${GREEN}[2/5] Configurando variáveis de ambiente...${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo ".env criado a partir do template."
fi

# Carregar segredos do .env
export $(cat .env | grep -v '#' | xargs)

# 3. Deploy dos Contratos
echo -e "${GREEN}[3/5] Fazendo deploy do PropertySale no Anvil...${NC}"
DEPLOY_LOG=$(forge script script/deploy/DeployPropertySale.s.sol --rpc-url http://localhost:8545 --broadcast)
CONTRACT_ADDRESS=$(echo "$DEPLOY_LOG" | grep "Contrato RWA pronto em:" | awk '{print $NF}')

echo -e "${BLUE}Contrato deployado em: $CONTRACT_ADDRESS${NC}"

# Atualizar .env com o novo endereço
sed -i "s/NEXT_PUBLIC_CONTRACT_ADDRESS=.*/NEXT_PUBLIC_CONTRACT_ADDRESS=$CONTRACT_ADDRESS/" .env

# Semeia imoveis iniciais
./seed-assets.sh

# 4. Sincronizar ABI (Garante que o Frontend e Indexador usem o ABI correto e limpo)
echo -e "${GREEN}[4/5] Sincronizando ABI dos contratos...${NC}"
jq '.abi' out/PropertySale.sol/PropertySale.json > frontend/src/abis/PropertySaleAbi.json
echo "export const PropertySaleAbi = $(cat frontend/src/abis/PropertySaleAbi.json) as const;" > frontend/src/abis/PropertySaleAbi.ts
cp frontend/src/abis/PropertySaleAbi.ts indexer/abis/PropertySaleAbi.ts
echo -e "${BLUE}ABI sincronizado com sucesso!${NC}"

# 5. Iniciar Indexador (Ponder)
echo -e "${GREEN}[5/5] Iniciando Indexador Ponder em background...${NC}"
cd indexer
npm install
# O Ponder roda em modo dev e recarrega automaticamente
npm run dev > ../indexer.log 2>&1 &
INDEXER_PID=$!
cd ..

# 6. Iniciar Frontend (Next.js)
echo -e "${GREEN}[6/6] Iniciando Frontend Next.js...${NC}"
cd frontend
npm install
echo -e "${BLUE}O Marketplace estará disponível em http://localhost:3000${NC}"
echo -e "${BLUE}Pressione Ctrl+C para encerrar todos os serviços.${NC}"

# Função para encerrar tudo ao sair
trap "kill $INDEXER_PID; docker compose down; exit" INT TERM EXIT

npm run dev
