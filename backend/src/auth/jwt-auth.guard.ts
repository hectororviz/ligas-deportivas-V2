import { ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  override handleRequest(
    err: any,
    user: any,
    info: any,
    _context: ExecutionContext,
    _status?: any,
  ) {
    if (err) {
      throw err;
    }
    if (!user) {
      if (info instanceof Error) {
        if (info.name === 'TokenExpiredError') {
          throw new UnauthorizedException('Token expirado');
        }
        throw new UnauthorizedException(info.message);
      }
      if (typeof info === 'string') {
        throw new UnauthorizedException(info);
      }
      throw new UnauthorizedException();
    }
    return user;
  }
}
