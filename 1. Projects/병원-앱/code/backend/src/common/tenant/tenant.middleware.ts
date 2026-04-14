import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

export interface TenantRequest extends Request {
  tenantId?: string;
}

@Injectable()
export class TenantMiddleware implements NestMiddleware {
  use(req: TenantRequest, _res: Response, next: NextFunction): void {
    const headerTenantId = req.headers['x-tenant-id'] as string | undefined;
    if (headerTenantId) {
      req.tenantId = headerTenantId;
      return next();
    }

    const host = req.hostname;
    const parts = host.split('.');
    if (parts.length >= 3) {
      req.tenantId = parts[0];
    }

    next();
  }
}
