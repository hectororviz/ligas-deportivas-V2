import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { LeaguesService } from './services/leagues.service';
import { ClubsService } from './services/clubs.service';
import { CategoriesService } from './services/categories.service';
import { TournamentsService } from './services/tournaments.service';
import { FixtureService } from './services/fixture.service';
import { MatchesService } from './services/matches.service';
import { PlayersService } from './services/players.service';
import { LeaguesController } from './controllers/leagues.controller';
import { ClubsController } from './controllers/clubs.controller';
import { CategoriesController } from './controllers/categories.controller';
import { TournamentsController } from './controllers/tournaments.controller';
import { FixtureController } from './controllers/fixture.controller';
import { MatchesController } from './controllers/matches.controller';
import { PlayersController } from './controllers/players.controller';
import { StandingsController } from './controllers/standings.controller';
import { StandingsService } from '../standings/standings.service';
import { StorageModule } from '../storage/storage.module';
import { AccessControlModule } from '../rbac/access-control.module';
import { TeamsService } from './services/teams.service';
import { TeamsController } from './controllers/teams.controller';
import { ZonesService } from './services/zones.service';
import { ZonesController } from './controllers/zones.controller';
import { MatchFlyerService } from './services/match-flyer.service';
import { FlyerTemplatesService } from './services/flyer-templates.service';
import { MatchPosterService } from './services/match-poster.service';
import { PosterTemplatesService } from './services/poster-templates.service';
import { MatchSheetService } from './services/match-sheet.service';
import { CompetitionController } from './controllers/competition.controller';
import { HomeSummaryController } from './controllers/home-summary.controller';
import { HomeSummaryService } from './services/home-summary.service';
import { LeaderboardsService } from './services/leaderboards.service';
import { LeaderboardsController } from './controllers/leaderboards.controller';

@Module({
  imports: [PrismaModule, StorageModule, AccessControlModule],
  providers: [
    LeaguesService,
    ClubsService,
    CategoriesService,
    TournamentsService,
    FixtureService,
    MatchesService,
    MatchFlyerService,
    MatchPosterService,
    MatchSheetService,
    FlyerTemplatesService,
    PosterTemplatesService,
    StandingsService,
    PlayersService,
    TeamsService,
    ZonesService,
    HomeSummaryService,
    LeaderboardsService
  ],
  controllers: [
    LeaguesController,
    ClubsController,
    CategoriesController,
    TournamentsController,
    FixtureController,
    MatchesController,
    CompetitionController,
    StandingsController,
    PlayersController,
    TeamsController,
    ZonesController,
    HomeSummaryController,
    LeaderboardsController
  ]
})
export class CompetitionModule {}
