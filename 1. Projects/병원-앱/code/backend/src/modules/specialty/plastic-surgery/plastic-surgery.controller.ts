import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { PlasticSurgeryService } from './plastic-surgery.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { PsPhotoType } from './entities/ps-photo-record.entity';
import { PsProcedureStatus } from './entities/ps-procedure.entity';

@Controller('api/v1/specialty/plastic-surgery')
@UseGuards(JwtAuthGuard)
export class PlasticSurgeryController {
  constructor(private readonly service: PlasticSurgeryService) {}

  @Post('procedures')
  addProcedure(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      doctorId: string;
      procedureType: string;
      description: string;
      cost?: number;
      procedureDate: string;
      recoveryDays?: number;
      status?: PsProcedureStatus;
    },
  ) {
    return this.service.addProcedure(patientId, {
      ...body,
      procedureDate: new Date(body.procedureDate),
    });
  }

  @Get('procedures')
  getProcedures(@CurrentUser('id') patientId: string) {
    return this.service.getProcedures(patientId);
  }

  @Post('procedures/:id/photos')
  addPhotoRecord(
    @Param('id', ParseUUIDPipe) procedureId: string,
    @Body() body: {
      photoType: PsPhotoType;
      imageUrl: string;
      takenAt: string;
      note?: string;
    },
  ) {
    return this.service.addPhotoRecord({
      procedureId,
      photoType: body.photoType,
      imageUrl: body.imageUrl,
      takenAt: new Date(body.takenAt),
      note: body.note,
    });
  }

  @Get('procedures/:id/photos')
  getPhotoRecords(@Param('id', ParseUUIDPipe) procedureId: string) {
    return this.service.getPhotoRecords(procedureId);
  }

  @Get('procedures/:id/before-after')
  getBeforeAfter(@Param('id', ParseUUIDPipe) procedureId: string) {
    return this.service.getBeforeAfter(procedureId);
  }

  @Post('procedures/:id/recovery-logs')
  addRecoveryLog(
    @Param('id', ParseUUIDPipe) procedureId: string,
    @Body() body: {
      dayNumber: number;
      swellingLevel: number;
      painLevel: number;
      note?: string;
      photoUrl?: string;
      loggedAt: string;
    },
  ) {
    return this.service.addRecoveryLog({
      procedureId,
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @Get('procedures/:id/recovery-logs')
  getRecoveryLogs(@Param('id', ParseUUIDPipe) procedureId: string) {
    return this.service.getRecoveryLogs(procedureId);
  }

  @Get('procedures/:id/recovery-progress')
  getRecoveryProgress(@Param('id', ParseUUIDPipe) procedureId: string) {
    return this.service.getRecoveryProgress(procedureId);
  }
}
