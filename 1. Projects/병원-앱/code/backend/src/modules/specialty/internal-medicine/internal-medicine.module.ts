import { DynamicModule, Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ImVitals } from './entities/im-vitals.entity';
import { ImMedication } from './entities/im-medication.entity';
import { ImMedLog } from './entities/im-med-log.entity';
import { InternalMedicineService } from './internal-medicine.service';
import { InternalMedicineController } from './internal-medicine.controller';

@Module({})
export class InternalMedicineModule {
  static forRoot(): DynamicModule {
    return {
      module: InternalMedicineModule,
      imports: [TypeOrmModule.forFeature([ImVitals, ImMedication, ImMedLog])],
      controllers: [InternalMedicineController],
      providers: [InternalMedicineService],
      exports: [InternalMedicineService],
    };
  }
}
