import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { StorageService } from '../../storage/storage.service';
import { MatchPosterService } from './match-poster.service';
import { PosterTemplate } from '../types/poster-template.types';

export interface PosterTemplateResponseDto {
  template: PosterTemplate;
  version: number;
  updatedAt: Date | null;
  backgroundUrl: string | null;
  hasCustomTemplate: boolean;
}

@Injectable()
export class PosterTemplatesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
    private readonly matchPosterService: MatchPosterService,
  ) {}

  async getForTournament(tournamentId: number): Promise<PosterTemplateResponseDto> {
    await this.ensureTournament(tournamentId);
    const template = await this.prisma.tournamentPosterTemplate.findUnique({
      where: { tournamentId },
    });
    return this.toResponse(template);
  }

  async upsertForTournament(
    tournamentId: number,
    options: { template: PosterTemplate; background?: Express.Multer.File },
  ): Promise<PosterTemplateResponseDto> {
    await this.ensureTournament(tournamentId);
    if (!options.template || !Array.isArray(options.template.layers)) {
      throw new BadRequestException('La plantilla debe incluir un listado de capas.');
    }

    const existing = await this.prisma.tournamentPosterTemplate.findUnique({
      where: { tournamentId },
    });

    let backgroundKey = existing?.backgroundKey ?? null;
    if (options.background) {
      if (backgroundKey) {
        await this.storageService.deleteAttachment(backgroundKey);
      }
      backgroundKey = await this.storageService.saveAttachment(options.background);
    }

    const version = existing ? existing.version + 1 : 1;
    const saved = await this.prisma.tournamentPosterTemplate.upsert({
      where: { tournamentId },
      update: {
        template: options.template,
        backgroundKey,
        version,
      },
      create: {
        tournamentId,
        template: options.template,
        backgroundKey,
        version,
      },
    });

    return this.toResponse(saved);
  }

  async generatePreviewForTournament(tournamentId: number, matchId: number) {
    await this.ensureTournament(tournamentId);
    const match = await this.prisma.match.findUnique({ where: { id: matchId } });
    if (!match || match.tournamentId !== tournamentId) {
      throw new NotFoundException('Partido no encontrado para este torneo.');
    }
    return this.matchPosterService.generate(matchId, { skipCache: true });
  }

  private async ensureTournament(tournamentId: number) {
    const tournament = await this.prisma.tournament.findUnique({ where: { id: tournamentId } });
    if (!tournament) {
      throw new NotFoundException('Torneo no encontrado.');
    }
  }

  private toResponse(template: {
    template: unknown;
    backgroundKey: string | null;
    version: number;
    updatedAt: Date;
  } | null): PosterTemplateResponseDto {
    if (!template) {
      return {
        template: { layers: [] },
        version: 0,
        updatedAt: null,
        backgroundUrl: null,
        hasCustomTemplate: false,
      };
    }

    return {
      template: template.template as PosterTemplate,
      version: template.version,
      updatedAt: template.updatedAt,
      backgroundUrl: template.backgroundKey
        ? this.storageService.getPublicUrl(template.backgroundKey)
        : null,
      hasCustomTemplate: true,
    };
  }
}
