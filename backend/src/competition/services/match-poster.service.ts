import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { createHash, randomUUID } from 'crypto';
import { promises as fs } from 'fs';
import * as path from 'path';
import axios from 'axios';
import * as dayjs from 'dayjs';
import 'dayjs/locale/es';
import { PrismaService } from '../../prisma/prisma.service';
import { StorageService } from '../../storage/storage.service';
import { PosterLayer, PosterTemplate } from '../types/poster-template.types';
import { Round } from '@prisma/client';

const POSTER_WIDTH = 1080;
const POSTER_HEIGHT = 1920;

dayjs.locale('es');

@Injectable()
export class MatchPosterService {
  private resvgModule?: Promise<typeof import('@resvg/resvg-js')>;
  private readonly logger = new Logger(MatchPosterService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
  ) {}

  async generate(
    matchId: number,
    options: { skipCache?: boolean } = {},
  ): Promise<{ buffer: Buffer; contentType: string; fileExtension: string }> {
    const match = await this.prisma.match.findUnique({
      where: { id: matchId },
      include: {
        tournament: true,
        homeClub: true,
        awayClub: true,
        categories: {
          include: {
            tournamentCategory: { include: { category: true } },
          },
          orderBy: { kickoffTime: 'asc' },
        },
      },
    });

    if (!match) {
      throw new NotFoundException('Partido no encontrado.');
    }

    const template = await this.prisma.tournamentPosterTemplate.findUnique({
      where: { tournamentId: match.tournamentId },
    });

    if (!template) {
      throw new BadRequestException('No se encontró una plantilla de poster configurada para este torneo.');
    }

    const renderModel = await this.buildRenderModel(match, template.template as PosterTemplate, template.backgroundKey);
    const hash = this.computeHash({
      templateVersion: template.version,
      template: template.template,
      match: renderModel.hashSource,
    });

    if (!options.skipCache) {
      const cached = await this.prisma.matchPosterCache.findUnique({ where: { matchId } });
      if (cached && cached.templateVersion === template.version && cached.hash === hash) {
        try {
          const cachedPath = this.storageService.resolveAttachmentPath(cached.storageKey);
          const buffer = await fs.readFile(cachedPath);
          return { buffer, contentType: 'image/png', fileExtension: 'png' };
        } catch (error) {
          this.logger.warn(`No se pudo leer el poster cacheado para match ${matchId}: ${String(error)}`);
        }
      }
    }

    try {
      const svg = await this.renderSvg(renderModel.layers);
      const buffer = await this.renderPng(svg);
      const storageKey = await this.savePosterBuffer(buffer, matchId, template.version, hash);
      await this.prisma.matchPosterCache.upsert({
        where: { matchId },
        update: {
          templateVersion: template.version,
          hash,
          storageKey,
          generatedAt: new Date(),
        },
        create: {
          matchId,
          templateVersion: template.version,
          hash,
          storageKey,
          generatedAt: new Date(),
        },
      });
      return { buffer, contentType: 'image/png', fileExtension: 'png' };
    } catch (error) {
      this.logger.error(
        `Error renderizando poster para match ${matchId} (tournament ${match.tournamentId}, template ${template.version}): ${String(error)}`,
      );
      throw new InternalServerErrorException('No se pudo renderizar el poster.');
    }
  }

  private computeHash(input: Record<string, unknown>) {
    return createHash('sha256').update(JSON.stringify(input)).digest('hex');
  }

  private async buildRenderModel(
    match: {
      id: number;
      date: Date | null;
      matchday: number;
      round: Round;
      tournament: { name: string };
      homeClub?: { name?: string | null; shortName?: string | null; logoKey?: string | null; logoUrl?: string | null } | null;
      awayClub?: { name?: string | null; shortName?: string | null; logoKey?: string | null; logoUrl?: string | null } | null;
      categories: {
        kickoffTime: string | null;
        tournamentCategory?: { category?: { name?: string | null } | null } | null;
      }[];
    },
    template: PosterTemplate,
    backgroundKey: string | null,
  ) {
    const dateLabel = match.date ? dayjs(match.date).format('DD/MM/YYYY') : 'Fecha a confirmar';
    const dayName = match.date ? dayjs(match.date).format('dddd') : '';
    const dayNameNormalized = dayName ? `${dayName[0].toUpperCase()}${dayName.slice(1)}` : '';
    const timeSlots = match.categories
      .map((category) => {
        const name = category.tournamentCategory?.category?.name ?? '';
        if (!category.kickoffTime && !name) {
          return '';
        }
        if (category.kickoffTime && name) {
          return `${category.kickoffTime} ${name}`;
        }
        return category.kickoffTime ?? name;
      })
      .filter(Boolean)
      .join(' · ');

    const homeName = match.homeClub?.shortName ?? match.homeClub?.name ?? 'Local';
    const awayName = match.awayClub?.shortName ?? match.awayClub?.name ?? 'Visitante';

    const [homeLogo, awayLogo] = await Promise.all([
      this.resolveLogo(match.homeClub?.logoKey, match.homeClub?.logoUrl),
      this.resolveLogo(match.awayClub?.logoKey, match.awayClub?.logoUrl),
    ]);

    const placeholderMap: Record<string, string> = {
      'tournament.name': match.tournament.name,
      'match.round': this.resolveRoundLabel(match.round),
      'match.matchday': String(match.matchday ?? ''),
      'match.date': dateLabel,
      'match.dayName': dayNameNormalized,
      'tournament.timeSlots': timeSlots,
      'homeClub.name': homeName,
      'awayClub.name': awayName,
      'venue.name': '',
      'venue.address': '',
      'homeClub.logoUrl': homeLogo ?? '',
      'awayClub.logoUrl': awayLogo ?? '',
    };

    const normalizedLayers = await Promise.all(
      template.layers.map(async (layer) => this.resolveLayer(layer, placeholderMap, backgroundKey)),
    );

    return {
      layers: normalizedLayers,
      hashSource: {
        matchId: match.id,
        dateLabel,
        dayNameNormalized,
        timeSlots,
        homeName,
        awayName,
        homeLogo: homeLogo ? homeLogo.slice(0, 64) : '',
        awayLogo: awayLogo ? awayLogo.slice(0, 64) : '',
      },
    };
  }

  private resolveRoundLabel(round: Round) {
    switch (round) {
      case Round.FIRST:
        return 'Rueda 1';
      case Round.SECOND:
        return 'Rueda 2';
      default:
        return 'Rueda';
    }
  }

  private async resolveLayer(
    layer: PosterLayer,
    placeholders: Record<string, string>,
    backgroundKey: string | null,
  ): Promise<PosterLayer> {
    if (layer.type === 'text') {
      return {
        ...layer,
        text: this.replacePlaceholders(layer.text, placeholders),
      };
    }

    if (layer.type === 'image') {
      let src = layer.src;
      if (!src && layer.isBackground && backgroundKey) {
        src = `storage://${backgroundKey}`;
      }
      const resolvedSrc = this.replacePlaceholders(src ?? '', placeholders);
      const dataUrl = await this.resolveImageSource(resolvedSrc);
      return {
        ...layer,
        src: dataUrl ?? '',
      };
    }

    return layer;
  }

  private replacePlaceholders(text: string, placeholders: Record<string, string>) {
    return text.replace(/\{\{\s*([^}]+)\s*\}\}/g, (_, key) => placeholders[key] ?? '');
  }

  private async resolveLogo(logoKey?: string | null, logoUrl?: string | null) {
    if (logoKey) {
      const filePath = this.storageService.resolveAttachmentPath(logoKey);
      return this.bufferToDataUrl(filePath, await fs.readFile(filePath));
    }
    if (logoUrl) {
      try {
        const response = await axios.get<ArrayBuffer>(logoUrl, { responseType: 'arraybuffer' });
        const mimeType = response.headers['content-type'] ?? this.inferMimeType(logoUrl);
        return this.bufferToDataUrl(logoUrl, Buffer.from(response.data), mimeType);
      } catch {
        return null;
      }
    }
    return null;
  }

  private async resolveImageSource(src: string) {
    if (!src) {
      return null;
    }
    if (src.startsWith('data:')) {
      return src;
    }
    if (src.startsWith('storage://')) {
      const key = src.replace('storage://', '');
      const filePath = this.storageService.resolveAttachmentPath(key);
      const buffer = await fs.readFile(filePath);
      return this.bufferToDataUrl(filePath, buffer);
    }
    if (src.startsWith('/storage/')) {
      const key = src.replace('/storage/', '');
      const filePath = this.storageService.resolveAttachmentPath(key);
      const buffer = await fs.readFile(filePath);
      return this.bufferToDataUrl(filePath, buffer);
    }
    if (src.startsWith('http://') || src.startsWith('https://')) {
      const response = await axios.get<ArrayBuffer>(src, { responseType: 'arraybuffer' });
      const mimeType = response.headers['content-type'] ?? this.inferMimeType(src);
      return this.bufferToDataUrl(src, Buffer.from(response.data), mimeType);
    }

    return src;
  }

  private bufferToDataUrl(reference: string, buffer: Buffer, overrideMime?: string) {
    const mime = overrideMime ?? this.inferMimeType(reference);
    return `data:${mime};base64,${buffer.toString('base64')}`;
  }

  private inferMimeType(value: string) {
    const extension = path.extname(value).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      case '.png':
      default:
        return 'image/png';
    }
  }

  private async renderSvg(layers: PosterLayer[]) {
    const sorted = [...layers].sort((a, b) => (a.zIndex ?? 0) - (b.zIndex ?? 0));
    const body = await Promise.all(sorted.map((layer) => this.layerToSvg(layer)));
    return `<?xml version="1.0" encoding="UTF-8"?>\n` +
      `<svg xmlns="http://www.w3.org/2000/svg" width="${POSTER_WIDTH}" height="${POSTER_HEIGHT}" viewBox="0 0 ${POSTER_WIDTH} ${POSTER_HEIGHT}">` +
      body.join('') +
      '</svg>';
  }

  private async layerToSvg(layer: PosterLayer) {
    const opacity = layer.opacity ?? 1;
    const transform = layer.rotation
      ? `transform="rotate(${layer.rotation} ${layer.x + layer.width / 2} ${layer.y + layer.height / 2})"`
      : '';

    if (layer.type === 'shape') {
      const radius = layer.radius ?? 0;
      const fill = layer.fill ?? 'transparent';
      const stroke = layer.strokeColor ?? 'transparent';
      const strokeWidth = layer.strokeWidth ?? 0;
      return `<rect x="${layer.x}" y="${layer.y}" width="${layer.width}" height="${layer.height}" rx="${radius}" ry="${radius}" fill="${fill}" stroke="${stroke}" stroke-width="${strokeWidth}" opacity="${opacity}" ${transform} />`;
    }

    if (layer.type === 'image') {
      const href = layer.src;
      if (!href) {
        return '';
      }
      const preserve = layer.fit === 'cover' ? 'xMidYMid slice' : 'xMidYMid meet';
      return `<image href="${href}" x="${layer.x}" y="${layer.y}" width="${layer.width}" height="${layer.height}" preserveAspectRatio="${preserve}" opacity="${opacity}" ${transform} />`;
    }

    const textLayer = layer;
    const fontSize = textLayer.fontSize ?? 48;
    const fontFamily = textLayer.fontFamily ?? 'Arial';
    const fontWeight = textLayer.fontWeight ?? 'normal';
    const fontStyle = textLayer.fontStyle ?? 'normal';
    const color = textLayer.color ?? '#ffffff';
    const align = textLayer.align ?? 'left';
    const stroke = textLayer.strokeColor ?? 'transparent';
    const strokeWidth = textLayer.strokeWidth ?? 0;

    const { lines, resolvedFontSize } = this.fitText(textLayer.text ?? '', textLayer.width, fontSize);
    const lineHeight = resolvedFontSize * 1.2;
    const textAnchor = align === 'center' ? 'middle' : align === 'right' ? 'end' : 'start';
    const x = align === 'center'
      ? textLayer.x + textLayer.width / 2
      : align === 'right'
        ? textLayer.x + textLayer.width
        : textLayer.x;
    const y = textLayer.y;

    const tspans = lines
      .map((line, index) => {
        const dy = index === 0 ? 0 : lineHeight;
        return `<tspan x="${x}" dy="${dy}">${this.escapeXml(line)}</tspan>`;
      })
      .join('');

    return `<text x="${x}" y="${y}" font-family="${fontFamily}" font-size="${resolvedFontSize}" font-weight="${fontWeight}" font-style="${fontStyle}" fill="${color}" stroke="${stroke}" stroke-width="${strokeWidth}" text-anchor="${textAnchor}" dominant-baseline="hanging" opacity="${opacity}" ${transform}>${tspans}</text>`;
  }

  private fitText(text: string, maxWidth: number, baseFontSize: number) {
    let fontSize = baseFontSize;
    let lines = this.wrapText(text, maxWidth, fontSize);
    const minFontSize = 14;

    while (lines.length > 2 && fontSize > minFontSize) {
      fontSize -= 2;
      lines = this.wrapText(text, maxWidth, fontSize);
    }

    if (lines.length > 2) {
      lines = lines.slice(0, 2);
      const maxChars = this.estimateMaxChars(maxWidth, fontSize);
      lines[1] = this.truncateWithEllipsis(lines[1], maxChars);
    }

    return { lines, resolvedFontSize: fontSize };
  }

  private wrapText(text: string, maxWidth: number, fontSize: number) {
    const words = text.split(/\s+/).filter(Boolean);
    if (words.length === 0) {
      return [''];
    }
    const maxChars = this.estimateMaxChars(maxWidth, fontSize);
    const lines: string[] = [];
    let current = '';

    for (const word of words) {
      const candidate = current ? `${current} ${word}` : word;
      if (candidate.length <= maxChars) {
        current = candidate;
      } else {
        if (current) {
          lines.push(current);
        }
        current = word;
      }
    }
    if (current) {
      lines.push(current);
    }

    return lines;
  }

  private estimateMaxChars(maxWidth: number, fontSize: number) {
    const averageCharWidth = fontSize * 0.6;
    return Math.max(1, Math.floor(maxWidth / averageCharWidth));
  }

  private truncateWithEllipsis(text: string, maxChars: number) {
    if (text.length <= maxChars) {
      return text;
    }
    if (maxChars <= 1) {
      return '…';
    }
    return `${text.slice(0, Math.max(0, maxChars - 1))}…`;
  }

  private escapeXml(text: string) {
    return text
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&apos;');
  }

  private async renderPng(svg: string) {
    const Resvg = await this.loadResvg();
    try {
      const renderer = new Resvg(svg, {
        fitTo: { mode: 'width', value: POSTER_WIDTH },
      });
      return Buffer.from(renderer.render().asPng());
    } catch (error) {
      throw new InternalServerErrorException('No se pudo renderizar el poster.');
    }
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
          'No se pudo cargar el renderizador de posters. Verifica que la dependencia "@resvg/resvg-js" esté instalada.',
        );
      }

      throw new InternalServerErrorException('No se pudo inicializar el renderizador de posters.');
    }
  }

  private async savePosterBuffer(buffer: Buffer, matchId: number, version: number, hash: string) {
    const dir = path.join(process.cwd(), 'storage', 'uploads', 'posters');
    await fs.mkdir(dir, { recursive: true });
    const filename = `${matchId}-${version}-${hash.slice(0, 8)}-${randomUUID()}.png`;
    const filePath = path.join(dir, filename);
    await fs.writeFile(filePath, buffer);
    return path.join('uploads', 'posters', filename).replace(/\\/g, '/');
  }
}
