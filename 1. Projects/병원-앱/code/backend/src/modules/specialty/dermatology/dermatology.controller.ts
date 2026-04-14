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
import { DermatologyService } from './dermatology.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/specialty/dermatology')
@UseGuards(JwtAuthGuard)
export class DermatologyController {
  constructor(private readonly dermService: DermatologyService) {}

  @Post('photos')
  addSkinPhoto(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      bodyArea: string;
      imageUrl: string;
      aiResult?: Record<string, unknown>;
      score?: number;
      takenAt: string;
    },
  ) {
    return this.dermService.addSkinPhoto(patientId, {
      ...body,
      takenAt: new Date(body.takenAt),
    });
  }

  @Get('photos')
  getSkinPhotos(
    @CurrentUser('id') patientId: string,
    @Query('bodyArea') bodyArea?: string,
  ) {
    return this.dermService.getSkinPhotos(patientId, bodyArea);
  }

  @Get('photos/timeline')
  getSkinTimeline(@CurrentUser('id') patientId: string) {
    return this.dermService.getSkinTimeline(patientId);
  }

  @Post('treatments')
  addTreatment(
    @CurrentUser('id') patientId: string,
    @Body() body: {
      doctorId: string;
      type: string;
      description: string;
      cost?: number;
      treatedAt: string;
      nextDate?: string;
    },
  ) {
    return this.dermService.addTreatment(patientId, {
      ...body,
      treatedAt: new Date(body.treatedAt),
    });
  }

  @Get('treatments')
  getTreatments(@CurrentUser('id') patientId: string) {
    return this.dermService.getTreatments(patientId);
  }

  @Get('before-after')
  getBeforeAfter(
    @CurrentUser('id') patientId: string,
    @Query('bodyArea') bodyArea: string,
  ) {
    return this.dermService.getBeforeAfter(patientId, bodyArea);
  }

  @Get('photos/:id')
  getSkinPhotoById(@Param('id', ParseUUIDPipe) id: string) {
    return { id };
  }
}
