import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { PediatricsService } from './pediatrics.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@Controller('api/v1/specialty/pediatrics')
@UseGuards(JwtAuthGuard)
export class PediatricsController {
  constructor(private readonly pedService: PediatricsService) {}

  @Post('children')
  addChild(
    @CurrentUser('id') parentId: string,
    @Body() body: {
      name: string;
      birthDate: string;
      gender: 'male' | 'female';
      bloodType?: string;
    },
  ) {
    return this.pedService.addChild(parentId, body);
  }

  @Get('children')
  getChildren(@CurrentUser('id') parentId: string) {
    return this.pedService.getChildren(parentId);
  }

  @Get('children/:id')
  getChild(@Param('id', ParseUUIDPipe) id: string) {
    return this.pedService.getChild(id);
  }

  @Post('children/:childId/growth')
  addGrowthLog(
    @Param('childId', ParseUUIDPipe) childId: string,
    @Body() body: {
      height: number;
      weight: number;
      headCirc?: number;
      measuredAt: string;
    },
  ) {
    return this.pedService.addGrowthLog(childId, {
      ...body,
      measuredAt: new Date(body.measuredAt),
    });
  }

  @Get('children/:childId/growth')
  getGrowthLogs(@Param('childId', ParseUUIDPipe) childId: string) {
    return this.pedService.getGrowthLogs(childId);
  }

  @Get('children/:childId/growth/chart')
  getGrowthChart(@Param('childId', ParseUUIDPipe) childId: string) {
    return this.pedService.getGrowthChart(childId);
  }

  @Get('children/:childId/vaccinations')
  getVaccinations(@Param('childId', ParseUUIDPipe) childId: string) {
    return this.pedService.getVaccinations(childId);
  }

  @Patch('vaccinations/:id')
  updateVaccination(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() body: { actualDate: string },
  ) {
    return this.pedService.updateVaccination(id, body.actualDate);
  }

  @Get('children/:childId/vaccinations/overdue')
  getOverdueVaccinations(@Param('childId', ParseUUIDPipe) childId: string) {
    return this.pedService.getOverdueVaccinations(childId);
  }
}
