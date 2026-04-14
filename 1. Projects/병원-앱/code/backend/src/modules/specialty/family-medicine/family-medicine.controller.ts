import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { FamilyMedicineService } from './family-medicine.service';
import { RiskLevel } from './entities/fm-checkup-result.entity';
import { LifestyleType } from './entities/fm-lifestyle-log.entity';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/specialty/family-medicine')
@UseGuards(JwtAuthGuard)
export class FamilyMedicineController {
  constructor(private readonly fmService: FamilyMedicineService) {}

  @Post('checkups')
  addCheckupResult(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      checkupDate: string;
      results: Record<string, unknown>;
      summary: string;
      riskLevel: RiskLevel;
    },
  ) {
    return this.fmService.addCheckupResult(patientId, body);
  }

  @Get('checkups')
  getCheckupResults(@CurrentUser('id') patientId: string) {
    return this.fmService.getCheckupResults(patientId);
  }

  @Get('checkups/latest')
  getLatestCheckup(@CurrentUser('id') patientId: string) {
    return this.fmService.getLatestCheckup(patientId);
  }

  @Post('lifestyle')
  addLifestyleLog(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      type: LifestyleType;
      value: Record<string, unknown>;
      loggedAt: string;
    },
  ) {
    return this.fmService.addLifestyleLog(patientId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @Get('lifestyle')
  getLifestyleLogs(
    @CurrentUser('id') patientId: string,
    @Query('type') type?: LifestyleType,
  ) {
    return this.fmService.getLifestyleLogs(patientId, type);
  }

  @Get('lifestyle/trend')
  getLifestyleTrend(
    @CurrentUser('id') patientId: string,
    @Query('type') type: LifestyleType,
  ) {
    return this.fmService.getLifestyleTrend(patientId, type);
  }

  @Get('bmi-history')
  getBMIHistory(@CurrentUser('id') patientId: string) {
    return this.fmService.getBMIHistory(patientId);
  }

  @Get('health')
  health() {
    return { status: 'ok', module: 'family-medicine' };
  }
}
