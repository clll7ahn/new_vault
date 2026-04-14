import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { OrthoPainLog } from './entities/ortho-pain-log.entity';
import { OrthoRehabProgram, RehabExercise } from './entities/ortho-rehab-program.entity';
import { OrthoExerciseLog } from './entities/ortho-exercise-log.entity';

@Injectable()
export class OrthopedicsService {
  constructor(
    @InjectRepository(OrthoPainLog)
    private readonly painLogRepo: Repository<OrthoPainLog>,
    @InjectRepository(OrthoRehabProgram)
    private readonly rehabRepo: Repository<OrthoRehabProgram>,
    @InjectRepository(OrthoExerciseLog)
    private readonly exerciseLogRepo: Repository<OrthoExerciseLog>,
  ) {}

  async addPainLog(patientId: string, dto: {
    bodyPart: string;
    intensity: number;
    painType: string;
    note?: string;
    loggedAt: Date;
  }): Promise<OrthoPainLog> {
    const log = this.painLogRepo.create({
      patientId,
      bodyPart: dto.bodyPart,
      intensity: dto.intensity,
      painType: dto.painType,
      note: dto.note ?? null,
      loggedAt: dto.loggedAt,
    });
    return this.painLogRepo.save(log);
  }

  async getPainLogs(patientId: string, from: string, to: string): Promise<OrthoPainLog[]> {
    return this.painLogRepo.find({
      where: {
        patientId,
        loggedAt: Between(new Date(from), new Date(to)),
      },
      order: { loggedAt: 'DESC' },
    });
  }

  async getPainTrend(
    patientId: string,
    bodyPart: string,
  ): Promise<{ loggedAt: Date; intensity: number; painType: string }[]> {
    const logs = await this.painLogRepo.find({
      where: { patientId, bodyPart },
      order: { loggedAt: 'ASC' },
      select: ['loggedAt', 'intensity', 'painType'],
    });
    return logs.map((l) => ({
      loggedAt: l.loggedAt,
      intensity: l.intensity,
      painType: l.painType,
    }));
  }

  async createRehabProgram(dto: {
    patientId: string;
    doctorId: string;
    title: string;
    exercises: RehabExercise[];
    startDate: string;
    endDate?: string;
  }): Promise<OrthoRehabProgram> {
    const program = this.rehabRepo.create({
      patientId: dto.patientId,
      doctorId: dto.doctorId,
      title: dto.title,
      exercises: dto.exercises,
      startDate: dto.startDate,
      endDate: dto.endDate ?? null,
    });
    return this.rehabRepo.save(program);
  }

  async getActivePrograms(patientId: string): Promise<OrthoRehabProgram[]> {
    return this.rehabRepo.find({
      where: { patientId, isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  async logExercise(programId: string, dto: {
    exerciseName: string;
    completed: boolean;
    loggedAt: Date;
  }): Promise<OrthoExerciseLog> {
    const program = await this.rehabRepo.findOne({ where: { id: programId } });
    if (!program) throw new NotFoundException('재활 프로그램을 찾을 수 없습니다.');

    const log = this.exerciseLogRepo.create({
      programId,
      exerciseName: dto.exerciseName,
      completed: dto.completed,
      loggedAt: dto.loggedAt,
    });
    return this.exerciseLogRepo.save(log);
  }

  async getExerciseLogs(programId: string): Promise<OrthoExerciseLog[]> {
    return this.exerciseLogRepo.find({
      where: { programId },
      order: { loggedAt: 'DESC' },
    });
  }

  async getRehabAdherence(programId: string): Promise<{ adherenceRate: number; completed: number; total: number }> {
    const logs = await this.exerciseLogRepo.find({ where: { programId } });
    const total = logs.length;
    const completed = logs.filter((l) => l.completed).length;
    const adherenceRate = total === 0 ? 0 : Math.round((completed / total) * 100);
    return { adherenceRate, completed, total };
  }
}
