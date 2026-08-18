-- CreateEnum
CREATE TYPE "PermissionLevel" AS ENUM ('TOTAL', 'LECTURA', 'MODIFICACION', 'LECTURA_CLUB', 'MODIFICACION_CLUB', 'NO');

-- Migrate User email -> username (only the seeded admin is expected to exist).
-- Backfill admin by its legacy email; any other legacy row falls back to its email
-- so uniqueness is preserved (email was unique).
ALTER TABLE "User" ADD COLUMN "username" TEXT;
UPDATE "User" SET "username" = 'admin' WHERE "email" = 'admin@ligas.local';
UPDATE "User" SET "username" = "email" WHERE "username" IS NULL;
ALTER TABLE "User" ALTER COLUMN "username" SET NOT NULL;

-- Add super-admin marker.
ALTER TABLE "User" ADD COLUMN "isAdmin" BOOLEAN NOT NULL DEFAULT false;

-- Create the per-user permission matrix table.
CREATE TABLE "UserPermission" (
    "id" SERIAL NOT NULL,
    "userId" INTEGER NOT NULL,
    "module" "Module" NOT NULL,
    "level" "PermissionLevel" NOT NULL DEFAULT 'NO',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "UserPermission_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "UserPermission_userId_module_key" ON "UserPermission"("userId", "module");

CREATE UNIQUE INDEX "User_username_key" ON "User"("username");

-- Drop the email column (its unique index is dropped automatically with the column).
ALTER TABLE "User" DROP COLUMN "email";
ALTER TABLE "User" DROP COLUMN "emailVerifiedAt";

ALTER TABLE "UserPermission" ADD CONSTRAINT "UserPermission_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Drop email-based flows.
DROP TABLE "EmailVerificationToken";
DROP TABLE "PasswordResetToken";
DROP TABLE "PasswordChangeRequest";
DROP TABLE "EmailChangeRequest";
