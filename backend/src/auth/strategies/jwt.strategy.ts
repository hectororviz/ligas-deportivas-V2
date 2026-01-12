import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AccessControlService } from '../../rbac/access-control.service';
import { PrismaService } from '../../prisma/prisma.service';
import { RequestUser } from '../../common/interfaces/request-user.interface';

interface JwtPayload {
  sub: number;
  email: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  private readonly disabledEmails: Set<string>;

  constructor(
    configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly accessControlService: AccessControlService
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('auth.accessSecret')
    });

    const disabled = configService.get<string[]>('auth.disabledEmails') ?? [];
    this.disabledEmails = new Set(disabled.map((email) => email.toLowerCase()));
  }

  async validate(payload: JwtPayload): Promise<RequestUser> {
    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      include: {
        club: {
          select: {
            id: true,
            name: true
          }
        },
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

    if (this.disabledEmails.has(user.email.toLowerCase())) {
      throw new UnauthorizedException();
    }

    const permissions = this.accessControlService.buildGrants(user.roles);
    const roles = user.roles.map((assignment) => assignment.role.key);

    return {
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      language: user.language,
      avatarHash: user.avatarHash,
      avatarUpdatedAt: user.avatarUpdatedAt,
      avatarMime: user.avatarMime,
      roles,
      permissions,
      club: user.club
        ? {
            id: user.club.id,
            name: user.club.name
          }
        : null
    };
  }
}
