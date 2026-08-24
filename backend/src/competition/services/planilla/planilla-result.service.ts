import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import axios from 'axios';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import sharp = require('sharp');

import { PrismaService } from '../../../prisma/prisma.service';
import { StorageService } from '../../../storage/storage.service';
import { PdfImageObject, buildPngImageObject } from '../../utils/pdf-image';
import { buildPlanillaRegions, SignatureBlock } from './planilla.definitions';
import { PlanillaPdfDraw } from './planilla.pdf-draw';

export interface PlanillaPageData {
  leagueName: string;
  tournamentName: string;
  tournamentYear: number;
  zoneName: string;
  matchday: number;
  matchDateLabel: string;
  homeClubName: string;
  awayClubName: string;
  homeClubLogo: PreparedLogo | null;
  awayClubLogo: PreparedLogo | null;
  categories: {
    name: string;
    tournamentCategoryId: number;
  }[];
}

interface PreparedLogo {
  png: Buffer;
  pngWidth: number;
  pngHeight: number;
  displayWidth: number;
  displayHeight: number;
}

interface PreparedPage {
  stream: string;
  images: PdfImageObject[];
}

@Injectable()
export class PlanillaResultService {
  private readonly logger = new Logger(PlanillaResultService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
  ) {}

  /** Carga los datos reales del partido desde la BD para la planilla. */
  async loadPlanillaData(matchId: number): Promise<PlanillaPageData> {
    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        zone: true,
        tournament: {
          include: {
            league: true,
          },
        },
        homeClub: true,
        awayClub: true,
        categories: {
          include: {
            tournamentCategory: {
              include: { category: true },
            },
          },
        },
      },
    });

    if (!match) {
      throw new NotFoundException('Partido no encontrado.');
    }

    // Mismo criterio de orden que el Listado existente: kickoff time y luego nombre (es-AR).
    const sortedCategories = [...match.categories].sort((left, right) => {
      const leftKickoffTime = left.tournamentCategory?.kickoffTime || left.kickoffTime || '99:99';
      const rightKickoffTime =
        right.tournamentCategory?.kickoffTime || right.kickoffTime || '99:99';

      const byKickoffTime = leftKickoffTime.localeCompare(rightKickoffTime);
      if (byKickoffTime !== 0) {
        return byKickoffTime;
      }

      const leftCategory = left.tournamentCategory?.category?.name || '';
      const rightCategory = right.tournamentCategory?.category?.name || '';
      return leftCategory.localeCompare(rightCategory, 'es-AR');
    });

    return {
      leagueName: match.tournament.league?.name ?? 'Liga',
      tournamentName: match.tournament.name,
      tournamentYear: match.tournament.year,
      zoneName: match.zone?.name ?? 'Sin zona',
      matchday: match.matchday,
      matchDateLabel: this.formatDate(match.date),
      homeClubName: match.homeClub?.shortName || match.homeClub?.name || 'Club local',
      awayClubName: match.awayClub?.shortName || match.awayClub?.name || 'Club visitante',
      homeClubLogo: await this.loadLogoPng(
        match.homeClub?.logoUrl ?? null,
        match.homeClub?.logoKey ?? null,
        34,
      ),
      awayClubLogo: await this.loadLogoPng(
        match.awayClub?.logoUrl ?? null,
        match.awayClub?.logoKey ?? null,
        34,
      ),
      categories: sortedCategories.map((category) => ({
        name: category.tournamentCategory?.category?.name ?? 'Categoría',
        tournamentCategoryId: category.tournamentCategoryId,
      })),
    };
  }

  /** Genera la primera página (planilla) como página PDF preparada. */
  async buildPlanillaPage(matchId: number): Promise<PreparedPage> {
    const data = await this.loadPlanillaData(matchId);
    return this.renderPlanillaPage(data);
  }

  private async renderPlanillaPage(data: PlanillaPageData): Promise<PreparedPage> {
    const regions = buildPlanillaRegions(data.categories.length);

    const draw = new PlanillaPdfDraw();
    const images: PdfImageObject[] = [];

    const addPng = async (
      png: Buffer,
      rect: { x: number; y: number; width: number; height: number },
      name: string,
    ) => {
      const built = await buildPngImageObject(png);
      images.push({ name, width: built.width, height: built.height, object: built.object });
      draw.image(name, rect.x, rect.y, rect.width, rect.height);
    };

    await this.drawHeader(draw, regions, data, addPng);
    this.drawTable(draw, regions, data);
    this.drawSignLine(draw, regions);
    this.drawCutLine(draw, regions);

    return { stream: draw.build(), images };
  }

  private async drawHeader(
    draw: PlanillaPdfDraw,
    regions: ReturnType<typeof buildPlanillaRegions>,
    data: PlanillaPageData,
    addPng: (
      png: Buffer,
      rect: { x: number; y: number; width: number; height: number },
      name: string,
    ) => Promise<void>,
  ): Promise<void> {
    const { title, escudos, detail } = regions;

    const ops: Promise<void>[] = [];
    if (data.homeClubLogo) {
      ops.push(addPng(data.homeClubLogo.png, escudos.local, 'LogoHome'));
    }
    if (data.awayClubLogo) {
      ops.push(addPng(data.awayClubLogo.png, escudos.visitor, 'LogoAway'));
    }

    // Título centrado con los nombres de los clubes.
    draw.setLineWidth(1.2);
    draw.textCentered(
      `${data.homeClubName} VS ${data.awayClubName}`,
      title.x,
      title.y,
      title.width,
      18,
      true,
    );

    // Detalle del partido en una sola línea.
    draw.setLineWidth(0.5);
    const detailParts = [
      data.leagueName,
      `${data.tournamentName} ${data.tournamentYear}`,
      `Zona ${data.zoneName}`,
      `Fecha ${data.matchday}`,
    ];
    if (data.matchDateLabel) {
      detailParts.push(data.matchDateLabel);
    }
    draw.textCentered(detailParts.join(' - '), detail.x, detail.y, detail.width, 10);

    await Promise.all(ops);
  }

  private drawTable(
    draw: PlanillaPdfDraw,
    regions: ReturnType<typeof buildPlanillaRegions>,
    data: PlanillaPageData,
  ) {
    const { tableLabel, rowLabels, columns } = regions;
    draw.setLineWidth(0.8);
    draw.text('RESULTADOS', tableLabel.x, tableLabel.y, 10, true);

    if (columns.length === 0) {
      draw.setLineWidth(0.6);
      draw.textCentered(
        'Sin categorías para este partido',
        tableLabel.x,
        tableLabel.y + 24,
        tableLabel.width,
        9,
      );
      return;
    }

    // Etiquetas LOCAL / VISITANTE al costado izquierdo de la tabla.
    draw.setLineWidth(0.6);
    draw.textCentered(
      'LOCAL',
      rowLabels.local.x,
      rowLabels.local.y + 16,
      rowLabels.local.width,
      9,
      true,
    );
    draw.textCentered(
      'VISITANTE',
      rowLabels.visitor.x,
      rowLabels.visitor.y + 16,
      rowLabels.visitor.width,
      9,
      true,
    );

    draw.setLineWidth(0.6);
    for (const col of columns) {
      const categoryData = data.categories[col.index];

      draw.rectTop(col.category.x, col.category.y, col.category.width, col.category.height);
      draw.rectTop(col.local.x, col.local.y, col.local.width, col.local.height);
      draw.rectTop(col.visitor.x, col.visitor.y, col.visitor.width, col.visitor.height);

      if (categoryData) {
        draw.textCentered(
          categoryData.name,
          col.category.x,
          col.category.y + 6,
          col.category.width,
          8,
          true,
        );
      }
    }
  }

  private drawSignLine(draw: PlanillaPdfDraw, regions: ReturnType<typeof buildPlanillaRegions>) {
    const { signLine } = regions;

    const drawBlock = (block: SignatureBlock, label: string) => {
      // Línea de fondo (firma).
      draw.setLineWidth(0.8);
      draw.line(block.line.x, block.line.y, block.line.x + block.line.width, block.line.y);
      // Etiqueta "Rep. X - Firma y aclaracion" debajo, centrada.
      draw.setLineWidth(0.4);
      draw.textCentered(label, block.label.x, block.label.y, block.label.width, 9, true);
    };

    drawBlock(signLine.local, 'Rep. Local - Firma y aclaracion');
    drawBlock(signLine.visitor, 'Rep. Visitante - Firma y aclaracion');
    drawBlock(signLine.referee, 'Arbitro - Firma y aclaracion');
  }

  private drawCutLine(draw: PlanillaPdfDraw, regions: ReturnType<typeof buildPlanillaRegions>) {
    draw.setDash('[3 3] 0 d');
    draw.setLineWidth(0.4);
    draw.line(16, regions.cutLineY, 595.28 - 16, regions.cutLineY);
    draw.setDash('[] 0 d');
  }

  private formatDate(date: Date | null): string {
    if (!date) {
      return '';
    }
    const day = String(date.getUTCDate()).padStart(2, '0');
    const month = String(date.getUTCMonth() + 1).padStart(2, '0');
    return `${day}/${month}/${date.getUTCFullYear()}`;
  }

  private async loadLogoPng(
    logoUrl: string | null,
    logoKey: string | null,
    maxSize: number,
  ): Promise<PreparedLogo | null> {
    const buffer = await this.readLogoBuffer(logoUrl, logoKey);
    if (!buffer) {
      return null;
    }
    try {
      const { data, info } = await sharp(buffer)
        .flatten({ background: '#ffffff' })
        .png()
        .toBuffer({ resolveWithObject: true });
      if (!info.width || !info.height) {
        return null;
      }
      const scale = Math.min(maxSize / info.width, maxSize / info.height, 1);
      return {
        png: data,
        pngWidth: info.width,
        pngHeight: info.height,
        displayWidth: Number((info.width * scale).toFixed(2)),
        displayHeight: Number((info.height * scale).toFixed(2)),
      };
    } catch (error) {
      this.logger.warn(`No se pudo preparar el escudo para la planilla: ${String(error)}`);
      return null;
    }
  }

  private async readLogoBuffer(
    logoUrl: string | null,
    logoKey: string | null,
  ): Promise<Buffer | null> {
    if (logoKey) {
      try {
        const filePath = this.storageService.resolveAttachmentPath(logoKey);
        return await fs.readFile(filePath);
      } catch (error) {
        this.logger.warn(
          `No se pudo leer el escudo desde storage key "${logoKey}": ${String(error)}`,
        );
      }
    }
    if (!logoUrl) {
      return null;
    }
    try {
      if (logoUrl.startsWith('http://') || logoUrl.startsWith('https://')) {
        const response = await axios.get<ArrayBuffer>(logoUrl, {
          responseType: 'arraybuffer',
          timeout: 5000,
        });
        return Buffer.from(response.data);
      }
      const normalized = logoUrl.startsWith('/') ? logoUrl.slice(1) : logoUrl;
      if (normalized.startsWith('uploads/')) {
        const filePath = path.resolve(process.cwd(), 'storage', normalized);
        return await fs.readFile(filePath);
      }
      const uploadIndex = normalized.indexOf('uploads/');
      if (uploadIndex >= 0) {
        const relativeUploadPath = normalized.slice(uploadIndex);
        const filePath = path.resolve(process.cwd(), 'storage', relativeUploadPath);
        return await fs.readFile(filePath);
      }
      this.logger.warn(`No se pudo resolver la ruta del escudo a partir de logoUrl="${logoUrl}".`);
      return null;
    } catch (error) {
      this.logger.warn(`No se pudo cargar el escudo desde "${logoUrl}": ${String(error)}`);
      return null;
    }
  }
}
