import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../../common/auth/entities/user.entity';

export enum RehabAssessmentType {
  ROM = 'rom',
  MUSCLE_STRENGTH = 'muscle_strength',
  ADL = 'adl',
  PAIN = 'pain',
  BALANCE = 'balance',
}

@Entity('rehab_assessments')
export class RehabAssessment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'doctor_id' })
  doctorId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'doctor_id' })
  doctor: User;

  @Column({ name: 'assessment_type', type: 'enum', enum: RehabAssessmentType })
  assessmentType: RehabAssessmentType;

  @Column({ name: 'body_part', type: 'varchar' })
  bodyPart: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  score: number;

  @Column({ name: 'max_score', type: 'decimal', precision: 10, scale: 2 })
  maxScore: number;

  @Column({ type: 'varchar', nullable: true })
  unit: string | null;

  @Column({ name: 'assessed_at', type: 'timestamptz' })
  assessedAt: Date;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
