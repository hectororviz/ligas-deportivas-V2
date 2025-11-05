import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class CaptchaService {
  private readonly logger = new Logger(CaptchaService.name);

  constructor(private readonly configService: ConfigService) {}

  async verify(token: string): Promise<void> {
    if (!token) {
      throw new BadRequestException('Captcha requerido');
    }

    const secret = this.configService.get<string>('captcha.secret')?.trim();
    if (!secret) {
      this.logger.warn('Captcha deshabilitado por falta de secret, solo válido en entornos de desarrollo.');
      return;
    }

    const provider = this.configService.get<string>('captcha.provider');

    const endpoint = provider === 'hcaptcha'
      ? 'https://hcaptcha.com/siteverify'
      : 'https://challenges.cloudflare.com/turnstile/v0/siteverify';

    const response = await axios.post(
      endpoint,
      new URLSearchParams({
        secret,
        response: token
      }),
      {
        headers: {
          'content-type': 'application/x-www-form-urlencoded'
        }
      }
    );

    if (!response.data.success) {
      throw new BadRequestException('Captcha inválido');
    }
  }
}
