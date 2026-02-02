#!/bin/bash

# Cores para o output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Iniciando RWAImob Local Environment ===${NC}"

# 1. Setup de Ambiente (antes de subir containers)
echo -e "${GREEN}[1/4] Configurando variáveis de ambiente...${NC}"
if [ ! -f .env ]; then
    cp .env.example .env
    echo ".env criado a partir do template."
fi

# Carregar segredos do .env
export $(cat .env | grep -v '#' | xargs)

# 2. Subir Infraestrutura
echo -e "${GREEN}[2/4] Subindo Docker (Postgres & Indexer)...${NC}"
docker compose up -d db indexer

# 3. Sincronizar ABI (Garante que o Frontend e Indexador usem o ABI correto e limpo)
echo -e "${GREEN}[3/4] Sincronizando ABI dos contratos...${NC}"
if [ -f out/PropertySale.sol/PropertySale.json ]; then
    jq '.abi' out/PropertySale.sol/PropertySale.json > frontend/src/abis/PropertySaleAbi.json
    echo "export const PropertySaleAbi = $(cat frontend/src/abis/PropertySaleAbi.json) as const;" > frontend/src/abis/PropertySaleAbi.ts
    cp frontend/src/abis/PropertySaleAbi.ts indexer/abis/PropertySaleAbi.ts
    echo -e "${BLUE}ABI sincronizado com sucesso!${NC}"
else
    echo -e "${BLUE}ABI não encontrado em out/. Pulando sincronização.${NC}"
fi

# 4. Recriar Indexador (Ponder) para pegar ABI/endereços atualizados
echo -e "${GREEN}[4/5] Recriando Indexador Ponder (Docker)...${NC}"
docker compose up -d indexer

# 5. Iniciar Frontend (Next.js)
echo -e "${GREEN}[5/5] Iniciando Frontend Next.js...${NC}"
cd frontend
npm install
echo -e "${BLUE}O Marketplace estará disponível em http://localhost:3000${NC}"
echo -e "${BLUE}Pressione Ctrl+C para encerrar o frontend.${NC}"
npm run dev
