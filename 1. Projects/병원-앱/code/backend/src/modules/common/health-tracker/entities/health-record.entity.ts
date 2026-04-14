import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  Index,
} from 'typeorm';
import { User } from '../../auth/entities/user.entity';

export enum HealthRecordType {
  STEPS = 'steps',
  HEART_RATE = 'heart_rate',
  SLEEP = 'sleep',
  BLOOD_PRESSURE = 'blood_pressure',
  BLOOD_GLUCOSE = 'blood_glucose',
  WEIGHT = 'weight',
}

export enum HealthRecordSource {
  MANUAL = 'manual',
  APPLE_HEALTH = 'apple_health',
  GOOGLE_FIT = 'google_fit',
  DEVICE = 'device',
}

@Entity('health_records')
@Index(['userId', 'type', 'recordedAt'], { unique: true })
export class HealthRecord {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id' })
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @Column({ type: 'enum', enum: HealthRecordType })
  type: HealthRecordType;

  @Column({ type: 'decimal', precision: 10, scale: 4 })
  value: number;

  @Column({
    name: 'value_secondary',
    type: 'decimal',
    precision: 10,
    scale: 4,
    nullable: true,
  })
  valueSecondary: number | null;

  @Column({ length: 20 })
  unit: string;

  @Column({ type: 'enum', enum: HealthRecordSource })
  source: HealthRecordSource;

  @Column({ name: 'recorded_at', type: 'timestamptz' })
  recordedAt: Date;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
