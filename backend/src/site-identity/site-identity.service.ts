import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { SiteIdentity } from '@prisma/client';
import { UpdateSiteIdentityDto } from './dto/update-site-identity.dto';
import { promises as fs } from 'fs';
import * as path from 'path';
import { validateLoginImage } from './flyer-template.utils';
import { createHash } from 'crypto';
// eslint-disable-next-line @typescript-eslint/no-var-requires
const sharp = require('sharp');

export interface SiteIdentityResponse {
  title: string;
  iconUrl: string | null;
  favicon: {
    basePath: string;
    updatedAt: number;
  } | null;
  flyerUrl: string | null;
}

export interface SiteIdentityIcon {
  path: string;
  mimeType: string;
}

@Injectable()
export class SiteIdentityService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly storageService: StorageService,
  ) {}

  async getIdentity(): Promise<SiteIdentityResponse> {
    const identity = await this.ensureIdentity();
    return this.toResponse(identity);
  }

  async updateIdentity(
    dto: UpdateSiteIdentityDto,
    iconFile?: Express.Multer.File,
    flyerFile?: Express.Multer.File,
  ): Promise<SiteIdentityResponse> {
    const existing = await this.ensureIdentity();
    let iconKey: string | null | undefined;
    let flyerKey: string | null | undefined;

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

    const updated = await this.prisma.siteIdentity.upsert({
      where: { id: existing.id },
      update: {
        title: dto.title,
        iconKey: iconKey !== undefined ? iconKey : existing.iconKey,
        flyerKey: flyerKey !== undefined ? flyerKey : existing.flyerKey,
      },
      create: {
        id: existing.id,
        title: dto.title,
        iconKey: iconKey ?? null,
        flyerKey: flyerKey ?? null,
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
    const outputDir = path.join(process.cwd(), 'public', 'site-identity', 'icons', hash);
    await fs.mkdir(outputDir, { recursive: true });

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
        await fs.writeFile(path.join(outputDir, filename), buffer);
        return buffer;
      }),
    );

    const icoBuffer = this.createIco(pngBuffers.slice(0, 3), sizes.slice(0, 3));
    await fs.writeFile(path.join(outputDir, 'favicon.ico'), icoBuffer);

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
      start_url: '.',
      scope: '.',
      display: 'standalone',
    };
    await fs.writeFile(
      path.join(outputDir, 'site.webmanifest'),
      JSON.stringify(manifest, null, 2),
    );

    const updated = await this.prisma.siteIdentity.update({
      where: { id: identity.id },
      data: {
        faviconHash: hash,
      },
    });

    return this.toResponse(updated);
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

  private async ensureIdentity(): Promise<SiteIdentity> {
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
  }

  private toResponse(identity: SiteIdentity): SiteIdentityResponse {
    let iconUrl: string | null = null;
    if (identity.iconKey) {
      const version = identity.updatedAt.getTime();
      iconUrl = `/api/v1/site-identity/icon?v=${version}`;
    }
    let favicon: SiteIdentityResponse['favicon'] = null;
    if (identity.faviconHash) {
      favicon = {
        basePath: `/site-identity/icons/${identity.faviconHash}`,
        updatedAt: identity.updatedAt.getTime(),
      };
    }
    let flyerUrl: string | null = null;
    if (identity.flyerKey) {
      const version = identity.updatedAt.getTime();
      flyerUrl = `/api/v1/site-identity/flyer?v=${version}`;
    }
    return {
      title: identity.title,
      iconUrl,
      favicon,
      flyerUrl,
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
      case '.bmp':
        return 'image/bmp';
      default:
        return 'application/octet-stream';
    }
  }

}
