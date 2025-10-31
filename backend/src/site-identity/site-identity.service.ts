import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StorageService } from '../storage/storage.service';
import { SiteIdentity } from '@prisma/client';
import { UpdateSiteIdentityDto } from './dto/update-site-identity.dto';

export interface SiteIdentityResponse {
  title: string;
  iconUrl: string | null;
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
  ): Promise<SiteIdentityResponse> {
    const existing = await this.ensureIdentity();
    let iconKey: string | null | undefined;

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

    const updated = await this.prisma.siteIdentity.upsert({
      where: { id: existing.id },
      update: {
        title: dto.title,
        iconKey: iconKey !== undefined ? iconKey : existing.iconKey,
      },
      create: {
        id: existing.id,
        title: dto.title,
        iconKey: iconKey ?? null,
      },
    });

    return this.toResponse(updated);
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
      },
    });
  }

  private toResponse(identity: SiteIdentity): SiteIdentityResponse {
    return {
      title: identity.title,
      iconUrl: identity.iconKey ? this.storageService.getPublicUrl(identity.iconKey) : null,
    };
  }
}
