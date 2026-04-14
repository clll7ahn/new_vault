import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

export enum VitalType {
  BLOOD_PRESSURE = 'blood_pressure',
  BLOOD_GLUCOSE = 'blood_glucose',
  WEIGHT = 'weight',
}

@Entity('im_vitals')
export class ImVitals {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ type: 'enum', enum: VitalType })
  type: VitalType;

  @Column({ name: 'value_1', type: 'decimal', precision: 10, scale: 2 })
  value1: number;

  @Column({ name: 'value_2', type: 'decimal', precision: 10, scale: 2, nullable: true })
  value2: number | null;

  @Column({ name: 'measured_at', type: 'timestamptz' })
  measuredAt: Date;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
