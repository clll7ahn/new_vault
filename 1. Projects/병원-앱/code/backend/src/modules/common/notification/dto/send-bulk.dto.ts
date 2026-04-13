import { IsUUID, IsString, MaxLength, IsEnum, IsArray } from 'class-validator';
import { NotificationType } from '../entities/notification.entity';

export class SendBulkDto {
  @IsArray()
  @IsUUID('all', { each: true })
  userIds: string[];

  @IsString()
  @MaxLength(200)
  title: string;

  @IsString()
  body: string;

  @IsEnum(NotificationType)
  type: NotificationType;
}
