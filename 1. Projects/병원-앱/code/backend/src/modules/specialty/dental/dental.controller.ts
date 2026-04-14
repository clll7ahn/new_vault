import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  ParseIntPipe,
} from '@nestjs/common';
import { DentalService } from './dental.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/specialty/dental')
@UseGuards(JwtAuthGuard)
export class DentalController {
  constructor(private readonly dentalService: DentalService) {}

  @Get('tooth-chart')
  getToothChart(@CurrentUser('id') patientId: string) {
    return this.dentalService.getToothChart(patientId);
  }

  @Patch('tooth-chart/:toothNumber')
  updateTooth(
    @CurrentUser('id') patientId: string,
    @Param('toothNumber', ParseIntPipe) toothNumber: number,
    @Body() body: {
      status: 'healthy' | 'cavity' | 'treated' | 'extracted' | 'implant';
      conditions?: Record<string, unknown>;
    },
  ) {
    return this.dentalService.updateTooth(patientId, toothNumber, body);
  }

  @Post('treatments')
  addTreatment(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      toothNumber: number;
      treatmentType: string;
      planStep?: number;
      status?: 'planned' | 'in_progress' | 'completed';
      treatedAt?: string;
      nextDate?: string;
    },
  ) {
    return this.dentalService.addTreatment(patientId, {
      ...body,
      treatedAt: body.treatedAt ? new Date(body.treatedAt) : undefined,
    });
  }

  @Get('treatments')
  getTreatments(@CurrentUser('id') patientId: string) {
    return this.dentalService.getTreatments(patientId);
  }

  @Get('treatments/plan')
  getTreatmentPlan(@CurrentUser('id') patientId: string) {
    return this.dentalService.getTreatmentPlan(patientId);
  }

  @Get('next-checkup')
  getNextCheckupDate(@CurrentUser('id') patientId: string) {
    return this.dentalService.getNextCheckupDate(patientId);
  }

  @Get('treatments/history')
  getTreatmentHistory(@CurrentUser('id') patientId: string) {
    return this.dentalService.getTreatments(patientId);
  }
}
