import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between, QueryFailedError } from 'typeorm';
import { HealthRecord, HealthRecordType } from './entities/health-record.entity';
import { CreateHealthRecordDto } from './dto/create-health-record.dto';
import { SyncHealthDataDto } from './dto/sync-health-data.dto';

@Injectable()
export class HealthTrackerService {
  constructor(
    @InjectRepository(HealthRecord)
    private readonly healthRecordRepository: Repository<HealthRecord>,
  ) {}

  async addRecord(userId: string, dto: CreateHealthRecordDto): Promise<HealthRecord> {
    const record = this.healthRecordRepository.create({
      userId,
      type: dto.type,
      value: dto.value,
      valueSecondary: dto.valueSecondary ?? null,
      unit: dto.unit,
      source: dto.source,
      recordedAt: new Date(dto.recordedAt),
    });

    try {
      return await this.healthRecordRepository.save(record);
    } catch (err) {
      if (err instanceof QueryFailedError && (err as any).code === '23505') {
        throw new ConflictException('Record already exists for this type and time');
      }
      throw err;
    }
  }

  async syncBulk(
    userId: string,
    dto: SyncHealthDataDto,
  ): Promise<{ inserted: number; skipped: number }> {
    let inserted = 0;
    let skipped = 0;

    for (const item of dto.records) {
      const record = this.healthRecordRepository.create({
        userId,
        type: item.type,
        value: item.value,
        valueSecondary: item.valueSecondary ?? null,
        unit: item.unit,
        source: item.source,
        recordedAt: new Date(item.recordedAt),
      });

      try {
        await this.healthRecordRepository.save(record);
        inserted++;
      } catch (err) {
        if (err instanceof QueryFailedError && (err as any).code === '23505') {
          skipped++;
        } else {
          throw err;
        }
      }
    }

    return { inserted, skipped };
  }

  async getRecords(
    userId: string,
    type?: HealthRecordType,
    from?: string,
    to?: string,
  ): Promise<HealthRecord[]> {
    const where: any = { userId };

    if (type) {
      where.type = type;
    }

    if (from && to) {
      where.recordedAt = Between(new Date(from), new Date(to));
    } else if (from) {
      where.recordedAt = Between(new Date(from), new Date());
    }

    return this.healthRecordRepository.find({
      where,
      order: { recordedAt: 'DESC' },
    });
  }

  async getDailySummary(
    userId: string,
    date: string,
  ): Promise<Record<string, HealthRecord | null>> {
    const start = new Date(date);
    start.setHours(0, 0, 0, 0);
    const end = new Date(date);
    end.setHours(23, 59, 59, 999);

    const records = await this.healthRecordRepository.find({
      where: { userId, recordedAt: Between(start, end) },
      order: { recordedAt: 'DESC' },
    });

    const summary: Record<string, HealthRecord | null> = {};
    for (const type of Object.values(HealthRecordType)) {
      summary[type] = records.find((r) => r.type === type) ?? null;
    }

    return summary;
  }

  async getWeeklySummary(
    userId: string,
  ): Promise<Record<string, { avg: number | null; sum: number | null; count: number }>> {
    const to = new Date();
    const from = new Date();
    from.setDate(from.getDate() - 6);
    from.setHours(0, 0, 0, 0);

    const records = await this.healthRecordRepository.find({
      where: { userId, recordedAt: Between(from, to) },
    });

    const result: Record<
      string,
      { avg: number | null; sum: number | null; count: number }
    > = {};

    for (const type of Object.values(HealthRecordType)) {
      const typeRecords = records.filter((r) => r.type === type);
      if (typeRecords.length === 0) {
        result[type] = { avg: null, sum: null, count: 0 };
        continue;
      }
      const values = typeRecords.map((r) => Number(r.value));
      const sum = values.reduce((a, b) => a + b, 0);
      result[type] = {
        avg: sum / values.length,
        sum,
        count: values.length,
      };
    }

    return result;
  }

  async getHealthSnapshot(userId: string): Promise<{
    period: { from: string; to: string };
    data: Record<string, { latest: HealthRecord | null; avg: number | null }>;
  }> {
    const to = new Date();
    const from = new Date();
    from.setDate(from.getDate() - 6);
    from.setHours(0, 0, 0, 0);

    const records = await this.healthRecordRepository.find({
      where: { userId, recordedAt: Between(from, to) },
      order: { recordedAt: 'DESC' },
    });

    const priorityTypes = [
      HealthRecordType.HEART_RATE,
      HealthRecordType.BLOOD_PRESSURE,
      HealthRecordType.BLOOD_GLUCOSE,
      HealthRecordType.WEIGHT,
      HealthRecordType.STEPS,
      HealthRecordType.SLEEP,
    ];

    const data: Record<string, { latest: HealthRecord | null; avg: number | null }> = {};

    for (const type of priorityTypes) {
      const typeRecords = records.filter((r) => r.type === type);
      const latest = typeRecords[0] ?? null;
      if (typeRecords.length === 0) {
        data[type] = { latest: null, avg: null };
      } else {
        const values = typeRecords.map((r) => Number(r.value));
        const avg = values.reduce((a, b) => a + b, 0) / values.length;
        data[type] = { latest, avg };
      }
    }

    return {
      period: { from: from.toISOString(), to: to.toISOString() },
      data,
    };
  }
}
