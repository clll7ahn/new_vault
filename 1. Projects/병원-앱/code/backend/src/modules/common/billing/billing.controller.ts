import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { BillingService } from './billing.service';
import { CreateBillingDto } from './dto/create-billing.dto';
import { ProcessPaymentDto } from './dto/process-payment.dto';
import { BillingStatus } from './entities/billing.entity';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@ApiTags('billings')
@Controller('api/v1/billings')
@UseGuards(JwtAuthGuard)
export class BillingController {
  constructor(private readonly billingService: BillingService) {}

  // GET /api/v1/billings — 내 청구 목록 (인증 필요)
  @Get()
  getMyBillings(
    @CurrentUser('id') patientId: string,
    @Query('status') status?: BillingStatus,
  ) {
    return this.billingService.getMyBillings(patientId, status);
  }

  // POST /api/v1/billings — 청구서 생성 (admin 전용)
  @Post()
  @UseGuards(RolesGuard)
  @Roles('admin')
  createBilling(@Body() dto: CreateBillingDto) {
    return this.billingService.createBilling(dto);
  }

  // GET /api/v1/billings/unpaid — 미납 청구 목록 (인증 필요)
  @Get('unpaid')
  getUnpaidBillings(@CurrentUser('id') patientId: string) {
    return this.billingService.getUnpaidBillings(patientId);
  }

  // GET /api/v1/billings/stats — 기간별 결제 통계 (admin 전용)
  @Get('stats')
  @UseGuards(RolesGuard)
  @Roles('admin')
  getTotalStats(@Query('period') period?: 'week' | 'month' | 'quarter') {
    return this.billingService.getTotalStats(period ?? 'month');
  }

  // GET /api/v1/billings/:id — 단일 청구서 조회 (인증 필요)
  @Get(':id')
  getBilling(@Param('id', ParseUUIDPipe) id: string) {
    return this.billingService.getBilling(id);
  }

  // PATCH /api/v1/billings/:id/pay — 결제 처리 (인증 필요)
  @Patch(':id/pay')
  processPayment(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ProcessPaymentDto,
  ) {
    return this.billingService.processPayment(id, dto);
  }
}
