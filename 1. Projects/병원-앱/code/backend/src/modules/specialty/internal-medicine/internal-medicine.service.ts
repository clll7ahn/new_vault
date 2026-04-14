import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, FindOptionsWhere } from 'typeorm';
import { ImVitals, VitalType } from './entities/im-vitals.entity';
import { ImMedication } from './entities/im-medication.entity';
import { ImMedLog, MedLogStatus } from './entities/im-med-log.entity';

@Injectable()
export class InternalMedicineService {
  constructor(
    @InjectRepository(ImVitals)
    private readonly vitalsRepo: Repository<ImVitals>,
    @InjectRepository(ImMedication)
    private readonly medicationRepo: Repository<ImMedication>,
    @InjectRepository(ImMedLog)
    private readonly medLogRepo: Repository<ImMedLog>,
  ) {}

  async addVitals(patientId: string, dto: {
    type: VitalType;
    value1: number;
    value2?: number;
    measuredAt: Date;
    note?: string;
  }): Promise<ImVitals> {
    const vitals = this.vitalsRepo.create({
      patientId,
      type: dto.type,
      value1: dto.value1,
      value2: dto.value2 ?? null,
      measuredAt: dto.measuredAt,
      note: dto.note ?? null,
    });
    return this.vitalsRepo.save(vitals);
  }

  async getVitals(
    patientId: string,
    type?: VitalType,
    from?: string,
    to?: string,
  ): Promise<ImVitals[]> {
    const where: FindOptionsWhere<ImVitals> = { patientId };
    if (type) where.type = type;
    if (from && to) {
      where.measuredAt = Between(new Date(from), new Date(to));
    }
    return this.vitalsRepo.find({
      where,
      order: { measuredAt: 'DESC' },
    });
  }

  async getVitalsTrend(
    patientId: string,
    type: VitalType,
  ): Promise<{ measuredAt: Date; value1: number; value2: number | null }[]> {
    const records = await this.vitalsRepo.find({
      where: { patientId, type },
      order: { measuredAt: 'ASC' },
      select: ['measuredAt', 'value1', 'value2'],
    });
    return records.map((r) => ({
      measuredAt: r.measuredAt,
      value1: Number(r.value1),
      value2: r.value2 !== null ? Number(r.value2) : null,
    }));
  }

  async addMedication(patientId: string, dto: {
    name: string;
    dosage: string;
    frequency: string;
    startDate: string;
    endDate?: string;
  }): Promise<ImMedication> {
    const med = this.medicationRepo.create({
      patientId,
      name: dto.name,
      dosage: dto.dosage,
      frequency: dto.frequency,
      startDate: dto.startDate,
      endDate: dto.endDate ?? null,
    });
    return this.medicationRepo.save(med);
  }

  async getActiveMedications(patientId: string): Promise<ImMedication[]> {
    return this.medicationRepo.find({
      where: { patientId, isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  async logMedication(medicationId: string, status: MedLogStatus): Promise<ImMedLog> {
    const med = await this.medicationRepo.findOne({ where: { id: medicationId } });
    if (!med) throw new NotFoundException('처방을 찾을 수 없습니다.');

    const log = this.medLogRepo.create({
      medicationId,
      status,
      takenAt: new Date(),
    });
    return this.medLogRepo.save(log);
  }

  async getMedLogs(patientId: string, from: string, to: string): Promise<ImMedLog[]> {
    return this.medLogRepo
      .createQueryBuilder('log')
      .innerJoin('log.medication', 'med', 'med.patient_id = :patientId', { patientId })
      .where('log.taken_at BETWEEN :from AND :to', { from: new Date(from), to: new Date(to) })
      .orderBy('log.taken_at', 'DESC')
      .getMany();
  }

  async getMedAdherence(patientId: string): Promise<{ adherenceRate: number; taken: number; total: number }> {
    const logs = await this.medLogRepo
      .createQueryBuilder('log')
      .innerJoin('log.medication', 'med', 'med.patient_id = :patientId', { patientId })
      .getMany();

    const total = logs.length;
    const taken = logs.filter((l) => l.status === MedLogStatus.TAKEN).length;
    const adherenceRate = total === 0 ? 0 : Math.round((taken / total) * 100);

    return { adherenceRate, taken, total };
  }
}
