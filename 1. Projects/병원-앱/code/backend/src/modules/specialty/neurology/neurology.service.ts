import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  NeuroHeadacheLog,
  HeadacheType,
  HeadacheLocation,
} from './entities/neuro-headache-log.entity';
import { NeuroCognitiveTest } from './entities/neuro-cognitive-test.entity';

@Injectable()
export class NeurologyService {
  constructor(
    @InjectRepository(NeuroHeadacheLog)
    private readonly headacheRepo: Repository<NeuroHeadacheLog>,
    @InjectRepository(NeuroCognitiveTest)
    private readonly cognitiveRepo: Repository<NeuroCognitiveTest>,
  ) {}

  async addHeadacheLog(patientId: string, dto: {
    headacheType: HeadacheType;
    intensity: number;
    durationHours: number;
    triggers?: string[];
    location: HeadacheLocation;
    loggedAt: Date;
  }): Promise<NeuroHeadacheLog> {
    const log = this.headacheRepo.create({
      patientId,
      headacheType: dto.headacheType,
      intensity: dto.intensity,
      durationHours: dto.durationHours,
      triggers: dto.triggers ?? null,
      location: dto.location,
      loggedAt: dto.loggedAt,
    });
    return this.headacheRepo.save(log);
  }

  async getHeadacheLogs(patientId: string, headacheType?: HeadacheType): Promise<NeuroHeadacheLog[]> {
    const where: Record<string, unknown> = { patientId };
    if (headacheType) where.headacheType = headacheType;
    return this.headacheRepo.find({ where, order: { loggedAt: 'DESC' } });
  }

  async getHeadacheTrend(patientId: string): Promise<{
    date: string;
    count: number;
    avgIntensity: number;
    avgDurationHours: number;
  }[]> {
    const logs = await this.headacheRepo.find({
      where: { patientId },
      order: { loggedAt: 'ASC' },
    });

    const grouped = logs.reduce<Record<string, { intensitySum: number; durationSum: number; count: number }>>(
      (acc, log) => {
        const date = log.loggedAt.toISOString().split('T')[0];
        if (!acc[date]) acc[date] = { intensitySum: 0, durationSum: 0, count: 0 };
        acc[date].intensitySum += log.intensity;
        acc[date].durationSum += Number(log.durationHours);
        acc[date].count += 1;
        return acc;
      },
      {},
    );

    return Object.entries(grouped).map(([date, { intensitySum, durationSum, count }]) => ({
      date,
      count,
      avgIntensity: Math.round((intensitySum / count) * 10) / 10,
      avgDurationHours: Math.round((durationSum / count) * 10) / 10,
    }));
  }

  async getHeadacheTriggerStats(patientId: string): Promise<{ trigger: string; count: number }[]> {
    const logs = await this.headacheRepo.find({ where: { patientId } });

    const triggerMap: Record<string, number> = {};
    for (const log of logs) {
      if (!log.triggers) continue;
      for (const trigger of log.triggers) {
        triggerMap[trigger] = (triggerMap[trigger] ?? 0) + 1;
      }
    }

    return Object.entries(triggerMap)
      .map(([trigger, count]) => ({ trigger, count }))
      .sort((a, b) => b.count - a.count);
  }

  async addCognitiveTest(patientId: string, dto: {
    testType: string;
    score: number;
    maxScore: number;
    testedAt: string;
    note?: string;
  }): Promise<NeuroCognitiveTest> {
    const test = this.cognitiveRepo.create({
      patientId,
      testType: dto.testType,
      score: dto.score,
      maxScore: dto.maxScore,
      testedAt: dto.testedAt,
      note: dto.note ?? null,
    });
    return this.cognitiveRepo.save(test);
  }

  async getCognitiveTests(patientId: string, testType?: string): Promise<NeuroCognitiveTest[]> {
    const where: Record<string, unknown> = { patientId };
    if (testType) where.testType = testType;
    return this.cognitiveRepo.find({ where, order: { testedAt: 'DESC' } });
  }

  async getCognitiveProgress(patientId: string, testType: string): Promise<{
    date: string;
    score: number;
    maxScore: number;
    percentage: number;
  }[]> {
    const tests = await this.cognitiveRepo.find({
      where: { patientId, testType },
      order: { testedAt: 'ASC' },
    });
    return tests.map((t) => ({
      date: t.testedAt,
      score: t.score,
      maxScore: t.maxScore,
      percentage: Math.round((t.score / t.maxScore) * 1000) / 10,
    }));
  }
}
