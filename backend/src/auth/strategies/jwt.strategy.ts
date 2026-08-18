import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { AccessControlService } from '../../rbac/access-control.service';
import { PrismaService } from '../../prisma/prisma.service';
import { RequestUser } from '../../common/interfaces/request-user.interface';

interface JwtPayload {
  sub: number;
  username: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
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
            role: { select: { key: true } }
          }
        },
        permissions: true
      }
    });

    if (!user) {
      throw new UnauthorizedException();
    }

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
