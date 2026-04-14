import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsDateString,
  MaxLength,
} from 'class-validator';
import { HealthRecordType, HealthRecordSource } from '../entities/health-record.entity';

export class CreateHealthRecordDto {
  @IsEnum(HealthRecordType)
  type: HealthRecordType;

  @IsNumber()
  value: number;

  @IsOptional()
  @IsNumber()
  valueSecondary?: number;

  @IsString()
  @MaxLength(20)
  unit: string;

  @IsEnum(HealthRecordSource)
  source: HealthRecordSource;

  @IsDateString()
  recordedAt: string;
}
