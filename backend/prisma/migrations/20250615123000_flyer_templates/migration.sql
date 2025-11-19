-- CreateTable
CREATE TABLE "FlyerTemplate" (
    "id" SERIAL PRIMARY KEY,
    "competitionId" INTEGER,
    "backgroundKey" TEXT,
    "layoutKey" TEXT,
    "layoutFileName" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "FlyerTemplate_competitionId_key" ON "FlyerTemplate"("competitionId");

-- AddForeignKey
ALTER TABLE "FlyerTemplate" ADD CONSTRAINT "FlyerTemplate_competitionId_fkey" FOREIGN KEY ("competitionId") REFERENCES "Tournament"("id") ON DELETE CASCADE ON UPDATE CASCADE;
