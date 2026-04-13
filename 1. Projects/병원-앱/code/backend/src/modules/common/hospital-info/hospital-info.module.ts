import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Hospital } from './entities/hospital.entity';
import { Department } from './entities/department.entity';
import { Doctor } from './entities/doctor.entity';
import { HospitalInfoService } from './hospital-info.service';
import { HospitalInfoController } from './hospital-info.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Hospital, Department, Doctor])],
  controllers: [HospitalInfoController],
  providers: [HospitalInfoService],
  exports: [HospitalInfoService],
})
export class HospitalInfoModule {}
