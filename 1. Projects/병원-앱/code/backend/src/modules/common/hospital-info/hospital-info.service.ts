import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Hospital } from './entities/hospital.entity';
import { Department } from './entities/department.entity';
import { Doctor } from './entities/doctor.entity';
import { CreateHospitalDto } from './dto/create-hospital.dto';
import { UpdateHospitalDto } from './dto/update-hospital.dto';
import { CreateDepartmentDto } from './dto/create-department.dto';
import { CreateDoctorDto } from './dto/create-doctor.dto';

@Injectable()
export class HospitalInfoService {
  constructor(
    @InjectRepository(Hospital)
    private readonly hospitalRepo: Repository<Hospital>,
    @InjectRepository(Department)
    private readonly departmentRepo: Repository<Department>,
    @InjectRepository(Doctor)
    private readonly doctorRepo: Repository<Doctor>,
  ) {}

  async getHospitalInfo(): Promise<Hospital> {
    const hospitals = await this.hospitalRepo.find({ take: 1 });
    if (hospitals.length === 0) {
      throw new NotFoundException('hospital info not found');
    }
    return hospitals[0];
  }

  async updateHospitalInfo(dto: UpdateHospitalDto): Promise<Hospital> {
    const hospitals = await this.hospitalRepo.find({ take: 1 });
    if (hospitals.length === 0) {
      throw new NotFoundException('hospital info not found');
    }
    const hospital = hospitals[0];
    Object.assign(hospital, dto);
    return this.hospitalRepo.save(hospital);
  }

  async createHospitalInfo(dto: CreateHospitalDto): Promise<Hospital> {
    const hospital = this.hospitalRepo.create(dto);
    return this.hospitalRepo.save(hospital);
  }

  async getDepartments(): Promise<Department[]> {
    return this.departmentRepo.find({
      where: { isActive: true },
      order: { displayOrder: 'ASC', name: 'ASC' },
    });
  }

  async getDepartment(id: string): Promise<Department> {
    const department = await this.departmentRepo.findOne({ where: { id } });
    if (!department) {
      throw new NotFoundException(`department ${id} not found`);
    }
    return department;
  }

  async createDepartment(dto: CreateDepartmentDto): Promise<Department> {
    const hospitals = await this.hospitalRepo.find({ take: 1 });
    if (hospitals.length === 0) {
      throw new BadRequestException('hospital info must be created first');
    }
    const department = this.departmentRepo.create({
      ...dto,
      hospitalId: hospitals[0].id,
    });
    return this.departmentRepo.save(department);
  }

  async getDoctors(departmentId?: string): Promise<Doctor[]> {
    const where: Record<string, unknown> = {};
    if (departmentId) {
      where.departmentId = departmentId;
    }
    return this.doctorRepo.find({
      where,
      relations: ['department'],
      order: { displayOrder: 'ASC', name: 'ASC' },
    });
  }

  async getDoctor(id: string): Promise<Doctor> {
    const doctor = await this.doctorRepo.findOne({
      where: { id },
      relations: ['department'],
    });
    if (!doctor) {
      throw new NotFoundException(`doctor ${id} not found`);
    }
    return doctor;
  }

  async createDoctor(dto: CreateDoctorDto): Promise<Doctor> {
    await this.getDepartment(dto.departmentId);
    const doctor = this.doctorRepo.create(dto);
    return this.doctorRepo.save(doctor);
  }
}
