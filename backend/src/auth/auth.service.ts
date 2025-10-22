import {
  BadRequestException,
  Injectable,
  UnauthorizedException
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AccessControlService } from '../rbac/access-control.service';
import { CaptchaService } from '../captcha/captcha.service';
import { MailService } from '../mail/mail.service';
import { RoleKey } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RequestUser } from '../common/interfaces/request-user.interface';
import { randomBytes } from 'crypto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { RequestPasswordResetDto } from './dto/request-password-reset.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

@Injectable()
export class AuthService {
  private readonly refreshTtlSeconds: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    configService: ConfigService,
    private readonly accessControlService: AccessControlService,
    private readonly captchaService: CaptchaService,
    private readonly mailService: MailService
  ) {
    this.refreshTtlSeconds = configService.get<number>('auth.refreshTtl') ?? 604800;
  }

  async register(dto: RegisterDto) {
    await this.captchaService.verify(dto.captchaToken);

    const email = dto.email.toLowerCase();
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new BadRequestException('El correo ya está registrado.');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);

    const user = await this.prisma.user.create({
      data: {
        email,
        passwordHash,
        firstName: dto.firstName,
        lastName: dto.lastName
      }
    });

    await this.accessControlService.assignRoleToUser(user.id, RoleKey.USER);

    const verificationToken = await this.createEmailVerificationToken(user.id);
    await this.mailService.sendEmailVerification(user.email, verificationToken, user.firstName);

    const requestUser = await this.loadRequestUser(user.id);
    const tokens = await this.generateTokens(requestUser);

    return {
      user: requestUser,
      ...tokens
    };
  }

  async validateUser(email: string, password: string): Promise<RequestUser> {
    const user = await this.prisma.user.findUnique({
      where: { email: email.toLowerCase() },
      include: {
        roles: {
          include: {
            league: true,
            club: true,
            category: true,
            role: {
              include: {
                permissions: {
                  include: { permission: true }
                }
              }
            }
          }
        }
      }
    });

    if (!user) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    if (!(await bcrypt.compare(password, user.passwordHash))) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    if (!user.emailVerifiedAt) {
      throw new UnauthorizedException('Debe verificar su correo electrónico.');
    }

    return this.mapToRequestUser(user);
  }

  async login(user: RequestUser | null, dto: LoginDto): Promise<{ user: RequestUser } & AuthTokens> {
    const validated = user ?? (await this.validateUser(dto.email, dto.password));
    const tokens = await this.generateTokens(validated);
    return { user: validated, ...tokens };
  }

  async refreshTokens(dto: RefreshTokenDto): Promise<{ user: RequestUser } & AuthTokens> {
    const { refreshToken } = dto;
    const [idPart, rawToken] = refreshToken.split('.');
    if (!idPart || !rawToken) {
      throw new UnauthorizedException('Refresh token inválido');
    }
    const tokenId = Number(idPart);
    if (Number.isNaN(tokenId)) {
      throw new UnauthorizedException('Refresh token inválido');
    }

    const storedToken = await this.prisma.userToken.findUnique({ where: { id: tokenId } });
    if (!storedToken) {
      throw new UnauthorizedException('Refresh token inválido');
    }

    if (storedToken.expiresAt < new Date()) {
      await this.prisma.userToken.delete({ where: { id: storedToken.id } });
      throw new UnauthorizedException('Refresh token expirado');
    }

    const isValid = await bcrypt.compare(rawToken, storedToken.token);
    if (!isValid) {
      throw new UnauthorizedException('Refresh token inválido');
    }

    const requestUser = await this.loadRequestUser(storedToken.userId);

    await this.prisma.userToken.delete({ where: { id: storedToken.id } });

    const tokens = await this.generateTokens(requestUser);
    return { user: requestUser, ...tokens };
  }

  async logout(refreshToken: string) {
    const [idPart] = refreshToken.split('.');
    if (!idPart) {
      return;
    }
    const tokenId = Number(idPart);
    if (!Number.isNaN(tokenId)) {
      await this.prisma.userToken.delete({ where: { id: tokenId } }).catch(() => undefined);
    }
  }

  async verifyEmail(dto: VerifyEmailDto) {
    const record = await this.prisma.emailVerificationToken.findFirst({
      where: {
        token: dto.token,
        usedAt: null,
        expiresAt: { gt: new Date() }
      }
    });

    if (!record) {
      throw new BadRequestException('Token inválido o expirado');
    }

    await this.prisma.$transaction([
      this.prisma.emailVerificationToken.update({
        where: { id: record.id },
        data: { usedAt: new Date() }
      }),
      this.prisma.user.update({
        where: { id: record.userId },
        data: { emailVerifiedAt: new Date() }
      })
    ]);

    return { success: true };
  }

  async requestPasswordReset(dto: RequestPasswordResetDto) {
    const user = await this.prisma.user.findUnique({ where: { email: dto.email.toLowerCase() } });
    if (!user) {
      return { success: true };
    }

    const token = await this.createPasswordResetToken(user.id);
    await this.mailService.sendPasswordReset(user.email, token, user.firstName);
    return { success: true };
  }

  async resetPassword(dto: ResetPasswordDto) {
    const record = await this.prisma.passwordResetToken.findFirst({
      where: {
        token: dto.token,
        usedAt: null,
        expiresAt: { gt: new Date() }
      }
    });

    if (!record) {
      throw new BadRequestException('Token inválido o expirado');
    }

    const passwordHash = await bcrypt.hash(dto.password, 12);

    await this.prisma.$transaction([
      this.prisma.passwordResetToken.update({
        where: { id: record.id },
        data: { usedAt: new Date() }
      }),
      this.prisma.user.update({
        where: { id: record.userId },
        data: { passwordHash }
      }),
      this.prisma.userToken.deleteMany({ where: { userId: record.userId } })
    ]);

    return { success: true };
  }

  async getProfile(userId: number): Promise<RequestUser> {
    return this.loadRequestUser(userId);
  }

  private async generateTokens(user: RequestUser): Promise<AuthTokens> {
    const payload = { sub: user.id, email: user.email };
    const accessToken = await this.jwtService.signAsync(payload);
    const refreshToken = await this.issueRefreshToken(user.id);
    return { accessToken, refreshToken };
  }

  private async issueRefreshToken(userId: number): Promise<string> {
    const rawToken = randomBytes(48).toString('hex');
    const hash = await bcrypt.hash(rawToken, 12);
    const expiresAt = new Date(Date.now() + this.refreshTtlSeconds * 1000);
    const record = await this.prisma.userToken.create({
      data: {
        userId,
        token: hash,
        expiresAt
      }
    });
    return `${record.id}.${rawToken}`;
  }

  private async loadRequestUser(userId: number): Promise<RequestUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        roles: {
          include: {
            league: true,
            club: true,
            category: true,
            role: {
              include: {
                permissions: {
                  include: { permission: true }
                }
              }
            }
          }
        }
      }
    });

    if (!user) {
      throw new UnauthorizedException();
    }

    return this.mapToRequestUser(user);
  }

  private mapToRequestUser(user: any): RequestUser {
    const permissions = this.accessControlService.buildGrants(user.roles);
    const roles = user.roles.map((assignment: any) => assignment.role.key);
    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      roles,
      permissions
    };
  }

  private async createEmailVerificationToken(userId: number) {
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60 * 24);
    await this.prisma.emailVerificationToken.create({
      data: {
        userId,
        token,
        expiresAt
      }
    });
    return token;
  }

  private async createPasswordResetToken(userId: number) {
    const token = randomBytes(32).toString('hex');
    const expiresAt = new Date(Date.now() + 1000 * 60 * 60);
    await this.prisma.passwordResetToken.create({
      data: {
        userId,
        token,
        expiresAt
      }
    });
    return token;
  }
}
