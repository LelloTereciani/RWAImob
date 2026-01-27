# 🏠 RWA Real Estate 🚀

Bem-vindo ao **RWA Real Estate**, uma plataforma descentralizada de ponta para a tokenização e negociação de ativos imobiliários do mundo real (RWA). 🌐

Este projeto utiliza o poder da **Blockchain** para trazer liquidez, transparência e segurança ao mercado imobiliário.

---

## 👨‍💻 Autor
**Wesley** — *Desenvolvedor e Visionário RWA* 💎

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

## 🚀 Como Iniciar (Ambiente Automatizado)

A forma mais rápida de subir todo o ecossistema (Blockchain, Indexador e Frontend) é usando o script de automação:

```bash
# ⚡ Apenas um comando para subir tudo!
./start-local.sh
```

---

## 🛠️ Passo a Passo Manual (Opcional)

Caso prefira subir cada serviço individualmente:

### 1. 🏗️ Infraestrutura (Anvil & Postgres)
```bash
docker compose up -d
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

Criamos scripts facilitadores para gerenciar seus ativos:

- 📝 **Listar Ativo**: `./list-asset.sh "Nome" "Preço ETH" "URL Imagem"`
- 🔄 **Fazer Upgrade**: `./upgrade-contract.sh` (Manter dados e atualizar lógica)
- 🏢 **Relistar**: Interface disponível via `PropertyCard` no navegador.

---

## 🌍 Acesso ao Marketplace

Após rodar os serviços, acesse:
👉 **[http://localhost:3000](http://localhost:3000)**

---

## 📜 Licença

Distribuído sob a licença **MIT**. Veja `LICENSE` para mais informações. ⚖️

---

> "O futuro do mercado imobiliário é on-chain." 🏠💎🚀
