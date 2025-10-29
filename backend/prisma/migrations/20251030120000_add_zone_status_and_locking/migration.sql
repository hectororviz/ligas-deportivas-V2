-- CreateEnum
CREATE TYPE "ZoneStatus" AS ENUM ('OPEN', 'IN_PROGRESS', 'FINISHED');

-- AlterTable
ALTER TABLE "Tournament" ADD COLUMN "fixtureLockedAt" TIMESTAMP(3);

-- AlterTable
ALTER TABLE "Zone" ADD COLUMN "status" "ZoneStatus" NOT NULL DEFAULT 'OPEN',
    ADD COLUMN "lockedAt" TIMESTAMP(3);
