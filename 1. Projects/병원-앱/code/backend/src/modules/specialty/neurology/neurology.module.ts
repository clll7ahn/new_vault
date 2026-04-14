import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { NeuroHeadacheLog } from './entities/neuro-headache-log.entity';
import { NeuroCognitiveTest } from './entities/neuro-cognitive-test.entity';
import { NeurologyService } from './neurology.service';
import { NeurologyController } from './neurology.controller';

@Module({
  imports: [TypeOrmModule.forFeature([NeuroHeadacheLog, NeuroCognitiveTest])],
  controllers: [NeurologyController],
  providers: [NeurologyService],
  exports: [NeurologyService],
})
export class NeurologyModule {}
