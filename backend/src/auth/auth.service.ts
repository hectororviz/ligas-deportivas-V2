import {
  Injectable,
  UnauthorizedException
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { AccessControlService } from '../rbac/access-control.service';
import * as argon2 from 'argon2';
import { Module, PermissionLevel } from '@prisma/client';
import { LoginDto } from './dto/login.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RequestUser } from '../common/interfaces/request-user.interface';
import { randomBytes } from 'crypto';

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
    private readonly accessControlService: AccessControlService
  ) {
    this.refreshTtlSeconds = configService.get<number>('auth.refreshTtl') ?? 604800;
  }

  async validateUser(username: string, password: string): Promise<RequestUser> {
    const user = await this.prisma.user.findUnique({
      where: { username },
      include: {
        club: {
          select: {
            id: true,
            name: true
          }
        },
        roles: {
          include: {
            role: { select: { key: true } }
          }
        },
        permissions: true
      }
    });

    if (!user) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    if (!(await argon2.verify(user.passwordHash, password))) {
      throw new UnauthorizedException('Credenciales inválidas');
    }

    return this.mapToRequestUser(user);
  }

  async login(user: RequestUser | null, dto: LoginDto): Promise<{ user: RequestUser } & AuthTokens> {
    const validated = user ?? (await this.validateUser(dto.username, dto.password));
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

    const isValid = await argon2.verify(storedToken.token, rawToken);
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

  async getProfile(userId: number): Promise<RequestUser> {
    return this.loadRequestUser(userId);
  }

  private async generateTokens(user: RequestUser): Promise<AuthTokens> {
    const payload = { sub: user.id, username: user.username };
    const accessToken = await this.jwtService.signAsync(payload);
    const refreshToken = await this.issueRefreshToken(user.id);
    return { accessToken, refreshToken };
  }

  private async issueRefreshToken(userId: number): Promise<string> {
    const rawToken = randomBytes(48).toString('hex');
    const hash = await argon2.hash(rawToken, {
      type: argon2.argon2id
    });
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
        club: {
          select: {
            id: true,
            name: true
          }
        },
        roles: {
          include: {
            role: { select: { key: true } }
          }
        },
        permissions: true
      }
    });

    if (!user) {
      throw new UnauthorizedException();
    }

    return this.mapToRequestUser(user);
  }

  private mapToRequestUser(user: {
    id: number;
    username: string;
    firstName: string;
    lastName: string;
    isAdmin: boolean;
    language: string | null;
    avatarHash: string | null;
    avatarUpdatedAt: Date | null;
    avatarMime: string | null;
    club: { id: number; name: string } | null;
    roles: Array<{ role: { key: string } }>;
    permissions: Array<{ module: Module; level: PermissionLevel }>;
  }): RequestUser {
    const permissions = this.accessControlService.buildGrantsFromLevels(
      user.permissions,
      user.club?.id ?? null
    );
    const moduleLevels = this.accessControlService.buildModuleLevels(user.permissions);
    const roles = user.roles.map((assignment) => assignment.role.key);

    return {
      id: user.id,
      username: user.username,
      firstName: user.firstName,
      lastName: user.lastName,
      isAdmin: user.isAdmin,
      language: user.language,
      avatarHash: user.avatarHash,
      avatarUpdatedAt: user.avatarUpdatedAt,
      avatarMime: user.avatarMime,
      roles,
      permissions,
      moduleLevels,
      club: user.club
        ? {
            id: user.club.id,
            name: user.club.name
          }
        : null
    };
  }
}
