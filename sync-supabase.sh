#!/usr/bin/env bash
set -euo pipefail

# Wrapper para correr el sync de resultados desde la máquina host.
# Copia los scripts al contenedor del backend y ejecuta node ahí dentro.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT="$SCRIPT_DIR"
INFRA_DIR="$REPO_ROOT/infra"
BACKEND_SCRIPTS="$REPO_ROOT/backend/scripts"

usage() {
  cat <<'USAGE'
Uso: ./sync-supabase.sh [--dry-run]

Opciones:
  --dry-run    Muestra qué haría el sync sin escribir cambios en v2.
  -h, --help   Muestra esta ayuda.
USAGE
}

DRY_RUN_FLAG=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN_FLAG=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Opción desconocida: $1" >&2; usage; exit 1 ;;
  esac
done

# Detecta el contenedor del backend (servicio "ligas-backend").
CONTAINER=""
if [ -f "$INFRA_DIR/docker-compose.yml" ] && command -v docker >/dev/null 2>&1; then
  CONTAINER=$(cd "$INFRA_DIR" && docker compose ps -q ligas-backend 2>/dev/null || true)
fi
if [ -z "$CONTAINER" ]; then
  # Fallback al nombre por defecto del despliegue.
  CONTAINER="infra-ligas-backend-1"
fi

if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
  echo "Error: no se encontró el contenedor del backend ('$CONTAINER'). ¿Está corriendo?" >&2
  exit 1
fi

echo "Contenedor: $CONTAINER"

# Copia los scripts al contenedor (idempotente).
docker exec "$CONTAINER" mkdir -p /app/lib
docker cp "$BACKEND_SCRIPTS/lib/supabase-common.js" "$CONTAINER:/app/lib/supabase-common.js"
docker cp "$BACKEND_SCRIPTS/sync-supabase.js" "$CONTAINER:/app/sync-supabase.js"

# Ejecuta.
if [ "$DRY_RUN_FLAG" = "1" ]; then
  docker exec "$CONTAINER" sh -c "cd /app && DRY_RUN=1 node sync-supabase.js"
else
  docker exec "$CONTAINER" sh -c "cd /app && node sync-supabase.js"
fi
