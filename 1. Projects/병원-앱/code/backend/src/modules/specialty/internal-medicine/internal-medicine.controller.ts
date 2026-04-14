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
import { InternalMedicineService } from './internal-medicine.service';
import { VitalType } from './entities/im-vitals.entity';
import { MedLogStatus } from './entities/im-med-log.entity';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/specialty/internal-medicine')
@UseGuards(JwtAuthGuard)
export class InternalMedicineController {
  constructor(private readonly imService: InternalMedicineService) {}

  @Post('vitals')
  addVitals(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      type: VitalType;
      value1: number;
      value2?: number;
      measuredAt: string;
      note?: string;
    },
  ) {
    return this.imService.addVitals(patientId, {
      ...body,
      measuredAt: new Date(body.measuredAt),
    });
  }

  @Get('vitals')
  getVitals(
    @CurrentUser('id') patientId: string,
    @Query('type') type?: VitalType,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.imService.getVitals(patientId, type, from, to);
  }

  @Get('vitals/trend')
  getVitalsTrend(
    @CurrentUser('id') patientId: string,
    @Query('type') type: VitalType,
  ) {
    return this.imService.getVitalsTrend(patientId, type);
  }

  @Post('medications')
  addMedication(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      name: string;
      dosage: string;
      frequency: string;
      startDate: string;
      endDate?: string;
    },
  ) {
    return this.imService.addMedication(patientId, body);
  }

  @Get('medications')
  getActiveMedications(@CurrentUser('id') patientId: string) {
    return this.imService.getActiveMedications(patientId);
  }

  @Post('medications/:id/log')
  logMedication(
    @Param('id', ParseUUIDPipe) medicationId: string,
    @Body() body: { status: MedLogStatus },
  ) {
    return this.imService.logMedication(medicationId, body.status);
  }

  @Get('med-logs')
  getMedLogs(
    @CurrentUser('id') patientId: string,
    @Query('from') from: string,
    @Query('to') to: string,
  ) {
    return this.imService.getMedLogs(patientId, from, to);
  }

  @Get('adherence')
  getMedAdherence(@CurrentUser('id') patientId: string) {
    return this.imService.getMedAdherence(patientId);
  }
}
