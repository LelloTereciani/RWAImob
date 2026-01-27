#!/bin/bash

# Script para re-listar uma propriedade
# Uso: ./relist-property.sh <propertyId> <newPrice>

PROPERTY_ID="$1"
NEW_PRICE_ETH="$2"

if [ -z "$PROPERTY_ID" ] || [ -z "$NEW_PRICE_ETH" ]; then
    echo "Uso: $0 <PropertyID> <Novo Preço em ETH>"
    echo "Exemplo: $0 1 2.5"
    exit 1
fi

# Converter preço para Wei
if command -v python3 &> /dev/null; then
    NEW_PRICE_WEI=$(python3 -c "print(int($NEW_PRICE_ETH * 10**18))")
else
    NEW_PRICE_WEI=$(echo "$NEW_PRICE_ETH * 1000000000000000000" | bc)
fi

echo "🏠 Re-listando Propriedade #$PROPERTY_ID"
echo "  Novo Preço: $NEW_PRICE_ETH ETH ($NEW_PRICE_WEI Wei)"
echo ""

# Nota: Como o upgrade falhou, vamos usar um workaround
# O contrato atual não tem relistProperty(), então vamos orientar o usuário

echo "⚠️  ATENÇÃO: O contrato atual não suporta re-listagem direta."
echo ""
echo "Para vender sua propriedade, você tem 2 opções:"
echo ""
echo "1️⃣  Aceitar Ofertas:"
echo "   - Aguarde ofertas de compradores"
echo "   - Use acceptOffer(propertyId, offerIndex)"
echo ""
echo "2️⃣  Fazer Upgrade do Contrato (recomendado):"
echo "   - Pare o Anvil e Ponder"
echo "   - Execute: ./start-local.sh"
echo "   - Isso fará um redeploy com a nova função relistProperty()"
echo ""

read -p "Deseja fazer o redeploy agora? (s/n): " resposta

if [ "$resposta" = "s" ] || [ "$resposta" = "S" ]; then
    echo "🔄 Reiniciando ambiente..."
    pkill -f anvil
    pkill -f ponder
    sleep 2
    ./start-local.sh
else
    echo "❌ Operação cancelada."
fi
