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
import { OphthalmologyService } from './ophthalmology.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/specialty/ophthalmology')
@UseGuards(JwtAuthGuard)
export class OphthalmologyController {
  constructor(private readonly ophService: OphthalmologyService) {}

  @Post('vision-logs')
  addVisionLog(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      eye: 'left' | 'right' | 'both';
      vision: number;
      iop?: number;
      measuredAt: string;
    },
  ) {
    return this.ophService.addVisionLog(patientId, {
      ...body,
      measuredAt: new Date(body.measuredAt),
    });
  }

  @Get('vision-logs')
  getVisionLogs(@CurrentUser('id') patientId: string) {
    return this.ophService.getVisionLogs(patientId);
  }

  @Get('vision-logs/trend')
  getVisionTrend(
    @CurrentUser('id') patientId: string,
    @Query('eye') eye: 'left' | 'right' | 'both',
  ) {
    return this.ophService.getVisionTrend(patientId, eye);
  }

  @Post('prescriptions')
  addPrescription(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      type: 'glasses' | 'contact_lens';
      sphLeft: number;
      sphRight: number;
      cylLeft?: number;
      cylRight?: number;
      prescribedAt: string;
      nextReplace?: string;
    },
  ) {
    return this.ophService.addPrescription(patientId, {
      ...body,
      prescribedAt: new Date(body.prescribedAt),
    });
  }

  @Get('prescriptions')
  getPrescriptions(@CurrentUser('id') patientId: string) {
    return this.ophService.getPrescriptions(patientId);
  }

  @Get('prescriptions/expiring')
  getExpiringPrescriptions(@CurrentUser('id') patientId: string) {
    return this.ophService.getExpiringPrescriptions(patientId);
  }

  @Post('eye-drops')
  addEyeDrop(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      name: string;
      frequency: string;
      startDate: string;
      endDate?: string;
    },
  ) {
    return this.ophService.addEyeDrop(patientId, body);
  }

  @Get('eye-drops/active')
  getActiveEyeDrops(
    @CurrentUser('id') patientId: string,
    @Param('id') _id?: string,
  ) {
    return this.ophService.getActiveEyeDrops(patientId);
  }
}
