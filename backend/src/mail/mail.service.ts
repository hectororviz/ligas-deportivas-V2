import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createTransport, Transporter } from 'nodemailer';
import SMTPTransport from 'nodemailer/lib/smtp-transport';

@Injectable()
export class MailService {
  private readonly transporter: Transporter;
  private readonly logger = new Logger(MailService.name);

  constructor(private readonly configService: ConfigService) {
    this.transporter = createTransport(this.resolveTransportOptions());
  }

  async sendEmailVerification(email: string, token: string, firstName: string) {
    const frontend = this.configService.get<string>('app.frontendUrl');
    const verificationUrl = this.buildFrontendUrl(frontend, '/verify-email', { token });
    await this.sendMail({
      to: email,
      subject: 'Verifica tu correo electrónico',
      html: `<p>Hola ${firstName},</p><p>Confirma tu cuenta haciendo clic en el siguiente enlace:</p><p><a href="${verificationUrl}">${verificationUrl}</a></p>`
    });
  }

  async sendPasswordReset(email: string, token: string, firstName: string) {
    const frontend = this.configService.get<string>('app.frontendUrl');
    const resetUrl = this.buildFrontendUrl(frontend, '/reset-password', { token });
    await this.sendMail({
      to: email,
      subject: 'Recuperación de contraseña',
      html: `<p>Hola ${firstName},</p><p>Puedes restablecer tu contraseña con el siguiente enlace:</p><p><a href="${resetUrl}">${resetUrl}</a></p>`
    });
  }

  async sendEmailChangeConfirmation(currentEmail: string, newEmail: string, token: string, firstName: string) {
    const frontend = this.configService.get<string>('app.frontendUrl');
    const confirmUrl = this.buildFrontendUrl(frontend, '/confirm-email', { token });
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
      const host = this.configService.get<string>('mail.host');
      const port = this.configService.get<number>('mail.port');
      const normalizedError =
        error instanceof Error ? error : new Error(String(error));

      this.logger.error(
        `Error enviando correo (SMTP ${host ?? 'desconocido'}:${port ?? 'desconocido'})`,
        normalizedError
      );

      throw normalizedError;
    }
  }

  private resolveTransportOptions(): SMTPTransport.Options {
    const host = this.configService.get<string>('mail.host');
    const port = this.configService.get<number>('mail.port') ?? 1025;
    const secureConfig = this.configService.get<boolean | undefined>('mail.secure');
    const requireTls = this.configService.get<boolean | undefined>('mail.requireTls');
    const ignoreTls = this.configService.get<boolean | undefined>('mail.ignoreTls');
    const rejectUnauthorized = this.configService.get<boolean | undefined>('mail.rejectUnauthorized');

    const options: SMTPTransport.Options = {
      host,
      port,
      secure: secureConfig ?? port === 465,
      auth: this.resolveAuth()
    };

    if (requireTls !== undefined) {
      options.requireTLS = requireTls;
    }

    if (ignoreTls !== undefined) {
      options.ignoreTLS = ignoreTls;
    }

    if (rejectUnauthorized !== undefined) {
      options.tls = {
        ...(options.tls ?? {}),
        rejectUnauthorized
      };
    }

    return options;
  }

  private buildFrontendUrl(frontend: string | undefined, route: string, query: Record<string, string>) {
    const normalizedFrontend = frontend ?? '';
    if (!normalizedFrontend) {
      return '';
    }
    const baseUrl = new URL(normalizedFrontend);
    const normalizedRoute = route.startsWith('/') ? route : `/${route}`;
    const fragmentBase = baseUrl.hash ? baseUrl.hash.replace(/^#/, '') : '';
    const cleanedFragment = fragmentBase.replace(/\/$/, '');
    const fragmentPath = cleanedFragment ? `${cleanedFragment}${normalizedRoute}` : normalizedRoute;
    const fragmentUrl = new URL(`http://fragment${fragmentPath}`);
    Object.entries(query).forEach(([key, value]) => {
      fragmentUrl.searchParams.set(key, value);
    });
    baseUrl.hash = `${fragmentUrl.pathname}${fragmentUrl.search}`;
    return baseUrl.toString();
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
