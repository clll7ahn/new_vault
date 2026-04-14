import {
  Controller,
  Post,
  Get,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { QueueService } from './queue.service';
import { CreateQueueDto } from './dto/create-queue.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';

@ApiTags('queue')
@Controller('api/v1/queue')
export class QueueController {
  constructor(private readonly queueService: QueueService) {}

  @Post('check-in')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('patient')
  checkIn(@Body() dto: CreateQueueDto) {
    return this.queueService.checkIn(dto);
  }

  @Get('current')
  getCurrentQueue(@Query('doctorId') doctorId: string) {
    return this.queueService.getCurrentQueue(doctorId);
  }

  @Get('my-status')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('patient')
  getMyQueueStatus(@CurrentUser('id') patientId: string) {
    return this.queueService.getMyQueueStatus(patientId);
  }

  @Get('estimate')
  getEstimatedWait(@Query('doctorId') doctorId: string) {
    return this.queueService.getEstimatedWait(doctorId);
  }

  @Get('stats')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('doctor', 'admin')
  getTodayStats(@Query('doctorId') doctorId: string) {
    return this.queueService.getTodayStats(doctorId);
  }

  @Patch(':id/call')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('doctor', 'admin')
  callNext(@Param('id', ParseUUIDPipe) id: string) {
    return this.queueService.callNext(id);
  }

  @Patch(':id/complete')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('doctor', 'admin')
  completeCurrent(@Param('id', ParseUUIDPipe) id: string) {
    return this.queueService.completeCurrent(id);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('patient')
  cancelEntry(@Param('id', ParseUUIDPipe) id: string) {
    return this.queueService.cancelEntry(id);
  }
}
