import { UserRole } from '../entities/user.entity';

export class UserProfileDto {
  id: string;
  email: string;
  name: string;
  role: UserRole;
  phone: string | null;
  isActive: boolean;
  createdAt: Date;
}

export class AuthResponseDto {
  accessToken: string;
  refreshToken: string;
  user: UserProfileDto;
}
