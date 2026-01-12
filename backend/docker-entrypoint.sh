#!/bin/sh
set -e

if [ -z "${SKIP_MIGRATIONS:-}" ]; then
  echo "Running Prisma migrations..."
  if ! npx prisma migrate deploy; then
    echo "Prisma migrations failed."
    echo "Fix the migration error or run migrations as a separate job."
    echo "Set SKIP_MIGRATIONS=1 to skip on startup."

    if [ "${MIGRATION_FAILURE_ACTION:-hold}" = "hold" ]; then
      echo "Holding the container to avoid restart loops."
      echo "Set MIGRATION_FAILURE_ACTION=exit to terminate immediately."
      tail -f /dev/null
    fi

    exit 1
  fi
  export MIGRATIONS_APPLIED=true
else
  echo "Skipping Prisma migrations (SKIP_MIGRATIONS set)."
fi

exec "$@"
