import {
  Controller,
  Get,
  Patch,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
} from '@nestjs/common';
import { HospitalInfoService } from './hospital-info.service';
import { UpdateHospitalDto } from './dto/update-hospital.dto';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { CreateDoctorDto } from './dto/create-doctor.dto';
import { JwtAuthGuard } from '../../../common/guards/jwt-auth.guard';
import { RolesGuard } from '../../../common/guards/roles.guard';
import { Roles } from '../../../common/decorators/roles.decorator';

@Controller('api/v1/hospitals')
export class HospitalInfoController {
  constructor(private readonly hospitalInfoService: HospitalInfoService) {}

  @Get('info')
  getHospitalInfo() {
    return this.hospitalInfoService.getHospitalInfo();
  }

  @Patch('info')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  updateHospitalInfo(@Body() dto: UpdateHospitalDto) {
    return this.hospitalInfoService.updateHospitalInfo(dto);
  }

  @Get('departments')
  getDepartments() {
    return this.hospitalInfoService.getDepartments();
  }

  @Post('departments')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  createDepartment(@Body() dto: CreateDepartmentDto) {
    return this.hospitalInfoService.createDepartment(dto);
  }

  @Get('doctors')
  getDoctors(@Query('departmentId') departmentId?: string) {
    return this.hospitalInfoService.getDoctors(departmentId);
  }

  @Get('doctors/:id')
  getDoctor(@Param('id', ParseUUIDPipe) id: string) {
    return this.hospitalInfoService.getDoctor(id);
  }

  @Post('doctors')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('admin')
  createDoctor(@Body() dto: CreateDoctorDto) {
    return this.hospitalInfoService.createDoctor(dto);
  }
}
