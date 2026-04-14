import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UroVoidingLog } from './entities/uro-voiding-log.entity';
import { UroPsaRecord } from './entities/uro-psa-record.entity';
import { UrologyService } from './urology.service';
import { UrologyController } from './urology.controller';

@Module({
  imports: [TypeOrmModule.forFeature([UroVoidingLog, UroPsaRecord])],
  controllers: [UrologyController],
  providers: [UrologyService],
  exports: [UrologyService],
})
export class UrologyModule {}
