import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { PsProcedure } from './ps-procedure.entity';

@Entity('ps_recovery_logs')
export class PsRecoveryLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'procedure_id' })
  procedureId: string;

  @ManyToOne(() => PsProcedure, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'procedure_id' })
  procedure: PsProcedure;

  @Column({ name: 'day_number', type: 'int' })
  dayNumber: number;

  @Column({ name: 'swelling_level', type: 'int' })
  swellingLevel: number;

  @Column({ name: 'pain_level', type: 'int' })
  painLevel: number;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @Column({ name: 'photo_url', type: 'varchar', nullable: true })
  photoUrl: string | null;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
