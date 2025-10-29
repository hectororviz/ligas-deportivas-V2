-- CreateEnum
CREATE TYPE "Gender" AS ENUM ('MASCULINO', 'FEMENINO', 'MIXTO');

-- AlterTable
ALTER TABLE "Player"
  ADD COLUMN     "gender" "Gender" NOT NULL DEFAULT 'MASCULINO';

