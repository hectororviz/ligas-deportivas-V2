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
import { Match, MatchStatus, Round, SiteIdentity } from '@prisma/client';

dayjs.locale('es');

type MatchWithFlyerRelations = Match & {
  tournament: { name: string };
  zone: { name: string };
  homeClub?: { name?: string | null; shortName?: string | null; logoKey?: string | null } | null;
  awayClub?: { name?: string | null; shortName?: string | null; logoKey?: string | null } | null;
  categories: {
    kickoffTime: string | null;
    tournamentCategory?: {
      kickoffTime?: string | null;
      category?: { name?: string | null } | null;
    } | null;
  }[];
};

interface FlyerCategoryToken {
  time: string;
  name: string;
}

interface FlyerTemplateContext {
  site: { title: string };
  tournament: { name: string };
  zone: { name: string };
  match: {
    id: number;
    summary: string;
    roundLabel: string;
    matchdayLabel: string;
    dateLabel: string;
    home: { name: string };
    away: { name: string };
  };
  address: { line: string };
  categories: FlyerCategoryToken[];
  assets: {
    background: string;
    backgroundMimeType: string;
    homeLogo?: string | null;
    awayLogo?: string | null;
  };
  custom?: Record<string, unknown>;
}

type TemplateToken = TemplateTextToken | TemplateVariableToken | TemplateSectionToken;

interface TemplateTextToken {
  type: 'text';
  value: string;
}

interface TemplateVariableToken {
  type: 'variable';
  name: string;
  raw: boolean;
}

interface TemplateSectionToken {
  type: 'section';
  name: string;
  tokens: TemplateToken[];
}

@Injectable()
export class MatchFlyerService {
  private resvgModule?: Promise<typeof import('@resvg/resvg-js')>;
  private sharpModule?: typeof import('sharp');

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

    const templateAssets = await this.resolveTemplateAssets(match.tournamentId, identity);
    if (!templateAssets) {
      throw new BadRequestException(
        'No se encontró una plantilla de flyer configurada para este torneo ni a nivel global.',
      );
    }

    const siteIdentity = identity ??
      ({ title: 'Ligas Deportivas', tokenConfig: null } as SiteIdentity);

    const [backgroundAsset, layoutTemplate] = await Promise.all([
      this.loadExistingFile(templateAssets.backgroundKey, 'fondo del flyer'),
      this.readTemplateFile(templateAssets.layoutKey, 'layout del flyer'),
    ]);

    const homeLogo = await this.readLogo(match.homeClub?.logoKey);
    const awayLogo = await this.readLogo(match.awayClub?.logoKey);

    const context = this.buildTemplateContext({
      match,
      identity: siteIdentity,
      background: backgroundAsset,
      homeLogo,
      awayLogo,
    });

    const svg = this.renderTemplate(layoutTemplate, context);

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

  private buildTemplateContext(options: {
    match: MatchWithFlyerRelations;
    identity: SiteIdentity;
    background: { mimeType: string; dataUri: string };
    homeLogo?: string | null;
    awayLogo?: string | null;
  }): FlyerTemplateContext {
    const homeName = options.match.homeClub?.shortName || options.match.homeClub?.name || 'Local';
    const awayName = options.match.awayClub?.shortName || options.match.awayClub?.name || 'Visitante';
    const custom = this.extractCustomConfig(options.identity.tokenConfig);

    return {
      site: { title: options.identity.title },
      tournament: { name: options.match.tournament.name },
      zone: { name: this.resolveZoneName(options.match.zone.name) },
      match: {
        id: options.match.id,
        summary: this.buildMatchSummary(options.match),
        roundLabel: this.resolveRoundNumber(options.match.round),
        matchdayLabel: options.match.matchday ? `Fecha ${options.match.matchday}` : 'Fecha a confirmar',
        dateLabel: options.match.date ? dayjs(options.match.date).format('DD/MM/YYYY') : 'Fecha a confirmar',
        home: { name: homeName },
        away: { name: awayName },
      },
      address: { line: this.resolveAddress(homeName) },
      categories: this.buildCategories(options.match),
      assets: {
        background: options.background.dataUri,
        backgroundMimeType: options.background.mimeType,
        homeLogo: options.homeLogo,
        awayLogo: options.awayLogo,
      },
      custom,
    };
  }

  private renderTemplate(template: string, context: FlyerTemplateContext) {
    const normalizedTemplate = this.normalizeTemplateDelimiters(template);
    const tokens = this.parseTemplate(normalizedTemplate);
    return this.renderTokens(tokens, [context]);
  }

  private normalizeTemplateDelimiters(template: string) {
    if (!template.includes('&#') && !template.includes('&lbrace;') && !template.includes('&rbrace;')) {
      return template;
    }

    return template
      .replace(/&#123;/g, '{')
      .replace(/&#125;/g, '}')
      .replace(/&#x7b;/gi, '{')
      .replace(/&#x7d;/gi, '}')
      .replace(/&lbrace;/gi, '{')
      .replace(/&rbrace;/gi, '}');
  }

  private parseTemplate(template: string) {
    const { tokens } = this.readSection(template, 0);
    return tokens;
  }

  private readSection(template: string, startIndex: number, stopTag?: string): { tokens: TemplateToken[]; index: number } {
    const tokens: TemplateToken[] = [];
    let cursor = startIndex;
    while (cursor < template.length) {
      const openIndex = template.indexOf('{{', cursor);
      if (openIndex === -1) {
        tokens.push({ type: 'text', value: template.slice(cursor) });
        cursor = template.length;
        break;
      }
      if (openIndex > cursor) {
        tokens.push({ type: 'text', value: template.slice(cursor, openIndex) });
      }

      const isTriple = template.startsWith('{{{', openIndex);
      if (isTriple) {
        const closeTriple = template.indexOf('}}}', openIndex + 3);
        if (closeTriple === -1) {
          tokens.push({ type: 'text', value: template.slice(openIndex) });
          cursor = template.length;
          break;
        }
        const name = template.slice(openIndex + 3, closeTriple).trim();
        tokens.push({ type: 'variable', name, raw: true });
        cursor = closeTriple + 3;
        continue;
      }

      const closeIndex = template.indexOf('}}', openIndex + 2);
      if (closeIndex === -1) {
        tokens.push({ type: 'text', value: template.slice(openIndex) });
        cursor = template.length;
        break;
      }

      const tagContent = template.slice(openIndex + 2, closeIndex).trim();
      if (tagContent.startsWith('/')) {
        const closingName = tagContent.slice(1).trim();
        if (stopTag && closingName === stopTag) {
          return { tokens, index: closeIndex + 2 };
        }
        tokens.push({ type: 'text', value: template.slice(openIndex, closeIndex + 2) });
        cursor = closeIndex + 2;
        continue;
      }

      if (tagContent.startsWith('#')) {
        const sectionName = tagContent.slice(1).trim();
        const inner = this.readSection(template, closeIndex + 2, sectionName);
        tokens.push({ type: 'section', name: sectionName, tokens: inner.tokens });
        cursor = inner.index;
        continue;
      }

      if (tagContent.startsWith('!')) {
        cursor = closeIndex + 2;
        continue;
      }

      if (tagContent.startsWith('&')) {
        const name = tagContent.slice(1).trim();
        tokens.push({ type: 'variable', name, raw: true });
        cursor = closeIndex + 2;
        continue;
      }

      if (!tagContent) {
        cursor = closeIndex + 2;
        continue;
      }

      tokens.push({ type: 'variable', name: tagContent, raw: false });
      cursor = closeIndex + 2;
    }

    if (stopTag) {
      throw new BadRequestException(`No se encontró el cierre para la sección "${stopTag}" en la plantilla del flyer.`);
    }

    return { tokens, index: cursor };
  }

  private renderTokens(tokens: TemplateToken[], stack: unknown[]): string {
    let result = '';
    for (const token of tokens) {
      if (token.type === 'text') {
        result += token.value;
        continue;
      }

      if (token.type === 'variable') {
        const value = this.lookupValue(stack, token.name);
        if (value === undefined || value === null) {
          continue;
        }
        const stringValue = typeof value === 'string' ? value : String(value);
        result += token.raw ? stringValue : this.escapeHtml(stringValue);
        continue;
      }

      if (token.type === 'section') {
        const value = this.lookupValue(stack, token.name);
        if (Array.isArray(value)) {
          for (const item of value) {
            const context = this.normalizeContext(item);
            result += this.renderTokens(token.tokens, [context, ...stack]);
          }
          continue;
        }

        if (this.isTruthy(value)) {
          const context = this.normalizeContext(value);
          result += this.renderTokens(token.tokens, [context, ...stack]);
        }
      }
    }
    return result;
  }

  private lookupValue(stack: unknown[], path: string): unknown {
    if (!path) {
      return undefined;
    }

    if (path === '.') {
      return stack[0];
    }

    const segments = path.split('.');
    for (const context of stack) {
      let current: unknown = context;
      let matched = true;
      for (const segment of segments) {
        if (segment === '.') {
          continue;
        }

        if (current === null || current === undefined) {
          matched = false;
          break;
        }

        if (typeof current !== 'object' && typeof current !== 'function') {
          matched = false;
          break;
        }

        current = (current as Record<string, unknown>)[segment];
        if (current === undefined) {
          matched = false;
          break;
        }
      }

      if (matched && current !== undefined) {
        return current;
      }
    }

    return undefined;
  }

  private normalizeContext(value: unknown) {
    if (value && typeof value === 'object') {
      return value as Record<string, unknown>;
    }
    return { '.': value };
  }

  private isTruthy(value: unknown) {
    if (value === false || value === null || value === undefined) {
      return false;
    }
    if (Array.isArray(value)) {
      return value.length > 0;
    }
    return Boolean(value);
  }

  private extractCustomConfig(config: SiteIdentity['tokenConfig']) {
    if (!config || typeof config !== 'object' || Array.isArray(config)) {
      return undefined;
    }
    return config as Record<string, unknown>;
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
    if (this.sharpModule) {
      return this.sharpModule;
    }

    try {
      // eslint-disable-next-line @typescript-eslint/no-var-requires
      const sharp = require('sharp');
      this.sharpModule = sharp as typeof import('sharp');
      return this.sharpModule;
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

  private buildCategories(match: MatchWithFlyerRelations) {
    return [...match.categories]
      .sort((left, right) => {
        const leftKickoffTime = left.tournamentCategory?.kickoffTime || left.kickoffTime || '99:99';
        const rightKickoffTime = right.tournamentCategory?.kickoffTime || right.kickoffTime || '99:99';

        const byKickoffTime = leftKickoffTime.localeCompare(rightKickoffTime);
        if (byKickoffTime !== 0) {
          return byKickoffTime;
        }

        const leftCategory = left.tournamentCategory?.category?.name || '';
        const rightCategory = right.tournamentCategory?.category?.name || '';
        return leftCategory.localeCompare(rightCategory, 'es-AR');
      })
      .map((category) => ({
        time: category.tournamentCategory?.kickoffTime || category.kickoffTime || 'Horario a confirmar',
        name: category.tournamentCategory?.category?.name || 'Categoría',
      }));
  }

  private async loadExistingFile(key: string, label: string) {
    let filePath: string;
    try {
      filePath = this.storageService.resolveAttachmentPath(key);
    } catch {
      throw new NotFoundException(`El archivo del ${label} no existe.`);
    }

    try {
      await fs.access(filePath);
    } catch {
      throw new NotFoundException(`El archivo del ${label} no existe.`);
    }

    const buffer = await fs.readFile(filePath);
    const mimeType = this.getMimeType(path.extname(filePath));
    return {
      mimeType,
      dataUri: `data:${mimeType};base64,${buffer.toString('base64')}`,
    };
  }

  private async readTemplateFile(key: string, label: string) {
    let filePath: string;
    try {
      filePath = this.storageService.resolveAttachmentPath(key);
    } catch {
      throw new NotFoundException(`El archivo del ${label} no existe.`);
    }

    try {
      await fs.access(filePath);
    } catch {
      throw new NotFoundException(`El archivo del ${label} no existe.`);
    }

    return fs.readFile(filePath, 'utf8');
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

  private async resolveTemplateAssets(tournamentId: number, identity: SiteIdentity | null) {
    const competitionTemplate = await this.prisma.flyerTemplate.findUnique({ where: { competitionId: tournamentId } });
    if (competitionTemplate?.backgroundKey && competitionTemplate?.layoutKey) {
      return { backgroundKey: competitionTemplate.backgroundKey, layoutKey: competitionTemplate.layoutKey };
    }

    const defaultTemplate = await this.prisma.flyerTemplate.findFirst({
      where: { competitionId: null },
      orderBy: { id: 'desc' },
    });
    if (defaultTemplate?.backgroundKey && defaultTemplate?.layoutKey) {
      return { backgroundKey: defaultTemplate.backgroundKey, layoutKey: defaultTemplate.layoutKey };
    }

    if (identity?.backgroundImage && identity.layoutSvg) {
      return { backgroundKey: identity.backgroundImage, layoutKey: identity.layoutSvg };
    }

    return null;
  }

  async previewTemplate(options: {
    backgroundKey: string;
    layoutKey: string;
    siteTitle: string;
    tokenConfig?: SiteIdentity['tokenConfig'];
  }) {
    const identity = {
      title: options.siteTitle,
      tokenConfig: options.tokenConfig ?? null,
    } as SiteIdentity;
    const [backgroundAsset, layoutTemplate] = await Promise.all([
      this.loadExistingFile(options.backgroundKey, 'fondo del flyer'),
      this.readTemplateFile(options.layoutKey, 'layout del flyer'),
    ]);
    const context = this.buildTemplateContext({
      match: this.buildPreviewMatch(),
      identity,
      background: backgroundAsset,
      homeLogo: null,
      awayLogo: null,
    });
    const svg = this.renderTemplate(layoutTemplate, context);
    return this.renderFlyer(svg);
  }

  private buildPreviewMatch(): MatchWithFlyerRelations {
    const now = new Date();
    return {
      id: 0,
      tournamentId: 0,
      zoneId: 0,
      matchday: 1,
      round: Round.FIRST,
      date: now,
      status: MatchStatus.PROGRAMMED,
      homeClubId: null,
      awayClubId: null,
      createdAt: now,
      updatedAt: now,
      tournament: { name: 'Torneo de ejemplo' },
      zone: { name: 'Zona A' },
      homeClub: { name: 'Club Local', shortName: 'Local' },
      awayClub: { name: 'Club Visitante', shortName: 'Visitante' },
      categories: [
        { kickoffTime: '09:00', tournamentCategory: { category: { name: 'Sub 12' } } },
        { kickoffTime: '10:30', tournamentCategory: { category: { name: 'Sub 14' } } },
      ],
    } as MatchWithFlyerRelations;
  }

  private escapeHtml(value: string) {
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
