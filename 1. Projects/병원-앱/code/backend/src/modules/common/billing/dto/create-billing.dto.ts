import {
  IsUUID,
  IsNumber,
  IsPositive,
  IsString,
  IsOptional,
  MaxLength,
} from 'class-validator';

export class CreateBillingDto {
  @IsUUID()
  patientId: string;

  @IsOptional()
  @IsUUID()
  appointmentId?: string;

  @IsNumber({ maxDecimalPlaces: 2 })
  @IsPositive()
  amount: number;

  @IsString()
  @MaxLength(500)
  description: string;
}
