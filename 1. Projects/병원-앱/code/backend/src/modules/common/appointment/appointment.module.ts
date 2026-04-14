import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Appointment } from './entities/appointment.entity';
import { ScheduleSlot } from './entities/schedule-slot.entity';
import { AppointmentReminder } from './entities/appointment-reminder.entity';
import { AppointmentService } from './appointment.service';
import { AppointmentController } from './appointment.controller';
import { NoShowGuardService } from './no-show-guard.service';
import { NotificationModule } from '../notification/notification.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Appointment, ScheduleSlot, AppointmentReminder]),
    NotificationModule,
  ],
  controllers: [AppointmentController],
  providers: [AppointmentService, NoShowGuardService],
  exports: [AppointmentService, NoShowGuardService],
})
export class AppointmentModule {}
