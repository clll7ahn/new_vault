import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { ObPregnancy, PregnancyStatus } from './entities/ob-pregnancy.entity';
import { ObCheckup } from './entities/ob-checkup.entity';
import { ObFetalMovement } from './entities/ob-fetal-movement.entity';
import { ObMaternalLog, EdemaLevel } from './entities/ob-maternal-log.entity';

const CHECKUP_SCHEDULE: Record<number, string[]> = {
  8: ['초기 혈액검사', '초음파'],
  12: ['NT 초음파', '기형아 1차 검사'],
  16: ['기형아 2차 검사'],
  20: ['정밀 초음파'],
  24: ['임신성 당뇨 검사'],
  28: ['빈혈 검사'],
  32: ['초음파'],
  36: ['B군 연쇄상구균 검사', '초음파'],
  38: ['내진', '초음파'],
  40: ['내진', '초음파', 'NST'],
};

@Injectable()
export class ObstetricsService {
  constructor(
    @InjectRepository(ObPregnancy)
    private readonly pregnancyRepo: Repository<ObPregnancy>,
    @InjectRepository(ObCheckup)
    private readonly checkupRepo: Repository<ObCheckup>,
    @InjectRepository(ObFetalMovement)
    private readonly fetalMovementRepo: Repository<ObFetalMovement>,
    @InjectRepository(ObMaternalLog)
    private readonly maternalLogRepo: Repository<ObMaternalLog>,
  ) {}

  async createPregnancy(
    patientId: string,
    dto: { dueDate: string; lmpDate: string },
  ): Promise<ObPregnancy> {
    const pregnancy = this.pregnancyRepo.create({
      patientId,
      dueDate: dto.dueDate,
      lmpDate: dto.lmpDate,
      status: PregnancyStatus.ACTIVE,
    });
    return this.pregnancyRepo.save(pregnancy);
  }

  async getActivePregnancy(patientId: string): Promise<ObPregnancy | null> {
    return this.pregnancyRepo.findOne({
      where: { patientId, status: PregnancyStatus.ACTIVE },
    });
  }

  getCurrentWeek(pregnancy: ObPregnancy): number {
    const lmp = new Date(pregnancy.lmpDate);
    const now = new Date();
    const diffMs = now.getTime() - lmp.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));
    return Math.floor(diffDays / 7);
  }

  private async findPregnancy(pregnancyId: string): Promise<ObPregnancy> {
    const pregnancy = await this.pregnancyRepo.findOne({ where: { id: pregnancyId } });
    if (!pregnancy) throw new NotFoundException('Pregnancy not found');
    return pregnancy;
  }

  async addCheckup(
    pregnancyId: string,
    dto: {
      week: number;
      type: string;
      results: Record<string, unknown>;
      ultrasoundUrl?: string;
      checkedAt: Date;
    },
  ): Promise<ObCheckup> {
    await this.findPregnancy(pregnancyId);
    const checkup = this.checkupRepo.create({
      pregnancyId,
      week: dto.week,
      type: dto.type,
      results: dto.results,
      ultrasoundUrl: dto.ultrasoundUrl ?? null,
      checkedAt: dto.checkedAt,
    });
    return this.checkupRepo.save(checkup);
  }

  async getCheckups(pregnancyId: string): Promise<ObCheckup[]> {
    return this.checkupRepo.find({
      where: { pregnancyId },
      order: { checkedAt: 'DESC' },
    });
  }

  async getCheckupSchedule(pregnancyId: string): Promise<Array<{ week: number; items: string[]; done: boolean }>> {
    const pregnancy = await this.findPregnancy(pregnancyId);
    const completed = await this.checkupRepo.find({ where: { pregnancyId } });
    const completedWeeks = new Set(completed.map((c) => c.week));
    const currentWeek = this.getCurrentWeek(pregnancy);

    return Object.entries(CHECKUP_SCHEDULE)
      .map(([week, items]) => ({
        week: Number(week),
        items,
        done: completedWeeks.has(Number(week)),
      }))
      .filter((entry) => entry.week <= currentWeek + 4)
      .sort((a, b) => a.week - b.week);
  }

  async addFetalMovement(
    pregnancyId: string,
    dto: { count: number; durationMin: number; loggedAt: Date },
  ): Promise<ObFetalMovement> {
    await this.findPregnancy(pregnancyId);
    const movement = this.fetalMovementRepo.create({
      pregnancyId,
      count: dto.count,
      durationMin: dto.durationMin,
      loggedAt: dto.loggedAt,
    });
    return this.fetalMovementRepo.save(movement);
  }

  async getFetalMovements(pregnancyId: string, date?: string): Promise<ObFetalMovement[]> {
    if (date) {
      const start = new Date(date);
      const end = new Date(date);
      end.setDate(end.getDate() + 1);
      return this.fetalMovementRepo.find({
        where: { pregnancyId, loggedAt: Between(start, end) },
        order: { loggedAt: 'DESC' },
      });
    }
    return this.fetalMovementRepo.find({
      where: { pregnancyId },
      order: { loggedAt: 'DESC' },
    });
  }

  async addMaternalLog(
    pregnancyId: string,
    dto: {
      weight: number;
      bloodPressureSys: number;
      bloodPressureDia: number;
      edemaLevel: EdemaLevel;
      note?: string;
      loggedAt: Date;
    },
  ): Promise<ObMaternalLog> {
    await this.findPregnancy(pregnancyId);
    const log = this.maternalLogRepo.create({
      pregnancyId,
      weight: dto.weight,
      bloodPressureSys: dto.bloodPressureSys,
      bloodPressureDia: dto.bloodPressureDia,
      edemaLevel: dto.edemaLevel,
      note: dto.note ?? null,
      loggedAt: dto.loggedAt,
    });
    return this.maternalLogRepo.save(log);
  }

  async getMaternalLogs(pregnancyId: string): Promise<ObMaternalLog[]> {
    return this.maternalLogRepo.find({
      where: { pregnancyId },
      order: { loggedAt: 'DESC' },
    });
  }

  async getMaternalTrend(pregnancyId: string): Promise<{
    weightTrend: Array<{ loggedAt: Date; weight: number }>;
    bpTrend: Array<{ loggedAt: Date; sys: number; dia: number }>;
  }> {
    const logs = await this.maternalLogRepo.find({
      where: { pregnancyId },
      order: { loggedAt: 'ASC' },
    });

    return {
      weightTrend: logs.map((l) => ({ loggedAt: l.loggedAt, weight: Number(l.weight) })),
      bpTrend: logs.map((l) => ({
        loggedAt: l.loggedAt,
        sys: l.bloodPressureSys,
        dia: l.bloodPressureDia,
      })),
    };
  }
}
