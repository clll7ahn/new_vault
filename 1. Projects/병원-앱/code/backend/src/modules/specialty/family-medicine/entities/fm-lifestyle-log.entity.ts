import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

export enum LifestyleType {
  SMOKING = 'smoking',
  DRINKING = 'drinking',
  EXERCISE = 'exercise',
  DIET = 'diet',
}

@Entity('fm_lifestyle_logs')
export class FmLifestyleLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ type: 'enum', enum: LifestyleType })
  type: LifestyleType;

  @Column({ type: 'jsonb' })
  value: Record<string, unknown>;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;
}
