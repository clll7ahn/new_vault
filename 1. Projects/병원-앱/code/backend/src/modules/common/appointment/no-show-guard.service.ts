import {
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual, IsNull, Not } from 'typeorm';
import { Appointment, AppointmentStatus } from './entities/appointment.entity';
import { AppointmentReminder, ReminderStatus } from './entities/appointment-reminder.entity';
import { NotificationService } from '../notification/notification.service';
import { NotificationType } from '../notification/entities/notification.entity';

@Injectable()
export class NoShowGuardService {
  private readonly logger = new Logger(NoShowGuardService.name);

  constructor(
    @InjectRepository(Appointment)
    private readonly appointmentRepo: Repository<Appointment>,

    @InjectRepository(AppointmentReminder)
    private readonly reminderRepo: Repository<AppointmentReminder>,

    private readonly notificationService: NotificationService,
  ) {}

  /**
   * 예약 생성 시 호출.
   * 3단계 알림을 appointment_reminders 테이블에 스케줄링한다.
   *
   * Stage 1: 예약 전날 오후 18:00
   * Stage 2: 예약 당일 오전 08:00
   * Stage 3: 예약 1시간 전
   */
  async scheduleReminders(appointmentId: string): Promise<void> {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId },
    });
    if (!appointment) {
      throw new NotFoundException('예약을 찾을 수 없습니다.');
    }

    // appointmentDate: 'YYYY-MM-DD', appointmentTime: 'HH:mm' or 'HH:mm:ss'
    const [year, month, day] = appointment.appointmentDate.split('-').map(Number);
    const [hour, minute] = appointment.appointmentTime.split(':').map(Number);

    // 예약 일시 (UTC 기준으로 저장; 실제 운영 시 timezone 처리 필요)
    const appointmentDateTime = new Date(year, month - 1, day, hour, minute, 0);

    // Stage 1: 전날 18:00
    const stage1At = new Date(year, month - 1, day - 1, 18, 0, 0);

    // Stage 2: 당일 08:00
    const stage2At = new Date(year, month - 1, day, 8, 0, 0);

    // Stage 3: 예약 1시간 전
    const stage3At = new Date(appointmentDateTime.getTime() - 60 * 60 * 1000);

    const stages: Array<{ stage: 1 | 2 | 3; scheduledAt: Date }> = [
      { stage: 1, scheduledAt: stage1At },
      { stage: 2, scheduledAt: stage2At },
      { stage: 3, scheduledAt: stage3At },
    ];

    const now = new Date();
    const reminders: AppointmentReminder[] = [];

    for (const { stage, scheduledAt } of stages) {
      // 이미 지난 시각은 스케줄하지 않음 (예: 당일 급하게 예약한 경우)
      if (scheduledAt <= now) {
        this.logger.debug(
          `Skipping stage ${stage} reminder for appointment ${appointmentId}: scheduled time already passed`,
        );
        continue;
      }

      const reminder = this.reminderRepo.create({
        appointmentId,
        stage,
        scheduledAt,
        sentAt: null,
        confirmedAt: null,
        status: ReminderStatus.PENDING,
      });
      reminders.push(reminder);
    }

    if (reminders.length > 0) {
      await this.reminderRepo.save(reminders);
      this.logger.log(
        `Scheduled ${reminders.length} reminder(s) for appointment ${appointmentId}`,
      );
    }
  }

  /**
   * 각 단계 처리: 알림 전송 + (마지막 단계 미확인 시) 슬롯 자동 오픈.
   * 실제 운영에서는 @nestjs/schedule Cron 잡이 매 분 이 메서드를 호출한다.
   * 예) @Cron('* * * * *') async runPendingReminders()
   */
  async processStage(appointmentId: string, stage: 1 | 2 | 3): Promise<void> {
    const reminder = await this.reminderRepo.findOne({
      where: { appointmentId, stage },
    });

    if (!reminder) {
      this.logger.warn(`No reminder found for appointment ${appointmentId} stage ${stage}`);
      return;
    }

    if (reminder.status !== ReminderStatus.PENDING) {
      this.logger.debug(
        `Reminder for appointment ${appointmentId} stage ${stage} already processed (${reminder.status})`,
      );
      return;
    }

    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId },
      relations: ['patient'],
    });

    if (!appointment) {
      this.logger.warn(`Appointment ${appointmentId} not found during processStage`);
      return;
    }

    // 이미 취소/완료된 예약은 알림 불필요
    if (
      appointment.status === AppointmentStatus.CANCELLED ||
      appointment.status === AppointmentStatus.COMPLETED
    ) {
      reminder.status = ReminderStatus.EXPIRED;
      await this.reminderRepo.save(reminder);
      return;
    }

    const stageMessages: Record<number, { title: string; body: string }> = {
      1: {
        title: '[내일 진료 예약] 출석 확인 요청',
        body: `내일(${appointment.appointmentDate} ${appointment.appointmentTime.slice(0, 5)}) 예약이 있습니다. 앱에서 참석을 확인해 주세요.`,
      },
      2: {
        title: '[오늘 진료 예약] 아침 리마인더',
        body: `오늘 ${appointment.appointmentTime.slice(0, 5)} 예약이 있습니다. 참석 여부를 확인해 주세요.`,
      },
      3: {
        title: '[1시간 후 진료] 최종 확인 요청',
        body: `1시간 후(${appointment.appointmentTime.slice(0, 5)}) 예약입니다. 지금 바로 참석을 확인해 주세요.`,
      },
    };

    const message = stageMessages[stage];

    await this.notificationService.create({
      userId: appointment.patientId,
      title: message.title,
      body: message.body,
      type: NotificationType.APPOINTMENT,
      data: {
        appointmentId,
        stage,
        appointmentDate: appointment.appointmentDate,
        appointmentTime: appointment.appointmentTime,
      },
    });

    reminder.sentAt = new Date();
    reminder.status = ReminderStatus.SENT;
    await this.reminderRepo.save(reminder);

    this.logger.log(
      `Stage ${stage} reminder sent for appointment ${appointmentId}`,
    );

    // Stage 3 전송 후 일정 시간(10분) 뒤 확인 안 하면 슬롯 해제
    // 실제 Cron 잡에서 scheduleAutoRelease 를 별도로 실행하거나,
    // 여기서 setTimeout을 사용할 수 있지만, 운영 안정성을 위해 별도 Cron 권장.
    if (stage === 3) {
      this.logger.log(
        `Stage 3 sent for ${appointmentId}. Auto-release will trigger after confirmation window.`,
      );
    }
  }

  /**
   * 환자가 "참석 확인" 버튼을 클릭했을 때 호출.
   * 가장 최근에 SENT 상태인 리마인더를 CONFIRMED 처리한다.
   */
  async confirmAttendance(appointmentId: string): Promise<void> {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId },
    });
    if (!appointment) {
      throw new NotFoundException('예약을 찾을 수 없습니다.');
    }

    // 전송됐지만 아직 미확인인 리마인더를 모두 확인 처리
    const sentReminders = await this.reminderRepo.find({
      where: {
        appointmentId,
        status: ReminderStatus.SENT,
        confirmedAt: IsNull(),
      },
    });

    if (sentReminders.length === 0) {
      this.logger.debug(`No pending sent reminders to confirm for appointment ${appointmentId}`);
      return;
    }

    const now = new Date();
    for (const reminder of sentReminders) {
      reminder.confirmedAt = now;
      reminder.status = ReminderStatus.CONFIRMED;
    }

    await this.reminderRepo.save(sentReminders);
    this.logger.log(
      `Attendance confirmed for appointment ${appointmentId} (${sentReminders.length} reminder(s) confirmed)`,
    );
  }

  /**
   * 3단계 알림 이후 일정 시간 내 확인이 없으면 슬롯을 해제하고
   * 대기자에게 슬롯을 자동으로 오픈한다.
   *
   * 실제 운영: Cron 잡에서 getUnconfirmedStage3Reminders()를 순회하며 호출.
   */
  async autoReleaseSlot(appointmentId: string): Promise<void> {
    const appointment = await this.appointmentRepo.findOne({
      where: { id: appointmentId },
      relations: ['patient'],
    });
    if (!appointment) {
      throw new NotFoundException('예약을 찾을 수 없습니다.');
    }

    // 이미 취소됐거나 완료된 예약은 처리 불필요
    if (
      appointment.status === AppointmentStatus.CANCELLED ||
      appointment.status === AppointmentStatus.COMPLETED
    ) {
      return;
    }

    // Stage 3 리마인더가 SENT 상태(미확인)인지 확인
    const stage3Reminder = await this.reminderRepo.findOne({
      where: {
        appointmentId,
        stage: 3 as 1 | 2 | 3,
        status: ReminderStatus.SENT,
      },
    });

    if (!stage3Reminder) {
      // 이미 확인됐거나 아직 Stage 3이 발송되지 않음
      return;
    }

    // 예약을 노쇼로 변경
    appointment.status = AppointmentStatus.NO_SHOW;
    await this.appointmentRepo.save(appointment);

    // 리마인더 만료 처리
    stage3Reminder.status = ReminderStatus.EXPIRED;
    await this.reminderRepo.save(stage3Reminder);

    this.logger.log(
      `Appointment ${appointmentId} marked as NO_SHOW. Slot released.`,
    );

    // 환자에게 노쇼 처리 알림
    await this.notificationService.create({
      userId: appointment.patientId,
      title: '[예약 자동 취소] 노쇼 처리됨',
      body: `${appointment.appointmentDate} ${appointment.appointmentTime.slice(0, 5)} 예약이 참석 미확인으로 인해 자동 취소되었습니다.`,
      type: NotificationType.APPOINTMENT,
      data: { appointmentId, reason: 'no_show_auto_release' },
    });

    // TODO: 대기자 목록 조회 후 슬롯 자동 배정
    // WaitlistService 연동 시 아래 코드를 활성화하세요:
    // await this.waitlistService.assignNextWaiting(
    //   appointment.doctorId,
    //   appointment.appointmentDate,
    //   appointment.appointmentTime,
    // );
  }

  /**
   * 오늘 예약 중 Stage 3 미확인(노쇼 위험) 예약 목록 (관리자용).
   */
  async getNoShowRiskAppointments(): Promise<Appointment[]> {
    const today = new Date();
    const todayStr = today.toISOString().split('T')[0]; // 'YYYY-MM-DD'

    // 오늘 날짜 예약 중 PENDING 또는 CONFIRMED 상태인 예약
    const appointments = await this.appointmentRepo.find({
      where: [
        { appointmentDate: todayStr, status: AppointmentStatus.PENDING },
        { appointmentDate: todayStr, status: AppointmentStatus.CONFIRMED },
      ],
      relations: ['patient', 'doctor', 'department'],
      order: { appointmentTime: 'ASC' },
    });

    // Stage 3 리마인더가 SENT(미확인) 상태인 예약만 필터링
    const riskAppointments: Appointment[] = [];

    for (const appointment of appointments) {
      const stage3 = await this.reminderRepo.findOne({
        where: {
          appointmentId: appointment.id,
          stage: 3 as 1 | 2 | 3,
          status: ReminderStatus.SENT,
          confirmedAt: IsNull(),
        },
      });
      if (stage3) {
        riskAppointments.push(appointment);
      }
    }

    return riskAppointments;
  }

  /**
   * 스케줄러에서 호출: scheduled_at이 지났고 아직 PENDING인 리마인더를 일괄 처리.
   * @nestjs/schedule 의 @Cron('* * * * *')에서 호출 권장.
   */
  async processDueReminders(): Promise<void> {
    const now = new Date();

    const dueReminders = await this.reminderRepo.find({
      where: {
        status: ReminderStatus.PENDING,
        scheduledAt: LessThanOrEqual(now),
      },
    });

    for (const reminder of dueReminders) {
      try {
        await this.processStage(reminder.appointmentId, reminder.stage);
      } catch (err) {
        this.logger.error(
          `Failed to process reminder ${reminder.id}: ${(err as Error).message}`,
        );
      }
    }
  }

  /**
   * 스케줄러에서 호출: Stage 3 발송 후 10분이 지났지만 미확인인 예약 자동 해제.
   * @nestjs/schedule 의 @Cron('*/5 * * * *')에서 호출 권장.
   */
  async processAutoReleases(): Promise<void> {
    const tenMinutesAgo = new Date(Date.now() - 10 * 60 * 1000);

    const expiredStage3 = await this.reminderRepo.find({
      where: {
        stage: 3 as 1 | 2 | 3,
        status: ReminderStatus.SENT,
        confirmedAt: IsNull(),
        sentAt: Not(IsNull()),
      },
    });

    for (const reminder of expiredStage3) {
      if (reminder.sentAt && reminder.sentAt <= tenMinutesAgo) {
        try {
          await this.autoReleaseSlot(reminder.appointmentId);
        } catch (err) {
          this.logger.error(
            `Failed to auto-release slot for appointment ${reminder.appointmentId}: ${(err as Error).message}`,
          );
        }
      }
    }
  }
}
