import { IsEnum } from 'class-validator';
import { QueueStatus } from '../entities/queue-entry.entity';

export class UpdateQueueStatusDto {
  @IsEnum(QueueStatus)
  status: QueueStatus;
}
