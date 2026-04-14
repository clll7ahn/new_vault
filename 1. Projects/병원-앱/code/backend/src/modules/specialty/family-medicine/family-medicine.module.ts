import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FmCheckupResult } from './entities/fm-checkup-result.entity';
import { FmLifestyleLog } from './entities/fm-lifestyle-log.entity';
import { FamilyMedicineService } from './family-medicine.service';
import { FamilyMedicineController } from './family-medicine.controller';

@Module({
  imports: [TypeOrmModule.forFeature([FmCheckupResult, FmLifestyleLog])],
  controllers: [FamilyMedicineController],
  providers: [FamilyMedicineService],
  exports: [FamilyMedicineService],
})
export class FamilyMedicineModule {}
