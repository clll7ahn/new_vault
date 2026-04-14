import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { HealthTrackerService } from './health-tracker.service';
import { CreateHealthRecordDto } from './dto/create-health-record.dto';
import { SyncHealthDataDto } from './dto/sync-health-data.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { HealthRecordType } from './entities/health-record.entity';

@Controller('api/v1/health')
@UseGuards(JwtAuthGuard)
export class HealthTrackerController {
  constructor(private readonly healthTrackerService: HealthTrackerService) {}

  @Post('records')
  addRecord(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateHealthRecordDto,
  ) {
    return this.healthTrackerService.addRecord(userId, dto);
  }

  @Post('sync')
  syncBulk(
    @CurrentUser('id') userId: string,
    @Body() dto: SyncHealthDataDto,
  ) {
    return this.healthTrackerService.syncBulk(userId, dto);
  }

  @Get('records')
  getRecords(
    @CurrentUser('id') userId: string,
    @Query('type') type?: HealthRecordType,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.healthTrackerService.getRecords(userId, type, from, to);
  }

  @Get('summary/daily')
  getDailySummary(
    @CurrentUser('id') userId: string,
    @Query('date') date?: string,
  ) {
    const targetDate = date ?? new Date().toISOString().split('T')[0];
    return this.healthTrackerService.getDailySummary(userId, targetDate);
  }

  @Get('summary/weekly')
  getWeeklySummary(@CurrentUser('id') userId: string) {
    return this.healthTrackerService.getWeeklySummary(userId);
  }

  @Get('snapshot')
  getHealthSnapshot(@CurrentUser('id') userId: string) {
    return this.healthTrackerService.getHealthSnapshot(userId);
  }
}
