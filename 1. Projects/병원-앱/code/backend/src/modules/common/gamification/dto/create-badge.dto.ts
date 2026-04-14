import { IsString, IsObject, MaxLength } from 'class-validator';

export class CreateBadgeDto {
  @IsString()
  @MaxLength(50)
  name: string;

  @IsString()
  @MaxLength(255)
  iconUrl: string;

  @IsString()
  description: string;

  @IsObject()
  condition: Record<string, unknown>;
}
