import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { DentToothChart } from './entities/dent-tooth-chart.entity';
import { DentTreatment } from './entities/dent-treatment.entity';
import { DentalService } from './dental.service';
import { DentalController } from './dental.controller';

@Module({
  imports: [TypeOrmModule.forFeature([DentToothChart, DentTreatment])],
  controllers: [DentalController],
  providers: [DentalService],
  exports: [DentalService],
})
export class DentalModule {}
