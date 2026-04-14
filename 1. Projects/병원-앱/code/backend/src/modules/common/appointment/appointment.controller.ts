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
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { AppointmentService } from './appointment.service';
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
  constructor(private readonly appointmentService: AppointmentService) {}

  @Get('slots')
  getAvailableSlots(
    @Query('doctorId') doctorId: string,
    @Query('date') date: string,
  ) {
    return this.appointmentService.getAvailableSlots(doctorId, date);
  }

  @Post()
  @UseGuards(RolesGuard)
  @Roles('patient')
  createAppointment(
    @CurrentUser('id') patientId: string,
    @Body() dto: CreateAppointmentDto,
  ) {
    return this.appointmentService.createAppointment(patientId, dto);
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
}
