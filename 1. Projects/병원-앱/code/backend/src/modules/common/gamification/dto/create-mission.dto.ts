import {
  IsString,
  IsEnum,
  IsInt,
  IsOptional,
  IsUUID,
  IsBoolean,
  MaxLength,
  Min,
  ValidateNested,
  IsIn,
  IsNumber,
} from 'class-validator';
import { Type } from 'class-transformer';
import { MissionType } from '../entities/mission.entity';

class MissionConditionDto {
  @IsIn(['steps', 'medication', 'checkin', 'quiz'])
  type: 'steps' | 'medication' | 'checkin' | 'quiz';

  @IsNumber()
  @Min(1)
  target: number;
}

export class CreateMissionDto {
  @IsString()
  @MaxLength(100)
  title: string;

  @IsString()
  description: string;

  @IsEnum(MissionType)
  type: MissionType;

  @ValidateNested()
  @Type(() => MissionConditionDto)
  condition: MissionConditionDto;

  @IsInt()
  @Min(1)
  points: number;

  @IsOptional()
  @IsUUID()
  badgeId?: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}
