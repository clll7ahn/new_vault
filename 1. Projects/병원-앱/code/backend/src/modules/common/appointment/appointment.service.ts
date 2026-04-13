import {
  Injectable,
  NotFoundException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Appointment, AppointmentStatus } from './entities/appointment.entity';
import { ScheduleSlot } from './entities/schedule-slot.entity';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { UpdateStatusDto } from './dto/update-status.dto';

@Injectable()
export class AppointmentService {
  constructor(
    @InjectRepository(Appointment)
    private readonly appointmentRepo: Repository<Appointment>,
    @InjectRepository(ScheduleSlot)
    private readonly slotRepo: Repository<ScheduleSlot>,
  ) {}

  async getAvailableSlots(doctorId: string, date: string): Promise<string[]> {
    const dateObj = new Date(date);
    const dayOfWeek = dateObj.getDay();

    const slots = await this.slotRepo.find({
      where: { doctorId, dayOfWeek, isActive: true },
    });

    if (slots.length === 0) return [];

    const booked = await this.appointmentRepo.find({
      where: {
        doctorId,
        appointmentDate: date,
      },
      select: ['appointmentTime', 'status'],
    });

    const bookedTimes = new Set(
      booked
        .filter((a) => a.status !== AppointmentStatus.CANCELLED)
        .map((a) => a.appointmentTime.slice(0, 5)),
    );

    const available: string[] = [];

    for (const slot of slots) {
      const [startH, startM] = slot.startTime.split(':').map(Number);
      const [endH, endM] = slot.endTime.split(':').map(Number);
      const startTotal = startH * 60 + startM;
      const endTotal = endH * 60 + endM;

      for (let t = startTotal; t + slot.slotDurationMin <= endTotal; t += slot.slotDurationMin) {
        const hh = String(Math.floor(t / 60)).padStart(2, '0');
        const mm = String(t % 60).padStart(2, '0');
        const timeStr = `${hh}:${mm}`;
        if (!bookedTimes.has(timeStr)) {
          available.push(timeStr);
        }
      }
    }

    return available;
  }

  async createAppointment(patientId: string, dto: CreateAppointmentDto): Promise<Appointment> {
    const conflict = await this.appointmentRepo.findOne({
      where: {
        doctorId: dto.doctor_id,
        appointmentDate: dto.appointment_date,
        appointmentTime: dto.appointment_time,
      },
    });

    if (conflict && conflict.status !== AppointmentStatus.CANCELLED) {
      throw new ConflictException('해당 시간에 이미 예약이 존재합니다.');
    }

    const appointment = this.appointmentRepo.create({
      patientId,
      doctorId: dto.doctor_id,
      departmentId: dto.department_id,
      appointmentDate: dto.appointment_date,
      appointmentTime: dto.appointment_time,
      chiefComplaint: dto.chief_complaint ?? null,
    });

    return this.appointmentRepo.save(appointment);
  }

  async getMyAppointments(userId: string, role: string): Promise<Appointment[]> {
    const where = role === 'doctor' ? { doctorId: userId } : { patientId: userId };
    return this.appointmentRepo.find({
      where,
      relations: ['patient', 'doctor', 'department'],
      order: { appointmentDate: 'DESC', appointmentTime: 'DESC' },
    });
  }

  async getAppointment(id: string): Promise<Appointment> {
    const appointment = await this.appointmentRepo.findOne({
      where: { id },
      relations: ['patient', 'doctor', 'department'],
    });
    if (!appointment) throw new NotFoundException('예약을 찾을 수 없습니다.');
    return appointment;
  }

  async cancelAppointment(id: string, userId: string): Promise<Appointment> {
    const appointment = await this.appointmentRepo.findOne({ where: { id } });
    if (!appointment) throw new NotFoundException('예약을 찾을 수 없습니다.');
    if (appointment.patientId !== userId) throw new ForbiddenException('본인 예약만 취소할 수 있습니다.');
    if (appointment.status === AppointmentStatus.CANCELLED) {
      throw new ConflictException('이미 취소된 예약입니다.');
    }

    appointment.status = AppointmentStatus.CANCELLED;
    return this.appointmentRepo.save(appointment);
  }

  async updateStatus(id: string, dto: UpdateStatusDto): Promise<Appointment> {
    const appointment = await this.appointmentRepo.findOne({ where: { id } });
    if (!appointment) throw new NotFoundException('예약을 찾을 수 없습니다.');

    appointment.status = dto.status;
    return this.appointmentRepo.save(appointment);
  }
}
