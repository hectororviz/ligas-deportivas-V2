#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)

log() {
  printf '\n[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

usage() {
  cat <<'USAGE'
Uso: ./deploy.sh [--seed] [--reset-db] [--no-down] [--branch <rama>]

Opciones:
  --seed           Ejecuta el seed de Prisma durante el job de migración.
  --reset-db       MUY PELIGROSO: baja servicios y elimina volúmenes de DB (docker compose down -v).
  --no-down        No baja servicios antes de desplegar (útil para debug).
  --branch <rama>  Hace checkout de la rama indicada antes de git pull.
  -h, --help       Muestra esta ayuda.

Variables de entorno:
  RUN_SEED=1        Equivalente a --seed.
USAGE
}

run_seed=false
reset_db=false
no_down=false
branch=""

normalize_bool() {
  case "${1:-}" in
    1|true|TRUE|yes|YES|on|ON) echo "true" ;;
    *) echo "false" ;;
  esac
}

if [ "$(normalize_bool "${RUN_SEED:-}")" = "true" ]; then
  run_seed=true
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    --seed)
      run_seed=true
      shift
      ;;
    --reset-db)
      reset_db=true
      shift
      ;;
    --no-down)
      no_down=true
      shift
      ;;
    --branch)
      if [ "$#" -lt 2 ]; then
        echo "Falta el nombre de la rama para --branch" >&2
        exit 1
      fi
      branch="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argumento desconocido: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

cd "$SCRIPT_DIR"

if [ ! -f ".env" ]; then
  echo "No se encontró infra/.env. Crea el archivo antes de desplegar." >&2
  exit 1
fi

log "Actualizando código en ${REPO_ROOT}..."
git -C "$REPO_ROOT" fetch --all
if [ -n "$branch" ]; then
  log "Haciendo checkout de la rama $branch"
  git -C "$REPO_ROOT" checkout "$branch"
fi
git -C "$REPO_ROOT" pull
log "Commit actual: $(git -C "$REPO_ROOT" rev-parse --short HEAD)"

if [ "$no_down" = "false" ]; then
  if [ "$reset_db" = "true" ]; then
    log "Deteniendo servicios y eliminando volúmenes (reset DB)."
    docker compose down -v
  else
    log "Deteniendo servicios actuales."
    docker compose down
  fi
else
  log "--no-down activo: no se detendrán servicios antes del deploy."
fi

log "Levantando base de datos..."
docker compose up -d db

wait_for_db_health() {
  local timeout_seconds=90
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

wait_for_db_health

log "Ejecutando migraciones..."
set +e
if [ "$run_seed" = "true" ]; then
  log "RUN_SEED habilitado: se ejecutará el seed."
  RUN_SEED=true docker compose run --rm migrate
  migrate_status=$?
else
  docker compose run --rm migrate
  migrate_status=$?
fi
set -e

if [ "$migrate_status" -ne 0 ]; then
  if [ "$migrate_status" -eq 2 ]; then
    echo "" >&2
    echo "RECOVERY STEPS" >&2
    echo "1) Resuelve las migraciones fallidas (copiar/pegar):" >&2
    ./recover_failed_migrations.sh >&2 || true
    echo "" >&2
    echo "2) Re-run: ./deploy.sh" >&2
    exit 2
  fi
  echo "El job de migraciones falló; abortando deploy." >&2
  exit 1
fi

log "Levantando stack completo..."
docker compose up -d --build --remove-orphans

log "Estado final de servicios:"
docker compose ps

report_unhealthy() {
  local services
  services=$(docker compose config --services 2>/dev/null || true)
  if [ -z "$services" ]; then
    echo "No se pudieron obtener los servicios desde docker compose." >&2
    return
  fi

  while IFS= read -r service; do
    [ -z "$service" ] && continue
    local container_id
    container_id=$(docker compose ps -q "$service")
    if [ -z "$container_id" ]; then
      echo "Servicio $service no tiene contenedor en ejecución." >&2
      docker compose logs --tail=50 "$service" || true
      continue
    fi

    local runtime_status
    local health_status
    local unhealthy=false
    runtime_status=$(docker inspect -f '{{.State.Status}}' "$container_id" 2>/dev/null || true)
    health_status=$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "$container_id" 2>/dev/null || true)

    if [ "$runtime_status" != "running" ]; then
      echo "Servicio $service no está corriendo (estado: ${runtime_status:-desconocido})." >&2
      unhealthy=true
    fi

    if [ -n "$health_status" ] && [ "$health_status" != "healthy" ]; then
      echo "Servicio $service no está healthy (estado: $health_status)." >&2
      unhealthy=true
    fi

    if [ "$unhealthy" = "true" ]; then
      docker compose logs --tail=50 "$service" || true
    fi
  done <<< "$services"
}

report_unhealthy
