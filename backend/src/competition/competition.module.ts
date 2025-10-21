import { Module } from '@nestjs/common';
import { PrismaModule } from '../prisma/prisma.module';
import { LeaguesService } from './services/leagues.service';
import { ClubsService } from './services/clubs.service';
import { CategoriesService } from './services/categories.service';
import { TournamentsService } from './services/tournaments.service';
import { FixtureService } from './services/fixture.service';
import { MatchesService } from './services/matches.service';
import { LeaguesController } from './controllers/leagues.controller';
import { ClubsController } from './controllers/clubs.controller';
import { CategoriesController } from './controllers/categories.controller';
import { TournamentsController } from './controllers/tournaments.controller';
import { FixtureController } from './controllers/fixture.controller';
import { MatchesController } from './controllers/matches.controller';
import { StandingsController } from './controllers/standings.controller';
import { StandingsService } from '../standings/standings.service';
import { StorageModule } from '../storage/storage.module';
import { AccessControlModule } from '../rbac/access-control.module';

@Module({
  imports: [PrismaModule, StorageModule, AccessControlModule],
  providers: [
    LeaguesService,
    ClubsService,
    CategoriesService,
    TournamentsService,
    FixtureService,
    MatchesService,
    StandingsService
  ],
  controllers: [
    LeaguesController,
    ClubsController,
    CategoriesController,
    TournamentsController,
    FixtureController,
    MatchesController,
    StandingsController
  ]
})
export class CompetitionModule {}
