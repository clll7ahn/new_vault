import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PsyMoodLog } from './entities/psy-mood-log.entity';
import { PsySleepLog } from './entities/psy-sleep-log.entity';
import { PsyMedReaction } from './entities/psy-med-reaction.entity';
import { PsyCounselingNote } from './entities/psy-counseling-note.entity';
import { PsychiatryService } from './psychiatry.service';
import { PsychiatryController } from './psychiatry.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([PsyMoodLog, PsySleepLog, PsyMedReaction, PsyCounselingNote]),
  ],
  controllers: [PsychiatryController],
  providers: [PsychiatryService],
  exports: [PsychiatryService],
})
export class PsychiatryModule {}
