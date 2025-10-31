import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { promises as fs } from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';

@Injectable()
export class StorageService {
  private readonly uploadDir: string;
  private readonly avatarDir: string;
  private readonly baseUrl?: string;

  constructor(private readonly configService: ConfigService) {
    const storageRoot = path.resolve(process.cwd(), 'storage');
    this.uploadDir = path.join(storageRoot, 'uploads');
    this.avatarDir = path.join(storageRoot, 'avatars');
    this.baseUrl = this.configService.get<string>('storage.baseUrl');
  }

  async saveAttachment(file: Express.Multer.File): Promise<string> {
    await fs.mkdir(this.uploadDir, { recursive: true });
    const extension = path.extname(file.originalname);
    const filename = `${randomUUID()}${extension}`;
    const filepath = path.join(this.uploadDir, filename);
    await fs.writeFile(filepath, file.buffer);
    return path.join('uploads', filename);
  }

  async deleteAttachment(key: string) {
    if (!key) {
      return;
    }
    const normalizedKey = key.replace(/^\/+/, '');
    const filePath = path.join(process.cwd(), 'storage', normalizedKey);
    await fs.rm(filePath, { force: true });
  }

  async clearAvatarVariants(userId: number) {
    const dir = path.join(this.avatarDir, String(userId));
    await fs.rm(dir, { recursive: true, force: true });
  }

  async saveAvatarVariant(options: {
    userId: number;
    hash: string;
    size: number;
    buffer: Buffer;
  }): Promise<string> {
    const dir = path.join(this.avatarDir, String(options.userId));
    await fs.mkdir(dir, { recursive: true });
    const filename = `${options.hash}_${options.size}.jpg`;
    const filepath = path.join(dir, filename);
    await fs.writeFile(filepath, options.buffer);
    return path.join('avatars', String(options.userId), filename).replace(/\\/g, '/');
  }

  getPublicUrl(key: string) {
    const normalizedKey = key.replace(/^\/+/, '');
    if (this.baseUrl) {
      return `${this.baseUrl.replace(/\/$/, '')}/${normalizedKey}`;
    }
    return `/storage/${normalizedKey}`;
  }
}
