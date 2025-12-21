import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { FlyerTemplate } from '@prisma/client';
import { PrismaService } from '../../prisma/prisma.service';
import { StorageService } from '../../storage/storage.service';
import { validateFlyerImage } from '../../site-identity/flyer-template.utils';
import { MatchFlyerService } from './match-flyer.service';

export interface FlyerTemplateResponseDto {
  backgroundUrl: string | null;
  layoutPreviewUrl: string | null;
  layoutFileName: string | null;
  updatedAt: Date | null;
  hasCustomTemplate: boolean;
}

@Injectable()
export class FlyerTemplatesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
    private readonly matchFlyerService: MatchFlyerService,
  ) {}

  async getForCompetition(competitionId: number): Promise<FlyerTemplateResponseDto> {
    await this.ensureTournament(competitionId);
    const template = await this.prisma.flyerTemplate.findUnique({ where: { competitionId } });
    return this.toResponse(template);
  }

  async upsertForCompetition(
    competitionId: number,
    files: { background?: Express.Multer.File; layout?: Express.Multer.File },
  ): Promise<FlyerTemplateResponseDto> {
    if (!files.background && !files.layout) {
      throw new BadRequestException('Debes adjuntar al menos un archivo para actualizar la plantilla.');
    }

    await this.ensureTournament(competitionId);
    const existing = await this.prisma.flyerTemplate.findUnique({ where: { competitionId } });

    let backgroundKey = existing?.backgroundKey ?? null;
    if (files.background) {
      validateFlyerImage(files.background);
      if (backgroundKey) {
        await this.storageService.deleteAttachment(backgroundKey);
      }
      backgroundKey = await this.storageService.saveAttachment(files.background);
    }

    let layoutKey = existing?.layoutKey ?? null;
    let layoutFileName = existing?.layoutFileName ?? null;
    if (files.layout) {
      this.ensureSvg(files.layout);
      if (layoutKey) {
        await this.storageService.deleteAttachment(layoutKey);
      }
      layoutKey = await this.storageService.saveAttachment(files.layout);
      layoutFileName = files.layout.originalname || 'flyer-layout.svg';
    }

    const saved = await this.prisma.flyerTemplate.upsert({
      where: { competitionId },
      update: {
        backgroundKey,
        layoutKey,
        layoutFileName,
      },
      create: {
        competitionId,
        backgroundKey,
        layoutKey,
        layoutFileName,
      },
    });

    return this.toResponse(saved);
  }

  async deleteForCompetition(competitionId: number) {
    await this.ensureTournament(competitionId);
    const existing = await this.prisma.flyerTemplate.findUnique({ where: { competitionId } });
    if (!existing) {
      return { success: true };
    }

    if (existing.backgroundKey) {
      await this.storageService.deleteAttachment(existing.backgroundKey);
    }
    if (existing.layoutKey) {
      await this.storageService.deleteAttachment(existing.layoutKey);
    }

    await this.prisma.flyerTemplate.delete({ where: { competitionId } });
    return { success: true };
  }

  async generatePreviewForCompetition(competitionId: number) {
    await this.ensureTournament(competitionId);
    const template = await this.prisma.flyerTemplate.findUnique({ where: { competitionId } });
    if (!template?.backgroundKey || !template.layoutKey) {
      throw new BadRequestException('Configura un fondo y un layout SVG antes de generar la vista previa.');
    }

    const identity = await this.prisma.siteIdentity.findUnique({ where: { id: 1 } });
    return this.matchFlyerService.previewTemplate({
      backgroundKey: template.backgroundKey,
      layoutKey: template.layoutKey,
      siteTitle: identity?.title ?? 'Ligas Deportivas',
      tokenConfig: identity?.tokenConfig,
    });
  }

  private async ensureTournament(competitionId: number) {
    const tournament = await this.prisma.tournament.findUnique({ where: { id: competitionId } });
    if (!tournament) {
      throw new NotFoundException('Torneo no encontrado.');
    }
  }

  private ensureSvg(file: Express.Multer.File) {
    if (!file || !file.buffer) {
      throw new BadRequestException('El layout SVG es inválido.');
    }
    const isSvgMime = file.mimetype === 'image/svg+xml';
    const hasSvgExtension = !!file.originalname && /\.svg$/i.test(file.originalname);
    if (!isSvgMime && !hasSvgExtension) {
      throw new BadRequestException('El layout debe ser un archivo SVG válido.');
    }
  }

  private toResponse(template: FlyerTemplate | null): FlyerTemplateResponseDto {
    return {
      backgroundUrl: template?.backgroundKey ? this.storageService.getPublicUrl(template.backgroundKey) : null,
      layoutPreviewUrl: null,
      layoutFileName: template?.layoutFileName ?? null,
      updatedAt: template?.updatedAt ?? null,
      hasCustomTemplate: Boolean(template),
    };
  }
}
