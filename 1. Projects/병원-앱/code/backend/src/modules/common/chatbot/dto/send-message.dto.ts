import { IsString, IsOptional, IsUUID, IsEnum } from 'class-validator';

export class SendMessageDto {
  @IsOptional()
  @IsUUID()
  sessionId?: string;

  @IsString()
  message: string;

  @IsOptional()
  @IsEnum(['faq', 'symptom_check'])
  type?: 'faq' | 'symptom_check';
}
