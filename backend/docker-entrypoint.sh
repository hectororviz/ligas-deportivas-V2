#!/bin/sh
set -e

if [ -z "${SKIP_MIGRATIONS:-}" ]; then
  echo "Running Prisma migrations..."
  if ! npx prisma migrate deploy; then
    echo "Prisma migrations failed. Review the logs above and run 'npx prisma migrate deploy' manually once the database is ready." >&2
    echo "Tip: set SKIP_MIGRATIONS=1 to start the API without retrying migrations at boot." >&2
    exit 1
  fi
  export MIGRATIONS_APPLIED=true
else
  echo "Skipping Prisma migrations (SKIP_MIGRATIONS set)."
fi

exec "$@"
