import { IsInt, Min } from 'class-validator';

export class UpdateMissionProgressDto {
  @IsInt()
  @Min(0)
  current: number;
}
