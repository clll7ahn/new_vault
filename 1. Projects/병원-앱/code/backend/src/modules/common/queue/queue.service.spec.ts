import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import {
  ConflictException,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { QueueService } from './queue.service';
import { QueueEntry, QueueStatus } from './entities/queue-entry.entity';
import { CreateQueueDto } from './dto/create-queue.dto';

describe('QueueService', () => {
  let service: QueueService;
  let mockQueueRepo: any;

  const mockQueueEntry: QueueEntry = {
    id: 'queue-id-123',
    patientId: 'patient-123',
    doctorId: 'doctor-456',
    departmentId: 'dept-789',
    appointmentId: null,
    queueNumber: 1,
    status: QueueStatus.WAITING,
    checkInAt: new Date(),
    calledAt: null,
    completedAt: null,
    estimatedWaitMin: null,
    patient: null,
    department: null,
    doctor: null,
  };

  beforeEach(async () => {
    mockQueueRepo = {
      findOne: jest.fn(),
      save: jest.fn(),
      create: jest.fn(),
      createQueryBuilder: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        QueueService,
        {
          provide: getRepositoryToken(QueueEntry),
          useValue: mockQueueRepo,
        },
      ],
    }).compile();

    service = module.get<QueueService>(QueueService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('checkIn', () => {
    it('should successfully check in patient and auto-assign queue number', async () => {
      const createDto: CreateQueueDto = {
        patient_id: 'patient-123',
        doctor_id: 'doctor-456',
        department_id: 'dept-789',
      };

      mockQueueRepo.findOne.mockResolvedValue(null);

      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue(null),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      mockQueueRepo.create.mockReturnValue({
        ...mockQueueEntry,
        queueNumber: 1,
      });
      mockQueueRepo.save.mockResolvedValue({
        ...mockQueueEntry,
        queueNumber: 1,
      });

      const result = await service.checkIn(createDto);

      expect(mockQueueRepo.findOne).toHaveBeenCalledWith({
        where: {
          patientId: createDto.patient_id,
          doctorId: createDto.doctor_id,
          status: QueueStatus.WAITING,
        },
      });
      expect(result.queueNumber).toBe(1);
      expect(result.status).toBe(QueueStatus.WAITING);
      expect(mockQueueRepo.save).toHaveBeenCalled();
    });

    it('should auto-increment queue number based on last entry', async () => {
      const createDto: CreateQueueDto = {
        patient_id: 'patient-200',
        doctor_id: 'doctor-456',
        department_id: 'dept-789',
      };

      mockQueueRepo.findOne.mockResolvedValue(null);

      const previousEntry = { ...mockQueueEntry, queueNumber: 5 };
      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue(previousEntry),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      mockQueueRepo.create.mockReturnValue({
        ...mockQueueEntry,
        patientId: createDto.patient_id,
        queueNumber: 6,
      });
      mockQueueRepo.save.mockResolvedValue({
        ...mockQueueEntry,
        patientId: createDto.patient_id,
        queueNumber: 6,
      });

      const result = await service.checkIn(createDto);

      expect(result.queueNumber).toBe(6);
    });

    it('should throw ConflictException when patient already waiting', async () => {
      const createDto: CreateQueueDto = {
        patient_id: 'patient-123',
        doctor_id: 'doctor-456',
        department_id: 'dept-789',
      };

      mockQueueRepo.findOne.mockResolvedValue({
        ...mockQueueEntry,
        status: QueueStatus.WAITING,
      });

      await expect(service.checkIn(createDto)).rejects.toThrow(
        ConflictException,
      );
      expect(mockQueueRepo.create).not.toHaveBeenCalled();
    });

    it('should include appointmentId if provided', async () => {
      const createDto: CreateQueueDto = {
        patient_id: 'patient-123',
        doctor_id: 'doctor-456',
        department_id: 'dept-789',
        appointment_id: 'appt-789',
      };

      mockQueueRepo.findOne.mockResolvedValue(null);

      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue(null),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      mockQueueRepo.create.mockReturnValue({
        ...mockQueueEntry,
        appointmentId: createDto.appointment_id,
      });
      mockQueueRepo.save.mockResolvedValue({
        ...mockQueueEntry,
        appointmentId: createDto.appointment_id,
      });

      const result = await service.checkIn(createDto);

      expect(mockQueueRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          appointmentId: createDto.appointment_id,
        }),
      );
      expect(result.appointmentId).toBe(createDto.appointment_id);
    });
  });

  describe('callNext', () => {
    it('should successfully call next waiting patient', async () => {
      const doctorId = 'doctor-456';
      const nextPatient = {
        ...mockQueueEntry,
        status: QueueStatus.WAITING,
        queueNumber: 1,
      };

      mockQueueRepo.findOne.mockResolvedValue(null);

      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue(nextPatient),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      mockQueueRepo.save.mockResolvedValue({
        ...nextPatient,
        status: QueueStatus.IN_PROGRESS,
        calledAt: new Date(),
      });

      const result = await service.callNext(doctorId);

      expect(result.status).toBe(QueueStatus.IN_PROGRESS);
      expect(result.calledAt).toBeDefined();
    });

    it('should throw ConflictException when patient already in progress', async () => {
      const doctorId = 'doctor-456';

      mockQueueRepo.findOne.mockResolvedValue({
        ...mockQueueEntry,
        status: QueueStatus.IN_PROGRESS,
      });

      await expect(service.callNext(doctorId)).rejects.toThrow(
        ConflictException,
      );
      expect(mockQueueRepo.save).not.toHaveBeenCalled();
    });

    it('should throw NotFoundException when no waiting patients', async () => {
      const doctorId = 'doctor-456';

      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getOne: jest.fn(),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      mockQueueRepo.findOne.mockResolvedValue(null);
      mockQueryBuilder.getOne.mockResolvedValueOnce(null);
      mockQueryBuilder.getOne.mockResolvedValueOnce(null);

      await expect(service.callNext(doctorId)).rejects.toThrow(
        NotFoundException,
      );
      expect(mockQueueRepo.save).not.toHaveBeenCalled();
    });

    it('should call earliest queue entry when multiple waiting', async () => {
      const doctorId = 'doctor-456';
      const earliestPatient = {
        ...mockQueueEntry,
        queueNumber: 1,
        status: QueueStatus.WAITING,
      };

      mockQueueRepo.findOne.mockResolvedValue(null);

      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getOne: jest.fn().mockResolvedValue(earliestPatient),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      mockQueueRepo.save.mockResolvedValue({
        ...earliestPatient,
        status: QueueStatus.IN_PROGRESS,
        calledAt: new Date(),
      });

      const result = await service.callNext(doctorId);

      expect(result.queueNumber).toBe(1);
      expect(result.status).toBe(QueueStatus.IN_PROGRESS);
    });
  });

  describe('getEstimatedWait', () => {
    it('should return correct estimated wait time', async () => {
      const doctorId = 'doctor-456';
      const waitingCount = 3;
      const expectedWait = waitingCount * 10;

      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getCount: jest.fn().mockResolvedValue(waitingCount),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      const result = await service.getEstimatedWait(doctorId);

      expect(result.waitingCount).toBe(waitingCount);
      expect(result.estimatedWaitMin).toBe(expectedWait);
    });

    it('should return zero minutes when no one waiting', async () => {
      const doctorId = 'doctor-456';

      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getCount: jest.fn().mockResolvedValue(0),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      const result = await service.getEstimatedWait(doctorId);

      expect(result.waitingCount).toBe(0);
      expect(result.estimatedWaitMin).toBe(0);
    });

    it('should calculate 10 minutes per waiting patient', async () => {
      const doctorId = 'doctor-456';
      const waitingCount = 5;

      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getCount: jest.fn().mockResolvedValue(waitingCount),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      const result = await service.getEstimatedWait(doctorId);

      expect(result.estimatedWaitMin).toBe(50);
    });

    it('should exclude cancelled and completed entries from wait calculation', async () => {
      const doctorId = 'doctor-456';

      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getCount: jest.fn().mockResolvedValue(2),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      const result = await service.getEstimatedWait(doctorId);

      expect(mockQueryBuilder.andWhere).toHaveBeenCalledWith(
        expect.stringContaining('status'),
        expect.objectContaining({ status: QueueStatus.WAITING }),
      );
      expect(result.estimatedWaitMin).toBe(20);
    });

    it('should only count same day waiting entries', async () => {
      const doctorId = 'doctor-456';

      const mockQueryBuilder = {
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getCount: jest.fn().mockResolvedValue(1),
      };
      mockQueueRepo.createQueryBuilder.mockReturnValue(mockQueryBuilder);

      const result = await service.getEstimatedWait(doctorId);

      expect(mockQueryBuilder.where).toHaveBeenCalled();
      expect(result.waitingCount).toBe(1);
    });
  });
});
