import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { User } from '../../../../common/auth/entities/user.entity';

export interface ExerciseItem {
  name: string;
  reps: number;
  sets: number;
  duration: number;
  videoUrl: string;
  instruction: string;
}

@Entity('rehab_exercise_programs')
export class RehabExerciseProgram {
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

  @Column({ type: 'varchar' })
  title: string;

  @Column({ type: 'text' })
  goal: string;

  @Column({ type: 'jsonb' })
  exercises: ExerciseItem[];

  @Column({ name: 'frequency_per_week', type: 'int' })
  frequencyPerWeek: number;

  @Column({ name: 'start_date', type: 'date' })
  startDate: string;

  @Column({ name: 'end_date', type: 'date', nullable: true })
  endDate: string | null;

  @Column({ name: 'is_active', type: 'boolean', default: true })
  isActive: boolean;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
