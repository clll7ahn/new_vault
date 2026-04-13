import {
  Injectable,
  NotFoundException,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan } from 'typeorm';
import { QueueEntry, QueueStatus } from './entities/queue-entry.entity';
import { CreateQueueDto } from './dto/create-queue.dto';

const AVG_CONSULT_MIN = 10;

@Injectable()
export class QueueService {
  constructor(
    @InjectRepository(QueueEntry)
    private readonly queueRepo: Repository<QueueEntry>,
  ) {}

  async checkIn(dto: CreateQueueDto): Promise<QueueEntry> {
    const today = this.todayStart();
    const tomorrow = this.tomorrowStart();

    const existing = await this.queueRepo.findOne({
      where: {
        patientId: dto.patient_id,
        doctorId: dto.doctor_id,
        status: QueueStatus.WAITING,
      },
    });

    if (existing) {
      throw new ConflictException('이미 대기 중인 항목이 있습니다.');
    }

    const last = await this.queueRepo
      .createQueryBuilder('q')
      .where('q.doctorId = :doctorId', { doctorId: dto.doctor_id })
      .andWhere('q.checkInAt >= :today', { today })
      .andWhere('q.checkInAt < :tomorrow', { tomorrow })
      .orderBy('q.queueNumber', 'DESC')
      .getOne();

    const queueNumber = last ? last.queueNumber + 1 : 1;

    const entry = this.queueRepo.create({
      patientId: dto.patient_id,
      departmentId: dto.department_id,
      doctorId: dto.doctor_id,
      appointmentId: dto.appointment_id ?? null,
      queueNumber,
      status: QueueStatus.WAITING,
      checkInAt: new Date(),
    });

    return this.queueRepo.save(entry);
  }

  async getCurrentQueue(doctorId: string): Promise<QueueEntry[]> {
    const today = this.todayStart();
    const tomorrow = this.tomorrowStart();

    return this.queueRepo
      .createQueryBuilder('q')
      .leftJoinAndSelect('q.patient', 'patient')
      .leftJoinAndSelect('q.department', 'department')
      .where('q.doctorId = :doctorId', { doctorId })
      .andWhere('q.status IN (:...statuses)', {
        statuses: [QueueStatus.WAITING, QueueStatus.IN_PROGRESS],
      })
      .andWhere('q.checkInAt >= :today', { today })
      .andWhere('q.checkInAt < :tomorrow', { tomorrow })
      .orderBy('q.queueNumber', 'ASC')
      .getMany();
  }

  async getMyQueueStatus(patientId: string): Promise<QueueEntry[]> {
    const today = this.todayStart();
    const tomorrow = this.tomorrowStart();

    return this.queueRepo
      .createQueryBuilder('q')
      .leftJoinAndSelect('q.doctor', 'doctor')
      .leftJoinAndSelect('q.department', 'department')
      .where('q.patientId = :patientId', { patientId })
      .andWhere('q.checkInAt >= :today', { today })
      .andWhere('q.checkInAt < :tomorrow', { tomorrow })
      .orderBy('q.checkInAt', 'DESC')
      .getMany();
  }

  async callNext(doctorId: string): Promise<QueueEntry> {
    const today = this.todayStart();
    const tomorrow = this.tomorrowStart();

    const inProgress = await this.queueRepo.findOne({
      where: { doctorId, status: QueueStatus.IN_PROGRESS },
    });

    if (inProgress) {
      throw new ConflictException('진행 중인 환자를 먼저 완료해 주세요.');
    }

    const next = await this.queueRepo
      .createQueryBuilder('q')
      .where('q.doctorId = :doctorId', { doctorId })
      .andWhere('q.status = :status', { status: QueueStatus.WAITING })
      .andWhere('q.checkInAt >= :today', { today })
      .andWhere('q.checkInAt < :tomorrow', { tomorrow })
      .orderBy('q.queueNumber', 'ASC')
      .getOne();

    if (!next) {
      throw new NotFoundException('대기 중인 환자가 없습니다.');
    }

    next.status = QueueStatus.IN_PROGRESS;
    next.calledAt = new Date();
    return this.queueRepo.save(next);
  }

  async completeCurrent(entryId: string): Promise<QueueEntry> {
    const entry = await this.queueRepo.findOne({ where: { id: entryId } });
    if (!entry) throw new NotFoundException('대기열 항목을 찾을 수 없습니다.');
    if (entry.status !== QueueStatus.IN_PROGRESS) {
      throw new BadRequestException('진행 중인 항목만 완료 처리할 수 있습니다.');
    }

    entry.status = QueueStatus.COMPLETED;
    entry.completedAt = new Date();
    return this.queueRepo.save(entry);
  }

  async cancelEntry(entryId: string): Promise<QueueEntry> {
    const entry = await this.queueRepo.findOne({ where: { id: entryId } });
    if (!entry) throw new NotFoundException('대기열 항목을 찾을 수 없습니다.');
    if (
      entry.status === QueueStatus.COMPLETED ||
      entry.status === QueueStatus.CANCELLED
    ) {
      throw new ConflictException('이미 완료되었거나 취소된 항목입니다.');
    }

    entry.status = QueueStatus.CANCELLED;
    return this.queueRepo.save(entry);
  }

  async getEstimatedWait(doctorId: string): Promise<{ estimatedWaitMin: number; waitingCount: number }> {
    const today = this.todayStart();
    const tomorrow = this.tomorrowStart();

    const waitingCount = await this.queueRepo
      .createQueryBuilder('q')
      .where('q.doctorId = :doctorId', { doctorId })
      .andWhere('q.status = :status', { status: QueueStatus.WAITING })
      .andWhere('q.checkInAt >= :today', { today })
      .andWhere('q.checkInAt < :tomorrow', { tomorrow })
      .getCount();

    const estimatedWaitMin = waitingCount * AVG_CONSULT_MIN;
    return { estimatedWaitMin, waitingCount };
  }

  async getTodayStats(doctorId: string): Promise<Record<string, number>> {
    const today = this.todayStart();
    const tomorrow = this.tomorrowStart();

    const rows = await this.queueRepo
      .createQueryBuilder('q')
      .select('q.status', 'status')
      .addSelect('COUNT(*)', 'count')
      .where('q.doctorId = :doctorId', { doctorId })
      .andWhere('q.checkInAt >= :today', { today })
      .andWhere('q.checkInAt < :tomorrow', { tomorrow })
      .groupBy('q.status')
      .getRawMany<{ status: string; count: string }>();

    const stats: Record<string, number> = {
      waiting: 0,
      in_progress: 0,
      completed: 0,
      cancelled: 0,
      no_show: 0,
    };

    for (const row of rows) {
      stats[row.status] = Number(row.count);
    }

    return stats;
  }

  private todayStart(): Date {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    return d;
  }

  private tomorrowStart(): Date {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    d.setDate(d.getDate() + 1);
    return d;
  }
}
