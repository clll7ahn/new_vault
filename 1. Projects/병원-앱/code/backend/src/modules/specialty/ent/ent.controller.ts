import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { EntService } from './ent.service';
import { EntSymptomType } from './entities/ent-symptom-log.entity';
import { AllergySeverity } from './entities/ent-allergy-record.entity';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/specialty/ent')
@UseGuards(JwtAuthGuard)
export class EntController {
  constructor(private readonly entService: EntService) {}

  @Post('symptoms')
  addSymptomLog(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      symptomType: EntSymptomType;
      severity: number;
      note?: string;
      loggedAt: string;
    },
  ) {
    return this.entService.addSymptomLog(patientId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @Get('symptoms')
  getSymptomLogs(
    @CurrentUser('id') patientId: string,
    @Query('symptomType') symptomType?: EntSymptomType,
  ) {
    return this.entService.getSymptomLogs(patientId, symptomType);
  }

  @Get('symptoms/trend')
  getSymptomTrend(
    @CurrentUser('id') patientId: string,
    @Query('symptomType') symptomType: EntSymptomType,
  ) {
    return this.entService.getSymptomTrend(patientId, symptomType);
  }

  @Post('allergies')
  addAllergyRecord(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      allergen: string;
      reactionType: string;
      severity: AllergySeverity;
      diagnosedAt: string;
      isActive?: boolean;
    },
  ) {
    return this.entService.addAllergyRecord(patientId, body);
  }

  @Get('allergies')
  getAllergies(
    @CurrentUser('id') patientId: string,
    @Query('activeOnly') activeOnly?: string,
  ) {
    return this.entService.getAllergies(patientId, activeOnly === 'true');
  }

  @Get('allergies/seasonal-alert')
  getSeasonalAlert(@Query('month') month?: string) {
    const m = month ? parseInt(month, 10) : new Date().getMonth() + 1;
    return this.entService.getSeasonalAlert(m);
  }

  @Get('health')
  health() {
    return { status: 'ok', module: 'ent' };
  }
}
