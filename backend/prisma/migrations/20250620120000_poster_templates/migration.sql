-- CreateTable
CREATE TABLE "TournamentPosterTemplate" (
    "id" SERIAL PRIMARY KEY,
    "tournamentId" INTEGER NOT NULL,
    "template" JSONB NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "backgroundKey" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateTable
CREATE TABLE "MatchPosterCache" (
    "id" SERIAL PRIMARY KEY,
    "matchId" INTEGER NOT NULL,
    "templateVersion" INTEGER NOT NULL,
    "hash" TEXT NOT NULL,
    "storageKey" TEXT NOT NULL,
    "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- CreateIndex
CREATE UNIQUE INDEX "TournamentPosterTemplate_tournamentId_key" ON "TournamentPosterTemplate"("tournamentId");

-- CreateIndex
CREATE UNIQUE INDEX "MatchPosterCache_matchId_key" ON "MatchPosterCache"("matchId");

-- AddForeignKey
ALTER TABLE "TournamentPosterTemplate" ADD CONSTRAINT "TournamentPosterTemplate_tournamentId_fkey" FOREIGN KEY ("tournamentId") REFERENCES "tournament"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "MatchPosterCache" ADD CONSTRAINT "MatchPosterCache_matchId_fkey" FOREIGN KEY ("matchId") REFERENCES "Match"("id") ON DELETE CASCADE ON UPDATE CASCADE;
