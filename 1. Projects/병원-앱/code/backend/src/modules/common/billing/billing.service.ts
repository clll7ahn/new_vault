import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Billing, BillingStatus, PaymentMethod } from './entities/billing.entity';
import { CreateBillingDto } from './dto/create-billing.dto';
import { ProcessPaymentDto } from './dto/process-payment.dto';

type Period = 'week' | 'month' | 'quarter';

@Injectable()
export class BillingService {
  constructor(
    @InjectRepository(Billing)
    private readonly billingRepo: Repository<Billing>,
    private readonly dataSource: DataSource,
  ) {}

  // ──────────────────────────────────────────
  // 청구서 생성 (admin)
  // ──────────────────────────────────────────

  async createBilling(dto: CreateBillingDto): Promise<Billing> {
    const billing = this.billingRepo.create({
      patientId: dto.patientId,
      appointmentId: dto.appointmentId ?? null,
      amount: dto.amount,
      description: dto.description,
      status: BillingStatus.PENDING,
    });
    return this.billingRepo.save(billing);
  }

  // ──────────────────────────────────────────
  // 내 청구 목록 조회 (환자)
  // ──────────────────────────────────────────

  async getMyBillings(
    patientId: string,
    status?: BillingStatus,
  ): Promise<Billing[]> {
    const qb = this.billingRepo
      .createQueryBuilder('b')
      .where('b.patient_id = :patientId', { patientId })
      .orderBy('b.created_at', 'DESC');

    if (status) {
      qb.andWhere('b.status = :status', { status });
    }

    return qb.getMany();
  }

  // ──────────────────────────────────────────
  // 단일 청구서 조회
  // ──────────────────────────────────────────

  async getBilling(id: string): Promise<Billing> {
    const billing = await this.billingRepo.findOne({
      where: { id },
      relations: ['patient', 'appointment'],
    });
    if (!billing) throw new NotFoundException('청구서를 찾을 수 없습니다.');
    return billing;
  }

  // ──────────────────────────────────────────
  // 결제 처리 (환자)
  // ──────────────────────────────────────────

  async processPayment(id: string, dto: ProcessPaymentDto): Promise<Billing> {
    const billing = await this.billingRepo.findOne({ where: { id } });
    if (!billing) throw new NotFoundException('청구서를 찾을 수 없습니다.');

    if (billing.status !== BillingStatus.PENDING && billing.status !== BillingStatus.OVERDUE) {
      throw new BadRequestException(
        `결제할 수 없는 상태입니다. 현재 상태: ${billing.status}`,
      );
    }

    billing.status = BillingStatus.PAID;
    billing.paymentMethod = dto.paymentMethod;
    billing.paidAt = new Date();
    billing.receiptNumber = this.generateReceiptNumber();

    return this.billingRepo.save(billing);
  }

  // ──────────────────────────────────────────
  // 미납 청구 목록 (환자)
  // ──────────────────────────────────────────

  async getUnpaidBillings(patientId: string): Promise<Billing[]> {
    return this.billingRepo
      .createQueryBuilder('b')
      .where('b.patient_id = :patientId', { patientId })
      .andWhere('b.status IN (:...statuses)', {
        statuses: [BillingStatus.PENDING, BillingStatus.OVERDUE],
      })
      .orderBy('b.created_at', 'ASC')
      .getMany();
  }

  // ──────────────────────────────────────────
  // 기간별 결제 통계 (admin)
  // ──────────────────────────────────────────

  async getTotalStats(period: Period = 'month'): Promise<{
    period: string;
    startDate: string;
    endDate: string;
    totalBillings: number;
    totalAmount: number;
    paidAmount: number;
    unpaidAmount: number;
    refundedAmount: number;
    paidCount: number;
    pendingCount: number;
    overdueCount: number;
    refundedCount: number;
    collectionRate: number;
  }> {
    const startDate = this.getStartDate(period);
    const endDate = new Date();

    const raw: Array<{
      status: string;
      cnt: string;
      total: string;
    }> = await this.dataSource.query(
      `
      SELECT
        status,
        COUNT(*) AS cnt,
        COALESCE(SUM(amount), 0) AS total
      FROM billings
      WHERE created_at >= $1
      GROUP BY status
      `,
      [startDate.toISOString()],
    );

    const byStatus: Record<string, { count: number; amount: number }> = {};
    let totalBillings = 0;
    let totalAmount = 0;

    for (const r of raw) {
      byStatus[r.status] = {
        count: parseInt(r.cnt),
        amount: parseFloat(r.total),
      };
      totalBillings += parseInt(r.cnt);
      totalAmount += parseFloat(r.total);
    }

    const paid = byStatus[BillingStatus.PAID] ?? { count: 0, amount: 0 };
    const pending = byStatus[BillingStatus.PENDING] ?? { count: 0, amount: 0 };
    const overdue = byStatus[BillingStatus.OVERDUE] ?? { count: 0, amount: 0 };
    const refunded = byStatus[BillingStatus.REFUNDED] ?? { count: 0, amount: 0 };

    const unpaidAmount = pending.amount + overdue.amount;
    const collectionRate =
      totalAmount > 0 ? +((paid.amount / totalAmount) * 100).toFixed(2) : 0;

    return {
      period,
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
      totalBillings,
      totalAmount: +totalAmount.toFixed(2),
      paidAmount: +paid.amount.toFixed(2),
      unpaidAmount: +unpaidAmount.toFixed(2),
      refundedAmount: +refunded.amount.toFixed(2),
      paidCount: paid.count,
      pendingCount: pending.count,
      overdueCount: overdue.count,
      refundedCount: refunded.count,
      collectionRate,
    };
  }

  // ──────────────────────────────────────────
  // 내부 유틸
  // ──────────────────────────────────────────

  private generateReceiptNumber(): string {
    const now = new Date();
    const yyyymmdd = now.toISOString().slice(0, 10).replace(/-/g, '');
    const random = Math.floor(Math.random() * 1_000_000)
      .toString()
      .padStart(6, '0');
    return `RCPT-${yyyymmdd}-${random}`;
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
