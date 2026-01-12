#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

log() {
  printf '\n[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

cd "$SCRIPT_DIR"

if [ ! -f ".env" ]; then
  echo "No se encontró infra/.env. Crea el archivo antes de validar." >&2
  exit 1
fi

wait_for_db_health() {
  local timeout_seconds=60
  local start
  start=$(date +%s)

  while true; do
    local container_id
    container_id=$(docker compose ps -q db)
    if [ -n "$container_id" ]; then
      local status
      status=$(docker inspect -f '{{.State.Health.Status}}' "$container_id" 2>/dev/null || true)
      if [ "$status" = "healthy" ]; then
        log "DB está healthy."
        return 0
      fi
      if [ -n "$status" ]; then
        log "Esperando DB healthy (estado actual: $status)..."
      else
        log "Esperando DB healthy (healthcheck aún no disponible)..."
      fi
    else
      log "Esperando contenedor DB..."
    fi

    if [ $(( $(date +%s) - start )) -ge $timeout_seconds ]; then
      echo "Timeout esperando healthcheck de DB." >&2
      docker compose logs --tail=50 db || true
      return 1
    fi

    sleep 5
  done
}

log "Recreando base de datos limpia para validar migraciones..."
docker compose down -v

docker compose up -d db
wait_for_db_health

log "Ejecutando prisma migrate deploy en DB limpia..."
docker compose run --rm migrate

log "Limpiando recursos..."
docker compose down -v
