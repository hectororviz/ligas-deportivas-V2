-- AlterTable
ALTER TABLE "Club"
  ADD COLUMN     "active" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN     "facebookUrl" TEXT,
  ADD COLUMN     "instagramUrl" TEXT,
  ADD COLUMN     "latitude" DECIMAL(11,8),
  ADD COLUMN     "logoUrl" TEXT,
  ADD COLUMN     "longitude" DECIMAL(11,8);
