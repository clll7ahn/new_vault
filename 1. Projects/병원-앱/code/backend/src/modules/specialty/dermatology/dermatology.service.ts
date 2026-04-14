import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DermSkinPhoto } from './entities/derm-skin-photo.entity';
import { DermTreatment } from './entities/derm-treatment.entity';

@Injectable()
export class DermatologyService {
  constructor(
    @InjectRepository(DermSkinPhoto)
    private readonly photoRepo: Repository<DermSkinPhoto>,
    @InjectRepository(DermTreatment)
    private readonly treatmentRepo: Repository<DermTreatment>,
  ) {}

  async addSkinPhoto(patientId: string, dto: {
    bodyArea: string;
    imageUrl: string;
    aiResult?: Record<string, unknown>;
    score?: number;
    takenAt: Date;
  }): Promise<DermSkinPhoto> {
    const photo = this.photoRepo.create({
      patientId,
      bodyArea: dto.bodyArea,
      imageUrl: dto.imageUrl,
      aiResult: dto.aiResult ?? null,
      score: dto.score ?? null,
      takenAt: dto.takenAt,
    });
    return this.photoRepo.save(photo);
  }

  async getSkinPhotos(patientId: string, bodyArea?: string): Promise<DermSkinPhoto[]> {
    const where: Record<string, unknown> = { patientId };
    if (bodyArea) where.bodyArea = bodyArea;
    return this.photoRepo.find({
      where,
      order: { takenAt: 'DESC' },
    });
  }

  async getSkinTimeline(patientId: string): Promise<Record<string, DermSkinPhoto[]>> {
    const photos = await this.photoRepo.find({
      where: { patientId },
      order: { takenAt: 'ASC' },
    });

    return photos.reduce<Record<string, DermSkinPhoto[]>>((acc, photo) => {
      if (!acc[photo.bodyArea]) acc[photo.bodyArea] = [];
      acc[photo.bodyArea].push(photo);
      return acc;
    }, {});
  }

  async addTreatment(patientId: string, dto: {
    doctorId: string;
    type: string;
    description: string;
    cost?: number;
    treatedAt: Date;
    nextDate?: string;
  }): Promise<DermTreatment> {
    const treatment = this.treatmentRepo.create({
      patientId,
      doctorId: dto.doctorId,
      type: dto.type,
      description: dto.description,
      cost: dto.cost ?? null,
      treatedAt: dto.treatedAt,
      nextDate: dto.nextDate ?? null,
    });
    return this.treatmentRepo.save(treatment);
  }

  async getTreatments(patientId: string): Promise<DermTreatment[]> {
    return this.treatmentRepo.find({
      where: { patientId },
      order: { treatedAt: 'DESC' },
    });
  }

  async getBeforeAfter(
    patientId: string,
    bodyArea: string,
  ): Promise<{ before: DermSkinPhoto | null; after: DermSkinPhoto | null }> {
    const photos = await this.photoRepo.find({
      where: { patientId, bodyArea },
      order: { takenAt: 'ASC' },
    });

    return {
      before: photos[0] ?? null,
      after: photos.length > 1 ? photos[photos.length - 1] : null,
    };
  }
}
