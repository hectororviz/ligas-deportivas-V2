#!/bin/sh
set -e

echo "Running Prisma migrations..."
npx prisma migrate deploy

if [ "${RUN_SEED:-false}" = "true" ] || [ "${RUN_SEED:-false}" = "1" ]; then
  echo "Running Prisma seed..."
  npx prisma db seed
fi
