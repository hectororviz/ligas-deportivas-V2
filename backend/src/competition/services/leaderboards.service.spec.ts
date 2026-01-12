import { LeaderboardsService } from './leaderboards.service';

describe('LeaderboardsService', () => {
  it('builds leaderboards from goals and match categories', async () => {
    const goals = [
      {
        matchCategoryId: 1,
        playerId: 10,
        clubId: 1,
        player: { firstName: 'Juan', lastName: 'Perez' },
        club: { id: 1, name: 'Club A', shortName: 'A' },
      },
      {
        matchCategoryId: 1,
        playerId: 10,
        clubId: 1,
        player: { firstName: 'Juan', lastName: 'Perez' },
        club: { id: 1, name: 'Club A', shortName: 'A' },
      },
      {
        matchCategoryId: 1,
        playerId: 10,
        clubId: 1,
        player: { firstName: 'Juan', lastName: 'Perez' },
        club: { id: 1, name: 'Club A', shortName: 'A' },
      },
      {
        matchCategoryId: 1,
        playerId: 11,
        clubId: 1,
        player: { firstName: 'Luis', lastName: 'Gomez' },
        club: { id: 1, name: 'Club A', shortName: 'A' },
      },
      {
        matchCategoryId: 1,
        playerId: 12,
        clubId: 2,
        player: { firstName: 'Ana', lastName: 'Ruiz' },
        club: { id: 2, name: 'Club B', shortName: 'B' },
      },
      {
        matchCategoryId: 2,
        playerId: 11,
        clubId: 1,
        player: { firstName: 'Luis', lastName: 'Gomez' },
        club: { id: 1, name: 'Club A', shortName: 'A' },
      },
      {
        matchCategoryId: 2,
        playerId: 11,
        clubId: 1,
        player: { firstName: 'Luis', lastName: 'Gomez' },
        club: { id: 1, name: 'Club A', shortName: 'A' },
      },
      {
        matchCategoryId: 2,
        playerId: 10,
        clubId: 1,
        player: { firstName: 'Juan', lastName: 'Perez' },
        club: { id: 1, name: 'Club A', shortName: 'A' },
      },
      {
        matchCategoryId: 3,
        playerId: 10,
        clubId: 1,
        player: { firstName: 'Juan', lastName: 'Perez' },
        club: { id: 1, name: 'Club A', shortName: 'A' },
      },
      {
        matchCategoryId: 3,
        playerId: 13,
        clubId: 3,
        player: { firstName: 'Maria', lastName: 'Lopez' },
        club: { id: 3, name: 'Club C', shortName: 'C' },
      },
    ];

    const matchCategories = [
      {
        id: 1,
        matchId: 100,
        homeScore: 4,
        awayScore: 1,
        match: {
          zone: { name: 'Zona 1' },
          homeClub: { id: 1, name: 'Club A', shortName: 'A' },
          awayClub: { id: 2, name: 'Club B', shortName: 'B' },
        },
        tournamentCategory: { category: { name: 'Sub 18' } },
      },
      {
        id: 2,
        matchId: 101,
        homeScore: 0,
        awayScore: 2,
        match: {
          zone: { name: 'Zona 1' },
          homeClub: { id: 2, name: 'Club B', shortName: 'B' },
          awayClub: { id: 1, name: 'Club A', shortName: 'A' },
        },
        tournamentCategory: { category: { name: 'Sub 18' } },
      },
      {
        id: 3,
        matchId: 102,
        homeScore: 1,
        awayScore: 1,
        match: {
          zone: { name: 'Zona 2' },
          homeClub: { id: 3, name: 'Club C', shortName: 'C' },
          awayClub: { id: 1, name: 'Club A', shortName: 'A' },
        },
        tournamentCategory: { category: { name: 'Sub 20' } },
      },
    ];

    const prisma = {
      goal: {
        findMany: jest.fn().mockResolvedValue(goals),
      },
      matchCategory: {
        findMany: jest.fn().mockResolvedValue(matchCategories),
      },
    };

    const service = new LeaderboardsService(prisma as any);

    const result = await service.getLeaderboards({
      tournamentId: 1,
      zoneId: null,
      categoryId: null,
    });

    expect(result.leaderboards.topScorersPlayers[0]).toEqual({
      playerId: 10,
      playerName: 'Juan Perez',
      clubId: 1,
      clubName: 'A',
      goals: 5,
    });
    expect(result.leaderboards.mostMatchesScoringPlayers[0].matchesWithGoal).toBe(3);
    expect(result.leaderboards.mostBracesPlayers[0]).toMatchObject({
      playerId: 11,
      bracesCount: 1,
    });
    expect(result.leaderboards.mostHatTricksPlayers[0]).toMatchObject({
      playerId: 10,
      hatTricksCount: 1,
    });
    expect(result.leaderboards.topScoringTeams[0]).toEqual({
      clubId: 1,
      clubName: 'A',
      goalsFor: 7,
    });
    expect(result.leaderboards.bestDefenseTeams[0]).toEqual({
      clubId: 3,
      clubName: 'C',
      goalsAgainst: 1,
    });
    expect(result.leaderboards.mostCleanSheetsTeams[0]).toEqual({
      clubId: 1,
      clubName: 'A',
      cleanSheets: 1,
    });
    expect(result.leaderboards.mostWinsTeams[0]).toEqual({
      clubId: 1,
      clubName: 'A',
      wins: 2,
    });
    expect(result.leaderboards.mostGoalsMatches[0]).toMatchObject({
      matchCategoryId: 1,
      totalGoals: 5,
    });
    expect(result.leaderboards.biggestWinsMatches[0]).toMatchObject({
      matchCategoryId: 1,
      goalDiff: 3,
    });
  });
});
