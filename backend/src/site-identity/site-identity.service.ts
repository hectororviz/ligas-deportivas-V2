import {
  BadRequestException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { Prisma, SiteIdentity } from '@prisma/client';
import { UpdateSiteIdentityDto } from './dto/update-site-identity.dto';
import { promises as fs } from 'fs';
import * as path from 'path';
import { validateLoginImage } from './flyer-template.utils';
import { createHash } from 'crypto';
import { DatabaseSchemaHealthService } from '../prisma/database-schema-health.service';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const sharp = require('sharp');

export interface SiteIdentityResponse {
  title: string;
  slogan: string | null;
  iconUrl: string | null;
  favicon: {
    url: string;
    previewUrl: string;
    updatedAt: number;
  } | null;
  flyerUrl: string | null;
  loadingAnimationUrl: string | null;
  loadingAnimationDuration: number;
  paletteId: string | null;
  homeBackground: HomeBackgroundConfig;
}

export interface HomeBackgroundConfig {
  enabled: boolean;
  opacity: number;
  speed: number;
  shieldSize: number;
  shieldGap: number;
  backgroundColor: string;
}

const DEFAULT_HOME_BACKGROUND: HomeBackgroundConfig = {
  enabled: true,
  opacity: 0.6,
  speed: 25,
  shieldSize: 90,
  shieldGap: 30,
  backgroundColor: '#173d35',
};

export interface SiteIdentityIcon {
  path: string;
  mimeType: string;
}

@Injectable()
export class SiteIdentityService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
    private readonly schemaHealth: DatabaseSchemaHealthService,
  ) { }

  async getIdentity(): Promise<SiteIdentityResponse> {
    const identity = await this.ensureIdentity();
    return this.toResponse(identity);
  }

  async updateIdentity(
    dto: UpdateSiteIdentityDto,
    iconFile?: Express.Multer.File,
    flyerFile?: Express.Multer.File,
    loadingAnimationFile?: Express.Multer.File,
  ): Promise<SiteIdentityResponse> {
    const existing = await this.ensureIdentity();
    let iconKey: string | null | undefined;
    let flyerKey: string | null | undefined;
    let loadingAnimationKey: string | null | undefined;

    if (dto.removeIcon) {
      if (existing.iconKey) {
        await this.storageService.deleteAttachment(existing.iconKey);
      }
      iconKey = null;
    }

    if (iconFile) {
      if (existing.iconKey && !dto.removeIcon) {
        await this.storageService.deleteAttachment(existing.iconKey);
      }
      iconKey = await this.storageService.saveAttachment(iconFile);
    }

    if (dto.removeFlyer) {
      if (existing.flyerKey) {
        await this.storageService.deleteAttachment(existing.flyerKey);
      }
      flyerKey = null;
    }

    if (flyerFile) {
      validateLoginImage(flyerFile);
      if (existing.flyerKey && !dto.removeFlyer) {
        await this.storageService.deleteAttachment(existing.flyerKey);
      }
      flyerKey = await this.storageService.saveAttachment(flyerFile);
    }

    if (dto.removeLoadingAnimation) {
      if (existing.loadingAnimationKey) {
        await this.storageService.deleteAttachment(existing.loadingAnimationKey);
      }
      loadingAnimationKey = null;
    }

    if (loadingAnimationFile) {
      await this.validateLoadingAnimationFile(loadingAnimationFile);
      if (existing.loadingAnimationKey && !dto.removeLoadingAnimation) {
        await this.storageService.deleteAttachment(existing.loadingAnimationKey);
      }
      loadingAnimationKey = await this.storageService.saveAttachment(loadingAnimationFile);
    }

    const updated = await this.prisma.siteIdentity.upsert({
      where: { id: existing.id },
      update: {
        title: dto.title,
        slogan: dto.slogan !== undefined ? (dto.slogan.trim() || null) : existing.slogan,
        iconKey: iconKey !== undefined ? iconKey : existing.iconKey,
        flyerKey: flyerKey !== undefined ? flyerKey : existing.flyerKey,
        loadingAnimationKey:
          loadingAnimationKey !== undefined ? loadingAnimationKey : existing.loadingAnimationKey,
        loadingAnimationDuration:
          dto.loadingAnimationDuration !== undefined
            ? dto.loadingAnimationDuration
            : existing.loadingAnimationDuration,
        paletteId: dto.paletteId !== undefined ? dto.paletteId : existing.paletteId,
        homeBackground: dto.homeBackground !== undefined
          ? this.parseHomeBackground(dto.homeBackground) as unknown as Prisma.InputJsonValue
          : existing.homeBackground,
      },
      create: {
        id: existing.id,
        title: dto.title,
        slogan: dto.slogan?.trim() || null,
        iconKey: iconKey ?? null,
        flyerKey: flyerKey ?? null,
        loadingAnimationKey: loadingAnimationKey ?? null,
        loadingAnimationDuration: dto.loadingAnimationDuration ?? 5000,
        paletteId: dto.paletteId ?? null,
        homeBackground: dto.homeBackground !== undefined
          ? this.parseHomeBackground(dto.homeBackground) as unknown as Prisma.InputJsonValue
          : null,
      },
    });

    return this.toResponse(updated);
  }

  async updateFavicon(file?: Express.Multer.File, remove?: boolean): Promise<SiteIdentityResponse> {
    const identity = await this.ensureIdentity();
    if (remove && file) {
      throw new BadRequestException('No puedes enviar archivo y eliminación al mismo tiempo.');
    }
    if (remove) {
      if (identity.faviconHash) {
        await this.storageService.deleteFavicon(identity.faviconHash);
      }
      const updated = await this.prisma.siteIdentity.update({
        where: { id: identity.id },
        data: {
          faviconHash: null,
        },
      });
      return this.toResponse(updated);
    }

    if (!file?.buffer) {
      throw new BadRequestException('Debes adjuntar un archivo válido.');
    }

    await this.validateFaviconFile(file);
    const hash = createHash('sha256').update(file.buffer).digest('hex');
    if (identity.faviconHash) {
      await this.storageService.deleteFavicon(identity.faviconHash);
    }

    const input = this.createFaviconSharpInput(file);
    const outputPngs: Record<number, string> = {
      16: 'favicon-16x16.png',
      32: 'favicon-32x32.png',
      48: 'favicon-48x48.png',
      180: 'apple-touch-icon.png',
      192: 'android-chrome-192x192.png',
      512: 'android-chrome-512x512.png',
    };
    const sizes = [16, 32, 48, 180, 192, 512];
    const pngBuffers = await Promise.all(
      sizes.map(async (size) => {
        const filename = outputPngs[size];
        const buffer = await input
          .clone()
          .resize(size, size, {
            fit: 'contain',
            background: { r: 0, g: 0, b: 0, alpha: 0 },
          })
          .png()
          .toBuffer();
        await this.storageService.saveFaviconFile(hash, filename, buffer);
        return buffer;
      }),
    );

    const icoBuffer = this.createIco(pngBuffers.slice(0, 3), sizes.slice(0, 3));
    await this.storageService.saveFaviconFile(hash, 'favicon.ico', icoBuffer);

    const manifest = {
      name: identity.title,
      short_name: identity.title,
      icons: [
        {
          src: './android-chrome-192x192.png',
          sizes: '192x192',
          type: 'image/png',
        },
        {
          src: './android-chrome-512x512.png',
          sizes: '512x512',
          type: 'image/png',
        },
      ],
      start_url: '/',
      scope: '/',
      display: 'standalone',
    };
    await this.storageService.saveFaviconFile(
      hash,
      'site.webmanifest',
      Buffer.from(JSON.stringify(manifest, null, 2), 'utf8'),
    );

    const updated = await this.prisma.siteIdentity.update({
      where: { id: identity.id },
      data: {
        faviconHash: hash,
      },
    });

    return this.toResponse(updated);
  }

  async getFaviconFile(filename: string): Promise<SiteIdentityIcon> {
    const identity = await this.ensureIdentity();
    if (!identity.faviconHash) {
      throw new NotFoundException('El sitio no tiene un favicon configurado.');
    }

    let filePath: string;
    try {
      filePath = this.storageService.resolveFaviconPath(identity.faviconHash, filename);
    } catch {
      throw new NotFoundException('El archivo del favicon no existe.');
    }

    try {
      await fs.access(filePath);
    } catch {
      throw new NotFoundException('El archivo del favicon no existe.');
    }

    return {
      path: filePath,
      mimeType: this.getMimeType(path.extname(filePath)),
    };
  }

  async getIconFile(): Promise<SiteIdentityIcon> {
    const identity = await this.ensureIdentity();
    if (!identity.iconKey) {
      throw new NotFoundException('El sitio no tiene un ícono configurado.');
    }

    let filePath: string;
    try {
      filePath = this.storageService.resolveAttachmentPath(identity.iconKey);
    } catch {
      throw new NotFoundException('El archivo del ícono no existe.');
    }

    try {
      await fs.access(filePath);
    } catch {
      throw new NotFoundException('El archivo del ícono no existe.');
    }

    return {
      path: filePath,
      mimeType: this.getMimeType(path.extname(filePath)),
    };
  }

  async getFlyerFile(): Promise<SiteIdentityIcon> {
    const identity = await this.ensureIdentity();
    if (!identity.flyerKey) {
      throw new NotFoundException('El sitio no tiene un flyer configurado.');
    }

    let filePath: string;
    try {
      filePath = this.storageService.resolveAttachmentPath(identity.flyerKey);
    } catch {
      throw new NotFoundException('El archivo del flyer no existe.');
    }

    try {
      await fs.access(filePath);
    } catch {
      throw new NotFoundException('El archivo del flyer no existe.');
    }

    return {
      path: filePath,
      mimeType: this.getMimeType(path.extname(filePath)),
    };
  }

  async getLoadingAnimationFile(): Promise<SiteIdentityIcon> {
    const identity = await this.ensureIdentity();
    if (!identity.loadingAnimationKey) {
      throw new NotFoundException('El sitio no tiene una animación de carga configurada.');
    }

    let filePath: string;
    try {
      filePath = this.storageService.resolveAttachmentPath(identity.loadingAnimationKey);
    } catch {
      throw new NotFoundException('El archivo de la animación no existe.');
    }

    try {
      await fs.access(filePath);
    } catch {
      throw new NotFoundException('El archivo de la animación no existe.');
    }

    return {
      path: filePath,
      mimeType: 'application/json',
    };
  }

  private async ensureIdentity(): Promise<SiteIdentity> {
    if (!this.schemaHealth.isReady()) {
      throw new ServiceUnavailableException('DB not migrated');
    }

    try {
      const existing = await this.prisma.siteIdentity.findUnique({ where: { id: 1 } });
      if (existing) {
        return existing;
      }
      return this.prisma.siteIdentity.create({
        data: {
          id: 1,
          title: 'Ligas Deportivas',
          flyerKey: null,
          faviconHash: null,
        },
      });
    } catch (error) {
      if (this.isSchemaMismatchError(error)) {
        throw new ServiceUnavailableException('DB schema mismatch. Ejecutar migrate job.');
      }
      throw error;
    }
  }

  private toResponse(identity: SiteIdentity): SiteIdentityResponse {
    let iconUrl: string | null = null;
    if (identity.iconKey) {
      const version = identity.updatedAt.getTime();
      iconUrl = `/api/v1/site-identity/icon?v=${version}`;
    }
    let favicon: SiteIdentityResponse['favicon'] = null;
    if (identity.faviconHash) {
      const version = identity.updatedAt.getTime();
      favicon = {
        url: `/api/v1/site-identity/favicon?v=${version}`,
        previewUrl: `/api/v1/site-identity/favicon/preview?v=${version}`,
        updatedAt: version,
      };
    }
    let flyerUrl: string | null = null;
    if (identity.flyerKey) {
      const version = identity.updatedAt.getTime();
      flyerUrl = `/api/v1/site-identity/flyer?v=${version}`;
    }
    let loadingAnimationUrl: string | null = null;
    if (identity.loadingAnimationKey) {
      const version = identity.updatedAt.getTime();
      loadingAnimationUrl = `/api/v1/site-identity/loading-animation?v=${version}`;
    }
    return {
      title: identity.title,
      slogan: identity.slogan ?? null,
      iconUrl,
      favicon,
      flyerUrl,
      loadingAnimationUrl,
      loadingAnimationDuration: identity.loadingAnimationDuration ?? 5000,
      paletteId: identity.paletteId ?? null,
      homeBackground: this.normalizeHomeBackground(identity.homeBackground),
    };
  }

  private parseHomeBackground(raw: string): HomeBackgroundConfig {
    let parsed: unknown = null;
    try {
      parsed = JSON.parse(raw);
    } catch {
      parsed = null;
    }
    return this.normalizeHomeBackground(parsed);
  }

  private normalizeHomeBackground(value: unknown): HomeBackgroundConfig {
    const source =
      value && typeof value === 'object'
        ? (value as Record<string, unknown>)
        : {};
    const clamp = (input: unknown, min: number, max: number, fallback: number) => {
      const num = typeof input === 'number' ? input : Number(input);
      if (!Number.isFinite(num)) return fallback;
      return Math.min(max, Math.max(min, num));
    };
    const isValidHex = (value: unknown): value is string =>
      typeof value === 'string' && /^#[0-9a-fA-F]{6}$/.test(value);
    return {
      enabled: typeof source.enabled === 'boolean' ? source.enabled : DEFAULT_HOME_BACKGROUND.enabled,
      opacity: clamp(source.opacity, 0.1, 0.9, DEFAULT_HOME_BACKGROUND.opacity),
      speed: clamp(source.speed, 10, 40, DEFAULT_HOME_BACKGROUND.speed),
      shieldSize: clamp(source.shieldSize, 60, 120, DEFAULT_HOME_BACKGROUND.shieldSize),
      shieldGap: clamp(source.shieldGap, 10, 50, DEFAULT_HOME_BACKGROUND.shieldGap),
      backgroundColor: isValidHex(source.backgroundColor)
        ? source.backgroundColor
        : DEFAULT_HOME_BACKGROUND.backgroundColor,
    };
  }

  private async validateFaviconFile(file: Express.Multer.File) {
    if (!file?.buffer) {
      throw new BadRequestException('Missing uploaded file buffer');
    }

    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      throw new BadRequestException('El favicon supera el tamaño máximo permitido de 5 MB.');
    }

    const allowed = ['image/svg+xml', 'image/png', 'image/webp'];
    if (!allowed.includes(file.mimetype)) {
      throw new BadRequestException('El favicon debe ser un SVG, PNG o WEBP.');
    }

    if (file.mimetype === 'image/png') {
      let metadata: { width?: number; height?: number };
      try {
        metadata = await sharp(file.buffer).metadata();
      } catch {
        throw new BadRequestException('Invalid image file');
      }
      if (!metadata.width || !metadata.height) {
        throw new BadRequestException('No se pudieron leer las dimensiones del PNG.');
      }
      if (metadata.width < 512 || metadata.height < 512) {
        throw new BadRequestException('El PNG debe medir al menos 512x512 píxeles.');
      }
    }
  }

  private async validateLoadingAnimationFile(file: Express.Multer.File) {
    if (!file?.buffer) {
      throw new BadRequestException('Debes adjuntar un archivo válido.');
    }

    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      throw new BadRequestException('La animación supera el tamaño máximo permitido de 5 MB.');
    }

    if (path.extname(file.originalname).toLowerCase() !== '.json') {
      throw new BadRequestException('La animación debe ser un archivo JSON exportado desde Lottie.');
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(file.buffer.toString('utf8'));
    } catch {
      throw new BadRequestException('El archivo no es un JSON válido.');
    }

    const isObject = parsed && typeof parsed === 'object' && !Array.isArray(parsed);
    if (!isObject) {
      throw new BadRequestException('El JSON no tiene el formato de una animación Lottie.');
    }

    const animation = parsed as Record<string, unknown>;
    const hasLayers = Array.isArray(animation.layers);
    const hasTiming =
      typeof animation.ip === 'number' ||
      typeof animation.op === 'number' ||
      typeof animation.fr === 'number';
    if (!hasLayers && !hasTiming) {
      throw new BadRequestException('El JSON no parece ser una animación Lottie válida.');
    }
  }

  private createFaviconSharpInput(file: Express.Multer.File) {
    if (file.mimetype === 'image/svg+xml') {
      return sharp(file.buffer, { density: 300 });
    }
    return sharp(file.buffer);
  }

  private createIco(buffers: Buffer[], sizes: number[]) {
    const entries = buffers.map((buffer, index) => {
      const size = sizes[index];
      return {
        width: size === 256 ? 0 : size,
        height: size === 256 ? 0 : size,
        buffer,
      };
    });

    const headerSize = 6;
    const entrySize = 16;
    let offset = headerSize + entrySize * entries.length;
    const parts: Buffer[] = [];

    const header = Buffer.alloc(headerSize);
    header.writeUInt16LE(0, 0);
    header.writeUInt16LE(1, 2);
    header.writeUInt16LE(entries.length, 4);
    parts.push(header);

    for (const entry of entries) {
      const dir = Buffer.alloc(entrySize);
      dir.writeUInt8(entry.width, 0);
      dir.writeUInt8(entry.height, 1);
      dir.writeUInt8(0, 2);
      dir.writeUInt8(0, 3);
      dir.writeUInt16LE(1, 4);
      dir.writeUInt16LE(32, 6);
      dir.writeUInt32LE(entry.buffer.length, 8);
      dir.writeUInt32LE(offset, 12);
      parts.push(dir);
      offset += entry.buffer.length;
    }

    for (const entry of entries) {
      parts.push(entry.buffer);
    }

    return Buffer.concat(parts);
  }

  private getMimeType(extension: string) {
    switch (extension.toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      case '.ico':
        return 'image/x-icon';
      case '.json':
        return 'application/json';
      case '.bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }

  private isSchemaMismatchError(error: unknown): boolean {
    if (error instanceof Prisma.PrismaClientKnownRequestError) {
      return error.code === 'P2021' || error.code === 'P2022';
    }

    if (error instanceof Error) {
      const message = error.message.toLowerCase();
      return (
        message.includes('column') ||
        message.includes('relation') ||
        message.includes('does not exist')
      );
    }

    return false;
  }

}
