import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { NeurologyService } from './neurology.service';
import { HeadacheType, HeadacheLocation } from './entities/neuro-headache-log.entity';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/specialty/neurology')
@UseGuards(JwtAuthGuard)
export class NeurologyController {
  constructor(private readonly neurologyService: NeurologyService) {}

  @Post('headaches')
  addHeadacheLog(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      headacheType: HeadacheType;
      intensity: number;
      durationHours: number;
      triggers?: string[];
      location: HeadacheLocation;
      loggedAt: string;
    },
  ) {
    return this.neurologyService.addHeadacheLog(patientId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @Get('headaches')
  getHeadacheLogs(
    @CurrentUser('id') patientId: string,
    @Query('headacheType') headacheType?: HeadacheType,
  ) {
    return this.neurologyService.getHeadacheLogs(patientId, headacheType);
  }

  @Get('headaches/trend')
  getHeadacheTrend(@CurrentUser('id') patientId: string) {
    return this.neurologyService.getHeadacheTrend(patientId);
  }

  @Get('headaches/trigger-stats')
  getHeadacheTriggerStats(@CurrentUser('id') patientId: string) {
    return this.neurologyService.getHeadacheTriggerStats(patientId);
  }

  @Post('cognitive-tests')
  addCognitiveTest(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      testType: string;
      score: number;
      maxScore: number;
      testedAt: string;
      note?: string;
    },
  ) {
    return this.neurologyService.addCognitiveTest(patientId, body);
  }

  @Get('cognitive-tests')
  getCognitiveTests(
    @CurrentUser('id') patientId: string,
    @Query('testType') testType?: string,
  ) {
    return this.neurologyService.getCognitiveTests(patientId, testType);
  }

  @Get('cognitive-tests/progress')
  getCognitiveProgress(
    @CurrentUser('id') patientId: string,
    @Query('testType') testType: string,
  ) {
    return this.neurologyService.getCognitiveProgress(patientId, testType);
  }

  @Get('health')
  health() {
    return { status: 'ok', module: 'neurology' };
  }
}
