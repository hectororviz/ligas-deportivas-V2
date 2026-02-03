-- CreateEnum
CREATE TYPE "TournamentStatus" AS ENUM ('ACTIVE', 'INACTIVE', 'FINISHED');

-- AlterTable
ALTER TABLE "tournament" ADD COLUMN "status" "TournamentStatus" NOT NULL DEFAULT 'ACTIVE';
