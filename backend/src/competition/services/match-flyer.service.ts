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
  dateLine: string;
  timeLine: string;
  roundLine: string;
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

  async generate(matchId: number): Promise<Buffer> {
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
      zoneName: match.zone.name,
      homeClubName: match.homeClub?.shortName || match.homeClub?.name || 'Local',
      awayClubName: match.awayClub?.shortName || match.awayClub?.name || 'Visitante',
      dateLine: this.resolveDateLine(match),
      timeLine: this.resolveTimeLine(match),
      roundLine: this.resolveRoundLine(match.round),
      addressLine: this.resolveAddress(match.homeClub?.name),
      categories: this.buildCategories(match),
      baseImage: flyerBase,
      homeLogo,
      awayLogo,
    };

    const svg = this.buildSvg(context);
    return Buffer.from(svg, 'utf8');
  }

  private resolveDateLine(match: Match) {
    return match.date ? dayjs(match.date).format('dddd DD [de] MMMM YYYY') : 'Fecha a confirmar';
  }

  private resolveTimeLine(match: Match) {
    return match.date ? dayjs(match.date).format('HH:mm') : 'Horario a confirmar';
  }

  private resolveRoundLine(round: Round) {
    switch (round) {
      case Round.FIRST:
        return 'Primera rueda';
      case Round.SECOND:
        return 'Segunda rueda';
      default:
        return 'Rueda sin especificar';
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
        const dy = index === 0 ? 0 : 52;
        return `<tspan x="80" dy="${dy}">${this.escape(cat.time)} · ${this.escape(cat.name)}</tspan>`;
      })
      .join('');

    const tournament = this.escape(context.tournamentName);
    const zone = this.escape(context.zoneName);
    const home = this.escape(context.homeClubName);
    const away = this.escape(context.awayClubName);

    return `<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">
  <defs>
    <style>
      .title { font: 700 52px 'Arial', sans-serif; fill: #ffffff; }
      .subtitle { font: 600 34px 'Arial', sans-serif; fill: #f1f5f9; }
      .label { font: 600 30px 'Arial', sans-serif; fill: #ffffff; }
      .info { font: 500 32px 'Arial', sans-serif; fill: #ffffff; }
      .category { font: 500 32px 'Arial', sans-serif; fill: #0f172a; }
      .address { font: 600 30px 'Arial', sans-serif; fill: #ffffff; }
    </style>
  </defs>
  <image href="${context.baseImage.dataUri}" x="0" y="0" width="1080" height="1920" preserveAspectRatio="xMidYMid slice" />
  <rect x="0" y="0" width="1080" height="1920" fill="rgba(0,0,0,0.35)" />

  <rect x="60" y="80" width="960" height="200" rx="22" fill="rgba(15,23,42,0.65)" />
  <text x="80" y="160" class="title">${tournament}</text>
  <text x="80" y="220" class="subtitle">Zona ${zone}</text>

  ${context.homeLogo ? `<image href="${context.homeLogo}" x="110" y="280" width="220" height="220" />` : ''}
  ${context.awayLogo ? `<image href="${context.awayLogo}" x="750" y="280" width="220" height="220" />` : ''}
  <text x="220" y="540" text-anchor="middle" class="label">${home}</text>
  <text x="860" y="540" text-anchor="middle" class="label">${away}</text>
  <text x="540" y="460" text-anchor="middle" class="subtitle">vs</text>

  <rect x="80" y="600" width="920" height="180" rx="20" fill="rgba(15,23,42,0.55)" />
  <text x="540" y="670" text-anchor="middle" class="info">${this.escape(context.dateLine)}</text>
  <text x="540" y="720" text-anchor="middle" class="info">${this.escape(context.timeLine)} · ${this.escape(context.roundLine)}</text>

  <rect x="60" y="820" width="960" height="720" rx="22" fill="rgba(255,255,255,0.92)" />
  <text x="80" y="900" class="label" fill="#0f172a">Cronograma</text>
  <text x="80" y="960" class="category">${categories}</text>

  <rect x="0" y="1760" width="1080" height="120" fill="rgba(15,23,42,0.8)" />
  <text x="540" y="1834" text-anchor="middle" class="address">${this.escape(context.addressLine)}</text>
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
