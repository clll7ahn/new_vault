import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { UrologyService } from './urology.service';
import { VoidType } from './entities/uro-voiding-log.entity';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/specialty/urology')
@UseGuards(JwtAuthGuard)
export class UrologyController {
  constructor(private readonly urologyService: UrologyService) {}

  @Post('voiding')
  addVoidingLog(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      voidType: VoidType;
      volumeMl?: number;
      loggedAt: string;
    },
  ) {
    return this.urologyService.addVoidingLog(patientId, {
      ...body,
      loggedAt: new Date(body.loggedAt),
    });
  }

  @Get('voiding')
  getVoidingLogs(
    @CurrentUser('id') patientId: string,
    @Query('voidType') voidType?: VoidType,
  ) {
    return this.urologyService.getVoidingLogs(patientId, voidType);
  }

  @Get('voiding/pattern')
  getVoidingPattern(@CurrentUser('id') patientId: string) {
    return this.urologyService.getVoidingPattern(patientId);
  }

  @Post('psa')
  addPSARecord(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      psaValue: number;
      testedAt: string;
      note?: string;
    },
  ) {
    return this.urologyService.addPSARecord(patientId, body);
  }

  @Get('psa')
  getPSARecords(@CurrentUser('id') patientId: string) {
    return this.urologyService.getPSARecords(patientId);
  }

  @Get('psa/trend')
  getPSATrend(@CurrentUser('id') patientId: string) {
    return this.urologyService.getPSATrend(patientId);
  }

  @Get('health')
  health() {
    return { status: 'ok', module: 'urology' };
  }
}
