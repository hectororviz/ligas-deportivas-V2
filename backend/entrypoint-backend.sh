#!/bin/sh
set -e

if [ "$1" = "node" ] && [ "$2" = "dist/main.js" ]; then
  /app/wait-for-migrations.sh
fi

exec "$@"
