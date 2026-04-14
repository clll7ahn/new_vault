import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Prediction, PredictionType } from './entities/prediction.entity';
import { Appointment, AppointmentStatus } from '../appointment/entities/appointment.entity';

type Period = 'week' | 'month' | 'quarter';

@Injectable()
export class AnalyticsService {
  constructor(
    @InjectRepository(Prediction)
    private readonly predictionRepo: Repository<Prediction>,
    @InjectRepository(Appointment)
    private readonly appointmentRepo: Repository<Appointment>,
    private readonly dataSource: DataSource,
  ) {}

  async predictNoShow(appointmentId: string): Promise<{
    appointmentId: string;
    probability: number;
    factors: Record<string, unknown>;
    risk: 'low' | 'medium' | 'high';
  }> {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId },
    });

    if (!appointment) {
      return { appointmentId, probability: 0, factors: {}, risk: 'low' };
    }

    const previousNoShows = await this.appointmentRepo.count({
      where: { patientId: appointment.patientId, status: AppointmentStatus.NO_SHOW },
    });

    const previousTotal = await this.appointmentRepo.count({
      where: { patientId: appointment.patientId },
    });

    const noShowRate = previousTotal > 0 ? previousNoShows / previousTotal : 0;

    const appointmentDate = new Date(appointment.appointmentDate);
    const dayOfWeek = appointmentDate.getDay();
    const isMondayOrFriday = dayOfWeek === 1 || dayOfWeek === 5;

    const [hour] = appointment.appointmentTime.split(':').map(Number);
    const isEarlyMorning = hour < 9;
    const isLateAfternoon = hour >= 17;

    let score = 0;
    const factors: Record<string, unknown> = {};

    if (noShowRate > 0.3) {
      score += 0.4;
      factors.historicalNoShowRate = `${(noShowRate * 100).toFixed(1)}%`;
    } else if (noShowRate > 0.1) {
      score += 0.2;
      factors.historicalNoShowRate = `${(noShowRate * 100).toFixed(1)}%`;
    }

    if (isMondayOrFriday) {
      score += 0.15;
      factors.dayOfWeek = dayOfWeek === 1 ? '월요일' : '금요일';
    }

    if (isEarlyMorning || isLateAfternoon) {
      score += 0.15;
      factors.timeSlot = isEarlyMorning ? '이른 아침' : '늦은 오후';
    }

    if (previousTotal === 0) {
      score += 0.1;
      factors.isNewPatient = true;
    }

    const probability = Math.min(score, 0.95);
    const risk: 'low' | 'medium' | 'high' =
      probability >= 0.5 ? 'high' : probability >= 0.25 ? 'medium' : 'low';

    await this.predictionRepo.save(
      this.predictionRepo.create({
        type: PredictionType.NO_SHOW,
        targetId: appointmentId,
        probability,
        factors,
        predictedFor: appointment.appointmentDate,
      }),
    );

    return { appointmentId, probability, factors, risk };
  }

  async getPeakTimeAnalysis(
    doctorId: string,
    period: Period = 'month',
  ): Promise<Array<{ hour: number; dayOfWeek: number; count: number; density: 'low' | 'medium' | 'high' }>> {
    const startDate = this.getStartDate(period);

    const results: Array<{ hour: string; dow: string; cnt: string }> =
      await this.dataSource.query(
        `
        SELECT
          EXTRACT(HOUR FROM appointment_time::interval) AS hour,
          EXTRACT(DOW FROM appointment_date::date) AS dow,
          COUNT(*) AS cnt
        FROM appointments
        WHERE doctor_id = $1
          AND appointment_date >= $2
          AND status NOT IN ('cancelled')
        GROUP BY hour, dow
        ORDER BY dow, hour
        `,
        [doctorId, startDate.toISOString().split('T')[0]],
      );

    const maxCount = results.reduce((m, r) => Math.max(m, parseInt(r.cnt)), 0);

    return results.map((r) => {
      const count = parseInt(r.cnt);
      const ratio = maxCount > 0 ? count / maxCount : 0;
      return {
        hour: parseInt(r.hour),
        dayOfWeek: parseInt(r.dow),
        count,
        density: ratio >= 0.7 ? 'high' : ratio >= 0.35 ? 'medium' : 'low',
      };
    });
  }

  async getPatientChurnRisk(): Promise<Array<{
    patientId: string;
    lastVisitDate: string;
    daysSinceLastVisit: number;
    appointmentCount: number;
    risk: 'medium' | 'high';
  }>> {
    const results: Array<{
      patient_id: string;
      last_visit: string;
      total_count: string;
    }> = await this.dataSource.query(`
      SELECT
        patient_id,
        MAX(appointment_date) AS last_visit,
        COUNT(*) AS total_count
      FROM appointments
      WHERE status = 'completed'
      GROUP BY patient_id
      HAVING MAX(appointment_date) < CURRENT_DATE - INTERVAL '90 days'
      ORDER BY last_visit ASC
      LIMIT 100
    `);

    return results.map((r) => {
      const lastVisit = new Date(r.last_visit);
      const daysSince = Math.floor(
        (Date.now() - lastVisit.getTime()) / (1000 * 60 * 60 * 24),
      );
      return {
        patientId: r.patient_id,
        lastVisitDate: r.last_visit,
        daysSinceLastVisit: daysSince,
        appointmentCount: parseInt(r.total_count),
        risk: daysSince >= 180 ? 'high' : 'medium',
      };
    });
  }

  async getDashboardInsights(): Promise<{
    date: string;
    highNoShowRiskToday: number;
    peakHoursToday: number[];
    churnRiskCount: number;
    todayAppointments: number;
  }> {
    const today = new Date().toISOString().split('T')[0];

    const todayAppointments = await this.appointmentRepo.count({
      where: { appointmentDate: today },
    });

    const recentPredictions = await this.predictionRepo.find({
      where: { type: PredictionType.NO_SHOW, predictedFor: today },
    });

    const highNoShowRiskToday = recentPredictions.filter(
      (p) => Number(p.probability) >= 0.5,
    ).length;

    const churnRisk = await this.getPatientChurnRisk();

    const peakResults: Array<{ hour: string; cnt: string }> =
      await this.dataSource.query(
        `
        SELECT
          EXTRACT(HOUR FROM appointment_time::interval) AS hour,
          COUNT(*) AS cnt
        FROM appointments
        WHERE appointment_date = $1 AND status NOT IN ('cancelled')
        GROUP BY hour
        ORDER BY cnt DESC
        LIMIT 3
        `,
        [today],
      );

    const peakHoursToday = peakResults.map((r) => parseInt(r.hour));

    return {
      date: today,
      highNoShowRiskToday,
      peakHoursToday,
      churnRiskCount: churnRisk.length,
      todayAppointments,
    };
  }

  async getRevenueMetrics(period: Period = 'month'): Promise<{
    period: string;
    startDate: string;
    endDate: string;
    totalAppointments: number;
    completedCount: number;
    cancelledCount: number;
    noShowCount: number;
    completionRate: number;
    cancellationRate: number;
    noShowRate: number;
  }> {
    const startDate = this.getStartDate(period);
    const endDate = new Date();

    const total = await this.appointmentRepo.count({
      where: {} as any,
    });

    const raw: Array<{ status: string; cnt: string }> =
      await this.dataSource.query(
        `
        SELECT status, COUNT(*) AS cnt
        FROM appointments
        WHERE appointment_date >= $1
        GROUP BY status
        `,
        [startDate.toISOString().split('T')[0]],
      );

    const countByStatus: Record<string, number> = {};
    let periodTotal = 0;
    for (const r of raw) {
      countByStatus[r.status] = parseInt(r.cnt);
      periodTotal += parseInt(r.cnt);
    }

    const completed = countByStatus['completed'] ?? 0;
    const cancelled = countByStatus['cancelled'] ?? 0;
    const noShow = countByStatus['no_show'] ?? 0;

    void total;

    return {
      period,
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
      totalAppointments: periodTotal,
      completedCount: completed,
      cancelledCount: cancelled,
      noShowCount: noShow,
      completionRate: periodTotal > 0 ? +(completed / periodTotal * 100).toFixed(2) : 0,
      cancellationRate: periodTotal > 0 ? +(cancelled / periodTotal * 100).toFixed(2) : 0,
      noShowRate: periodTotal > 0 ? +(noShow / periodTotal * 100).toFixed(2) : 0,
    };
  }

  private getStartDate(period: Period): Date {
    const now = new Date();
    if (period === 'week') {
      now.setDate(now.getDate() - 7);
    } else if (period === 'month') {
      now.setMonth(now.getMonth() - 1);
    } else {
      now.setMonth(now.getMonth() - 3);
    }
    return now;
  }
}
