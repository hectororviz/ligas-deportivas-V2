import { Controller, Get, Param, ParseIntPipe } from '@nestjs/common';
import { StandingsService } from '../../standings/standings.service';

@Controller()
export class StandingsController {
  constructor(private readonly standingsService: StandingsService) {}

  @Get('zones/:zoneId/categories/:categoryId/standings')
  zoneStandings(
    @Param('zoneId', ParseIntPipe) zoneId: number,
    @Param('categoryId', ParseIntPipe) tournamentCategoryId: number
  ) {
    return this.standingsService.getZoneStandings(zoneId, tournamentCategoryId);
  }

  @Get('tournaments/:tournamentId/standings')
  tournamentStandings(@Param('tournamentId', ParseIntPipe) tournamentId: number) {
    return this.standingsService.getTournamentStandings(tournamentId);
  }

  @Get('leagues/:leagueId/standings')
  leagueStandings(@Param('leagueId', ParseIntPipe) leagueId: number) {
    return this.standingsService.getLeagueStandings(leagueId);
  }
}
