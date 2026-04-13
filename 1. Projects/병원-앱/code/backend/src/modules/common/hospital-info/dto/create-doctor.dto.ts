import {
  IsString,
  IsOptional,
  IsBoolean,
  IsInt,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateDoctorDto {
  @IsOptional()
  @IsUUID()
  userId?: string;

  @IsUUID()
  departmentId: string;

  @IsString()
  @MaxLength(100)
  name: string;

  @IsString()
  @MaxLength(50)
  licenseNumber: string;

  @IsString()
  @MaxLength(100)
  specialty: string;

  @IsOptional()
  @IsString()
  bio?: string;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  profileImageUrl?: string;

  @IsOptional()
  @IsBoolean()
  isAvailable?: boolean;

  @IsOptional()
  @IsInt()
  @Min(0)
  displayOrder?: number;
}
