import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { LessThan, Repository } from 'typeorm';
import { PedChild } from './entities/ped-child.entity';
import { PedGrowthLog } from './entities/ped-growth-log.entity';
import { PedVaccination } from './entities/ped-vaccination.entity';

@Injectable()
export class PediatricsService {
  constructor(
    @InjectRepository(PedChild)
    private readonly childRepo: Repository<PedChild>,
    @InjectRepository(PedGrowthLog)
    private readonly growthRepo: Repository<PedGrowthLog>,
    @InjectRepository(PedVaccination)
    private readonly vaccinationRepo: Repository<PedVaccination>,
  ) {}

  async addChild(parentId: string, dto: {
    name: string;
    birthDate: string;
    gender: 'male' | 'female';
    bloodType?: string;
  }): Promise<PedChild> {
    const child = this.childRepo.create({
      parentId,
      name: dto.name,
      birthDate: dto.birthDate,
      gender: dto.gender,
      bloodType: dto.bloodType ?? null,
    });
    return this.childRepo.save(child);
  }

  async getChildren(parentId: string): Promise<PedChild[]> {
    return this.childRepo.find({
      where: { parentId },
      order: { createdAt: 'ASC' },
    });
  }

  async getChild(id: string): Promise<PedChild> {
    const child = await this.childRepo.findOne({ where: { id } });
    if (!child) throw new NotFoundException(`Child ${id} not found`);
    return child;
  }

  async addGrowthLog(childId: string, dto: {
    height: number;
    weight: number;
    headCirc?: number;
    measuredAt: Date;
  }): Promise<PedGrowthLog> {
    const log = this.growthRepo.create({
      childId,
      height: dto.height,
      weight: dto.weight,
      headCirc: dto.headCirc ?? null,
      measuredAt: dto.measuredAt,
    });
    return this.growthRepo.save(log);
  }

  async getGrowthLogs(childId: string): Promise<PedGrowthLog[]> {
    return this.growthRepo.find({
      where: { childId },
      order: { measuredAt: 'DESC' },
    });
  }

  async getGrowthChart(childId: string): Promise<{
    measuredAt: Date;
    height: number;
    weight: number;
    headCirc: number | null;
  }[]> {
    const logs = await this.growthRepo.find({
      where: { childId },
      order: { measuredAt: 'ASC' },
    });
    return logs.map((l) => ({
      measuredAt: l.measuredAt,
      height: Number(l.height),
      weight: Number(l.weight),
      headCirc: l.headCirc !== null ? Number(l.headCirc) : null,
    }));
  }

  async getVaccinations(childId: string): Promise<PedVaccination[]> {
    return this.vaccinationRepo.find({
      where: { childId },
      order: { scheduledDate: 'ASC' },
    });
  }

  async updateVaccination(id: string, actualDate: string): Promise<PedVaccination> {
    const vaccination = await this.vaccinationRepo.findOne({ where: { id } });
    if (!vaccination) throw new NotFoundException(`Vaccination ${id} not found`);
    vaccination.actualDate = actualDate;
    vaccination.status = 'completed';
    return this.vaccinationRepo.save(vaccination);
  }

  async getOverdueVaccinations(childId: string): Promise<PedVaccination[]> {
    const today = new Date().toISOString().split('T')[0];
    return this.vaccinationRepo.find({
      where: {
        childId,
        status: 'scheduled',
        scheduledDate: LessThan(today) as unknown as string,
      },
      order: { scheduledDate: 'ASC' },
    });
  }
}
