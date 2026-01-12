#!/bin/sh
set -eu

usage() {
  cat <<'USAGE'
Uso: ./deploy.sh [--seed]

Opciones:
  --seed   Ejecuta el seed de Prisma durante el job de migración.
USAGE
}

RUN_SEED_FLAG="false"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --seed)
      RUN_SEED_FLAG="true"
      shift
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

if [ ! -f ".env" ]; then
  echo "No se encontró infra/.env. Crea el archivo antes de desplegar." >&2
  exit 1
fi

echo "Iniciando base de datos..."
docker compose up -d db

echo "Ejecutando migraciones..."
if [ "$RUN_SEED_FLAG" = "true" ]; then
  RUN_SEED=true docker compose run --rm migrate
else
  docker compose run --rm migrate
fi

echo "Levantando backend y frontend..."
docker compose up -d backend frontend
