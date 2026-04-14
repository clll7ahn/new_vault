import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, Between } from 'typeorm';
import { PsyMoodLog } from './entities/psy-mood-log.entity';
import { PsySleepLog } from './entities/psy-sleep-log.entity';
import { PsyMedReaction } from './entities/psy-med-reaction.entity';
import { PsyCounselingNote } from './entities/psy-counseling-note.entity';

const CRISIS_RESOURCES = [
  { name: '자살예방상담전화', phone: '1393', available: '24시간' },
  { name: '정신건강위기상담전화', phone: '1577-0199', available: '24시간' },
];

@Injectable()
export class PsychiatryService {
  constructor(
    @InjectRepository(PsyMoodLog)
    private readonly moodLogRepo: Repository<PsyMoodLog>,
    @InjectRepository(PsySleepLog)
    private readonly sleepLogRepo: Repository<PsySleepLog>,
    @InjectRepository(PsyMedReaction)
    private readonly medReactionRepo: Repository<PsyMedReaction>,
    @InjectRepository(PsyCounselingNote)
    private readonly counselingNoteRepo: Repository<PsyCounselingNote>,
  ) {}

  async addMoodLog(
    patientId: string,
    dto: { moodScore: number; moodEmoji: string; note?: string; loggedAt: Date },
  ): Promise<PsyMoodLog> {
    const log = this.moodLogRepo.create({
      patientId,
      moodScore: dto.moodScore,
      moodEmoji: dto.moodEmoji,
      note: dto.note ?? null,
      loggedAt: dto.loggedAt,
    });
    return this.moodLogRepo.save(log);
  }

  async getMoodLogs(patientId: string, from: Date, to: Date): Promise<PsyMoodLog[]> {
    return this.moodLogRepo.find({
      where: { patientId, loggedAt: Between(from, to) },
      order: { loggedAt: 'DESC' },
    });
  }

  async getMoodTrend(patientId: string): Promise<Array<{ week: string; avgScore: number }>> {
    const logs = await this.moodLogRepo.find({
      where: { patientId },
      order: { loggedAt: 'ASC' },
    });

    const weekMap = new Map<string, number[]>();
    for (const log of logs) {
      const date = new Date(log.loggedAt);
      const day = date.getDay();
      const monday = new Date(date);
      monday.setDate(date.getDate() - (day === 0 ? 6 : day - 1));
      const weekKey = monday.toISOString().split('T')[0];
      if (!weekMap.has(weekKey)) weekMap.set(weekKey, []);
      weekMap.get(weekKey)!.push(log.moodScore);
    }

    return Array.from(weekMap.entries()).map(([week, scores]) => ({
      week,
      avgScore: Math.round((scores.reduce((a, b) => a + b, 0) / scores.length) * 10) / 10,
    }));
  }

  async addSleepLog(
    patientId: string,
    dto: { bedTime: string; wakeTime: string; quality: number; note?: string; loggedAt: Date },
  ): Promise<PsySleepLog> {
    const log = this.sleepLogRepo.create({
      patientId,
      bedTime: dto.bedTime,
      wakeTime: dto.wakeTime,
      quality: dto.quality,
      note: dto.note ?? null,
      loggedAt: dto.loggedAt,
    });
    return this.sleepLogRepo.save(log);
  }

  async getSleepLogs(patientId: string, from: Date, to: Date): Promise<PsySleepLog[]> {
    return this.sleepLogRepo.find({
      where: { patientId, loggedAt: Between(from, to) },
      order: { loggedAt: 'DESC' },
    });
  }

  async getSleepPattern(patientId: string): Promise<{
    avgDurationHours: number;
    avgQuality: number;
  }> {
    const logs = await this.sleepLogRepo.find({ where: { patientId } });
    if (logs.length === 0) return { avgDurationHours: 0, avgQuality: 0 };

    const durations = logs.map((log) => {
      const [bh, bm] = log.bedTime.split(':').map(Number);
      const [wh, wm] = log.wakeTime.split(':').map(Number);
      let minutes = (wh * 60 + wm) - (bh * 60 + bm);
      if (minutes < 0) minutes += 24 * 60;
      return minutes / 60;
    });

    const avgDurationHours =
      Math.round((durations.reduce((a, b) => a + b, 0) / durations.length) * 10) / 10;
    const avgQuality =
      Math.round((logs.reduce((a, b) => a + b.quality, 0) / logs.length) * 10) / 10;

    return { avgDurationHours, avgQuality };
  }

  async addMedReaction(
    patientId: string,
    dto: {
      medication: string;
      moodBefore: number;
      moodAfter: number;
      sideEffects?: string;
      loggedAt: Date;
    },
  ): Promise<PsyMedReaction> {
    const reaction = this.medReactionRepo.create({
      patientId,
      medication: dto.medication,
      moodBefore: dto.moodBefore,
      moodAfter: dto.moodAfter,
      sideEffects: dto.sideEffects ?? null,
      loggedAt: dto.loggedAt,
    });
    return this.medReactionRepo.save(reaction);
  }

  async getMedReactions(patientId: string): Promise<PsyMedReaction[]> {
    return this.medReactionRepo.find({
      where: { patientId },
      order: { loggedAt: 'DESC' },
    });
  }

  async addCounselingNote(
    doctorId: string,
    dto: {
      patientId: string;
      summary: string;
      patientVisible: boolean;
      sessionAt: Date;
    },
  ): Promise<PsyCounselingNote> {
    const note = this.counselingNoteRepo.create({
      doctorId,
      patientId: dto.patientId,
      summary: dto.summary,
      patientVisible: dto.patientVisible,
      sessionAt: dto.sessionAt,
    });
    return this.counselingNoteRepo.save(note);
  }

  async getCounselingNotes(patientId: string, doctorRole: boolean): Promise<PsyCounselingNote[]> {
    const where: Record<string, unknown> = { patientId };
    if (!doctorRole) where.patientVisible = true;
    return this.counselingNoteRepo.find({
      where,
      order: { sessionAt: 'DESC' },
    });
  }

  getCrisisResources(): typeof CRISIS_RESOURCES {
    return CRISIS_RESOURCES;
  }
}
