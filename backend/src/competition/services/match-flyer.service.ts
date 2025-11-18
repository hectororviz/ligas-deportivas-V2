import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
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
  private resvgModule?: Promise<typeof import('@resvg/resvg-js')>;
  private sharpModule?: Promise<typeof import('sharp')>;

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

    try {
      const rendered = await this.renderFlyer(svg);
      return rendered;
    } catch (error) {
      if (error instanceof BadRequestException && this.isRendererUnavailable(error.message)) {
        const fallbackRender = await this.renderWithSharp(svg, 'jpeg');
        if (fallbackRender) {
          return fallbackRender;
        }

        return this.buildSvgResponse(svg);
      }

      throw error;
    }
  }

  private async renderFlyer(svg: string) {
    try {
      const Resvg = await this.loadResvg();
      const renderer = new Resvg(svg, { fitTo: { mode: 'original' } });
      const image = renderer.render();
      return { buffer: Buffer.from(image.asPng()), contentType: 'image/png', fileExtension: 'png' };
    } catch (error) {
      if (error instanceof BadRequestException && this.isRendererUnavailable(error.message)) {
        const sharpRender = await this.renderWithSharp(svg, 'jpeg');
        if (sharpRender) {
          return sharpRender;
        }

        return this.buildSvgResponse(svg);
      }

      throw error;
    }
  }

  private isRendererUnavailable(message?: string) {
    if (!message) return false;
    return message.includes('@resvg/resvg-js');
  }

  private async renderWithSharp(svg: string, format: 'png' | 'jpeg' = 'png') {
    try {
      const sharp = await this.loadSharp();
      const transformer = sharp(Buffer.from(svg));
      const buffer =
        format === 'jpeg' ? await transformer.jpeg({ quality: 90 }).toBuffer() : await transformer.png().toBuffer();
      const contentType = format === 'jpeg' ? 'image/jpeg' : 'image/png';
      const fileExtension = format === 'jpeg' ? 'jpg' : 'png';
      return { buffer, contentType, fileExtension };
    } catch (error) {
      if (error instanceof BadRequestException && this.isSharpUnavailable(error.message)) {
        return null;
      }

      throw new InternalServerErrorException('No se pudo renderizar el flyer.');
    }
  }

  private buildSvgResponse(svg: string) {
    return {
      buffer: Buffer.from(svg, 'utf8'),
      contentType: 'image/svg+xml',
      fileExtension: 'svg',
    };
  }

  private async loadResvg() {
    if (!this.resvgModule) {
      this.resvgModule = import('@resvg/resvg-js');
    }

    try {
      const module = await this.resvgModule;
      return module.Resvg;
    } catch (error) {
      this.resvgModule = undefined;
      if (error instanceof Error && /Cannot find module/.test(error.message)) {
        throw new BadRequestException(
          'No se pudo cargar el renderizador de flyers. Verifica que la dependencia "@resvg/resvg-js" esté instalada.',
        );
      }

      throw new InternalServerErrorException('No se pudo inicializar el renderizador de flyers.');
    }
  }

  private async loadSharp() {
    if (!this.sharpModule) {
      this.sharpModule = import('sharp');
    }

    try {
      const module = await this.sharpModule;
      const sharpFn = (module as unknown as typeof import('sharp')).default || (module as unknown as any);
      return sharpFn as unknown as typeof import('sharp');
    } catch (error) {
      this.sharpModule = undefined;
      if (error instanceof Error && /Cannot find module/.test(error.message)) {
        throw new BadRequestException(
          'No se pudo cargar el renderizador de flyers. Verifica que la dependencia "sharp" esté instalada.',
        );
      }

      throw new InternalServerErrorException('No se pudo inicializar el renderizador de flyers.');
    }
  }

  private isSharpUnavailable(message?: string) {
    if (!message) return false;
    return message.includes('sharp');
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
    const categoryLines = context.categories.map((cat) => `${this.escape(cat.time)} - ${this.escape(cat.name)}`);
    const lineHeight = 80;
    const categories = categoryLines
      .map((line, index) => {
        const dy = index === 0 ? 0 : lineHeight;
        return `<tspan x="140" dy="${dy}">${line}</tspan>`;
      })
      .join('');

    const tournament = this.escape(`Torneo ${context.tournamentName}`);
    const zone = this.escape(context.zoneName);
    const home = this.escape(context.homeClubName);
    const away = this.escape(context.awayClubName);

    return `<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" width="1080" height="1920" viewBox="0 0 1080 1920">
  <defs>
    <style>
      .eyebrow { font: 900 72px 'Arial', sans-serif; fill: #3f6212; letter-spacing: 4px; }
      .title { font: 900 124px 'Arial', sans-serif; fill: #111827; }
      .subtitle { font: 800 84px 'Arial', sans-serif; fill: #4b5563; }
      .label { font: 900 60px 'Arial', sans-serif; fill: #111827; }
      .info { font: 800 52px 'Arial', sans-serif; fill: #ffffff; letter-spacing: 2px; }
      .category { font: 800 56px 'Arial', sans-serif; fill: #111827; }
      .section { font: 900 62px 'Arial', sans-serif; fill: #111827; }
      .address { font: 800 40px 'Arial', sans-serif; fill: #ffffff; letter-spacing: 1px; }
    </style>
  </defs>
  <image href="${context.baseImage.dataUri}" x="0" y="0" width="1080" height="1920" preserveAspectRatio="xMidYMid slice" />

  <text x="540" y="150" text-anchor="middle" class="eyebrow">Torneo</text>
  <text x="540" y="260" text-anchor="middle" class="title">${tournament.replace('Torneo ', '')}</text>
  <text x="540" y="350" text-anchor="middle" class="subtitle">${zone}</text>

  ${context.homeLogo ? `<image href="${context.homeLogo}" x="140" y="420" width="360" height="360" />` : ''}
  ${context.awayLogo ? `<image href="${context.awayLogo}" x="580" y="420" width="360" height="360" />` : ''}
  <text x="320" y="840" text-anchor="middle" class="label">${home}</text>
  <text x="760" y="840" text-anchor="middle" class="label">${away}</text>
  <text x="540" y="670" text-anchor="middle" class="subtitle">vs</text>

  <rect x="0" y="900" width="1080" height="130" fill="#000000" />
  <text x="540" y="985" text-anchor="middle" class="info">${this.escape(context.matchSummaryLine)}</text>

  <text x="120" y="1110" class="section">Horarios</text>
  <text x="140" y="1180" class="category">${categories}</text>

  <rect x="0" y="1820" width="1080" height="70" fill="#000000" />
  <text x="540" y="1870" text-anchor="middle" class="address">${this.escape(context.addressLine)}</text>
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

  private getFileExtensionFromMime(mimeType: string) {
    switch (mimeType.toLowerCase()) {
      case 'image/png':
        return 'png';
      case 'image/jpeg':
        return 'jpg';
      case 'image/svg+xml':
        return 'svg';
      default:
        return 'bin';
    }
  }
}
