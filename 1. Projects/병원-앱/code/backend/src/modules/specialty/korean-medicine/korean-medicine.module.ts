import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { KmConstitution } from './entities/km-constitution.entity';
import { KmTreatmentRecord } from './entities/km-treatment-record.entity';
import { KmDietaryGuide } from './entities/km-dietary-guide.entity';
import { KoreanMedicineService } from './korean-medicine.service';
import { KoreanMedicineController } from './korean-medicine.controller';

@Module({
  imports: [TypeOrmModule.forFeature([KmConstitution, KmTreatmentRecord, KmDietaryGuide])],
  controllers: [KoreanMedicineController],
  providers: [KoreanMedicineService],
  exports: [KoreanMedicineService],
})
export class KoreanMedicineModule {}
