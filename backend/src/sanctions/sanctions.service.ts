import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CardType, CardDisciplinaryStatus, SuspensionStatus } from '@prisma/client';
import { CreateCardDto, CardResponseDto, CardAlertDto, CreateCardResponseDto } from './dto/card.dto';
import { CreateSuspensionDto, UpdateSuspensionDto, SuspensionResponseDto } from './dto/suspension.dto';
import { CreateDeductionDto, DeductionResponseDto } from './dto/deduction.dto';
import { UpdateDisciplinaryRulesDto, DisciplinaryRulesResponseDto, DefaultDisciplinaryRules } from './dto/disciplinary-rules.dto';
import { TournamentSanctionsSummaryDto } from './dto/sanctions-summary.dto';

@Injectable()
export class SanctionsService {
  constructor(private readonly prisma: PrismaService) {}

  // ============================================================================
  // TARJETAS
  // ============================================================================

  async createCard(
    matchCategoryId: number,
    dto: CreateCardDto,
  ): Promise<CreateCardResponseDto> {
    // Verificar que el match category existe
    const matchCategory = await this.prisma.matchCategory.findUnique({
      where: { id: matchCategoryId },
      include: {
        match: {
          include: {
            zone: true,
          },
        },
      },
    });

    if (!matchCategory) {
      throw new NotFoundException('Match category no encontrado');
    }

    const tournamentId = matchCategory.match.zone.tournamentId;

    // Crear la tarjeta
    const card = await this.prisma.playerCard.create({
      data: {
        matchCategoryId,
        playerId: dto.playerId,
        clubId: dto.clubId,
        cardType: dto.cardType,
        minute: dto.minute,
      },
      include: {
        player: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            dni: true,
          },
        },
        club: {
          select: {
            id: true,
            name: true,
          },
        },
      },
    });

    // Calcular alertas
    const alert = await this.calculateAlert(dto.playerId, tournamentId, dto.cardType, matchCategoryId);

    return {
      card,
      alert,
    };
  }

  private async calculateAlert(
    playerId: number,
    tournamentId: number,
    cardType: CardType,
    matchCategoryId: number,
  ): Promise<CardAlertDto> {
    // Obtener reglas del torneo
    const rules = await this.prisma.tournamentDisciplinaryRules.findUnique({
      where: { tournamentId },
    });

    const yellowLimit = rules?.yellowCardLimit ?? DefaultDisciplinaryRules.yellowCardLimit;

    // Contar amarillas PENDING del jugador en el torneo
    const pendingYellows = await this.prisma.playerCard.count({
      where: {
        playerId,
        cardType: CardType.YELLOW,
        disciplinaryStatus: CardDisciplinaryStatus.PENDING,
        matchCategory: {
          match: {
            zone: {
              tournamentId,
            },
          },
        },
      },
    });

    // Si es roja directa
    if (cardType === CardType.RED) {
      // Verificar si ya tenía una amarilla en este partido (doble amarilla)
      const yellowsInMatch = await this.prisma.playerCard.count({
        where: {
          playerId,
          matchCategoryId,
          cardType: CardType.YELLOW,
          id: {
            not: {
              // Excluir la tarjeta que acabamos de crear (la más reciente)
            },
          },
        },
      });

      if (yellowsInMatch >= 1) {
        return {
          type: 'DOUBLE_YELLOW',
          yellowCount: pendingYellows,
        };
      }

      return {
        type: 'DIRECT_RED',
        yellowCount: pendingYellows,
      };
    }

    // Si es amarilla y alcanzó el límite
    if (cardType === CardType.YELLOW && pendingYellows >= yellowLimit) {
      return {
        type: 'YELLOW_LIMIT',
        yellowCount: pendingYellows,
      };
    }

    return {
      type: null,
      yellowCount: pendingYellows,
    };
  }

  // ============================================================================
  // SUSPENSIONES
  // ============================================================================

  async createSuspension(
    tournamentId: number,
    dto: CreateSuspensionDto,
    createdById: number,
  ): Promise<SuspensionResponseDto> {
    // Verificar que el torneo existe
    const tournament = await this.prisma.tournament.findUnique({
      where: { id: tournamentId },
    });

    if (!tournament) {
      throw new NotFoundException('Torneo no encontrado');
    }

    // Crear la suspensión en una transacción
    const suspension = await this.prisma.$transaction(async (tx) => {
      // Crear la suspensión
      const created = await tx.playerSuspension.create({
        data: {
          playerId: dto.playerId,
          tournamentId,
          originalMatches: dto.originalMatches,
          remainingMatches: dto.originalMatches,
          reason: dto.reason,
          createdById,
        },
        include: {
          player: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              dni: true,
            },
          },
        },
      });

      // Si hay tarjetas vinculadas, marcarlas como PROCESSED
      if (dto.cardIds && dto.cardIds.length > 0) {
        await tx.playerCard.updateMany({
          where: {
            id: { in: dto.cardIds },
          },
          data: {
            disciplinaryStatus: CardDisciplinaryStatus.PROCESSED,
          },
        });

        // Crear relaciones en SuspensionOriginCard
        await tx.suspensionOriginCard.createMany({
          data: dto.cardIds.map(cardId => ({
            suspensionId: created.id,
            cardId,
          })),
          skipDuplicates: true,
        });
      }

      return created;
    });

    return this.getSuspensionById(suspension.id);
  }

  async updateSuspension(
    id: number,
    dto: UpdateSuspensionDto,
  ): Promise<SuspensionResponseDto> {
    const suspension = await this.prisma.playerSuspension.findUnique({
      where: { id },
    });

    if (!suspension) {
      throw new NotFoundException('Suspensión no encontrada');
    }

    const updated = await this.prisma.playerSuspension.update({
      where: { id },
      data: {
        status: dto.status,
        remainingMatches: dto.remainingMatches,
        reason: dto.reason,
      },
      include: {
        player: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            dni: true,
          },
        },
      },
    });

    return this.getSuspensionById(updated.id);
  }

  async getSuspensionById(id: number): Promise<SuspensionResponseDto> {
    const suspension = await this.prisma.playerSuspension.findUnique({
      where: { id },
      include: {
        player: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            dni: true,
          },
        },
        originCards: {
          include: {
            card: {
              select: {
                id: true,
                cardType: true,
                matchCategoryId: true,
              },
            },
          },
        },
        servedMatches: {
          select: {
            id: true,
            matchCategoryId: true,
            servedAt: true,
          },
        },
      },
    });

    if (!suspension) {
      throw new NotFoundException('Suspensión no encontrada');
    }

    return {
      ...suspension,
      originCards: suspension.originCards.map(oc => ({
        id: oc.card.id,
        cardType: oc.card.cardType,
        matchCategoryId: oc.card.matchCategoryId,
      })),
    };
  }

  // ============================================================================
  // DEDUCCIONES DE PUNTOS
  // ============================================================================

  async createDeduction(
    tournamentId: number,
    dto: CreateDeductionDto,
    createdById: number,
  ): Promise<DeductionResponseDto> {
    const tournament = await this.prisma.tournament.findUnique({
      where: { id: tournamentId },
    });

    if (!tournament) {
      throw new NotFoundException('Torneo no encontrado');
    }

    const deduction = await this.prisma.pointDeduction.create({
      data: {
        clubId: dto.clubId,
        tournamentId,
        tournamentCategoryId: dto.tournamentCategoryId ?? null,
        points: dto.points,
        reason: dto.reason,
        createdById,
      },
      include: {
        club: {
          select: {
            id: true,
            name: true,
          },
        },
        tournamentCategory: {
          include: {
            category: {
              select: {
                name: true,
              },
            },
          },
        },
      },
    });

    return deduction;
  }

  async deleteDeduction(id: number): Promise<void> {
    const deduction = await this.prisma.pointDeduction.findUnique({
      where: { id },
    });

    if (!deduction) {
      throw new NotFoundException('Deducción no encontrada');
    }

    await this.prisma.pointDeduction.delete({
      where: { id },
    });
  }

  // ============================================================================
  // RESUMEN DE SANCIIONES POR TORNEO
  // ============================================================================

  async getTournamentSanctions(tournamentId: number): Promise<TournamentSanctionsSummaryDto> {
    // Verificar que el torneo existe
    const tournament = await this.prisma.tournament.findUnique({
      where: { id: tournamentId },
    });

    if (!tournament) {
      throw new NotFoundException('Torneo no encontrado');
    }

    // Obtener reglas disciplinarias para calcular acumulación
    const rules = await this.getOrCreateDisciplinaryRules(tournamentId);
    const yellowCardLimit = rules.yellowCardLimit;

    // Tarjetas PENDING sin suspensión
    const pendingCards = await this.prisma.playerCard.findMany({
      where: {
        disciplinaryStatus: CardDisciplinaryStatus.PENDING,
        matchCategory: {
          match: {
            zone: {
              tournamentId,
            },
          },
        },
        suspensionCards: {
          none: {},
        },
      },
      include: {
        player: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            dni: true,
          },
        },
        club: {
          select: {
            id: true,
            name: true,
          },
        },
        matchCategory: {
          select: {
            id: true,
            match: {
              select: {
                id: true,
                matchday: true,
                round: true,
                date: true,
                homeClub: {
                  select: {
                    id: true,
                    name: true,
                  },
                },
                awayClub: {
                  select: {
                    id: true,
                    name: true,
                  },
                },
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Contar amarillas pendientes por jugador
    const yellowCardCountByPlayer = new Map<number, number>();
    for (const card of pendingCards) {
      if (card.cardType === CardType.YELLOW) {
        const current = yellowCardCountByPlayer.get(card.playerId) || 0;
        yellowCardCountByPlayer.set(card.playerId, current + 1);
      }
    }

    // Calcular canSuspend para cada tarjeta
    const pendingCardsWithStatus = pendingCards.map(card => {
      let canSuspend = false;
      let yellowCount = 0;

      if (card.cardType === CardType.RED) {
        // Roja directa: siempre se puede suspender
        canSuspend = true;
      } else {
        // Amarilla: solo si el jugador llegó al límite
        const playerYellowCount = yellowCardCountByPlayer.get(card.playerId) || 0;
        yellowCount = playerYellowCount;
        canSuspend = playerYellowCount >= yellowCardLimit;
      }

      return {
        ...card,
        canSuspend,
        yellowCount,
      };
    });

    // Suspensiones ACTIVE (vigentes - aún tienen partidos pendientes)
    const activeSuspensions = await this.prisma.playerSuspension.findMany({
      where: {
        tournamentId,
        status: SuspensionStatus.ACTIVE,
        remainingMatches: { gt: 0 },
      },
      include: {
        player: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            dni: true,
          },
        },
        originCards: {
          include: {
            card: {
              select: {
                id: true,
                cardType: true,
                matchCategoryId: true,
              },
            },
          },
        },
        servedMatches: {
          select: {
            id: true,
            matchCategoryId: true,
            servedAt: true,
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Suspensiones COMPLETED (cumplidas)
    const completedSuspensions = await this.prisma.playerSuspension.findMany({
      where: {
        tournamentId,
        status: SuspensionStatus.COMPLETED,
      },
      include: {
        player: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            dni: true,
          },
        },
        originCards: {
          include: {
            card: {
              select: {
                id: true,
                cardType: true,
                matchCategoryId: true,
              },
            },
          },
        },
        servedMatches: {
          select: {
            id: true,
            matchCategoryId: true,
            servedAt: true,
          },
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    // Suspensiones CANCELLED (canceladas)
    const cancelledSuspensions = await this.prisma.playerSuspension.findMany({
      where: {
        tournamentId,
        status: SuspensionStatus.CANCELLED,
      },
      include: {
        player: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            dni: true,
          },
        },
        originCards: {
          include: {
            card: {
              select: {
                id: true,
                cardType: true,
                matchCategoryId: true,
              },
            },
          },
        },
        servedMatches: {
          select: {
            id: true,
            matchCategoryId: true,
            servedAt: true,
          },
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    // Deducciones
    const deductions = await this.prisma.pointDeduction.findMany({
      where: {
        tournamentId,
      },
      include: {
        club: {
          select: {
            id: true,
            name: true,
          },
        },
        tournamentCategory: {
          include: {
            category: {
              select: {
                name: true,
              },
            },
          },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    const mapSuspension = (s: typeof activeSuspensions[0]): SuspensionResponseDto => ({
      ...s,
      originCards: s.originCards.map(oc => ({
        id: oc.card.id,
        cardType: oc.card.cardType,
        matchCategoryId: oc.card.matchCategoryId,
      })),
    });

    return {
      pending: pendingCardsWithStatus,
      active: activeSuspensions.map(mapSuspension),
      completed: completedSuspensions.map(mapSuspension),
      cancelled: cancelledSuspensions.map(mapSuspension),
      deductions,
    };
  }

  // ============================================================================
  // REGLAS DISCIPLINARIAS
  // ============================================================================

  async getOrCreateDisciplinaryRules(tournamentId: number): Promise<DisciplinaryRulesResponseDto> {
    let rules = await this.prisma.tournamentDisciplinaryRules.findUnique({
      where: { tournamentId },
    });

    if (!rules) {
      rules = await this.prisma.tournamentDisciplinaryRules.create({
        data: {
          tournamentId,
          yellowCardLimit: DefaultDisciplinaryRules.yellowCardLimit,
          yellowLimitSuspensionMatches: DefaultDisciplinaryRules.yellowLimitSuspensionMatches,
          directRedSuspensionMatches: DefaultDisciplinaryRules.directRedSuspensionMatches,
          doubleYellowSuspensionMatches: DefaultDisciplinaryRules.doubleYellowSuspensionMatches,
          resetYellowsOnPhaseChange: DefaultDisciplinaryRules.resetYellowsOnPhaseChange,
        },
      });
    }

    return rules;
  }

  async updateDisciplinaryRules(
    tournamentId: number,
    dto: UpdateDisciplinaryRulesDto,
  ): Promise<DisciplinaryRulesResponseDto> {
    await this.getOrCreateDisciplinaryRules(tournamentId);

    const updated = await this.prisma.tournamentDisciplinaryRules.update({
      where: { tournamentId },
      data: dto,
    });

    return updated;
  }

  // ============================================================================
  // CUMPLIMIENTO DE SUSPENSIONES AL CERRAR JORNADA
  // ============================================================================

  async processMatchdaySuspensions(matchdayId: number): Promise<void> {
    const matchday = await this.prisma.zoneMatchday.findUnique({
      where: { id: matchdayId },
      include: {
        zone: true,
      },
    });

    if (!matchday) {
      throw new NotFoundException('Jornada no encontrada');
    }

    const tournamentId = matchday.zone.tournamentId;

    // Obtener todos los partidos de esta jornada con sus categorías cerradas
    const matches = await this.prisma.match.findMany({
      where: {
        zoneId: matchday.zoneId,
        matchday: matchday.matchday,
      },
      include: {
        categories: {
          where: {
            closedAt: { not: null },
          },
        },
      },
    });

    // Obtener todos los MatchCategory cerrados
    const closedMatchCategories: Array<{ id: number; match: { homeClubId: number | null; awayClubId: number | null } }> = [];
    for (const match of matches) {
      for (const category of match.categories) {
        closedMatchCategories.push({
          id: category.id,
          match: {
            homeClubId: match.homeClubId,
            awayClubId: match.awayClubId,
          },
        });
      }
    }

    if (closedMatchCategories.length === 0) {
      return;
    }

    // Obtener clubes que jugaron en esta jornada
    const clubIds = new Set<number>();
    for (const mc of closedMatchCategories) {
      if (mc.match.homeClubId !== null) {
        clubIds.add(mc.match.homeClubId);
      }
      if (mc.match.awayClubId !== null) {
        clubIds.add(mc.match.awayClubId);
      }
    }

    // Buscar suspensiones ACTIVE de jugadores de esos clubes
    const activeSuspensions = await this.prisma.playerSuspension.findMany({
      where: {
        tournamentId,
        status: SuspensionStatus.ACTIVE,
        remainingMatches: { gt: 0 },
        player: {
          playerTournamentClubs: {
            some: {
              tournamentId,
              clubId: { in: Array.from(clubIds) },
            },
          },
        },
      },
    });

    if (activeSuspensions.length === 0) {
      return;
    }

    // Procesar cada suspensión
    await this.prisma.$transaction(async (tx) => {
      for (const suspension of activeSuspensions) {
        // Para cada partido cerrado, registrar que cumplió la suspensión
        for (const matchCategory of closedMatchCategories) {
          const match = matchCategory.match;

          // Verificar si el jugador pertenece a alguno de los clubes que jugaron
          const possibleClubIds = [match.homeClubId, match.awayClubId].filter((id): id is number => id !== null);
          if (possibleClubIds.length === 0) {
            continue;
          }
          
          const playerClub = await tx.playerTournamentClub.findFirst({
            where: {
              playerId: suspension.playerId,
              tournamentId,
              clubId: {
                in: possibleClubIds,
              },
            },
          });

          if (!playerClub) {
            continue;
          }

          // Verificar si ya existe el registro
          const existing = await tx.suspensionServedMatch.findUnique({
            where: {
              suspensionId_matchCategoryId: {
                suspensionId: suspension.id,
                matchCategoryId: matchCategory.id,
              },
            },
          });

          if (existing) {
            continue;
          }

          // Crear el registro de cumplimiento
          await tx.suspensionServedMatch.create({
            data: {
              suspensionId: suspension.id,
              matchCategoryId: matchCategory.id,
            },
          });

          // Decrementar remainingMatches
          const updated = await tx.playerSuspension.update({
            where: { id: suspension.id },
            data: {
              remainingMatches: {
                decrement: 1,
              },
            },
          });

          // Si llegó a 0, marcar como COMPLETED
          if (updated.remainingMatches <= 0) {
            await tx.playerSuspension.update({
              where: { id: suspension.id },
              data: {
                status: SuspensionStatus.COMPLETED,
                remainingMatches: 0,
              },
            });
          }
        }
      }
    });
  }
}
