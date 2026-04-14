import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

export enum VoidType {
  URINATION = 'urination',
  URGENCY = 'urgency',
  LEAKAGE = 'leakage',
}

@Entity('uro_voiding_logs')
export class UroVoidingLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'void_type', type: 'enum', enum: VoidType })
  voidType: VoidType;

  @Column({ name: 'volume_ml', type: 'int', nullable: true })
  volumeMl: number | null;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;
}
