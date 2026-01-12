#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

usage() {
  cat <<'USAGE'
Uso: ./recover_failed_migrations.sh [--apply <nombre>] [--rollback <nombre>]

Opciones:
  --apply <nombre>    Marca la migración como aplicada (si ya la aplicaste manualmente).
  --rollback <nombre> Marca la migración como rollback (si falló y no aplicaste cambios).
  -h, --help          Muestra esta ayuda.

Sin flags, lista migraciones fallidas y comandos recomendados (rolled-back).
USAGE
}

get_failed_migrations() {
  docker compose run --rm --entrypoint node migrate - <<'NODE'
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function main() {
  try {
    const migrationsTableResult = await prisma.$queryRaw`
      SELECT EXISTS (
        SELECT 1
        FROM information_schema.tables
        WHERE table_schema = 'public'
          AND table_name = '_prisma_migrations'
      ) AS "exists";
    `;
    const migrationsTableExists = Array.isArray(migrationsTableResult)
      ? migrationsTableResult[0]?.exists
      : false;

    if (!migrationsTableExists) {
      process.exit(0);
    }

    const failedMigrations = await prisma.$queryRaw`
      SELECT migration_name
      FROM _prisma_migrations
      WHERE finished_at IS NULL
        AND rolled_back_at IS NULL
      ORDER BY migration_name ASC
    `;

    if (Array.isArray(failedMigrations)) {
      failedMigrations.forEach((row) => {
        if (row && row.migration_name) {
          console.log(row.migration_name);
        }
      });
    }
  } catch (error) {
    console.error('No se pudo leer _prisma_migrations.', error);
    process.exit(1);
  } finally {
    await prisma.$disconnect();
  }
}

main();
NODE
}

cd "$SCRIPT_DIR"

if [ ! -f ".env" ]; then
  echo "No se encontró infra/.env. Crea el archivo antes de continuar." >&2
  exit 1
fi

if [ "$#" -gt 0 ]; then
  case "$1" in
    --apply)
      if [ "$#" -lt 2 ]; then
        echo "Falta el nombre de la migración para --apply." >&2
        exit 1
      fi
      docker compose run --rm --entrypoint sh migrate -lc \
        "npx prisma migrate resolve --applied $2"
      exit 0
      ;;
    --rollback)
      if [ "$#" -lt 2 ]; then
        echo "Falta el nombre de la migración para --rollback." >&2
        exit 1
      fi
      docker compose run --rm --entrypoint sh migrate -lc \
        "npx prisma migrate resolve --rolled-back $2"
      exit 0
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
fi

failed_migrations=$(get_failed_migrations)

if [ -z "$failed_migrations" ]; then
  echo "No se detectaron migraciones fallidas en _prisma_migrations."
  exit 0
fi

echo "Migraciones fallidas detectadas:"
echo "$failed_migrations" | sed 's/^/- /'

echo ""
echo "Comandos recomendados (rolled-back por defecto):"
while IFS= read -r migration_name; do
  [ -n "$migration_name" ] || continue
  echo "docker compose run --rm --entrypoint sh migrate -lc 'npx prisma migrate resolve --rolled-back ${migration_name}'"
done <<< "$failed_migrations"

echo ""
echo "Si ya aplicaste cambios manualmente, usa --applied en lugar de --rolled-back."
