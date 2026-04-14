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
import { ObstetricsService } from './obstetrics.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { EdemaLevel } from './entities/ob-maternal-log.entity';

@Controller('api/v1/specialty/obstetrics')
@UseGuards(JwtAuthGuard)
export class ObstetricsController {
  constructor(private readonly obService: ObstetricsService) {}

  @Post('pregnancies')
  createPregnancy(
    @CurrentUser('id') patientId: string,
    @Body() body: { dueDate: string; lmpDate: string },
  ) {
    return this.obService.createPregnancy(patientId, body);
  }

  @Get('pregnancies/active')
  getActivePregnancy(@CurrentUser('id') patientId: string) {
    return this.obService.getActivePregnancy(patientId);
  }

  @Get('pregnancies/:id/week')
  async getCurrentWeek(@Param('id', ParseUUIDPipe) id: string) {
    const pregnancy = await this.obService['findPregnancy'](id);
    return { week: this.obService.getCurrentWeek(pregnancy) };
  }

  @Post('pregnancies/:id/checkups')
  addCheckup(
    @Param('id', ParseUUIDPipe) pregnancyId: string,
    @Body() body: {
      week: number;
      type: string;
      results: Record<string, unknown>;
      ultrasoundUrl?: string;
      checkedAt: string;
    },
  ) {
    return this.obService.addCheckup(pregnancyId, {
      ...body,
      checkedAt: new Date(body.checkedAt),
    });
  }

  @Get('pregnancies/:id/checkups')
  getCheckups(@Param('id', ParseUUIDPipe) pregnancyId: string) {
    return this.obService.getCheckups(pregnancyId);
  }

  @Get('pregnancies/:id/checkup-schedule')
  getCheckupSchedule(@Param('id', ParseUUIDPipe) pregnancyId: string) {
    return this.obService.getCheckupSchedule(pregnancyId);
  }

  @Post('pregnancies/:id/fetal-movements')
  addFetalMovement(
    @Param('id', ParseUUIDPipe) pregnancyId: string,
    @Body() body: { count: number; durationMin: number; loggedAt: string },
  ) {
    return this.obService.addFetalMovement(pregnancyId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @Get('pregnancies/:id/fetal-movements')
  getFetalMovements(
    @Param('id', ParseUUIDPipe) pregnancyId: string,
    @Query('date') date?: string,
  ) {
    return this.obService.getFetalMovements(pregnancyId, date);
  }

  @Post('pregnancies/:id/maternal-logs')
  addMaternalLog(
    @Param('id', ParseUUIDPipe) pregnancyId: string,
    @Body() body: {
      weight: number;
      bloodPressureSys: number;
      bloodPressureDia: number;
      edemaLevel: EdemaLevel;
      note?: string;
      loggedAt: string;
    },
  ) {
    return this.obService.addMaternalLog(pregnancyId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @Get('pregnancies/:id/maternal-logs')
  getMaternalLogs(@Param('id', ParseUUIDPipe) pregnancyId: string) {
    return this.obService.getMaternalLogs(pregnancyId);
  }

  @Get('pregnancies/:id/maternal-trend')
  getMaternalTrend(@Param('id', ParseUUIDPipe) pregnancyId: string) {
    return this.obService.getMaternalTrend(pregnancyId);
  }
}
