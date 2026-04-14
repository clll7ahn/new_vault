import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../../common/auth/entities/user.entity';

export enum PsProcedureStatus {
  PLANNED = 'planned',
  COMPLETED = 'completed',
  FOLLOW_UP = 'follow_up',
}

@Entity('ps_procedures')
export class PsProcedure {
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

  @Column({ name: 'procedure_type', type: 'varchar' })
  procedureType: string;

  @Column({ type: 'text' })
  description: string;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  cost: number | null;

  @Column({ name: 'procedure_date', type: 'timestamptz' })
  procedureDate: Date;

  @Column({ name: 'recovery_days', type: 'int', nullable: true })
  recoveryDays: number | null;

  @Column({
    type: 'enum',
    enum: PsProcedureStatus,
    default: PsProcedureStatus.PLANNED,
  })
  status: PsProcedureStatus;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
