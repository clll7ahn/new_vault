import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('ortho_pain_logs')
export class OrthoPainLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'body_part', type: 'varchar' })
  bodyPart: string;

  @Column({ type: 'int' })
  intensity: number;

  @Column({ name: 'pain_type', type: 'varchar' })
  painType: string;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
