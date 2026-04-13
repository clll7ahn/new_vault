import {
  IsString,
  IsOptional,
  IsNumber,
  IsObject,
  MaxLength,
} from 'class-validator';

export class CreateHospitalDto {
  @IsString()
  @MaxLength(255)
  name: string;

  @IsString()
  @MaxLength(500)
  address: string;

  @IsString()
  @MaxLength(20)
  phone: string;

  @IsString()
  @MaxLength(50)
  registrationNumber: string;

  @IsOptional()
  @IsObject()
  operatingHours?: Record<string, { open: string; close: string }>;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  logoUrl?: string;

  @IsOptional()
  @IsNumber()
  latitude?: number;

  @IsOptional()
  @IsNumber()
  longitude?: number;

  @IsOptional()
  @IsString()
  termsOfService?: string;

  @IsOptional()
  @IsString()
  privacyPolicy?: string;
}
