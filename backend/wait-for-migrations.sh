#!/bin/sh
set -e

echo "Verificando esquema de base de datos antes de iniciar el backend..."
set +e
node /app/scripts/db-schema-check.js
status=$?
set -e
if [ "$status" -eq 2 ]; then
  echo "DB no migrada. Ejecutar migrate job."
  exit 2
fi
if [ "$status" -ne 0 ]; then
  echo "Error inesperado al verificar el esquema de la base."
  exit "$status"
fi
