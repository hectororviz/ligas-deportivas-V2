-- CreateEnum
CREATE TYPE "CardType" AS ENUM ('YELLOW', 'RED');

-- CreateEnum
CREATE TYPE "CardDisciplinaryStatus" AS ENUM ('PENDING', 'PROCESSED', 'IGNORED');

-- CreateEnum
CREATE TYPE "SuspensionStatus" AS ENUM ('ACTIVE', 'COMPLETED', 'CANCELLED');

-- CreateTable
CREATE TABLE "PlayerCard" (
    "id" SERIAL NOT NULL,
    "matchCategoryId" INTEGER NOT NULL,
    "playerId" INTEGER NOT NULL,
    "clubId" INTEGER NOT NULL,
    "cardType" "CardType" NOT NULL,
    "minute" INTEGER,
    "disciplinaryStatus" "CardDisciplinaryStatus" NOT NULL DEFAULT 'PENDING',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PlayerCard_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PlayerSuspension" (
    "id" SERIAL NOT NULL,
    "playerId" INTEGER NOT NULL,
    "tournamentId" INTEGER NOT NULL,
    "originalMatches" INTEGER NOT NULL,
    "remainingMatches" INTEGER NOT NULL,
    "status" "SuspensionStatus" NOT NULL DEFAULT 'ACTIVE',
    "reason" TEXT,
    "createdById" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlayerSuspension_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SuspensionOriginCard" (
    "suspensionId" INTEGER NOT NULL,
    "cardId" INTEGER NOT NULL,

    CONSTRAINT "SuspensionOriginCard_pkey" PRIMARY KEY ("suspensionId","cardId")
);

-- CreateTable
CREATE TABLE "SuspensionServedMatch" (
    "id" SERIAL NOT NULL,
    "suspensionId" INTEGER NOT NULL,
    "matchCategoryId" INTEGER NOT NULL,
    "servedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SuspensionServedMatch_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PointDeduction" (
    "id" SERIAL NOT NULL,
    "clubId" INTEGER NOT NULL,
    "tournamentId" INTEGER NOT NULL,
    "tournamentCategoryId" INTEGER,
    "points" INTEGER NOT NULL,
    "reason" TEXT NOT NULL,
    "createdById" INTEGER NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PointDeduction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TournamentDisciplinaryRules" (
    "id" SERIAL NOT NULL,
    "tournamentId" INTEGER NOT NULL,
    "yellowCardLimit" INTEGER NOT NULL DEFAULT 3,
    "yellowLimitSuspensionMatches" INTEGER NOT NULL DEFAULT 1,
    "directRedSuspensionMatches" INTEGER NOT NULL DEFAULT 2,
    "doubleYellowSuspensionMatches" INTEGER NOT NULL DEFAULT 1,
    "resetYellowsOnPhaseChange" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "TournamentDisciplinaryRules_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "PlayerCard_playerId_disciplinaryStatus_idx" ON "PlayerCard"("playerId", "disciplinaryStatus");

-- CreateIndex
CREATE INDEX "PlayerCard_matchCategoryId_idx" ON "PlayerCard"("matchCategoryId");

-- CreateIndex
CREATE INDEX "PlayerCard_clubId_idx" ON "PlayerCard"("clubId");

-- CreateIndex
CREATE INDEX "PlayerSuspension_playerId_tournamentId_status_idx" ON "PlayerSuspension"("playerId", "tournamentId", "status");

-- CreateIndex
CREATE INDEX "PlayerSuspension_tournamentId_status_idx" ON "PlayerSuspension"("tournamentId", "status");

-- CreateIndex
CREATE INDEX "SuspensionOriginCard_suspensionId_idx" ON "SuspensionOriginCard"("suspensionId");

-- CreateIndex
CREATE INDEX "SuspensionOriginCard_cardId_idx" ON "SuspensionOriginCard"("cardId");

-- CreateIndex
CREATE UNIQUE INDEX "SuspensionServedMatch_suspensionId_matchCategoryId_key" ON "SuspensionServedMatch"("suspensionId", "matchCategoryId");

-- CreateIndex
CREATE INDEX "SuspensionServedMatch_suspensionId_idx" ON "SuspensionServedMatch"("suspensionId");

-- CreateIndex
CREATE INDEX "SuspensionServedMatch_matchCategoryId_idx" ON "SuspensionServedMatch"("matchCategoryId");

-- CreateIndex
CREATE INDEX "PointDeduction_tournamentId_tournamentCategoryId_idx" ON "PointDeduction"("tournamentId", "tournamentCategoryId");

-- CreateIndex
CREATE INDEX "PointDeduction_clubId_tournamentId_idx" ON "PointDeduction"("clubId", "tournamentId");

-- CreateIndex
CREATE UNIQUE INDEX "TournamentDisciplinaryRules_tournamentId_key" ON "TournamentDisciplinaryRules"("tournamentId");

-- AddForeignKey
ALTER TABLE "PlayerCard" ADD CONSTRAINT "PlayerCard_matchCategoryId_fkey" FOREIGN KEY ("matchCategoryId") REFERENCES "MatchCategory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlayerCard" ADD CONSTRAINT "PlayerCard_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlayerCard" ADD CONSTRAINT "PlayerCard_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES "Club"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlayerSuspension" ADD CONSTRAINT "PlayerSuspension_playerId_fkey" FOREIGN KEY ("playerId") REFERENCES "Player"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlayerSuspension" ADD CONSTRAINT "PlayerSuspension_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "tournament"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PlayerSuspension" ADD CONSTRAINT "PlayerSuspension_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SuspensionOriginCard" ADD CONSTRAINT "SuspensionOriginCard_suspensionId_fkey" FOREIGN KEY ("suspensionId") REFERENCES "PlayerSuspension"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SuspensionOriginCard" ADD CONSTRAINT "SuspensionOriginCard_cardId_fkey" FOREIGN KEY ("cardId") REFERENCES "PlayerCard"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SuspensionServedMatch" ADD CONSTRAINT "SuspensionServedMatch_suspensionId_fkey" FOREIGN KEY ("suspensionId") REFERENCES "PlayerSuspension"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SuspensionServedMatch" ADD CONSTRAINT "SuspensionServedMatch_matchCategoryId_fkey" FOREIGN KEY ("matchCategoryId") REFERENCES "MatchCategory"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PointDeduction" ADD CONSTRAINT "PointDeduction_clubId_fkey" FOREIGN KEY ("clubId") REFERENCES "Club"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PointDeduction" ADD CONSTRAINT "PointDeduction_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "tournament"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PointDeduction" ADD CONSTRAINT "PointDeduction_tournamentCategoryId_fkey" FOREIGN KEY ("tournamentCategoryId") REFERENCES "TournamentCategory"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PointDeduction" ADD CONSTRAINT "PointDeduction_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TournamentDisciplinaryRules" ADD CONSTRAINT "TournamentDisciplinaryRules_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "tournament"("id") ON DELETE CASCADE ON UPDATE CASCADE;
