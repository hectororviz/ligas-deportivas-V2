import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import axios from 'axios';
import { promises as fs } from 'node:fs';
import path from 'node:path';
import sharp = require('sharp');

import { PrismaService } from '../../../prisma/prisma.service';
import { StorageService } from '../../../storage/storage.service';
import { PdfImageObject, buildPngImageObject } from '../../utils/pdf-image';
import {
  buildPlanillaRegions,
  TEMPLATE_LABEL,
  TEMPLATE_SHORT_LABEL,
  ArucoId,
} from './template-v1.definitions';
import { generateArUcoMarkers, ArucoMarkerAsset } from './aruco.renderer';
import { buildPlanillaQrPayload, generatePlanillaQrPng } from './qr';
import { PlanillaPdfDraw } from './planilla.pdf-draw';

export interface PlanillaPageData {
  matchId: number;
  uuid: string;
  tournamentId: number;
  zoneId: number;
  homeClubId: number;
  awayClubId: number;
  leagueName: string;
  tournamentName: string;
  tournamentYear: number;
  zoneName: string;
  matchday: number;
  matchDateLabel: string;
  homeClubName: string;
  awayClubName: string;
  venue: string;
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
      matchId: match.id,
      uuid: match.uuid,
      tournamentId: match.tournamentId,
      zoneId: match.zoneId,
      homeClubId: match.homeClubId ?? 0,
      awayClubId: match.awayClubId ?? 0,
      leagueName: match.tournament.league?.name ?? 'Liga',
      tournamentName: match.tournament.name,
      tournamentYear: match.tournament.year,
      zoneName: match.zone?.name ?? 'Sin zona',
      matchday: match.matchday,
      matchDateLabel: this.formatDate(match.date),
      homeClubName: match.homeClub?.name ?? 'Club local',
      awayClubName: match.awayClub?.name ?? 'Club visitante',
      venue: match.homeClub?.name ?? 'A confirmar',
      homeClubLogo: await this.loadLogoPng(
        match.homeClub?.logoUrl ?? null,
        match.homeClub?.logoKey ?? null,
        20,
      ),
      awayClubLogo: await this.loadLogoPng(
        match.awayClub?.logoUrl ?? null,
        match.awayClub?.logoKey ?? null,
        20,
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
    const regions = buildPlanillaRegions();
    const qrPng = await generatePlanillaQrPng(
      buildPlanillaQrPayload({
        uuid: data.uuid,
        matchId: data.matchId,
        tournamentId: data.tournamentId,
        zoneId: data.zoneId,
        homeClubId: data.homeClubId,
        awayClubId: data.awayClubId,
      }),
    );
    const arucos = await generateArUcoMarkers(8);

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

    await this.drawArUcos(draw, arucos, regions, addPng);
    await this.drawQr(draw, qrPng, regions, addPng);
    await this.drawLogos(draw, data, regions, addPng);
    this.drawHeader(draw, regions, data);
    this.drawTable(draw, regions, data);
    this.drawAdministrative(draw, regions);
    this.drawCutLine(draw, regions);

    return { stream: draw.build(), images };
  }

  private drawLogos(
    draw: PlanillaPdfDraw,
    data: PlanillaPageData,
    regions: ReturnType<typeof buildPlanillaRegions>,
    addPng: (
      png: Buffer,
      rect: { x: number; y: number; width: number; height: number },
      name: string,
    ) => Promise<void>,
  ): Promise<void> {
    const ops: Promise<void>[] = [];
    const m = regions.matchInfo;
    if (data.homeClubLogo) {
      ops.push(
        addPng(
          data.homeClubLogo.png,
          {
            x: m.x + 2,
            y: m.y + 4,
            width: data.homeClubLogo.displayWidth,
            height: data.homeClubLogo.displayHeight,
          },
          'LogoHome',
        ),
      );
    }
    if (data.awayClubLogo) {
      ops.push(
        addPng(
          data.awayClubLogo.png,
          {
            x: m.x + m.width - data.awayClubLogo.displayWidth - 2,
            y: m.y + 4,
            width: data.awayClubLogo.displayWidth,
            height: data.awayClubLogo.displayHeight,
          },
          'LogoAway',
        ),
      );
    }
    return Promise.all(ops).then(() => undefined);
  }

  private drawHeader(
    draw: PlanillaPdfDraw,
    regions: ReturnType<typeof buildPlanillaRegions>,
    data: PlanillaPageData,
  ) {
    const { title, matchInfo } = regions;
    draw.setLineWidth(1.2);
    draw.textCentered(TEMPLATE_LABEL, title.x, title.y, title.width, 14, true);
    draw.textCentered(TEMPLATE_SHORT_LABEL, title.x, title.y + 16, title.width, 8, true);

    draw.setLineWidth(0.6);

    const nameBaseline = matchInfo.y + 22;
    const nameLeft = matchInfo.x + (data.homeClubLogo ? data.homeClubLogo.displayWidth + 6 : 0);
    const nameRight =
      matchInfo.x + matchInfo.width - (data.awayClubLogo ? data.awayClubLogo.displayWidth + 6 : 0);

    draw.textCentered(
      `PARTIDO #${data.matchId}`,
      matchInfo.x,
      matchInfo.y + 2,
      matchInfo.width,
      12,
      true,
    );

    draw.text(data.homeClubName, nameLeft, nameBaseline, 9, true);
    draw.textRight(data.awayClubName, nameRight, nameBaseline, 9, true);

    draw.text(
      `${data.leagueName} - ${data.tournamentName} ${data.tournamentYear}`,
      matchInfo.x,
      matchInfo.y + 34,
      8.5,
    );
    draw.text(
      `Zona: ${data.zoneName}  |  Jornada: ${data.matchday}`,
      matchInfo.x,
      matchInfo.y + 45,
      8.5,
    );
    draw.text(`Fecha del encuentro: ${data.matchDateLabel}`, matchInfo.x, matchInfo.y + 53, 8.5);
  }

  private drawArUcos(
    draw: PlanillaPdfDraw,
    arucos: ArucoMarkerAsset[],
    regions: ReturnType<typeof buildPlanillaRegions>,
    addPng: (
      png: Buffer,
      rect: { x: number; y: number; width: number; height: number },
      name: string,
    ) => Promise<void>,
  ): Promise<void> {
    const positions: Record<number, { x: number; y: number; width: number; height: number }> = {
      [ArucoId.TOP_LEFT]: regions.arucos.topLeft,
      [ArucoId.TOP_RIGHT]: regions.arucos.topRight,
      [ArucoId.BOTTOM_RIGHT]: regions.arucos.bottomRight,
      [ArucoId.BOTTOM_LEFT]: regions.arucos.bottomLeft,
    };
    const ops: Promise<void>[] = [];
    for (const marker of arucos) {
      const rect = positions[marker.id];
      if (rect) {
        ops.push(addPng(marker.buffer, rect, `Ar${marker.id}`));
      }
    }
    return Promise.all(ops).then(() => undefined);
  }

  private drawQr(
    draw: PlanillaPdfDraw,
    qrPng: Buffer,
    regions: ReturnType<typeof buildPlanillaRegions>,
    addPng: (
      png: Buffer,
      rect: { x: number; y: number; width: number; height: number },
      name: string,
    ) => Promise<void>,
  ): Promise<void> {
    return addPng(qrPng, regions.qr, 'QR');
  }

  private drawTable(
    draw: PlanillaPdfDraw,
    regions: ReturnType<typeof buildPlanillaRegions>,
    data: PlanillaPageData,
  ) {
    const { headers, rows } = regions;
    const { category, local, visitor } = headers;
    draw.setLineWidth(0.8);
    draw.textCentered('CATEGORIA', category.x, category.y, category.width, 9, true);
    draw.textCentered('LOCAL', local.x, local.y, local.width, 9, true);
    draw.textCentered('VISITANTE', visitor.x, visitor.y, visitor.width, 9, true);
    draw.rectTop(category.x, category.y, category.width, category.height);
    draw.rectTop(local.x, local.y, local.width, local.height);
    draw.rectTop(visitor.x, visitor.y, visitor.width, visitor.height);

    const existing = new Set(data.categories.map((c) => c.tournamentCategoryId));

    for (const row of rows) {
      const categoryData = data.categories[row.index];
      draw.setLineWidth(0.6);
      draw.rectTop(row.category.x, row.category.y, row.category.width, row.category.height);
      draw.rectTop(row.local.x, row.local.y, row.local.width, row.local.height);
      draw.rectTop(row.visitor.x, row.visitor.y, row.visitor.width, row.visitor.height);

      const hasCategory = !!categoryData && existing.has(categoryData.tournamentCategoryId);
      if (hasCategory) {
        draw.text(categoryData.name, row.category.x + 4, row.category.y + 5, 9);
      } else {
        this.drawCross(draw, row.local);
        this.drawCross(draw, row.visitor);
      }
    }
  }

  private drawCross(
    draw: PlanillaPdfDraw,
    rect: { x: number; y: number; width: number; height: number },
  ) {
    const inset = 4;
    draw.setLineWidth(1.4);
    draw.line(
      rect.x + inset,
      rect.y + inset,
      rect.x + rect.width - inset,
      rect.y + rect.height - inset,
    );
    draw.line(
      rect.x + rect.width - inset,
      rect.y + inset,
      rect.x + inset,
      rect.y + rect.height - inset,
    );
  }

  private drawAdministrative(
    draw: PlanillaPdfDraw,
    regions: ReturnType<typeof buildPlanillaRegions>,
  ) {
    const { administrative, instruction } = regions;
    draw.setLineWidth(0.6);
    const blocks = [
      { rect: administrative.arbitrator, label: 'Arbitro', sign: null },
      { rect: administrative.arbitratorSign, label: 'Firma', sign: true },
    ];
    for (const block of blocks) {
      draw.rectTop(block.rect.x, block.rect.y, block.rect.width, block.rect.height);
      draw.text(block.label, block.rect.x + 4, block.rect.y + 4, 8.5);
    }
    const secondRow = [
      { rect: administrative.localRepresentative, label: 'Representante Local', sign: false },
      { rect: administrative.localSign, label: 'Firma', sign: true },
      { rect: administrative.visitorRepresentative, label: 'Representante Visitante', sign: false },
      { rect: administrative.visitorSign, label: 'Firma', sign: true },
    ];
    for (const block of secondRow) {
      draw.rectTop(block.rect.x, block.rect.y, block.rect.width, block.rect.height);
      draw.text(block.label, block.rect.x + 4, block.rect.y + 4, 8.5);
    }

    draw.setLineWidth(0.5);
    draw.textCentered(
      'COMPLETAR CADA RESULTADO CON UN UNICO NUMERO CLARO. NO TACHAR NI SUPERPONER VALORES.',
      instruction.x,
      instruction.y,
      instruction.width,
      7.5,
    );
    draw.textCentered(
      'FOTOGRAFIAR LA PLANILLA COMPLETA SIN CUBRIR QR NI MARCADORES.',
      instruction.x,
      instruction.y + 12,
      instruction.width,
      7.5,
    );
  }

  private drawCutLine(draw: PlanillaPdfDraw, regions: ReturnType<typeof buildPlanillaRegions>) {
    draw.setDash('[3 3] 0 d');
    draw.setLineWidth(0.4);
    draw.line(24, regions.cutLineY, 595.28 - 24, regions.cutLineY);
    draw.setDash('[] 0 d');
  }

  private formatDate(date: Date | null): string {
    if (!date) {
      return 'A confirmar';
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
