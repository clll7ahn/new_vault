import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

export enum RiskLevel {
  NORMAL = 'normal',
  CAUTION = 'caution',
  WARNING = 'warning',
  DANGER = 'danger',
}

@Entity('fm_checkup_results')
export class FmCheckupResult {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'checkup_date', type: 'date' })
  checkupDate: string;

  @Column({ type: 'jsonb' })
  results: Record<string, unknown>;

  @Column({ type: 'text' })
  summary: string;

  @Column({ name: 'risk_level', type: 'enum', enum: RiskLevel })
  riskLevel: RiskLevel;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
