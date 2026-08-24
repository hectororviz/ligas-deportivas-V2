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
      homeClubName: match.homeClub?.shortName || match.homeClub?.name || 'Club local',
      awayClubName: match.awayClub?.shortName || match.awayClub?.name || 'Club visitante',
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
    this.drawTitle(draw, regions, data);
    await this.drawTable(draw, regions, data, addPng);
    this.drawSignLine(draw, regions);
    this.drawCutLine(draw, regions);

    return { stream: draw.build(), images };
  }

  private drawTitle(
    draw: PlanillaPdfDraw,
    regions: ReturnType<typeof buildPlanillaRegions>,
    data: PlanillaPageData,
  ) {
    const { title, detail } = regions;
    draw.setLineWidth(1);
    const size = 14;
    const baseline = title.y + title.height - 6;

    const vsLabel = ' VS ';
    // Estimación de ancho en Helvetica-Bold: ~0.62 del tamaño por carácter.
    const width = (text: string) => text.length * size * 0.62;

    let cursorX = title.x;
    draw.text(data.homeClubName, cursorX, baseline, size, true);
    cursorX += width(data.homeClubName);
    draw.text(vsLabel, cursorX, baseline, size, true);
    cursorX += width(vsLabel);
    draw.text(data.awayClubName, cursorX, baseline, size, true);

    // Detalle del partido en una sola línea.
    draw.setLineWidth(0.5);
    draw.text(
      `${data.leagueName} - ${data.tournamentYear} - ${data.zoneName} - Fecha ${data.matchday}`,
      detail.x,
      detail.y,
      10,
    );
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

  private async drawTable(
    draw: PlanillaPdfDraw,
    regions: ReturnType<typeof buildPlanillaRegions>,
    data: PlanillaPageData,
    addPng: (
      png: Buffer,
      rect: { x: number; y: number; width: number; height: number },
      name: string,
    ) => Promise<void>,
  ): Promise<void> {
    const { tableLabel, columns, clubColumn } = regions;
    draw.setLineWidth(0.8);
    draw.text('RESULTADOS', tableLabel.x, tableLabel.y, 10, true);

    // Primera columna: escudo + nombre corto de cada club (local arriba,
    // visitante abajo).
    draw.setLineWidth(0.6);
    draw.rectTop(clubColumn.local.x, clubColumn.local.y, clubColumn.local.width, clubColumn.local.height);
    draw.rectTop(clubColumn.visitor.x, clubColumn.visitor.y, clubColumn.visitor.width, clubColumn.visitor.height);

    const ops: Promise<void>[] = [];
    const nameX = clubColumn.local.x + 34;
    if (data.homeClubLogo) {
      ops.push(
        addPng(
          data.homeClubLogo.png,
          {
            x: clubColumn.local.x + 4,
            y: clubColumn.local.y + 4,
            width: 26,
            height: 26,
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
            x: clubColumn.visitor.x + 4,
            y: clubColumn.visitor.y + 4,
            width: 26,
            height: 26,
          },
          'LogoAway',
        ),
      );
    }
    draw.text(data.homeClubName, nameX, clubColumn.local.y + 14, 9, true);
    draw.text(data.awayClubName, nameX, clubColumn.visitor.y + 14, 9, true);

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

    await Promise.all(ops);
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

  private drawSignLine(draw: PlanillaPdfDraw, regions: ReturnType<typeof buildPlanillaRegions>) {
    const { signLine } = regions;
    // Línea continua de firma.
    draw.setLineWidth(0.7);
    draw.line(signLine.line.x, signLine.line.y, signLine.line.x + signLine.line.width, signLine.line.y);

    // Etiquetas de los campos debajo de la línea.
    draw.setLineWidth(0.4);
    const cells: { key: 'local' | 'visitor' | 'referee' | 'sign'; label: string }[] = [
      { key: 'local', label: 'Representante Local' },
      { key: 'visitor', label: 'Representante Visitante' },
      { key: 'referee', label: 'Arbitro' },
      { key: 'sign', label: 'Firma' },
    ];
    for (const cell of cells) {
      const rect = signLine.labels[cell.key];
      draw.textCentered(cell.label, rect.x, rect.y, rect.width, 9);
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
