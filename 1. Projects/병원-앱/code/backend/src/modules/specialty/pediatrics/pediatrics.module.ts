import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PedChild } from './entities/ped-child.entity';
import { PedGrowthLog } from './entities/ped-growth-log.entity';
import { PedVaccination } from './entities/ped-vaccination.entity';
import { PediatricsService } from './pediatrics.service';
import { PediatricsController } from './pediatrics.controller';

@Module({
  imports: [TypeOrmModule.forFeature([PedChild, PedGrowthLog, PedVaccination])],
  controllers: [PediatricsController],
  providers: [PediatricsService],
  exports: [PediatricsService],
})
export class PediatricsModule {}
