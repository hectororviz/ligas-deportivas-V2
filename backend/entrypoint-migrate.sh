#!/bin/sh
set -e

node /app/scripts/db-schema-check.js --log-only

echo "Verificando migraciones fallidas..."
node /app/scripts/prisma-preflight.js

echo "Running Prisma migrations..."
npx prisma migrate deploy

if [ "${RUN_SEED:-false}" = "true" ] || [ "${RUN_SEED:-false}" = "1" ]; then
  echo "Running Prisma seed..."
  npx prisma db seed
fi

echo "Verificando esquema aplicado..."
node /app/scripts/db-schema-check.js
