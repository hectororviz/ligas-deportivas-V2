import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { StorageService } from '../../storage/storage.service';
import { promises as fs } from 'fs';
import * as path from 'path';
import * as dayjs from 'dayjs';
import 'dayjs/locale/es';
import { Match, Round } from '@prisma/client';

dayjs.locale('es');

interface FlyerContext {
  tournamentName: string;
  zoneName: string;
  homeClubName: string;
  awayClubName: string;
  matchSummaryLine: string;
  addressLine: string;
  categories: { time: string; name: string }[];
  baseImage: { mimeType: string; dataUri: string };
  homeLogo?: string | null;
  awayLogo?: string | null;
}

@Injectable()
export class MatchFlyerService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
  ) {}

  async generate(matchId: number): Promise<{ buffer: Buffer; contentType: string; fileExtension: string }> {
    const [match, identity] = await Promise.all([
      this.prisma.match.findUnique({
        where: { id: matchId },
        include: {
          tournament: true,
          zone: true,
          homeClub: true,
          awayClub: true,
          categories: {
            include: {
              tournamentCategory: { include: { category: true } },
            },
            orderBy: { kickoffTime: 'asc' },
          },
        },
      }),
      this.prisma.siteIdentity.findUnique({ where: { id: 1 } }),
    ]);

    if (!match) {
      throw new NotFoundException('Partido no encontrado.');
    }

    if (!identity?.flyerKey) {
      throw new BadRequestException('El sitio no tiene un flyer configurado.');
    }

    const flyerBase = await this.loadExistingFile(identity.flyerKey, 'flyer');

    const homeLogo = await this.readLogo(match.homeClub?.logoKey);
    const awayLogo = await this.readLogo(match.awayClub?.logoKey);

    const context: FlyerContext = {
      tournamentName: match.tournament.name,
      zoneName: this.resolveZoneName(match.zone.name),
      homeClubName: match.homeClub?.shortName || match.homeClub?.name || 'Local',
      awayClubName: match.awayClub?.shortName || match.awayClub?.name || 'Visitante',
      matchSummaryLine: this.buildMatchSummary(match),
      addressLine: this.resolveAddress(match.homeClub?.shortName || match.homeClub?.name),
      categories: this.buildCategories(match),
      baseImage: flyerBase,
      homeLogo,
      awayLogo,
    };

    const svg = this.buildSvg(context);
    const png = await this.tryRenderPng(svg);

    if (png) {
      return { buffer: png, contentType: 'image/png', fileExtension: 'png' };
    }

    return { buffer: Buffer.from(svg), contentType: 'image/svg+xml', fileExtension: 'svg' };
  }

  private async tryRenderPng(svg: string): Promise<Buffer | null> {
    try {
      const sharpModule = await import('sharp');
      const sharp = (sharpModule as any).default ?? sharpModule;

      return await sharp(Buffer.from(svg))
        .resize(1080, 1920, { fit: 'cover' })
        .png({ quality: 100 })
        .toBuffer();
    } catch (error) {
      // Continue with the SVG fallback when sharp is not available in the environment.
      // eslint-disable-next-line no-console
      console.warn('PNG render skipped because sharp is unavailable:', error);
      return null;
    }
  }

  private resolveZoneName(zoneName: string) {
    if (/^zona\s+/i.test(zoneName)) {
      return zoneName;
    }
    return `Zona ${zoneName}`;
  }

  private buildMatchSummary(match: Match) {
    const datePart = match.date ? dayjs(match.date).format('DD/MM') : 'Fecha a confirmar';
    const roundPart = this.resolveRoundNumber(match.round);
    const matchdayPart = match.matchday ? `Fecha ${match.matchday}` : 'Fecha a confirmar';
    return `${datePart} - ${roundPart} - ${matchdayPart}`;
  }

  private resolveRoundNumber(round: Round) {
    switch (round) {
      case Round.FIRST:
        return 'Rueda 1';
      case Round.SECOND:
        return 'Rueda 2';
      default:
        return 'Rueda a confirmar';
    }
  }

  private resolveAddress(clubName?: string | null) {
    const name = clubName?.trim() || 'Club local';
    return `${name} - Dirección a confirmar`;
  }

  private buildCategories(
    match: Match & {
      categories: {
        kickoffTime: string | null;
        tournamentCategory?: { category?: { name?: string | null } | null };
      }[];
    },
  ) {
    return match.categories
      .map((category) => ({
        time: category.kickoffTime || 'Horario a confirmar',
        name: category.tournamentCategory?.category?.name || 'Categoría',
      }))
      .sort((a, b) => a.time.localeCompare(b.time));
  }

  private async loadExistingFile(key: string, label: string) {
    let filePath: string;
    try {
      filePath = this.storageService.resolveAttachmentPath(key);
    } catch {
      throw new NotFoundException(`El archivo base del ${label} no existe.`);
    }

    try {
      await fs.access(filePath);
    } catch {
      throw new NotFoundException(`El archivo base del ${label} no existe.`);
    }

    const buffer = await fs.readFile(filePath);
    const mimeType = this.getMimeType(path.extname(filePath));
    return {
      mimeType,
      dataUri: `data:${mimeType};base64,${buffer.toString('base64')}`,
    };
  }

  private async readLogo(logoKey?: string | null) {
    if (!logoKey) {
      return null;
    }
    try {
      const filePath = this.storageService.resolveAttachmentPath(logoKey);
      await fs.access(filePath);
      const buffer = await fs.readFile(filePath);
      const mimeType = this.getMimeType(path.extname(filePath));
      return `data:${mimeType};base64,${buffer.toString('base64')}`;
    } catch {
      return null;
    }
  }

  private buildSvg(context: FlyerContext) {
    const categories = context.categories
      .map((cat, index) => {
        const dy = index === 0 ? 0 : 56;
        return `<tspan x="100" dy="${dy}">${this.escape(cat.time)} - ${this.escape(cat.name)}</tspan>`;
      })
      .join('');

    const tournament = this.escape(`Torneo ${context.tournamentName}`);
    const zone = this.escape(context.zoneName);
    const home = this.escape(context.homeClubName);
    const away = this.escape(context.awayClubName);

    return `<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">
  <defs>
    <style>
      .title { font: 800 92px 'Arial', sans-serif; fill: #ffffff; stroke: #000000; stroke-width: 4px; paint-order: stroke fill; }
      .subtitle { font: 700 64px 'Arial', sans-serif; fill: #ffffff; stroke: #000000; stroke-width: 3px; paint-order: stroke fill; }
      .label { font: 700 38px 'Arial', sans-serif; fill: #ffffff; stroke: #000000; stroke-width: 2px; paint-order: stroke fill; }
      .info { font: 700 40px 'Arial', sans-serif; fill: #ffffff; }
      .category { font: 700 36px 'Arial', sans-serif; fill: #0f172a; }
      .section { font: 800 40px 'Arial', sans-serif; fill: #0f172a; }
      .address { font: 700 30px 'Arial', sans-serif; fill: #ffffff; }
    </style>
  </defs>
  <image href="${context.baseImage.dataUri}" x="0" y="0" width="1080" height="1920" preserveAspectRatio="xMidYMid slice" />
  <rect x="0" y="0" width="1080" height="1920" fill="rgba(0,0,0,0.35)" />

  <text x="540" y="170" text-anchor="middle" class="title">${tournament}</text>
  <text x="540" y="260" text-anchor="middle" class="subtitle">${zone}</text>

  ${context.homeLogo ? `<image href="${context.homeLogo}" x="110" y="300" width="260" height="260" />` : ''}
  ${context.awayLogo ? `<image href="${context.awayLogo}" x="710" y="300" width="260" height="260" />` : ''}
  <text x="240" y="620" text-anchor="middle" class="label">${home}</text>
  <text x="840" y="620" text-anchor="middle" class="label">${away}</text>
  <text x="540" y="490" text-anchor="middle" class="subtitle">vs</text>

  <rect x="0" y="660" width="1080" height="120" fill="#000000" />
  <text x="540" y="735" text-anchor="middle" class="info">${this.escape(context.matchSummaryLine)}</text>

  <rect x="70" y="820" width="940" height="260" rx="24" fill="rgba(255,255,255,0.85)" />
  <text x="100" y="900" class="section">Horarios:</text>
  <text x="100" y="960" class="category">${categories}</text>

  <rect x="0" y="1800" width="1080" height="80" fill="#000000" />
  <text x="540" y="1855" text-anchor="middle" class="address">${this.escape(context.addressLine)}</text>
</svg>`;
  }

  private escape(value: string) {
    return value
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#39;');
  }

  private getMimeType(extension: string) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.svg':
        return 'image/svg+xml';
      default:
        return 'application/octet-stream';
    }
  }
}
