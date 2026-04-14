import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PsProcedure } from './entities/ps-procedure.entity';
import { PsPhotoRecord } from './entities/ps-photo-record.entity';
import { PsRecoveryLog } from './entities/ps-recovery-log.entity';
import { PlasticSurgeryService } from './plastic-surgery.service';
import { PlasticSurgeryController } from './plastic-surgery.controller';

@Module({
  imports: [TypeOrmModule.forFeature([PsProcedure, PsPhotoRecord, PsRecoveryLog])],
  controllers: [PlasticSurgeryController],
  providers: [PlasticSurgeryService],
  exports: [PlasticSurgeryService],
})
export class PlasticSurgeryModule {}
