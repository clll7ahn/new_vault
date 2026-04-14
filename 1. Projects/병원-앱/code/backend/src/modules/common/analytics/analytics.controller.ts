import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';

@Controller('api/v1/analytics')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('admin')
export class AnalyticsController {
  constructor(private readonly analyticsService: AnalyticsService) {}

  @Get('dashboard')
  getDashboard() {
    return this.analyticsService.getDashboardInsights();
  }

  @Get('no-show-risk')
  getNoShowRisk(@Query('appointmentId') appointmentId: string) {
    return this.analyticsService.predictNoShow(appointmentId);
  }

  @Get('peak-times')
  getPeakTimes(
    @Query('doctorId') doctorId: string,
    @Query('period') period: 'week' | 'month' | 'quarter' = 'month',
  ) {
    return this.analyticsService.getPeakTimeAnalysis(doctorId, period);
  }

  @Get('churn-risk')
  getChurnRisk() {
    return this.analyticsService.getPatientChurnRisk();
  }

  @Get('revenue')
  getRevenue(@Query('period') period: 'week' | 'month' | 'quarter' = 'month') {
    return this.analyticsService.getRevenueMetrics(period);
  }
}
