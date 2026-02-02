#!/bin/bash

# Carregar variáveis do arquivo .env
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | xargs)
fi

echo "🌱 Semeando imóveis iniciais no Marketplace..."

# Lista de imóveis padrão (você pode adicionar mais aqui)
properties=(
    "Apartamento em Ipanema|1.5|https://images.unsplash.com/photo-1522708323590-d24dbb6b0267"
    "Cobertura em Balneário Camboriú|12.0|https://images.unsplash.com/photo-1512917774080-9991f1c4c750"
    "Casa de Praia - Búzios|3.5|https://images.unsplash.com/photo-1499793983690-e29da59ef1c2"
    "Penthouse em Nova York|25.0|https://images.unsplash.com/photo-1502672260266-1c1ef2d93688"
)

for prop in "${properties[@]}"; do
    IFS="|" read -r location price uri <<< "$prop"
    echo "🏠 Inserindo: $location..."
    if ! ./list-asset.sh "$location" "$price" "$uri"; then
        echo "❌ Falha ao inserir: $location"
        exit 1
    fi
done

echo "✅ Marketplace semeado com sucesso!"
