import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RehabAssessment, RehabAssessmentType } from './entities/rehab-assessment.entity';
import { RehabExerciseProgram, ExerciseItem } from './entities/rehab-exercise-program.entity';
import { RehabSessionLog, CompletedExercise } from './entities/rehab-session-log.entity';

@Injectable()
export class RehabilitationService {
  constructor(
    @InjectRepository(RehabAssessment)
    private readonly assessmentRepo: Repository<RehabAssessment>,
    @InjectRepository(RehabExerciseProgram)
    private readonly programRepo: Repository<RehabExerciseProgram>,
    @InjectRepository(RehabSessionLog)
    private readonly sessionRepo: Repository<RehabSessionLog>,
  ) {}

  async addAssessment(patientId: string, dto: {
    doctorId: string;
    assessmentType: RehabAssessmentType;
    bodyPart: string;
    score: number;
    maxScore: number;
    unit?: string;
    assessedAt: Date;
    note?: string;
  }): Promise<RehabAssessment> {
    const assessment = this.assessmentRepo.create({
      patientId,
      doctorId: dto.doctorId,
      assessmentType: dto.assessmentType,
      bodyPart: dto.bodyPart,
      score: dto.score,
      maxScore: dto.maxScore,
      unit: dto.unit ?? null,
      assessedAt: dto.assessedAt,
      note: dto.note ?? null,
    });
    return this.assessmentRepo.save(assessment);
  }

  async getAssessments(patientId: string, assessmentType?: RehabAssessmentType): Promise<RehabAssessment[]> {
    const where: Record<string, unknown> = { patientId };
    if (assessmentType) where.assessmentType = assessmentType;
    return this.assessmentRepo.find({ where, order: { assessedAt: 'DESC' } });
  }

  async getAssessmentTrend(patientId: string, bodyPart: string): Promise<{
    bodyPart: string;
    assessments: RehabAssessment[];
    trend: { date: Date; scorePercent: number }[];
  }> {
    const assessments = await this.assessmentRepo.find({
      where: { patientId, bodyPart },
      order: { assessedAt: 'ASC' },
    });
    const trend = assessments.map((a) => ({
      date: a.assessedAt,
      scorePercent: Number(a.maxScore) > 0
        ? Math.round((Number(a.score) / Number(a.maxScore)) * 100)
        : 0,
    }));
    return { bodyPart, assessments, trend };
  }

  async createProgram(patientId: string, dto: {
    doctorId: string;
    title: string;
    goal: string;
    exercises: ExerciseItem[];
    frequencyPerWeek: number;
    startDate: string;
    endDate?: string;
  }): Promise<RehabExerciseProgram> {
    const program = this.programRepo.create({
      patientId,
      doctorId: dto.doctorId,
      title: dto.title,
      goal: dto.goal,
      exercises: dto.exercises,
      frequencyPerWeek: dto.frequencyPerWeek,
      startDate: dto.startDate,
      endDate: dto.endDate ?? null,
      isActive: true,
    });
    return this.programRepo.save(program);
  }

  async getActivePrograms(patientId: string): Promise<RehabExerciseProgram[]> {
    return this.programRepo.find({
      where: { patientId, isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  async logSession(dto: {
    programId: string;
    exercisesCompleted: CompletedExercise[];
    painBefore: number;
    painAfter: number;
    note?: string;
    loggedAt: Date;
  }): Promise<RehabSessionLog> {
    const log = this.sessionRepo.create({
      programId: dto.programId,
      exercisesCompleted: dto.exercisesCompleted,
      painBefore: dto.painBefore,
      painAfter: dto.painAfter,
      note: dto.note ?? null,
      loggedAt: dto.loggedAt,
    });
    return this.sessionRepo.save(log);
  }

  async getSessionLogs(programId: string): Promise<RehabSessionLog[]> {
    return this.sessionRepo.find({
      where: { programId },
      order: { loggedAt: 'DESC' },
    });
  }

  async getRehabProgress(programId: string): Promise<{
    totalSessions: number;
    completionRate: number;
    avgPainBefore: number;
    avgPainAfter: number;
    painReduction: number;
  }> {
    const logs = await this.sessionRepo.find({ where: { programId } });
    if (!logs.length) {
      return { totalSessions: 0, completionRate: 0, avgPainBefore: 0, avgPainAfter: 0, painReduction: 0 };
    }

    const totalSessions = logs.length;
    const allCompleted = logs.flatMap((l) => l.exercisesCompleted);
    const completionRate = allCompleted.length > 0
      ? Math.round((allCompleted.filter((e) => e.completed).length / allCompleted.length) * 100)
      : 0;
    const avgPainBefore = logs.reduce((s, l) => s + l.painBefore, 0) / totalSessions;
    const avgPainAfter = logs.reduce((s, l) => s + l.painAfter, 0) / totalSessions;
    const painReduction = Math.round(((avgPainBefore - avgPainAfter) / avgPainBefore) * 100);

    return { totalSessions, completionRate, avgPainBefore, avgPainAfter, painReduction };
  }
}
