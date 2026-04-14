import {
  Controller,
  Get,
  Post,
  Delete,
  Patch,
  Body,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AppointmentService } from './appointment.service';
import { NoShowGuardService } from './no-show-guard.service';
import { CreateAppointmentDto } from './dto/create-appointment.dto';
import { UpdateStatusDto } from './dto/update-status.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@ApiTags('appointments')
@Controller('api/v1/appointments')
@UseGuards(JwtAuthGuard)
export class AppointmentController {
  constructor(
    private readonly appointmentService: AppointmentService,
    private readonly noShowGuardService: NoShowGuardService,
  ) {}

  @Get('slots')
  getAvailableSlots(
    @Query('doctorId') doctorId: string,
    @Query('date') date: string,
  ) {
    return this.appointmentService.getAvailableSlots(doctorId, date);
  }

  /**
   * GET /api/v1/appointments/no-show-risk
   * 오늘 예약 중 Stage 3 알림 미확인(노쇼 위험) 예약 목록 (admin 전용)
   * NOTE: 반드시 `:id` 파라미터 라우트보다 먼저 선언해야 충돌 없음.
   */
  @Get('no-show-risk')
  @UseGuards(RolesGuard)
  @Roles('admin')
  @ApiOperation({ summary: '노쇼 위험 예약 목록 조회 (관리자)' })
  @ApiResponse({ status: 200, description: '오늘 날짜 기준 Stage 3 미확인 예약 목록 반환' })
  getNoShowRiskAppointments() {
    return this.noShowGuardService.getNoShowRiskAppointments();
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('patient')
  async createAppointment(
    @CurrentUser('id') patientId: string,
    @Body() dto: CreateAppointmentDto,
  ) {
    const appointment = await this.appointmentService.createAppointment(patientId, dto);
    // 예약 생성 직후 3단계 노쇼 방어 알림 스케줄링 (실패해도 예약은 유지)
    await this.noShowGuardService.scheduleReminders(appointment.id).catch(() => undefined);
    return appointment;
  }

  @Get()
  getMyAppointments(
    @CurrentUser('id') userId: string,
    @CurrentUser('role') role: string,
  ) {
    return this.appointmentService.getMyAppointments(userId, role);
  }

  @Get(':id')
  getAppointment(@Param('id', ParseUUIDPipe) id: string) {
    return this.appointmentService.getAppointment(id);
  }

  @Delete(':id')
  @UseGuards(RolesGuard)
  @Roles('patient')
  cancelAppointment(
    @Param('id', ParseUUIDPipe) id: string,
    @CurrentUser('id') userId: string,
  ) {
    return this.appointmentService.cancelAppointment(id, userId);
  }

  @Patch(':id/status')
  @UseGuards(RolesGuard)
  @Roles('doctor', 'admin')
  updateStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateStatusDto,
  ) {
    return this.appointmentService.updateStatus(id, dto);
  }

  /**
   * POST /api/v1/appointments/:id/confirm
   * 환자가 "참석 확인" 버튼을 누를 때 호출.
   * SENT 상태 리마인더를 CONFIRMED 처리한다.
   */
  @Post(':id/confirm')
  @UseGuards(RolesGuard)
  @Roles('patient')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: '예약 참석 확인 (환자)' })
  @ApiResponse({ status: 200, description: '참석 확인 완료' })
  confirmAttendance(@Param('id', ParseUUIDPipe) id: string) {
    return this.noShowGuardService.confirmAttendance(id);
  }
}
