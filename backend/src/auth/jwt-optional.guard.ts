import { ExecutionContext, Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Request } from 'express';

@Injectable()
export class JwtOptionalAuthGuard extends AuthGuard('jwt') {
  canActivate(context: ExecutionContext) {
    const request = context.switchToHttp().getRequest<Request>();
    const authorization = request.headers?.authorization;

    if (!authorization) {
      return true;
    }

    return super.canActivate(context);
  }

  handleRequest(err: unknown, user: unknown) {
    if (err) {
      throw err;
    }

    return user ?? undefined;
  }
}
