import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

export enum HeadacheType {
  TENSION = 'tension',
  MIGRAINE = 'migraine',
  CLUSTER = 'cluster',
  OTHER = 'other',
}

export enum HeadacheLocation {
  FRONTAL = 'frontal',
  TEMPORAL = 'temporal',
  OCCIPITAL = 'occipital',
  WHOLE = 'whole',
}

@Entity('neuro_headache_logs')
export class NeuroHeadacheLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'headache_type', type: 'enum', enum: HeadacheType })
  headacheType: HeadacheType;

  @Column({ type: 'int' })
  intensity: number;

  @Column({ name: 'duration_hours', type: 'decimal', precision: 5, scale: 2 })
  durationHours: number;

  @Column({ type: 'text', array: true, nullable: true })
  triggers: string[] | null;

  @Column({ type: 'enum', enum: HeadacheLocation })
  location: HeadacheLocation;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;
}
