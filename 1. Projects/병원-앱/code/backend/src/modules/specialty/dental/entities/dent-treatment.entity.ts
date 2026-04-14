import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('dent_treatments')
export class DentTreatment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'tooth_number', type: 'int' })
  toothNumber: number;

  @Column({ name: 'treatment_type', type: 'varchar' })
  treatmentType: string;

  @Column({ name: 'plan_step', type: 'int', nullable: true })
  planStep: number | null;

  @Column({
    type: 'enum',
    enum: ['planned', 'in_progress', 'completed'],
    default: 'planned',
  })
  status: 'planned' | 'in_progress' | 'completed';

  @Column({ name: 'treated_at', type: 'timestamptz', nullable: true })
  treatedAt: Date | null;

  @Column({ name: 'next_date', type: 'date', nullable: true })
  nextDate: string | null;
}
