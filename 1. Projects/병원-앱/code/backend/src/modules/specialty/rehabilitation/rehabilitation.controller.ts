import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { RehabilitationService } from './rehabilitation.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { RehabAssessmentType } from './entities/rehab-assessment.entity';
import { ExerciseItem } from './entities/rehab-exercise-program.entity';
import { CompletedExercise } from './entities/rehab-session-log.entity';

@Controller('api/v1/specialty/rehabilitation')
@UseGuards(JwtAuthGuard)
export class RehabilitationController {
  constructor(private readonly service: RehabilitationService) {}

  @Post('assessments')
  addAssessment(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      doctorId: string;
      assessmentType: RehabAssessmentType;
      bodyPart: string;
      score: number;
      maxScore: number;
      unit?: string;
      assessedAt: string;
      note?: string;
    },
  ) {
    return this.service.addAssessment(patientId, {
      ...body,
      assessedAt: new Date(body.assessedAt),
    });
  }

  @Get('assessments')
  getAssessments(
    @CurrentUser('id') patientId: string,
    @Query('type') assessmentType?: RehabAssessmentType,
  ) {
    return this.service.getAssessments(patientId, assessmentType);
  }

  @Get('assessments/trend')
  getAssessmentTrend(
    @CurrentUser('id') patientId: string,
    @Query('bodyPart') bodyPart: string,
  ) {
    return this.service.getAssessmentTrend(patientId, bodyPart);
  }

  @Post('programs')
  createProgram(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      doctorId: string;
      title: string;
      goal: string;
      exercises: ExerciseItem[];
      frequencyPerWeek: number;
      startDate: string;
      endDate?: string;
    },
  ) {
    return this.service.createProgram(patientId, body);
  }

  @Get('programs/active')
  getActivePrograms(@CurrentUser('id') patientId: string) {
    return this.service.getActivePrograms(patientId);
  }

  @Post('programs/:id/sessions')
  logSession(
    @Param('id', ParseUUIDPipe) programId: string,
    @Body() body: {
      exercisesCompleted: CompletedExercise[];
      painBefore: number;
      painAfter: number;
      note?: string;
      loggedAt: string;
    },
  ) {
    return this.service.logSession({
      programId,
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @Get('programs/:id/sessions')
  getSessionLogs(@Param('id', ParseUUIDPipe) programId: string) {
    return this.service.getSessionLogs(programId);
  }

  @Get('programs/:id/progress')
  getRehabProgress(@Param('id', ParseUUIDPipe) programId: string) {
    return this.service.getRehabProgress(programId);
  }
}
