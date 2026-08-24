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
    this.drawTitle(draw, regions, data);
    this.drawTable(draw, regions, data);
    this.drawFooter(draw, regions);
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
    const t = regions.title;
    // Logos chicos a los costados del título "Local VS Visitante".
    const margin = 4;
    if (data.homeClubLogo) {
      ops.push(
        addPng(
          data.homeClubLogo.png,
          {
            x: t.x,
            y: t.y + 2,
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
            x: t.x + t.width - data.awayClubLogo.displayWidth - margin,
            y: t.y + 2,
            width: data.awayClubLogo.displayWidth,
            height: data.awayClubLogo.displayHeight,
          },
          'LogoAway',
        ),
      );
    }
    return Promise.all(ops).then(() => undefined);
  }

  private drawTitle(
    draw: PlanillaPdfDraw,
    regions: ReturnType<typeof buildPlanillaRegions>,
    data: PlanillaPageData,
  ) {
    const { title, info } = regions;
    draw.setLineWidth(0.8);
    const size = 13;
    const baseline = title.y + title.height - 6;

    const homeLogoW = data.homeClubLogo ? data.homeClubLogo.displayWidth + 6 : 0;

    const vsLabel = ' VS ';
    const homeW = data.homeClubName.length * size * 0.48;
    const vsW = vsLabel.length * size * 0.48;
    const awayW = data.awayClubName.length * size * 0.48;

    let cursorX = title.x + homeLogoW;
    draw.text(data.homeClubName, cursorX, baseline, size, true);
    cursorX += homeW;
    draw.text(vsLabel, cursorX, baseline, size, true);
    cursorX += vsW;
    draw.text(data.awayClubName, cursorX, baseline, size, true);

    draw.setLineWidth(0.5);
    draw.text(`Liga: ${data.leagueName}`, info.league.x, info.league.y, 9.5);
    draw.text(`Torneo: ${data.tournamentName} ${data.tournamentYear}`, info.tournament.x, info.tournament.y, 9.5);
    draw.text(`Zona: ${data.zoneName}`, info.zone.x, info.zone.y, 9.5);
    draw.text(`Fecha (Jornada): ${data.matchday}`, info.date.x, info.date.y, 9.5);
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
    const { tableLabel, columns } = regions;
    draw.setLineWidth(0.8);
    draw.text('RESULTADOS', tableLabel.x, tableLabel.y, 10, true);

    draw.setLineWidth(0.6);
    for (const col of columns) {
      const categoryData = data.categories[col.index];
      const hasCategory = !!categoryData;

      draw.rectTop(col.category.x, col.category.y, col.category.width, col.category.height);
      draw.rectTop(col.local.x, col.local.y, col.local.width, col.local.height);
      draw.rectTop(col.visitor.x, col.visitor.y, col.visitor.width, col.visitor.height);

      if (hasCategory) {
        draw.textCentered(
          categoryData.name,
          col.category.x,
          col.category.y + 6,
          col.category.width,
          8,
          true,
        );
      } else {
        this.drawCross(draw, col.local);
        this.drawCross(draw, col.visitor);
      }
    }
  }

  private drawCross(
    draw: PlanillaPdfDraw,
    rect: { x: number; y: number; width: number; height: number },
  ) {
    const inset = 5;
    draw.setLineWidth(1.6);
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

  private drawFooter(draw: PlanillaPdfDraw, regions: ReturnType<typeof buildPlanillaRegions>) {
    const { footer } = regions;
    draw.setLineWidth(0.6);

    const blocks: { key: 'local' | 'visitor' | 'referee'; label: string }[] = [
      { key: 'local', label: 'Representante Local' },
      { key: 'visitor', label: 'Representante Visitante' },
      { key: 'referee', label: 'Referi' },
    ];

    for (const block of blocks) {
      const rect = footer[block.key];
      draw.rectTop(rect.name.x, rect.name.y, rect.name.width, rect.name.height);
      draw.rectTop(rect.sign.x, rect.sign.y, rect.sign.width, rect.sign.height);
      draw.text(block.label, rect.name.x + 4, rect.name.y + 4, 9);
      draw.text('Firma', rect.sign.x + 4, rect.sign.y + 4, 8);
    }
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
