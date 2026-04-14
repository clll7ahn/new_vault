import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
} from 'typeorm';
import { OrthoRehabProgram } from './ortho-rehab-program.entity';

@Entity('ortho_exercise_logs')
export class OrthoExerciseLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'program_id' })
  programId: string;

  @ManyToOne(() => OrthoRehabProgram, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'program_id' })
  program: OrthoRehabProgram;

  @Column({ name: 'exercise_name', type: 'varchar' })
  exerciseName: string;

  @Column({ type: 'boolean' })
  completed: boolean;

  @Column({ name: 'logged_at', type: 'timestamptz' })
  loggedAt: Date;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
