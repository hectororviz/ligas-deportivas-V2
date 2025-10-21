import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import nodemailer, { Transporter } from 'nodemailer';

@Injectable()
export class MailService {
  private readonly transporter: Transporter;
  private readonly logger = new Logger(MailService.name);

  constructor(private readonly configService: ConfigService) {
    this.transporter = nodemailer.createTransport({
      host: this.configService.get<string>('mail.host'),
      port: this.configService.get<number>('mail.port') ?? 1025,
      secure: false,
      auth: this.resolveAuth()
    });
  }

  async sendEmailVerification(email: string, token: string, firstName: string) {
    const frontend = this.configService.get<string>('app.frontendUrl');
    const verificationUrl = `${frontend}/verify-email?token=${token}`;
    await this.sendMail({
      to: email,
      subject: 'Verifica tu correo electrónico',
      html: `<p>Hola ${firstName},</p><p>Confirma tu cuenta haciendo clic en el siguiente enlace:</p><p><a href="${verificationUrl}">${verificationUrl}</a></p>`
    });
  }

  async sendPasswordReset(email: string, token: string, firstName: string) {
    const frontend = this.configService.get<string>('app.frontendUrl');
    const resetUrl = `${frontend}/reset-password?token=${token}`;
    await this.sendMail({
      to: email,
      subject: 'Recuperación de contraseña',
      html: `<p>Hola ${firstName},</p><p>Puedes restablecer tu contraseña con el siguiente enlace:</p><p><a href="${resetUrl}">${resetUrl}</a></p>`
    });
  }

  private async sendMail(options: { to: string; subject: string; html: string }) {
    const from = this.configService.get<string>('mail.from');
    try {
      await this.transporter.sendMail({
        from,
        ...options
      });
    } catch (error) {
      this.logger.error('Error enviando correo', error as Error);
    }
  }

  private resolveAuth() {
    const user = this.configService.get<string>('mail.user');
    const pass = this.configService.get<string>('mail.pass');
    if (user && pass) {
      return { user, pass };
    }
    return undefined;
  }
}
