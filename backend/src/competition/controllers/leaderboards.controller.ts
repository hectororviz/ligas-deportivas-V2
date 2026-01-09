import { BadRequestException, Controller, Get, Query } from '@nestjs/common';
import { LeaderboardsService } from '../services/leaderboards.service';

@Controller()
export class LeaderboardsController {
  constructor(private readonly leaderboardsService: LeaderboardsService) {}

  @Get('stats/leaderboards')
  getLeaderboards(
    @Query('tournamentId') tournamentId?: string,
    @Query('zoneId') zoneId?: string,
    @Query('categoryId') categoryId?: string,
  ) {
    const parsedTournamentId = this.parseId(tournamentId);
    if (parsedTournamentId == null) {
      throw new BadRequestException('tournamentId es obligatorio');
    }
    return this.leaderboardsService.getLeaderboards({
      tournamentId: parsedTournamentId,
      zoneId: this.parseId(zoneId),
      categoryId: this.parseId(categoryId),
    });
  }

  private parseId(value?: string): number | null {
    if (!value) {
      return null;
    }
    const parsed = Number.parseInt(value, 10);
    return Number.isNaN(parsed) ? null : parsed;
  }
}
