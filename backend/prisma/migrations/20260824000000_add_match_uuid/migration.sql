-- Agrega un identificador público/externo UUID al modelo Match.
-- Se conserva el id numérico autoincremental como PK interna.

-- Habilita pgcrypto (gen_random_uuid) si no está disponible.
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Agrega la columna uuid con valor por defecto generado por PostgreSQL.
-- Los registros existentes reciben automáticamente un UUID único.
ALTER TABLE "Match" ADD COLUMN "uuid" UUID NOT NULL DEFAULT gen_random_uuid();

-- Restricción UNIQUE sobre uuid.
ALTER TABLE "Match" ADD CONSTRAINT "Match_uuid_key" UNIQUE ("uuid");
