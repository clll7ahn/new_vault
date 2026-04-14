import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { KmConstitution, KmConstitutionType } from './entities/km-constitution.entity';
import { KmTreatmentRecord, KmTreatmentType } from './entities/km-treatment-record.entity';
import { KmDietaryGuide } from './entities/km-dietary-guide.entity';

@Injectable()
export class KoreanMedicineService {
  constructor(
    @InjectRepository(KmConstitution)
    private readonly constitutionRepo: Repository<KmConstitution>,
    @InjectRepository(KmTreatmentRecord)
    private readonly treatmentRepo: Repository<KmTreatmentRecord>,
    @InjectRepository(KmDietaryGuide)
    private readonly dietaryRepo: Repository<KmDietaryGuide>,
  ) {}

  async setConstitution(patientId: string, dto: {
    doctorId: string;
    constitutionType: KmConstitutionType;
    diagnosisNote: string;
    diagnosedAt: Date;
  }): Promise<KmConstitution> {
    const constitution = this.constitutionRepo.create({
      patientId,
      doctorId: dto.doctorId,
      constitutionType: dto.constitutionType,
      diagnosisNote: dto.diagnosisNote,
      diagnosedAt: dto.diagnosedAt,
    });
    return this.constitutionRepo.save(constitution);
  }

  async getConstitution(patientId: string): Promise<KmConstitution | null> {
    return this.constitutionRepo.findOne({
      where: { patientId },
      order: { diagnosedAt: 'DESC' },
    });
  }

  async addTreatmentRecord(patientId: string, dto: {
    doctorId: string;
    treatmentType: KmTreatmentType;
    bodyPoints?: string[];
    prescription?: string;
    note?: string;
    treatedAt: Date;
  }): Promise<KmTreatmentRecord> {
    const record = this.treatmentRepo.create({
      patientId,
      doctorId: dto.doctorId,
      treatmentType: dto.treatmentType,
      bodyPoints: dto.bodyPoints ?? null,
      prescription: dto.prescription ?? null,
      note: dto.note ?? null,
      treatedAt: dto.treatedAt,
    });
    return this.treatmentRepo.save(record);
  }

  async getTreatmentRecords(patientId: string): Promise<KmTreatmentRecord[]> {
    return this.treatmentRepo.find({
      where: { patientId },
      order: { treatedAt: 'DESC' },
    });
  }

  async getTreatmentHistory(patientId: string, treatmentType: KmTreatmentType): Promise<KmTreatmentRecord[]> {
    return this.treatmentRepo.find({
      where: { patientId, treatmentType },
      order: { treatedAt: 'ASC' },
    });
  }

  async getDietaryGuide(constitutionId: string): Promise<KmDietaryGuide | null> {
    return this.dietaryRepo.findOne({ where: { constitutionId } });
  }

  async setDietaryGuide(constitutionId: string, dto: {
    recommendedFoods: string[];
    avoidedFoods: string[];
    lifestyleTips: string[];
  }): Promise<KmDietaryGuide> {
    const existing = await this.dietaryRepo.findOne({ where: { constitutionId } });
    if (existing) {
      Object.assign(existing, dto);
      return this.dietaryRepo.save(existing);
    }
    const guide = this.dietaryRepo.create({ constitutionId, ...dto });
    return this.dietaryRepo.save(guide);
  }
}
