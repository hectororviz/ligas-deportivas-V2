import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { promises as fs } from 'fs';
import * as path from 'path';
import { randomUUID } from 'crypto';

@Injectable()
export class StorageService {
  private readonly uploadDir: string;
  private readonly baseUrl?: string;

  constructor(private readonly configService: ConfigService) {
    this.uploadDir = path.resolve(process.cwd(), 'storage', 'uploads');
    this.baseUrl = this.configService.get<string>('storage.baseUrl');
  }

  async saveAttachment(file: Express.Multer.File): Promise<string> {
    await fs.mkdir(this.uploadDir, { recursive: true });
    const extension = path.extname(file.originalname);
    const filename = `${randomUUID()}${extension}`;
    const filepath = path.join(this.uploadDir, filename);
    await fs.writeFile(filepath, file.buffer);
    return filename;
  }

  getPublicUrl(key: string) {
    if (this.baseUrl) {
      return `${this.baseUrl.replace(/\/$/, '')}/${key}`;
    }
    return `/attachments/${key}`;
  }
}
