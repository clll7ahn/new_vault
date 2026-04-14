import { Type } from 'class-transformer';
import { IsArray, ValidateNested, ArrayMinSize } from 'class-validator';
import { CreateHealthRecordDto } from './create-health-record.dto';

export class SyncHealthDataDto {
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => CreateHealthRecordDto)
  records: CreateHealthRecordDto[];
}
