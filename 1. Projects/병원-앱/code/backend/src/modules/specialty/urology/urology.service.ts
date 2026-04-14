import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { UroVoidingLog, VoidType } from './entities/uro-voiding-log.entity';
import { UroPsaRecord } from './entities/uro-psa-record.entity';

@Injectable()
export class UrologyService {
  constructor(
    @InjectRepository(UroVoidingLog)
    private readonly voidingRepo: Repository<UroVoidingLog>,
    @InjectRepository(UroPsaRecord)
    private readonly psaRepo: Repository<UroPsaRecord>,
  ) {}

  async addVoidingLog(patientId: string, dto: {
    voidType: VoidType;
    volumeMl?: number;
    loggedAt: Date;
  }): Promise<UroVoidingLog> {
    const log = this.voidingRepo.create({
      patientId,
      voidType: dto.voidType,
      volumeMl: dto.volumeMl ?? null,
      loggedAt: dto.loggedAt,
    });
    return this.voidingRepo.save(log);
  }

  async getVoidingLogs(patientId: string, voidType?: VoidType): Promise<UroVoidingLog[]> {
    const where: Record<string, unknown> = { patientId };
    if (voidType) where.voidType = voidType;
    return this.voidingRepo.find({ where, order: { loggedAt: 'DESC' } });
  }

  async getVoidingPattern(patientId: string): Promise<{ hour: number; count: number }[]> {
    const logs = await this.voidingRepo.find({ where: { patientId } });

    const hourMap = new Array(24).fill(0) as number[];
    for (const log of logs) {
      const hour = log.loggedAt.getHours();
      hourMap[hour] += 1;
    }

    return hourMap.map((count, hour) => ({ hour, count }));
  }

  async addPSARecord(patientId: string, dto: {
    psaValue: number;
    testedAt: string;
    note?: string;
  }): Promise<UroPsaRecord> {
    const record = this.psaRepo.create({
      patientId,
      psaValue: dto.psaValue,
      testedAt: dto.testedAt,
      note: dto.note ?? null,
    });
    return this.psaRepo.save(record);
  }

  async getPSARecords(patientId: string): Promise<UroPsaRecord[]> {
    return this.psaRepo.find({
      where: { patientId },
      order: { testedAt: 'DESC' },
    });
  }

  async getPSATrend(patientId: string): Promise<{ date: string; psaValue: number }[]> {
    const records = await this.psaRepo.find({
      where: { patientId },
      order: { testedAt: 'ASC' },
    });
    return records.map((r) => ({ date: r.testedAt, psaValue: Number(r.psaValue) }));
  }
}
