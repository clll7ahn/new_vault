import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FmCheckupResult, RiskLevel } from './entities/fm-checkup-result.entity';
import { FmLifestyleLog, LifestyleType } from './entities/fm-lifestyle-log.entity';

@Injectable()
export class FamilyMedicineService {
  constructor(
    @InjectRepository(FmCheckupResult)
    private readonly checkupRepo: Repository<FmCheckupResult>,
    @InjectRepository(FmLifestyleLog)
    private readonly lifestyleRepo: Repository<FmLifestyleLog>,
  ) {}

  async addCheckupResult(patientId: string, dto: {
    checkupDate: string;
    results: Record<string, unknown>;
    summary: string;
    riskLevel: RiskLevel;
  }): Promise<FmCheckupResult> {
    const result = this.checkupRepo.create({
      patientId,
      checkupDate: dto.checkupDate,
      results: dto.results,
      summary: dto.summary,
      riskLevel: dto.riskLevel,
    });
    return this.checkupRepo.save(result);
  }

  async getCheckupResults(patientId: string): Promise<FmCheckupResult[]> {
    return this.checkupRepo.find({
      where: { patientId },
      order: { checkupDate: 'DESC' },
    });
  }

  async getLatestCheckup(patientId: string): Promise<FmCheckupResult | null> {
    return this.checkupRepo.findOne({
      where: { patientId },
      order: { checkupDate: 'DESC' },
    });
  }

  async addLifestyleLog(patientId: string, dto: {
    type: LifestyleType;
    value: Record<string, unknown>;
    loggedAt: Date;
  }): Promise<FmLifestyleLog> {
    const log = this.lifestyleRepo.create({
      patientId,
      type: dto.type,
      value: dto.value,
      loggedAt: dto.loggedAt,
    });
    return this.lifestyleRepo.save(log);
  }

  async getLifestyleLogs(patientId: string, type?: LifestyleType): Promise<FmLifestyleLog[]> {
    const where: Record<string, unknown> = { patientId };
    if (type) where.type = type;
    return this.lifestyleRepo.find({ where, order: { loggedAt: 'DESC' } });
  }

  async getLifestyleTrend(patientId: string, type: LifestyleType): Promise<{
    date: string;
    value: Record<string, unknown>;
  }[]> {
    const logs = await this.lifestyleRepo.find({
      where: { patientId, type },
      order: { loggedAt: 'ASC' },
    });
    return logs.map((log) => ({
      date: log.loggedAt.toISOString().split('T')[0],
      value: log.value,
    }));
  }

  async getBMIHistory(patientId: string): Promise<{ date: string; bmi: number }[]> {
    const checkups = await this.checkupRepo.find({
      where: { patientId },
      order: { checkupDate: 'ASC' },
    });
    return checkups
      .filter((c) => c.results && typeof (c.results as Record<string, unknown>).bmi === 'number')
      .map((c) => ({
        date: c.checkupDate,
        bmi: (c.results as Record<string, number>).bmi,
      }));
  }
}
