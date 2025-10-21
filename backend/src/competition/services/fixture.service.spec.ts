import { FixtureService } from './fixture.service';

describe('FixtureService round robin', () => {
  const service = new FixtureService({} as any);

  it('generates balanced fixture for even number of clubs', () => {
    const result = (service as any).buildRoundRobin([1, 2, 3, 4]);
    expect(result.totalMatchdays).toBe(3);
    expect(result.firstRound).toHaveLength(6);
    const firstMatch = result.firstRound[0];
    expect([1, 2, 3, 4]).toContain(firstMatch.homeClubId);
    expect([1, 2, 3, 4]).toContain(firstMatch.awayClubId);

    const secondRoundMatch = result.secondRound[0];
    expect(secondRoundMatch.homeClubId).toBe(firstMatch.awayClubId);
    expect(secondRoundMatch.awayClubId).toBe(firstMatch.homeClubId);
  });

  it('handles odd number of clubs with byes', () => {
    const result = (service as any).buildRoundRobin([1, 2, 3, 4, 5]);
    expect(result.totalMatchdays).toBe(5 - 1 + 1); // 6 slots -> 5 matchdays
    const clubs = new Set<number>();
    result.firstRound.forEach((match: any) => {
      clubs.add(match.homeClubId);
      clubs.add(match.awayClubId);
    });
    expect(clubs.size).toBeGreaterThan(0);
  });
});
