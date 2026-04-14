import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { HealthRecord } from './entities/health-record.entity';
import { HealthTrackerService } from './health-tracker.service';
import { HealthTrackerController } from './health-tracker.controller';

@Module({
  imports: [TypeOrmModule.forFeature([HealthRecord])],
  controllers: [HealthTrackerController],
  providers: [HealthTrackerService],
  exports: [HealthTrackerService],
})
export class HealthTrackerModule {}
