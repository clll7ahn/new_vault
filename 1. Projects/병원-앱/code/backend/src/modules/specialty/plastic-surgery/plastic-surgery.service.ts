import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { PsProcedure, PsProcedureStatus } from './entities/ps-procedure.entity';
import { PsPhotoRecord, PsPhotoType } from './entities/ps-photo-record.entity';
import { PsRecoveryLog } from './entities/ps-recovery-log.entity';

@Injectable()
export class PlasticSurgeryService {
  constructor(
    @InjectRepository(PsProcedure)
    private readonly procedureRepo: Repository<PsProcedure>,
    @InjectRepository(PsPhotoRecord)
    private readonly photoRepo: Repository<PsPhotoRecord>,
    @InjectRepository(PsRecoveryLog)
    private readonly recoveryRepo: Repository<PsRecoveryLog>,
  ) {}

  async addProcedure(patientId: string, dto: {
    doctorId: string;
    procedureType: string;
    description: string;
    cost?: number;
    procedureDate: Date;
    recoveryDays?: number;
    status?: PsProcedureStatus;
  }): Promise<PsProcedure> {
    const procedure = this.procedureRepo.create({
      patientId,
      doctorId: dto.doctorId,
      procedureType: dto.procedureType,
      description: dto.description,
      cost: dto.cost ?? null,
      procedureDate: dto.procedureDate,
      recoveryDays: dto.recoveryDays ?? null,
      status: dto.status ?? PsProcedureStatus.PLANNED,
    });
    return this.procedureRepo.save(procedure);
  }

  async getProcedures(patientId: string): Promise<PsProcedure[]> {
    return this.procedureRepo.find({
      where: { patientId },
      order: { procedureDate: 'DESC' },
    });
  }

  async addPhotoRecord(dto: {
    procedureId: string;
    photoType: PsPhotoType;
    imageUrl: string;
    takenAt: Date;
    note?: string;
  }): Promise<PsPhotoRecord> {
    const record = this.photoRepo.create({
      procedureId: dto.procedureId,
      photoType: dto.photoType,
      imageUrl: dto.imageUrl,
      takenAt: dto.takenAt,
      note: dto.note ?? null,
    });
    return this.photoRepo.save(record);
  }

  async getPhotoRecords(procedureId: string): Promise<PsPhotoRecord[]> {
    return this.photoRepo.find({
      where: { procedureId },
      order: { takenAt: 'ASC' },
    });
  }

  async getBeforeAfter(procedureId: string): Promise<{
    before: PsPhotoRecord | null;
    after: PsPhotoRecord | null;
  }> {
    const [before, after] = await Promise.all([
      this.photoRepo.findOne({
        where: { procedureId, photoType: PsPhotoType.BEFORE },
        order: { takenAt: 'ASC' },
      }),
      this.photoRepo.findOne({
        where: { procedureId, photoType: PsPhotoType.AFTER },
        order: { takenAt: 'DESC' },
      }),
    ]);
    return { before: before ?? null, after: after ?? null };
  }

  async addRecoveryLog(dto: {
    procedureId: string;
    dayNumber: number;
    swellingLevel: number;
    painLevel: number;
    note?: string;
    photoUrl?: string;
    loggedAt: Date;
  }): Promise<PsRecoveryLog> {
    const log = this.recoveryRepo.create({
      procedureId: dto.procedureId,
      dayNumber: dto.dayNumber,
      swellingLevel: dto.swellingLevel,
      painLevel: dto.painLevel,
      note: dto.note ?? null,
      photoUrl: dto.photoUrl ?? null,
      loggedAt: dto.loggedAt,
    });
    return this.recoveryRepo.save(log);
  }

  async getRecoveryLogs(procedureId: string): Promise<PsRecoveryLog[]> {
    return this.recoveryRepo.find({
      where: { procedureId },
      order: { dayNumber: 'ASC' },
    });
  }

  async getRecoveryProgress(procedureId: string): Promise<{
    logs: PsRecoveryLog[];
    avgSwelling: number;
    avgPain: number;
    latestDay: number;
  }> {
    const logs = await this.getRecoveryLogs(procedureId);
    if (!logs.length) {
      return { logs, avgSwelling: 0, avgPain: 0, latestDay: 0 };
    }
    const avgSwelling = logs.reduce((s, l) => s + l.swellingLevel, 0) / logs.length;
    const avgPain = logs.reduce((s, l) => s + l.painLevel, 0) / logs.length;
    const latestDay = logs[logs.length - 1].dayNumber;
    return { logs, avgSwelling, avgPain, latestDay };
  }
}
