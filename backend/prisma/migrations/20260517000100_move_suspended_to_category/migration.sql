-- AlterTable: remove suspended from Match
ALTER TABLE "Match" DROP COLUMN IF EXISTS "suspended";

-- AlterTable: add suspended to MatchCategory
ALTER TABLE "MatchCategory" ADD COLUMN "suspended" BOOLEAN NOT NULL DEFAULT false;
