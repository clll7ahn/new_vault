import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import {
  ConflictException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { AppointmentService } from './appointment.service';
import { Appointment, AppointmentStatus } from './entities/appointment.entity';
import { ScheduleSlot } from './entities/schedule-slot.entity';
import { CreateAppointmentDto } from './dto/create-appointment.dto';

describe('AppointmentService', () => {
  let service: AppointmentService;
  let mockAppointmentRepo: any;
  let mockSlotRepo: any;

  const mockAppointment: Appointment = {
    id: 'appt-id-123',
    patientId: 'patient-123',
    doctorId: 'doctor-456',
    departmentId: 'dept-789',
    appointmentDate: '2025-04-20',
    appointmentTime: '10:00:00',
    status: AppointmentStatus.PENDING,
    chiefComplaint: 'Back pain',
    notes: null,
    createdAt: new Date(),
    updatedAt: new Date(),
    patient: null,
    doctor: null,
    department: null,
  };

  const mockScheduleSlot = {
    id: 'slot-1',
    doctorId: 'doctor-456',
    dayOfWeek: 0,
    startTime: '09:00',
    endTime: '17:00',
    slotDurationMin: 30,
    isActive: true,
  };

  beforeEach(async () => {
    mockAppointmentRepo = {
      findOne: jest.fn(),
      find: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    };

    mockSlotRepo = {
      find: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AppointmentService,
        {
          provide: getRepositoryToken(Appointment),
          useValue: mockAppointmentRepo,
        },
        {
          provide: getRepositoryToken(ScheduleSlot),
          useValue: mockSlotRepo,
        },
      ],
    }).compile();

    service = module.get<AppointmentService>(AppointmentService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('createAppointment', () => {
    it('should create appointment successfully with valid data', async () => {
      const patientId = 'patient-123';
      const createDto: CreateAppointmentDto = {
        doctor_id: 'doctor-456',
        department_id: 'dept-789',
        appointment_date: '2025-04-20',
        appointment_time: '10:00:00',
        chief_complaint: 'Headache',
      };

      mockAppointmentRepo.findOne.mockResolvedValue(null);
      mockAppointmentRepo.create.mockReturnValue({
        ...mockAppointment,
        chiefComplaint: createDto.chief_complaint,
      });
      mockAppointmentRepo.save.mockResolvedValue({
        ...mockAppointment,
        chiefComplaint: createDto.chief_complaint,
      });

      const result = await service.createAppointment(patientId, createDto);

      expect(mockAppointmentRepo.findOne).toHaveBeenCalledWith({
        where: {
          doctorId: createDto.doctor_id,
          appointmentDate: createDto.appointment_date,
          appointmentTime: createDto.appointment_time,
        },
      });
      expect(mockAppointmentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          patientId,
          doctorId: createDto.doctor_id,
          departmentId: createDto.department_id,
          appointmentDate: createDto.appointment_date,
          appointmentTime: createDto.appointment_time,
        }),
      );
      expect(result.patientId).toBe(patientId);
      expect(result.status).toBe(AppointmentStatus.PENDING);
    });

    it('should create appointment without chief complaint', async () => {
      const patientId = 'patient-123';
      const createDto: CreateAppointmentDto = {
        doctor_id: 'doctor-456',
        department_id: 'dept-789',
        appointment_date: '2025-04-20',
        appointment_time: '10:00:00',
      };

      mockAppointmentRepo.findOne.mockResolvedValue(null);
      mockAppointmentRepo.create.mockReturnValue({
        ...mockAppointment,
        chiefComplaint: null,
      });
      mockAppointmentRepo.save.mockResolvedValue({
        ...mockAppointment,
        chiefComplaint: null,
      });

      const result = await service.createAppointment(patientId, createDto);

      expect(result.chiefComplaint).toBeNull();
    });

    it('should throw ConflictException when appointment time slot is already booked', async () => {
      const patientId = 'patient-123';
      const createDto: CreateAppointmentDto = {
        doctor_id: 'doctor-456',
        department_id: 'dept-789',
        appointment_date: '2025-04-20',
        appointment_time: '10:00:00',
      };

      const existingAppointment = {
        ...mockAppointment,
        status: AppointmentStatus.CONFIRMED,
      };

      mockAppointmentRepo.findOne.mockResolvedValue(existingAppointment);

      await expect(
        service.createAppointment(patientId, createDto),
      ).rejects.toThrow(ConflictException);
      expect(mockAppointmentRepo.create).not.toHaveBeenCalled();
    });

    it('should allow booking if previous appointment was cancelled', async () => {
      const patientId = 'patient-123';
      const createDto: CreateAppointmentDto = {
        doctor_id: 'doctor-456',
        department_id: 'dept-789',
        appointment_date: '2025-04-20',
        appointment_time: '10:00:00',
      };

      const cancelledAppointment = {
        ...mockAppointment,
        status: AppointmentStatus.CANCELLED,
      };

      mockAppointmentRepo.findOne.mockResolvedValue(cancelledAppointment);
      mockAppointmentRepo.create.mockReturnValue({
        ...mockAppointment,
      });
      mockAppointmentRepo.save.mockResolvedValue({
        ...mockAppointment,
      });

      const result = await service.createAppointment(patientId, createDto);

      expect(mockAppointmentRepo.create).toHaveBeenCalled();
      expect(result.status).toBe(AppointmentStatus.PENDING);
    });
  });

  describe('cancelAppointment', () => {
    it('should cancel own appointment successfully', async () => {
      const appointmentId = 'appt-id-123';
      const userId = 'patient-123';

      mockAppointmentRepo.findOne.mockResolvedValue(mockAppointment);
      mockAppointmentRepo.save.mockResolvedValue({
        ...mockAppointment,
        status: AppointmentStatus.CANCELLED,
      });

      const result = await service.cancelAppointment(appointmentId, userId);

      expect(mockAppointmentRepo.findOne).toHaveBeenCalledWith({
        where: { id: appointmentId },
      });
      expect(mockAppointmentRepo.save).toHaveBeenCalledWith(
        expect.objectContaining({
          status: AppointmentStatus.CANCELLED,
        }),
      );
      expect(result.status).toBe(AppointmentStatus.CANCELLED);
    });

    it('should throw ForbiddenException when trying to cancel others appointment', async () => {
      const appointmentId = 'appt-id-123';
      const differentUserId = 'patient-999';

      mockAppointmentRepo.findOne.mockResolvedValue(mockAppointment);

      await expect(
        service.cancelAppointment(appointmentId, differentUserId),
      ).rejects.toThrow(ForbiddenException);
      expect(mockAppointmentRepo.save).not.toHaveBeenCalled();
    });

    it('should throw NotFoundException when appointment does not exist', async () => {
      const appointmentId = 'nonexistent-id';
      const userId = 'patient-123';

      mockAppointmentRepo.findOne.mockResolvedValue(null);

      await expect(
        service.cancelAppointment(appointmentId, userId),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw ConflictException when appointment is already cancelled', async () => {
      const appointmentId = 'appt-id-123';
      const userId = 'patient-123';

      const cancelledAppointment = {
        ...mockAppointment,
        status: AppointmentStatus.CANCELLED,
      };

      mockAppointmentRepo.findOne.mockResolvedValue(cancelledAppointment);

      await expect(
        service.cancelAppointment(appointmentId, userId),
      ).rejects.toThrow(ConflictException);
      expect(mockAppointmentRepo.save).not.toHaveBeenCalled();
    });

    it('should successfully cancel appointment with PENDING status', async () => {
      const appointmentId = 'appt-id-123';
      const userId = 'patient-123';

      const pendingAppointment = {
        ...mockAppointment,
        status: AppointmentStatus.PENDING,
      };

      mockAppointmentRepo.findOne.mockResolvedValue(pendingAppointment);
      mockAppointmentRepo.save.mockResolvedValue({
        ...pendingAppointment,
        status: AppointmentStatus.CANCELLED,
      });

      const result = await service.cancelAppointment(appointmentId, userId);

      expect(result.status).toBe(AppointmentStatus.CANCELLED);
    });
  });

  describe('getAvailableSlots', () => {
    it('should return available time slots excluding booked appointments', async () => {
      const doctorId = 'doctor-456';
      const date = '2025-04-20'; // Sunday = 0
      const dateObj = new Date(date);
      const dayOfWeek = dateObj.getDay();

      mockSlotRepo.find.mockResolvedValue([mockScheduleSlot]);
      mockAppointmentRepo.find.mockResolvedValue([
        {
          ...mockAppointment,
          appointmentTime: '10:00:00',
          status: AppointmentStatus.CONFIRMED,
        },
        {
          ...mockAppointment,
          id: 'appt-2',
          appointmentTime: '10:30:00',
          status: AppointmentStatus.CONFIRMED,
        },
      ]);

      const result = await service.getAvailableSlots(doctorId, date);

      expect(mockSlotRepo.find).toHaveBeenCalledWith({
        where: { doctorId, dayOfWeek, isActive: true },
      });
      expect(mockAppointmentRepo.find).toHaveBeenCalledWith({
        where: { doctorId, appointmentDate: date },
        select: ['appointmentTime', 'status'],
      });
      expect(result).toBeInstanceOf(Array);
      expect(result).not.toContain('10:00');
      expect(result).not.toContain('10:30');
    });

    it('should return all slots when no appointments are booked', async () => {
      const doctorId = 'doctor-456';
      const date = '2025-04-20';

      mockSlotRepo.find.mockResolvedValue([mockScheduleSlot]);
      mockAppointmentRepo.find.mockResolvedValue([]);

      const result = await service.getAvailableSlots(doctorId, date);

      expect(result).toBeInstanceOf(Array);
      expect(result.length).toBeGreaterThan(0);
    });

    it('should return empty array when no schedule slots exist', async () => {
      const doctorId = 'doctor-456';
      const date = '2025-04-20';

      mockSlotRepo.find.mockResolvedValue([]);

      const result = await service.getAvailableSlots(doctorId, date);

      expect(result).toEqual([]);
    });

    it('should exclude cancelled appointments from booked slots', async () => {
      const doctorId = 'doctor-456';
      const date = '2025-04-20';

      mockSlotRepo.find.mockResolvedValue([mockScheduleSlot]);
      mockAppointmentRepo.find.mockResolvedValue([
        {
          ...mockAppointment,
          appointmentTime: '10:00:00',
          status: AppointmentStatus.CANCELLED,
        },
        {
          ...mockAppointment,
          id: 'appt-2',
          appointmentTime: '10:30:00',
          status: AppointmentStatus.CONFIRMED,
        },
      ]);

      const result = await service.getAvailableSlots(doctorId, date);

      expect(result).toContain('10:00');
      expect(result).not.toContain('10:30');
    });

    it('should generate correct time slots based on duration', async () => {
      const doctorId = 'doctor-456';
      const date = '2025-04-20';
      const slotWithShortDuration = {
        ...mockScheduleSlot,
        startTime: '09:00',
        endTime: '10:00',
        slotDurationMin: 15,
      };

      mockSlotRepo.find.mockResolvedValue([slotWithShortDuration]);
      mockAppointmentRepo.find.mockResolvedValue([]);

      const result = await service.getAvailableSlots(doctorId, date);

      expect(result.length).toBe(4);
      expect(result[0]).toBe('09:00');
      expect(result[1]).toBe('09:15');
      expect(result[2]).toBe('09:30');
      expect(result[3]).toBe('09:45');
    });
  });
});
