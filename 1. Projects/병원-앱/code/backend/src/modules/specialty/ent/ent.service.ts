import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { EntSymptomLog, EntSymptomType } from './entities/ent-symptom-log.entity';
import { EntAllergyRecord, AllergySeverity } from './entities/ent-allergy-record.entity';

@Injectable()
export class EntService {
  constructor(
    @InjectRepository(EntSymptomLog)
    private readonly symptomRepo: Repository<EntSymptomLog>,
    @InjectRepository(EntAllergyRecord)
    private readonly allergyRepo: Repository<EntAllergyRecord>,
  ) {}

  async addSymptomLog(patientId: string, dto: {
    symptomType: EntSymptomType;
    severity: number;
    note?: string;
    loggedAt: Date;
  }): Promise<EntSymptomLog> {
    const log = this.symptomRepo.create({
      patientId,
      symptomType: dto.symptomType,
      severity: dto.severity,
      note: dto.note ?? null,
      loggedAt: dto.loggedAt,
    });
    return this.symptomRepo.save(log);
  }

  async getSymptomLogs(patientId: string, symptomType?: EntSymptomType): Promise<EntSymptomLog[]> {
    const where: Record<string, unknown> = { patientId };
    if (symptomType) where.symptomType = symptomType;
    return this.symptomRepo.find({ where, order: { loggedAt: 'DESC' } });
  }

  async getSymptomTrend(patientId: string, symptomType: EntSymptomType): Promise<{
    date: string;
    avgSeverity: number;
    count: number;
  }[]> {
    const logs = await this.symptomRepo.find({
      where: { patientId, symptomType },
      order: { loggedAt: 'ASC' },
    });

    const grouped = logs.reduce<Record<string, { sum: number; count: number }>>((acc, log) => {
      const date = log.loggedAt.toISOString().split('T')[0];
      if (!acc[date]) acc[date] = { sum: 0, count: 0 };
      acc[date].sum += log.severity;
      acc[date].count += 1;
      return acc;
    }, {});

    return Object.entries(grouped).map(([date, { sum, count }]) => ({
      date,
      avgSeverity: Math.round((sum / count) * 10) / 10,
      count,
    }));
  }

  async addAllergyRecord(patientId: string, dto: {
    allergen: string;
    reactionType: string;
    severity: AllergySeverity;
    diagnosedAt: string;
    isActive?: boolean;
  }): Promise<EntAllergyRecord> {
    const record = this.allergyRepo.create({
      patientId,
      allergen: dto.allergen,
      reactionType: dto.reactionType,
      severity: dto.severity,
      diagnosedAt: dto.diagnosedAt,
      isActive: dto.isActive ?? true,
    });
    return this.allergyRepo.save(record);
  }

  async getAllergies(patientId: string, activeOnly = false): Promise<EntAllergyRecord[]> {
    const where: Record<string, unknown> = { patientId };
    if (activeOnly) where.isActive = true;
    return this.allergyRepo.find({ where, order: { diagnosedAt: 'DESC' } });
  }

  getSeasonalAlert(month: number): { season: string; alert: string; allergens: string[] } {
    if (month >= 3 && month <= 5) {
      return {
        season: '봄',
        alert: '봄철 꽃가루 시즌입니다. 외출 시 마스크를 착용하세요.',
        allergens: ['소나무 꽃가루', '자작나무 꽃가루', '오리나무 꽃가루'],
      };
    }
    if (month >= 6 && month <= 8) {
      return {
        season: '여름',
        alert: '여름철 곰팡이 포자와 잔디 꽃가루 주의하세요.',
        allergens: ['잔디 꽃가루', '곰팡이 포자'],
      };
    }
    if (month >= 9 && month <= 11) {
      return {
        season: '가을',
        alert: '가을철 쑥·돼지풀 꽃가루 시즌입니다. 알레르기 증상에 주의하세요.',
        allergens: ['쑥 꽃가루', '돼지풀 꽃가루', '환삼덩굴 꽃가루'],
      };
    }
    return {
      season: '겨울',
      alert: '겨울철 실내 알레르겐(집먼지진드기, 반려동물 비듬)에 주의하세요.',
      allergens: ['집먼지진드기', '반려동물 비듬', '바퀴벌레'],
    };
  }
}
