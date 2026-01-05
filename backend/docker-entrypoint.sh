#!/bin/sh
set -e

if [ -z "${SKIP_MIGRATIONS:-}" ]; then
  echo "Running Prisma migrations..."
  npx prisma migrate deploy
else
  echo "Skipping Prisma migrations (SKIP_MIGRATIONS set)."
fi

exec "$@"
