# 🏠 RWA Real Estate 🚀

Bem-vindo ao **RWA Real Estate**, uma plataforma descentralizada de ponta para a tokenização e negociação de ativos imobiliários do mundo real (RWA). 🌐

Este projeto utiliza o poder da **Blockchain** para trazer liquidez, transparência e segurança ao mercado imobiliário.

> ⚠️ **Projeto de estudos**: este repositório é voltado para aprendizado, prototipagem e experimentação. Não é um produto pronto para produção.

---

## 👨‍💻 Autor
**Wesley Rodrigues Tereciani** 
— *Desenvolvedor e Visionário RWA* 💎
— *Especialista Blockchain* 💎

---

## ✨ Funcionalidades Incríveis

- 🏗️ **Tokenização de Ativos**: Transforme imóveis em NFTs (ERC721) únicos.
- 💰 **Marketplace Descentralizado**: Compre e venda propriedades usando ETH diretamente.
- 🤝 **Sistema de Ofertas**: Faça propostas em imóveis e gerencie negociações de forma transparente.
- 🛡️ **Segurança de Elite**: Contratos baseados nos padrões OpenZeppelin e protegidos contra reentrância.
- 📊 **Indexação em Tempo Real**: Monitoramento ultra-rápido via Ponder para dados precisos.
- 🎨 **Interface Premium**: Dashboard moderno com Glassmorphism e micro-animações.

---

## 🛠️ Tecnologias Utilizadas

- **Smart Contracts**: Solidity ⛓️ & Foundry 🔨
- **Indexação**: Ponder 📈
- **Frontend**: Next.js ⚛️ & Tailwind CSS 🎨
- **Web3**: Wagmi & RainbowKit 🌈
- **Infra**: Docker 🐳 & PostgreSQL 🐘

---

## 🌐 Rede Sepolia (Testnet) — Uso Exclusivo

Este projeto foi configurado **exclusivamente** para a **testnet Sepolia**. Não use em mainnet.
Garanta no `.env`:

- `PONDER_RPC_URL_11155111` — URL do nó RPC Sepolia (use nó público como fallback: `https://ethereum-sepolia-rpc.publicnode.com`)
- `RPC_URL`
- `NEXT_PUBLIC_CONTRACT_ADDRESS`
- `NEXT_PUBLIC_SEPOLIA_RPC_URL`
- `NEXT_PUBLIC_PONDER_URL`

> ⚠️ **Chaves Alchemy expiram ou atingem limites de taxa.** Use sempre um nó público como fallback para evitar que o Ponder entre em loop de erro e consuma CPU excessivamente.

---

## 🚰 Faucet Sepolia (Test ETH)

Para obter ETH de teste na Sepolia, use um faucet:

- Alchemy Sepolia Faucet: https://www.alchemy.com/dapps/sepolia-faucet
- Chainlink Faucet (Sepolia): https://chain.link/faucets
- Alchemy Testnet Faucets (lista): https://www.alchemy.com/faucets

> Você só precisa do **endereço público** da carteira (não compartilhe a chave privada).

---

## 🚀 Como Iniciar (Ambiente Local)

A forma mais rápida de subir o **ambiente local** (Postgres + Ponder via Docker + Frontend local) é usando o script:

```bash
# ⚡ Apenas um comando para subir tudo!
./start-local.sh
```

> Observação: em produção, o app (`docker-compose.prod.yml`) roda separado do edge proxy (`infra/edge-proxy/docker-compose.yml`).

---

## 🚀 Deploy Real na Sepolia (Passo a Passo)

1) **Deploy do contrato**
```bash
./deploy-sepolia.sh
```

2) **Build & push das imagens (GHCR)**
```bash
bash scripts/build-push-ghcr.sh
```

3) **Configurar .env na VPS**
Garanta:
- `FRONTEND_IMAGE=ghcr.io/SEU_USUARIO/rwaimob-frontend:latest`
- `PONDER_IMAGE=ghcr.io/SEU_USUARIO/rwaimob-ponder:latest`
- `NEXT_PUBLIC_PONDER_URL=/RWAImob/api`

4) **Subir app stack**
```bash
bash scripts/deploy-prod.sh
```

5) **(Uma vez) emitir HTTPS no edge**
```bash
bash scripts/enable-https.sh
```

---

## 🛠️ Passo a Passo Manual (Opcional)

Caso prefira subir cada serviço individualmente:

### 1. 🏗️ Infraestrutura (Postgres + Ponder)
```bash
docker compose -f docker-compose.prod.yml --env-file .env up -d postgres ponder
```

### 2. 📜 Deploy dos Contratos
```bash
# Carregar variáveis do .env
export $(cat .env | grep -v '#' | xargs)
forge script script/deploy/DeployPropertySale.s.sol --rpc-url $RPC_URL --broadcast
```

### 3. 📈 Indexador (Ponder)
```bash
cd indexer
npm install
# Ambiente local (hot-reload):
npm run dev
# Produção (via Docker/VPS): usa 'npm run start' — não use 'dev' em produção!
```

### 4. ⚛️ Frontend (Next.js)
```bash
cd frontend
npm install
npm run dev
```

---

## 🏠 Como Inserir Imóveis para Venda

Após iniciar o ambiente, você precisa cadastrar os imóveis para que eles apareçam no Marketplace. Use o script CLI que preparamos:

```bash
# Formato: ./list-asset.sh "Nome/Localização" "Preço em ETH" "URL da Imagem"

# Exemplo 1: Apartamento de Luxo
./list-asset.sh "Apartamento em Ipanema" "1.5" "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267"

# Exemplo 2: Casa de Praia
./list-asset.sh "Casa de Praia - Búzios" "3.0" "https://images.unsplash.com/photo-1499793983690-e29da59ef1c2"
```

> **Dica**: As imagens devem ser links válidos de fotos reais para uma melhor experiência no Marketplace. 🖼️

---

## 🛠️ Ferramentas Auxiliares (CLI)

Criamos scripts facilitadores para gerenciar seus ativos e o ambiente:

- 🚀 **Subir o ambiente completo**: `./start-local.sh`  
  Sobe Docker (Postgres + Ponder), sincroniza ABI e inicia o frontend.
- 🚀 **Deploy real na Sepolia**: `./deploy-sepolia.sh`  
  Faz deploy do contrato, atualiza `NEXT_PUBLIC_CONTRACT_ADDRESS` e `PONDER_START_BLOCK`.
- 🐳 **Build & push das imagens (GHCR)**: `bash scripts/build-push-ghcr.sh`  
  Gera as imagens do frontend e do Ponder para produção.
- 🚀 **Deploy na VPS (produção)**: `bash scripts/deploy-prod.sh`  
  Sobe/atualiza `postgres`, `ponder`, `frontend` e conecta na rede `edge`.
- 🌐 **Deploy do edge proxy**: `bash infra/edge-proxy/scripts/deploy-edge.sh`  
  Sobe o Nginx dedicado que atende 80/443 para toda a VPS.
- 🔒 **Emitir HTTPS**: `bash scripts/enable-https.sh`  
  Emite certificado Let's Encrypt e recarrega o edge proxy.
- 🔁 **Renovar HTTPS**: `bash scripts/renew-certs-and-reload-nginx.sh`  
  Executa renovação e reload do Nginx.
- 🧹 **Limpeza de logs (2 dias)**: `bash scripts/cleanup-project-logs-2days.sh`  
  Remove logs locais de npm com mais de 2 dias.
- 🐳 **Limpeza Docker (semanal)**: `bash scripts/cleanup-docker.sh`  
  Remove imagens, containers, redes e build cache inativos. Executado automaticamente pelo cron toda domingo às 04:00 no servidor. Log em `/var/log/docker-cleanup.log`.
- 🏠 **Listar imóvel**: `./list-asset.sh "Nome" "Preço ETH" "URL Imagem"`  
  Registra um imóvel no contrato via Foundry.
- 🌱 **Semear imóveis padrão**: `./seed-assets.sh`  
  Popular o marketplace com exemplos rápidos.
- 📋 **Listar imóveis (via Ponder)**: `./list-properties.sh`  
  Consulta o indexador e imprime status/valores.
- 🔄 **Upgrade do contrato**: `./upgrade-contract.sh`  
  Faz upgrade da implementação via ProxyAdmin.
- 🧩 **Relistar (helper)**: `./relist-property.sh <id> <novo_preco>`  
  Script de apoio/diagnóstico; pode sugerir redeploy caso a função não exista no contrato atual.

---

## 🧭 Futuras Implementações (Roadmap de Estudos)

- ✅ **Filtro e ordenação** por status, preço e data de listagem.
- 🔔 **Notificações on-chain** e histórico detalhado de transações por usuário.
- 🧩 **Metadata dinâmica** (ex.: atualização de status do imóvel e documentação).
- 🧮 **Precificação com oráculos** (USD/ETH) e conversão automática.
- 🔐 **Permissões granulares** para operadores/administradores.
- 🧾 **Relatórios exportáveis** (CSV/JSON) para auditoria e análises.
- 🏦 **Fluxos multiassinatura** para operações sensíveis.

---

## ✅ Novos Testes Recomendados

- **Unidade**: validações de preço, status e limites (0, overflow, edge cases).
- **Integração**: compra, oferta, aceitação e relistagem com múltiplos usuários.
- **Reentrância e CEI**: cenários maliciosos e contratos receptores.
- **Indexação**: consistência entre eventos e estado indexado (Ponder).
- **Frontend**: estados de loading/erro/sucesso e updates após confirmação.
- **Gas & performance**: benchmarks e otimizações de custo por operação.

---

## ⚖️ Medidas de Compliance (Para Futuro)

> Nota: itens abaixo são sugestões para estudos e planejamento. Não constituem aconselhamento jurídico.

- **KYC/AML** para compradores e vendedores quando aplicável.
- **LGPD/GDPR**: minimização de dados pessoais, consentimento e retenção.
- **Auditoria de smart contracts** por terceiros antes de produção.
- **Políticas de listagem** (verificação de documentação do imóvel).
- **Gestão de risco** e monitoramento de operações suspeitas.
- **Adequação regulatória** para tokens/RWA na jurisdição alvo.

---

## 🌍 Acesso ao Marketplace (Produção/Estudos)

Este projeto é servido por um edge proxy dedicado na VPS.

- Frontend: 👉 **https://portifolio.cloud/RWAImob**
- API Ponder: 👉 **https://portifolio.cloud/RWAImob/api**

---

## 🌐 VPS (Hostinger) com Edge Proxy Dedicado (Produção/Estudos)

Arquitetura atual:
- `infra/edge-proxy/docker-compose.yml`: Nginx de borda (80/443, TLS, roteamento)
- `docker-compose.prod.yml`: stack da aplicação RWAImob (`postgres`, `ponder`, `frontend`)
- `stellar-explorer` backend em container separado, conectado na mesma rede Docker `edge`

Roteamento principal no edge:
- `/` e `/explorer` (estáticos em `/var/www/html`)
- `/RWAImob` -> `rwaimob-frontend:3000`
- `/RWAImob/api` -> `rwaimob-ponder:42069`
- `/api` -> `stellar-explorer-backend:3001`

### ✅ Pré-requisitos na VPS
- Docker + Docker Compose Plugin instalados
- DNS apontando `portifolio.cloud` e `www.portifolio.cloud` para o IP da VPS
- Portas 80 e 443 liberadas
- Acesso ao GHCR (se suas imagens forem privadas)
- Rede Docker compartilhada `edge` (criada automaticamente pelos scripts)

### 🧩 Arquivos usados
- `docker-compose.prod.yml` (RWAImob app stack)
- `infra/edge-proxy/docker-compose.yml` (edge proxy)
- `infra/edge-proxy/nginx/conf.d/default.conf`
- `infra/edge-proxy/.env` (com `LETSENCRYPT_EMAIL`)
- `.env` (usado também em produção)

### 🚀 Subir stack da aplicação
```bash
bash scripts/deploy-prod.sh
```

### 🌐 Subir edge proxy
```bash
bash infra/edge-proxy/scripts/deploy-edge.sh
```

### 🔒 Habilitar HTTPS (Let’s Encrypt)
1) Crie `infra/edge-proxy/.env` com:
```bash
LETSENCRYPT_EMAIL=seu-email@dominio.com
```

2) Execute:
```bash
bash scripts/enable-https.sh
```

### ♻️ Rotina de renovação, logs e limpeza automática
```bash
bash infra/edge-proxy/scripts/install-ops.sh
```
Esse comando instala:
- Cron de renovação TLS + reload do Nginx
- Cron de limpeza de logs locais de npm
- `logrotate` diário mantendo 2 dias para logs de containers e logs de projeto

**Cron jobs ativos no servidor (sudo crontab):**

| Horário | Tarefa |
|---|---|
| 03:17 e 15:17 (diário) | Renovação SSL + reload Nginx |
| 03:27 (diário) | Limpeza de logs npm >2 dias |
| 04:00 (domingo) | Limpeza Docker (imagens, cache, redes, containers parados) |

**Limites de log dos containers** (configurado em `docker-compose.prod.yml`):
- Máximo de **10MB por arquivo** e **3 arquivos rotativos** por serviço
- Impede acúmulo ilimitado de logs no disco do servidor

### ✅ Healthcheck
- `https://portifolio.cloud/healthz`
- `https://portifolio.cloud/RWAImob/api/healthz`

---

## 📜 Licença

Distribuído sob a licença **MIT**. Veja `LICENSE` para mais informações. ⚖️

---

"O futuro do mercado imobiliário é on-chain." 🏠💎🚀
