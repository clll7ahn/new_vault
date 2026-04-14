import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { OrthoPainLog } from './entities/ortho-pain-log.entity';
import { OrthoRehabProgram } from './entities/ortho-rehab-program.entity';
import { OrthoExerciseLog } from './entities/ortho-exercise-log.entity';
import { OrthopedicsService } from './orthopedics.service';
import { OrthopedicsController } from './orthopedics.controller';

@Module({
  imports: [TypeOrmModule.forFeature([OrthoPainLog, OrthoRehabProgram, OrthoExerciseLog])],
  controllers: [OrthopedicsController],
  providers: [OrthopedicsService],
  exports: [OrthopedicsService],
})
export class OrthopedicsModule {}
