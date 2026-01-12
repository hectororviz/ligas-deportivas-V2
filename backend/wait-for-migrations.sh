#!/bin/sh
set -e

echo "Verificando esquema de base de datos antes de iniciar el backend..."
if ! node /app/scripts/db-schema-check.js; then
  echo "DB no migrada. Ejecutar migrate job."
  exit 1
fi
