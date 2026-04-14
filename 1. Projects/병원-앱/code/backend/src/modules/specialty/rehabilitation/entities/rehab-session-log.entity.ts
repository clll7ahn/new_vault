import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { RehabExerciseProgram } from './rehab-exercise-program.entity';

export interface CompletedExercise {
  name: string;
  completed: boolean;
  actualReps: number;
}

@Entity('rehab_session_logs')
export class RehabSessionLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'program_id' })
  programId: string;

  @ManyToOne(() => RehabExerciseProgram, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'program_id' })
  program: RehabExerciseProgram;

  @Column({ name: 'exercises_completed', type: 'jsonb' })
  exercisesCompleted: CompletedExercise[];

  @Column({ name: 'pain_before', type: 'int' })
  painBefore: number;

  @Column({ name: 'pain_after', type: 'int' })
  painAfter: number;

  @Column({ type: 'text', nullable: true })
  note: string | null;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
