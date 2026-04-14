import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { PsychiatryService } from './psychiatry.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { UserRole } from '../../common/auth/entities/user.entity';

@Controller('api/v1/specialty/psychiatry')
export class PsychiatryController {
  constructor(private readonly psyService: PsychiatryService) {}

  @Get('crisis-resources')
  getCrisisResources() {
    return this.psyService.getCrisisResources();
  }

  @UseGuards(JwtAuthGuard)
  @Post('mood-logs')
  addMoodLog(
    @CurrentUser('id') patientId: string,
    @Body() body: { moodScore: number; moodEmoji: string; note?: string; loggedAt: string },
  ) {
    return this.psyService.addMoodLog(patientId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @UseGuards(JwtAuthGuard)
  @Get('mood-logs')
  getMoodLogs(
    @CurrentUser('id') patientId: string,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.psyService.getMoodLogs(patientId, new Date(from), new Date(to));
  }

  @UseGuards(JwtAuthGuard)
  @Get('mood-logs/trend')
  getMoodTrend(@CurrentUser('id') patientId: string) {
    return this.psyService.getMoodTrend(patientId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('sleep-logs')
  addSleepLog(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      bedTime: string;
      wakeTime: string;
      quality: number;
      note?: string;
      loggedAt: string;
    },
  ) {
    return this.psyService.addSleepLog(patientId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @UseGuards(JwtAuthGuard)
  @Get('sleep-logs')
  getSleepLogs(
    @CurrentUser('id') patientId: string,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.psyService.getSleepLogs(patientId, new Date(from), new Date(to));
  }

  @UseGuards(JwtAuthGuard)
  @Get('sleep-logs/pattern')
  getSleepPattern(@CurrentUser('id') patientId: string) {
    return this.psyService.getSleepPattern(patientId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('med-reactions')
  addMedReaction(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      medication: string;
      moodBefore: number;
      moodAfter: number;
      sideEffects?: string;
      loggedAt: string;
    },
  ) {
    return this.psyService.addMedReaction(patientId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @UseGuards(JwtAuthGuard)
  @Get('med-reactions')
  getMedReactions(@CurrentUser('id') patientId: string) {
    return this.psyService.getMedReactions(patientId);
  }

  @UseGuards(JwtAuthGuard)
  @Post('counseling-notes')
  addCounselingNote(
    @CurrentUser('id') doctorId: string,
    @Body() body: {
      patientId: string;
      summary: string;
      patientVisible: boolean;
      sessionAt: string;
    },
  ) {
    return this.psyService.addCounselingNote(doctorId, {
      ...body,
      sessionAt: new Date(body.sessionAt),
    });
  }

  @UseGuards(JwtAuthGuard)
  @Get('counseling-notes')
  getCounselingNotes(
    @CurrentUser('id') patientId: string,
    @CurrentUser('role') role: UserRole,
  ) {
    const isDoctor = role === UserRole.DOCTOR || role === UserRole.ADMIN;
    return this.psyService.getCounselingNotes(patientId, isDoctor);
  }
}
