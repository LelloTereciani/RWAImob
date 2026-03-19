#!/usr/bin/env bash
# cleanup-docker.sh
# Limpeza automática semanal do Docker:
#   - Remove imagens não utilizadas (dangling)
#   - Remove containers parados
#   - Remove redes não utilizadas
#   - Remove volumes não utilizados (exceto volumes nomeados de dados)
# NÃO remove: imagens em uso, volumes nomeados em uso (ex: postgres_data)
set -euo pipefail

LOG_TAG="docker-cleanup"

echo "[$LOG_TAG] Iniciando limpeza Docker - $(date '+%Y-%m-%d %H:%M:%S')"

# Remove containers parados
CONTAINERS=$(docker container prune -f 2>&1)
echo "[$LOG_TAG] Containers removidos: $CONTAINERS"

# Remove imagens sem tag (dangling) e imagens não usadas por nenhum container
IMAGES=$(docker image prune -af 2>&1)
echo "[$LOG_TAG] Imagens removidas: $IMAGES"

# Remove redes não utilizadas
NETWORKS=$(docker network prune -f 2>&1)
echo "[$LOG_TAG] Redes removidas: $NETWORKS"

# Remove build cache acumulado
BUILD_CACHE=$(docker builder prune -af 2>&1)
echo "[$LOG_TAG] Build cache removido: $BUILD_CACHE"

# Mostra uso de disco atual do Docker após limpeza
echo "[$LOG_TAG] Uso de disco Docker pós-limpeza:"
docker system df

echo "[$LOG_TAG] Limpeza concluída - $(date '+%Y-%m-%d %H:%M:%S')"
