import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EntSymptomLog } from './entities/ent-symptom-log.entity';
import { EntAllergyRecord } from './entities/ent-allergy-record.entity';
import { EntService } from './ent.service';
import { EntController } from './ent.controller';

@Module({
  imports: [TypeOrmModule.forFeature([EntSymptomLog, EntAllergyRecord])],
  controllers: [EntController],
  providers: [EntService],
  exports: [EntService],
})
export class EntModule {}
