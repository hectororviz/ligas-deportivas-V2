import { Express } from 'express';
import {
  BadRequestException,
  Injectable,
  NotFoundException
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { UpdateMatchDto } from '../dto/update-match.dto';
import { RecordMatchResultDto } from '../dto/record-match-result.dto';
import { MatchStatus, MatchdayStatus } from '@prisma/client';
import { StorageService } from '../../storage/storage.service';
import { StandingsService } from '../../standings/standings.service';

@Injectable()
export class MatchesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
    private readonly standingsService: StandingsService
  ) {}

  async listByZone(zoneId: number) {
    const [matches, matchdays] = await this.prisma.$transaction([
      this.prisma.match.findMany({
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
      }),
      this.prisma.zoneMatchday.findMany({
        where: { zoneId },
        orderBy: { matchday: 'asc' }
      })
    ]);

    if (matchdays.length === 0 && matches.length > 0) {
      const uniqueMatchdays = Array.from(new Set(matches.map((match) => match.matchday))).sort((a, b) => a - b);
      const fallback = uniqueMatchdays.map((matchday, index) => ({
        zoneId,
        matchday,
        status:
          index === 0
            ? MatchdayStatus.IN_PROGRESS
            : MatchdayStatus.PENDING,
        createdAt: new Date(),
        updatedAt: new Date(),
        id: 0
      }));
      return { matches, matchdays: fallback };
    }

    return { matches, matchdays };
  }

  async finalizeMatchday(zoneId: number, matchday: number) {
    return this.prisma.$transaction(async (tx) => {
      const entry = await tx.zoneMatchday.findUnique({
        where: { zoneId_matchday: { zoneId, matchday } }
      });

      if (!entry) {
        throw new NotFoundException('Fecha no encontrada para la zona indicada');
      }

      const matches = await tx.match.findMany({
        where: { zoneId, matchday },
        select: { status: true }
      });

      if (!matches.length) {
        throw new BadRequestException('No hay partidos asignados a esta fecha');
      }

      const allFinished = matches.every((match) => match.status === MatchStatus.FINISHED);
      const newStatus = allFinished ? MatchdayStatus.PLAYED : MatchdayStatus.INCOMPLETE;

      const updates: Promise<unknown>[] = [];
      updates.push(
        tx.zoneMatchday.update({
          where: { zoneId_matchday: { zoneId, matchday } },
          data: { status: newStatus }
        })
      );

      const nextMatchday = await tx.zoneMatchday.findFirst({
        where: { zoneId, matchday: { gt: matchday } },
        orderBy: { matchday: 'asc' }
      });

      if (nextMatchday && nextMatchday.status === MatchdayStatus.PENDING) {
        updates.push(
          tx.zoneMatchday.update({
            where: { zoneId_matchday: { zoneId, matchday: nextMatchday.matchday } },
            data: { status: MatchdayStatus.IN_PROGRESS }
          })
        );
      }

      await Promise.all(updates);

      return tx.zoneMatchday.findMany({
        where: { zoneId },
        orderBy: { matchday: 'asc' }
      });
    });
  }

  async getResult(matchId: number, tournamentCategoryId: number) {
    const matchCategory = await this.prisma.matchCategory.findFirst({
      where: { matchId, tournamentCategoryId },
      include: {
        match: {
          select: {
            homeClubId: true,
            awayClubId: true
          }
        },
        goals: {
          include: {
            player: {
              select: {
                id: true,
                firstName: true,
                lastName: true
              }
            }
          }
        },
        otherGoals: true
      }
    });

    if (!matchCategory) {
      throw new NotFoundException('Partido/categoría no encontrado');
    }

    const groupedGoals = new Map<
      number,
      {
        playerId: number;
        clubId: number;
        goals: number;
        player: { id: number; firstName: string | null; lastName: string | null };
      }
    >();

    for (const goal of matchCategory.goals) {
      const existing = groupedGoals.get(goal.playerId);
      if (existing) {
        existing.goals += 1;
      } else {
        groupedGoals.set(goal.playerId, {
          playerId: goal.playerId,
          clubId: goal.clubId,
          goals: 1,
          player: {
            id: goal.playerId,
            firstName: goal.player.firstName,
            lastName: goal.player.lastName
          }
        });
      }
    }

    return {
      matchId,
      tournamentCategoryId,
      homeClubId: matchCategory.match.homeClubId,
      awayClubId: matchCategory.match.awayClubId,
      homeScore: matchCategory.homeScore,
      awayScore: matchCategory.awayScore,
      playerGoals: Array.from(groupedGoals.values()),
      otherGoals: matchCategory.otherGoals.map((goal) => ({
        clubId: goal.clubId,
        goals: goal.goals
      }))
    };
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
