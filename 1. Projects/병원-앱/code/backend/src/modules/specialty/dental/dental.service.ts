import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DentToothChart } from './entities/dent-tooth-chart.entity';
import { DentTreatment } from './entities/dent-treatment.entity';

@Injectable()
export class DentalService {
  constructor(
    @InjectRepository(DentToothChart)
    private readonly toothChartRepo: Repository<DentToothChart>,
    @InjectRepository(DentTreatment)
    private readonly treatmentRepo: Repository<DentTreatment>,
  ) {}

  async getToothChart(patientId: string): Promise<DentToothChart[]> {
    return this.toothChartRepo.find({
      where: { patientId },
      order: { toothNumber: 'ASC' },
    });
  }

  async updateTooth(
    patientId: string,
    toothNumber: number,
    dto: {
      status: 'healthy' | 'cavity' | 'treated' | 'extracted' | 'implant';
      conditions?: Record<string, unknown>;
    },
  ): Promise<DentToothChart> {
    let tooth = await this.toothChartRepo.findOne({ where: { patientId, toothNumber } });
    if (!tooth) {
      tooth = this.toothChartRepo.create({ patientId, toothNumber });
    }
    tooth.status = dto.status;
    tooth.conditions = dto.conditions ?? null;
    return this.toothChartRepo.save(tooth);
  }

  async addTreatment(patientId: string, dto: {
    toothNumber: number;
    treatmentType: string;
    planStep?: number;
    status?: 'planned' | 'in_progress' | 'completed';
    treatedAt?: Date;
    nextDate?: string;
  }): Promise<DentTreatment> {
    const treatment = this.treatmentRepo.create({
      patientId,
      toothNumber: dto.toothNumber,
      treatmentType: dto.treatmentType,
      planStep: dto.planStep ?? null,
      status: dto.status ?? 'planned',
      treatedAt: dto.treatedAt ?? null,
      nextDate: dto.nextDate ?? null,
    });
    return this.treatmentRepo.save(treatment);
  }

  async getTreatments(patientId: string): Promise<DentTreatment[]> {
    return this.treatmentRepo.find({
      where: { patientId },
      order: { treatedAt: 'DESC' },
    });
  }

  async getTreatmentPlan(patientId: string): Promise<DentTreatment[]> {
    return this.treatmentRepo.find({
      where: [
        { patientId, status: 'planned' },
        { patientId, status: 'in_progress' },
      ],
      order: { planStep: 'ASC' },
    });
  }

  async getNextCheckupDate(patientId: string): Promise<{ nextCheckup: string | null }> {
    const lastTreatment = await this.treatmentRepo.findOne({
      where: { patientId, status: 'completed' },
      order: { treatedAt: 'DESC' },
    });

    if (!lastTreatment || !lastTreatment.treatedAt) {
      return { nextCheckup: null };
    }

    const next = new Date(lastTreatment.treatedAt);
    next.setMonth(next.getMonth() + 6);
    return { nextCheckup: next.toISOString().split('T')[0] };
  }
}
