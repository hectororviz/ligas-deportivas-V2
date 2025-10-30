import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport, Transporter } from 'nodemailer';

@Injectable()
export class MailService {
  private readonly transporter: Transporter;
  private readonly logger = new Logger(MailService.name);

  constructor(private readonly configService: ConfigService) {
    this.transporter = createTransport({
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

  async sendEmailChangeConfirmation(currentEmail: string, newEmail: string, token: string, firstName: string) {
    const frontend = this.configService.get<string>('app.frontendUrl');
    const confirmUrl = `${frontend}/confirm-email?token=${token}`;
    await this.sendMail({
      to: currentEmail,
      subject: 'Confirmación de cambio de correo',
      html: `<p>Hola ${firstName},</p><p>Solicitaste cambiar tu correo a <strong>${newEmail}</strong>.</p><p>Confirma la operación con el siguiente enlace:</p><p><a href="${confirmUrl}">${confirmUrl}</a></p>`
    });
  }

  async sendPasswordChangeConfirmation(email: string, firstName: string) {
    await this.sendMail({
      to: email,
      subject: 'Cambio de contraseña confirmado',
      html: `<p>Hola ${firstName},</p><p>Tu contraseña ha sido actualizada correctamente.</p><p>Si no fuiste tú, por favor contacta al soporte inmediatamente.</p>`
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
