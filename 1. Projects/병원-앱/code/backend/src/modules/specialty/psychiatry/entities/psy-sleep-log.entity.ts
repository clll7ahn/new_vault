import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('psy_sleep_logs')
export class PsySleepLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'bed_time', type: 'time' })
  bedTime: string;

  @Column({ name: 'wake_time', type: 'time' })
  wakeTime: string;

  @Column({ type: 'int' })
  quality: number;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;
}
