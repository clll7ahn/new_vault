import {
  IsUUID,
  IsString,
  MaxLength,
  IsEnum,
  IsOptional,
  IsObject,
} from 'class-validator';
import { NotificationType } from '../entities/notification.entity';

export class CreateNotificationDto {
  @IsUUID()
  userId: string;

  @IsString()
  @MaxLength(200)
  title: string;

  @IsString()
  body: string;

  @IsEnum(NotificationType)
  type: NotificationType;

  @IsOptional()
  @IsObject()
  data?: Record<string, unknown>;
}
