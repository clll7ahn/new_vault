import { IsUUID, IsDateString, IsString, IsOptional, Matches } from 'class-validator';

export class CreateAppointmentDto {
  @IsUUID()
  doctor_id: string;

  @IsUUID()
  department_id: string;

  @IsDateString()
  appointment_date: string;

  @IsString()
  @Matches(/^\d{2}:\d{2}$/, { message: 'appointment_time must be HH:mm' })
  appointment_time: string;

  @IsOptional()
  @IsString()
  chief_complaint?: string;
}
