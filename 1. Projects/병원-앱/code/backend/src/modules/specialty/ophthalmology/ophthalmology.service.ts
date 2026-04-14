import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { OphVisionLog } from './entities/oph-vision-log.entity';
import { OphPrescription } from './entities/oph-prescription.entity';
import { OphEyeDrop } from './entities/oph-eye-drop.entity';

@Injectable()
export class OphthalmologyService {
  constructor(
    @InjectRepository(OphVisionLog)
    private readonly visionRepo: Repository<OphVisionLog>,
    @InjectRepository(OphPrescription)
    private readonly prescriptionRepo: Repository<OphPrescription>,
    @InjectRepository(OphEyeDrop)
    private readonly eyeDropRepo: Repository<OphEyeDrop>,
  ) {}

  async addVisionLog(patientId: string, dto: {
    eye: 'left' | 'right' | 'both';
    vision: number;
    iop?: number;
    measuredAt: Date;
  }): Promise<OphVisionLog> {
    const log = this.visionRepo.create({
      patientId,
      eye: dto.eye,
      vision: dto.vision,
      iop: dto.iop ?? null,
      measuredAt: dto.measuredAt,
    });
    return this.visionRepo.save(log);
  }

  async getVisionLogs(patientId: string): Promise<OphVisionLog[]> {
    return this.visionRepo.find({
      where: { patientId },
      order: { measuredAt: 'DESC' },
    });
  }

  async getVisionTrend(
    patientId: string,
    eye: 'left' | 'right' | 'both',
  ): Promise<{ measuredAt: Date; vision: number; iop: number | null }[]> {
    const logs = await this.visionRepo.find({
      where: { patientId, eye },
      order: { measuredAt: 'ASC' },
    });
    return logs.map((l) => ({
      measuredAt: l.measuredAt,
      vision: Number(l.vision),
      iop: l.iop !== null ? Number(l.iop) : null,
    }));
  }

  async addPrescription(patientId: string, dto: {
    type: 'glasses' | 'contact_lens';
    sphLeft: number;
    sphRight: number;
    cylLeft?: number;
    cylRight?: number;
    prescribedAt: Date;
    nextReplace?: string;
  }): Promise<OphPrescription> {
    const prescription = this.prescriptionRepo.create({
      patientId,
      type: dto.type,
      sphLeft: dto.sphLeft,
      sphRight: dto.sphRight,
      cylLeft: dto.cylLeft ?? null,
      cylRight: dto.cylRight ?? null,
      prescribedAt: dto.prescribedAt,
      nextReplace: dto.nextReplace ?? null,
    });
    return this.prescriptionRepo.save(prescription);
  }

  async getPrescriptions(patientId: string): Promise<OphPrescription[]> {
    return this.prescriptionRepo.find({
      where: { patientId },
      order: { prescribedAt: 'DESC' },
    });
  }

  async getExpiringPrescriptions(patientId: string): Promise<OphPrescription[]> {
    const thirtyDaysLater = new Date();
    thirtyDaysLater.setDate(thirtyDaysLater.getDate() + 30);
    const cutoff = thirtyDaysLater.toISOString().split('T')[0];
    const today = new Date().toISOString().split('T')[0];

    const prescriptions = await this.prescriptionRepo.find({
      where: { patientId },
      order: { nextReplace: 'ASC' },
    });

    return prescriptions.filter(
      (p) => p.nextReplace && p.nextReplace >= today && p.nextReplace <= cutoff,
    );
  }

  async addEyeDrop(patientId: string, dto: {
    name: string;
    frequency: string;
    startDate: string;
    endDate?: string;
  }): Promise<OphEyeDrop> {
    const eyeDrop = this.eyeDropRepo.create({
      patientId,
      name: dto.name,
      frequency: dto.frequency,
      startDate: dto.startDate,
      endDate: dto.endDate ?? null,
      isActive: true,
    });
    return this.eyeDropRepo.save(eyeDrop);
  }

  async getActiveEyeDrops(patientId: string): Promise<OphEyeDrop[]> {
    return this.eyeDropRepo.find({
      where: { patientId, isActive: true },
      order: { startDate: 'DESC' },
    });
  }
}
