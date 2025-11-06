-- CreateTable or modifications for user club relation
ALTER TABLE "User"
  ADD COLUMN "clubId" INTEGER;

ALTER TABLE "User"
  ADD CONSTRAINT "User_clubId_fkey"
  FOREIGN KEY ("clubId") REFERENCES "Club"("id")
  ON DELETE SET NULL
  ON UPDATE CASCADE;
