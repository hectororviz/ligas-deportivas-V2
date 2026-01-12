#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL no está definido."
  exit 1
fi

node scripts/db-schema-check.js
