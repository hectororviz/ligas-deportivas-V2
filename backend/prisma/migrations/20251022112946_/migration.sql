/*
  Warnings:

  - A unique constraint covering the columns `[userId,roleId,leagueId,clubId,categoryId]` on the table `UserRole` will be added. If there are existing duplicate values, this will fail.

*/
-- CreateIndex
CREATE UNIQUE INDEX "UserRole_userId_roleId_leagueId_clubId_categoryId_key" ON "UserRole"("userId", "roleId", "leagueId", "clubId", "categoryId");
