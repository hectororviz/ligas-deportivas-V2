import { Express } from 'express';
import {
  BadRequestException,
  Injectable,
  NotFoundException
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateMatchDto } from '../dto/update-match.dto';
import { RecordMatchResultDto } from '../dto/record-match-result.dto';
import { MatchStatus } from '@prisma/client';
import { StorageService } from '../../storage/storage.service';
import { StandingsService } from '../../standings/standings.service';

@Injectable()
export class MatchesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
    private readonly standingsService: StandingsService
  ) {}

  listByZone(zoneId: number) {
    return this.prisma.match.findMany({
      where: { zoneId },
      orderBy: [{ matchday: 'asc' }, { round: 'asc' }],
      include: {
        homeClub: true,
        awayClub: true,
        categories: {
          include: {
            tournamentCategory: {
              include: { category: true }
            }
          }
        }
      }
    });
  }

  async updateMatch(matchId: number, dto: UpdateMatchDto) {
    await this.prisma.match.findUniqueOrThrow({ where: { id: matchId } });
    return this.prisma.match.update({
      where: { id: matchId },
      data: {
        status: dto.status,
        date: dto.date ? new Date(dto.date) : undefined
      }
    });
  }

  async recordResult(
    matchId: number,
    tournamentCategoryId: number,
    dto: RecordMatchResultDto,
    userId: number,
    attachment?: Express.Multer.File
  ) {
    const result = await this.prisma.$transaction(async (tx) => {
      const matchCategory = await tx.matchCategory.findFirst({
        where: { matchId, tournamentCategoryId },
        include: {
          match: {
            include: {
              homeClub: true,
              awayClub: true,
              categories: true
            }
          }
        }
      });

      if (!matchCategory) {
        throw new NotFoundException('Partido/categoría no encontrado');
      }

      const homeClubId = matchCategory.match.homeClubId;
      const awayClubId = matchCategory.match.awayClubId;

      if (!homeClubId || !awayClubId) {
        throw new BadRequestException('El partido no tiene clubes definidos');
      }

      for (const goal of dto.playerGoals) {
        if (![homeClubId, awayClubId].includes(goal.clubId)) {
          throw new BadRequestException('El club indicado en un gol no pertenece al partido.');
        }
      }
      for (const goal of dto.otherGoals) {
        if (![homeClubId, awayClubId].includes(goal.clubId)) {
          throw new BadRequestException('El club indicado no pertenece al partido.');
        }
      }

      const totals = this.calculateTotals(dto);

      const homeTotal = totals[homeClubId] ?? 0;
      const awayTotal = totals[awayClubId] ?? 0;
      if (homeTotal !== dto.homeScore || awayTotal !== dto.awayScore) {
        throw new BadRequestException('La suma de goles no coincide con el marcador informado');
      }

      await tx.goal.deleteMany({ where: { matchCategoryId: matchCategory.id } });
      await tx.otherGoal.deleteMany({ where: { matchCategoryId: matchCategory.id } });

      const goalEntries = this.expandGoals(matchCategory.id, dto);
      if (goalEntries.length) {
        await tx.goal.createMany({ data: goalEntries });
      }

      if (dto.otherGoals.length) {
        await tx.otherGoal.createMany({
          data: dto.otherGoals.map((goal) => ({
            matchCategoryId: matchCategory.id,
            clubId: goal.clubId,
            goals: goal.goals
          }))
        });
      }

      const closedAt = dto.confirm ? new Date() : null;

      await tx.matchCategory.update({
        where: { id: matchCategory.id },
        data: {
          homeScore: dto.homeScore,
          awayScore: dto.awayScore,
          closedAt: closedAt ?? undefined,
          closedById: closedAt ? userId : null
        }
      });

      if (dto.confirm) {
        const categories = await tx.matchCategory.findMany({
          where: { matchId },
          select: { id: true, closedAt: true }
        });
        const allClosed = categories.every((category) => category.closedAt);
        if (allClosed) {
          await tx.match.update({
            where: { id: matchId },
            data: { status: MatchStatus.FINISHED }
          });
        }
      } else {
        await tx.match.update({
          where: { id: matchId },
          data: { status: MatchStatus.PENDING }
        });
      }

      if (attachment) {
        const key = await this.storageService.saveAttachment(attachment);
        const url = this.storageService.getPublicUrl(key);
        await tx.matchAttachment.create({
          data: {
            matchId,
            url,
            uploadedById: userId
          }
        });
      }

      await tx.matchLog.create({
        data: {
          matchId,
          userId,
          action: 'RESULT_UPDATED'
        }
      });

      return tx.match.findUnique({
        where: { id: matchId },
        include: {
          homeClub: true,
          awayClub: true,
          categories: true
        }
      });
    });

    await this.standingsService.recalculateForMatch(matchId);
    return result;
  }

  private calculateTotals(dto: RecordMatchResultDto) {
    const totals: Record<number, number> = {};

    for (const goal of dto.playerGoals) {
      if (!totals[goal.clubId]) {
        totals[goal.clubId] = 0;
      }
      totals[goal.clubId] += goal.goals;
    }

    for (const goal of dto.otherGoals) {
      if (!totals[goal.clubId]) {
        totals[goal.clubId] = 0;
      }
      totals[goal.clubId] += goal.goals;
    }

    return totals;
  }

  private expandGoals(matchCategoryId: number, dto: RecordMatchResultDto) {
    const entries: { matchCategoryId: number; playerId: number; clubId: number }[] = [];
    for (const goal of dto.playerGoals) {
      if (goal.goals <= 0) {
        continue;
      }
      for (let i = 0; i < goal.goals; i += 1) {
        entries.push({ matchCategoryId, playerId: goal.playerId, clubId: goal.clubId });
      }
    }
    return entries;
  }
}
