import { IsUUID, IsOptional } from 'class-validator';

export class CreateQueueDto {
  @IsUUID()
  patient_id: string;

  @IsUUID()
  department_id: string;

  @IsUUID()
  doctor_id: string;

  @IsOptional()
  @IsUUID()
  appointment_id?: string;
}
