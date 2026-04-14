import { IsInt, IsString, IsOptional, MaxLength, Min } from 'class-validator';

export class SpendPointsDto {
  @IsInt()
  @Min(1)
  amount: number;

  @IsString()
  @MaxLength(200)
  @IsOptional()
  description?: string;
}
