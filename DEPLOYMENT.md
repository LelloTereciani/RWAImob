# Deployment Guide: RWAImob

Este guia detalha como preparar e implantar o projeto RWAImob em ambientes de Produção e VPS.

## 1. Variáveis de Ambiente
Copie o arquivo `.env.example` para `.env` e preencha as chaves:
- `POSTGRES_USER/PASSWORD/DB`: Credenciais do banco.
- `PONDER_RPC_URL_1`: RPC da rede alvo (Base, Polygon, Mainnet).
- `NEXT_PUBLIC_WAGMI_PROJECT_ID`: Seu ID do WalletConnect Cloud.

## 2. Deploy do Frontend (Vercel)
O frontend está na pasta `/frontend`.
1. Conecte seu repositório à Vercel.
2. Defina a **Root Directory** como `frontend`.
3. Adicione as Environment Variables listadas no `.env.example`.
4. O Build Command padrão `npm run build` deve funcionar.

## 3. Deploy do Indexador (VPS)
Recomendamos rodar o Ponder em uma VPS (Docker) para garantir persistência.
1. Na VPS, execute `docker compose up -d`.
2. Certifique-se de que o Ponder aponte para o Postgres do Docker via `DATABASE_URL`.
3. Execute `cd indexer && npm install && npm run build && npm run start`.

## 4. Contratos Inteligentes
Certifique-se de que os contratos estejam deployados na rede correta e que os endereços no `ponder.config.ts` e `frontend/src/wagmi.ts` estejam atualizados.
