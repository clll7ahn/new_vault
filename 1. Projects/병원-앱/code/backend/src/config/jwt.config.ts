import { registerAs } from '@nestjs/config';
import { JwtModuleOptions } from '@nestjs/jwt';

export default registerAs(
  'jwt',
  (): JwtModuleOptions => ({
    secret: process.env.JWT_SECRET ?? 'fallback-secret-change-in-production',
    signOptions: {
      expiresIn: process.env.JWT_EXPIRATION ?? '15m',
    },
  }),
);
