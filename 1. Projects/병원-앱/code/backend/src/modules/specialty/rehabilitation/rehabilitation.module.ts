import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RehabAssessment } from './entities/rehab-assessment.entity';
import { RehabExerciseProgram } from './entities/rehab-exercise-program.entity';
import { RehabSessionLog } from './entities/rehab-session-log.entity';
import { RehabilitationService } from './rehabilitation.service';
import { RehabilitationController } from './rehabilitation.controller';

@Module({
  imports: [TypeOrmModule.forFeature([RehabAssessment, RehabExerciseProgram, RehabSessionLog])],
  controllers: [RehabilitationController],
  providers: [RehabilitationService],
  exports: [RehabilitationService],
})
export class RehabilitationModule {}
