import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { KoreanMedicineService } from './korean-medicine.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { KmConstitutionType } from './entities/km-constitution.entity';
import { KmTreatmentType } from './entities/km-treatment-record.entity';

@Controller('api/v1/specialty/korean-medicine')
@UseGuards(JwtAuthGuard)
export class KoreanMedicineController {
  constructor(private readonly service: KoreanMedicineService) {}

  @Post('constitution')
  setConstitution(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      doctorId: string;
      constitutionType: KmConstitutionType;
      diagnosisNote: string;
      diagnosedAt: string;
    },
  ) {
    return this.service.setConstitution(patientId, {
      ...body,
      diagnosedAt: new Date(body.diagnosedAt),
    });
  }

  @Get('constitution')
  getConstitution(@CurrentUser('id') patientId: string) {
    return this.service.getConstitution(patientId);
  }

  @Post('treatments')
  addTreatmentRecord(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      doctorId: string;
      treatmentType: KmTreatmentType;
      bodyPoints?: string[];
      prescription?: string;
      note?: string;
      treatedAt: string;
    },
  ) {
    return this.service.addTreatmentRecord(patientId, {
      ...body,
      treatedAt: new Date(body.treatedAt),
    });
  }

  @Get('treatments')
  getTreatmentRecords(@CurrentUser('id') patientId: string) {
    return this.service.getTreatmentRecords(patientId);
  }

  @Get('treatments/history')
  getTreatmentHistory(
    @CurrentUser('id') patientId: string,
    @Query('type') treatmentType: KmTreatmentType,
  ) {
    return this.service.getTreatmentHistory(patientId, treatmentType);
  }

  @Get('dietary-guide/:constitutionId')
  getDietaryGuide(@Param('constitutionId', ParseUUIDPipe) constitutionId: string) {
    return this.service.getDietaryGuide(constitutionId);
  }

  @Put('dietary-guide/:constitutionId')
  setDietaryGuide(
    @Param('constitutionId', ParseUUIDPipe) constitutionId: string,
    @Body() body: {
      recommendedFoods: string[];
      avoidedFoods: string[];
      lifestyleTips: string[];
    },
  ) {
    return this.service.setDietaryGuide(constitutionId, body);
  }
}
