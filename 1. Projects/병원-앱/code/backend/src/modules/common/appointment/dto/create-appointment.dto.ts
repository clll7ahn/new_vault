import { IsUUID, IsDateString, IsString, IsOptional, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateAppointmentDto {
  @ApiProperty({ description: '의사 UUID', example: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890' })
  @IsUUID()
  doctor_id: string;

  @ApiProperty({ description: '진료과 UUID', example: 'b2c3d4e5-f6a7-8901-bcde-f12345678901' })
  @IsUUID()
  department_id: string;

  @ApiProperty({ description: '예약 날짜 (ISO 8601)', example: '2026-05-01' })
  @IsDateString()
  appointment_date: string;

  @ApiProperty({ description: '예약 시간 (HH:mm)', example: '09:30' })
  @IsString()
  @Matches(/^\d{2}:\d{2}$/, { message: 'appointment_time must be HH:mm' })
  appointment_time: string;

  @ApiProperty({ description: '주요 증상', example: '두통과 발열', required: false })
  @IsOptional()
  @IsString()
  chief_complaint?: string;
}
