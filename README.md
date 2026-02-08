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

- `PONDER_RPC_URL_11155111`
- `RPC_URL`
- `NEXT_PUBLIC_CONTRACT_ADDRESS`
- `NEXT_PUBLIC_SEPOLIA_RPC_URL`
- `NEXT_PUBLIC_PONDER_URL`

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

> Observação: o projeto usa **apenas** `docker-compose.prod.yml`. O arquivo `docker-compose.yml` foi removido.

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

4) **Subir o deploy**
```bash
bash scripts/deploy-prod.sh
```

5) **(Opcional) HTTPS**
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
npm run dev
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
  Sobe os containers usando `docker-compose.prod.yml`.
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

## 🌍 Acesso ao Marketplace (Local)

Após rodar os serviços, acesse:
👉 **http://localhost:3000/RWAImob**

> Não usamos mais Ponder local. O indexador aponta para a **testnet Sepolia**.
> Para API do Ponder, utilize a rota publicada na VPS:
👉 **http://portifolio.cloud/RWAImob/api**

---

## 🌐 VPS (Hostinger) com Docker + Nginx (Produção/Estudos)

Esta estrutura usa **Docker Compose** e expõe o frontend em:
👉 **http://portifolio.cloud/RWAImob**

O Ponder fica atrás de:
👉 **http://portifolio.cloud/RWAImob/api**

### ✅ Pré-requisitos na VPS
- Docker + Docker Compose Plugin instalados
- DNS apontando `portifolio.cloud` e `www.portifolio.cloud` para o IP da VPS
- Porta 80 liberada (HTTPS será ativado depois)
- Acesso ao GHCR (se suas imagens forem privadas)

### 🧩 Arquivos usados
- `docker-compose.prod.yml`
- `nginx/conf.d/default.conf`
- `nginx/ssl.conf.template`
- `.env` (usado também em produção)

### 🚀 Subir tudo na VPS
```bash
bash scripts/deploy-prod.sh
```

### 🔒 Habilitar HTTPS (Let’s Encrypt)
1) Adicione no `.env`:
```bash
LETSENCRYPT_EMAIL=seu-email@dominio.com
```

2) Execute:
```bash
./scripts/enable-https.sh
```

Após isso, o acesso deve ficar em:
👉 **https://portifolio.cloud/RWAImob**

### ✅ Healthcheck
- `http://portifolio.cloud/healthz`
- `http://portifolio.cloud/RWAImob/api/healthz`

---

## 📜 Licença

Distribuído sob a licença **MIT**. Veja `LICENSE` para mais informações. ⚖️

---

"O futuro do mercado imobiliário é on-chain." 🏠💎🚀
