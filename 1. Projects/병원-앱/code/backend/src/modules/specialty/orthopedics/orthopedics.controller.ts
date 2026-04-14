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
import { OrthopedicsService } from './orthopedics.service';
import { RehabExercise } from './entities/ortho-rehab-program.entity';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/specialty/orthopedics')
@UseGuards(JwtAuthGuard)
export class OrthopedicsController {
  constructor(private readonly orthoService: OrthopedicsService) {}

  @Post('pain-logs')
  addPainLog(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      bodyPart: string;
      intensity: number;
      painType: string;
      note?: string;
      loggedAt: string;
    },
  ) {
    return this.orthoService.addPainLog(patientId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @Get('pain-logs')
  getPainLogs(
    @CurrentUser('id') patientId: string,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.orthoService.getPainLogs(patientId, from, to);
  }

  @Get('pain-logs/trend')
  getPainTrend(
    @CurrentUser('id') patientId: string,
    @Query('bodyPart') bodyPart: string,
  ) {
    return this.orthoService.getPainTrend(patientId, bodyPart);
  }

  @Post('rehab-programs')
  createRehabProgram(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      doctorId: string;
      title: string;
      exercises: RehabExercise[];
      startDate: string;
      endDate?: string;
    },
  ) {
    return this.orthoService.createRehabProgram({ patientId, ...body });
  }

  @Get('rehab-programs')
  getActivePrograms(@CurrentUser('id') patientId: string) {
    return this.orthoService.getActivePrograms(patientId);
  }

  @Post('rehab-programs/:id/exercise-logs')
  logExercise(
    @Param('id', ParseUUIDPipe) programId: string,
    @Body() body: {
      exerciseName: string;
      completed: boolean;
      loggedAt: string;
    },
  ) {
    return this.orthoService.logExercise(programId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @Get('rehab-programs/:id/exercise-logs')
  getExerciseLogs(@Param('id', ParseUUIDPipe) programId: string) {
    return this.orthoService.getExerciseLogs(programId);
  }

  @Get('rehab-programs/:id/adherence')
  getRehabAdherence(@Param('id', ParseUUIDPipe) programId: string) {
    return this.orthoService.getRehabAdherence(programId);
  }
}
