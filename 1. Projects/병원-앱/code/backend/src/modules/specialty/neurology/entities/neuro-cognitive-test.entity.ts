import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../../common/auth/entities/user.entity';

@Entity('neuro_cognitive_tests')
export class NeuroCognitiveTest {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'patient_id' })
  patientId: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'patient_id' })
  patient: User;

  @Column({ name: 'test_type', type: 'varchar' })
  testType: string;

  @Column({ type: 'int' })
  score: number;

  @Column({ name: 'max_score', type: 'int' })
  maxScore: number;

  @Column({ name: 'tested_at', type: 'date' })
  testedAt: string;

  @Column({ type: 'text', nullable: true })
  note: string | null;
}
